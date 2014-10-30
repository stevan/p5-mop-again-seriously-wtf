package mop;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use mop::object;
use mop::method;
use mop::role;
use mop::class;

use mop::internal::finalize ();
use mop::internal::util     ();

use Scalar::Util ();

our $BOOTSTRAPPED = 0;

sub import {
    return if $BOOTSTRAPPED;

    mop::internal::finalize->import_into( 'mop::class' );
    mop::internal::finalize->import_into( 'mop::object' );
    mop::internal::finalize->import_into( 'mop::method' );
    mop::internal::finalize->import_into( 'mop::role' );    

    # mark us as boostrapped 
    $BOOTSTRAPPED = 1;
}

sub meta ($instance) {
    mop::class->new( name => Scalar::Util::blessed( $instance ) || $instance );
}

1;

__END__