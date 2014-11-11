package mop::method;

use v5.20;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures', 'experimental::postderef';

use B ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our @ISA; BEGIN { @ISA  = ('mop::object') }

sub new ($class, %args) {
    my $body = $args{'body'} or die 'The method `body` is required';
    my $self = bless \$body => 'mop::method';
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

1;

__END__