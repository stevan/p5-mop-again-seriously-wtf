#!/usr/bin/perl -w

use v5.20;
use warnings;

use Test::More;
use Test::Fatal;
use Data::Dumper;

BEGIN {
    use_ok('mop');
}

my $Class = mop::class->new( name => 'mop::class' );
isa_ok($Class, 'mop::class');
isa_ok($Class, 'mop::object');

ok($Class->does_role('mop::role'), '... mop::class does mop::role');

is($Class, mop::meta($Class), '... Class is an instance of Class');
is($Class, mop::meta(mop::meta($Class)), '... Class is an instance of Class (really)');
is($Class, mop::meta(mop::meta(mop::meta($Class))), '... Class is an instance of Class (no, really)');

is(mop::meta($Class), mop::meta(mop::meta($Class)), '... Class is an instance of Class (you think I am kidding)');
is(mop::meta($Class), mop::meta(mop::meta(mop::meta($Class))), '... Class is an instance of Class (really)');

is(mop::meta(mop::meta($Class)), mop::meta(mop::meta(mop::meta($Class))), '... Class is an instance of Class (still the same)');

my @METHODS = qw[
    new 

    name
    version
    authority

    roles
    does_role

    superclasses
    mro

    construct_instance

    methods
    has_method
    get_method
    delete_method
    add_method
    alias_method
];

can_ok($Class, $_) for @METHODS;

is($Class->name,      'mop::class', '... got the expected value from ->name');
is($Class->version,   '0.01', '... got the expected value from ->version');
is($Class->authority, 'cpan:STEVAN', '... got the expected value ->authority');

is_deeply([ $Class->superclasses ], [ 'mop::object' ], '... got the expected value from ->superclasses');
is_deeply([ $Class->mro ], [ 'mop::class', 'mop::object' ], '... got the expected value from ->mro');

is_deeply([ $Class->roles ], [ 'mop::role' ], '... got the expected value from ->roles');

is_deeply([ sort map { $_->name } $Class->methods ], [ sort @METHODS ], '... got the expected value from ->methods');

is($Class->get_method('superclasses'), \&mop::class::superclasses, '... got the expected value from ->get_method');

like(
    exception { $Class->add_method('foo' => sub {}) },
    qr/^\[PACKAGE FINALIZED\] The package \(mop\:\:class\) has been finalized, attempt to store into key \(foo\) is not allowed/,
    '... got the expected exception from ->add_method'
);

like(
    exception { $Class->delete_method('superclasses') },
    qr/^Modification of a read-only value attempted/,
    '... got the expected exception from ->delete_method'
);

can_ok($Class, 'superclasses');
is_deeply([ $Class->superclasses ], [ 'mop::object' ], '... got the expected value from ->superclasses (still)');

done_testing;