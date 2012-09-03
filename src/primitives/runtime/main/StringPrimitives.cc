#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void
IMLPrim_String_concat2Impl(UInt32Value argsCount,
                           Cell* argumentRefs[],
                           Cell* resultRef)
{
    // ToDo : By building the result string directly on the result block,
    // some optimaization is possible.
    // But This requires to push arguments into rootset for GC.
    char* arg1 = PrimitiveSupport::cellToString(*argumentRefs[0]);
    char* arg2 = PrimitiveSupport::cellToString(*argumentRefs[1]);
    UInt32Value arg1Length =
    PrimitiveSupport::cellToStringLength(*argumentRefs[0]);
    UInt32Value arg2Length =
    PrimitiveSupport::cellToStringLength(*argumentRefs[1]);
    char* buffer = new char[arg1Length + arg2Length + 1];
    COPY_MEMORY(buffer, arg1, arg1Length);
    COPY_MEMORY(buffer + arg1Length, arg2, arg2Length);
    buffer[arg1Length + arg2Length] = 0;
    *resultRef =
    PrimitiveSupport::stringToCell(buffer, arg1Length + arg2Length);
    delete[] buffer;
    return;
};

void
IMLPrim_String_subImpl(UInt32Value argsCount,
                       Cell* argumentRefs[],
                       Cell* resultRef)
{
    char* arg1 = PrimitiveSupport::cellToString(*argumentRefs[0]);
    UInt32Value arg1Length =
    PrimitiveSupport::cellToStringLength(*argumentRefs[0]);
    SInt32Value arg2 = argumentRefs[1]->sint32;
    if((arg2 < 0) || (arg1Length <= arg2)){
        // ToDo : ML exception "Sub" should be thrown.
        throw UserException();
    }
    resultRef->uint32 = arg1[arg2];
    return;
};

void
IMLPrim_String_sizeImpl(UInt32Value argsCount,
                        Cell* argumentRefs[],
                        Cell* resultRef)
{
    resultRef->uint32 = PrimitiveSupport::cellToStringLength(*argumentRefs[0]);
    return;
};

void
IMLPrim_String_substringImpl(UInt32Value argsCount,
                             Cell* argumentRefs[],
                             Cell* resultRef)
{
    char* arg1 = PrimitiveSupport::cellToString(*argumentRefs[0]);
    SInt32Value beginIndex = argumentRefs[1]->sint32;
    SInt32Value length = argumentRefs[2]->sint32;
    UInt32Value arg1Length =
    PrimitiveSupport::cellToStringLength(*argumentRefs[0]);
    char* buffer = new char[length + 1];
    COPY_MEMORY(buffer, arg1 + beginIndex, length);
    buffer[length] = 0;
    *resultRef = PrimitiveSupport::stringToCell(buffer, length);
    delete[] buffer;
    return;
    
}

void
IMLPrim_String_updateImpl(UInt32Value argsCount,
                          Cell* argumentRefs[],
                          Cell* resultRef)
{
    char* arg1 = PrimitiveSupport::cellToString(*argumentRefs[0]);
    SInt32Value index = argumentRefs[1]->sint32;
    UInt32Value ch = argumentRefs[2]->uint32;
    arg1[index] = ch;
    resultRef->uint32 = 0;
/*
*    *resultRef = PrimitiveSupport::constructUnit();
*/	
    return;
}

void
IMLPrim_String_allocateImpl(UInt32Value argsCount,
                            Cell* argumentRefs[],
                            Cell* resultRef)
{
    SInt32Value length = argumentRefs[0]->sint32;
    UInt32Value ch = argumentRefs[1]->uint32;
    char* buffer = new char[length + 1];
    for(int index = 0; index < length; index += 1){
        buffer[index] = ch;
    }
    buffer[length] = 0;
    *resultRef = PrimitiveSupport::stringToCell(buffer, length);
    delete[] buffer;
    return;
};

void
IMLPrim_printImpl(UInt32Value argsCount, Cell* argumentRefs[], Cell* resultRef)
{
    char* arg = PrimitiveSupport::cellToString(*argumentRefs[0]);
    int argLength = PrimitiveSupport::cellToStringLength(*argumentRefs[0]);
    PrimitiveSupport::writeToSTDOUT(argLength, arg);
    resultRef->uint32 = 0;
/*
*    *resultRef = PrimitiveSupport::constructUnit();
*/
    return;
};

/* ToDo :
 *  The typedef 'Primitive' is declared in Primitives.hh
 *     typedef void (*Primitive)(UInt32Value, Cell**, Cell*);
 * and primitives are declared also in Primitives.hh as
 *     extern Primitive IMLPrim_Int_toString;
 *  If the IMLPrim_Int_toString is defined in this file as
 *     void IMLPrim_Int_toString(UInt32Value, Cell**, Cell*){ ... }
 * then, compiler complains the declaration and the definition conflict.
 *  If declared in Primitives.hh as,
 *     extern void IMLPrim_Int_toString(UInt32Value, Cell**, Cell*);
 * the compiler do not complain, but is there another solution ?
 * Someone is expected to refine this.
 */
Primitive IMLPrim_String_concat2 = IMLPrim_String_concat2Impl;
Primitive IMLPrim_String_sub = IMLPrim_String_subImpl;
Primitive IMLPrim_String_size = IMLPrim_String_sizeImpl;
Primitive IMLPrim_String_substring = IMLPrim_String_substringImpl;
Primitive IMLPrim_String_update = IMLPrim_String_updateImpl;
Primitive IMLPrim_String_allocate = IMLPrim_String_allocateImpl;
Primitive IMLPrim_print = IMLPrim_printImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
