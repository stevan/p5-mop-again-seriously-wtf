#!/usr/bin/perl -w

use v5.20;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('mop');
}

# set up some test packages ...

package Foo {
    use v5.20;
    use warnings;

    our %HAS; 
    BEGIN { 
        %HAS = ( bar => sub { 'Foo::BAR' } );
    }
} 

package Bar {
    use v5.20;
    use warnings;

    use mop::internal::util FINALIZE => 'UNITCHECK';  

    our (@ISA, %HAS); 
    BEGIN { 
        @ISA = ('Foo');
        %HAS = ( baz => sub { 'Bar::BAZ' } );
    }

    BEGIN { 
        our @FINALIZERS = (sub {
            mop::internal::util::GATHER_ALL_ATTRIBUTES(
                mop::class->new( name => __PACKAGE__ )
            );
        })
    }
} 

# test them ...

my $Foo = mop::class->new( name => 'Foo' );
isa_ok($Foo, 'mop::class');

my $Bar = mop::class->new( name => 'Bar' );
isa_ok($Bar, 'mop::class');

{
    my @attributes = $Foo->attributes;

    is((scalar @attributes), 1, '... got the one attribute we expected');

    foreach my $attr ( @attributes ) {
        isa_ok($attr, 'mop::attribute');    
        is(ref $attr->initializer, 'CODE', '... got the initializer reftype');
    }

    is($attributes[0]->name, 'bar', '... got the attribute name');
    is($attributes[0]->initializer->(), 'Foo::BAR', '... got the attribute initializer value');
    ok($Foo->has_attribute('bar'), '... the class agrees that we do have this attribute');
}

{
    my @attributes = $Bar->attributes;

    is((scalar @attributes), 1, '... got the one attribute we expected');

    foreach my $attr ( @attributes ) {
        isa_ok($attr, 'mop::attribute');    
        is(ref $attr->initializer, 'CODE', '... got the initializer reftype');
    }

    is($attributes[0]->name, 'baz', '... got the attribute name');
    is($attributes[0]->initializer->(), 'Bar::BAZ', '... got the attribute initializer value');
    ok($Bar->has_attribute('baz'), '... the class agrees that we do have this attribute');
    ok(!$Bar->has_attribute('bar'), '... the class agrees that we do not have this attribute');
    ok($Bar->has_attribute_alias('bar'), '... the class agrees that we do have an alias of this attribute');
}

{
    my $foo = $Foo->construct_instance({});
    isa_ok($foo, $Foo->name);

    is_deeply([ keys %$foo ], ['bar'], '... got the expected slots in the instance');
    is($foo->{bar}, 'Foo::BAR', '... got the value expected in `bar`');
}

{
    my $bar = $Bar->construct_instance({});
    isa_ok($bar, $Bar->name);

    is_deeply([ sort keys %$bar ], ['bar', 'baz'], '... got the expected slots in the instance');
    is($bar->{bar}, 'Foo::BAR', '... got the value expected in `bar`');
    is($bar->{baz}, 'Bar::BAZ', '... got the value expected in `baz`');
}

done_testing;


