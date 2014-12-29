package mop::attribute;

use v5.20;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures', 'experimental::postderef';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use B ();

our @ISA; BEGIN { @ISA  = ('mop::object') }

sub new ($class, %args) {

    die 'The parameter `name` is required, and it must be a string'
        unless exists  $args{'name'} 
            && defined $args{'name'} 
            && length  $args{'name'} > 0;

    die 'The parameter `initializer` is required'
        unless exists $args{'initializer'}
            && ref    $args{'initializer'} eq 'CODE';

    my $name        = $args{'name'};
    my $initializer = $args{'initializer'};

    # NOTE:
    # this is basically just a blessed HE (HashEntry)
    # because we want to avoid having to have need 
    # any attribute instances for the core mop classes
    # - SL
    my $self = bless [ $name => $initializer ] => $class;
    $self->can('BUILD') && mop::internal::util::BUILDALL( $self, \%args );
    $self; 
}

sub name       ($self) { $self->[0] }
sub stash_name ($self) { B::svref_2object( $self->[1] )->GV->STASH->NAME }

sub initializer ($self) { $self->[1] }

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