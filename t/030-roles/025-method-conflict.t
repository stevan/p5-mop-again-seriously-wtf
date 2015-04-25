#!perl

use strict;
use warnings;

use Test::More;

package Foo {
    use Moxie;

    sub foo { 'Foo::foo' }
}

package Foo2 {
    use Moxie;

    with 'Foo';

    sub foo { 'Foo2::foo' }
}

package Bar {
    use Moxie;

    sub foo { 'Bar::foo' }
}


{
    my $Foo2 = mop::role->new( name => 'Foo2' );
    is_deeply([$Foo2->required_methods], [], '... no method conflict here');
    ok($Foo2->has_method('foo'), '... Foo2 has the foo method');
    is($Foo2->get_method('foo')->body->(), 'Foo2::foo', '... the method in Foo2 is as we expected');
}

package FooBar {
    use Moxie;

    with 'Foo', 'Bar';
}

{
    my ($FooBar, $Foo, $Bar) = map { mop::role->new( name => $_ ) } qw[ FooBar Foo Bar ];
    is_deeply([$FooBar->required_methods], ['foo'], '... method conflict between roles results in required method');
    ok(!$FooBar->has_method('foo'), '... FooBar does not have the foo method');
    ok($Foo->has_method('foo'), '... Foo still has the foo method');
    ok($Bar->has_method('foo'), '... Bar still has the foo method');
}

package FooBarClass {
    use Moxie;

    extends 'mop::object';
       with 'Foo', 'Bar';

    sub foo { 'FooBarClass::foo' }
}

{
    my $FooBarClass = mop::class->new( name => 'FooBarClass' );
    my ($Foo, $Bar) = map { mop::role->new( name => $_ ) } qw[ Foo Bar ];
    is_deeply([$FooBarClass->required_methods], [], '... method conflict between roles results in required method');
    ok($FooBarClass->has_method('foo'), '... FooBarClass does have the foo method');
    is($FooBarClass->get_method('foo')->body->(), 'FooBarClass::foo', '... FooBarClass foo method is what makes sense');
    ok($Foo->has_method('foo'), '... Foo still has the foo method');
    ok($Bar->has_method('foo'), '... Bar still has the foo method');
}

{
    local $@ = undef;
    eval q[
        package FooBarBrokenClass1 {
            use Moxie;

            extends 'mop::object';
               with 'Foo', 'Bar';
        }
    ];
    like(
        "$@",
        qr/^\[mop\:\:PANIC\] There should be no conflicting methods when composing \(Foo, Bar\) into the class \(FooBarBrokenClass1\) but instead we found \(foo\)/,
        '... got the exception we expected'
    );
}

{
    local $@ = undef;
    eval q[
        package Gorch {
            use Moxie;

            extends 'mop::object';
               with 'Foo', 'Bar';

            BEGIN {
                mop::internal::opaque::set_at_slot(
                    \%Gorch::,
                    'is_abstract', 
                    1
                );                
            };
        }
    ];
    ok(!$@, '... no exception because the class is declared abstract');

    my $Gorch = mop::class->new( name => 'Gorch' );
    my ($Foo, $Bar) = map { mop::role->new( name => $_ ) } qw[ Foo Bar ];
    is_deeply([$Gorch->required_methods], ['foo'], '... method conflict between roles results in required method');
    ok(!$Gorch->has_method('foo'), '... Gorch does not have the foo method');
    ok($Foo->has_method('foo'), '... Foo still has the foo method');
    ok($Bar->has_method('foo'), '... Bar still has the foo method');
}

package Baz {
    use Moxie;

    extends 'mop::object';
       with 'Foo';

    sub foo { 'Baz::foo' }
}

{
    my ($Baz, $Foo) = map { mop::class->new( name => $_ ) } qw[ Baz Foo ];
    is_deeply([$Baz->required_methods], [], '... no method conflict between class/role');
    ok($Foo->has_method('foo'), '... Foo still has the foo method');
    is(Baz->new->foo, 'Baz::foo', '... got the right method');
}

done_testing;
