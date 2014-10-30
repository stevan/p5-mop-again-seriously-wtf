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
isa_ok($Class, 'mop::role');
isa_ok($Class, 'mop::object');

is($Class, mop::meta($Class), '... Class is an instance of Class');
is($Class, mop::meta(mop::meta($Class)), '... Class is an instance of Class (really)');
is($Class, mop::meta(mop::meta(mop::meta($Class))), '... Class is an instance of Class (no, really)');

is(mop::meta($Class), mop::meta(mop::meta($Class)), '... Class is an instance of Class (you think I am kidding)');
is(mop::meta($Class), mop::meta(mop::meta(mop::meta($Class))), '... Class is an instance of Class (really)');

is(mop::meta(mop::meta($Class)), mop::meta(mop::meta(mop::meta($Class))), '... Class is an instance of Class (still the same)');

can_ok($Class, $_) for qw[
    new 

    name
    version
    authority

    roles

    superclasses
    mro

    construct_instance

    methods
    has_method
    get_method
    delete_method
    add_method
];

is($Class->name,      'mop::class', '... got the expected value from ->name');
is($Class->version,   '0.01', '... got the expected value from ->version');
is($Class->authority, 'cpan:STEVAN', '... got the expected value ->authority');

is_deeply([ $Class->superclasses ], [ 'mop::role' ], '... got the expected value from ->superclasses');
is_deeply([ $Class->mro ], [ 'mop::class', 'mop::role', 'mop::object' ], '... got the expected value from ->mro');

is_deeply([ $Class->roles ], [ 'mop::role' ], '... got the expected value from ->roles');

is_deeply([ sort map { B::svref_2object( $_ )->GV->NAME } $Class->methods ], [qw[ construct_instance mro superclasses ]], '... got the expected value from ->methods');

done_testing;