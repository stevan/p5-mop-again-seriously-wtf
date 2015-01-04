#!/usr/bin/perl -w

use v5.20;
use warnings;

use Test::More;
use Test::Fatal;
use Data::Dumper;

BEGIN {
    use_ok('mop');
}

sub init_foo { 'FOO' }

my $Attribute = mop::attribute->new( name => 'foo', initializer => \&init_foo );
isa_ok($Attribute, 'mop::attribute');

my @METHODS = qw[
    new 
    name
    initializer
    stash_name
    was_aliased_from
];

can_ok($Attribute, $_) for @METHODS;

is($Attribute->initializer, \&init_foo, '... got the expected initializer');
is($Attribute->initializer->(), 'FOO', '... got the expected result from calling initializer');

is($Attribute->name, 'foo', '... got the expected result from ->name');
is($Attribute->stash_name, 'main', '... got the expected result from ->stash_name');

ok($Attribute->was_aliased_from('main'), '... the method was aliased from main::');
ok(!$Attribute->was_aliased_from('Foo'), '... the method was not aliased from Foo::');

done_testing;


