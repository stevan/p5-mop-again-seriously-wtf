package mop::instance;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use Scalar::Util ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub new ($class, $proto) {
    die "[mop::PANIC] the prototype for a new mop::instance must not be a blessed object"
        if Scalar::Util::blessed( $proto );
    bless \$proto => $class;
}

sub repr ($self) {
    Scalar::Util::reftype( $self->$* )
}

sub bless ($self, $into_class) {
    bless $self->$* => $into_class;
}

sub get_slot ($self, $name)         { $self->$*->{$name}          }
sub set_slot ($self, $name, $value) { $self->$*->{$name} = $value }

1;

__END__