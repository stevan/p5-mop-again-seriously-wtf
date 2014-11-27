package Moxie;

use v5.20;
use warnings;
use feature 'signatures', 'postderef';
no warnings 'experimental::signatures', 'experimental::postderef';

sub import {
    my $pkg   = caller;
    my $class = shift;    
    my @args  = @_;

    my (@extends, @with);
    my ($in_extends, $in_with) = (0, 0);
    foreach my $arg ( @args ) {
        $in_extends++ && $in_with--    || next if $arg eq 'extends';
        ++$in_with    && --$in_extends || next if $arg eq 'with';
        push @extends => $arg if $in_extends;
        push @with    => $arg if $in_with;   
    }

    use Data::Dumper;
    warn Dumper [ \@extends, \@with ];

    #${^CLASS} = mop::class->new( name => $class );

    #undef ${^CLASS};
}

sub has ($name, @traits) {
    my $attr = ${^CLASS}->add_attribute( $name, undef );
    foreach my $trait ( @traits ) {
        $trait->( ${^CLASS}, $attr );
    }
    return;
}

1;