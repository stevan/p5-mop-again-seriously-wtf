package Moxie;

use v5.20;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures', 'experimental::postderef';

my %METACACHE;

my %TRAITS;

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

    mop::internal::util::INSTALL_FINALIZATION_RUNNER_FOR( $pkg );

    my $metatype  = (scalar @extends ? 'class' : 'role'); 
    my $metaclass = 'mop::' . $metatype; 

    my $meta = $metaclass->new( name => $pkg );
    $meta->set_superclasses( @extends ) if @extends;
    if ( @with ) {
        $meta->set_roles( @with );
        $meta->add_finalizer(sub { mop::internal::util::APPLY_ROLES( $meta, \@with, to => $metatype ) });
    }
    $meta->add_finalizer(sub { $meta->set_is_closed(1) });    

    feature->import('signatures', 'postderef');
    warnings->unimport('experimental::signatures', 'experimental::postderef');
    {
        no strict 'refs';
        *{$pkg . '::has'} = \&has;
    }

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

1;