// HeapTest0001
// jp_ac_jaist_iml_runtime

/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: HeapTest0001.cc,v 1.1 2005/09/29 16:45:07 kiyoshiy Exp $
 */
#include "HeapTest0001.hh"
#include "FixedHeapClient.hh"
#include "Heap.hh"
#include "SystemDef.hh"

#include "TestCaller.h"

#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void
HeapTest0001::setUp()
{
    // setup facades
}

void
HeapTest0001::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const int TESTALLOCATOMBLOCK0001_HEAP_SIZE = 1024;
const int TESTALLOCATOMBLOCK0001_BLOCKS = 3;
const int TESTALLOCATOMBLOCK0001_FIELDS = 1;

void
HeapTest0001::testAllocAtomBlock0001()
{
    testAllocAtomBlockImpl(TESTALLOCATOMBLOCK0001_HEAP_SIZE,
                           TESTALLOCATOMBLOCK0001_BLOCKS,
                           TESTALLOCATOMBLOCK0001_FIELDS);
}

////////////////////////////////////////

const int TESTALLOCATOMBLOCK0002_HEAP_SIZE = 1024;
const int TESTALLOCATOMBLOCK0002_BLOCKS = 3;
const int TESTALLOCATOMBLOCK0002_FIELDS = 17;

void
HeapTest0001::testAllocAtomBlock0002()
{
    testAllocAtomBlockImpl(TESTALLOCATOMBLOCK0002_HEAP_SIZE,
                           TESTALLOCATOMBLOCK0002_BLOCKS,
                           TESTALLOCATOMBLOCK0002_FIELDS);
}

////////////////////////////////////////

const int TESTALLOCATOMBLOCK0003_HEAP_SIZE = 1024;
const int TESTALLOCATOMBLOCK0003_BLOCKS = 3;
const int TESTALLOCATOMBLOCK0003_FIELDS = 32;

void
HeapTest0001::testAllocAtomBlock0003()
{
    testAllocAtomBlockImpl(TESTALLOCATOMBLOCK0003_HEAP_SIZE,
                           TESTALLOCATOMBLOCK0003_BLOCKS,
                           TESTALLOCATOMBLOCK0003_FIELDS);
}

///////////////////////////////////////////////////////////////////////////////

void
HeapTest0001::testAllocAtomBlockImpl(int heapSize,
                                                   int numBlocks,
                                                   int numFields)
{
    FixedHeapClient client = FixedHeapClient(NULL, 0);
    Heap heap(heapSize, &client);

    SInt32Value fieldValues[numBlocks][numFields];
    for(int blockIndex = 0; blockIndex < numBlocks; blockIndex += 1)
    {
        for(int fieldIndex = 0; fieldIndex < numFields; fieldIndex += 1)
        {
            fieldValues[blockIndex][fieldIndex] = 
            (blockIndex * 100) + fieldIndex;
        }
    }

    Cell* blocks[numBlocks];

    for(int blockIndex = 0; blockIndex < numBlocks; blockIndex += 1)
    {
        blocks[blockIndex] = heap.allocAtomBlock(numFields);
        assertLongsEqual(numFields, heap.getPayloadSize(blocks[blockIndex]));

        for(int fieldIndex = 0; fieldIndex < numFields; fieldIndex += 1)
        {
            Cell value;
            value.sint32 = fieldValues[blockIndex][fieldIndex];
            heap.initializeField(blocks[blockIndex], fieldIndex, value);
        }
    }

    for(int blockIndex = 0; blockIndex < numBlocks; blockIndex += 1)
    {
        assertLongsEqual(numFields, heap.getPayloadSize(blocks[blockIndex]));

        for(int fieldIndex = 0; fieldIndex < numFields; fieldIndex += 1)
        {
            assertLongsEqual
            (fieldValues[blockIndex][fieldIndex],
             blocks[blockIndex][fieldIndex].sint32);
        }
    }
}

///////////////////////////////////////////////////////////////////////////////

HeapTest0001::Suite::Suite()
{
    addTest(new TestCaller<HeapTest0001>
            ("testAllocAtomBlock0001",
             &HeapTest0001::testAllocAtomBlock0001));
    addTest(new TestCaller<HeapTest0001>
            ("testAllocAtomBlock0002",
             &HeapTest0001::testAllocAtomBlock0002));
    addTest(new TestCaller<HeapTest0001>
            ("testAllocAtomBlock0003",
             &HeapTest0001::testAllocAtomBlock0003));
}

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
