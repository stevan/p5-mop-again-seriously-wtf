#!perl

use strict;
use warnings;

use Test::More;

package Point {
    use v5.20;
    use warnings;
    use mop isa => 'mop::object';

    has 'x' => ( is => 'ro', default => sub { 0 } );
    has 'y' => ( is => 'ro', default => sub { 0 } );

    sub set_x ($self, $x) {
        $self->{x} = $x;
    }

    sub set_y ($self, $y) {
        $self->{y} = $y;
    }

    sub clear ($self) {
        @{ $self }{'x', 'y'} = (0, 0);
    }

    sub pack ($self) {
        +{ x => $self->x, y => $self->y }
    }
}

# ... subclass it ...

package Point3D {
    use v5.20;
    use warnings;
    use mop isa => 'Point';

    has 'z' => ( is => 'ro', default => sub { 0 } );

    sub set_z ($self, $z) {
        $self->{z} = $z;
    }

    sub pack ($self) {
        my $data = $self->next::method;
        $data->{z} = $self->{z};
        $data;
    }
}

## Test an instance
{
    my $p = Point->new;
    isa_ok($p, 'Point');

    is_deeply(
        mro::get_linear_isa('Point'),
        [ 'Point', 'mop::object' ],
        '... got the expected linear isa'
    );

    is $p->x, 0, '... got the default value for x';
    is $p->y, 0, '... got the default value for y';

    $p->set_x(10);
    is $p->x, 10, '... got the right value for x';

    $p->set_y(320);
    is $p->y, 320, '... got the right value for y';

    is_deeply $p->pack, { x => 10, y => 320 }, '... got the right value from pack';
}

## Test the instance
{
    my $p3d = Point3D->new();
    isa_ok($p3d, 'Point3D');
    isa_ok($p3d, 'Point');

    is_deeply(
        mro::get_linear_isa('Point3D'),
        [ 'Point3D', 'Point', 'mop::object' ],
        '... got the expected linear isa'
    );

    is $p3d->z, 0, '... got the default value for z';

    $p3d->set_x(10);
    is $p3d->x, 10, '... got the right value for x';

    $p3d->set_y(320);
    is $p3d->y, 320, '... got the right value for y';

    $p3d->set_z(30);
    is $p3d->z, 30, '... got the right value for z';

    is_deeply $p3d->pack, { x => 10, y => 320, z => 30 }, '... got the right value from pack';
}


done_testing;


