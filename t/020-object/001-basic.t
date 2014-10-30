#!/usr/bin/env perl 

use v5.20;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('mop');
}

{
    my $o = mop::object->new( test => 1 );
    isa_ok($o, 'mop::object');

    is_deeply({ %$o }, { test => 1 }, '... got expected values in the instance itself');
}



done_testing();