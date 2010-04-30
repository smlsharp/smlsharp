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

    Cell array;
    array.blockRef =
      PrimitiveSupport::allocatePointerArray(commandLineArgumentsCount, false);
    TemporaryRoot root(&array);

    for(int index = 0; index < commandLineArgumentsCount; index += 1){
        Cell argument =
        PrimitiveSupport::stringToCell(commandLineArguments[index]);
        Heap::initializeField(array.blockRef, index, argument);
    }
    *resultRef = array;

    return;
}

Primitive IMLPrim_CommandLine_name = IMLPrim_CommandLine_nameImpl;
Primitive IMLPrim_CommandLine_arguments = IMLPrim_CommandLine_argumentsImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
