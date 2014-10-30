package mop::object;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use mop::internal::util;

use Variable::Magic ();

sub new ($class, %args) {
    my %repr;

    Variable::Magic::cast( 
        %repr, 
        mop::internal::util::get_wiz(), 
        {
            id    => mop::internal::util::next_oid(),
            slots => { %args }
        }
    ); 

    my $self = bless \%repr => $class;
    $self->BUILDALL( \%args );
    $self;
}

sub BUILDALL ($self, $args) {
    # ... TODO 

    return $self;
}

sub DEMOLISHALL ($self, $args) {
    # ... TODO

    return $self;
}

sub DESTROY ($self) {
    $self->can('DEMOLISH') && $self->DEMOLISHALL
}

1;

__END__