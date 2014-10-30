package mop::object;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use mop::internal::finalize;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub new ($class, %args) {
    my $self = mop::meta( __PACKAGE__ )->construct_instance( {}, \%args );
    $self->BUILDALL( \%args );
    $self;
}

sub BUILDALL ($self, $args) {
    # ... TODO 

    return $self;
}

sub DEMOLISHALL ($self, $args) {
    # ... TODO

    return $self;
}

sub DESTROY ($self) {
    $self->can('DEMOLISH') && $self->DEMOLISHALL
}

1;

__END__