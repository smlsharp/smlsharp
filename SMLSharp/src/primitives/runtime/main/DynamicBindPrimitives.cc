#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <stdlib.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/*
 * DynamicBind_importSymbol : string -> unit ptr
 */
void
IMLPrim_DynamicBind_importSymbolImpl(UInt32Value argsCount,
                                     Cell* argumentRefs[],
                                     Cell* resultRef)
{
    const char* symbol = PrimitiveSupport::cellToString(*argumentRefs[0]);
    DBGWRAP(fprintf(stderr, "importSymbol(%s)\n", symbol));

    void* fptr = VirtualMachine::getInstance()->importSymbol(symbol);
    if(NULL == fptr){
        const char* message = "import symbol not found.";
        Cell exception = PrimitiveSupport::constructExnSysErr(0, message);
        PrimitiveSupport::raiseException(exception);
        return;
    }
    resultRef->uint32 = (UInt32Value)fptr;
}

/*
 * DynamicBind_exportSymbol : string * unit ptr -> unit
 */
void
IMLPrim_DynamicBind_exportSymbolImpl(UInt32Value argsCount,
                                     Cell* argumentRefs[],
                                     Cell* resultRef)
{
    const char* symbolName = PrimitiveSupport::cellToString(*argumentRefs[0]);
    void* fptr = (void*)argumentRefs[1]->uint32;
    DBGWRAP(fprintf(stderr, "exportSymbol(%s)\n", symbolName));

    VirtualMachine::getInstance()->exportSymbol(symbolName, fptr);

    *resultRef = PrimitiveSupport::constructUnit();
}

Primitive IMLPrim_DynamicBind_importSymbol =
          IMLPrim_DynamicBind_importSymbolImpl;
Primitive IMLPrim_DynamicBind_exportSymbol =
          IMLPrim_DynamicBind_exportSymbolImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
