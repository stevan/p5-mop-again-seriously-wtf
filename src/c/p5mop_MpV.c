#include "p5mop.h"
#include "p5mop_MpV.h"

/* *****************************************************
 * Constructors
 * ***************************************************** */

SV* THX_newMopMpV(pTHX_ SV* name) {  
    assert(name != NULL);

    if (SvTYPE(name) >= SVt_PVAV) {
        croak("name is not a regular scalar");
    } 

    return newRV_noinc(newRV_inc((SV*) gv_stashsv(name, GV_ADD)));
}

/* *****************************************************
 * Accessors
 * ***************************************************** */

HV* THX_MopMpV_get_stash (pTHX_ SV* self) {
    assert(self != NULL);

    if (SvTYPE(self) != SVt_RV 
            && SvTYPE(SvRV(self)) != SVt_RV
                && SvTYPE(SvRV(SvRV(self))) != SVt_PVHV) {
        croak("self is not a MopMpV structure");
    }

    return (HV*) SvRV(SvRV(self));    
}

char* THX_MopMpV_get_stash_name(pTHX_ SV* self) {
    assert(self != NULL);

    return HvNAME(MopMpV_get_stash(self));
}

bool THX_MopMpV_has_glob_at(pTHX_ SV* self, char* name, I32 len) {
    assert(self != NULL && name != NULL);

    SV** gvp = hv_fetch(MopMpV_get_stash(self), name, len, 0);
    return (gvp == NULL) ? TRUE : FALSE;
}

GV* THX_MopMpV_get_glob_at(pTHX_ SV* self, char* name, I32 len) {
    assert(self != NULL && name != NULL);

    SV** gvp = hv_fetch(MopMpV_get_stash(self), name, len, 0);
    return (gvp == NULL) ? NULL : (GV*) *gvp;
}

GV* THX_MopMpV_create_glob_at(pTHX_ SV* self, char* name, I32 len) {
    assert(self != NULL && name != NULL);

    HV* stash  = MopMpV_get_stash(self);
    GV* new_gv = (GV*) newSV(0);
    gv_init_pvn(new_gv, stash, name, len, GV_ADDMULTI);
    (void) hv_store(stash, name, len, (SV*) new_gv, 0);
    return new_gv;
}

void THX_MopMpV_set_glob_SV_at(pTHX_ SV* self, GV* glob, SV* value) {
    assert(self != NULL && glob != NULL && value != NULL);

    SV* sv = GvSV(glob);
    if (sv == NULL) gv_SVadd(glob);
    GvSV(glob) = value;
}

void THX_MopMpV_set_glob_AV_at(pTHX_ SV* self, GV* glob, AV* value) {
    assert(self != NULL && glob != NULL && value != NULL);

    AV* av = GvAV(glob);
    if (av == NULL) gv_AVadd(glob);
    GvAV(glob) = value;
}

void THX_MopMpV_set_glob_HV_at(pTHX_ SV* self, GV* glob, HV* value) {
    assert(self != NULL && glob != NULL && value != NULL);

    HV* hv = GvHV(glob);
    if (hv == NULL) gv_HVadd(glob);
    GvHV(glob) = value;
}

/* *****************************************************
 * Methods
 * ***************************************************** */

/* *****************************************************
 * Internal Util functions ...
 * ***************************************************** */