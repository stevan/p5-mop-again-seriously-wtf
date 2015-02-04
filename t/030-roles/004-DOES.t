#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# roles ...
package Foo {
    use v5.20;
    use warnings;
    use mop;
}
package Bar {
    use v5.20;
    use warnings;
    use mop;
}
package Baz {
    use v5.20;
    use warnings;
    use mop;
}
package Bat {
    use v5.20;
    use warnings;
    use mop;

    with 'Baz';
}

# classes ...
package Quux { 
    use v5.20;
    use warnings;
    use mop;

    extends 'mop::object';
       with 'Foo', 'Bar'; 
}

package Quuux { 
    use v5.20;
    use warnings;
    use mop;

    extends 'Quux';
       with 'Foo', 'Baz';
}

package Xyzzy { 
    use v5.20;
    use warnings;
    use mop;
    
    extends 'mop::object';
       with 'Foo', 'Bat';
}

ok(Quux->DOES($_),  "... Quux DOES $_")  for qw( Foo Bar         Quux       mop::object UNIVERSAL );
ok(Quuux->DOES($_), "... Quuux DOES $_") for qw( Foo Bar Baz     Quux Quuux mop::object UNIVERSAL );
ok(Xyzzy->DOES($_), "... Xyzzy DOES $_") for qw( Foo     Baz Bat      Xyzzy mop::object UNIVERSAL );

#{ local $TODO = "broken in core perl" if $] < 5.019005;
#push @UNIVERSAL::ISA, 'Blorg';
#ok(Quux->DOES('Blorg'));
#ok(Quuux->DOES('Blorg'));
#ok(Xyzzy->DOES('Blorg'));
#}

done_testing;
