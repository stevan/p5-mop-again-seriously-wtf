package mop;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use mop::internal::util;
use mop::internal::package;

use mop::object;
use mop::method;
use mop::role;
use mop::class;

our $BOOTSTRAPPED = 0;

sub import {
    return if $BOOTSTRAPPED;
    # mark us as boostrapped 
    $BOOTSTRAPPED = mop::class->new( name => 'mop::class' )->is_closed;
}

1;

__END__