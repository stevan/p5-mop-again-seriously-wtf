package mop::class;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

use mop::internal::util;
use mop::internal::util::package::FINALIZE;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our @ISA;  BEGIN { @ISA  = ('mop::object') }
our @DOES; BEGIN { @DOES = ('mop::role')   }

# instance construction 

sub construct_instance ($self, $candidate) {
    return bless $candidate => $self->name;
}

# inheritance 

sub superclasses ($self) {
    my $ISA = $self->$*->{'ISA'};
    return () unless $ISA;
    return $ISA->*{'ARRAY'}->@*;
}

sub mro ($self, $type = mro::get_mro( $self->name )) { 
    return mro::get_linear_isa( $self->name, $type )->@*;
}

# finalizer

FINALIZE {

    # NOTE:
    # We need to finalize mop::class itself so 
    # that the bootstrap is complete, which is 
    # why we are using mop::role below and not 
    # mop::class. The mop::role class is complete
    # and contains all the functionality we require
    # to make mop::class complete. Since roles
    # are just classes which do not create 
    # instances, this just works. 
    # - SL

    my $meta = mop::role->new( name => __PACKAGE__ );
    mop::internal::util::APPLY_ROLES( $meta, \@DOES, to => 'class' );
    our $CLOSED = 1;
};

1;

__END__