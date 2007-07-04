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

void
IMLPrim_Platform_isBigEndianImpl(UInt32Value argsCount,
                                 Cell* argumentRefs[],
                                 Cell* resultRef)
{
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
    *resultRef = PrimitiveSupport::boolToCell(false);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
    *resultRef = PrimitiveSupport::boolToCell(true);
#else
#error ---- BYTE_ORDER_{BIG|LITTLE}_ENDIAN is not defined ----
#endif
}


Primitive IMLPrim_Platform_getPlatform = IMLPrim_Platform_getPlatformImpl;
Primitive IMLPrim_Platform_isBigEndian = IMLPrim_Platform_isBigEndianImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
