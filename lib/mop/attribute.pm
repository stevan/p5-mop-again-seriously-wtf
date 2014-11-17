package mop::attribute;

use v5.20;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures', 'experimental::postderef';

use B ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our @ISA; BEGIN { @ISA  = ('mop::object') }

sub new ($class, %args) {
    my $name        = $args{'name'}        or die 'The attribute `name` is required';
    my $initializer = $args{'initializer'} or die 'The attribute `initializer` is required';
    # NOTE:
    # this is basically just a blessed HE (HashEntry)
    # because we want to avoid having to have need 
    # any attribute instances for the core mop classes
    # - SL
    my $self = bless [ $name => $initializer ] => $class;
    $self->can('BUILD') && mop::internal::util::BUILDALL( $self, \%args );
    $self; 
}

sub name        ($self) { $self->[0] }
sub initializer ($self) { $self->[1] }
sub stash_name  ($self) { B::svref_2object( $self->[1] )->GV->STASH->NAME }

sub was_aliased_from ($self, @packages) {
    my $stash_name = $self->stash_name;
    foreach my $p (@packages) {
        return 1 if $p eq $stash_name;
    }
    return 0;
}

1;

__END__