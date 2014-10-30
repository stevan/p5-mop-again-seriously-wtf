package mop::role;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

use Symbol       ();
use Sub::Name    ();
use Scalar::Util ();

use mop::internal::util;
use mop::internal::finalize;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our @ISA; BEGIN { @ISA = ('mop::object') }

sub new ($class, %args) {
    my $name = $args{'name'} || die 'The role `name` is required';
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

# roles 

sub roles ($self) {
    my $DOES = $self->{'DOES'};
    return () unless $DOES;
    return $DOES->*{'ARRAY'}->@*;
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