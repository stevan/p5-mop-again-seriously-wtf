#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

my ($foo, $bar);

package Foo {
    use v5.20;
    use warnings;
    use mop;

    extends 'mop::object';

    sub foo ($self) { $::foo++ }
}

package Bar {
    use v5.20;
    use warnings;
    use mop;

    sub foo ($self) {
        $self->next::method;
        $::bar++;
    }
}

package Baz {
    use v5.20;
    use warnings;
    use mop;

    extends 'Foo';
       with 'Bar';
}

TODO: {
    local $TODO = 'next::method does not work unless we rename the method with Sub::Util::subname';
    my $baz = Baz->new;
    ($::foo, $::bar) = (0, 0);
    is(exception { $baz->foo }, undef, '... no exception calling ->foo');
    is($::foo, 1, '... Foo::foo was called (via next::method)');
    is($::bar, 1, '... Bar::foo was called (it was composed into Baz)');
}

done_testing;