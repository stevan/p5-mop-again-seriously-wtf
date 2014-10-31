package mop::role;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

use Symbol          ();
use Sub::Name       ();
use Scalar::Util    ();

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

    mop::internal::package::UPGRADE_PACKAGE( $stash, %args ) 
        unless mop::internal::package::IS_PACKAGE_UPGRADED( $stash );

    return bless \$stash => $class;
}

# access to the package itself

sub stash ( $self ) { return $self->$* }

# meta-info 

sub name ($self) { 
    B::svref_2object( $self->$* )->NAME;
}

sub version ($self) { 
    return unless exists $self->$*->{'VERSION'};
    return $self->$*->{'VERSION'}->*{'SCALAR'}->$*;
}

sub authority ($self) { 
    return unless exists $self->$*->{'AUTHORITY'};
    return $self->$*->{'AUTHORITY'}->*{'SCALAR'}->$*;
}

# access additional package data 

sub is_closed ($self) { 
    mop::internal::package::IS_PACKAGE_CLOSED( $self->$* )
}

# roles 

sub roles ($self) {
    my $DOES = $self->$*->{'DOES'};
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
    foreach my $candidate ( keys $self->$*->%* ) {
        if ( my $code = $self->$*->{ $candidate }->*{'CODE'} ) {
            $code = mop::method->new( body => $code );
            if ( $code->stash_name eq $self->name || $code->was_aliased_from( $self->roles ) ) {
                push @methods => $code;
            }
        }
    }
    return @methods;
}

sub has_method ($self, $name) {
    return 0 unless exists $self->$*->{ $name };
    if ( my $code = $self->$*->{ $name }->*{'CODE'} ) {
        $code = mop::method->new( body => $code );
        return 0 unless $code->stash_name eq $self->name or $code->was_aliased_from( $self->roles );
        return 1;
    }
    return 0;
}

sub get_method ($self, $name) {
    return unless exists $self->$*->{ $name };
    if ( my $code = $self->$*->{ $name }->*{'CODE'} ) {
        $code = mop::method->new( body => $code );
        return unless $code->stash_name eq $self->name or $code->was_aliased_from( $self->roles );
        return $code;
    }
    return;
}

sub delete_method ($self, $name) {
    die "[PANIC] Cannot delete method ($name) from (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    return unless exists $self->$*->{ $name };
    if ( my $code = $self->$*->{ $name }->*{'CODE'} ) {
        $code = mop::method->new( body => $code );
        return unless $code->stash_name eq $self->name or $code->was_aliased_from( $self->roles );
        my $glob = $self->$*->{ $name };      
        my %to_save;
        foreach my $type (qw[ SCALAR ARRAY HASH IO ]) {
            if ( my $val = $glob->*{ $type } ) {
                $to_save{ $type } = $val;
            }
        }
        $self->$*->{ $name } = Symbol::gensym();
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
    die "[PANIC] Cannot add method ($name) to (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    no strict 'refs';
    my $full_name = $self->name . '::' . $name;
    *{$full_name} = Sub::Name::subname( 
        $full_name, 
        Scalar::Util::blessed($code) ? $code->body : $code
    );
}

sub alias_method ($self, $name, $code) {
    die "[PANIC] Cannot alias method ($name) to (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    no strict 'refs';
    *{ $self->name . '::' . $name } = Scalar::Util::blessed($code) ? $code->body : $code;
}

# Finalizer 

UNITCHECK { 
    # NOTE:
    # We need to close mop::role here as well.
    my $meta = __PACKAGE__->new( name => __PACKAGE__ ); 
    mop::internal::package::CLOSE_PACKAGE( $meta->stash );
}

1;

__END__