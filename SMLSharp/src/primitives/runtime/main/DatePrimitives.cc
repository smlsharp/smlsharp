#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <time.h>
#include <stdlib.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

const int MAX_STRFTIME_LEN = 1024;

static void
argumentsToTM(Cell* argumentRefs[], struct tm *TM)
{
   TM->tm_sec = argumentRefs[0]->sint32;
   TM->tm_min = argumentRefs[1]->sint32;
   TM->tm_hour = argumentRefs[2]->sint32;
   TM->tm_mday = argumentRefs[3]->sint32;
   TM->tm_mon = argumentRefs[4]->sint32;
   TM->tm_year = argumentRefs[5]->sint32;
   TM->tm_wday = argumentRefs[6]->sint32;
   TM->tm_yday = argumentRefs[7]->sint32;
   TM->tm_isdst = argumentRefs[8]->sint32;
   return;
}

// tm -> string
void
IMLPrim_Date_ascTimeImpl(UInt32Value argsCount,
                         Cell* argumentRefs[],
                         Cell* resultRef)
{
// printf("begin Date_ascTime\n");
    struct tm TM;
    assert(sizeof(struct tm) / sizeof(Cell) == argsCount);
    argumentsToTM(argumentRefs, &TM);

    char formatted[32];
    if(::strftime(formatted, 32, "%a %b %d %H:%M:%S %Y", &TM)){
        *resultRef = PrimitiveSupport::stringToCell(formatted);
    }
    else{
        Cell exn = PrimitiveSupport::constructExnSysErr(0, "ascTime fails.");
        PrimitiveSupport::raiseException(exn);
    }
// printf("end Date_ascTime\n");
    return;
}

// int -> tm
void
IMLPrim_Date_localTimeImpl(UInt32Value argsCount,
                           Cell* argumentRefs[],
                           Cell* resultRef)
{
// printf("begin Date_localTime\n");
    SInt32Value seconds = argumentRefs[0]->sint32;
    int numFields = sizeof(struct tm) / sizeof(Cell);
    assert(9 == numFields);
    Cell* block = Heap::allocAtomBlock(numFields);
    struct tm* local_tm = ::localtime((time_t*)&seconds);
    if(local_tm){
        COPY_MEMORY((struct tm*)block, local_tm, sizeof(struct tm));
        resultRef->blockRef = block;
// printf("end Date_localTime\n");
    }
    else{
        Cell exn = PrimitiveSupport::constructExnSysErr(0, "localTime fails.");
        PrimitiveSupport::raiseException(exn);
            
    }
    return;
}

// int -> tm
void
IMLPrim_Date_gmTimeImpl(UInt32Value argsCount,
                        Cell* argumentRefs[],
                        Cell* resultRef)
{
// printf("begin Date_gmTime\n");
    SInt32Value seconds = argumentRefs[0]->sint32;
    int numFields = sizeof(struct tm) / sizeof(Cell);
    assert(9 == numFields);
    Cell* block = Heap::allocAtomBlock(numFields);
    struct tm* gm_tm = ::gmtime((time_t*)&seconds);
    if(gm_tm){
        COPY_MEMORY((struct tm*)block, gm_tm, sizeof(struct tm));
        resultRef->blockRef = block;
    }
    else{
        Cell exn = PrimitiveSupport::constructExnSysErr(0, "gmTime fails.");
        PrimitiveSupport::raiseException(exn);
    }
// printf("end Date_gmTime\n");
    return;
}

// tm -> int
void
IMLPrim_Date_mkTimeImpl(UInt32Value argsCount,
                        Cell* argumentRefs[],
                        Cell* resultRef)
{
// printf("begin Date_mkTime\n");
    struct tm TM;
    assert(sizeof(struct tm) / sizeof(Cell) == argsCount);
    argumentsToTM(argumentRefs, &TM);
    int seconds = ::mktime(&TM);
    if(-1 == seconds){
        DBGWRAP(LOG.error("mktime(TM = %x) fails.\n", TM));
        DBGWRAP(LOG.error("sec = %d, min = %d, hour = %d, mday = %d, mon = %d, year = %d, wday = %d, yday = %d, isdst = %d\n",
                          TM.tm_sec, TM.tm_min, TM.tm_hour, TM.tm_mday, TM.tm_mon, TM.tm_year, TM.tm_wday, TM.tm_yday, TM.tm_isdst));
        Cell exn = PrimitiveSupport::constructExnSysErr(0, "mkTime fails.");
        PrimitiveSupport::raiseException(exn);
    }
    else{
        resultRef->sint32 = seconds;
    }
// printf("end Date_mkTime\n");
    return;
}

// (string * tm) -> string
void
IMLPrim_Date_strfTimeImpl(UInt32Value argsCount,
                          Cell* argumentRefs[],
                          Cell* resultRef)
{
// printf("begin Date_strfTime\n");
    char* format = PrimitiveSupport::cellToString(*argumentRefs[0]);
    struct tm *TM = (struct tm*)(argumentRefs[1]->blockRef);
    char buffer[MAX_STRFTIME_LEN];
    if(0 == strftime(buffer, MAX_STRFTIME_LEN, format, TM)){
        Cell exn = PrimitiveSupport::constructExnSysErr(0, "strfTime fails.");
        PrimitiveSupport::raiseException(exn);
    }
    else{
        *resultRef = PrimitiveSupport::stringToCell(buffer);
    }
// printf("end Date_strfTime\n");
    return;
}


Primitive IMLPrim_Date_ascTime = IMLPrim_Date_ascTimeImpl;
Primitive IMLPrim_Date_localTime = IMLPrim_Date_localTimeImpl;
Primitive IMLPrim_Date_gmTime = IMLPrim_Date_gmTimeImpl;
Primitive IMLPrim_Date_mkTime = IMLPrim_Date_mkTimeImpl;
Primitive IMLPrim_Date_strfTime = IMLPrim_Date_strfTimeImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
