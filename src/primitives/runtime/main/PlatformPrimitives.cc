#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Constants.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void
IMLPrim_Platform_getPlatformImpl(UInt32Value argsCount,
                                 Cell* argumentRefs[],
                                 Cell* resultRef)
{
  *resultRef = PrimitiveSupport::stringToCell(SMLSHARP_PLATFORM);
  return;
}

Primitive IMLPrim_Platform_getPlatform = IMLPrim_Platform_getPlatformImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
