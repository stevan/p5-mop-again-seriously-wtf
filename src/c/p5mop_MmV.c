#include "p5mop.h"
#include "p5mop_MaV.h"

/* 
    TODO:

    1) We need to add the ability to check if a method is required or not.
    2) The double ref instance thing is wasteful, we can improve this for sure.

*/

/* *****************************************************
 * Constructors
 * ***************************************************** */

SV* THX_newMopMmV(pTHX_ CV* code) {
    assert(code != NULL);

    return newRV_noinc(newMopOV(newRV_inc((SV*) code)));
}

/* *****************************************************
 * Accessors
 * ***************************************************** */

CV* THX_MopMmV_get_cv(pTHX_ SV* self) {
    assert(self != NULL);

    if (SvTYPE(self) != SVt_RV 
            && SvTYPE(SvRV(self)) != SVt_RV
                && SvTYPE(SvRV(SvRV(self))) != SVt_PVCV) {
        croak("self is not a MopMmV structure");
    }

    return (CV*) SvRV(SvRV(self));
}

GV* THX_MopMmV_get_glob(pTHX_ SV* self) {
    assert(self != NULL);

    return CvGV(MopMmV_get_cv(self));
}

char* THX_MopMmV_get_name(pTHX_ SV* self) { 
    assert(self != NULL);

    return GvNAME(MopMmV_get_glob(self));
}

HV* THX_MopMmV_get_stash(pTHX_ SV* self) {
    assert(self != NULL);

    return (HV*) GvSTASH(MopMmV_get_glob(self));
}

char* THX_MopMmV_get_stash_name(pTHX_ SV* self) {
    assert(self != NULL);

    return HvNAME(MopMmV_get_stash(self));
}

/* *****************************************************
 * Methods
 * ***************************************************** */

bool THX_MopMmV_was_aliased_from(pTHX_ SV* self, AV* candidates) {
    assert(self != NULL && candidates != NULL);

    int i, len;
    SV* name;

    name = newSVpv(MopMmV_get_stash_name(self), 0);
    len  = av_top_index(candidates);

    for (i = 0; i <= len; i++) {
        if (sv_eq(AvARRAY(candidates)[i], name)) {
            return TRUE;
        }
    }
    return FALSE;
}

/* *****************************************************
 * Internal Util functions ...
 * ***************************************************** */