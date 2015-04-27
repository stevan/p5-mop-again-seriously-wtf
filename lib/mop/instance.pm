package mop::instance;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our %GENERATORS;

BEGIN {
    %GENERATORS = (
        HASH   => sub { +{ @_ }                                   },
        ARRAY  => sub { +[ @_ ]                                   },
        SCALAR => sub { my $x = $_[0]; \$x                        }, 
        GLOB   => sub { select select my $fh; %{ *$fh } = @_; $fh },  
        OPAQUE => sub { 
            my %args   = @_;
            my $opaque = mop::internal::newMopOV( \(my $x) );
            mop::internal::opaque::set_at_slot( $opaque, $_, $args{ $_ } ) 
                foreach keys %args;
            return $opaque;
        } 
    ); 
}

sub new ($class, $repr_or_generator) {
    my $generator = ref $repr_or_generator 
        ? $repr_or_generator 
        : ($GENERATORS{ $repr_or_generator } 
            // die "[mop::PANIC] Unsupported repr type '$repr_or_generator'");

    die "[mop::PANIC] the generator for a new instance must be CODE reference"
        unless ref $generator eq 'CODE';    

    my $self = bless \$generator => $class;
    $self->can('BUILD') && mop::internal::util::BUILDALL( $self, {} );
    $self; 
}

sub generator { $_[0]->$* }

sub CREATE ($self, @args) { $self->$*->( @args ) }

sub BLESS ($self, $into_class, @args) {
    my $instance = $self->CREATE( @args );
    bless $instance => $into_class;
}

BEGIN {
    our @FINALIZERS = ( sub { mop::internal::util::CLOSE_CLASS(__PACKAGE__) } );
}

1;

__END__