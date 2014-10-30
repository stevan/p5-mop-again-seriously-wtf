#!/usr/bin/perl -w

use v5.20;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('mop');
}

BEGIN {
    # set up some test roles ...

    package Bar::Role {
        sub bar { 'Bar::Role::bar' } 
    }

    package Baz::Role {
        sub baz { 'Baz::Role::baz' } 
    }

    # set up a test class ...

    package Foo {
        use mop::internal::finalize;

        our @DOES = ('Bar::Role', 'Baz::Role');

        sub foo { 'Foo::foo' }
    } 
}

{
    my $Foo = mop::role->new( name => 'Foo' );
    isa_ok($Foo, 'mop::role');

    ok($Foo->has_method('foo'), '... the foo method is there');

    ok($Foo->has_method('bar'), '... the bar method was composed properly');
    ok($Foo->has_method('baz'), '... the baz method was composed properly');
}


done_testing;



