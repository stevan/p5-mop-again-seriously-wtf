#include "p5mop.h"
#include "p5mop_MaV.h"

/* 
    TODO:

    1) We need to add the ability to check if a method is required or not.

*/

/* *****************************************************
 * Constructors
 * ***************************************************** */

SV* THX_newMopMmV(pTHX_ CV* code) {
    return newRV_noinc(newRV_inc((SV*) code));
}

/* *****************************************************
 * Accessors
 * ***************************************************** */

CV* THX_MopMmV_get_cv(pTHX_ SV* self) {
    return (CV*) SvRV(SvRV(self));
}

GV* THX_MopMmV_get_glob(pTHX_ SV* self) {
    return CvGV(MopMmV_get_cv(self));
}

char* THX_MopMmV_get_name(pTHX_ SV* self) { 
    return GvNAME(MopMmV_get_glob(self));
}

HV* THX_MopMmV_get_stash(pTHX_ SV* self) {
    return (HV*) GvSTASH(MopMmV_get_glob(self));
}

char* THX_MopMmV_get_stash_name(pTHX_ SV* self) {
    return HvNAME(MopMmV_get_stash(self));
}

bool THX_MopMmV_was_aliased_from(pTHX_ SV* self, AV* candidates) {
    int i, len;
    SV* name;

    len  = av_top_index(candidates);
    name = newSVpv(MopMmV_get_stash_name(self), 0);

    for (i = 0; i <= len; i++) {
        if (sv_eq(AvARRAY(candidates)[i], name)) {
            return TRUE;
        }
    }
    return FALSE;
}

/* *****************************************************
 * Methods
 * ***************************************************** */

/* *****************************************************
 * Internal Util functions ...
 * ***************************************************** */