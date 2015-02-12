#include "EXTERN.h"
#include "perl.h"

#ifndef MOP_MMV_H
#define MOP_MMV_H

// Mop M(eta)m(ethod)V(alue)

#define newMopMmV(code)                           THX_newMopMmV(aTHX_ code)

#define MopMmV_get_cv(self)                       THX_MopMmV_get_cv(aTHX_ self)
#define MopMmV_get_glob(self)                     THX_MopMmV_get_glob(aTHX_ self)
#define MopMmV_get_name(self)                     THX_MopMmV_get_name(aTHX_ self)
#define MopMmV_get_stash(self)                    THX_MopMmV_get_stash(aTHX_ self)
#define MopMmV_get_stash_name(self)               THX_MopMmV_get_stash_name(aTHX_ self)
#define MopMmV_was_aliased_from(self, candidates) THX_MopMmV_was_aliased_from(aTHX_ self, candidates)

// ...

SV*   THX_newMopMmV(pTHX_ CV* code);

CV*   THX_MopMmV_get_cv(pTHX_ SV* self);
GV*   THX_MopMmV_get_glob(pTHX_ SV* self);
char* THX_MopMmV_get_name(pTHX_ SV* self);
HV*   THX_MopMmV_get_stash(pTHX_ SV* self);
char* THX_MopMmV_get_stash_name(pTHX_ SV* self);
bool  THX_MopMmV_was_aliased_from(pTHX_ SV* self, AV* candidates);

#endif /* MOP_MMV_H */