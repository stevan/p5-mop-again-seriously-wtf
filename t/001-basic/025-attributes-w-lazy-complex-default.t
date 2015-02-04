#!perl

use strict;
use warnings;

use Test::More;


=pod

...

=cut

package Foo {
    use v5.20;
    use warnings;
    use mop;

    extends 'mop::object';

    has 'bar';

    sub bar ($self) { $self->{bar} //= [ 5, 10, 15 ] }

    sub has_bar   ($self)     { defined $self->{bar} }
    sub set_bar   ($self, $b) { $self->{bar} = $b  }
    sub init_bar  ($self)     { $self->{bar} = [ 1, 2, 3 ] }
    sub clear_bar ($self)     { undef $self->{bar} }
}

{
    my $foo = Foo->new;
    ok( $foo->isa( 'Foo' ), '... the object is from class Foo' );

    ok(!$foo->has_bar, '... no bar is set');
    is_deeply($foo->bar, [ 5, 10, 15 ], '... values are defined');

    my $bar_1 = $foo->bar;

    ok($foo->has_bar, '... bar is now set');

    eval { $foo->init_bar };
    is($@, "", '... initialized bar without error');
    is_deeply($foo->bar, [ 1, 2, 3 ], '... value is initialized by the init_bar method');

    eval { $foo->set_bar([1000]) };
    is($@, "", '... set bar without error');
    is_deeply($foo->bar, [1000], '... value is set by the set_bar method');

    eval { $foo->clear_bar };
    is($@, "", '... set bar without error');
    ok(!$foo->has_bar, '... no bar is set');
    is_deeply($foo->bar, [ 5, 10, 15 ], '... values are defined');

    isnt($foo->bar, $bar_1, '... new values are regnerated by the lazy init');
}

{
    my $foo = Foo->new( bar => [10] );
    ok( $foo->isa( 'Foo' ), '... the object is from class Foo' );

    ok($foo->has_bar, '... a bar is set');
    is_deeply($foo->bar, [10], '... values are initialized via the constructor');

    eval { $foo->init_bar };
    is($@, "", '... initialized bar without error');
    ok($foo->has_bar, '... a bar is set');
    is_deeply($foo->bar, [1, 2, 3], '... value is initialized by the init_bar method');

    eval { $foo->set_bar([1000]) };
    is($@, "", '... set bar without error');
    ok($foo->has_bar, '... a bar is set');
    is_deeply($foo->bar, [1000], '... value is set by the set_bar method');

    eval { $foo->clear_bar };
    is($@, "", '... set bar without error');
    ok(!$foo->has_bar, '... no bar is set');
    is_deeply($foo->bar, [ 5, 10, 15 ], '... values are defined');
}


done_testing;