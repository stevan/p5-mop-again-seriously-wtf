#!/usr/bin/perl -w

use v5.20;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('mop::class');
}

package Foo 0.01 {} 
package Bar {

    our $VERSION   = '0.01';
    our $AUTHORITY = 'cpan:STEVAN';

    use base 'Foo';
} 
package Baz { our @ISA = ('Bar') }

my $Foo = mop::class->new( 'Foo' );
isa_ok($Foo, 'mop::class');

my $Bar = mop::class->new( 'Bar' );
isa_ok($Bar, 'mop::class');

my $Baz = mop::class->new( 'Baz' );
isa_ok($Baz, 'mop::class');

is($Foo->name,       'Foo',  '... got the name we expected');
is($Foo->version,    '0.01', '... got the version we expected');
is($Foo->authority,   undef, '... got the authority we expected');
is_deeply([ $Foo->superclasses ], [], '... got the superclasses we expected');

is($Bar->name,       'Bar',         '... got the name we expected');
is($Bar->version,    '0.01',        '... got the version we expected');
is($Bar->authority,  'cpan:STEVAN', '... got the authority we expected');
is_deeply([ $Bar->superclasses ], ['Foo'], '... got the superclasses we expected');

is($Baz->name,       'Baz', '... got the name we expected');
is($Baz->version,    undef, '... got the version we expected');
is($Baz->authority,  undef, '... got the authority we expected');
is_deeply([ $Baz->superclasses ], ['Bar'], '... got the superclasses we expected');

my $Class = mop::class->new('mop::class');
isa_ok($Class, 'mop::class');

is($Class, $Class->class, '... Class is an instance of Class');

done_testing;