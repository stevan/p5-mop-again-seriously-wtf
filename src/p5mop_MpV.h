#include "EXTERN.h"
#include "perl.h"

#ifndef MOP_MPV_H
#define MOP_MPV_H

// Mop M(eta)p(ackage)V(alue)

#define newMopMpV(name)                     THX_newMopMpV(aTHX_ name)

#define MopMpV_get_stash(self)              THX_MopMpV_get_stash(aTHX_ self)
#define MopMpV_get_stash_name(self)         THX_MopMpV_get_stash_name(aTHX_ self)
#define MopMpV_get_glob_at(self, name, len) THX_MopMpV_get_glob_at(aTHX_ self, name, len)

// ...

SV*   THX_newMopMpV(pTHX_ SV* name);

HV*   THX_MopMpV_get_stash(pTHX_ SV* self);
char* THX_MopMpV_get_stash_name(pTHX_ SV* self);
GV*   THX_MopMpV_get_glob_at(pTHX_ SV* self, char* name, I32 len);

#endif /* MOP_MPV_H */