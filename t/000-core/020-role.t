#!/usr/bin/perl -w

use v5.20;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('mop');
}

my $Class = mop::class->new( name => 'mop::class' );

my $Role = mop::class->new( name => 'mop::role' );
isa_ok($Role, 'mop::role');
isa_ok($Role, 'mop::object');

is($Class, mop::meta($Role), '... Role is an instance of Class');

my @METHODS = qw[
    new 

    name
    version
    authority

    roles

    methods
    has_method
    get_method
    delete_method
    add_method
];

can_ok($Role, $_) for @METHODS;

is($Role->name,      'mop::role', '... got the expected value from ->name');
is($Role->version,   '0.01', '... got the expected value from ->version');
is($Role->authority, 'cpan:STEVAN', '... got the expected value ->authority');

is_deeply([ sort map { B::svref_2object( $_ )->GV->NAME } $Role->methods ], [ sort @METHODS ], '... got the expected value from ->methods');

done_testing;