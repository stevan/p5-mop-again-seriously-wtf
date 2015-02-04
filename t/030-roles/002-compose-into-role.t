#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

package Foo {
    use v5.20;
    use warnings;
    use mop;

    has 'bar' => (default => sub { 'bar' });

    sub bar { $_[0]->{bar} }
}

package Baz {
    use v5.20;
    use warnings;
    use mop;

    with 'Foo';

    sub baz ($self) { join ", "  => $self->bar, 'baz' }
}

package Gorch {
    use v5.20;
    use warnings;
    use mop;

    extends 'mop::object';
       with 'Baz';
}

ok( mop::role->new( name => 'Baz' )->does_role( 'Foo' ), '... Baz does the Foo role');

my $bar_method = mop::role->new( name => 'Baz' )->get_method('bar');
ok( $bar_method->isa( 'mop::method' ), '... got a method object' );
is( $bar_method->name, 'bar', '... got the method we expected' );

my $bar_attribute = mop::role->new( name => 'Baz' )->get_attribute('bar');
ok( $bar_attribute->isa( 'mop::attribute' ), '... got an attribute object' );
is( $bar_attribute->name, 'bar', '... got the attribute we expected' );

my $baz_method = mop::role->new( name => 'Baz' )->get_method('baz');
ok( $baz_method->isa( 'mop::method' ), '... got a method object' );
is( $baz_method->name, 'baz', '... got the method we expected' );

my $gorch = Gorch->new;
isa_ok($gorch, 'Gorch');
is_deeply([ mop::role->new( name => 'Gorch' )->roles ], [ 'Baz' ], '... got the list of expected roles');
ok($gorch->DOES('Baz'), '... gorch does Baz');
ok($gorch->DOES('Foo'), '... gorch does Foo');

is($gorch->baz, 'bar, baz', '... got the expected output');

done_testing;