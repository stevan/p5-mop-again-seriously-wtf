package mop::role;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

use Symbol       ();
use Sub::Name    ();
use Scalar::Util ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our @ISA; BEGIN { @ISA = ('mop::object') }

sub new ($class, %args) {
    my $name = $args{'name'} or die 'The role `name` is required';
    my $stash;
    {
        no strict 'refs';
        $stash = \%{ $name . '::' };
    }

    # no need to rebless anything
    return $stash if Scalar::Util::blessed( $stash );

    return bless $stash => $class;
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

# roles 

sub roles ($self) {
    my $DOES = $self->{'DOES'};
    return () unless $DOES;
    return $DOES->*{'ARRAY'}->@*;
}

sub does_role ($self, $role_to_test) {
    # try the simple way first ...
    return 1 if scalar grep { $_ eq $role_to_test } $self->roles;
    # then try the harder way next ...
    return 1 if scalar grep { mop::role->new( name => $_ )->does_role( $role_to_test ) } $self->roles;
    return 0;
}

# methods 

sub methods ($self) {
    my @methods;
    foreach my $candidate ( keys %$self ) {
        if ( my $code = $self->{ $candidate }->*{'CODE'} ) {
            $code = mop::method->new( body => $code );
            if ( $code->stash_name eq $self->name || $code->was_aliased_from( $self->roles ) ) {
                push @methods => $code;
            }
        }
    }
    return @methods;
}

sub has_method ($self, $name) {
    return 0 unless exists $self->{ $name };
    if ( my $code = $self->{ $name }->*{'CODE'} ) {
        $code = mop::method->new( body => $code );
        return 0 unless $code->stash_name eq $self->name or $code->was_aliased_from( $self->roles );
        return 1;
    }
    return 0;
}

sub get_method ($self, $name) {
    return unless exists $self->{ $name };
    if ( my $code = $self->{ $name }->*{'CODE'} ) {
        $code = mop::method->new( body => $code );
        return unless $code->stash_name eq $self->name or $code->was_aliased_from( $self->roles );
        return mop::method->new( body => $code );
    }
    return;
}

sub delete_method ($self, $name) {
    return unless exists $self->{ $name };
    if ( my $code = $self->{ $name }->*{'CODE'} ) {
        $code = mop::method->new( body => $code );
        return unless $code->stash_name eq $self->name or $code->was_aliased_from( $self->roles );
        my $glob = $self->{ $name };      
        my %to_save;
        foreach my $type (qw[ SCALAR ARRAY HASH IO ]) {
            if ( my $val = $glob->*{ $type } ) {
                $to_save{ $type } = $val;
            }
        }
        $self->{ $name } = Symbol::gensym();
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

sub alias_method ($self, $name, $code) {
    no strict 'refs';
    *{ $self->name . '::' . $name } = $code;
}

1;

__END__