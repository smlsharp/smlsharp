#include "config.h"

#ifdef HAVE_FENV_H
#include <fenv.h>
#else
static void fesetround(int mode){}
static int fegetround(){return 0;}
#define FE_TONEAREST 0
#define FE_DOWNWARD 1
#define FE_UPWARD 2
#define FE_TOWARDZERO 3
#endif

#include "SystemDef.hh"
#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void 
IMLPrim_IEEEReal_setRoundingModeImpl(UInt32Value argsCount,
                                     Cell* argumentRefs[],
                                     Cell* resultRef)
{
    switch(argumentRefs[0]->sint32){
      case 0: ::fesetround(FE_TONEAREST); break;
      case 1: ::fesetround(FE_DOWNWARD); break;
      case 2: ::fesetround(FE_UPWARD); break;
      case 3: ::fesetround(FE_TOWARDZERO); break;
      default:
        Cell exn =
            PrimitiveSupport::constructExnSysErr(0, "setRoundingMod fails.");
        PrimitiveSupport::raiseException(exn);
    }
    return;
};

void 
IMLPrim_IEEEReal_getRoundingModeImpl(UInt32Value argsCount,
                                     Cell* argumentRefs[],
                                     Cell* resultRef)
{
    switch(::fegetround()){
      case FE_TONEAREST: resultRef->sint32 = 0; break; /* = TO_NEAREST */
      case FE_DOWNWARD: resultRef->sint32 = 1; break; /* = TO_NEGINF */
      case FE_UPWARD: resultRef->sint32 = 2; break; /* = TO_POSINF */
      case FE_TOWARDZERO: resultRef->sint32 = 3; break; /* = TO_ZERO */
      default:
        Cell exn =
            PrimitiveSupport::constructExnSysErr(0, "getRoundingMod fails.");
        PrimitiveSupport::raiseException(exn);
    }
};

Primitive IMLPrim_IEEEReal_setRoundingMode = IMLPrim_IEEEReal_setRoundingModeImpl;
Primitive IMLPrim_IEEEReal_getRoundingMode = IMLPrim_IEEEReal_getRoundingModeImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
