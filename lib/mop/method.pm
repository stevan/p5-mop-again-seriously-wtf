package mop::method;

use v5.20;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures', 'experimental::postderef';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use B ();

our @ISA; BEGIN { @ISA  = ('mop::object') }

sub new ($class, %args) {
    die "The parameter 'body' is required"
        unless exists $args{'body'}
            && ref    $args{'body'} eq 'CODE';

    my $body = $args{'body'};
    my $self = bless \$body => $class;
    $self->can('BUILD') && mop::internal::util::BUILDALL( $self, \%args );
    $self; 
}

sub body ($self) { $self->$* }

sub name       ($self) { B::svref_2object( $self->$* )->GV->NAME        }
sub stash_name ($self) { B::svref_2object( $self->$* )->GV->STASH->NAME }

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