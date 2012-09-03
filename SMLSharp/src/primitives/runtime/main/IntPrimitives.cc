#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "LargeInt.hh"
#include "Log.hh"
#include "Debug.hh"

#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void
IMLPrim_Int_toStringImpl(UInt32Value argsCount,
                         Cell* argumentRefs[],
                         Cell* resultRef)
{
    char buffer[32];
    SInt32Value num = argumentRefs[0]->sint32;
    if(0 <= num){
      sprintf(buffer, "%ld", num);
    }
    else{// use "~" instead of "-" as a minus sign character.
      sprintf(buffer, "~%lu", 0 - (UInt32Value)num);
    }
    *resultRef = PrimitiveSupport::stringToCell(buffer);
    return;
};

void
IMLPrim_LargeInt_toStringImpl(UInt32Value argsCount,
                              Cell* argumentRefs[],
                              Cell* resultRef)
{
    // ToDo : 
    PrimitiveSupport::raiseFail("LargeInt_toString is not implemented.");
    return;
};

void
IMLPrim_LargeInt_toIntImpl(UInt32Value argsCount,
                           Cell* argumentRefs[],
                           Cell* resultRef)
{
    resultRef->sint32 =
        LargeInt::toInt(*(LargeInt::largeInt*)(argumentRefs[0]->blockRef));
    return;
};

void
IMLPrim_LargeInt_toWordImpl(UInt32Value argsCount,
                            Cell* argumentRefs[],
                            Cell* resultRef)
{
    resultRef->uint32 =
        LargeInt::toWord(*(LargeInt::largeInt*)(argumentRefs[0]->blockRef));
    return;
};

void
IMLPrim_LargeInt_fromIntImpl(UInt32Value argsCount,
                             Cell* argumentRefs[],
                             Cell* resultRef)
{
    Cell* block = Heap::allocLargeIntBlock(NULL);
    LargeInt::initFromInt(*((LargeInt::largeInt*)block),
                          argumentRefs[0]->sint32);
    resultRef->blockRef = block;
    return;
};

void
IMLPrim_LargeInt_fromWordImpl(UInt32Value argsCount,
                              Cell* argumentRefs[],
                              Cell* resultRef)
{
    Cell* block = Heap::allocLargeIntBlock(NULL);
    LargeInt::initFromWord(*((LargeInt::largeInt*)block),
                           argumentRefs[0]->uint32);
    resultRef->blockRef = block;
    return;
};

/* "largeInt * int -> largeInt" */
void
IMLPrim_LargeInt_powImpl(UInt32Value argsCount,
                         Cell* argumentRefs[],
                         Cell* resultRef)
{
    Cell* block = Heap::allocLargeIntBlock(NULL);
    LargeInt::pow(*((LargeInt::largeInt*)block),
                  *(LargeInt::largeInt*)(argumentRefs[0]->blockRef),
                  argumentRefs[1]->sint32);
    resultRef->blockRef = block;
    return;
};

/* "largeInt -> int" */
void
IMLPrim_LargeInt_log2Impl(UInt32Value argsCount,
                          Cell* argumentRefs[],
                          Cell* resultRef)
{
    resultRef->sint32 =
        LargeInt::log_2(*(LargeInt::largeInt*)(argumentRefs[0]->blockRef));
    return;
};

/* "largeInt * largeInt -> largeInt" */
void
IMLPrim_LargeInt_orbImpl(UInt32Value argsCount,
                         Cell* argumentRefs[],
                         Cell* resultRef)
{
    Cell* block = Heap::allocLargeIntBlock(NULL);
    LargeInt::orb(*((LargeInt::largeInt*)block),
                  *(LargeInt::largeInt*)(argumentRefs[0]->blockRef),
                  *(LargeInt::largeInt*)(argumentRefs[1]->blockRef));
    resultRef->blockRef = block;
    return;
};

/* "largeInt * largeInt -> largeInt" */
void
IMLPrim_LargeInt_xorbImpl(UInt32Value argsCount,
                          Cell* argumentRefs[],
                          Cell* resultRef)
{
    Cell* block = Heap::allocLargeIntBlock(NULL);
    LargeInt::xorb(*((LargeInt::largeInt*)block),
                   *(LargeInt::largeInt*)(argumentRefs[0]->blockRef),
                   *(LargeInt::largeInt*)(argumentRefs[1]->blockRef));
    resultRef->blockRef = block;
    return;
};

/* "largeInt * largeInt -> largeInt" */
void
IMLPrim_LargeInt_andbImpl(UInt32Value argsCount,
                          Cell* argumentRefs[],
                          Cell* resultRef)
{
    Cell* block = Heap::allocLargeIntBlock(NULL);
    LargeInt::andb(*((LargeInt::largeInt*)block),
                   *(LargeInt::largeInt*)(argumentRefs[0]->blockRef),
                   *(LargeInt::largeInt*)(argumentRefs[1]->blockRef));
    resultRef->blockRef = block;
    return;
};

/* "largeInt -> largeInt" */
void
IMLPrim_LargeInt_notbImpl(UInt32Value argsCount,
                          Cell* argumentRefs[],
                          Cell* resultRef)
{
    Cell* block = Heap::allocLargeIntBlock(NULL);
    LargeInt::notb(*((LargeInt::largeInt*)block),
                   *(LargeInt::largeInt*)(argumentRefs[0]->blockRef));
    resultRef->blockRef = block;
    return;
};

Primitive IMLPrim_Int_toString = IMLPrim_Int_toStringImpl;
Primitive IMLPrim_LargeInt_toString = IMLPrim_LargeInt_toStringImpl;
Primitive IMLPrim_LargeInt_toInt = IMLPrim_LargeInt_toIntImpl;
Primitive IMLPrim_LargeInt_toWord = IMLPrim_LargeInt_toWordImpl;
Primitive IMLPrim_LargeInt_fromInt = IMLPrim_LargeInt_fromIntImpl;
Primitive IMLPrim_LargeInt_fromWord = IMLPrim_LargeInt_fromWordImpl;
Primitive IMLPrim_LargeInt_pow = IMLPrim_LargeInt_powImpl;
Primitive IMLPrim_LargeInt_log2 = IMLPrim_LargeInt_log2Impl;
Primitive IMLPrim_LargeInt_orb = IMLPrim_LargeInt_orbImpl;
Primitive IMLPrim_LargeInt_xorb = IMLPrim_LargeInt_xorbImpl;
Primitive IMLPrim_LargeInt_andb = IMLPrim_LargeInt_andbImpl;
Primitive IMLPrim_LargeInt_notb = IMLPrim_LargeInt_notbImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
