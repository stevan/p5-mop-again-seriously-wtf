package mop::internal::util;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use Scalar::Util ();

sub BUILDALL ($instance, $args) {
    foreach my $c ( mro::get_linear_isa( Scalar::Util::blessed( $instance ) )->@* ) {
        if ( my $build = $c->can('BUILD') ) {
            $instance->$build( $args );
        }
    }
    return;
}

sub DEMOLISHALL ($instance)  {
    foreach my $c ( mro::get_linear_isa( Scalar::Util::blessed( $instance ) )->@* ) {
        if ( my $demolish = $c->can('DEMOLISH') ) {
            $instance->$demolish();
        }
    }
    return;
}

1;

__END__
