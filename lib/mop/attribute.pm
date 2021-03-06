package mop::attribute;

use v5.20;
use warnings;
use experimental 'signatures';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our @ISA; BEGIN { @ISA  = ('mop::object') }

sub new ($class, %args) {

    die "The parameter 'name' is required, and it must be a string"
        unless exists  $args{name} 
            && defined $args{name} 
            && length  $args{name} > 0;

    die "The parameter 'initializer' is required"
        unless exists $args{initializer}
            && ref    $args{initializer} eq 'CODE';

    # NOTE:
    # this is basically just a blessed HE (HashEntry)
    # because we want to avoid having to have need 
    # any attribute instances for the core mop classes
    # - SL
    my $self = bless mop::internal::newMopMaV( @args{ 'name', 'initializer' } ) => $class;
    $self->can('BUILD') && mop::internal::util::BUILDALL( $self, \%args );
    $self; 
}

BEGIN {
    our @FINALIZERS = ( sub { mop::internal::util::CLOSE_CLASS(__PACKAGE__) } );
}

1;

__END__