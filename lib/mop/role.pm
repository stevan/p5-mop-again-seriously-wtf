package mop::role;

use v5.20;
use mro;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures', 'experimental::postderef';

use Symbol       ();
use Sub::Util    ();
use Scalar::Util ();

use mop::internal::util FINALIZE => 'UNITCHECK';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our @ISA; BEGIN { @ISA = ('mop::object') }

sub new ($class, %args) {
    die 'The parameter `name` is required, and it must be a string'
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

sub set_is_closed ($self, $value) {
    die "[mop::PANIC] Cannot set is_closed in (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    no strict 'refs';
    no warnings 'once';
    ${ $self->name . '::IS_CLOSED'} = $value;
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

sub set_is_abstract ($self, $value) {
    die "[mop::PANIC] Cannot set is_abstract in (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    no strict 'refs';
    no warnings 'once';
    ${ $self->name . '::IS_ABSTRACT'} = $value;
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
        no warnings 'once';
        *{ $self->name . '::FINALIZERS'} = [ $finalizer ];
    }
    else {
        push $self->$*->{'FINALIZERS'}->*{'ARRAY'}->@* => $finalizer;
    }
}

sub run_all_finalizers ($self) { $_->() for $self->finalizers }

# roles 

sub roles ($self) {
    my $DOES = $self->$*->{'DOES'};
    return () unless $DOES;
    return $DOES->*{'ARRAY'}->@*;
}

sub set_roles ($self, @roles) {
    die "[mop::PANIC] Cannot set roles in (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    no strict 'refs';
    no warnings 'once';
    @{ $self->name . '::DOES'} = ( @roles );
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
        if ( $attr->stash_name eq $self->name or $attr->was_aliased_from( $self->roles ) ) {
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
    return 0 unless $attr->stash_name eq $self->name or $attr->was_aliased_from( $self->roles );

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
    return unless $attr->stash_name eq $self->name or $attr->was_aliased_from( $self->roles );
    
    return $attr;
}

sub delete_attribute ($self, $name) {
    my $HAS = $self->$*->{'HAS'};
    return unless $HAS;

    my $attrs = $HAS->*{'HASH'};
    return unless exists $attrs->{ $name };
    
    my $attr = mop::attribute->new( name => $name, initializer => $attrs->{ $name } );
    return unless $attr->stash_name eq $self->name or $attr->was_aliased_from( $self->roles );
    
    return delete $attrs->{ $name };
}

sub add_attribute ($self, $name, $initializer) {
    die "[mop::PANIC] Cannot add attribute ($name) to (" . $self->name . ") because it has been closed"
        if $self->is_closed;

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
            next if ref $glob eq 'GLOB';
            next if ref $glob ne 'SCALAR';
            next if not defined $glob->$*;
            push @required => $candidate if $glob->$* == -1;
        }
    }
    return @required;
}

sub requires_method ($self, $name) {
    return 0 unless exists $self->$*->{ $name };
    my $glob = \($self->$*->{ $name });
    return 0 if ref $glob eq 'GLOB';
    return 0 if ref $glob ne 'SCALAR';
    return 0 if not defined $glob->$*;
    return 1 if $glob->$* == -1;
    die "[mop::PANIC] I found a (" . (ref $glob) . ") with a value of (" . $glob->$* . ") at '$name', I expected a GLOB or a SCALAR";
}

sub add_required_method ($self, $name) {
    die "[mop::PANIC] Cannot add a method requirement ($name) to (" . $self->name . ") because it has been closed"
        if $self->is_closed;

    if ( exists $self->$*->{ $name } ) {
        my $glob = \($self->$*->{ $name });
        # NOTE: 
        # If something happens to autovivify the
        # typeglob for this $name, then this will 
        # throw the exception below. This can be 
        # caused by any number of things, such as 
        # calling ->can($name) or having another 
        # type of variable (SCALAR, ARRAY, HASH)
        # with the same $name. Basically it can 
        # only be a C<sub foo;> and nothing else.
        # 
        # It is possible this is just too fragile
        # but perhaps we can do something on the 
        # XS side later on to better capture this
        # and remove some of the fragility.
        # - SL
        die "[mop::PANIC] Cannot add a method requirement ($name) because a typeglob exists for ($name) and we cannot easily determine if method is required or not"
            if ref $glob eq 'GLOB'
            || ref $glob ne 'SCALAR'
            || not defined $glob->$*;
        # if it is just a SCALAR ref and derefs 
        # to -1, then we already require that 
        # method, so we can just skip.
        return if $glob->$* == -1;
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
    return if ref $glob eq 'GLOB';
    return if ref $glob ne 'SCALAR';
    return if not defined $glob->$*;

    if ( $glob->$* == -1 ) {
        return delete $self->$*->{ $name };
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
                $code = mop::method->new( body => $code );
                if ( $code->stash_name eq $self->name or $code->was_aliased_from( $self->roles ) ) {
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
        $code = mop::method->new( body => $code );
        return 0 unless $code->stash_name eq $self->name or $code->was_aliased_from( $self->roles );
        return 1;
    }
    return 0;
}

sub has_method_alias ($self, $name) {
    return 0 unless exists $self->$*->{ $name };
    my $glob = \($self->$*->{ $name });
    return 0 unless ref $glob eq 'GLOB';
    if ( my $code = $glob->$*->*{'CODE'} ) {
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

    my $glob = \($self->$*->{ $name });
    return unless ref $glob eq 'GLOB';

    if ( my $code = $glob->$*->*{'CODE'} ) {
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
    no warnings 'once';
    *{ $self->name . '::' . $name } = Scalar::Util::blessed($code) ? $code->body : $code;
}

# Finalization

BEGIN {
    our $IS_CLOSED;
    our @FINALIZERS = ( sub { $IS_CLOSED = 1 } );
}

1;

__END__