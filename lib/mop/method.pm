package mop::method;

use v5.20;
use warnings;
use experimental 'signatures';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our @ISA; BEGIN { @ISA  = ('mop::object') }

sub new ($class, %args) {
    die "The parameter 'body' is required"
        unless exists $args{body}
            && ref    $args{body} eq 'CODE';

    my $self = bless mop::internal::newMopMmV( $args{body} ) => $class;
    $self->can('BUILD') && mop::internal::util::BUILDALL( $self, \%args );
    $self; 
}

BEGIN {
    our @FINALIZERS = ( sub { mop::internal::opaque::set_at_slot(\%mop::method::, 'is_closed', 1) } );
}

1;

__END__