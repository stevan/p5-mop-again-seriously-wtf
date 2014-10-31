package mop::internal::package;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

use Carp            ();
use Variable::Magic ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

## adding extra info to packages ...

my $WIZARD; 
BEGIN { $WIZARD = Variable::Magic::wizard( data => sub { $_[1] } ) }

sub UPGRADE_PACKAGE ($stash) {
    # Apply magic to the stash, this 
    # should only be done once because 
    # we are setting state here.
    Carp::confess("[PANIC] The package already has magic applied to it.") 
        if Variable::Magic::getdata( $stash->%*, $WIZARD );
    Variable::Magic::cast( 
        $stash->%*, $WIZARD, { 
            is_closed => 0,
        }
    );
}

sub IS_PACKAGE_UPGRADED ($stash) {
    !! Variable::Magic::getdata( $stash->%*, $WIZARD );
}

sub IS_PACKAGE_CLOSED ($stash) {
    my $slots = Variable::Magic::getdata( $stash->%*, $WIZARD );
    Carp::confess("[PANIC] The package does not have the correct magic applied.") unless $slots;
    return $slots->{is_closed};
}

sub CLOSE_PACKAGE ($stash) {
    my $slots = Variable::Magic::getdata( $stash->%*, $WIZARD );
    Carp::confess("[PANIC] The package does not have the correct magic applied.") unless $slots;
    $slots->{is_closed} = 1;
}

sub OPEN_PACKAGE ($stash) {
    my $slots = Variable::Magic::getdata( $stash->%*, $WIZARD );
    Carp::confess("[PANIC] The package does not have the correct magic applied.") unless $slots;
    $slots->{is_closed} = 0;
}

1;

__END__
