#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $collector;

package Foo {
    use v5.20;
    use warnings;
    use mop;

    extends 'mop::object';

    sub collect ($self, $stuff) {
        push @{ $collector } => $stuff;
    }

    sub DEMOLISH ($self) {
        $self->collect( 'Foo' );
    }
}

package Bar {
    use v5.20;
    use warnings;
    use mop;

    extends 'Foo';

    sub DEMOLISH ($self) {
        $self->collect( 'Bar' );
    }
}

package Baz {
    use v5.20;
    use warnings;
    use mop;

    extends 'Bar';

    sub DEMOLISH ($self) {
        $self->collect( 'Baz' );
    }
}


$collector = [];
Foo->new;
is_deeply($collector, ['Foo'], '... got the expected collection');

$collector = [];
Bar->new;
is_deeply($collector, ['Bar', 'Foo'], '... got the expected collection');

$collector = [];
Baz->new;
is_deeply($collector, ['Baz', 'Bar', 'Foo'], '... got the expected collection');

done_testing;