#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#if defined(HAVE_SYS_TIME_H) && defined(HAVE_GETTIMEOFDAY)
#include <sys/time.h>
#else
#include <time.h>
#endif
#include <stdlib.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void
IMLPrim_Time_gettimeofdayImpl(UInt32Value argsCount,
                              Cell* argumentRefs[],
                              Cell* resultRef)
{
    Cell values[2];

#if defined(HAVE_GETTIMEOFDAY)
    struct timeval time;
    ::gettimeofday(&time, NULL);
    values[0].sint32 = time.tv_sec;
    values[1].sint32 = time.tv_usec;
#else
    values[0].sint32 = ::time(NULL);
    values[1].sint32 = 0;
#endif
    Cell* block = PrimitiveSupport::allocateAtomBlock(2, values);
    resultRef->blockRef = block;
}

Primitive IMLPrim_Time_gettimeofday = IMLPrim_Time_gettimeofdayImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
