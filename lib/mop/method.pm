package mop::method;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use B ();

our @ISA; BEGIN { @ISA  = ('mop::object') }

sub new ($class, %args) {
    die "The parameter 'body' is required"
        unless exists $args{'body'}
            && ref    $args{'body'} eq 'CODE';

    my $self = bless mop::internal::newMopMmV( $args{'body'} ) => $class;
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