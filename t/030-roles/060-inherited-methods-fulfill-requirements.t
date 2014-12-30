#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

package Role::Table {
    use v5.20;
    use warnings;
    use mop;

    sub query_by_id;
}

package Role::Table::RO {
    use v5.20;
    use warnings;
    use mop does => 'Role::Table';

    sub count;
    sub select;
}

package Table {
    use v5.20;
    use warnings;
    use mop 
        isa  => 'mop::object',
        does => 'Role::Table';

    sub query_by_id { 'Table::query_by_id' }
}

package Table::RO {
    use v5.20;
    use warnings;
    use mop 
        isa  => 'Table',
        does => 'Role::Table::RO';

    sub count  { 'Table::RO::count' }
    sub select { 'Table::RO::select' }
}

my $t = Table::RO->new;
isa_ok($t, 'Table::RO');

done_testing;
