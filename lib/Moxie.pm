package Moxie;

use v5.20;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures', 'experimental::postderef';

use mop ();

use Symbol;
use Scalar::Util;
use Module::Runtime qw[ use_package_optimistically ];

my (%METACACHE, %TRAITS);

sub import {
    shift;
    my $pkg  = caller;
    my @args = @_;

    my ($current, @extends, @with);
    foreach my $arg ( @args ) {
        if ( $arg eq 'extends' ) {
            $current = \@extends;
        }
        elsif ( $arg eq 'with' ) {
            $current = \@with;
        }
        else {
            push @$current => $arg;
        }
    }

    use_package_optimistically $_ foreach @extends, @with;

    mop::internal::util::INSTALL_FINALIZATION_RUNNER_FOR_ENDOFSCOPE( $pkg );

    my $metatype  = (scalar @extends ? 'class' : 'role'); 
    my $metaclass = 'mop::' . $metatype; 

    my $meta = $metaclass->new( name => $pkg );
    $meta->set_superclasses( @extends ) if $metatype eq 'class';
    if ( @with ) {
        $meta->set_roles( @with );
    }

    strict->import;
    warnings->import;
    feature->import('signatures', 'postderef');
    warnings->unimport('experimental::signatures', 'experimental::postderef');
    {
        no strict 'refs';
        *{$pkg . '::has'}     = \&has;
        *{$pkg . '::blessed'} = \&Scalar::Util::blessed;
    }

    # cleanup ...

    $meta->add_finalizer(sub {

        # first remove the has sub
        {
            no strict 'refs';
            *{$pkg . '::has'} = Symbol::gensym();
        }

        # then process all the attribute traits ...
        foreach my $attribute ( $meta->attributes ) {
            my %traits = %{ $attribute->traits };
            if ( keys %traits ) {
                foreach my $k ( keys %traits ) {
                    die "[Moxie::PANIC] Cannot locate trait ($k) to apply to attributes (" . $attribute->name . ")"
                        unless exists $TRAITS{ $k };
                    $TRAITS{ $k }->( $meta, $attribute, $traits{ $k } );
                }
            }
        }

        # next apply all the roles ...

        # NOTE:
        # This is assumed to take place 
        # after all the attributes have
        # been created and their trait 
        # finalizers have been registered
        # if ever that is not the case, 
        # it should be fixed.
        # - SL
        mop::internal::util::APPLY_ROLES( $meta, \@with, to => $metatype );

        # perform some optimizations

        # because we know we are very 
        # shortly about to close the 
        # class ...
        mop::internal::util::GATHER_ALL_ATTRIBUTES( $meta )
            if $metatype eq 'class';    

        # close the class ...
        $meta->set_is_closed(1);    
    }); 

    $METACACHE{ $pkg } = $meta;
}

sub has ($name, %traits) {
    my $pkg  = caller;
    my $meta = $METACACHE{ $pkg };

    # this is the only one we handle 
    # specially, everything else gets
    # called as a trait ...
    $traits{default} //= eval 'sub { undef }'; # we need this to be a unique CV ... sigh

    $meta->add_attribute( $name, delete $traits{default}, \%traits );

    return;
}

BEGIN {
    $TRAITS{'is'} = sub ($m, $a, $type) {
        my $slot = $a->name;
        if ( $type eq 'ro' ) {
            $m->add_method( $slot => sub { 
                die "Cannot assign to a readonly attribute" if scalar @_ != 1;
                $_[0]->{ $slot };
            });
        } elsif ( $type eq 'rw' ) {
            $m->add_method( $slot => sub { 
                $_[0]->{ $slot } = $_[1] if $_[1];
                $_[0]->{ $slot };
            });            
        } else {
            die "[Moxie::PANIC] Got strange option ($type) to trait (is)";
        }
    };

    $TRAITS{'required'} = sub ($m, $a, $bool) {
        if ( $bool ) {
            my $class = $m->name;
            my $attr  = $a->name;
            my $init  = sub { die "[Moxie::ERROR] The attribute `$attr` is required" };

            Sub::Util::set_subname( ($class . '::__ANON__'), $init );

            $a->set_initializer( $init );
        }
    };
}


1;