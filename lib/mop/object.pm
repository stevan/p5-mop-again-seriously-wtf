package mop::object;

use v5.20;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures', 'experimental::postderef';

use mop::internal::util;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub new ($class, %args) {
    my $self = mop::class->new( name => $class )->construct_instance( \%args );
    $self->can('BUILD') && mop::internal::util::BUILDALL( $self, \%args );
    $self;
}

sub does ($self, $role) {
    mop::class->new( name => ref $self || $self )->does_role( $role )
}

sub DESTROY ($self) {
    $self->can('DEMOLISH') && mop::internal::util::DEMOLISHALL( $self )
}

1;

__END__