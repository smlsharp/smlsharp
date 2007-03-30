#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <stdlib.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

#define ASSERT_ALIGNED(address, type) \
ASSERT(0 == ((int)(address) % sizeof(type)))

///////////////////////////////////////////////////////////////////////////////

void
IMLPrim_UnmanagedMemory_allocateImpl(UInt32Value argsCount,
                                     Cell* argumentRefs[],
                                     Cell* resultRef)
{
    int bytes = argumentRefs[0]->sint32;
    void* address = ALLOCATE_MEMORY(bytes);
    resultRef->uint32 = (UInt32Value)address;
}

void
IMLPrim_UnmanagedMemory_releaseImpl(UInt32Value argsCount,
                                    Cell* argumentRefs[],
                                    Cell* resultRef)
{
    void* address = (void*)(argumentRefs[0]->uint32);
    RELEASE_MEMORY(address);
    *resultRef = PrimitiveSupport::constructUnit();
}

void
IMLPrim_UnmanagedMemory_subImpl(UInt32Value argsCount,
                                Cell* argumentRefs[],
                                Cell* resultRef)
{
    unsigned char* address = (unsigned char*)(argumentRefs[0]->uint32);
    resultRef->uint32 = *address;
}

void
IMLPrim_UnmanagedMemory_updateImpl(UInt32Value argsCount,
                                Cell* argumentRefs[],
                                Cell* resultRef)
{
    unsigned char* address = (unsigned char*)(argumentRefs[0]->uint32);
    unsigned char value = argumentRefs[1]->uint32;
    *address = value;
    *resultRef = PrimitiveSupport::constructUnit();
}

void
IMLPrim_UnmanagedMemory_subWordImpl(UInt32Value argsCount,
                                    Cell* argumentRefs[],
                                    Cell* resultRef)
{
    char* address = (char*)(argumentRefs[0]->uint32);
    ASSERT_ALIGNED(address, UInt32Value);
    resultRef->uint32 = *(UInt32Value*)address;
}

void
IMLPrim_UnmanagedMemory_updateWordImpl(UInt32Value argsCount,
                                       Cell* argumentRefs[],
                                       Cell* resultRef)
{
    char* address = (char*)(argumentRefs[0]->uint32);
    UInt32Value value = argumentRefs[1]->uint32;
    ASSERT_ALIGNED(address, UInt32Value);
    *(UInt32Value*)address = value;
    *resultRef = PrimitiveSupport::constructUnit();
}

void
IMLPrim_UnmanagedMemory_subRealImpl(UInt32Value argsCount,
                                    Cell* argumentRefs[],
                                    Cell* resultRef)
{
    Real64Value* address = (Real64Value*)(argumentRefs[0]->uint32);
    ASSERT_ALIGNED(address, Real64Value);
    PrimitiveSupport::real64ToCellRef(*address, resultRef);
}

void
IMLPrim_UnmanagedMemory_updateRealImpl(UInt32Value argsCount,
                                       Cell* argumentRefs[],
                                       Cell* resultRef)
{
    Real64Value* address = (Real64Value*)(argumentRefs[0]->uint32);
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[1]);
    ASSERT_ALIGNED(address, Real64Value);
    *address = realValue;
    *resultRef = PrimitiveSupport::constructUnit();
}

void
IMLPrim_UnmanagedMemory_importImpl(UInt32Value argsCount,
                                   Cell* argumentRefs[],
                                   Cell* resultRef)
{
    char* address = (char*)(argumentRefs[0]->uint32);
    int bytes = argumentRefs[1]->sint32;
    if(bytes < 0){
        // ToDo : ML exception should be thrown.
        throw UserException();
    }
    *resultRef = PrimitiveSupport::byteArrayToCell(address, bytes);
}

void
IMLPrim_UnmanagedMemory_exportImpl(UInt32Value argsCount,
                                   Cell* argumentRefs[],
                                   Cell* resultRef)
{
    Cell block = *argumentRefs[0];
    int offset = argumentRefs[1]->sint32;
    int size = argumentRefs[2]->sint32;
    char* heapBuffer = PrimitiveSupport::cellToString(block);
    int bytes = PrimitiveSupport::cellToStringLength(block);
    if(bytes < size){
        // ToDo : ML exception should be thrown.
        throw UserException();
    }
    void* rawMemory = ALLOCATE_MEMORY(size);
    COPY_MEMORY(rawMemory, heapBuffer + offset, size);
    resultRef->uint32 = (UInt32Value)rawMemory;
}

Primitive IMLPrim_UnmanagedMemory_allocate =
          IMLPrim_UnmanagedMemory_allocateImpl;
Primitive IMLPrim_UnmanagedMemory_release =
          IMLPrim_UnmanagedMemory_releaseImpl;
Primitive IMLPrim_UnmanagedMemory_sub = IMLPrim_UnmanagedMemory_subImpl;
Primitive IMLPrim_UnmanagedMemory_update = IMLPrim_UnmanagedMemory_updateImpl;
Primitive IMLPrim_UnmanagedMemory_subWord =
          IMLPrim_UnmanagedMemory_subWordImpl;
Primitive IMLPrim_UnmanagedMemory_updateWord =
          IMLPrim_UnmanagedMemory_updateWordImpl;
Primitive IMLPrim_UnmanagedMemory_subReal =
          IMLPrim_UnmanagedMemory_subRealImpl;
Primitive IMLPrim_UnmanagedMemory_updateReal =
          IMLPrim_UnmanagedMemory_updateRealImpl;
Primitive IMLPrim_UnmanagedMemory_import =
          IMLPrim_UnmanagedMemory_importImpl;
Primitive IMLPrim_UnmanagedMemory_export =
          IMLPrim_UnmanagedMemory_exportImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
