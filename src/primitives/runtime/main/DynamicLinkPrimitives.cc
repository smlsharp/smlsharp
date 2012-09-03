#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <stdlib.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void
IMLPrim_DynamicLink_dlopenImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    char* libName = PrimitiveSupport::cellToString(*argumentRefs[0]);

    DLL_HANDLE dllHandle = DLL_OPEN(libName);
    if(0 == dllHandle){
        char* message = DLL_ERROR();
        Cell exception = PrimitiveSupport::constructExnSysErr(0, message);
        VirtualMachine::getInstance()->setPrimitiveException(exception);
        return;
    }
    resultRef->uint32 = (UInt32Value)dllHandle;
}

void
IMLPrim_DynamicLink_dlcloseImpl(UInt32Value argsCount,
                                Cell* argumentRefs[],
                                Cell* resultRef)
{
    DLL_HANDLE dllHandle = (DLL_HANDLE)(argumentRefs[0]->uint32);
    if(0 != DLL_CLOSE(dllHandle)){
        char* message = DLL_ERROR();
        Cell exception = PrimitiveSupport::constructExnSysErr(0, message);
        VirtualMachine::getInstance()->setPrimitiveException(exception);
        return;
    }
    *resultRef = PrimitiveSupport::constructUnit();
}

void
IMLPrim_DynamicLink_dlsymImpl(UInt32Value argsCount,
                              Cell* argumentRefs[],
                              Cell* resultRef)
{
    DLL_HANDLE dllHandle = (DLL_HANDLE)(argumentRefs[0]->uint32);
    char* funName = PrimitiveSupport::cellToString(*argumentRefs[1]);

    UInt32Value function = (UInt32Value)(DLL_GET_SYM(dllHandle, funName));
    if(0 == function){
        char* message = DLL_ERROR();
        Cell exception = PrimitiveSupport::constructExnSysErr(0, message);
        VirtualMachine::getInstance()->setPrimitiveException(exception);
        return;
    }
    resultRef->uint32 = function;
}

Primitive IMLPrim_DynamicLink_dlopen = IMLPrim_DynamicLink_dlopenImpl;
Primitive IMLPrim_DynamicLink_dlclose = IMLPrim_DynamicLink_dlcloseImpl;
Primitive IMLPrim_DynamicLink_dlsym = IMLPrim_DynamicLink_dlsymImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
