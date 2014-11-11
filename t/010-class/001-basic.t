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
    use v5.20;
    use warnings;

    sub foo { 'Foo::foo' }
} 
package Bar {
    use v5.20;
    use warnings;

    our $VERSION   = '0.01';
    our $AUTHORITY = 'cpan:STEVAN';

    use base 'Foo';
} 
package Baz { 
    use v5.20;
    use warnings;
    
    our @ISA = ('Bar') 
}

# test them ...

my $Foo = mop::class->new( name => 'Foo' );
isa_ok($Foo, 'mop::class');

isnt($Foo, mop::class->new( name => 'Foo' ), '... they are not always the same instances');

{
    my $FooRole = mop::role->new( name => 'Foo' );
    isa_ok($FooRole, 'mop::role');
    isa_ok($Foo, 'mop::class');
}

my $Bar = mop::class->new( name => 'Bar' );
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
    is($code->body->(), 'Foo::foo', '... got the expected behavior from the &foo method');

    my @methods = $Foo->methods;
    is(scalar @methods, 1, '... got the amount of method we expected');
    is($methods[0]->body, $code->body, '... got the methods we expected in the set');
}

{
    my $foo = $Foo->construct_instance({});
    isa_ok($foo, 'Foo');

    ok(!$foo->can('name'), '... we are not our meta-object');
    ok($foo->can('foo'), '... we are our own object');
}

{
    my $code = $Foo->delete_method('foo');
    ok(defined $code, '... got the deleted &foo method');
    is($code->body->(), 'Foo::foo', '... got the expected behavior from the deleted &foo method');
    ok(!$Foo->has_method('foo'), '... we no longer have a &foo method');

    my @methods = $Foo->methods;
    is(scalar @methods, 0, '... got the amount of method we expected');
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
    my $code = sub { 'Bar::bar' };
    $Bar->add_method( bar => $code );
    ok($Bar->has_method('bar'), '... we now have a &bar method');
    is($Bar->get_method('bar')->body, $code, '... got the same &bar method back');

    my @methods = $Bar->methods;
    is(scalar @methods, 1, '... got the amount of method we expected');
    is($methods[0]->body, $code, '... got the methods we expected in the set');
}

is($Baz->name,       'Baz', '... got the name we expected');
is($Baz->version,    undef, '... got the version we expected');
is($Baz->authority,  undef, '... got the authority we expected');
is_deeply([ $Baz->superclasses ], ['Bar'], '... got the superclasses we expected');
is_deeply([ $Baz->mro ], ['Baz', 'Bar', 'Foo'], '... got the mro we expected');

done_testing;



