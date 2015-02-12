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



