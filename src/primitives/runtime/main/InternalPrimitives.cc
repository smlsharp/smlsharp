#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "ExecutableLinker.hh"
#include "Log.hh"
#include "Debug.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void
IMLPrim_Internal_IPToStringImpl(UInt32Value argsCount,
                                Cell* argumentRefs[],
                                Cell* resultRef)
{
    Executable *executable = (Executable*)(argumentRefs[0]->uint32);
    UInt32Value offset = argumentRefs[1]->uint32;

    char buffer[256];
    VirtualMachine::IPToString(buffer, sizeof(buffer), executable, offset);
    *resultRef = PrimitiveSupport::stringToCell(buffer);
}

Primitive IMLPrim_Internal_IPToString = IMLPrim_Internal_IPToStringImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
