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

sub import_into ($class, $pkg) {
    # set up the finalizers for this package ...
    $FINALIZERS{ $pkg } = [];
    # set up the UNITCHECK hook to run them ...
    Devel::Hook->push_UNITCHECK_hook(sub { $_->() for @{ $FINALIZERS{ $pkg } } });
    # now install the FINALIZE sub ...
    {
        no strict 'refs';
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