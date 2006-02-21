#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <time.h>
#include <stdlib.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void
IMLPrim_Time_gettimeofdayImpl(UInt32Value argsCount,
                              Cell* argumentRefs[],
                              Cell* resultRef)
{
    Cell values[2];
/*
    struct timeval time;
    ::gettimeofday(&time, NULL);
    values[0].sint32 = time.tv_sec;
    values[1].sint32 = time.tv_usec;
*/
    values[0].sint32 = ::time(NULL);
    values[1].sint32 = 0;
    Cell* block = PrimitiveSupport::allocateAtomBlock(2, values);
    resultRef->blockRef = block;
}

Primitive IMLPrim_Time_gettimeofday = IMLPrim_Time_gettimeofdayImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
