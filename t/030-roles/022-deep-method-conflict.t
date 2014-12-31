#!perl

use strict;
use warnings;

use Test::More;

package Service {
    use v5.20;
    use warnings;
    use mop;

    sub is_locked { 0 }
}

package WithClass {
    use v5.20;
    use warnings;
    use mop does => 'Service';
}       

package WithParameters {
    use v5.20;
    use warnings;
    use mop does => 'Service';
} 

package WithDependencies {
    use v5.20;
    use warnings;
    use mop does => 'Service';
}

foreach my $role (map { mop::role->new( name => $_ ) } qw[ 
    WithClass
    WithParameters
    WithDependencies
]) {
    ok($role->has_method('is_locked'), '... the is_locked method is treated as a proper method because it was composed from a role');
    ok($role->has_method_alias('is_locked'), '... the is_locked method is also an alias, because that is how we install things in roles');
    is_deeply(
        [ map { $_->name } $role->methods ],
        [ 'is_locked' ],
        '... these roles should then show the is_locked method'
    );
};

{
    local $@;
    eval q[
        package ConstructorInjection { 
            use v5.20;
            use warnings;
            use mop 
                isa  => 'mop::object',
                does => 'WithClass', 'WithParameters', 'WithDependencies';
        }
    ];
    is($@, "", '... this worked');
}

done_testing;
