package mop;

use v5.20;
use mro;
use warnings;
use experimental 'signatures', 'postderef';

use Module::Runtime ();
use Symbol          ();

use Devel::CallParser;
use XSLoader; 
BEGIN { 
    our $VERSION   = '0.01';
    our $AUTHORITY = 'cpan:STEVAN';
    XSLoader::load( __PACKAGE__, $VERSION ); 
}

use mop::internal::util;

use mop::object;
use mop::attribute;
use mop::method;
use mop::role;
use mop::class;

our $IS_BOOTSTRAPPED = 0;

our %TRAITS;

# TODO:
# Everything that this &import method does should be 
# in util subroutines so that someone else can just
# come in and use it sensibly to implement their own 
# object system if they want. The idea is that the 
# simple, bare bones sugar I provide here is just barely
# one step above the raw version which uses the package
# variables and mop::internal::util::* methods directly
# inside BEGIN blocks, etc. 
#
# In short, there is no need to make people jump through 
# stupid meta-layer subclass stuff in order to maintain 
# a level or purity that perl just doesn't give a fuck
# about anyway. In the 'age of objects' we have forgotten 
# that subroutines are also an excellent form of encapsulation
# and re-use. 
# - SL

sub import ($class, @args) {
    # start the bootstrapping ...
    unless ( $IS_BOOTSTRAPPED ) {
        # NOTE:
        # Run the finalizers for the three packages that we 
        # could not run it for previously. The issue is that 
        # the finalize runner needs mop::role, and that cannot
        # run until mop::role is loaded. These three packages
        # are all needed by mop::role, so we have to tie the 
        # knot here to make all things well.
        foreach my $pkg (qw[ mop::object mop::attribute mop::method ]) {
            mop::role->new( name => $pkg )->run_all_finalizers;     
        }

        # bootstrapping is complete ...
        $IS_BOOTSTRAPPED = 1;
    }

    my $caller = caller;

    # make the assumption that if we are 
    # loaded outside of main then we are 
    # likely being loaded in a class, so
    # turn on all the features 
    if ( $caller ne 'main' ) {

        # FIXME:
        # There are a lot of assumptions here that 
        # we are not loading mop.pm in a package 
        # where it might have already been loaded
        # so we might want to keep that in mind 
        # and guard against some of that below, 
        # in particular I think the FINALIZE handlers
        # might need to be checked, and perhaps the
        # 'has' keyword importation as well.
        # - SL

        # NOTE:
        # create the meta-object, we start 
        # with this as a role, but it will 
        # get "cast" to a class if there 
        # is a need for it. 
        my $meta = mop::role->new( name => $caller );

        # install our finalizer feature ...
        mop::internal::util::INSTALL_FINALIZATION_RUNNER( $caller );   

        # turn on signatures ...
        feature->import('signatures');
        warnings->unimport('experimental::signatures');

        # import has keyword
        {
            no strict 'refs';
            *{ $caller . '::has'     } = sub { 1 };
            *{ $caller . '::extends' } = sub { 1 };
            *{ $caller . '::with'    } = sub { 1 };

            mop::internal::util::syntax::install_keyword_handler(
                \&{ $caller . '::has' }, 
                sub {
                    use strict 'refs';

                    my $has = mop::internal::util::syntax::parse_full_statement;

                    my ($name, %traits) = $has->();

                    # this is the only one we handle 
                    # specially, everything else gets
                    # called as a trait ...
                    $traits{default} //= delete $traits{required} 
                                          ? sub { die "[mop::ERROR] The attribute '$name' is required" }
                                          : eval 'sub { undef }'; # we need this to be a unique CV ... sigh

                    $meta->add_attribute( $name, delete $traits{default} );

                    if ( keys %traits ) {
                        my $attr = $meta->get_attribute( $name );
                        foreach my $k ( keys %traits ) {
                            die "[mop::PANIC] Cannot locate trait ($k) to apply to attributes ($name)"
                                unless exists $TRAITS{ $k };
                            $TRAITS{ $k }->( $meta, $attr, $traits{ $k } );
                        }
                    }

                    # replace this with a noop since 
                    # we did all our work at compile 
                    # time already.
                    return (sub { () }, 1);
                }
            ); 

            mop::internal::util::syntax::install_keyword_handler(
                \&{ $caller . '::extends' }, 
                sub {
                    use strict 'refs';

                    my $extends = mop::internal::util::syntax::parse_full_statement;

                    my @isa = $extends->();

                    Module::Runtime::use_package_optimistically( $_ ) foreach @isa;

                    ($meta->isa('mop::class') 
                        ? $meta
                        : (bless $meta => 'mop::class') # cast into class
                    )->set_superclasses( @isa );

                    # replace this with a noop since 
                    # we did all our work at compile 
                    # time already.
                    return (sub { () }, 1);
                }
            );

            mop::internal::util::syntax::install_keyword_handler(
                \&{ $caller . '::with' }, 
                sub {
                    use strict 'refs';

                    my $with = mop::internal::util::syntax::parse_full_statement;

                    my @does = $with->();

                    Module::Runtime::use_package_optimistically( $_ ) foreach @does;

                    $meta->set_roles( @does );

                    # replace this with a noop since 
                    # we did all our work at compile 
                    # time already.
                    return (sub { () }, 1);
                }
            );
        }

        $meta->add_finalizer(sub { 


            if ( $meta->isa('mop::class') ) {
                # FIXME - move this code to an internal::util::METHOD - SL
                # make sure to 'inherit' the required methods ...
                foreach my $super ( map { mop::role->new( name => $_ ) } $meta->superclasses ) {
                    foreach my $required_method ( $super->required_methods ) {
                        $meta->add_required_method($required_method)
                    }
                }

                # this is an optimization to pre-populate the 
                # cache for all the attributes 
                mop::internal::util::GATHER_ALL_ATTRIBUTES( $meta );
            }

            # apply roles ...
            if ( my @does = $meta->roles ) {
                mop::internal::util::APPLY_ROLES( 
                    $meta, 
                    \@does, 
                    to => ($meta->isa('mop::class') ? 'class' : 'role')
                );
            }

            $meta->set_is_closed(1);
        });
    }

}

# TODO:
# Move this to a mop::traits module, like in p5-mop-redux
BEGIN {
    $TRAITS{'is'} = sub ($m, $a, $type) {
        my $slot = $a->name;
        if ( $type eq 'ro' ) {
            $m->add_method( $slot => sub { 
                die "Cannot assign to `$slot`, it is a readonly attribute" if scalar @_ != 1;
                $_[0]->{ $slot };
            });
        } elsif ( $type eq 'rw' ) {
            $m->add_method( $slot => sub { 
                $_[0]->{ $slot } = $_[1] if $_[1];
                $_[0]->{ $slot };
            });            
        } else {
            die "[mop::PANIC] Got strange option ($type) to trait (is)";
        }
    };
}

1;

__END__

=pod

=head1 GENERAL IMPLEMENTATION NOTES

This section is here just so I can make some general 
notes about the implementation that will eventually 
be part of the proposal and rationale.

=head2 Attributes in mop::* classes

I am attempting to avoid the creation of any attributes
in the C<mop::*> classes, this has always been a pain point
in the bootstraps of the other versions. Instead each of the 
underlying objects that are blessed in the C<mop::*> 
constructors provide all their state information via 
methods. For example, C<mop::role> (and consequently
the C<mop::class>) both are blessed refs to the package
stash, which holds all it's state data as package level 
variables. Additionally C<mop::method> is a blessed CODE
ref and C<mop::attribute> is a blessed ARRAY ref (this is 
actually meant to model a perlguts data structure called HE
which is basically an entry in a HASH). 

This may seem "incorrect" if you really wanted to be strict
about things, but the reality is that in many languages the
data structures behind classes and other such meta-level 
objects are not user-level exposed things. The decision to 
go in this direction is a tradeoff, we are favoring "simple" 
over "correct".

=head2 Attributes and Methods objects are built on the fly

In previous prototypes we have spent a lot of time and effort
to make sure that all method and attributes are inflated into 
full meta-objects at all times. This agian was a case of wanting
to be fully "correct" at all times, which upon further inspection 
is really quite wasteful. Creating a full C<mop::method> instance 
just to add a method to a class is overkill when a simple 
name/code-ref pair will suffice. 

Instead, we only return C<mop::method> and C<mop::attribute>
instances when you call methods on the C<mop::class> or C<mop::role>
objects. The idea here is that you only need the full object
when you are actually doing work with the meta-objects, for the 
cases where this is not needed, we don't do it. This is not so 
much a performance decision, it is more about not forcing people
to use the C<mop::*> classes if they really have no need to.

=head2 Attributes stored in %HAS 

The long term goal of this arrangement is to treat attributes
as much like methods as possible. If you think about a package 
STASH, it is pretty much just a special HASH. The way method 
caching works is that upon successful dispatch an inherited 
method will be "cached" in the local package STASH. It is possible 
to differentiate these cached methods by the fact their CODE 
refs have a different STASH name. The idea is to do the same thing
with the entries stored in C<%HAS> since the values must be CODE
references, the STASH of the package they were created in set
accordingly. This means we can "cache" inherited attributes in 
C<%HAS> and just filter accordingly. We will also (eventually)
adopt the same cache invalidation approach as methods have.

=head2 Are Packages Roles or Classes?

The previous prototypes have made a big deal about making a Role
object into something special and different from a class. This 
is another case of being overly "correct" and as with the other 
cases above, we have tossed it aside. 

The fact is that a package in Perl is simply that, a package, 
any distinction we make is potentially invalidated by someone 
simply using a role as a class or a class as a role. By not 
enforcing this we actually allow this behavior that we spent 
quite a lot of time trying to prevent in the past prototypes. 

It is my belief that by lifing this strictness we are putting 
the power and decision in the hands of the user and as a result
being more Perlish.

=head2 Why all the package variables?

I decided to design this prototype bottom-up where the "bottom"
is basically core Perl OO. In the past we put a lot of effort 
into creating a new OO system that existed along side the old
OO system. In the end all the "new systems" ended up becoming
some variation of the "old system". 

This prototype tries instead to extend the existing system 
(optionally of course) such that blessing a "non-MOP" class
with C<mop::class> will still give you sensible information
about that class. Ideally this will make back-compat issues
much easier to handle, though this is still to be tested.

=head2 Required Methods

Required methods are implemented using the existing Perl 
feature of an undefined subroutine. This is basically a C<sub>
without a body. For example:

  sub foo; 

  foo(); # Undefined subroutine &main::foo called at ...

They are actually stored in the symbol table as a -1 instead
of actually creating the GLOB. However, if there already is 
a GLOB, or the GLOB is autovivified for some reason (calling
C<can> with the method name, etc.) then perl will "upgrade"
it into a special kind of CV. For example, this code:

  use Devel::Peek;

  package Test {
    sub foo;
  }

  Dump(Test->can('foo'));

Gives you the following output:

  SV = IV(0x7fcbdb027be0) at 0x7fcbdb027bf0
    REFCNT = 1
    FLAGS = (TEMP,ROK)
    RV = 0x7fcbdb003468
    SV = PVCV(0x7fcbdb026ee8) at 0x7fcbdb003468
      REFCNT = 2
      FLAGS = (POK,pPOK)
      PROTOTYPE = "-1"
      COMP_STASH = 0x7fcbdb003120 "main"
      ROOT = 0x0
      GVGV::GV = 0x7fcbdb17d2d8   "Test" :: "foo"
      FILE = "test.pl"
      DEPTH = 0
      FLAGS = 0x0
      OUTSIDE_SEQ = 0
      PADLIST = 0x0
      OUTSIDE = 0x0 (null)

  # Note the PROTOTYPE and FLAGS, these didn't always 
  # show up, they only appeared if we had tried to print 
  # the value in 'foo', which at the time is -1, and 
  # then auto-vivify. I suspect this has something to do
  # with dualvars, but I don't know that for sure.

Right now the code (since it is in perl-space) is perhaps
not doing required method creation and detection as safely 
as it could be, but that can be fixed in the XS version. For
now, this works and we have these notes reminding us to 
improve it.

=head2 Pragma syntax

One of the key differences between this and Moose is 
that it will perform inheritance and role composition at 
compile time instead of runtime. This is required because 
we run the FINALIZER stuff during the UNITCHECK time, so we 
need to know about the class earlier.

To make C<has> happen at compile time we use the keyword
API to add in a C<has> keyword. 

  package Eq;

  use v5.20;
  use warnings;
  use mop;

  sub equal_to;

  sub not_equal_to ($self, $other) {
      not $self->equal_to($other);
  }

  package Comparable;

  use v5.20;
  use warnings;
  use mop does => 'Eq';

  sub compare;

  sub equal_to ($self, $other) {
      $self->compare($other) == 0;
  }

  sub greater_than ($self, $other)  {
      $self->compare($other) == 1;
  }

  sub less_than ($self, $other) {
      $self->compare($other) == -1;
  }

  sub greater_than_or_equal_to ($self, $other)  {
      $self->greater_than($other) || $self->equal_to($other);
  }

  sub less_than_or_equal_to ($self, $other)  {
      $self->less_than($other) || $self->equal_to($other);
  }

  package Printable;
  
  use v5.20;
  use warnings;
  use mop;

  sub to_string;

  package US::Currency;

  use v5.20;
  use warnings;
  use mop
      isa  => 'mop::object',
      does => 'Comparable', 'Printable';

  has 'amount' => (
      is      => 'rw', 
      default => sub { 0 } 
  );

  sub compare ($self, $other) {
      $self->amount <=> $other->amount;
  }

  sub to_string ($self) {
      sprintf '$%0.2f USD' => $self->amount;
  }


Couple of notes:

=over 4

=item There is no C<mop::role> package to specify roles.

If you look above, I talk about how a package is both a 
role and a class and it only matters in how you treat them, 
this is what is going on here.

The only thing that kind of sucks about this is that 
we have to explictly inherit from C<mop::object> since
we cannot make an assumption about your intent.

=back

=head2 new mop style syntax

This is the exact same syntax as in the previous prototype
(p5-mop-redux), so just refer to that project for more 
details.

  role Eq {
      method equal_to;
  
      method not_equal_to ($other) {
          not $self->equal_to($other);
      }
  }
  
  role Comparable with Eq {
      method compare;
      method equal_to ($other) {
          $self->compare($other) == 0;
      }
  
      method greater_than ($other)  {
          $self->compare($other) == 1;
      }
  
      method less_than  ($other) {
          $self->compare($other) == -1;
      }
  
      method greater_than_or_equal_to ($other)  {
          $self->greater_than($other) || $self->equal_to($other);
      }
  
      method less_than_or_equal_to ($other)  {
          $self->less_than($other) || $self->equal_to($other);
      }
  }
  
  role Printable {
      method to_string;
  }
  
  class US::Currency with Comparable, Printable {
      has $!amount is ro = 0;
  
      method compare ($other) {
          $!amount <=> $other->amount;
      }
  
      method to_string {
          sprintf '$%0.2f USD' => $!amount;
      }
  }

=cut





