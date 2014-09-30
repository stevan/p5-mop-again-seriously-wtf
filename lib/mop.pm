package mop;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use mop::object;
use mop::class;

use Scalar::Util ();

sub meta ($instance) {
    mop::class->new( name => Scalar::Util::blessed( $instance ) || $instance );
}

1;

__END__