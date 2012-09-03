// HeapTest0002
// jp_ac_jaist_iml_runtime

#include "HeapTest0002.hh"
#include "FixedHeapClient.hh"
#include "Heap.hh"
#include "SystemDef.hh"

#include "TestCaller.h"

#include <stdio.h>

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

void
HeapTest0002::setUp()
{
    // setup facades
}

void
HeapTest0002::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const int TESTALLOCATOMBLOCK0001_HEAP_SIZE = 1024;
const int TESTALLOCATOMBLOCK0001_BLOCKS = 3;
const int TESTALLOCATOMBLOCK0001_FIELDS = 1;

void
HeapTest0002::testAllocPointerBlock0001()
{
    testAllocPointerBlockImpl(TESTALLOCATOMBLOCK0001_HEAP_SIZE,
                              TESTALLOCATOMBLOCK0001_BLOCKS,
                              TESTALLOCATOMBLOCK0001_FIELDS);
}

////////////////////////////////////////

const int TESTALLOCATOMBLOCK0002_HEAP_SIZE = 1024;
const int TESTALLOCATOMBLOCK0002_BLOCKS = 3;
const int TESTALLOCATOMBLOCK0002_FIELDS = 17;

void
HeapTest0002::testAllocPointerBlock0002()
{
    testAllocPointerBlockImpl(TESTALLOCATOMBLOCK0002_HEAP_SIZE,
                              TESTALLOCATOMBLOCK0002_BLOCKS,
                              TESTALLOCATOMBLOCK0002_FIELDS);
}

////////////////////////////////////////

const int TESTALLOCATOMBLOCK0003_HEAP_SIZE = 1024;
const int TESTALLOCATOMBLOCK0003_BLOCKS = 3;
const int TESTALLOCATOMBLOCK0003_FIELDS = 32;

void
HeapTest0002::testAllocPointerBlock0003()
{
    testAllocPointerBlockImpl(TESTALLOCATOMBLOCK0003_HEAP_SIZE,
                              TESTALLOCATOMBLOCK0003_BLOCKS,
                              TESTALLOCATOMBLOCK0003_FIELDS);
}

////////////////////////////////////////

void
HeapTest0002::testAllocPointerBlockImpl(int heapSize,
                                                      int numBlocks,
                                                      int numFields)
{
    FixedHeapClient client = FixedHeapClient(NULL, 0);
    Heap heap =
    Heap(heapSize, &client);

    // set up test values
    Cell* fieldValues[numBlocks][numFields];
    for(int blockIndex = 0; blockIndex < numBlocks; blockIndex += 1)
    {
        for(int fieldIndex = 0; fieldIndex < numFields; fieldIndex += 1)
        {
            fieldValues[blockIndex][fieldIndex] = heap.allocAtomBlock(1);
        }
    }

    ////////////////////////////////////////

    Cell* blocks[numBlocks];

    for(int blockIndex = 0; blockIndex < numBlocks; blockIndex += 1)
    {
        blocks[blockIndex] = heap.allocPointerBlock(numFields);

        for(int fieldIndex = 0; fieldIndex < numFields; fieldIndex += 1)
        {
            Cell value;
            value.blockRef = fieldValues[blockIndex][fieldIndex];
            heap.initializeField(blocks[blockIndex], fieldIndex, value);
        }
    }

    for(int blockIndex = 0; blockIndex < numBlocks; blockIndex += 1)
    {
        assertLongsEqual(numFields, heap.getPayloadSize(blocks[blockIndex]));

        for(int fieldIndex = 0; fieldIndex < numFields; fieldIndex += 1)
        {
            assert(fieldValues[blockIndex][fieldIndex] ==
                   blocks[blockIndex][fieldIndex].blockRef);
        }
    }
}

///////////////////////////////////////////////////////////////////////////////

HeapTest0002::Suite::Suite()
{
    addTest(new TestCaller<HeapTest0002>
            ("testAllocPointerBlock0001",
             &HeapTest0002::testAllocPointerBlock0001));
    addTest(new TestCaller<HeapTest0002>
            ("testAllocPointerBlock0002",
             &HeapTest0002::testAllocPointerBlock0002));
    addTest(new TestCaller<HeapTest0002>
            ("testAllocPointerBlock0003",
             &HeapTest0002::testAllocPointerBlock0003));
}

///////////////////////////////////////////////////////////////////////////////

}
