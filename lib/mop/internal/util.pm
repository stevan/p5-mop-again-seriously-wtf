package mop::internal::util;

use v5.20;
use mro;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures', 'experimental::postderef';

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

    push @{ mop::internal::util::guts::get_UNITCHECK_AV() } => (
        sub { mop::role->new( name => $pkg )->run_all_finalizers }
    );
}

## Instance construction and destruction 

# TODO:
# - add caches here using a `state` var
# - the ->can("BUILD") is likely not doing the right thing, fix it.
#     - should be able to use a %seen hash to avoid calling a BUILD/DEMOLISH twice
# - SL

sub BUILDALL ($instance, $args) {
    foreach my $c ( reverse mro::get_linear_isa( ref $instance )->@* ) {
        if ( my $build = $c->can('BUILD') ) {
            $instance->$build( $args );
        }
    }
    return;
}

sub DEMOLISHALL ($instance)  {
    foreach my $c ( mro::get_linear_isa( ref $instance )->@* ) {
        if ( my $demolish = $c->can('DEMOLISH') ) {
            $instance->$demolish();
        }
    }
    return;
}

## Attribute gathering ...

# NOTE:
# The %HAS variable will cache things much like 
# the package stash method/cache works. It will 
# be possible to distinguish the local attributes 
# from the inherited ones because the default sub
# will have a different stash name. 

sub GATHER_ALL_ATTRIBUTES ($meta) {
    my @mro = $meta->mro;
    shift @mro; # no need to search ourselves ...
    foreach my $super ( map { mop::role->new( name => $_ ) } @mro ) {
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

    die "[mop::PANIC] There should be no conflicting methods when composing (" . (join ', ' => @$roles) . ") into (" . $meta->name . ") but instead we found (" . (join ', ' => keys %$method_conflicts)  . ")"
        if scalar keys %$method_conflicts;

    # check the required method set and 
    # see if what we are composing into 
    # happens to fulfill them 
    foreach my $name ( keys %$required_methods ) {
        delete $required_methods->{ $name } 
            if $meta->name->can( $name );
    }

    die "[mop::PANIC] There should be no required methods when composing (" . (join ', ' => @$roles) . ") into (" . $meta->name . ") but instead we found (" . (join ', ' => keys %$required_methods)  . ")"
        if $opts{to} eq 'class' 
        && scalar keys %$required_methods
        && !$meta->is_abstract;

    foreach my $name ( keys %$methods ) {
        # if we have a method already by that name ...
        if ( $meta->has_method( $name ) ) {
            # if we are a class, the class wins
            next if $opts{to} eq 'class';
            # if we are not a class, (we are a role) and we die with a conflict ...
            die "[mop::PANIC] Role Conflict, cannot compose method ($name) into (" . $meta->name . ") because ($name) already exists"
                if $meta->get_method( $name )->was_aliased_from( @$roles );
        }
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
