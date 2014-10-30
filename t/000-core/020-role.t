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

my $Role = mop::role->new( name => 'mop::role' );
isa_ok($Role, 'mop::object');

my @METHODS = qw[
    new 

    name
    version
    authority

    roles
    does_role

    methods
    has_method
    get_method
    delete_method
    add_method
    alias_method
];

can_ok($Role, $_) for @METHODS;

is($Role->name,      'mop::role', '... got the expected value from ->name');
is($Role->version,   '0.01', '... got the expected value from ->version');
is($Role->authority, 'cpan:STEVAN', '... got the expected value ->authority');

is_deeply([ sort map { $_->name } $Role->methods ], [ sort @METHODS ], '... got the expected value from ->methods');

is($Role->get_method('name'), \&mop::role::name, '... got the expected value from ->get_method');

like(
    exception { $Role->add_method('foo' => sub {}) },
    qr/^\[PACKAGE FINALIZED\] The package \(mop\:\:role\) has been finalized, attempt to store into key \(foo\) is not allowed/,
    '... got the expected exception from ->add_method'
);

like(
    exception { $Role->delete_method('name') },
    qr/^Modification of a read-only value attempted/,
    '... got the expected exception from ->delete_method'
);

can_ok($Role, 'name');
is($Role->name, 'mop::role', '... got the expected value from ->name');

done_testing;


