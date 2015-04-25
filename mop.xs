#include "EXTERN.h"
#include "perl.h"
#include "callparser1.h"
#include "XSUB.h"

/* ===================================================== */

#include "p5mop.h"
#include "p5mop.c"

#include "p5mop_OV.h"
#include "p5mop_OV.c"

#include "p5mop_MpV.h"
#include "p5mop_MpV.c"

#include "p5mop_MaV.h"
#include "p5mop_MaV.c"

#include "p5mop_MmV.h"
#include "p5mop_MmV.c"

#include "p5mop_internal.h"
#include "p5mop_internal.c"

/* ===================================================== */

MODULE = mop  PACKAGE = mop

INCLUDE: src/xs/mop/role.xs
INCLUDE: src/xs/mop/class.xs
INCLUDE: src/xs/mop/method.xs
INCLUDE: src/xs/mop/attribute.xs
INCLUDE: src/xs/mop/internal.xs





