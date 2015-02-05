package mop::role::mutable;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Symbol       ();
use Sub::Util    ();
use Scalar::Util ();

#use mop::internal::util 'FINALIZE';

our @ISA; BEGIN { @ISA = ('mop::role::immutable') }

# access additional package data 

sub set_is_closed ($self, $value) {
    no strict 'refs';
    no warnings 'once';
    ${ $self->name . '::IS_CLOSED'} = $value;
}

sub set_is_abstract ($self, $value) {
    no strict 'refs';
    no warnings 'once';
    ${ $self->name . '::IS_ABSTRACT'} = $value;
}

# finalization 

sub add_finalizer ($self, $finalizer) {
    unless ( $self->$*->{'FINALIZERS'} ) {
        no strict 'refs';
        no warnings 'once';
        *{ $self->name . '::FINALIZERS'} = [ $finalizer ];
    }
    else {
        push $self->$*->{'FINALIZERS'}->*{'ARRAY'}->@* => $finalizer;
    }
}

# roles 

sub set_roles ($self, @roles) {
    no strict 'refs';
    no warnings 'once';
    @{ $self->name . '::DOES'} = ( @roles );
}

# attributes 

sub delete_attribute ($self, $name) {
    my $HAS = $self->$*->{'HAS'};
    return unless $HAS;

    my $attrs = $HAS->*{'HASH'};
    return unless exists $attrs->{ $name };
    
    my $attr = mop::attribute->new( name => $name, initializer => $attrs->{ $name } );
    return unless $attr->stash_name eq $self->name || ($self->roles && $attr->was_aliased_from( $self->roles ));
    
    return delete $attrs->{ $name };
}

sub add_attribute ($self, $name, $initializer) {

    $initializer = $initializer->initializer
        if Scalar::Util::blessed($initializer);

    # make sure to set this up correctly ...
    Sub::Util::set_subname(($self->name . '::__ANON__'), $initializer);

    unless ( $self->$*->{'HAS'} ) {
        no strict 'refs';
        no warnings 'once';
        %{ $self->name . '::HAS'} = ( $name => $initializer );
    }
    else {
        my $HAS = $self->$*->{'HAS'}->*{'HASH'};   
        $HAS->{ $name } = $initializer;
    }
}

sub alias_attribute ($self, $name, $initializer) {

    $initializer = $initializer->initializer
        if Scalar::Util::blessed($initializer);

    unless ( $self->$*->{'HAS'} ) {
        no strict 'refs';
        no warnings 'once';
        %{ $self->name . '::HAS'} = ( $name => $initializer );
    }
    else {
        my $HAS = $self->$*->{'HAS'}->*{'HASH'};   
        $HAS->{ $name } = $initializer;
    }
}

# required methods

sub add_required_method ($self, $name) {

    if ( exists $self->$*->{ $name } ) {
        my $glob = \($self->$*->{ $name });
        # NOTE: 
        # If something happens to autovivify the
        # typeglob for this $name, we need to look
        # a little closer. This situation can be 
        # caused by any number of things, such as 
        # calling ->can($name) or having another 
        # type of variable (SCALAR, ARRAY, HASH)
        # with the same $name. Basically it can 
        # only be a C<sub foo;> and nothing else.
        # - SL
        if (ref $glob eq 'GLOB') {

            # if we have a glob, but just not 
            # the CODE slot for it, then we can 
            # install our required method.
            if ( not defined $glob->*{'CODE'} ) {
                my $pkg_name = $self->name;
                eval "package $pkg_name { sub ${name}; }; 1;" or do { warn $@ };
                return;
            } else {
                # if our CODE slot is defined, lets 
                # check it in more detail ...
                my $op = B::svref_2object( $glob->*{'CODE'} );
                # if it is a CV and the ROOT of it is a NULL op
                # then we know there already is a required method
                # and we can just return 
                return if $op->isa('B::CV') && $op->ROOT->isa('B::NULL');
                # otherwise we just return because we
                # know that we have a CODE ref that is
                # actually not a required sub, it is a
                # regular one, which would fulfill the 
                # the requirements anyway
                return;
            }

        }
        else {
        
            # if it is just a SCALAR ref or derefs 
            # to -1, then we already require that 
            # method, so we can just skip.
            return if ref $glob->$* eq 'SCALAR';
            return if $glob->$* == -1;
        }
        die "[mop::PANIC] I found a (" . (ref $glob) . ") with a value of (" . $glob->$* . ") at '$name', I expected a GLOB or a SCALAR";
    }
    else {
        $self->$*->{ $name } = -1;
    }
}

sub delete_required_method ($self, $name) {

    return unless exists $self->$*->{ $name };
    
    my $glob = \($self->$*->{ $name });

    # if it is a GLOB ref then ...
    if (ref $glob eq 'GLOB') {
        # if we have a glob, but just not 
        # the CODE slot for it, then we can 
        # just return because we don't have 
        # a required method here ...
        return if not defined $glob->*{'CODE'};
        # if our CODE slot is defined, lets 
        # check it in more detail ...
        my $op = B::svref_2object( $glob->*{'CODE'} );
        # if it is a CV and the ROOT of it is a NULL op
        # then we know there already is a required method
        # and we can just return 
        if ( $op->isa('B::CV') && $op->ROOT->isa('B::NULL') ) {
            return delete $self->$*->{ $name }
        }
    }
    else {
        return if ref $glob ne 'SCALAR';
        return if not defined $glob->$*;

        if ( $glob->$* == -1 ) {
            return delete $self->$*->{ $name };
        }
    }    

    die "[mop::PANIC] I found a (" . (ref $glob) . ") with a value of (" . $glob->$* . ") at '$name', I expected a GLOB or a SCALAR";
}

# methods 

sub delete_method ($self, $name) {

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
            no warnings 'once';
            foreach my $type ( keys %to_save ) {
                *{ $self->name . '::' . $name } = $to_save{ $type };
            }
        }
        return $code;
    }
    return;
}

sub add_method ($self, $name, $code) {
    no strict 'refs';
    no warnings 'once', 'redefine';
    my $full_name = $self->name . '::' . $name;
    *{$full_name} = Sub::Util::set_subname( 
        $full_name, 
        Scalar::Util::blessed($code) ? $code->body : $code
    );
}

sub alias_method ($self, $name, $code) {
    no strict 'refs';
    no warnings 'once', 'redefine';
    *{ $self->name . '::' . $name } = Scalar::Util::blessed($code) ? $code->body : $code;
}

# FINALIZE

BEGIN {
    our $IS_CLOSED;
    our @FINALIZERS = ( sub { $IS_CLOSED = 1 } );
}


1;

__END__