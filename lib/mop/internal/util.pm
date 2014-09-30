package mop::internal::util;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use Variable::Magic ();

sub next_oid {
    state $OID = 0;
    $OID++;
}

sub get_wiz {
    state $WIZ = Variable::Magic::wizard( data => sub { $_[1] } );
    $WIZ;
}

1;

__END__
