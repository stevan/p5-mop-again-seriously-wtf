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

my @METHODS = qw[
    new 

    stash

    name
    version
    authority

    is_closed
    set_is_closed

    is_abstract
    set_is_abstract

    roles
    set_roles
    does_role

    superclasses
    set_superclasses
    mro

    construct_instance

    attributes
    has_attribute
    has_attribute_alias
    get_attribute
    delete_attribute
    add_attribute
    alias_attribute

    finalizers
    has_finalizers
    add_finalizer
    run_all_finalizers

    required_methods
    requires_method
    add_required_method
    delete_required_method

    methods
    has_method
    has_method_alias
    get_method
    delete_method
    add_method
    alias_method
];

can_ok($Class, $_) for @METHODS;

is($Class->name,      'mop::class', '... got the expected value from ->name');
is($Class->version,   '0.01', '... got the expected value from ->version');
is($Class->authority, 'cpan:STEVAN', '... got the expected value ->authority');

ok($Class->is_closed,    '... the class has been closed');

is_deeply([ $Class->superclasses ], [ 'mop::object' ], '... got the expected value from ->superclasses');
is_deeply([ $Class->mro ], [ 'mop::class', 'mop::object' ], '... got the expected value from ->mro');

is_deeply([ $Class->roles ], [ 'mop::role' ], '... got the expected value from ->roles');

is_deeply([ sort map { $_->name } $Class->methods ], [ sort @METHODS ], '... got the expected value from ->methods');

is($Class->get_method('superclasses')->body, \&mop::class::superclasses, '... got the expected value from ->get_method');

like(
    exception { $Class->add_method('foo' => sub {}) },
    qr/^\[mop\:\:PANIC\] Cannot add method \(foo\) to \(mop\:\:class\) because it has been closed/,
    '... got the expected exception from ->add_method'
);

like(
    exception { $Class->delete_method('superclasses') },
    qr/^\[mop\:\:PANIC\] Cannot delete method \(superclasses\) from \(mop\:\:class\) because it has been closed/,
    '... got the expected exception from ->delete_method'
);

can_ok($Class, 'superclasses');
is_deeply([ $Class->superclasses ], [ 'mop::object' ], '... got the expected value from ->superclasses (still)');

done_testing;