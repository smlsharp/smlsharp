#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "ExecutableLinker.hh"
#include "Log.hh"
#include "Debug.hh"

#include <errno.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void
IMLPrim_StandardC_errnoImpl(UInt32Value argsCount,
                            Cell* argumentRefs[],
                            Cell* resultRef)
{
    resultRef->sint32 = errno;
    return;
}

Primitive IMLPrim_StandardC_errno = IMLPrim_StandardC_errnoImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
