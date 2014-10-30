package mop::method;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use mop::internal::finalize;

use B ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our @ISA; BEGIN { @ISA  = ('mop::object') }

sub new ($class, %args) {
    my $body = $args{'body'} or die 'The method `body` is required';

    # no need to rebless things ...
    return $body if Scalar::Util::blessed( $body );

    return bless $body => 'mop::method';
}

sub name       ($self) { B::svref_2object( $self )->GV->NAME        }
sub stash_name ($self) { B::svref_2object( $self )->GV->STASH->NAME }

sub was_aliased_from ($self, @packages) {
    my $stash_name = $self->stash_name;
    foreach my $p (@packages) {
        return 1 if $p eq $stash_name;
    }
    return 0;
}

1;

__END__