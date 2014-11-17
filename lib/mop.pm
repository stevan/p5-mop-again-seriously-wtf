package mop;

use v5.20;
use warnings;

use mop::internal::util;

use mop::object;
use mop::attribute;
use mop::method;
use mop::role;
use mop::class;

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

=cut





