package mop::class;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

use mop::internal::util 'FINALIZE';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our @ISA;  BEGIN { @ISA  = ('mop::object') }
our @DOES; BEGIN { @DOES = ('mop::role')   }

# instance construction 

sub construct_instance ($self, $candidate) {
    die "[mop::PANIC] Cannot construct instance, the class (" . $self->name . ") is abstract"
        if $self->is_abstract;
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

BEGIN {
    our $CLOSED;
    our @FINALIZERS = ( 
        sub {
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
            mop::internal::util::APPLY_ROLES(
                mop::role->new( name => __PACKAGE__ ), 
                \@DOES, 
                to => 'class' 
            );
            $CLOSED = 1;
        }
    )
}

1;

__END__