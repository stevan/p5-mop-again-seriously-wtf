package mop::object;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use mop::internal::util;

use Variable::Magic ();

sub new ($class, %args) {
    my %repr;
    my $self = $class->BLESS( $class->CREATE( \%repr, %args ) );
    $self->BUILDALL( \%args );
    $self;
}


# the CREATE method takes the repr
# or representation of the instance
# we want and and the arguments and
# returns an appropriately set up 
# instance representation that is 
# suitable for passing to BLESS.
sub CREATE ($class, $repr, %args) {

    Variable::Magic::cast( 
        %$repr, 
        mop::internal::util::get_wiz(), 
        {
            id    => mop::internal::util::next_oid(),
            slots => { %args }
        }
    );    

    return $repr;
}


# the BLESS method performs the blessing
# necessary to associate a given repr with 
# a given class/package
sub BLESS ($class, $repr) {
    return bless $repr => $class;
}

# the BUILDALL method calls all the BUILD
# methods in the entire inheritance 
# hierarchy in the correct order
sub BUILDALL ($self, $args) {
    # ... TODO 

    return $self;
}

# the DEMOLISHALL method calls all the DEMOLISH
# methods in the entire inheritance 
# hierarchy in the correct order
sub DEMOLISHALL ($self, $args) {
    # ... TODO

    return $self;
}

sub DESTROY {
    # ... TODO 
}

1;

__END__