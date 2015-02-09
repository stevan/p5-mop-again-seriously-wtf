#include "EXTERN.h"
#include "perl.h"

#ifndef MOP_MAV_H
#define MOP_MAV_H

// Mop M(eta)a(ttribute)V(alue)

#define newMopMaV(name, init)        THX_newMopMaV(aTHX_ name, init)

#define MopMaV_get_name(self)        THX_MopMaV_get_name(aTHX_ self)
#define MopMaV_get_initializer(self) THX_MopMaV_get_initializer(aTHX_ self)
#define MopMaV_get_glob(self)        THX_MopMaV_get_glob(aTHX_ self)
#define MopMaV_get_stash(self)       THX_MopMaV_get_stash(aTHX_ self)
#define MopMaV_get_stash_name(self)  THX_MopMaV_get_stash_name(aTHX_ self)

// ...

SV*   THX_newMopMaV(pTHX_ SV* name, SV* init);

char* THX_MopMaV_get_name(pTHX_ SV* self);
CV*   THX_MopMaV_get_initializer(pTHX_ SV* self);
GV*   THX_MopMaV_get_glob(pTHX_ SV* self);
HV*   THX_MopMaV_get_stash(pTHX_ SV* self);
char* THX_MopMaV_get_stash_name(pTHX_ SV* self);

#endif /* MOP_MAV_H */