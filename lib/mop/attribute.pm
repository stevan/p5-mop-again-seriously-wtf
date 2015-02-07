package mop::attribute;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use B ();

our @ISA; BEGIN { @ISA  = ('mop::object') }

sub new ($class, %args) {

    die "The parameter 'name' is required, and it must be a string"
        unless exists  $args{'name'} 
            && defined $args{'name'} 
            && length  $args{'name'} > 0;

    die "The parameter 'initializer' is required"
        unless exists $args{'initializer'}
            && ref    $args{'initializer'} eq 'CODE';

    # NOTE:
    # this is basically just a blessed HE (HashEntry)
    # because we want to avoid having to have need 
    # any attribute instances for the core mop classes
    # - SL
    my $self = bless mop::internal::newMopMaV( @args{ 'name', 'initializer' } ) => $class;
    $self->can('BUILD') && mop::internal::util::BUILDALL( $self, \%args );
    $self; 
}

sub was_aliased_from ($self, @packages) {
    my $stash_name = $self->stash_name;
    foreach my $p (@packages) {
        return 1 if $p eq $stash_name;
    }
    return 0;
}

BEGIN {
    our $IS_CLOSED;
    our @FINALIZERS = ( sub { $IS_CLOSED = 1 } );
}

1;

__END__