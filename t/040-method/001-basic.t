#!perl

use strict;
use warnings;

use Test::More;

use mop;

=pod

This is just a basic test for what we have now,
which is pretty basic and primative. The plan
is to wait to see what happens with the
function signature work and basically use what
they have, only for methods.

Eventually this test (and this test folder) will
get a lot more tests when we know how things end
up.

=cut

package Foo {
    use v5.20;
    use warnings;
    use mop;

    extends 'mop::object';

    sub bar { 'BAR' }

    sub bar_with_empty_body {}

    sub bar_w_implicit_params { shift; join ', ' => 'BAR', @_ }

    sub bar_w_explicit_params ($self, @args) { join ', ' => 'BAR', @args }

    sub bar_w_explicit_param ($self, $a) { join ', ' => 'BAR', ($a // '') }

    sub bar_w_default_params ($self, $a = 10) { join ', ' => 'BAR', $a }

    sub bar_w_two_default_params ($self, $a = 10, $b = 20) { join ', ' => 'BAR', $a, $b }
}

my $foo = Foo->new;
isa_ok($foo, 'Foo');

is($foo->bar, 'BAR', '... got the expected return value');

is($foo->bar_w_implicit_params, 'BAR', '... got the expected return value');
is($foo->bar_w_implicit_params(1, 2), 'BAR, 1, 2', '... got the expected return value');

is($foo->bar_w_explicit_params, 'BAR', '... got the expected return value');
is($foo->bar_w_explicit_params(1, 2), 'BAR, 1, 2', '... got the expected return value');

my $result = $foo->bar_with_empty_body;
ok !defined $result, 'empty method bodies should not return a defined value';
my @result = $foo->bar_with_empty_body;
ok !defined $result[0], '... even if they are called in list context';

{
    # NOTE:
    # We can sit on this one for now and
    # wait until the function sigs is more
    # nailed down.
    # - SL
    local $TODO = '<rjbs> stevan: My recollection was "too few is an error, too many is not," but there is a thread... (but not a spec)...';
    eval { $foo->bar_w_explicit_param; die 'Stupid uninitialized variable warnings, *sigh*' };
    like(
        $@,
        qr/Not enough parameters/,
        '... got the expected error'
    );
}
is($foo->bar_w_explicit_param(1), 'BAR, 1', '... got the expected return value');

is($foo->bar_w_default_params, 'BAR, 10', '... got the expected return value');
is($foo->bar_w_default_params(1), 'BAR, 1', '... got the expected return value');

is($foo->bar_w_two_default_params, 'BAR, 10, 20', '... got the expected return value');
is($foo->bar_w_two_default_params(1), 'BAR, 1, 20', '... got the expected return value');
is($foo->bar_w_two_default_params(1, 2), 'BAR, 1, 2', '... got the expected return value');

done_testing;
