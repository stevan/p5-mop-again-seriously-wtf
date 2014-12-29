
# NOTE:
# One of the key goals here is to be as 
# absolutely minimalist as possible, which 
# means not having any more dependencies 
# then I actually need. Below is the list
# of dependencies and comments about how 
# easily replaced they are, any additions
# to this list should do the same.
# - SL

requires 'Symbol'       => 0;    # used in mop::role (core module)
requires 'Scalar::Util' => 0;    # used in mop::role (core module)
requires 'Sub::Util'    => 1.40; # used in mop::role (core module (as of 5.22))
