package mop::class;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

use B            ();
use Sub::Name    ();
use Scalar::Util ();

use mop::internal::util;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our @ISA = ('mop::object');

sub new ($class, %args) {
    my $name = $args{'name'} || die 'The class `name` is required';
    {
        # NOTE:
        # we are doing what mop::object::new might do
        # expect that we are not actually calling that
        # method (it will infinitely recurse), this is 
        # intentional, we can bootstrap later if we 
        # actually need to.
        # - SL
        no strict 'refs';
        Variable::Magic::cast( 
            %{ $name . '::' }, 
            mop::internal::util::get_wiz(),
            {
                id    => mop::internal::util::next_oid(),
                slots => {}
            } 
        );
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

# instance construction 

sub construct_instance ($self, $candidate, $args) {

    my $wiz  = mop::internal::util::get_wiz();
    my $data = {
        id    => mop::internal::util::next_oid(),
        slots => { %$args }
    };

    my $repr_type = ref $candidate;
    if ( $repr_type eq 'HASH' ) {
        Variable::Magic::cast( %$candidate, $wiz, $data );
    } 
    elsif ( $repr_type eq 'ARRAY' ) {
        Variable::Magic::cast( @$candidate, $wiz, $data );
    } 
    elsif ( $repr_type eq 'SCALAR' ) {
        Variable::Magic::cast( $$candidate, $wiz, $data );
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
    return @{ *{ $ISA }{'ARRAY'} };
}

sub mro ($self, $type = mro::get_mro( $self->name )) { 
    return @{ mro::get_linear_isa( $self->name, $type ) };
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