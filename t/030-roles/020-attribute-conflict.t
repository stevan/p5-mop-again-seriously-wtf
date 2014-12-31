#!perl

use strict;
use warnings;

use Test::More;

package Foo {
    use v5.20;
    use warnings;
    use mop;

    has 'foo';
}

{
    eval q[
        package Foo2 {
            use v5.20;
            use warnings;
            use mop does => 'Foo';
            has 'foo';
        }
    ];
    like("$@", qr/^\[mop\:\:PANIC\] Role Conflict, cannot compose attribute \(foo\) into \(Foo2\) because \(foo\) already exists/, '... got the expected error message (role on role)');
    $@ = undef;
}

package Bar {
    use v5.20;
    use warnings;
    use mop;

    has 'foo';
}

{
    eval q[
        package FooBar {
            use v5.20;
            use warnings;
            use mop does => 'Foo', 'Bar';
        }
    ];
    like("$@", qr/^\[mop\:\:PANIC\] There should be no conflicting attributes when composing \(Foo, Bar\) into \(FooBar\)/, '... got the expected error message (composite role)');
    $@ = undef;
}


{
    eval q[
        package FooBaz {
            use v5.20;
            use warnings;
            use mop 
                isa  => 'mop::object',
                does => 'Foo';

            has 'foo';
        }
    ];
    like("$@", qr/^\[mop\:\:PANIC\] Role Conflict, cannot compose attribute \(foo\) into \(FooBaz\) because \(foo\) already exists/, '... got the expected error message (role on class)');
    $@ = undef;
}

done_testing;
