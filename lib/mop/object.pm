package mop::object;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use mop::internal::util;

use Variable::Magic ();

sub new ($class, %args) {
    my %self;
    $class->BLESS( 
        $class->CREATE( 
            \%self, %args 
        ) 
    )->BUILDALL( 
        \%args 
    );
}

sub CREATE ($class, $repr, %args) {

    Variable::Magic::cast( 
        %$repr, 
        mop::internal::util::get_wiz(), 
        {
            id    => mop::internal::util::next_oid(),
            slots => { %args }
        }
    );    

    return $repr;
}

sub BLESS ($class, $repr) {
    return bless $repr => $class;
}

sub BUILDALL ($self, $args) {
    # ...

    return $self;
}

1;

__END__