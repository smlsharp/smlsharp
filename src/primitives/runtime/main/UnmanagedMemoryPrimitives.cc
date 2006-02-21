#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <stdlib.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void
IMLPrim_UnmanagedMemory_allocateImpl(UInt32Value argsCount,
                                     Cell* argumentRefs[],
                                     Cell* resultRef)
{
    int bytes = argumentRefs[0]->sint32;
    void* block = ALLOCATE_MEMORY(bytes);
    resultRef->uint32 = (UInt32Value)block;
}

void
IMLPrim_UnmanagedMemory_releaseImpl(UInt32Value argsCount,
                                    Cell* argumentRefs[],
                                    Cell* resultRef)
{
    void* block = (void*)(argumentRefs[0]->uint32);
    RELEASE_MEMORY(block);
    *resultRef = PrimitiveSupport::constructUnit();
}

void
IMLPrim_UnmanagedMemory_subImpl(UInt32Value argsCount,
                                Cell* argumentRefs[],
                                Cell* resultRef)
{
    char* block = (char*)(argumentRefs[0]->uint32);
    resultRef->uint32 = *block;
}

void
IMLPrim_UnmanagedMemory_updateImpl(UInt32Value argsCount,
                                Cell* argumentRefs[],
                                Cell* resultRef)
{
    char* block = (char*)(argumentRefs[0]->uint32);
    char value = argumentRefs[1]->uint32;
    *block = value;
    *resultRef = PrimitiveSupport::constructUnit();
}

void
IMLPrim_UnmanagedMemory_subWordImpl(UInt32Value argsCount,
                                    Cell* argumentRefs[],
                                    Cell* resultRef)
{
    char* block = (char*)(argumentRefs[0]->uint32);
    resultRef->uint32 = *(UInt32Value*)block;
}

void
IMLPrim_UnmanagedMemory_updateWordImpl(UInt32Value argsCount,
                                       Cell* argumentRefs[],
                                       Cell* resultRef)
{
    char* block = (char*)(argumentRefs[0]->uint32);
    UInt32Value value = argumentRefs[1]->uint32;
    *(UInt32Value*)block = value;
    *resultRef = PrimitiveSupport::constructUnit();
}

void
IMLPrim_UnmanagedMemory_importImpl(UInt32Value argsCount,
                                   Cell* argumentRefs[],
                                   Cell* resultRef)
{
    char* buffer = (char*)(argumentRefs[0]->uint32);
    int bytes = argumentRefs[1]->sint32;
    if(bytes < 0){
        // ToDo : ML exception should be thrown.
        throw UserException();
    }
    *resultRef = PrimitiveSupport::byteArrayToCell(buffer, bytes);
}

void
IMLPrim_UnmanagedMemory_exportImpl(UInt32Value argsCount,
                                   Cell* argumentRefs[],
                                   Cell* resultRef)
{
    Cell block = *argumentRefs[0];
    char* heapBuffer = PrimitiveSupport::cellToString(block);
    int bytes = PrimitiveSupport::cellToStringLength(block);
    void* rawMemory = ALLOCATE_MEMORY(bytes);
    COPY_MEMORY(rawMemory, heapBuffer, bytes);
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
Primitive IMLPrim_UnmanagedMemory_import =
          IMLPrim_UnmanagedMemory_importImpl;
Primitive IMLPrim_UnmanagedMemory_export =
          IMLPrim_UnmanagedMemory_exportImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
