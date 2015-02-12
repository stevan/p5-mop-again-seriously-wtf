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