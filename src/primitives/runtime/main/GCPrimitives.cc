#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <stdlib.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void
IMLPrim_GC_addFinalizableImpl(UInt32Value argsCount,
                              Cell* argumentRefs[],
                              Cell* resultRef)
{
    /* actual finalizable is passed packed in a 'ref' block.
     * This is because the type inferencer prohibits a primitive such as
     *   GC_addFinalizable : 'a -> unit
     * so, instead, we use the following alternatively.
     *   GC_addFinalizable : 'a ref -> unit
     */
    Cell* finalizable = argumentRefs[0]->blockRef;
    Heap::addFinalizable(finalizable[0].blockRef);
    *resultRef = PrimitiveSupport::constructUnit();
}

void
IMLPrim_GC_doGCImpl(UInt32Value argsCount,
                    Cell* argumentRefs[],
                    Cell* resultRef)
{
    UInt32Value ifMajor = argumentRefs[0]->uint32;
    Heap::invokeGC(0 == ifMajor ? Heap::GC_MINOR : Heap::GC_MAJOR );
    *resultRef = PrimitiveSupport::constructUnit();
}

bool ensureRefOfBlock(Cell* ref)
{
    if(!Heap::isPointerField(ref, 0))
    {
        // ToDo : raise more specific exception.
        char* message = "expects pointer value.";
        Cell exception = PrimitiveSupport::constructExnFail(message);
        VirtualMachine::getInstance()->setPrimitiveException(exception);
        return false;
    }
    return true;
}

bool ensureFLOB(Cell* block)
{
    if(!Heap::isFLOB(block)){
        // ToDo : raise more specific exception.
        char* message = "expects FLOB.";
        Cell exception = PrimitiveSupport::constructExnFail(message);
        VirtualMachine::getInstance()->setPrimitiveException(exception);
        return false;
    }
    return true;
}

void
IMLPrim_GC_fixedCopyImpl(UInt32Value argsCount,
                         Cell* argumentRefs[],
                         Cell* resultRef)
{
    Cell* refBlock = argumentRefs[0]->blockRef;
    if(!ensureRefOfBlock(refBlock)){return;}
    resultRef->blockRef = Heap::fixedCopy(refBlock[0].blockRef);
}

void
IMLPrim_GC_releaseFLOBImpl(UInt32Value argsCount,
                           Cell* argumentRefs[],
                           Cell* resultRef)
{
    Cell* refBlock = argumentRefs[0]->blockRef;
    if(!ensureRefOfBlock(refBlock)){return;}
    Cell* FLOB = refBlock[0].blockRef;
    if(!ensureFLOB(FLOB)){return;}
    Heap::releaseFLOB(FLOB);
    *resultRef = PrimitiveSupport::constructUnit();
}

void
IMLPrim_GC_addressOfFLOBImpl(UInt32Value argsCount,
                             Cell* argumentRefs[],
                             Cell* resultRef)
{
    Cell* refBlock = argumentRefs[0]->blockRef;
    if(!ensureRefOfBlock(refBlock)){return;}
    Cell* FLOB = refBlock[0].blockRef;
    if(!ensureFLOB(FLOB)){return;}
    resultRef->blockRef = FLOB;
}

void
IMLPrim_GC_copyBlockImpl(UInt32Value argsCount,
                         Cell* argumentRefs[],
                         Cell* resultRef)
{
    Cell* refBlock = argumentRefs[0]->blockRef;
    if(!ensureRefOfBlock(refBlock)){return;}
    Cell* newBlock = Heap::reserveCopy(refBlock[0].blockRef);
    /* Note: Don't use refBlock, because GC might have made it invalid in
     *      Heap::reserveCopy. */
    Heap::copyBlock(argumentRefs[0]->blockRef[0].blockRef, newBlock);
    resultRef->blockRef = newBlock;
}

void
IMLPrim_GC_isAddressOfBlockImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    Cell* block = argumentRefs[0]->blockRef;
    *resultRef
        = PrimitiveSupport::boolToCell(Heap::isValidBlockPointer(block));
}

void
IMLPrim_GC_isAddressOfFLOBImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    Cell* block = argumentRefs[0]->blockRef;// this may be not valid Cell*
    *resultRef = PrimitiveSupport::boolToCell(Heap::isFLOB(block));
}

Primitive IMLPrim_GC_addFinalizable = IMLPrim_GC_addFinalizableImpl;
Primitive IMLPrim_GC_doGC = IMLPrim_GC_doGCImpl;
Primitive IMLPrim_GC_fixedCopy = IMLPrim_GC_fixedCopyImpl;
Primitive IMLPrim_GC_releaseFLOB = IMLPrim_GC_releaseFLOBImpl;
Primitive IMLPrim_GC_addressOfFLOB = IMLPrim_GC_addressOfFLOBImpl;
Primitive IMLPrim_GC_copyBlock = IMLPrim_GC_copyBlockImpl;
Primitive IMLPrim_GC_isAddressOfBlock = IMLPrim_GC_isAddressOfBlockImpl;
Primitive IMLPrim_GC_isAddressOfFLOB = IMLPrim_GC_isAddressOfFLOBImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
