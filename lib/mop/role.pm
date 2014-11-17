package mop::role;

use v5.20;
use mro;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures', 'experimental::postderef';

use Symbol       ();
use Sub::Util    ();
use Scalar::Util ();

use mop::internal::util 'FINALIZE';

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

    my $self = bless \$stash => $class;
    $self->can('BUILD') && mop::internal::util::BUILDALL( $self, \%args );
    $self;    
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
    return 0 unless exists $self->$*->{'IS_CLOSED'};
    return $self->$*->{'IS_CLOSED'}->*{'SCALAR'}->$* ? 1 : 0;
}

sub is_abstract ($self) {
    # if you have required methods, you are abstract
    # that is a hard enforced rule here ...
    my $default = scalar $self->required_methods ? 1 : 0;
    # if there is no $IS_ABSTRACT variable, return the 
    # calculated default ...
    return $default unless exists $self->$*->{'IS_ABSTRACT'};
    # if there is an $IS_ABSTRACT variable, only allow a 
    # true value to override the calculated default
    return $self->$*->{'IS_ABSTRACT'}->*{'SCALAR'}->$* ? 1 : $default;
    # this approach should allow someone to create 
    # an abstract class even if they do not have any
    # required methods, but also keep the strict 
    # checking of required methods as a indicator 
    # of abstract-ness
}

# finalization 

sub finalizers ($self) {
    my $FINALIZERS = $self->$*->{'FINALIZERS'};
    return () unless $FINALIZERS;
    return $FINALIZERS->*{'ARRAY'}->@*;
}

sub has_finalizers ($self) {
    return 0 unless exists $self->$*->{'FINALIZERS'};
    return (scalar $self->$*->{'FINALIZERS'}->*{'ARRAY'}->@*) ? 1 : 0;
}

sub add_finalizer ($self, $finalizer) {
    die "[mop::PANIC] Cannot add finalizer to (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    unless ( $self->$*->{'FINALIZERS'} ) {
        no strict 'refs';
        *{ $self->name . '::FINALIZERS'} = [ $finalizer ];
    }
    else {
        push $self->$*->{'FINALIZERS'}->*{'ARRAY'}->@* => $finalizer;
    }
}

sub finalize_class ($self) { $_->() for $self->finalizers }

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

# attributes 

sub attributes ($self) {
    my $HAS = $self->$*->{'HAS'};
    return () unless $HAS;

    my $attrs = $HAS->*{'HASH'};
    return () unless keys %$attrs;

    my @attrs;
    foreach my $candidate ( keys %$attrs ) {
        my $attr = mop::attribute->new( name => $candidate, initializer => $attrs->{ $candidate } );
        if ( $attr->stash_name eq $self->name || $attr->was_aliased_from( $self->roles ) ) {
            push @attrs => $attr;
        }
    }
    return @attrs;
}

sub has_attribute ($self, $name) {
    # TODO
}

sub get_attribute ($self, $name) {
    # TODO
}

sub delete_attribute ($self, $name) {
    # TODO
}

sub add_attribute ($self, $name, $initializer) {
    die "[mop::PANIC] Cannot add attribute ($name) to (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    unless ( $self->$*->{'HAS'} ) {
        no strict 'refs';
        %{ $self->name . '::HAS'} = ( $name => $initializer );
    }
    else {
        my $HAS = $self->$*->{'HAS'}->*{'HASH'};   
        $HAS->{ $name } = Sub::Util::set_subname(
            ($self->name . '::__ANON__'),
            $initializer
        );
    }
}

sub alias_attribute ($self, $name, $initializer) {
    die "[mop::PANIC] Cannot alias method ($name) to (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    unless ( $self->$*->{'HAS'} ) {
        no strict 'refs';
        %{ $self->name . '::HAS'} = ( $name => $initializer );
    }
    else {
        my $HAS = $self->$*->{'HAS'}->*{'HASH'};   
        $HAS->{ $name } = $initializer;
    }
}

# required methods

sub required_methods ($self) {
    my $REQUIRES = $self->$*->{'REQUIRES'};
    return () unless $REQUIRES;
    return $REQUIRES->*{'ARRAY'}->@*;
}

sub requires_method ($self, $name) {
    my $REQUIRES = $self->$*->{'REQUIRES'};
    return 0 unless $REQUIRES;
    foreach ( $REQUIRES->*{'ARRAY'}->@* ) {
        return 1 if $_ eq $name;
    }
    return 0;
}

sub add_required_method ($self, $name) {
    die "[mop::PANIC] Cannot add a method requirement ($name) to (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    unless ( $self->$*->{'REQUIRES'} ) {
        no strict 'refs';
        *{ $self->name . '::REQUIRES'} = [ $name ];
    }
    else {
        my $REQUIRES = $self->$*->{'REQUIRES'}->*{'ARRAY'};   
        foreach ( $REQUIRES->@* ) {
            return if $_ eq $name;
        }
        push $REQUIRES->@* => $name;
    }
}

sub delete_required_method ($self, $name) {
    die "[mop::PANIC] Cannot delete method requirement ($name) from (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    return unless $self->$*->{'REQUIRES'};
    my $REQUIRES = $self->$*->{'REQUIRES'}->*{'ARRAY'};
    $REQUIRES->@* = grep { $_ ne $name } $REQUIRES->@*;
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
    die "[mop::PANIC] Cannot delete method ($name) from (" . $self->name . ") because it has been closed"
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
    die "[mop::PANIC] Cannot add method ($name) to (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    no strict 'refs';
    my $full_name = $self->name . '::' . $name;
    *{$full_name} = Sub::Util::set_subname( 
        $full_name, 
        Scalar::Util::blessed($code) ? $code->body : $code
    );
}

sub alias_method ($self, $name, $code) {
    die "[mop::PANIC] Cannot alias method ($name) to (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    no strict 'refs';
    *{ $self->name . '::' . $name } = Scalar::Util::blessed($code) ? $code->body : $code;
}

# Finalization

BEGIN {
    our $IS_CLOSED;
    our @FINALIZERS = ( sub { $IS_CLOSED = 1 } );
}

1;

__END__