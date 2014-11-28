package mop::internal::util;

use v5.20;
use mro;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures', 'experimental::postderef';

use Devel::Hook ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub import ($class, @args) {
    my $calling_pkg = caller;
    if ( @args ) {
        if ( $args[0] eq 'FINALIZE' ) {
            INSTALL_FINALIZATION_RUNNER_FOR( $calling_pkg )
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

sub INSTALL_FINALIZATION_RUNNER_FOR ($pkg) {
    die "[mop::PANIC] To late to install finalization runner for <$pkg>, current-phase: (${^GLOBAL_PHASE})" 
        unless ${^GLOBAL_PHASE} eq 'START';

    Devel::Hook->push_UNITCHECK_hook(sub { 
        mop::role->new( name => $pkg )->run_all_finalizers; 
    });
}

## Instance construction and destruction 

# TODO:
# add caches here using a `state` var, similar 
# to what we do in GATHER_ALL_ATTRIBUTES below.
# - SL

sub BUILDALL ($instance, $args) {
    foreach my $c ( mro::get_linear_isa( ref $instance )->@* ) {
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
    state $ATTRIBUTES_BEEN_GATHERED_IN = {};

    unless ( exists $ATTRIBUTES_BEEN_GATHERED_IN->{ $meta->name } ) {
        my @mro = $meta->mro;
        shift @mro; # no need to search ourselves ...
        foreach my $super ( map { mop::role->new( name => $_ ) } @mro ) {
            foreach my $attr ( $super->attributes ) {
                $meta->alias_attribute( $attr->name, $attr->initializer ) 
                    unless $meta->has_attribute( $attr->name ) 
                        || $meta->has_attribute_alias( $attr->name );
            }
        }
        $ATTRIBUTES_BEEN_GATHERED_IN->{ $meta->name } = 1;
    }
    # return nothing in void context, it 
    # typically means we are doing this 
    # at compile time or something, so we 
    # need to just skip it
    return unless defined wantarray; 
    # however, if we are calling this 
    # to actually get the values, ...
    my $HAS = $meta->stash->{'HAS'};
    return () unless $HAS;
    return $HAS->*{'HASH'}->%*;
}

## Role application and composition

sub APPLY_ROLES ($meta, $roles, %opts) {
    die "[mop::PANIC] You must specify what type of object you want roles applied `to`" 
        unless exists $opts{to};

    foreach my $r ( $meta->roles ) {
        die "[mop::PANIC] Could not find role ($_) in the set of roles in $meta (" . $meta->name . ")" 
            unless scalar grep { $r eq $_ } @$roles;
    }

    my (
        $methods, 
        $conflicts,
        $required
    ) = COMPOSE_ALL_ROLES( 
        map { mop::role->new( name => $_ ) } @$roles 
    );

    die "[mop::PANIC] There should be no conflicting methods when composing (" . (join ', ' => @$roles) . ") into (" . $meta->name . ")"
        if scalar keys %$conflicts;

    # check the required method set and 
    # see if what we are composing into 
    # happens to fulfill them 
    foreach my $name ( keys $required->%* ) {
        delete $required->{ $name } 
            if $meta->has_method( $name )
    }

    die "[mop::PANIC] There should be no required methods when composing (" . (join ', ' => @$roles) . ") into (" . $meta->name . ")"
        if $opts{to} eq 'class' 
        # TODO:
        # think about checking for Abstract-ness here
        # it could be done with another $opt(ion).
        && scalar keys %$required;

    foreach my $name ( keys $methods->%* ) {
        # if we have a method already by that name ...
        if ( $meta->has_method( $name ) ) {
            # if we are a class, the class wins
            next if $opts{to} eq 'class';
            # if we are not a class, (we are a role) and we die with a conflict ...
            die "[mop::PANIC] Role Conflict, cannot compose method ($name) into (" . $meta->name . ") because ($name) already exists"
                if $meta->has_method( $name );
        }
        $meta->alias_method( $name, $methods->{ $name } );
    }

    # if we still have keys in $required, it is 
    # because we are a role (class would have 
    # died above), so we can just stuff in the 
    # required methods ...
    $meta->add_required_method( $_ ) for keys $required->%*;

    return;
}

sub COMPOSE_ALL_ROLES (@roles) {
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
            # it is a conflict, which means:            
            if ( exists $methods{ $name } ) {
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
                $methods{ $name } = $m;
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
