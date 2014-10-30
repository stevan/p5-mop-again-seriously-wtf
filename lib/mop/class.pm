package mop::class;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

use mop::internal::util;

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
    my $ISA = $self->{'ISA'};
    return () unless $ISA;
    return $ISA->*{'ARRAY'}->@*;
}

sub mro ($self, $type = mro::get_mro( $self->name )) { 
    return mro::get_linear_isa( $self->name, $type )->@*;
}

1;

__END__