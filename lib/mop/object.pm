package mop::object;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use mop::internal::util;

use Variable::Magic ();

sub new ($class, %args) {

    my %self;

    Variable::Magic::cast( %self, mop::internal::util::get_wiz(), {
        id    => mop::internal::util::next_oid(),
        slots => { %args }
    });

    mop::meta( $class )->construct_instance( \%self );
}

1;

__END__