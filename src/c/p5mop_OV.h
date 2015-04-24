#include "EXTERN.h"
#include "perl.h"

#ifndef MOP_OV_H
#define MOP_OV_H

// Mop O(paque)V(alue)

typedef struct {
    I32* id;
    HV*  slots;
} MopOV;

// constructor

#define newMopOV(rv) THX_newMopOV(aTHX_ rv)

SV* THX_newMopOV(pTHX_ SV* rv);

// destructor

#define freeMopOV(opaque) THX_freeMopOV(aTHX_ opaque)

void THX_freeMopOV(pTHX_ MopOV* opaque);

// Slot access ...

#define MopOV_get_slots(rv) THX_MopOV_get_slots(aTHX_ rv)
#define MopOV_get_at_slot(rv, slot_name) THX_MopOV_get_at_slot(aTHX_ rv, slot_name)
#define MopOV_set_at_slot(rv, slot_name, slot_value) THX_MopOV_set_at_slot(aTHX_ rv, slot_name, slot_value)
#define MopOV_has_at_slot(rv, slot_name) THX_MopOV_has_at_slot(aTHX_ rv, slot_name)
#define MopOV_clear_at_slot(rv, slot_name) THX_MopOV_clear_at_slot(aTHX_ rv, slot_name)

HV*  THX_MopOV_get_slots(pTHX_ SV* rv);
SV*  THX_MopOV_get_at_slot(pTHX_ SV* rv, SV* slot_name);
void THX_MopOV_set_at_slot(pTHX_ SV* rv, SV* slot_name, SV* slot_value);
bool THX_MopOV_has_at_slot(pTHX_ SV* rv, SV* slot_name);
void THX_MopOV_clear_at_slot(pTHX_ SV* rv, SV* slot_name);

/* *****************************************************
 * General Utilities
 * ***************************************************** */

MopOV* SVrv_to_MopOV(SV* rv);
bool   isSVrv_a_MopOV(SV* rv);

#endif /* MOP_OV_H */