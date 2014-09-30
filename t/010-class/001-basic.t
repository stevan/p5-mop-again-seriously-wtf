#!/usr/bin/perl -w

use v5.20;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('mop');
}

# set up some test packages ...

package Foo 0.01 {
    sub foo { 'Foo::foo' }
} 
package Bar {

    our $VERSION   = '0.01';
    our $AUTHORITY = 'cpan:STEVAN';

    use base 'Foo';
} 
package Baz { our @ISA = ('Bar') }

# test them ...

my $Foo = mop::class->new( name => 'Foo' );
isa_ok($Foo, 'mop::class');
isa_ok($Foo, 'mop::object');

# also contruct the meta this way ...
my $Bar = mop::meta( 'Bar' );
isa_ok($Bar, 'mop::class');
isa_ok($Bar, 'mop::object');

my $Baz = mop::class->new( name => 'Baz' );
isa_ok($Baz, 'mop::class');
isa_ok($Baz, 'mop::object');

is($Foo->name,       'Foo',  '... got the name we expected');
is($Foo->version,    '0.01', '... got the version we expected');
is($Foo->authority,   undef, '... got the authority we expected');
is_deeply([ $Foo->superclasses ], [], '... got the superclasses we expected');
is_deeply([ $Foo->mro ], ['Foo'], '... got the mro we expected');

{
    my $foo = $Foo->construct_instance({});
    isa_ok($foo, 'Foo');

    ok(!$foo->can('name'), '... we are not our meta-object');
    ok($foo->can('foo'), '... we are our own object');

    is(mop::meta($foo), $Foo, '... the metaclass is as expected');
}

is($Bar->name,       'Bar',         '... got the name we expected');
is($Bar->version,    '0.01',        '... got the version we expected');
is($Bar->authority,  'cpan:STEVAN', '... got the authority we expected');
is_deeply([ $Bar->superclasses ], ['Foo'], '... got the superclasses we expected');
is_deeply([ $Bar->mro ], ['Bar', 'Foo'], '... got the mro we expected');

is($Baz->name,       'Baz', '... got the name we expected');
is($Baz->version,    undef, '... got the version we expected');
is($Baz->authority,  undef, '... got the authority we expected');
is_deeply([ $Baz->superclasses ], ['Bar'], '... got the superclasses we expected');
is_deeply([ $Baz->mro ], ['Baz', 'Bar', 'Foo'], '... got the mro we expected');


done_testing;



