#include "EXTERN.h"
#include "perl.h"
#define NO_XSLOCKS
#include "XSUB.h"

MODULE = mop  PACKAGE = mop::internal::util::guts
 
AV* 
get_UNITCHECK_AV()
    CODE:
        if ( !PL_unitcheckav ) PL_unitcheckav = newAV();
        RETVAL = PL_unitcheckav;
    OUTPUT:
        RETVAL

