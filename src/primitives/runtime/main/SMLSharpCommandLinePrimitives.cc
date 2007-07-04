#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////


void
IMLPrim_SMLSharpCommandLine_executableImageNameImpl(UInt32Value argsCount,
                                                    Cell* argumentRefs[],
                                                    Cell* resultRef)
{
    const char* imageName =
                    VirtualMachine::getInstance()->getExecutableImageName();
    if(imageName){
        Cell nameValue = PrimitiveSupport::stringToCell(imageName);
        *resultRef = PrimitiveSupport::constructOptionSOME(&nameValue, true);
    }
    else{
        *resultRef = PrimitiveSupport::constructOptionNONE();
    }
    return;
}

Primitive IMLPrim_SMLSharpCommandLine_executableImageName =
          IMLPrim_SMLSharpCommandLine_executableImageNameImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
