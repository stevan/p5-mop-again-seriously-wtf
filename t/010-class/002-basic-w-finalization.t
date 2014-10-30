#!/usr/bin/perl -w

use v5.20;
use warnings;

use Test::More;
use Test::Fatal;
use Data::Dumper;

BEGIN {
    use_ok('mop');
}

# set up some test packages ...

package Foo 0.01 {
    use mop::internal::finalize;

    sub foo { 'Foo::foo' }
} 

package Bar {
    use mop::internal::finalize;

    use Scalar::Util qw[ blessed ];

    our $VERSION   = '0.01';
    our $AUTHORITY = 'cpan:STEVAN';

    use base 'Foo';
} 

package Baz { 
    use mop::internal::finalize;

    our @ISA = ('Bar') 
}

# test them ...

my $Foo = mop::class->new( name => 'Foo' );
isa_ok($Foo, 'mop::class');

# also contruct the meta this way ...
my $Bar = mop::meta( 'Bar' );
isa_ok($Bar, 'mop::class');

my $Baz = mop::class->new( name => 'Baz' );
isa_ok($Baz, 'mop::class');

is($Foo->name,       'Foo',  '... got the name we expected');
is($Foo->version,    '0.01', '... got the version we expected');
is($Foo->authority,   undef, '... got the authority we expected');
is_deeply([ $Foo->superclasses ], [], '... got the superclasses we expected');
is_deeply([ $Foo->mro ], ['Foo'], '... got the mro we expected');
ok($Foo->has_method('foo'), '... we have a &foo method');
ok(!$Foo->has_method('bar'), '... we do not have a &bar method');

{
    my $code = $Foo->get_method('foo');
    ok(defined $code, '... got the &foo method');
    is($code->(), 'Foo::foo', '... got the expected behavior from the &foo method');

    my @methods = $Foo->methods;
    is(scalar @methods, 1, '... got the amount of method we expected');
    is($methods[0], $code, '... got the methods we expected in the set');
}

{
    my $foo = $Foo->construct_instance({});
    isa_ok($foo, 'Foo');

    ok(!$foo->can('name'), '... we are not our meta-object');
    ok($foo->can('foo'), '... we are our own object');

    is(mop::meta($foo), $Foo, '... the metaclass is as expected');
}

{
    like(
        exception { $Foo->delete_method('foo') },
        qr/^Modification of a read-only value attempted/,
        '... got the expection we expected (for method deletion)'
    );

    ok($Foo->has_method('foo'), '... we still have a &foo method');

    my @methods = $Foo->methods;
    is(scalar @methods, 1, '... got the amount of method we expected');
}

is($Bar->name,       'Bar',         '... got the name we expected');
is($Bar->version,    '0.01',        '... got the version we expected');
is($Bar->authority,  'cpan:STEVAN', '... got the authority we expected');
is_deeply([ $Bar->superclasses ], ['Foo'], '... got the superclasses we expected');
is_deeply([ $Bar->mro ], ['Bar', 'Foo'], '... got the mro we expected');
ok(!$Bar->has_method('bar'), '... we do not have a &bar method');
ok(!$Bar->has_method('blessed'), '... we do not have the imported &blessed function showing up as a method');

{
    my @methods = $Bar->methods;
    is(scalar @methods, 0, '... got the amount of method we expected');
}

{
    like(
        exception { $Bar->add_method( bar => sub { 'Bar::bar' } ) },
        qr/^\[PACKAGE FINALIZED\] The package \(Bar\) has been finalized, attempt to store into key \(bar\) is not allowed/,
        '... got the exception we expected (for trying to add a method)'
    );
    ok(!$Bar->has_method('bar'), '... we do not have a &bar method');

    my @methods = $Bar->methods;
    is(scalar @methods, 0, '... got the amount of method we expected');
}

is($Baz->name,       'Baz', '... got the name we expected');
is($Baz->version,    undef, '... got the version we expected');
is($Baz->authority,  undef, '... got the authority we expected');
is_deeply([ $Baz->superclasses ], ['Bar'], '... got the superclasses we expected');
is_deeply([ $Baz->mro ], ['Baz', 'Bar', 'Foo'], '... got the mro we expected');

done_testing;


