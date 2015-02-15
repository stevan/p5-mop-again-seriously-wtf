package Moxie;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

use Module::Runtime ();

use mop;
use mop::internal::util;
use mop::internal::util::syntax;

our %TRAITS;

# TODO:
# Everything that this &import method does should be 
# in util subroutines so that someone else can just
# come in and use it sensibly to implement their own 
# object system if they want. The idea is that the 
# simple, bare bones sugar I provide here is just barely
# one step above the raw version which uses the package
# variables and mop::internal::util::* methods directly
# inside BEGIN blocks, etc. 
#
# In short, there is no need to make people jump through 
# stupid meta-layer subclass stuff in order to maintain 
# a level or purity that perl just doesn't give a fuck
# about anyway. In the 'age of objects' we have forgotten 
# that subroutines are also an excellent form of encapsulation
# and re-use. 
# - SL

sub import ($class, @args) {
    my $caller = caller;

    # make the assumption that if we are 
    # loaded outside of main then we are 
    # likely being loaded in a class, so
    # turn on all the features 
    if ( $caller ne 'main' ) {

        # FIXME:
        # There are a lot of assumptions here that 
        # we are not loading mop.pm in a package 
        # where it might have already been loaded
        # so we might want to keep that in mind 
        # and guard against some of that below, 
        # in particular I think the FINALIZE handlers
        # might need to be checked, and perhaps the
        # 'has' keyword importation as well.
        # - SL

        # NOTE:
        # create the meta-object, we start 
        # with this as a role, but it will 
        # get "cast" to a class if there 
        # is a need for it. 
        my $meta = mop::role->new( name => $caller );

        # install our finalizer feature ...
        mop::internal::util::INSTALL_FINALIZATION_RUNNER( $caller );   

        # turn on strict/warnings
        strict->import;
        warnings->import;

        # turn on signatures ...
        feature->import('signatures');
        warnings->unimport('experimental::signatures');

        # turn on postfixderef ...
        feature->import('postderef');
        warnings->unimport('experimental::postderef');        

        # import has, extend and with keyword
        mop::internal::util::syntax::setup_keyword_handler(
            ($caller, 'has') => sub {
                my ($name, %traits) = @_;

                # this is the only one we handle 
                # specially, everything else gets
                # called as a trait ...
                $traits{default} //= delete $traits{required} 
                                      ? sub { die "[mop::ERROR] The attribute '$name' is required" }
                                      : eval 'sub { undef }'; # we need this to be a unique CV ... sigh

                $meta->add_attribute( $name, delete $traits{default} );

                if ( keys %traits ) {
                    my $attr = $meta->get_attribute( $name );
                    foreach my $k ( keys %traits ) {
                        die "[mop::PANIC] Cannot locate trait ($k) to apply to attributes ($name)"
                            unless exists $TRAITS{ $k };
                        $TRAITS{ $k }->( $meta, $attr, $traits{ $k } );
                    }
                }
                return;
            }
        ); 

        mop::internal::util::syntax::setup_keyword_handler(
            ($caller, 'extends') => sub {
                my @isa = @_;
                Module::Runtime::use_package_optimistically( $_ ) foreach @isa;
                ($meta->isa('mop::class') 
                    ? $meta
                    : (bless $meta => 'mop::class') # cast into class
                )->set_superclasses( @isa );
                return;
            }
        );

        mop::internal::util::syntax::setup_keyword_handler(
            ($caller, 'with') => sub {
                my @does = @_;
                Module::Runtime::use_package_optimistically( $_ ) foreach @does;
                $meta->set_roles( @does );
                return;
            }
        );

        # install our class finalizers
        $meta->add_finalizer(sub { 

            if ( $meta->isa('mop::class') ) {
                # make sure to 'inherit' the required methods ...
                mop::internal::util::INHERIT_REQUIRED_METHODS( $meta );
                # this is an optimization to pre-populate the 
                # cache for all the attributes 
                mop::internal::util::GATHER_ALL_ATTRIBUTES( $meta );
            }

            # apply roles ...
            if ( my @does = $meta->roles ) {
                mop::internal::util::APPLY_ROLES( 
                    $meta, 
                    \@does, 
                    to => ($meta->isa('mop::class') ? 'class' : 'role')
                );
            }

            mop::internal::util::syntax::teardown_keyword_handler( $meta->name, $_ ) 
                foreach qw[ with has extends ];

            $meta->set_is_closed(1);
        });
    }

}

# TODO:
# Move this to a mop::traits module, like in p5-mop-redux
BEGIN {
    $TRAITS{'is'} = sub ($m, $a, $type) {
        my $slot = $a->name;
        if ( $type eq 'ro' ) {
            $m->add_method( $slot => sub { 
                die "Cannot assign to `$slot`, it is a readonly attribute" if scalar @_ != 1;
                $_[0]->{ $slot };
            });
        } elsif ( $type eq 'rw' ) {
            $m->add_method( $slot => sub { 
                $_[0]->{ $slot } = $_[1] if $_[1];
                $_[0]->{ $slot };
            });            
        } else {
            die "[mop::PANIC] Got strange option ($type) to trait (is)";
        }
    };
}

1;

__END__

=pod

=head1 NAME

Moxie

=head1 SYNOPSIS

    package Point {
        use Moxie;

        extends 'mop::object';

        has 'x' => (is => 'ro', default => sub { 0 });
        has 'y' => (is => 'ro', default => sub { 0 });

        sub clear ($self) {
            @{$self}{'x', 'y'} = (0, 0);
        }
    }

    package Point3D {
        use Moxie;

        extends 'Point';

        has 'z' => (is => 'ro', default => sub { 0 });

        sub clear ($self) {
            $self->next::method;
            $self->{'z'} = 0;
        }
    }

=head1 DESCRIPTION

Moxie is a reference implemenation for an object system built 
on top of the mop. It is purposefully meant to be similar to 
the Moose/Mouse/Moo style of classes, but with a number of 
improvements as well.

=cut





