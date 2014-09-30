package mop::internal::util;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use Variable::Magic ();

our $OID = 0;
our $WIZ = Variable::Magic::wizard( data => sub { $_[1] } );

sub next_oid { $OID++ }
sub get_wiz  { $WIZ   }

# TODO:
#
# 1) These assume that the instance 
#    is a HASH ref, which is wrong,
#    so we need to dispatch based on 
#    ref type instead.
# 
# 2) There is not enough error handling
#    here, we need to make sure that the
#    call to getdata works, and die if
#    the value does not have magic.
# 
# ...

sub get_oid ($instance) { 
    my $opaque = Variable::Magic::getdata( %$instance, $WIZ );
    return $opaque->{id};
}

sub get_slots ($instance) {
    my $opaque = Variable::Magic::getdata( %$instance, $WIZ );
    return $opaque->{slots};
}

1;

__END__
