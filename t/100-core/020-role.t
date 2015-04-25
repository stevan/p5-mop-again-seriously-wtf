#!/usr/bin/perl -w

use v5.20;
use warnings;

use Test::More;
use Test::Fatal;
use Data::Dumper;

BEGIN {
    use_ok('mop');
}

my $Role = mop::role->new( name => 'mop::role' );
isa_ok($Role, 'mop::object');

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

can_ok($Role, $_) for @METHODS;

is($Role->name,      'mop::role', '... got the expected value from ->name');
is($Role->version,   '0.01', '... got the expected value from ->version');
is($Role->authority, 'cpan:STEVAN', '... got the expected value ->authority');

ok($Role->is_closed,    '... the role has been closed');

is_deeply([ sort map { $_->name } $Role->methods ], [ sort @METHODS ], '... got the expected value from ->methods');

is($Role->get_method('name')->body, \&mop::role::name, '... got the expected value from ->get_method');

like(
    exception { $Role->add_method('foo' => sub {}) },
    qr/^\[mop\:\:PANIC\] Cannot add method \(foo\) to \(mop\:\:role\) because it has been closed/,
    '... got the expected exception from ->add_method'
);

like(
    exception { $Role->delete_method('name') },
    qr/^\[mop\:\:PANIC\] Cannot delete method \(name\) from \(mop\:\:role\) because it has been closed/,
    '... got the expected exception from ->delete_method'
);

can_ok($Role, 'name');
is($Role->name, 'mop::role', '... got the expected value from ->name');

{
    mop::internal::opaque::set_at_slot(\%mop::role::, 'is_closed', 0);

    is(
        exception { $Role->add_method('foo' => sub { 'FOO' }) },
        undef,
        '... got no exception from ->add_method'
    );

    can_ok($Role, 'foo');
    is($Role->foo, 'FOO', '... got the expected value from ->foo');

    is(
        exception { $Role->delete_method('foo') },
        undef,
        '... got the expected exception from ->delete_method'
    );

    ok(!$Role->can('foo'), '... removed the ->foo method');

    mop::internal::opaque::set_at_slot(\%mop::role::, 'is_closed', 1);
}

like(
    exception { $Role->add_method('foo' => sub {}) },
    qr/^\[mop\:\:PANIC\] Cannot add method \(foo\) to \(mop\:\:role\) because it has been closed/,
    '... got the expected exception from ->add_method'
);

like(
    exception { $Role->delete_method('name') },
    qr/^\[mop\:\:PANIC\] Cannot delete method \(name\) from \(mop\:\:role\) because it has been closed/,
    '... got the expected exception from ->delete_method'
);

can_ok($Role, 'name');
is($Role->name, 'mop::role', '... got the expected value from ->name');

done_testing;


