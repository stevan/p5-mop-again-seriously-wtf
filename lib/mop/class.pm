package mop::class;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

use B               ();
use Variable::Magic ();

my $ID  = 0;
my $WIZ = Variable::Magic::wizard( data => sub { $_[1] } );

sub new ($class, $name) {

    my $self;

    no strict 'refs';

    # no need to add magic if 
    # this magic has already 
    # been attached to it 
    unless ( Variable::Magic::getdata( %{ $name . '::' }, $WIZ ) ) {
        Variable::Magic::cast( %{ $name . '::' }, $WIZ, {
            id    => $ID++,
            class => \$self,
            slots => {}
        });
    }

    # but still want to return
    # the reference just the 
    # same
    $self = bless \%{ $name . '::' } => $class;
}

sub id ($self) { 
    my $opaque = Variable::Magic::getdata( %$self, $WIZ );
    return $opaque->{id};
}

sub class ($self) { 
    my $opaque = Variable::Magic::getdata( %$self, $WIZ );
    return $opaque->{class}->$*;
}

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

sub superclasses ($self) {
    my $ISA = $self->{'ISA'};
    return () unless $ISA;
    return @{ *{ $ISA }{'ARRAY'} };
}

sub mro ($self, $type = mro::get_mro( $self->name )) { 
    return @{ mro::get_linear_isa( $self->name, $type ) };
}

sub construct_instance ($self, $repr) {
    return bless $repr => $self->name;
}

1;

__END__