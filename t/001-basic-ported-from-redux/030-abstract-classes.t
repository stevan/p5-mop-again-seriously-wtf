#!perl

use strict;
use warnings;

use Test::More;

use mop ();

package Foo {
    use v5.20;
    use warnings;
    use mop isa => 'mop::object';

    sub bar;
}

ok(mop::class->new( name => 'Foo' )->requires_method('bar'), '... bar is a required method');
ok(mop::class->new( name => 'Foo' )->is_abstract, '... Foo is an abstract class');

eval { Foo->new };
like(
    $@,
    qr/^\[mop\:\:PANIC\] Cannot construct instance, the class \(Foo\) is abstract/,
    '... cannot create an instance of abstract class Foo'
);

package Bar {
    use v5.20;
    use warnings;
    use mop isa => 'Foo';

    sub bar { 'Bar::bar' }
}

ok(!mop::class->new( name => 'Bar' )->requires_method('bar'), '... bar is a not required method');
ok(!mop::class->new( name => 'Bar' )->is_abstract, '... Bar is not an abstract class');

{
    my $bar = eval { Bar->new };
    is($@, "", '... we can create an instance of Bar');
    isa_ok($bar, 'Bar');
    isa_ok($bar, 'Foo');
}

package Baz {
    use v5.20;
    use warnings;
    use mop isa => 'Bar';

    sub baz;
}

ok(!mop::class->new( name => 'Baz' )->requires_method('bar'), '... bar is a not required method');
ok(mop::class->new( name => 'Baz' )->requires_method('baz'), '... baz is a required method');
ok(mop::class->new( name => 'Baz' )->is_abstract, '... Baz is an abstract class');

eval { Baz->new };
like(
    $@,
    qr/^\[mop\:\:PANIC\] Cannot construct instance, the class \(Baz\) is abstract/,
    '... cannot create an instance of abstract class Baz'
);

package Gorch {
    use v5.20;
    use warnings;
    use mop isa => 'Foo';
}

ok(mop::class->new( name => 'Gorch' )->requires_method('bar'), '... bar is a required method');
ok(mop::class->new( name => 'Gorch' )->is_abstract, '... Gorch is an abstract class');

eval { Gorch->new };
like(
    $@,
    qr/^\[mop\:\:PANIC\] Cannot construct instance, the class \(Gorch\) is abstract/,
    '... cannot create an instance of abstract class Gorch'
);

done_testing;