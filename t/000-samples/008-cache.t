#!perl

use strict;
use warnings;

use Test::More;

=pod
{
    package Cache;
    use Moose;

    has fetcher => (is => 'ro', required => 1);
    has data => (
        is        => 'rw',
        lazy      => 1,
        builder   => '_fetch_data',
        predicate => 'has_data',
        clearer   => 'clear'
    );

    sub _fetch_data {
        (shift)->fetcher->()
    }
}
=cut


package Cache {
    use Moxie;

    extends 'mop::object';

    has 'fetcher' => (required => 1);
    has 'data';

    sub data ($self) {
        $self->{data} //= $self->_fetch_data;
    }

    sub has_data ($self) { defined $self->{data} }
    sub clear    ($self) { undef $self->{data} }

    sub _fetch_data ($self) { $self->{fetcher}->() }
}

my @data = qw[
    one
    two
    three
];

my $c = Cache->new( fetcher => sub { shift @data } );
isa_ok($c, 'Cache');

is($c->data, 'one', '... the data we got is correct');
ok($c->has_data, '... we have data');

$c->clear;

is($c->data, 'two', '... the data we got is correct (cache has been cleared)');
is($c->data, 'two', '... the data is still the same');
ok($c->has_data, '... we have data');

$c->clear;

is($c->data, 'three', '... the data we got is correct (cache has been cleared)');
ok($c->has_data, '... we have data');

$c->clear;

ok(!$c->has_data, '... we no longer have data');
is($c->data, undef, '... the cache is empty now');

done_testing;