#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

package Foo {
    use v5.20;
    use warnings;
    use mop;

    sub bar;
}

package Gorch {
    use v5.20;
    use warnings;
    use mop; 
    
    extends 'mop::object';
       with 'Foo';

    BEGIN { our $IS_ABSTRACT = 1 }
}

package Bar {
    use v5.20;
    use warnings;
    use mop;

    extends 'Gorch';
}

{
    my $meta = mop::class->new( name => 'Gorch' );
    ok($meta->is_abstract, '... composing a role with still required methods creates an abstract class');
    is_deeply(
        [ $meta->required_methods ],
        [ 'bar' ],
        '... got the list of expected required methods for Gorch'
    );
    eval { Gorch->new };
    like(
        $@,
        qr/^\[mop\:\:PANIC\] Cannot construct instance, the class \(Gorch\) is abstract/,
        '... cannot create an instance of Gorch'
    );
}

{
    my $meta = mop::class->new( name => 'Bar' );
    ok($meta->is_abstract, '... composing a role with still required methods creates an abstract class');
    is_deeply(
        [ $meta->required_methods ],
        [ 'bar' ],
        '... got the list of expected required methods for Bar'
    );
    eval { Bar->new };
    like(
        $@,
        qr/^\[mop\:\:PANIC\] Cannot construct instance, the class \(Bar\) is abstract/,
        '... cannot create an instance of Bar'
    );
}

done_testing;