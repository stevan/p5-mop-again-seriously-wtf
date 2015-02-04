#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

package Foo {

    use v5.20;
    use warnings;
    use mop;

    extends 'mop::object';    

    has 'foo';
    has 'bar';

    sub bar { 'Foo::bar' }

    sub baz ($self, $x) {
        join "::" => $self, 'baz', $x
    }

    sub test ($self, $x = undef) {
        $self->{foo} = $x if $x;
        $self->{foo};
    }

    sub test_bar ($self) { $self->bar . "x2" }
}

is_deeply(
    mro::get_linear_isa('Foo'),
    [ 'Foo', 'mop::object' ],
    '... got the expected linear isa'
);

is(Foo->bar, 'Foo::bar', '... simple test works');
is(Foo->baz('hi'), 'Foo::baz::hi', '... another test works');

my $foo = Foo->new;
isa_ok($foo, 'Foo');

is($foo->bar, 'Foo::bar', '... simple test works');
is($foo->baz('hi'), $foo . '::baz::hi', '... another test works');

is($foo->test(10), 10, '... got the right value');
is($foo->test, 10, '... got the right value');
is($foo->test(20), 20, '... got the right value');
is($foo->test, 20, '... got the right value');
is_deeply($foo->test([ 1, 2, 3 ]), [ 1, 2, 3 ], '... got the right value');
is_deeply($foo->test, [ 1, 2, 3 ], '... got the right value');

is($foo->test_bar, 'Foo::barx2', '... got the value we expected');

done_testing;