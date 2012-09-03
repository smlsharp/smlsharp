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
    Cell arg1 = *argumentRefs[0];
    Cell arg2 = *argumentRefs[1];
    TemporaryRoot root1(&arg1);
    TemporaryRoot root2(&arg2);

    UInt32Value arg1Length = PrimitiveSupport::cellToStringLength(arg1);
    UInt32Value arg2Length = PrimitiveSupport::cellToStringLength(arg2);

    *resultRef = PrimitiveSupport::stringToCell(NULL, arg1Length + arg2Length);
    char* buffer = (char*)(resultRef->blockRef);

    char* argString1 = PrimitiveSupport::cellToString(arg1);
    char* argString2 = PrimitiveSupport::cellToString(arg2);
    COPY_MEMORY(buffer, argString1, arg1Length);
    COPY_MEMORY(buffer + arg1Length, argString2, arg2Length);
    buffer[arg1Length + arg2Length] = 0;

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
    resultRef->uint32 = (unsigned char)arg1[arg2];
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
    Cell arg1 = *argumentRefs[0];
    TemporaryRoot root1(&arg1);

    SInt32Value beginIndex = argumentRefs[1]->sint32;
    SInt32Value length = argumentRefs[2]->sint32;
    UInt32Value arg1Length = PrimitiveSupport::cellToStringLength(arg1);

    *resultRef = PrimitiveSupport::stringToCell(NULL, length);
    char* buffer = (char*)(resultRef->blockRef);

    char* argString1 = PrimitiveSupport::cellToString(arg1);
    COPY_MEMORY(buffer, argString1 + beginIndex, length);
    buffer[length] = 0;

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
    *resultRef = PrimitiveSupport::constructUnit();
    return;
}

void
IMLPrim_String_copyImpl(UInt32Value argsCount,
                        Cell* argumentRefs[],
                        Cell* resultRef)
{
    char* src = PrimitiveSupport::cellToString(*argumentRefs[0]);
    SInt32Value si = argumentRefs[1]->sint32;
    char* dst = PrimitiveSupport::cellToString(*argumentRefs[2]);
    SInt32Value di = argumentRefs[3]->sint32;
    SInt32Value len = argumentRefs[4]->sint32;

    COPY_MEMORY(dst + di, src + si, len);

    *resultRef = PrimitiveSupport::constructUnit();
    return;
}

void
IMLPrim_String_allocateMutableImpl(UInt32Value argsCount,
                                   Cell* argumentRefs[],
                                   Cell* resultRef)
{
    SInt32Value length = argumentRefs[0]->sint32;
    UInt32Value ch = argumentRefs[1]->uint32;

    *resultRef = PrimitiveSupport::stringToCell(NULL, length, true);
    char* buffer = (char*)(resultRef->blockRef);

    for(int index = 0; index < length; index += 1){
        buffer[index] = ch;
    }
    buffer[length] = 0;

    return;
};

void
IMLPrim_String_allocateImmutableImpl(UInt32Value argsCount,
                                     Cell* argumentRefs[],
                                     Cell* resultRef)
{
    SInt32Value length = argumentRefs[0]->sint32;
    UInt32Value ch = argumentRefs[1]->uint32;

    *resultRef = PrimitiveSupport::stringToCell(NULL, length, false);
    char* buffer = (char*)(resultRef->blockRef);

    for(int index = 0; index < length; index += 1){
        buffer[index] = ch;
    }
    buffer[length] = 0;

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
Primitive IMLPrim_String_allocateMutable = IMLPrim_String_allocateMutableImpl;
Primitive IMLPrim_String_allocateImmutable =
            IMLPrim_String_allocateImmutableImpl;
Primitive IMLPrim_String_copy = IMLPrim_String_copyImpl;
Primitive IMLPrim_print = IMLPrim_printImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
