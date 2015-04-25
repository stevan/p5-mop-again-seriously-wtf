package mop::object;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Scalar::Util ();

use mop::internal::util;

sub new ($class, @args) {
    die "[mop::PANIC] cannot call 'new' with a blessed instance"
        if Scalar::Util::blessed $class;
    my $args = $class->BUILDARGS( @args );
    my $self = mop::class->new( name => $class )->construct_instance( $args );
    $self->can('BUILD') && mop::internal::util::BUILDALL( $self, $args );
    $self;
}

sub BUILDARGS ($class, @args) {
    return scalar @args == 1 && ref $args[0] ? $args[0] : { @args }
}

sub DOES ($self, $role) {
    my $class = ref $self || $self;
    # if we inherit from this, we are good ...
    return 1 if $class->isa( $role );
    # next check the roles ...
    my $meta = mop::class->new( name => $class );
    # test just the local (and composed) roles first ...
    return 1 if $meta->does_role( $role );
    # then check the inheritance hierarchy next ...
    return 1 if scalar grep { mop::class->new( name => $_ )->does_role( $role ) } $meta->mro;
    return 0;
}

sub DESTROY ($self) {
    $self->can('DEMOLISH') && mop::internal::util::DEMOLISHALL( $self )
}

BEGIN {
    our @FINALIZERS = ( sub { mop::internal::util::CLOSE_CLASS(__PACKAGE__) } );
}

1;

__END__