package mop::class;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

use B         ();
use Sub::Name ();

sub new ($class, %args) {
    my $name = $args{'name'} || die 'The class `name` is required';
    {
        no strict 'refs';
        return bless \%{ $name . '::' } => $class;
    }
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

# methods 

sub methods ($self) {
    my @methods;
    foreach my $candidate ( keys %$self ) {
        if ( my $code = $self->{ $candidate }->*{'CODE'} ) {
            if ( B::svref_2object( $code )->GV->STASH->NAME eq $self->name ) {
                push @methods => $code;
            }
        }
    }
    return @methods;
}

sub has_method ($self, $name) {
    return 0 unless exists $self->{ $name };
    if ( my $code = $self->{ $name }->*{'CODE'} ) {
        return 0 unless B::svref_2object( $code )->GV->STASH->NAME eq $self->name;
        return 1;
    }
    return 0;
}

sub get_method ($self, $name) {
    return unless exists $self->{ $name };
    if ( my $code = $self->{ $name }->*{'CODE'} ) {
        return unless B::svref_2object( $code )->GV->STASH->NAME eq $self->name;
        return $code;
    }
    return;
}

sub delete_method ($self, $name) {
    return unless exists $self->{ $name };
    if ( my $code = $self->{ $name }->*{'CODE'} ) {
        return unless B::svref_2object( $code )->GV->STASH->NAME eq $self->name;
        my $glob = delete $self->{ $name };
        my %to_save;
        foreach my $type (qw[ SCALAR ARRAY HASH IO ]) {
            if ( my $val = $glob->*{ $type } ) {
                $to_save{ $type } = $val;
            }
        }
        {
            no strict 'refs';
            foreach my $type ( keys %to_save ) {
                *{ $self->name . '::' . $name } = $to_save{ $type };
            }
        }
        return $code;
    }
    return;
}

sub add_method ($self, $name, $code) {
    my $full_name = $self->name . '::' . $name;
    {
        no strict 'refs';
        *{$full_name} = Sub::Name::subname( $full_name, $code );
    }
}

1;

__END__