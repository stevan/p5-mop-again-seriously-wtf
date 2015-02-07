package mop::class;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use mop::internal::util 'FINALIZE';

our @ISA;  BEGIN { @ISA  = ('mop::object') }
our @DOES; BEGIN { @DOES = ('mop::role')   }

# instance construction 

sub construct_instance ($self, $candidate) {
    die "[mop::PANIC] Cannot construct instance, the class (" . $self->name . ") is abstract"
        if $self->is_abstract;

    my %instance;
    if ( my $HAS = $self->stash->{'HAS'} ) {
        my %proto =  $HAS->*{'HASH'}->%*;
        foreach my $k ( keys %proto ) {
            $instance{ $k } = exists $candidate->{ $k } 
                ? $candidate->{ $k }
                : $proto{ $k }->();
        }
    }

    return bless \%instance => $self->name;
}

# inheritance 

sub set_superclasses ($self, @supers) {
    die "[mop::PANIC] Cannot set superclasses in (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    no strict 'refs';
    no warnings 'once';
    @{ $self->name . '::ISA'} = ( @supers );
}

# finalizer

BEGIN {
    our $IS_CLOSED;
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
            $IS_CLOSED = 1;
        }
    )
}

1;

__END__