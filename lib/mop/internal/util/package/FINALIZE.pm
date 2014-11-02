package mop::internal::util::package::FINALIZE;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

use Devel::Hook      ();
use Devel::BeginLift ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our %FINALIZERS;

sub import ($class, @) { 
    $class->import_into( scalar caller );
}

# NOTE:
# This whole package is there simply because we 
# need the FINALIZE blocks to run in FIFO order
# and the raw UNITCHECK blocks run in LIFO order
# which can present issues when more then one 
# class/role is in a single compiliation unit
# and the later class/role depends on a former
# class/role to have been finalized.
# - SL

sub import_into ($class, $pkg) {
    # set up the finalizers for this package ...
    $FINALIZERS{ $pkg } = [];
    # set up the UNITCHECK hook to run them ...
    Devel::Hook->push_UNITCHECK_hook(sub { 
        $_->() for @{ $FINALIZERS{ $pkg } } 
        # TODO:
        # Think about using this moment to actually
        # remove the FINALIZE function that we 
        # imported into the $pkg. Either that 
        # or we need to do lexical exports (as 
        # suggested below).
        # - SL
    });
    # now install the FINALIZE sub ...
    {
        no strict 'refs';
        # TODO:
        # make the exports lexical ...
        # which may not matter much, or even
        # not work at all, due to our usage 
        # of BeginLift, but worth checking 
        # - SL
        *{ $pkg . '::FINALIZE' } = sub :prototype(&) { push @{ $FINALIZERS{ $pkg } } => $_[0]; return };
    }
    # ... and lift it
    Devel::BeginLift->setup_for( $pkg => [ 'FINALIZE' ] );
}

sub add_finalizer_for ($class, $pkg, $callback) {
    push @{ $FINALIZERS{ $pkg } } => $callback;
    return;
}

1;

__END__