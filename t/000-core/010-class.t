#!/usr/bin/perl -w

use v5.20;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('mop');
}

my $Class = mop::class->new( name => 'mop::class' );
isa_ok($Class, 'mop::class');

is($Class, mop::meta($Class), '... Class is an instance of Class');
is($Class, mop::meta(mop::meta($Class)), '... Class is an instance of Class (really)');
is($Class, mop::meta(mop::meta(mop::meta($Class))), '... Class is an instance of Class (no, really)');

is(mop::meta($Class), mop::meta(mop::meta($Class)), '... Class is an instance of Class (you think I am kidding)');
is(mop::meta($Class), mop::meta(mop::meta(mop::meta($Class))), '... Class is an instance of Class (really)');

is(mop::meta(mop::meta($Class)), mop::meta(mop::meta(mop::meta($Class))), '... Class is an instance of Class (still the same)');

done_testing;