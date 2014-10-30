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
    my $name = $args{'body'} || die 'The method `body` is required';
    return $args{'body'} 
        if Scalar::Util::blessed( $args{'body'} )
        && $args{'body'}->isa(__PACKAGE__);
    return bless $args{'body'} => 'mop::method';
}

sub name       { B::svref_2object( shift )->GV->NAME        }
sub stash_name { B::svref_2object( shift )->GV->STASH->NAME }

sub was_aliased_from {
    my ($self, @packages) = @_;
    my $stash_name = $self->stash_name;
    foreach my $p (@packages) {
        return 1 if $p eq $stash_name;
    }
    return 0;
}

1;

__END__