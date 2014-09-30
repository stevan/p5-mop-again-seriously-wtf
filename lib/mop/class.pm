package mop::class;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

use mop::internal::util;

use B               ();
use Variable::Magic ();

sub new ($class, %args) {

    my $name = $args{'name'} || die 'The class `name` is required';

    no strict 'refs';

    # no need to add magic if 
    # this magic has already 
    # been attached to it 
    unless ( Variable::Magic::getdata( %{ $name . '::' }, mop::internal::util::get_wiz() ) ) {
        Variable::Magic::cast( %{ $name . '::' }, mop::internal::util::get_wiz(), {
            id    => mop::internal::util::next_oid(),
            slots => {}
        });
    }

    bless \%{ $name . '::' } => $class;
}

# meta-info 

sub name ($self) { 
    B::svref_2object( $self )->NAME;
}

sub version ($self) { 
    return unless exists $self->{'VERSION'};
    return $self->{'VERSION'}->*{'SCALAR'}->$*;
}

sub authority ($self) { 
    return unless exists $self->{'AUTHORITY'};
    return $self->{'AUTHORITY'}->*{'SCALAR'}->$*;
}

# inheritance 

sub superclasses ($self) {
    my $ISA = $self->{'ISA'};
    return () unless $ISA;
    return @{ *{ $ISA }{'ARRAY'} };
}

sub mro ($self, $type = mro::get_mro( $self->name )) { 
    return @{ mro::get_linear_isa( $self->name, $type ) };
}

# instance management

sub construct_instance ($self, $repr) {
    return bless $repr => $self->name;
}

1;

__END__