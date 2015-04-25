#!perl

use strict;
use warnings;

use Test::More;

package Foo {
    use Moxie;

    extends 'mop::object';

    BEGIN { 
        mop::internal::opaque::set_at_slot( 
            \%Foo::, 
            'is_abstract',
            1 
        );
    }
}

ok(mop::class->new( name => 'Foo' )->is_abstract, '... Foo is an abstract class');

eval { Foo->new };
like(
    $@,
    qr/^\[mop\:\:PANIC\] Cannot construct instance, the class \(Foo\) is abstract/,
    '... cannot create an instance of abstract class Foo'
);

package Bar {
    use Moxie;

    extends 'Foo';
}

ok(!mop::class->new( name => 'Bar' )->is_abstract, '... Bar is not an abstract class');

{
    my $bar = eval { Bar->new };
    is($@, "", '... we can create an instance of Bar');
    isa_ok($bar, 'Bar');
    isa_ok($bar, 'Foo');
}

done_testing;