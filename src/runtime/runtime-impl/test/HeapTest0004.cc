// HeapTest0004
// jp_ac_jaist_iml_runtime

#include "HeapTest0004.hh"
#include "FixedHeapClient.hh"
#include "Heap.hh"
#include "SystemDef.hh"

#include "TestCaller.h"

#include <stdio.h>

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

void
HeapTest0004::setUp()
{
    // setup facades
}

void
HeapTest0004::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const int NUMFIELDS = 32;
const int HEAPSIZE = 1024;

void
HeapTest0004::testUpdateField0001()
{
    FixedHeapClient client = FixedHeapClient(NULL, 0);
    Heap heap =
    Heap(HEAPSIZE, &client);

    Cell* block = heap.allocAtomBlock(NUMFIELDS);

    testUpdateFieldIntegerImpl(heap, block);
}

void
HeapTest0004::testUpdateField0002()
{
    FixedHeapClient client = FixedHeapClient(NULL, 0);
    Heap heap =
    Heap(HEAPSIZE, &client);

    Cell* block = heap.allocPointerBlock(NUMFIELDS);

    testUpdateFieldPointerImpl(heap, block);
}

void
HeapTest0004::testUpdateField0003()
{
    FixedHeapClient client = FixedHeapClient(NULL, 0);
    Heap heap =
    Heap(HEAPSIZE, &client);

    Cell* block = heap.allocRecordBlock((Bitmap)0, NUMFIELDS);

    testUpdateFieldIntegerImpl(heap, block);
}

void
HeapTest0004::testUpdateField0004()
{
    FixedHeapClient client = FixedHeapClient(NULL, 0);
    Heap heap =
    Heap(HEAPSIZE, &client);

    Cell* block = heap.allocRecordBlock((Bitmap)0xFFFFFFFF, NUMFIELDS);

    testUpdateFieldPointerImpl(heap, block);
}

///////////////////////////////////////////////////////////////////////////////

void
HeapTest0004::
testUpdateFieldIntegerImpl(Heap& heap, Cell* block)
{
    SInt32Value initialValues[NUMFIELDS];
    SInt32Value updatedValues[NUMFIELDS];
    for(int fieldIndex = 0; fieldIndex < NUMFIELDS; fieldIndex += 1)
    {
        initialValues[fieldIndex] = fieldIndex;
        updatedValues[fieldIndex] = fieldIndex + 100;
    }

    for(int fieldIndex = 0; fieldIndex < NUMFIELDS; fieldIndex += 1)
    {
        Cell value;
        value.sint32 = initialValues[fieldIndex];
        heap.initializeField(block, fieldIndex, value);
    }

    for(int fieldIndex = 0; fieldIndex < NUMFIELDS; fieldIndex += 1)
    {
        Cell value;
        value.sint32 = updatedValues[fieldIndex];
        heap.updateField(block, fieldIndex, value);
    }

    for(int fieldIndex = 0; fieldIndex < NUMFIELDS; fieldIndex += 1)
    {
        assertLongsEqual(updatedValues[fieldIndex], block[fieldIndex].sint32);

        assert(initialValues[fieldIndex] != block[fieldIndex].sint32);
    }
}

void
HeapTest0004::
testUpdateFieldPointerImpl(Heap& heap, Cell* block)
{
    Cell* initialValues[NUMFIELDS];
    Cell* updatedValues[NUMFIELDS];
    for(int fieldIndex = 0; fieldIndex < NUMFIELDS; fieldIndex += 1)
    {
        initialValues[fieldIndex] = heap.allocAtomBlock(1);
        updatedValues[fieldIndex] = heap.allocAtomBlock(1);
    }

    for(int fieldIndex = 0; fieldIndex < NUMFIELDS; fieldIndex += 1)
    {
        Cell value;
        value.blockRef = initialValues[fieldIndex];
        heap.initializeField(block, fieldIndex, value);
    }

    for(int fieldIndex = 0; fieldIndex < NUMFIELDS; fieldIndex += 1)
    {
        Cell value;
        value.blockRef = updatedValues[fieldIndex];
        heap.updateField(block, fieldIndex, value);
    }

    for(int fieldIndex = 0; fieldIndex < NUMFIELDS; fieldIndex += 1)
    {
        assert(updatedValues[fieldIndex] == block[fieldIndex].blockRef);

        assert(initialValues[fieldIndex] != block[fieldIndex].blockRef);
    }
}

///////////////////////////////////////////////////////////////////////////////

HeapTest0004::Suite::Suite()
{
    addTest(new TestCaller<HeapTest0004>
            ("testUpdateField0001",
             &HeapTest0004::testUpdateField0001));
    addTest(new TestCaller<HeapTest0004>
            ("testUpdateField0002",
             &HeapTest0004::testUpdateField0002));
    addTest(new TestCaller<HeapTest0004>
            ("testUpdateField0003",
             &HeapTest0004::testUpdateField0003));
    addTest(new TestCaller<HeapTest0004>
            ("testUpdateField0004",
             &HeapTest0004::testUpdateField0004));
}

///////////////////////////////////////////////////////////////////////////////

}
