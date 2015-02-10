#include "EXTERN.h"
#include "perl.h"
#include "callparser1.h"
#include "XSUB.h"

#include "p5mop.h"
#include "p5mop.c"

#include "p5mop_MpV.h"
#include "p5mop_MpV.c"

#include "p5mop_MaV.h"
#include "p5mop_MaV.c"

#include "p5mop_MmV.h"
#include "p5mop_MmV.c"

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

MODULE = mop  PACKAGE = mop::role

# access to the package itself

SV* 
stash(self)
        SV* self;
    PPCODE: 
        EXTEND(SP, 1);
        PUSHs(SvRV(self));

# meta-info 

SV* 
name(self)
        SV* self;
    CODE: 
        RETVAL = newSVpv(MopMpV_get_stash_name(self), 0);
    OUTPUT:
        RETVAL

SV*
version(self)
        SV* self;
    PREINIT:
        GV* version;
    CODE:
        version = MopMpV_get_glob_at(self, "VERSION", 7);
        RETVAL = GvSV_or_undef(version);
    OUTPUT: 
        RETVAL

SV*
authority(self)
        SV* self;
    PREINIT:
        GV* authority;
    CODE:
        authority = MopMpV_get_glob_at(self, "AUTHORITY", 9);
        RETVAL = GvSV_or_undef(authority);
    OUTPUT: 
        RETVAL

# package variables

SV*
is_closed(self)
        SV* self;
    PREINIT:
        GV* is_closed;
    CODE:
        is_closed = MopMpV_get_glob_at(self, "IS_CLOSED", 9);
        RETVAL = GvSV_to_bool(is_closed);
    OUTPUT: 
        RETVAL

void 
set_is_closed(self, value)
        SV* self;
        SV* value;
    PREINIT:
        GV* is_closed;
    PPCODE:
        MopMpV_Error_if_closed(self, "set_is_closed");

        is_closed = MopMpV_get_glob_at(self, "IS_CLOSED", 9);
        if (is_closed == NULL) {
            is_closed = MopMpV_create_glob_at(self, "IS_CLOSED", 9);
        }
        MopMpV_set_glob_SV_at(self, is_closed, value);

void 
set_is_abstract(self, value)
        SV* self;
        SV* value;
    PREINIT:
        GV* is_abstract;
    PPCODE:
        MopMpV_Error_if_closed(self, "set_is_abstract");

        is_abstract = MopMpV_get_glob_at(self, "IS_ABSTRACT", 11);
        if (is_abstract == NULL) {
            is_abstract = MopMpV_create_glob_at(self, "IS_ABSTRACT", 11);
        }
        MopMpV_set_glob_SV_at(self, is_abstract, value);

# finalization 

void
finalizers(self)
        SV* self;
    PREINIT: 
        GV* finalizers;
    PPCODE:
        finalizers = MopMpV_get_glob_at(self, "FINALIZERS", 10);
        if (finalizers != NULL) {
            XPUSHav(GvAV(finalizers));
        }

SV*
has_finalizers(self)
        SV* self;
    PREINIT:
        GV* finalizers;
    CODE:
        finalizers = MopMpV_get_glob_at(self, "FINALIZERS", 10);
        if (finalizers != NULL) {
            AV* f = GvAV(finalizers);
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
        SV* self;
    PREINIT: 
        GV* roles;
    PPCODE:
        roles = MopMpV_get_glob_at(self, "DOES", 4);
        if (roles != NULL) {
            XPUSHav(GvAV(roles));
        }

void 
set_roles(self, ...)
        SV* self;
    CODE:
        if (items > 1) {
            GV* does;
            AV* args;

            MopMpV_Error_if_closed(self, "set_roles");

            args = newAV(); 
            SLURP_ARGS(args, 1);
            does = MopMpV_get_glob_at(self, "DOES", 4);

            if (does == NULL) {
                does = MopMpV_create_glob_at(self, "DOES", 4);
            }

            MopMpV_set_glob_AV_at(self, does, args);
        }

MODULE = mop  PACKAGE = mop::class

void
superclasses(self)
        SV* self;
    PREINIT: 
        GV* superclasses;
    PPCODE:
        superclasses = MopMpV_get_glob_at(self, "ISA", 3);
        if (superclasses != NULL) {
            XPUSHav(GvAV(superclasses));
        }

void 
set_superclasses(self, ...)
        SV* self;
    CODE:
        if (items > 1) {
            GV* isa;
            AV* args;

            MopMpV_Error_if_closed(self, "set_superclasses");

            args = newAV(); 
            SLURP_ARGS(args, 1);
            isa  = MopMpV_get_glob_at(self, "ISA", 3);

            if (isa == NULL) {
                isa = MopMpV_create_glob_at(self, "ISA", 3);
            }

            MopMpV_set_glob_AV_at(self, isa, args);
        }

void 
mro(self)
        SV* self;
    PPCODE:
        XPUSHav(mro_get_linear_isa(MopMpV_get_stash(self)));

MODULE = mop  PACKAGE = mop::method

SV* 
body(self)
        SV* self;
    PPCODE: 
        EXTEND(SP, 1);
        PUSHs(SvRV(self));

SV* 
name(self)
        SV* self;
    CODE: 
        RETVAL = newSVpv(MopMmV_get_name(self), 0);
    OUTPUT:
        RETVAL

SV* 
stash_name(self)
        SV* self;
    CODE: 
        RETVAL = newSVpv(MopMmV_get_stash_name(self), 0);
    OUTPUT:
        RETVAL

SV*
was_aliased_from(self, ...)
        SV* self;
    CODE:
        if (items == 1) {
            RETVAL = &PL_sv_no;
        } else {
            AV* args = newAV(); 
            SLURP_ARGS(args, 1);
            RETVAL = MopMmV_was_aliased_from(self, args) ? &PL_sv_yes : &PL_sv_no;
        }
    OUTPUT:
        RETVAL

MODULE = mop  PACKAGE = mop::attribute

SV* 
name(self)
        SV* self;
    CODE: 
        RETVAL = newSVpv(MopMaV_get_name(self), 0);
    OUTPUT:
        RETVAL

SV* 
initializer(self)
        SV* self;
    PPCODE: 
        EXTEND(SP, 1);
        PUSHs(newRV_inc((SV*) MopMaV_get_initializer(self)));        

SV* 
stash_name(self)
        SV* self;
    CODE: 
        RETVAL = newSVpv(MopMaV_get_stash_name(self), 0);
    OUTPUT:
        RETVAL

SV*
was_aliased_from(self, ...)
        SV* self;
    CODE:
        if (items == 1) {
            RETVAL = &PL_sv_no;
        } else {
            AV* args = newAV(); 
            SLURP_ARGS(args, 1);
            RETVAL = MopMaV_was_aliased_from(self, args) ? &PL_sv_yes : &PL_sv_no;
        }
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



