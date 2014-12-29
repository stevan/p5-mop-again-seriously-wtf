#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use mop;

our $x;

package Foo {
    use v5.20;
    use warnings;
    use mop isa => 'mop::object';

    sub inc { ++$::x }
    sub dec { --$::x }
}

{
    $x = 1;

    my $foo = Foo->new;

    is($x, 1);
    is($foo->inc, 2);
    is($foo->inc, 3);
    is($x, 3);
    is($foo->dec, 2);
    is($foo->dec, 1);
    is($x, 1);
}

our $y;

package Bar {
    use v5.20;
    use warnings;
    use mop isa => 'mop::object';

    sub get_y;

    sub inc { ++$::y }
    sub dec { --$::y }
}

package Baz {
    use v5.20;
    use warnings;
    use mop isa => 'Bar';

    sub get_y { $::y }
}

{
    $y = 1;

    my $baz = Baz->new;

    is($baz->get_y, 1);
    is($baz->inc, 2);
    is($baz->inc, 3);
    is($baz->get_y, 3);
    is($baz->dec, 2);
    is($baz->dec, 1);
    is($baz->get_y, 1);
}

done_testing;