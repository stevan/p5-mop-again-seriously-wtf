package mop::internal::finalize;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use Package::Finalize ();

sub import {
    my $pkg = caller;
    Package::Finalize->import_into( $pkg, ( 'DEMOLISH', 'BUILD' ) );
    Package::Finalize->add_finalizer_for( $pkg, sub {
        # NOTE:
        # mop::role is composed into mop::class 
        # during the boostrap process, which 
        # means we don't have a fully formed 
        # mop::class yet that we can use to 
        # introspect the mop::class object itself
        if ( $pkg eq 'mop::class' ) {

            my (%methods, %required);
            foreach my $r ( map { mop::role->new( name => $_ ) } @mop::class::DOES ) {
                foreach my $m ( $r->methods ) {
                    my $m_name = B::svref_2object( $m )->GV->NAME;
                    if ( exists $methods{ $m_name } ) {
                        $required{ $m_name } = undef;
                    }
                    else {
                        $methods{ $m_name } = $m;
                        delete $required{ $m_name } if exists $required{ $m_name };
                    }
                }
            }
            
            die "Odd, there should be no required methods for mop::class role composition"
                if scalar keys %required;

            {
                no strict 'refs';
                foreach my $name ( keys %methods ) {
                    *{'mop::class::' . $name} = $methods{ $name };
                }
            }
        }
        else {
            
        }
    });
}

1;

__END__
