#!/usr/bin/env perl

use v5.20;
use warnings;

use Test::More;

BEGIN {
    use_ok('mop');

    use_ok('mop::class');
    use_ok('mop::object');
    use_ok('mop::method');
    use_ok('mop::role');
}

done_testing;

