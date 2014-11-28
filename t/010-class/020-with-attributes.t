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

    our %HAS; BEGIN {
        %HAS = (
            bar => sub { 'BAR' },
            baz => sub { 'BAZ' },
        )
    };
} 

# test them ...

my $Foo = mop::class->new( name => 'Foo' );
isa_ok($Foo, 'mop::class');

{
    my @attributes = sort { $a->name cmp $b->name } $Foo->attributes;

    is((scalar @attributes), 2, '... got the two attributes we expected');

    foreach my $attr ( @attributes ) {
        isa_ok($attr, 'mop::attribute');    
        is(ref $attr->initializer, 'CODE', '... got the initializer reftype');
    }

    is($attributes[0]->name, 'bar', '... got the attribute name');
    is($attributes[0]->initializer->(), 'BAR', '... got the attribute initializer value');
    ok($Foo->has_attribute('bar'), '... the class agrees that we do have this attribute');

    is($attributes[1]->name, 'baz', '... got the attribute name');
    is($attributes[1]->initializer->(), 'BAZ', '... got the attribute initializer value');
    ok($Foo->has_attribute('baz'), '... the class agrees that we do have this attribute');
}

$Foo->add_attribute( gorch => sub { 'GORCH' } );

{
    my @attributes = sort { $a->name cmp $b->name } $Foo->attributes;

    is((scalar @attributes), 3, '... got the two attributes we expected');

    foreach my $attr ( @attributes ) {
        isa_ok($attr, 'mop::attribute');    
        is(ref $attr->initializer, 'CODE', '... got the initializer reftype');
    }

    is($attributes[0]->name, 'bar', '... got the attribute name');
    is($attributes[0]->initializer->(), 'BAR', '... got the attribute initializer value');
    ok($Foo->has_attribute('bar'), '... the class agrees that we do have this attribute');

    is($attributes[1]->name, 'baz', '... got the attribute name');
    is($attributes[1]->initializer->(), 'BAZ', '... got the attribute initializer value');
    ok($Foo->has_attribute('baz'), '... the class agrees that we do have this attribute');

    is($attributes[2]->name, 'gorch', '... got the attribute name');
    is($attributes[2]->initializer->(), 'GORCH', '... got the attribute initializer value');
    ok($Foo->has_attribute('gorch'), '... the class agrees that we do have this attribute');
}

$Foo->alias_attribute( bling => sub { 'BLING' } );

{
    my @attributes = sort { $a->name cmp $b->name } $Foo->attributes;

    is((scalar @attributes), 3, '... got the two attributes we expected');

    foreach my $attr ( @attributes ) {
        isa_ok($attr, 'mop::attribute');    
        is(ref $attr->initializer, 'CODE', '... got the initializer reftype');
    }

    is($attributes[0]->name, 'bar', '... got the attribute name');
    is($attributes[0]->initializer->(), 'BAR', '... got the attribute initializer value');
    ok($Foo->has_attribute('bar'), '... the class agrees that we do have this attribute');

    is($attributes[1]->name, 'baz', '... got the attribute name');
    is($attributes[1]->initializer->(), 'BAZ', '... got the attribute initializer value');
    ok($Foo->has_attribute('baz'), '... the class agrees that we do have this attribute');

    is($attributes[2]->name, 'gorch', '... got the attribute name');
    is($attributes[2]->initializer->(), 'GORCH', '... got the attribute initializer value');
    ok($Foo->has_attribute('gorch'), '... the class agrees that we do have this attribute');

    ok(exists $Foo::HAS{'bling'}, '... that said, we do have the attribute though');
    is($Foo::HAS{'bling'}->(), 'BLING', '... and it works as expected');
    ok(!$Foo->has_attribute('bling'), '... the class agrees that we do NOT have this attribute');
}

done_testing;


