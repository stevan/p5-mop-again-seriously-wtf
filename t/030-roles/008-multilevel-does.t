#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

package Foo {
    use v5.20;
    use warnings;
    use mop;
}

package Bar { 
    use v5.20;
    use warnings;
    use mop does => 'Foo';
}

package Baz {
    use v5.20;
    use warnings;
    use mop
        isa  => 'mop::object',
        does => 'Bar';
}

ok(Baz->DOES('Bar'), '... Baz DOES Bar');
ok(Baz->DOES('Foo'), '... Baz DOES Foo');

package R1 { 
    use v5.20;
    use warnings;
    use mop;
}

package R2 {
    use v5.20;
    use warnings;
    use mop;
}

package R3 { 
    use v5.20;
    use warnings;
    use mop does => 'R1', 'R2';
}

package C1 { 
    use v5.20;
    use warnings;
    use mop 
        isa  => 'mop::object',
        does => 'R3';
}

ok(C1->DOES('R3'), '... C1 DOES R3');
ok(C1->DOES('R2'), '... C1 DOES R2');
ok(C1->DOES('R1'), '... C1 DOES R1');

done_testing;