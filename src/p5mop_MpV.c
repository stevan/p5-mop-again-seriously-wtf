#include "p5mop.h"
#include "p5mop_MpV.h"

/* *****************************************************
 * Constructors
 * ***************************************************** */

SV* THX_newMopMpV(pTHX_ SV* name) {  
    return newRV_noinc(newRV_inc((SV*) gv_stashsv(name, GV_ADD)));
}

/* *****************************************************
 * Accessors
 * ***************************************************** */

HV* THX_MopMpV_get_stash (pTHX_ SV* self) {
    return (HV*) SvRV(SvRV(self));    
}

char* THX_MopMpV_get_stash_name(pTHX_ SV* self) {
    return HvNAME(MopMpV_get_stash(self));
}

GV* THX_MopMpV_get_glob_at(pTHX_ SV* self, char* name, I32 len) {
    SV** gvp = hv_fetch(MopMpV_get_stash(self), name, len, 0);
    return (gvp == NULL) ? NULL : (GV*) *gvp;
}

/* *****************************************************
 * Methods
 * ***************************************************** */

/* *****************************************************
 * Internal Util functions ...
 * ***************************************************** */