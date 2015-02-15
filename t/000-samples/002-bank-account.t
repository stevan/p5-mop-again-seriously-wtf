#!perl

use strict;
use warnings;

use Test::More;

package BankAccount {
    use Moxie;

    extends 'mop::object';

    has 'balance' => ( is => 'ro', default => sub { 0 } );

    sub deposit ($self, $amount) { $self->{balance} += $amount }

    sub withdraw ($self, $amount) {
        ($self->{balance} >= $amount)
            || die "Account overdrawn";
        $self->{balance} -= $amount;
    }
}

package CheckingAccount {
    use Moxie;

    extends 'BankAccount';

    has 'overdraft_account' => ( is => 'ro' );

    sub withdraw ($self, $amount) {

        my $overdraft_amount = $amount - $self->balance;

        if ( $self->{overdraft_account} && $overdraft_amount > 0 ) {
            $self->{overdraft_account}->withdraw( $overdraft_amount );
            $self->deposit( $overdraft_amount );
        }

        $self->next::method( $amount );
    }
}

my $savings = BankAccount->new( balance => 250 );
isa_ok($savings, 'BankAccount' );

is $savings->balance, 250, '... got the savings balance we expected';

$savings->withdraw( 50 );
is $savings->balance, 200, '... got the savings balance we expected';

$savings->deposit( 150 );
is $savings->balance, 350, '... got the savings balance we expected';

my $checking = CheckingAccount->new(
    overdraft_account => $savings,
);
isa_ok($checking, 'CheckingAccount');
isa_ok($checking, 'BankAccount');

is $checking->balance, 0, '... got the checking balance we expected';

$checking->deposit( 100 );
is $checking->balance, 100, '... got the checking balance we expected';
is $checking->overdraft_account, $savings, '... got the right overdraft account';

$checking->withdraw( 50 );
is $checking->balance, 50, '... got the checking balance we expected';
is $savings->balance, 350, '... got the savings balance we expected';

$checking->withdraw( 200 );
is $checking->balance, 0, '... got the checking balance we expected';
is $savings->balance, 200, '... got the savings balance we expected';

is_deeply(
    mro::get_linear_isa('BankAccount'),
    [ 'BankAccount', 'mop::object' ],
    '... got the expected linear isa'
);

is_deeply(
    mro::get_linear_isa('CheckingAccount'),
    [ 'CheckingAccount', 'BankAccount', 'mop::object' ],
    '... got the expected linear isa'
);

done_testing;


