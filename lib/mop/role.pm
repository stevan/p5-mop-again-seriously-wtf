package mop::role;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use B            ();
use Symbol       ();
use Sub::Util    ();
use Scalar::Util ();

use mop::internal::util 'FINALIZE';

our @ISA; BEGIN { @ISA = ('mop::object') }

sub new ($class, %args) {
    die "The parameter 'name' is required, and it must be a string"
        unless exists  $args{'name'} 
            && defined $args{'name'} 
            && length  $args{'name'} > 0;

    my $self = bless mop::internal::newMopMpV( $args{'name'} ) => $class;
    $self->can('BUILD') && mop::internal::util::BUILDALL( $self, \%args );
    $self;    
}

# access additional package data 

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

sub add_finalizer ($self, $finalizer) {
    die "[mop::PANIC] Cannot add finalizer to (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    unless ( $self->$*->{'FINALIZERS'} ) {
        no strict 'refs';
        no warnings 'once';
        *{ $self->name . '::FINALIZERS'} = [ $finalizer ];
    }
    else {
        push $self->$*->{'FINALIZERS'}->*{'ARRAY'}->@* => $finalizer;
    }
}

sub run_all_finalizers ($self) { $_->() for $self->finalizers }

# roles 

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
    die "[mop::PANIC] Cannot add attribute ($name) to (" . $self->name . ") because it has been closed"
        if $self->is_closed;

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
    die "[mop::PANIC] Cannot alias method ($name) to (" . $self->name . ") because it has been closed"
        if $self->is_closed;

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

sub add_required_method ($self, $name) {
    die "[mop::PANIC] Cannot add a method requirement ($name) to (" . $self->name . ") because it has been closed"
        if $self->is_closed;

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
    die "[mop::PANIC] Cannot delete method requirement ($name) from (" . $self->name . ") because it has been closed"
        if $self->is_closed;

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

sub delete_method ($self, $name) {
    die "[mop::PANIC] Cannot delete method ($name) from (" . $self->name . ") because it has been closed"
        if $self->is_closed;

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
    die "[mop::PANIC] Cannot add method ($name) to (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    no strict 'refs';
    no warnings 'once';
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
    no warnings 'once', 'redefine';
    *{ $self->name . '::' . $name } = Scalar::Util::blessed($code) ? $code->body : $code;
}

# Finalization

BEGIN {
    our $IS_CLOSED;
    our @FINALIZERS = ( sub { $IS_CLOSED = 1 } );
}

1;

__END__