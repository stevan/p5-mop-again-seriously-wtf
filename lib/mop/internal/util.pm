package mop::internal::util;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

## ...

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

## ...

sub APPLY_ROLES ($meta, @roles) {
    my (
        $methods, 
        $conflicts,
        $required
    ) = COMPOSE_ALL_ROLES( 
        map { mop::role->new( name => $_ ) } @roles 
    );

    die "[PANIC] There should be no conflicting methods for " . $meta->name . " role composition"
        if scalar keys %$conflicts;

    die "[PANIC] There should be no required methods for " . $meta->name . " role composition"
        if scalar keys %$required;

    foreach my $name ( keys %$methods ) {
        $meta->alias_method( $name, $methods->{ $name } );
    }
}

sub COMPOSE_ALL_ROLES (@roles) {
    my (%methods, %conflicts, %required);
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
    return \%methods, \%conflicts, \%required;
}

1;

__END__
