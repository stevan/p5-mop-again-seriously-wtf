#!perl

use strict;
use warnings;

use Test::More;

use mop;

package Foo {
    use v5.20;
    use warnings;
    use mop;

    sub foo { 'Foo::foo' }
}

package Foo2 {
    use v5.20;
    use warnings;
    use mop does => 'Foo';

    sub foo { 'Foo2::foo' }
}

package Bar {
    use v5.20;
    use warnings;
    use mop;

    sub foo { 'Bar::foo' }
}

TODO: {
    local $TODO = '... need to think about these some more';

    is_deeply([mop::role->new( name => 'Foo2' )->required_methods], [], '... no method conflict here');
    ok(mop::role->new( name => 'Foo2' )->has_method('foo'), '... Foo2 has the foo method');
}

package FooBar {
    use v5.20;
    use warnings;
    use mop does => 'Foo', 'Bar';
}

TODO: {
    local $TODO = '... need to think about these some more';

    is_deeply([mop::role->new( name => 'FooBar' )->required_methods], ['foo'], '... method conflict between roles results in required method');
    ok(!mop::role->new( name => 'FooBar' )->has_method('foo'), '... FooBar does not have the foo method');
    ok(mop::role->new( name => 'Foo' )->has_method('foo'), '... Foo still has the foo method');
    ok(mop::role->new( name => 'Bar' )->has_method('foo'), '... Bar still has the foo method');
}

fail('... fix the code here');
=pod

class Baz with Foo {
    method foo { 'Baz::foo' }
}

is_deeply([mop::class->new( name => 'Baz' )->required_methods], [], '... no method conflict between class/role');
ok(mop::meta('Foo')->has_method('foo'), '... Foo still has the foo method');
is(Baz->new->foo, 'Baz::foo', '... got the right method');

class Gorch with Foo, Bar is abstract {}

ok(mop::class->new( name => 'Gorch' )->is_abstract, '... method conflict between roles results in required method (and an abstract class)');
is_deeply([mop::meta('Gorch')->required_methods], ['foo'], '... method conflict between roles results in required method');

role WithFinalize1 {
    method FINALIZE { }
}

role WithFinalize2 {
    method FINALIZE { }
}

eval "class MultipleFinalizeMethods with WithFinalize1, WithFinalize2 { }";
like($@, qr/Required method\(s\) \[FINALIZE\] are not allowed in MultipleFinalizeMethods unless class is declared abstract/);

role WithNew1 {
    method new { }
}

role WithNew2 {
    method new { }
}

eval "class MultipleNewMethods with WithNew1, WithNew2 { }";
like($@, qr/Required method\(s\) \[new\] are not allowed in MultipleNewMethods unless class is declared abstract/);

=cut

done_testing;
