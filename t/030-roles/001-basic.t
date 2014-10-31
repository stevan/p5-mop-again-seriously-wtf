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
        use mop::internal::util qw[ :FINALIZE ];
        
        our @DOES = ('Bar::Role', 'Baz::Role');

        sub foo { 'Foo::foo' }

        FINALIZE {
            mop::internal::util::APPLY_ROLES( mop::role->new( name => __PACKAGE__ ), \@DOES, to => 'role' );
        }
    } 
}

{
    my $Foo = mop::role->new( name => 'Foo' );
    isa_ok($Foo, 'mop::role');

    is_deeply([ $Foo->roles ], [ 'Bar::Role', 'Baz::Role' ], '... got the list of roles we expected');

    ok($Foo->has_method('foo'), '... the foo method is there');

    is($Foo->get_method('foo')->stash_name, 'Foo', '... got the expected stash_name for &foo');

    ok($Foo->has_method('bar'), '... the bar method was composed properly');
    ok($Foo->has_method('baz'), '... the baz method was composed properly');

    is($Foo->get_method('bar')->stash_name, 'Bar::Role', '... got the expected stash_name for &bar');
    is($Foo->get_method('baz')->stash_name, 'Baz::Role', '... got the expected stash_name for &baz');
}


done_testing;



