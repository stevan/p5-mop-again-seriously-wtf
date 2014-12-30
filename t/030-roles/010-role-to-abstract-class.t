#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

package Foo {
    use v5.20;
    use warnings;
    use mop;

    sub bar;
}

package Gorch {
    use v5.20;
    use warnings;
    use mop 
        isa    => 'mop::object',
        does   => 'Foo';

    BEGIN { our $IS_ABSTRACT = 1 }
}

ok(mop::class->new( name => 'Gorch' )->is_abstract, '... composing a role with still required methods creates an abstract class');
eval { Gorch->new };
like(
    $@,
    qr/^\[mop\:\:PANIC\] Cannot construct instance, the class \(Gorch\) is abstract/,
    '... cannot create an instance of Gorch'
);

done_testing;