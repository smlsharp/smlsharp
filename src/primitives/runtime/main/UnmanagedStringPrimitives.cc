#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <stdlib.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void
IMLPrim_UnmanagedString_sizeImpl(UInt32Value argsCount,
                                 Cell* argumentRefs[],
                                 Cell* resultRef)
{
    char* buffer = (char*)argumentRefs[0]->uint32;
    resultRef->uint32 = ::strlen(buffer);
}

Primitive IMLPrim_UnmanagedString_size = IMLPrim_UnmanagedString_sizeImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
