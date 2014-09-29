package mop::class;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

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
            slots => {
                '$!name' => $name,
            }
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
    my $opaque = Variable::Magic::getdata( %$self, $WIZ );
    return $opaque->{slots}->{'$!name'};
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



1;

__END__