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

    is_deeply({ %$o }, {}, '... got nothing in the instance itself');
    is_deeply(mop::internal::util::get_slots($o), { test => 1 }, '... got the expected slots');
}

done_testing();