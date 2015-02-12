package mop::internal::util::syntax;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

# NOTE:
# we should likely enforce that the keyword 
# has an empty typeglob so that when we delete
# it in the teardown we are not removing
# anything. I did try to just delete the CODE
# slot in the keyword typeglob and it broke 
# stuff in weird ways. 
# - Sl

sub setup_keyword_handler ($pkg, $method, $handler) {
    my $cv = eval 'sub { 1 }'; # need to force a new CV each time here 
    {
        no strict 'refs';
        *{"${pkg}::${method}"} = $cv;
    }
    mop::internal::util::syntax::install_keyword_handler(
        $cv, sub {
            my $stmt = mop::internal::util::syntax::parse_full_statement;
            my $resp = $handler->( $stmt->() );
            $resp = sub {()} unless $resp && ref $resp eq 'CODE';
            return ($resp, 1);
        }
    );
}

sub teardown_keyword_handler ($pkg, $method) {
    no strict 'refs';
    delete ${"${pkg}::"}{ $method };
}

1;

__END__
