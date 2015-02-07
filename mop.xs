#include "EXTERN.h"
#include "perl.h"
#include "callparser1.h"
#include "XSUB.h"

/* ======================================================= */
// BEGIN: Shameless Steal from Parse::Keyword 
/* ======================================================= */

#ifndef cv_clone
#define cv_clone(a) Perl_cv_clone(aTHX_ a)
#endif

static SV *parser_fn(OP *(fn)(pTHX_ U32), bool named)
{
    I32 floor;
    CV *code;
    U8 errors;
 
    ENTER;
 
    PL_curcop = &PL_compiling;
    SAVEVPTR(PL_op);
    SAVEI8(PL_parser->error_count);
    PL_parser->error_count = 0;
 
    floor = start_subparse(0, named ? 0 : CVf_ANON);
    code = newATTRSUB(floor, NULL, NULL, NULL, fn(aTHX_ 0));
 
    errors = PL_parser->error_count;
 
    LEAVE;
 
    if (errors) {
        ++PL_parser->error_count;
        return newSV(0);
    }
    else {
        if (CvCLONE(code)) {
            code = cv_clone(code);
        }
 
        return newRV_inc((SV*)code);
    }
}

// shamelessly stolen from Parse::Keyword
static OP *parser_callback(pTHX_ GV *namegv, SV *psobj, U32 *flagsp)
{
    dSP;
    SV *args_generator;
    SV *statement = NULL;
    I32 count;
 
    /* call the parser callback
     * it should take no arguments and return a coderef which, when called,
     * produces the arguments to the keyword function
     * the optree we want to generate is for something like
     *   mykeyword($code->())
     * where $code is the thing returned by the parser function
     */
 
    PUSHMARK(SP);
    mXPUSHp(GvNAME(namegv), GvNAMELEN(namegv));
    PUTBACK;
    count = call_sv(psobj, G_ARRAY);
    SPAGAIN;
    if (count > 1) {
        statement = POPs;
    }
    args_generator = SvREFCNT_inc(POPs);
    PUTBACK;
 
    if (!SvROK(args_generator) || SvTYPE(SvRV(args_generator)) != SVt_PVCV) {
        croak("The parser function for %s must return a coderef, not %"SVf,
              GvNAME(namegv), args_generator);
    }
 
    if (SvTRUE(statement)) {
        *flagsp |= CALLPARSER_STATEMENT;
    }
 
    return newUNOP(OP_ENTERSUB, OPf_STACKED,
                   newCVREF(0, newSVOP(OP_CONST, 0, args_generator)));
}

/* ======================================================= */
// END: Shameless Steal from Parse::Keyword 
/* ======================================================= */

/* ======================================================= */
// BEGIN: mop Code
/* ======================================================= */

// constructors

#define newMopMpV(name) newRV_noinc(newRV_inc((SV*) gv_stashsv(name, GV_ADD)))
#define newMopMmV(code) newRV_noinc(newRV_inc((SV*) code))
#define newMopMaV(attr) newRV_noinc((SV*) attr)

// Mop M(eta)p(ackage)V(alue)

#define MopMpV_get_stash(self)              ((HV*) SvRV(SvRV(self)))
#define MopMpV_get_stash_name(self)         HvNAME(MopMpV_get_stash(self))
#define MopMpV_get_glob_at(self, name, len) hv_fetch(MopMpV_get_stash(self), name, len, 0)

// Mop M(eta)m(ethod)V(alue)

#define MopMmV_get_cv(self)         ((CV*) SvRV(SvRV(self)))
#define MopMmV_get_glob(self)       CvGV(MopMmV_get_cv(self))
#define MopMmV_get_name(self)       GvNAME(MopMmV_get_glob(self))
#define MopMmV_get_stash(self)      ((HV*) GvSTASH(MopMmV_get_glob(self)))
#define MopMmV_get_stash_name(self) HvNAME(MopMmV_get_stash(self))

// Mop M(eta)a(ttribute)V(alue)

#define MopMaV_get_name(self)        ((SV*) *(av_fetch((AV*) SvRV(self), 0, 0)))
#define MopMaV_get_initializer(self) ((SV*) *(av_fetch((AV*) SvRV(self), 1, 0)))
#define MopMaV_get_glob(self)        CvGV((CV*) SvRV(MopMaV_get_initializer(self)))
#define MopMaV_get_stash(self)       ((HV*) GvSTASH(MopMaV_get_glob(self)))
#define MopMaV_get_stash_name(self)  HvNAME(MopMaV_get_stash(self))

// Utils 

#define av_to_bool(av)   (av != NULL && av_top_index(av) > -1) ? &PL_sv_yes : &PL_sv_no

#define GvSV_or_undef(s) ((s != NULL && *s != NULL) ? GvSV((GV*) *s) : &PL_sv_undef)
#define GvSV_to_bool(s)  ((s != NULL && *s != NULL) ? SvTRUE(GvSV((GV*) *s)) ? &PL_sv_yes : &PL_sv_no : &PL_sv_no)

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

/* ======================================================= */
// END: mop Code
/* ======================================================= */

MODULE = mop  PACKAGE = mop::role

# access to the package itself

SV* 
stash(self)
        SV *self
    PPCODE: 
        EXTEND(SP, 1);
        PUSHs(SvRV(self));

# meta-info 

SV* 
name(self)
        SV *self;
    CODE: 
        RETVAL = newSVpv(MopMpV_get_stash_name(self), 0);
    OUTPUT:
        RETVAL

SV*
version(self)
        SV *self;
    PREINIT:
        SV** version;
    CODE:
        version = MopMpV_get_glob_at(self, "VERSION", 7);
        RETVAL = GvSV_or_undef(version);
    OUTPUT: 
        RETVAL

SV*
authority(self)
        SV *self;
    PREINIT:
        SV** authority;
    CODE:
        authority = MopMpV_get_glob_at(self, "AUTHORITY", 9);
        RETVAL = GvSV_or_undef(authority);
    OUTPUT: 
        RETVAL

# package variables

SV*
is_closed(self)
        SV *self;
    PREINIT:
        SV** is_closed;
    CODE:
        is_closed = MopMpV_get_glob_at(self, "IS_CLOSED", 9);
        RETVAL = GvSV_to_bool(is_closed);
    OUTPUT: 
        RETVAL

# finalization 

void
finalizers(self)
        SV *self;
    PREINIT: 
        SV** finalizers;
    PPCODE:
        finalizers = MopMpV_get_glob_at(self, "FINALIZERS", 10);
        if (finalizers != NULL) {
            XPUSHav(GvAV((GV*) *finalizers));
        }

SV*
has_finalizers(self)
        SV *self;
    PREINIT:
        SV** finalizers;
    CODE:
        finalizers = MopMpV_get_glob_at(self, "FINALIZERS", 10);
        if (finalizers != NULL && *finalizers != NULL) {
            AV* f = GvAV((GV*) *finalizers);
            RETVAL = av_to_bool(f);
        }
        else {
            RETVAL = &PL_sv_no;
        }
    OUTPUT: 
        RETVAL

# roles 

void
roles(self)
        SV *self;
    PREINIT: 
        SV** roles;
    PPCODE:
        roles = MopMpV_get_glob_at(self, "DOES", 4);
        if (roles != NULL) {
            XPUSHav(GvAV((GV*) *roles));
        }

MODULE = mop  PACKAGE = mop::method

SV* 
body(self)
        SV *self;
    PPCODE: 
        EXTEND(SP, 1);
        PUSHs(SvRV(self));

SV* 
name(self)
        SV *self;
    CODE: 
        RETVAL = newSVpv(MopMmV_get_name(self), 0);
    OUTPUT:
        RETVAL

SV* 
stash_name(self)
        SV *self;
    CODE: 
        RETVAL = newSVpv(MopMmV_get_stash_name(self), 0);
    OUTPUT:
        RETVAL

SV*
was_aliased_from(self, ...)
        SV* self;
    PREINIT:
        int i;
        SV* name   = newSVpv(MopMmV_get_stash_name(self), 0);
        SV* result = &PL_sv_no;     
    CODE:
        for (i = 1; i < items; i++) {
            if (sv_eq(ST(i), name)) {
                result = &PL_sv_yes;
                break;
            } 
        }
        RETVAL = result;
    OUTPUT:
        RETVAL

MODULE = mop  PACKAGE = mop::attribute

SV* 
name(self)
        SV *self;
    CODE: 
        RETVAL = newSVsv(MopMaV_get_name(self));
    OUTPUT:
        RETVAL

SV* 
initializer(self)
        SV *self;
    PPCODE: 
        EXTEND(SP, 1);
        PUSHs(MopMaV_get_initializer(self));        

SV* 
stash_name(self)
        SV *self;
    CODE: 
        RETVAL = newSVpv(MopMaV_get_stash_name(self), 0);
    OUTPUT:
        RETVAL

SV*
was_aliased_from(self, ...)
        SV* self;
    PREINIT:
        int i;
        SV* name   = newSVpv(MopMaV_get_stash_name(self), 0);
        SV* result = &PL_sv_no;     
    CODE:
        for (i = 1; i < items; i++) {
            if (sv_eq(ST(i), name)) {
                result = &PL_sv_yes;
                break;
            } 
        }
        RETVAL = result;
    OUTPUT:
        RETVAL

MODULE = mop  PACKAGE = mop::internal

SV* 
newMopMpV(name)
        SV* name;

SV*
newMopMmV(code)
        SV* code;
    CODE:
        RETVAL = newMopMmV((CV*) SvRV(code));
    OUTPUT:
        RETVAL

SV*
newMopMaV(name, init)
        SV* name; 
        SV* init;
    PREINIT:
        AV* attr;
    CODE:
        attr = newAV();
        av_store(attr, 0, SvREFCNT_inc(name));
        av_store(attr, 1, SvREFCNT_inc(init));
        RETVAL = newMopMaV(attr);
    OUTPUT:
        RETVAL

MODULE = mop  PACKAGE = mop::internal::util::guts
 
AV* 
get_UNITCHECK_AV()
    CODE:
        if ( !PL_unitcheckav ) PL_unitcheckav = newAV();
        RETVAL = PL_unitcheckav;
    OUTPUT:
        RETVAL

MODULE = mop  PACKAGE = mop::internal::util::guts::syntax

# NOTE:
# Everything in this package has been stolen from 
# Parse::Keyword, it could almost certainly use some 
# improvement, but is good for now.
# - SL

PROTOTYPES: DISABLE

void
install_keyword_handler(keyword, handler)
        SV *keyword
        SV *handler
    CODE:
        cv_set_call_parser( (CV*) SvRV( keyword ), parser_callback, handler );

SV*
parse_full_statement(named = FALSE)
        bool named
    CODE:
        RETVAL = parser_fn( Perl_parse_fullstmt, named );
    OUTPUT:
        RETVAL



