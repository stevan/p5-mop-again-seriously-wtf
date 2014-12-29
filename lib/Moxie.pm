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

    my ($current, @isa, @does);
    foreach my $arg ( @args ) {
        if ( $arg eq 'isa' ) {
            $current = \@isa;
        }
        elsif ( $arg eq 'does' ) {
            $current = \@does;
        }
        else {
            push @$current => $arg;
        }
    }

    use_package_optimistically $_ foreach @isa, @does;

    mop::internal::util::INSTALL_FINALIZATION_RUNNER_FOR_ENDOFSCOPE( $pkg );

    my $metatype  = (scalar @isa ? 'class' : 'role'); 
    my $metaclass = 'mop::' . $metatype; 

    my $meta = $metaclass->new( name => $pkg );
    $meta->set_superclasses( @isa ) if $metatype eq 'class';
    if ( @does ) {
        $meta->set_roles( @does );
        $meta->add_finalizer(sub { mop::internal::util::APPLY_ROLES( $meta, \@does, to => $metatype ) });
    }
    
    $meta->add_finalizer(sub {
        mop::internal::util::GATHER_ALL_ATTRIBUTES( $meta )
    }) if $metatype eq 'class';    

    $meta->add_finalizer(sub { $meta->set_is_closed(1) });    

    strict->import;
    warnings->import;
    feature->import('signatures', 'postderef');
    warnings->unimport('experimental::signatures', 'experimental::postderef');
    {
        no strict 'refs';
        *{$pkg . '::has'}     = \&has;
        *{$pkg . '::blessed'} = \&Scalar::Util::blessed;
    }

    $meta->add_finalizer(sub {
        no strict 'refs';
        *{$pkg . '::has'} = Symbol::gensym();
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


    $meta->add_attribute( $name, delete $traits{default} );

    if ( keys %traits ) {
        my $attr = $meta->get_attribute( $name );
        foreach my $k ( keys %traits ) {
            die "[Moxie::PANIC] Cannot locate trait ($k) to apply to attributes ($name)"
                unless exists $TRAITS{ $k };
            $TRAITS{ $k }->( $meta, $attr, $traits{ $k } );
        }
    }

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