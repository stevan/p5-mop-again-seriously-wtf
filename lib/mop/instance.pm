package mop::instance;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use Scalar::Util ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub new ($class, $proto = {}) {
    die "[mop::PANIC] the prototype for a new mop::instance must not be a blessed object"
        if Scalar::Util::blessed( $proto );
    die "[mop::PANIC] the prototype for a new mop::instance must be a HASH ref"
        if ref $proto ne 'HASH';
    bless \$proto => $class;
}

sub repr ($self) {
    Scalar::Util::reftype( $self->$* )
}

sub bless ($self, $into_class) {
    bless $self->$* => $into_class;
}


1;

__END__