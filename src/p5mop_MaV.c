#include "p5mop.h"
#include "p5mop_MaV.h"


/* 
    TODO:
    
    1) We should use a better data structure then an AV here, it is overkill
       and we should use a C side data structure instead, but for now we are 
       avoiding that complexity in favor of getting shit done.
*/

/* *****************************************************
 * Constructors
 * ***************************************************** */

SV* newMopMaV(pTHX_ SV* name, SV* init) {
    AV* attr = newAV();
    av_store(attr, 0, SvREFCNT_inc(name));
    av_store(attr, 1, SvREFCNT_inc(init));
    return newRV_noinc((SV*) attr);
}

/* *****************************************************
 * Accessors
 * ***************************************************** */

char* MopMaV_get_name(pTHX_ SV* self) {       
    SV** name_p = av_fetch((AV*) SvRV(self), 0, 0);
    if (name_p == NULL || *name_p == NULL) return NULL;
    return SvPV_nolen((SV*) *name_p);
}

CV* MopMaV_get_initializer(pTHX_ SV* self) {
    SV** init_p = av_fetch((AV*) SvRV(self), 1, 0);
    if (init_p == NULL || *init_p == NULL) return NULL;
    return (CV*) SvRV((SV*) *init_p);
}

GV* MopMaV_get_glob(pTHX_ SV* self) {
    return CvGV((CV*) MopMaV_get_initializer(self));
}

HV* MopMaV_get_stash(pTHX_ SV* self) {
    return (HV*) GvSTASH(MopMaV_get_glob(self));
}

char* MopMaV_get_stash_name(pTHX_ SV* self) {
    return HvNAME(MopMaV_get_stash(self));
}

/* *****************************************************
 * Methods
 * ***************************************************** */

bool THX_MopMaV_was_aliased_from(pTHX_ SV* self, AV* candidates) {
    int i, len;
    SV* name;

    len  = av_top_index(candidates);
    name = newSVpv(MopMaV_get_stash_name(self), 0);

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