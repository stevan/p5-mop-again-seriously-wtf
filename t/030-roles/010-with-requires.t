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
        use v5.20;
        use warnings;

        our @REQUIRES = ('foo');

        sub bar { 'Bar::Role::bar' } 
    }

    package Baz::Role {
        use v5.20;
        use warnings;

        sub baz { 'Baz::Role::baz' } 
    }

    # set up a test class ...

    package Foo {
        use v5.20;
        use warnings;
        
        use mop::internal::util 'FINALIZE';

        our @DOES = ('Bar::Role', 'Baz::Role');

        sub foo { 'Foo::foo' }

        BEGIN { 
            our @FINALIZERS = (sub {
                mop::internal::util::APPLY_ROLES( 
                    mop::role->new( name => __PACKAGE__ ), 
                    \@DOES, 
                    to => 'role' 
                );
            });
        }
    } 
}

BEGIN {
    my $BarRole = mop::role->new( name => 'Bar::Role' );
    isa_ok($BarRole, 'mop::role');

    ok($BarRole->requires_method('foo'), '... we require the &foo method');
    ok(!$BarRole->requires_method('gorch'), '... we do not require the &gorch method');

    is_deeply([ $BarRole->required_methods ], ['foo'], '... got the expected result from ->required_methods');

    # NOTE:
    # if this is not added witin the BEGIN 
    # block, then the required_methods in 
    # Foo will only be what Bar::Role had 
    # at UNITCHECK time, which would be 
    # missing the gorch method.
    $BarRole->add_required_method('gorch');

    ok($BarRole->requires_method('gorch'), '... we require the &gorch method');
    is_deeply([ $BarRole->required_methods ], ['foo', 'gorch'], '... got the expected result from ->required_methods');

}

{
    my $Foo = mop::role->new( name => 'Foo' );
    isa_ok($Foo, 'mop::role');

    is_deeply([ $Foo->roles ], [ 'Bar::Role', 'Baz::Role' ], '... got the list of roles we expected');

    ok($Foo->requires_method('gorch'), '... we require the &gorch method');
    is_deeply([ $Foo->required_methods ], ['gorch'], '... got the expected result from ->required_methods');

    ok($Foo->has_method('foo'), '... the foo method is there');

    is($Foo->get_method('foo')->stash_name, 'Foo', '... got the expected stash_name for &foo');

    ok($Foo->has_method('bar'), '... the bar method was composed properly');
    ok($Foo->has_method('baz'), '... the baz method was composed properly');

    is($Foo->get_method('bar')->stash_name, 'Bar::Role', '... got the expected stash_name for &bar');
    is($Foo->get_method('baz')->stash_name, 'Baz::Role', '... got the expected stash_name for &baz');
}


done_testing;



