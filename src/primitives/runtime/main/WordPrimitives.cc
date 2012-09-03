#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void 
IMLPrim_Word_toStringImpl(UInt32Value argsCount,
                          Cell* argumentRefs[],
                          Cell* resultRef)
{
    char buffer[32];
    sprintf(buffer, "%lx", argumentRefs[0]->uint32);
    *resultRef = PrimitiveSupport::stringToCell(buffer);
    return;
};

Primitive IMLPrim_Word_toString = IMLPrim_Word_toStringImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
