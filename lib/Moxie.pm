package Moxie;

use v5.20;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures', 'experimental::postderef';

my %METACACHE;

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

sub has ($name, @traits) {
    my $pkg = caller;
    my $meta  = $METACACHE{ $pkg };

    $meta->add_attribute( $name, sub { undef } );

    if ( @traits ) {
        my $attr = $meta->get_attribute( $name );
        $_->( $meta, $attr ) foreach @traits;
    }

    return;
}

1;