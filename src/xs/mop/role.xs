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
