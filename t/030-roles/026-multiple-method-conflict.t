#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;



package R1 { 
    use v5.20;
    use warnings;
    use mop;
    sub foo { 1 } 
}

package R2 { 
    use v5.20;
    use warnings;
    use mop;
    sub foo { 1 } 
}

package R3 { 
    use v5.20;
    use warnings;
    use mop;
    sub foo { 1 } 
}

package R4 { 
    use v5.20;
    use warnings;
    use mop;
    sub foo { 1 } 
}

package R5 { 
    use v5.20;
    use warnings;
    use mop;
    sub foo { 1 } 
}

{
    local $@ = undef;
    eval q[
        package C1 {
            use v5.20;
            use warnings;
            use mop 
                isa  => 'mop::object', 
                does => 'R1';
        }
    ];
    ok(!$@, '... no exception, C1 does R1');
}

{
    local $@ = undef;
    eval q[
        package C2 {
            use v5.20;
            use warnings;
            use mop 
                isa  => 'mop::object', 
                does => 'R1', 'R2';
        }
    ];
    like(
        "$@",
        qr/^\[mop\:\:PANIC\] There should be no conflicting methods when composing \(R1, R2\) into the class \(C2\) but instead we found \(foo\)/, 
        '... got an exception, C2 does R1, R2'
    );
}

{
    local $@ = undef;
    eval q[
        package C3 {
            use v5.20;
            use warnings;
            use mop 
                isa  => 'mop::object', 
                does => 'R1', 'R2', 'R3';
        }
    ];
    like(
        "$@",
        qr/^\[mop\:\:PANIC\] There should be no conflicting methods when composing \(R1, R2, R3\) into the class \(C3\) but instead we found \(foo\)/, 
        '... got an exception, C3 does R1, R2, R3'
    );
}

{
    local $@ = undef;
    eval q[
        package C4 {
            use v5.20;
            use warnings;
            use mop 
                isa  => 'mop::object', 
                does => 'R1', 'R2', 'R3', 'R4';
        }
    ];
    like(
        "$@",
        qr/^\[mop\:\:PANIC\] There should be no conflicting methods when composing \(R1, R2, R3, R4\) into the class \(C4\) but instead we found \(foo\)/, 
        '... got an exception, C4 does R1, R2, R3, R4'
    );
}

{
    local $@ = undef;
    eval q[
        package C5 {
            use v5.20;
            use warnings;
            use mop 
                isa  => 'mop::object', 
                does => 'R1', 'R2', 'R3', 'R4', 'R5';
        }
    ];
    like(
        "$@",
        qr/^\[mop\:\:PANIC\] There should be no conflicting methods when composing \(R1, R2, R3, R4, R5\) into the class \(C5\) but instead we found \(foo\)/, 
        '... got an exception, C5 does R1, R2, R3, R4, R5'
    );
}

package R1_required { 
    use v5.20;
    use warnings;
    use mop;
    sub foo; 
}

{
    local $@ = undef;
    eval q[
        package C1_required {
            use v5.20;
            use warnings;
            use mop 
                isa  => 'mop::object', 
                does => 'R1_required', 'R2';
        }
    ];
    ok(!$@, '... no exception, C1 does R1');
}

done_testing;
