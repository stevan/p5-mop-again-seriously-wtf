#!/usr/bin/env perl

use v5.20;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('mop');
}

{
    my $o = mop::internal::newMopOV({});

    is_deeply(
        mop::internal::opaque::get_slots($o), 
        {}, 
        '... got the expected slots'
    );

    ok(!mop::internal::opaque::has_at_slot($o, 'foo'), '... no value set yet');
    is(
        exception{ mop::internal::opaque::set_at_slot($o, 'foo', 10) },
        undef,
        '... set slot successfully'
    );

    ok(mop::internal::opaque::has_at_slot($o, 'foo'), '... a value has been set');
    is(mop::internal::opaque::get_at_slot($o, 'foo'), 10, '... got the expected value');

    is_deeply(
        mop::internal::opaque::get_slots($o), 
        { foo => 10 }, 
        '... got the expected slots (changed)'
    );

    is(
        exception{ mop::internal::opaque::set_at_slot($o, 'foo', undef) },
        undef,
        '... set slot successfully to undef'
    );
    ok(mop::internal::opaque::has_at_slot($o, 'foo'), '... a value is still set, even though it is undef');
    is(mop::internal::opaque::get_at_slot($o, 'foo'), undef, '... got the expected undef value');

    is(
        exception{ mop::internal::opaque::clear_at_slot($o, 'foo') },
        undef,
        '... cleared slot successfully'
    );
    ok(!mop::internal::opaque::has_at_slot($o, 'foo'), '... a value no longer set');
    is(mop::internal::opaque::get_at_slot($o, 'foo'), undef, '... got the expected lack of a value (undef)');

}

done_testing;

