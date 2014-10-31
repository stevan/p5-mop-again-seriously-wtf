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
    $BOOTSTRAPPED = mop::class->new( name => 'mop::class' )->is_closed;
}

1;

__END__