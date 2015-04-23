
============================================================

package ORDERING { 
    sub compare; 
}

package Sortable { 
    
    our %PARAMETERS = (
        Ordering => { does => 'ORDERING' } 
    );

    sub sort ($self, @elements) {
        sort { $self->compare($a, $b) } @elements
    }
}

package StringOrder {

    our @DOES = ('ORDERING');

    sub compare {
        my (undef, $x, $y) = @_;
        $x cmp $y;
    }
}

package NumericOrder {

    our @DOES = ('ORDERING');

    sub compare {
        my (undef, $x, $y) = @_;
        $x <=> $y;
    }
}

package AlphabeticalOrder {

    our @DOES = ('ORDERING');

    sub compare {
        my (undef, $x, $y) = @_;
        lc($x) cmp lc($y);
    }
}

package BunchOfStrings {

    with 'Sortable' => [ 'StringOrder' ];

    # ...
}

package BunchOfNumbers { 

    with 'Sortable' => [ 'NumericOrder' ];
    # ...
}

============================================================

role ORDERING { requires 'compare' }

role Sortable [Ordering => (does => 'ORDERING') ] {
    sub sort {
        my ($self, @elements)
        sort { $self->compare($a, $b) } @elements
    }
}

role StringOrder with ORDERING {
    sub compare {
        my (undef, $x, $y) = @_;
        $x cmp $y;
    }
}

role NumericOrder with ORDERING {
    sub compare {
        my (undef, $x, $y) = @_;
        $x <=> $y;
    }
}

role AlphabeticalOrder with ORDERING {
    sub compare {
        my (undef, $x, $y) = @_;
        lc($x) cmp lc($y);
    }
}

class BunchOfStrings with Sortable(StringOrder) {
    # ...
}

class BunchOfNumbers with Sortable(NumericOrder) {
    # ...
}

============================================================

package COLLAPSER { sub pack; sub unpack; }
package FORMATTER { sub thaw; sub freeze; }
package IO        { sub load; sub store;  }

package DefaultCollapser { 
    
    with 'COLLAPSER';

    sub pack {
        Collapser::Engine->new( object => $self )
                         ->collapse_object
    }

    sub unpack ($class, $data) {
        Collapser::Engine->new( class => $class )
                         ->expand_object( $data )
    }
}

package JSONFormatter { 

    with 'FORMATTER';

    parameters( Collapser => (does => 'COLLAPSER') );

    sub thaw ($class, $json) {
        $class->unpack( JSON::Any->encode( $json ) )
    }

    sub freeze {
        JSON::Any->decode( $self->pack )
    }
}

package SimpleFile {

    with 'IO';

    parameters( Formatter => (does => 'FORMATTER') );

    sub load ($class, $filename){
        my $fh   = IO::File->new( $filename, 'r' );
        my $data = do { local $/; <$fh>; };
        $class->thaw( $data );
    }

    sub store ($self, $filename) {
        my $fh = IO::File->new( $filename, 'w' );
        $fh->print( $self->freeze );
    }
}


package Point {
    
    with SimpleFile => [ 
        Formatter => [ 
            JSONFormatter => [
                Collapser => 'DefaultCollapser'
            ]
        ]
    ];
          
    has x => (is => 'rw', isa => Int, default => 0);
    has y => (is => 'rw', default => 0);

    sub clear ($self) {
        $self->x(0);
        $self->y(0);
    }
}

package Point {
    
    with JSONFormatter => [ 
        Collapser => 'DefaultCollapser' 
    ];

    has x => (is => 'rw', default => 0);
    has y => (is => 'rw', default => 0);

    self clear ($self) {
        $self->x(0);
        $self->y(0);
    }
}

package Point {

    with 'DefaultCollapser';

    has x => (is => 'rw', default => 0);
    has y => (is => 'rw', default => 0);

    sub clear ($self) {
        $self->x(0);
        $self->y(0);
    }
}



---------------------------------------------------------------------------------

role COLLAPSER { requires 'pack', 'unpack' }
role FORMATTER { requires 'thaw', 'freeze' }
role IO        { requires 'load', 'store'  }

role DefaultCollapser with COLLAPSER {

    method pack {
        Collapser::Engine->new( object => $self )
                         ->collapse_object
    }

    method unpack ($class:, $data) {
        Collapser::Engine->new( class => $class )
                         ->expand_object( $data )
    }
}

role JSONFormatter [ 
        Collapser => (does => COLLAPSER) 
    ] with FORMATTER {

    method thaw ($class:, $json) {
        $class->unpack( JSON::Any->encode( $json ) )
    }

    method freeze {
        JSON::Any->decode( $self->pack )
    }
}

role SimpleFile [ 
        Formatter => (does => FORMATTER) 
    ] with IO {

    method load ($class:, $filename){
        my $fh   = IO::File->new( $filename, 'r' );
        my $data = do { local $/; <$fh>; };
        $class->thaw( $data );
    }

    method store ($filename) {
        my $fh = IO::File->new( $filename, 'w' );
        $fh->print( $self->freeze );
    }
}

------------------------------------------------------


class Point 
 with SimpleFile( 
          Formatter => JSONFormatter( 
              Collapser => DefaultCollapser 
          ) 
    ) {
    has x => (is => rw, isa => Int, default => 0);
    has y => (is => rw, isa => Int, default => 0);

    method clear {
        $self->x(0);
        $self->y(0);
    }
}

class Point
 with JSONFormatter( 
          Collapser => DefaultCollapser 
    ) {
    has x => (is => rw, isa => Int, default => 0);
    has y => (is => rw, isa => Int, default => 0);

    method clear {
        $self->x(0);
        $self->y(0);
    }
}

class Point with DefaultCollapser {
    has x => (is => rw, isa => Int, default => 0);
    has y => (is => rw, isa => Int, default => 0);

    method clear {
        $self->x(0);
        $self->y(0);
    }
}

