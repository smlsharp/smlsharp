#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <sys/time.h>
#include <stdlib.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void
IMLPrim_CommandLine_nameImpl(UInt32Value argsCount,
                             Cell* argumentRefs[],
                             Cell* resultRef)
{
    *resultRef =
    PrimitiveSupport::stringToCell(VirtualMachine::getInstance()->getName());
    return;
}

void
IMLPrim_CommandLine_argumentsImpl(UInt32Value argsCount,
                                  Cell* argumentRefs[],
                                  Cell* resultRef)
{
    const char** commandLineArguments;
    int commandLineArgumentsCount = 
    VirtualMachine::getInstance()->getArguments(&commandLineArguments);

    Cell resultList = PrimitiveSupport::constructListNil();
    for(int index = commandLineArgumentsCount - 1; 0 <= index ; index -= 1){
        TemporaryRoot root(&resultList);
        Cell argument =
        PrimitiveSupport::stringToCell(commandLineArguments[index]);
        resultList =
        PrimitiveSupport::constructListCons(&argument, &resultList, true);
    }
    *resultRef = resultList;

    return;
}

Primitive IMLPrim_CommandLine_name = IMLPrim_CommandLine_nameImpl;
Primitive IMLPrim_CommandLine_arguments = IMLPrim_CommandLine_argumentsImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
