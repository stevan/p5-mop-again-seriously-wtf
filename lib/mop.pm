package mop;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use mop::object;
use mop::method;
use mop::role;
use mop::class;

use mop::internal::util;

our $BOOTSTRAPPED = 0;

sub import {
    return if $BOOTSTRAPPED;
    # mark us as boostrapped 
    $BOOTSTRAPPED = 1;
}

sub meta ($instance) {
    mop::class->new( name => ref( $instance ) || $instance );
}

1;

__END__