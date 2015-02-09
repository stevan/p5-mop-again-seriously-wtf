#include "EXTERN.h"
#include "perl.h"

#ifndef MOP_H
#define MOP_H

// Some useful utils ...

#define av_to_bool(av)   (av != NULL && av_top_index(av) > -1) ? &PL_sv_yes : &PL_sv_no

#define GvSV_or_undef(s) ((s != NULL) ? GvSV(s) : &PL_sv_undef)
#define GvSV_to_bool(s)  ((s != NULL) ? SvTRUE(GvSV(s)) ? &PL_sv_yes : &PL_sv_no : &PL_sv_no)

#define XPUSHav(_av) STMT_START { AV* av = (_av);  \
    if (av != NULL) {                              \
        int av_size = av_top_index(av);            \
        if (av_size > -1) {                        \
            int i; av_size++; EXTEND(SP, av_size); \
            for (i = 0; i < av_size; i++) {        \
                SV** sv = av_fetch(av, i, 0);      \
                if (sv != NULL) PUSHs((SV*) *sv);  \
            }                                      \
        }                                          \
    }} STMT_END

#define SLURP_ARGS(offset) newAV(); STMT_START { \
    int i; for (i = offset; i < items; i++) {   \
        (void)av_store(args, i-offset, ST(i));  \
    }} STMT_END

#endif /* MOP_H */