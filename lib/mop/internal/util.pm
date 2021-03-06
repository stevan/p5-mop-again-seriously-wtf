package mop::internal::util;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub import ($class, @args) {
    my $calling_pkg = caller;
    while ( @args ) {
        my $arg = shift @args;
        if ( $arg eq 'FINALIZE' ) {
            INSTALL_FINALIZATION_RUNNER( $calling_pkg );   
        }
    }
}

## Class finalization 

# NOTE:
# This feature is here simply because we need
# to run the FINALIZE blocks in FIFO order
# and the raw UNITCHECK blocks run in LIFO order
# which can present issues when more then one 
# class/role is in a single compiliation unit
# and the later class/role depends on a former
# class/role to have been finalized.
#
# It is important to note that UNITCHECK, while
# compilation unit specific, is *not* package 
# specific, so we need to manage the per-package
# stuff on our own. 
# - SL

sub INSTALL_FINALIZATION_RUNNER ($pkg) {
    # NOTE:
    # this check is imperfect, ideally things 
    # will always happen completely at compile 
    # time, for which the ${^GLOBAL_PHASE} check
    # is correct, but this does not work for 
    # code created with eval STRING, in this case ...
    die "[mop::PANIC] To late to install finalization runner for <$pkg>, current-phase: (${^GLOBAL_PHASE})" 
        unless ${^GLOBAL_PHASE} eq 'START' 
            # we check the caller, and climb
            # far enough up the stack to work 
            # reasonably correctly for our common
            # use cases (at least the ones we have
            # right now). That said, it is fragile
            # at best and will break if you aren't 
            # that number of stack frames away from 
            # an eval STRING;
            || (caller(3))[3] eq '(eval)';

    push @{ mop::internal::util::get_UNITCHECK_AV() } => (
        sub { mop::role->new( name => $pkg )->run_all_finalizers }
    );
}

## Closing classes

sub CLOSE_CLASS ($class) {
    no strict 'refs';
    mop::internal::opaque::set_at_slot( \%{$class.'::'}, is_closed => 1 );
}

## Dispatching and class MRO walking

# NOTE:
# The dispatcher current returns a CODE ref
# that maintains internal state, this is 
# an implementation detail. This could easily
# return some opaque interator object just 
# as easily. The only two things which would 
# need to be aware of this are the WALKCLASS
# and WALKMETH functions below. Then if everyone
# used the WALKCLASS/WALKMETH functions, we 
# can really optimize the dispatcher, which 
# would then we optimize a lot of other things 
# as well.
# - SL

sub DISPATCHER ($class, %opts) {
    my $meta = $opts{type} || 'mop::role';
    if ( $opts{reverse} ) {
        return sub { 
            state $mro = [ reverse @{ mro::get_linear_isa( $class ) } ]; 
            return $meta->new( name => ((shift @$mro) || return) ) 
        };
    }
    else {
        return sub { 
            state $mro = [ @{ mro::get_linear_isa( $class ) } ]; 
            return $meta->new( name => ((shift @$mro) || return) ) 
        };
    }
}

sub WALKCLASS ($dispatcher) { $dispatcher->() }

sub WALKMETH ($dispatcher, $method) {
    {; ($dispatcher->() || return)->get_method( $method ) || redo }       
}

## Instance construction and destruction 

sub BUILDALL ($instance, $args) {
    my $dispatcher = DISPATCHER(ref $instance, ( reverse => 1, type => 'mop::class' ));
    while ( my $method = WALKMETH( $dispatcher, 'BUILD' ) ) {
        $method->body->( $instance, $args );
    }
    return; 
}

sub DEMOLISHALL ($instance)  {
    my $dispatcher = DISPATCHER(ref $instance, ( type => 'mop::class' ));
    while ( my $method = WALKMETH( $dispatcher, 'DEMOLISH' ) ) {
        $method->body->( $instance );
    }
    return; 
}

## Inheriting required methods 

sub INHERIT_REQUIRED_METHODS ($meta) {
    foreach my $super ( map { mop::role->new( name => $_ ) } $meta->superclasses ) {
        foreach my $required_method ( $super->required_methods ) {
            $meta->add_required_method($required_method)
        }
    }
}

## Attribute gathering ...

# NOTE:
# The %HAS variable will cache things much like 
# the package stash method/cache works. It will 
# be possible to distinguish the local attributes 
# from the inherited ones because the default sub
# will have a different stash name. 

sub GATHER_ALL_ATTRIBUTES ($meta) {
    my $dispatcher = DISPATCHER( $meta->name );
    WALKCLASS( $dispatcher ); # no need to search ourselves ...
    while ( my $super = WALKCLASS( $dispatcher ) ) {
        foreach my $attr ( $super->attributes ) {
            $meta->alias_attribute( $attr->name, $attr->initializer ) 
                unless $meta->has_attribute( $attr->name ) 
                    || $meta->has_attribute_alias( $attr->name );
        }
    }
}

## Role application and composition

sub APPLY_ROLES ($meta, $roles, %opts) {
    die "[mop::PANIC] You must specify what type of object you want roles applied `to`" 
        unless exists $opts{to};

    foreach my $r ( $meta->roles ) {
        die "[mop::PANIC] Could not find role ($_) in the set of roles in $meta (" . $meta->name . ")" 
            unless scalar grep { $r eq $_ } @$roles;
    }

    my @meta_roles = map { mop::role->new( name => $_ ) } @$roles;

    my (
        $attributes,
        $attr_conflicts
    ) = COMPOSE_ALL_ROLE_ATTRIBUTES( @meta_roles );

    die "[mop::PANIC] There should be no conflicting attributes when composing (" . (join ', ' => @$roles) . ") into (" . $meta->name . ")"
        if scalar keys %$attr_conflicts;

    foreach my $name ( keys %$attributes ) {
        # if we have an attribute already by that name ...
        die "[mop::PANIC] Role Conflict, cannot compose attribute ($name) into (" . $meta->name . ") because ($name) already exists"
            if $meta->has_attribute( $name );
        # otherwise alias it ...
        $meta->alias_attribute( $name, $attributes->{ $name } );
    }

    my (
        $methods, 
        $method_conflicts,
        $required_methods
    ) = COMPOSE_ALL_ROLE_METHODS( @meta_roles );

    die "[mop::PANIC] There should be no conflicting methods when composing (" . (join ', ' => @$roles) . ") into the class (" . $meta->name . ") but instead we found (" . (join ', ' => keys %$method_conflicts)  . ")"
        if $opts{to} eq 'class'           # if we are composing into a class ...
        && (scalar keys %$method_conflicts) # and we have any conflicts ...
        # and the conflicts are not satisfied by the composing class ...
        && (scalar grep { !$meta->has_method( $_ ) } keys %$method_conflicts)
        # and the class is not declared abstract ....
        && !$meta->is_abstract; 

    # check the required method set and 
    # see if what we are composing into 
    # happens to fulfill them 
    foreach my $name ( keys %$required_methods ) {
        delete $required_methods->{ $name } 
            if $meta->name->can( $name );
    }

    die "[mop::PANIC] There should be no required methods when composing (" . (join ', ' => @$roles) . ") into (" . $meta->name . ") but instead we found (" . (join ', ' => keys %$required_methods)  . ")"
        if $opts{to} eq 'class'           # if we are composing into a class ...
        && scalar keys %$required_methods # and we have required methods ...
        && !$meta->is_abstract;           # and the class is not abstract ...

    foreach my $name ( keys %$methods ) {
        # if we have a method already by that name ...
        next if $meta->has_method( $name );
        # otherwise, alias it ...
        $meta->alias_method( $name, $methods->{ $name } );
    }

    # if we still have keys in $required, it is 
    # because we are a role (class would have 
    # died above), so we can just stuff in the 
    # required methods ...
    $meta->add_required_method( $_ ) for keys %$required_methods;

    return;
}

sub COMPOSE_ALL_ROLE_ATTRIBUTES (@roles) {
    my (%attributes, %conflicts);

    foreach my $role ( @roles ) {
        foreach my $attr ( $role->attributes ) {
            my $name = $attr->name;
            # if we have one already, but 
            # it is not the same refaddr ...
            if ( exists $attributes{ $name } && $attributes{ $name } != $attr->initializer ) {
                # mark it as a conflict ...
                $conflicts{ $name } = undef;
                # and remove it from our attribute set ...
                delete $attributes{ $name };
            }
            # if we don't have it already ...
            else {
                # make a note of it
                $attributes{ $name } = $attr->initializer;    
            }
        }
    }

    return \%attributes, \%conflicts;
}


# TODO:
# We should track the name of the role
# where the required method was composed 
# from, as well as the two classes in 
# which a method conflicted.
# - SL
sub COMPOSE_ALL_ROLE_METHODS (@roles) {
    my (%methods, %conflicts, %required);

    # flatten the set of required methods ...
    foreach my $r ( @roles ) {
        foreach my $m ( $r->required_methods ) {
            $required{ $m } = undef;
        }
    }

    # for every role ...
    foreach my $r ( @roles ) {
        # and every method in that role ...
        foreach my $m ( $r->methods ) {
            my $name = $m->name;
            # if we have already seen the method, 
            # but it is not the same refaddr
            # it is a conflict, which means:            
            if ( exists $methods{ $name } && $methods{ $name } != $m->body  ) {
                # we need to add it to our required-method map
                $required{ $name } = undef;
                # and note that it is also a conflict ...
                $conflicts{ $name } = undef;
                # and remove it from our method map
                delete $methods{ $name };
            }
            # if we haven't seen the method ...
            else {
                # add it to the method map
                $methods{ $name } = $m->body;
                # and remove it from the required-method map 
                delete $required{ $name } 
                    # if it actually exists in it, and ...
                    if exists $required{ $name }
                    # is not also a conflict ...
                    && not exists $conflicts{ $name };
            }
        }
    }  

    #use Data::Dumper;
    #warn Dumper [ [ map { $_->name } @roles ], \%methods, \%conflicts, \%required ];

    return \%methods, \%conflicts, \%required;
}

1;

__END__
