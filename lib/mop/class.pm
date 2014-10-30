package mop::class;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

use mop::internal::util;
use mop::internal::finalize;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our @ISA  = ('mop::role');
our @DOES = ('mop::role');

# instance construction 

sub construct_instance ($self, $candidate, $args) {

    my $wiz  = mop::internal::util::get_wiz();
    my $data = {
        id    => mop::internal::util::next_oid(),
        slots => { $args->%* }
    };

    my $repr_type = ref $candidate;
    if ( $repr_type eq 'HASH' ) {
        Variable::Magic::cast( $candidate->%*, $wiz, $data );
    } 
    elsif ( $repr_type eq 'ARRAY' ) {
        Variable::Magic::cast( $candidate->@*, $wiz, $data );
    } 
    elsif ( $repr_type eq 'SCALAR' ) {
        Variable::Magic::cast( $candidate->$*, $wiz, $data );
    } 
    elsif ( $repr_type eq 'CODE' ) {
        Variable::Magic::cast( $candidate, $wiz, $data );
    } 
    else {
        die "Unsupported candiate type: $repr_type";
    }

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