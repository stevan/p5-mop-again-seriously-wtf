#include "p5mop_OV.h"

/* *****************************************************
 * predeclare some internal functions
 * ***************************************************** */

static I32* new_uuid();

// magic destructor ...
static int mg_freeMopOV(pTHX_ SV *sv, MAGIC *mg);
static MGVTBL MopOV_vtbl = {
    NULL,         /* get   */
    NULL,         /* set   */
    NULL,         /* len   */
    NULL,         /* clear */
    mg_freeMopOV, /* free  */
    NULL,         /* copy  */
    NULL,         /* dup   */
    NULL          /* local */
};

/* *****************************************************
 * Constructors
 * ***************************************************** */

SV* THX_newMopOV(pTHX_ SV* rv) {
    assert(rv != NULL);

    if (SvTYPE(rv) != SVt_RV) {
        croak("rv is not a reference");
    }

    if (isSVrv_a_MopOV(rv)) {
        return rv;
    }

    MopOV* opaque;

    Newx(opaque, 1, MopOV);
    opaque->id        = new_uuid();
    opaque->slots     = newHV();

    sv_magicext(SvRV(rv), NULL, PERL_MAGIC_ext, &MopOV_vtbl, (char*) opaque, 0);

    return rv;
}

/* *****************************************************
 * Destructor
 * ***************************************************** */

void THX_freeMopOV(pTHX_ MopOV* opaque) {
    assert(opaque != NULL);

    hv_undef(opaque->slots);

    Safefree(opaque->id);
    opaque->id        = NULL;
    opaque->slots     = NULL;

    Safefree(opaque);
    opaque = NULL;
}

/* *****************************************************
 * Slot access
 * ***************************************************** */

HV* THX_MopOV_get_slots(pTHX_ SV* rv) {
    MopOV* opaque  = SVrv_to_MopOV(rv);
    return opaque->slots;
}

SV* THX_MopOV_get_at_slot(pTHX_ SV* rv, SV* slot_name) {
    MopOV* opaque  = SVrv_to_MopOV(rv);
    HE* slot_entry = hv_fetch_ent(opaque->slots, slot_name, 0, 0);
    return slot_entry == NULL ? NULL : HeVAL(slot_entry);
}

void THX_MopOV_set_at_slot(pTHX_ SV* rv, SV* slot_name, SV* slot_value) {
    MopOV* opaque = SVrv_to_MopOV(rv);
    SvREFCNT_inc(slot_value);
    (void)hv_store_ent(opaque->slots, slot_name, slot_value, 0);
}

bool THX_MopOV_has_at_slot(pTHX_ SV* rv, SV* slot_name) {
    MopOV* opaque = SVrv_to_MopOV(rv);
    return hv_exists_ent(opaque->slots, slot_name, 0);
}

void THX_MopOV_clear_at_slot(pTHX_ SV* rv, SV* slot_name) {
    MopOV* opaque = SVrv_to_MopOV(rv);
    (void)hv_delete_ent(opaque->slots, slot_name, G_DISCARD, 0);    
}

/* *****************************************************
 * Util functions ...
 * ***************************************************** */

bool isSVrv_a_MopOV(SV* rv) {
    assert(rv != NULL);

    if (SvTYPE(rv) != SVt_RV && SvTYPE(SvRV(rv)) != SVt_PVMG) {
        croak("rv is not a magic reference");
    }

    if (SvMAGICAL(SvRV(rv))) {
        MAGIC* mg;
        for (mg = SvMAGIC(SvRV(rv)); mg; mg = mg->mg_moremagic) {
            if ((mg->mg_type == PERL_MAGIC_ext) && (mg->mg_virtual == &MopOV_vtbl)) {
                return mg->mg_ptr != NULL ? TRUE : FALSE;
            }
        }
    }

    return false;
}

MopOV* SVrv_to_MopOV(SV* rv) {
    assert(rv != NULL);

    if (SvTYPE(rv) != SVt_RV && SvTYPE(SvRV(rv)) != SVt_PVMG) {
        croak("rv is not a magic reference");
    }

    if (SvMAGICAL(SvRV(rv))) {
        MAGIC* mg;
        for (mg = SvMAGIC(SvRV(rv)); mg; mg = mg->mg_moremagic) {
            if ((mg->mg_type == PERL_MAGIC_ext) && (mg->mg_virtual == &MopOV_vtbl)) {
                return (MopOV*) mg->mg_ptr;
            }
        }
    }

    croak("rv is not a mop instance");
}

/* *****************************************************
 * Internal Util functions ...
 * ***************************************************** */

// magic destructor ...
static int mg_freeMopOV(pTHX_ SV *sv, MAGIC *mg) {

    // XXX:
    // guard against global destruction
    // in here (not exactly sure how, but
    // Vincent suggested it).
    // - SL

    if (SvREFCNT(sv) == 0) {
        freeMopOV((MopOV*) mg->mg_ptr);
        mg->mg_ptr = NULL;
    }
    return 0;
}

// Quick simple (and wrong) UUID mechanism, this will get
// replaced, but sufficient for now,
static I32* new_uuid() {
    I32* uuid;
    int i;

    Newx(uuid, 4, I32);

    if (!PL_srand_called) {
        (void)seedDrand01((Rand_seed_t)Perl_seed(aTHX));
        PL_srand_called = TRUE;
    }

    for (i = 0; i < 4; ++i) {
        uuid[i] = (I32)(Drand01() * (double)(2<<30));
    }

    return uuid;
}


