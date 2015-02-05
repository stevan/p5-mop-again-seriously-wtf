package mop::role;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub new ($class, %args) {
    ${^GLOBAL_PHASE} eq 'START' || do { 
            my $depth = 0;
            {
               my @caller = caller( $depth++ ); 
               @caller && ($caller[3] eq '(eval)' || redo);
            }
        }
        ? mop::role::mutable->new( %args )
        : mop::role::immutable->new( %args )
}

1;

__END__