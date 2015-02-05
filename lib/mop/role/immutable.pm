package mop::role::immutable;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

#use mop::internal::util 'FINALIZE';

our @ISA; BEGIN { @ISA = ('mop::object') }

sub new ($class, %args) {
    die "The parameter 'name' is required, and it must be a string"
        unless exists  $args{'name'} 
            && defined $args{'name'} 
            && length  $args{'name'} > 0;

    my $stash;
    {
        no strict 'refs';
        $stash = \%{ $args{'name'} . '::' };
    }

    my $self = bless \$stash => $class;
    $self->can('BUILD') && mop::internal::util::BUILDALL( $self, \%args );
    $self;    
}

=pod

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

=cut

# access additional package data 

sub is_closed ($self) { 
    return 0 unless exists $self->$*->{'IS_CLOSED'};
    return $self->$*->{'IS_CLOSED'}->*{'SCALAR'}->$* ? 1 : 0;
}

# ...

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

sub run_all_finalizers ($self) { $_->() for $self->finalizers }

# roles 

sub roles ($self) {
    my $DOES = $self->$*->{'DOES'};
    return () unless $DOES;
    my $roles = $DOES->*{'ARRAY'};
    return () unless $roles;
    return @$roles;
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
        if ( $attr->stash_name eq $self->name || ($self->roles && $attr->was_aliased_from( $self->roles )) ){
            push @attrs => $attr;
        }
    }
    return @attrs;
}

sub has_attribute ($self, $name) {
    my $HAS = $self->$*->{'HAS'};
    return 0 unless $HAS;

    my $attrs = $HAS->*{'HASH'};
    return 0 unless exists $attrs->{ $name };
    
    my $attr = mop::attribute->new( name => $name, initializer => $attrs->{ $name } );
    return 0 unless $attr->stash_name eq $self->name || ($self->roles && $attr->was_aliased_from( $self->roles ));

    return 1;
}

sub has_attribute_alias ($self, $name) {
    my $HAS = $self->$*->{'HAS'};
    return 0 unless $HAS;

    my $attrs = $HAS->*{'HASH'};
    return 0 unless exists $attrs->{ $name };
    
    my $attr = mop::attribute->new( name => $name, initializer => $attrs->{ $name } );
    return 1 if $attr->stash_name ne $self->name;
    return 0;
}

sub get_attribute ($self, $name) {
    my $HAS = $self->$*->{'HAS'};
    return unless $HAS;

    my $attrs = $HAS->*{'HASH'};
    return unless exists $attrs->{ $name };
    
    my $attr = mop::attribute->new( name => $name, initializer => $attrs->{ $name } );
    return unless $attr->stash_name eq $self->name || ($self->roles && $attr->was_aliased_from( $self->roles ));
    
    return $attr;
}

# required methods

sub required_methods ($self) {
    my @required;
    foreach my $candidate ( keys $self->$*->%* ) {
        if ( my $glob = \($self->$*->{ $candidate }) ) {
            # if it is a GLOB ref then ...
            if (ref $glob eq 'GLOB') {
                # check the CODE slot for it, if 
                # we do not have CODE slot, then
                # we can move on ...
                next if not defined $glob->*{'CODE'};
                # if our CODE slot is defined, lets 
                # check it in more detail ...
                my $op = B::svref_2object( $glob->*{'CODE'} );
                # if it is not a CV or the ROOT of it is
                # not a NULL op, then we move on ...
                next if not( $op->isa('B::CV') && $op->ROOT->isa('B::NULL') );
            }
            else {
                next if ref $glob ne 'SCALAR';
                next if not defined $glob->$*;
                next if $glob->$* != -1;
            }
            push @required => $candidate;
        }
    }
    return @required;
}

sub requires_method ($self, $name) {
    return 0 unless exists $self->$*->{ $name };
    my $glob = \($self->$*->{ $name });
    # if it is a GLOB ref then ...
    if (ref $glob eq 'GLOB') {
        # check the CODE slot for it, if 
        # we do not have CODE slot, then
        # we can move on ...
        return 0 if not defined $glob->*{'CODE'};
        # if our CODE slot is defined, lets 
        # check it in more detail ...
        my $op = B::svref_2object( $glob->*{'CODE'} );
        # if it is not a CV or the ROOT of it is
        # not a NULL op, then we move on ...
        return 1 if $op->isa('B::CV') && $op->ROOT->isa('B::NULL');
        return 0;
    }
    else {
        return 0 if ref $glob ne 'SCALAR';
        return 0 if not defined $glob->$*;
        return 1 if $glob->$* == -1;
    }
    die "[mop::PANIC] I found a (" . (ref $glob) . ") with a value of (" . $glob->$* . ") at '$name', I expected a GLOB or a SCALAR";
}

# methods 

sub methods ($self) {
    my @methods;
    foreach my $candidate ( keys $self->$*->%* ) {
        if ( exists $self->$*->{ $candidate } ) {
            my $glob = \($self->$*->{ $candidate });
            next unless ref $glob eq 'GLOB';
            if ( my $code = $glob->$*->*{'CODE'} ) {
                
                my $op = B::svref_2object( $glob->*{'CODE'} );
                next if $op->isa('B::CV') 
                     && $op->ROOT->isa('B::NULL') 
                     && !$op->XSUB;

                $code = mop::method->new( body => $code );
                if ( $code->stash_name eq $self->name || ($self->roles && $code->was_aliased_from( $self->roles )) ){
                    push @methods => $code;
                }
            }
        }
    }
    return @methods;
}

sub has_method ($self, $name) {
    return 0 unless exists $self->$*->{ $name };
    my $glob = \($self->$*->{ $name });
    return 0 unless ref $glob eq 'GLOB';
    if ( my $code = $glob->$*->*{'CODE'} ) {

        my $op = B::svref_2object( $glob->*{'CODE'} );
        return 0 if $op->isa('B::CV') 
                 && $op->ROOT->isa('B::NULL')
                 && !$op->XSUB;

        $code = mop::method->new( body => $code );
        return 0 unless $code->stash_name eq $self->name || ($self->roles && $code->was_aliased_from( $self->roles ));
        return 1;
    }
    return 0;
}

sub has_method_alias ($self, $name) {
    return 0 unless exists $self->$*->{ $name };
    my $glob = \($self->$*->{ $name });
    return 0 unless ref $glob eq 'GLOB';
    if ( my $code = $glob->$*->*{'CODE'} ) {
        my $op = B::svref_2object( $glob->*{'CODE'} );
        return 0 if $op->isa('B::CV') 
                 && $op->ROOT->isa('B::NULL')
                 && !$op->XSUB;

        $code = mop::method->new( body => $code );
        return 1 if $code->stash_name ne $self->name;
    }
    return 0;
}

sub get_method ($self, $name) {
    return unless exists $self->$*->{ $name };
    my $glob = \($self->$*->{ $name });
    return unless ref $glob eq 'GLOB';
    if ( my $code = $glob->$*->*{'CODE'} ) {    
        my $op = B::svref_2object( $glob->*{'CODE'} );
        return if $op->isa('B::CV') 
               && $op->ROOT->isa('B::NULL')
               && !$op->XSUB;

        $code = mop::method->new( body => $code );
        return unless $code->stash_name eq $self->name || ($self->roles && $code->was_aliased_from( $self->roles ));
        return $code;
    }
    return;
}

# FINALIZE

BEGIN {
    our $IS_CLOSED;
    our @FINALIZERS = ( sub { $IS_CLOSED = 1 } );
}

1;

__END__