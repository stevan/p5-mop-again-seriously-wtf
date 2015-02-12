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