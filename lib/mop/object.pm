package mop::object;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use mop::internal::util;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub new ($class, %args) {
    my $self = mop::meta( $class )->construct_instance( \%args );
    $self->can('BUILD') && mop::internal::util::BUILDALL( $self, \%args );
    $self;
}

sub DESTROY ($self) {
    $self->can('DEMOLISH') && mop::internal::util::DEMOLISHALL( $self )
}

1;

__END__