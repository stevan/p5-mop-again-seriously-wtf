package mop::object;

use v5.20;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures', 'experimental::postderef';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use mop::internal::util;

sub new ($class, @args) {
    my %args = scalar @args == 1 && ref $args[0] ? %{ $args[0] } : @args;
    my $self = mop::class->new( name => $class )->construct_instance( \%args );
    $self->can('BUILD') && mop::internal::util::BUILDALL( $self, \%args );
    $self;
}

sub DOES ($self, $role) {
    mop::class->new( name => ref $self || $self )->does_role( $role )
}

sub DESTROY ($self) {
    $self->can('DEMOLISH') && mop::internal::util::DEMOLISHALL( $self )
}

BEGIN {
    our $IS_CLOSED;
    our @FINALIZERS = ( sub { $IS_CLOSED = 1 } );
}

1;

__END__