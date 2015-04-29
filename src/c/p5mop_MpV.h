#include "EXTERN.h"
#include "perl.h"

#ifndef MOP_MPV_H
#define MOP_MPV_H

// Mop M(eta)p(ackage)V(alue)

#define newMopMpV(name)                          THX_newMopMpV(aTHX_ name)

#define MopMpV_get_stash(self)                   THX_MopMpV_get_stash(aTHX_ self)
#define MopMpV_get_stash_name(self)              THX_MopMpV_get_stash_name(aTHX_ self)
#define MopMpV_has_glob_at(self, name, len)      THX_MopMpV_has_glob_at(aTHX_ self, name, len)
#define MopMpV_get_glob_at(self, name, len)      THX_MopMpV_get_glob_at(aTHX_ self, name, len)
#define MopMpV_create_glob_at(self, name, len)   THX_MopMpV_create_glob_at(aTHX_ self, name, len)
#define MopMpV_set_glob_SV_at(self, glob, value) THX_MopMpV_set_glob_SV_at(aTHX_ self, glob, value)
#define MopMpV_set_glob_AV_at(self, glob, value) THX_MopMpV_set_glob_AV_at(aTHX_ self, glob, value)
#define MopMpV_set_glob_HV_at(self, glob, value) THX_MopMpV_set_glob_HV_at(aTHX_ self, glob, value)

// ...

SV*   THX_newMopMpV(pTHX_ SV* name);

HV*   THX_MopMpV_get_stash(pTHX_ SV* self);
char* THX_MopMpV_get_stash_name(pTHX_ SV* self);
bool  THX_MopMpV_has_glob_at(pTHX_ SV* self, char* name, I32 len);
GV*   THX_MopMpV_get_glob_at(pTHX_ SV* self, char* name, I32 len);
GV*   THX_MopMpV_create_glob_at(pTHX_ SV* self, char* name, I32 len);
void  THX_MopMpV_set_glob_SV_at(pTHX_ SV* self, GV* glob, SV* value);
void  THX_MopMpV_set_glob_AV_at(pTHX_ SV* self, GV* glob, AV* value);
void  THX_MopMpV_set_glob_HV_at(pTHX_ SV* self, GV* glob, HV* value);

// Error handling

#define MopMpV_Error_if_closed(self, name) STMT_START {                       \
    if (SvOK(MopOV_get_at_slot(SvRV(self), "is_closed", 9))) {                \
        die("[mop::PANIC] Cannot call %s on (%s) because it has been closed", \
            name, MopMpV_get_stash_name(self));                               \
    }} STMT_END

#endif /* MOP_MPV_H */