package mop::internal::finalize;

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';

use Package::Finalize ();

sub import { (shift)->import_into(caller) }

sub import_into {
    my (undef, $pkg) = @_;
    Package::Finalize->import_into( $pkg, ( 'DEMOLISH', 'BUILD' ) );
    Package::Finalize->add_finalizer_for( $pkg, sub {
        if ( $pkg eq 'mop::class' ) {
            # NOTE:
            # mop::role is composed into mop::class 
            # during the boostrap process, which 
            # means we don't have a fully formed 
            # mop::class yet that we can use to 
            # introspect the mop::class object itself
            my (%methods, %required);
            foreach my $r ( map { mop::role->new( name => $_ ) } @mop::class::DOES ) {
                foreach my $m ( $r->methods ) {
                    if ( exists $methods{ $m->name } ) {
                        $required{ $m->name } = undef;
                    }
                    else {
                        $methods{ $m->name } = $m;
                        delete $required{ $m->name } if exists $required{ $m->name };
                    }
                }
            }
            
            die "[PANIC] Odd, there should be no required methods for mop::class role composition"
                if scalar keys %required;

            {
                no strict 'refs';
                foreach my $name ( keys %methods ) {
                    *{'mop::class::' . $name} = $methods{ $name };
                }
            }
        }
        else {
            my $meta = mop::class->new( name => $pkg );
            if ( my @roles = $meta->roles ) {
                
                my (%methods, %required);
                foreach my $r ( map { mop::role->new( name => $_ ) } @roles ) {
                    foreach my $m ( $r->methods ) {
                        if ( exists $methods{ $m->name } ) {
                            $required{ $m->name } = undef;
                        }
                        else {
                            $methods{ $m->name } = $m;
                            delete $required{ $m->name } if exists $required{ $m->name };
                        }
                    }
                }

                die "[PANIC] Odd, there should be no required methods for role composition in $pkg"
                    if scalar keys %required;

                foreach my $name ( keys %methods ) {
                    $meta->alias_method( $name => $methods{ $name } );
                }
            }
        }
    });
}

1;

__END__
