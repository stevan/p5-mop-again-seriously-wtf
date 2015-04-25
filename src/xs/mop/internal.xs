MODULE = mop  PACKAGE = mop::internal

SV* 
newMopMpV(name)
        SV* name;

SV*
newMopMmV(code)
        SV* code;
    CODE:
        if (SvTYPE(code) != SVt_RV && SvTYPE(SvRV(code)) != SVt_PVCV) {
            croak("'code' argument is not a CODE reference");
        }
        RETVAL = newMopMmV((CV*) SvRV(code));
    OUTPUT:
        RETVAL

SV*
newMopMaV(name, init)
        SV* name; 
        SV* init;

SV*
newMopOV(rv)
        SV* rv;
    PPCODE:
        (void)newMopOV(rv);
        XSRETURN(1);

MODULE = mop  PACKAGE = mop::internal::opaque

SV*  
get_slots(rv)
        SV* rv;
    PPCODE:
        EXTEND(SP, 1);
        PUSHs(newRV_inc((SV*) MopOV_get_slots(rv)));


SV*  
get_at_slot(rv, name_sv)
        SV* rv;
        SV* name_sv;
    PREINIT:
        STRLEN name_len;
        char*  name;
    PPCODE:
        name = SvPV(name_sv, name_len);    
        EXTEND(SP, 1);
        PUSHs(SvREFCNT_inc(MopOV_get_at_slot(rv, name, name_len)));

void 
set_at_slot(rv, name_sv, value)
        SV* rv;
        SV* name_sv;
        SV* value;
    PREINIT:
        STRLEN name_len;
        char*  name;
    CODE:
        name = SvPV(name_sv, name_len);   
        MopOV_set_at_slot(rv, name, name_len, value);

bool 
has_at_slot(rv, name_sv)
        SV* rv;
        SV* name_sv;
    PREINIT:
        STRLEN name_len;
        char*  name;
    CODE:
        name = SvPV(name_sv, name_len);           
        RETVAL = MopOV_has_at_slot(rv, name, name_len);
    OUTPUT:
        RETVAL

void
clear_at_slot(rv, name_sv);
        SV* rv;
        SV* name_sv;
    PREINIT:
        STRLEN name_len;
        char*  name;
    CODE:
        name = SvPV(name_sv, name_len);           
        MopOV_clear_at_slot(rv, name, name_len);

MODULE = mop  PACKAGE = mop::internal::util
 
AV* 
get_UNITCHECK_AV()
    CODE:
        if ( !PL_unitcheckav ) PL_unitcheckav = newAV();
        RETVAL = PL_unitcheckav;
    OUTPUT:
        RETVAL

void 
turn_CvMETHOD_on(code)
        SV* code;
    CODE:
        if (SvTYPE(code) != SVt_RV && SvTYPE(SvRV(code)) != SVt_PVCV) {
            croak("'code' argument is not a CODE reference");
        }
        CvMETHOD_on((CV*) SvRV(code));

MODULE = mop  PACKAGE = mop::internal::util::syntax

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
        if (SvTYPE(keyword) != SVt_RV && SvTYPE(SvRV(keyword)) != SVt_PVCV) {
            croak("'keyword' argument is not a CODE reference");
        }
        if (SvTYPE(handler) != SVt_RV && SvTYPE(SvRV(handler)) != SVt_PVCV) {
            croak("'handler' argument is not a CODE reference");
        }
        cv_set_call_parser( (CV*) SvRV( keyword ), parser_callback, handler );

SV*
parse_full_statement(named = FALSE)
        bool named
    CODE:
        RETVAL = parser_fn( Perl_parse_fullstmt, named );
    OUTPUT:
        RETVAL



