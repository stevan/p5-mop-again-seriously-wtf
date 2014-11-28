package Moxie;

use v5.20;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures', 'experimental::postderef';

use Symbol;

my (%METACACHE, %TRAITS);

sub import {
    shift;
    my $pkg  = caller;
    my @args = @_;

    my (@extends, @with);
    my ($in_extends, $in_with) = (0, 0);
    foreach my $arg ( @args ) {
        $in_extends++ && $in_with--    || next if $arg eq 'extends';
        ++$in_with    && --$in_extends || next if $arg eq 'with';
        push @extends => $arg if $in_extends;
        push @with    => $arg if $in_with;   
    }

    mop::internal::util::INSTALL_FINALIZATION_RUNNER_FOR_ENDOFSCOPE( $pkg );

    my $metatype  = (scalar @extends ? 'class' : 'role'); 
    my $metaclass = 'mop::' . $metatype; 

    my $meta = $metaclass->new( name => $pkg );
    $meta->set_superclasses( @extends ) if $metatype eq 'class';
    if ( @with ) {
        $meta->set_roles( @with );
        $meta->add_finalizer(sub { mop::internal::util::APPLY_ROLES( $meta, \@with, to => $metatype ) });
    }
    
    $meta->add_finalizer(sub {
        mop::internal::util::GATHER_ALL_ATTRIBUTES( $meta )
    }) if $metatype eq 'class';    

    $meta->add_finalizer(sub { $meta->set_is_closed(1) });    

    feature->import('signatures', 'postderef');
    warnings->unimport('experimental::signatures', 'experimental::postderef');
    {
        no strict 'refs';
        *{$pkg . '::has'} = \&has;
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
    $traits{default} //= sub { undef };

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
}


1;