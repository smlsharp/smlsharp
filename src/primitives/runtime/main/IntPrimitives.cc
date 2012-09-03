#include "Primitives.hh"
#include "PrimitiveSupport.hh"
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

Primitive IMLPrim_Int_toString = IMLPrim_Int_toStringImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
