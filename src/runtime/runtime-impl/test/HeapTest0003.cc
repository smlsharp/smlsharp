// HeapTest0003
// jp_ac_jaist_iml_runtime

#include "HeapTest0003.hh"
#include "FixedHeapClient.hh"
#include "Heap.hh"
#include "SystemDef.hh"

#include "TestCaller.h"

#include <stdio.h>

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

void
HeapTest0003::setUp()
{
    // setup facades
}

void
HeapTest0003::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const int TESTALLOCATOMBLOCK0001_HEAP_SIZE = 1024;
const int TESTALLOCATOMBLOCK0001_BLOCKS = 3;
const int TESTALLOCATOMBLOCK0001_FIELDS = 1;

void
HeapTest0003::testAllocRecordBlock0001()
{
    testAllocRecordBlockImplAllInteger(TESTALLOCATOMBLOCK0001_HEAP_SIZE,
                                       TESTALLOCATOMBLOCK0001_BLOCKS,
                                       TESTALLOCATOMBLOCK0001_FIELDS);
}

////////////////////////////////////////

const int TESTALLOCATOMBLOCK0002_HEAP_SIZE = 1024;
const int TESTALLOCATOMBLOCK0002_BLOCKS = 3;
const int TESTALLOCATOMBLOCK0002_FIELDS = 1;
const Bitmap TESTALLOCATOMBLOCK0002_BITMAP = 1;

void
HeapTest0003::testAllocRecordBlock0002()
{
    testAllocRecordBlockImplAllPointer(TESTALLOCATOMBLOCK0002_HEAP_SIZE,
                                       TESTALLOCATOMBLOCK0002_BITMAP,
                                       TESTALLOCATOMBLOCK0002_BLOCKS,
                                       TESTALLOCATOMBLOCK0002_FIELDS);
}

////////////////////////////////////////

const int TESTALLOCATOMBLOCK0003_HEAP_SIZE = 1024;
const int TESTALLOCATOMBLOCK0003_BLOCKS = 3;
const int TESTALLOCATOMBLOCK0003_FIELDS = 17;

void
HeapTest0003::testAllocRecordBlock0003()
{
    testAllocRecordBlockImplAllInteger(TESTALLOCATOMBLOCK0003_HEAP_SIZE,
                                       TESTALLOCATOMBLOCK0003_BLOCKS,
                                       TESTALLOCATOMBLOCK0003_FIELDS);
}

////////////////////////////////////////

const int TESTALLOCATOMBLOCK0004_HEAP_SIZE = 1024;
const int TESTALLOCATOMBLOCK0004_BLOCKS = 3;
const int TESTALLOCATOMBLOCK0004_FIELDS = 17;
const Bitmap TESTALLOCATOMBLOCK0004_BITMAP = 0x1FFFF;

void
HeapTest0003::testAllocRecordBlock0004()
{
    testAllocRecordBlockImplAllPointer(TESTALLOCATOMBLOCK0004_HEAP_SIZE,
                                       TESTALLOCATOMBLOCK0004_BITMAP,
                                       TESTALLOCATOMBLOCK0004_BLOCKS,
                                       TESTALLOCATOMBLOCK0004_FIELDS);
}

////////////////////////////////////////

const int TESTALLOCATOMBLOCK0005_HEAP_SIZE = 1024;
const int TESTALLOCATOMBLOCK0005_BLOCKS = 3;
const int TESTALLOCATOMBLOCK0005_FIELDS = 17;
const Bitmap TESTALLOCATOMBLOCK0005_BITMAP = 0x15555;// 10101010 10101010 1B

void
HeapTest0003::testAllocRecordBlock0005()
{
    testAllocRecordBlockImplMixed(TESTALLOCATOMBLOCK0005_HEAP_SIZE,
                                  TESTALLOCATOMBLOCK0005_BITMAP,
                                  TESTALLOCATOMBLOCK0005_BLOCKS,
                                  TESTALLOCATOMBLOCK0005_FIELDS);
}

////////////////////////////////////////


const int TESTALLOCATOMBLOCK0006_HEAP_SIZE = 1024;
const int TESTALLOCATOMBLOCK0006_BLOCKS = 3;
const int TESTALLOCATOMBLOCK0006_FIELDS = 32;

void
HeapTest0003::testAllocRecordBlock0006()
{
    testAllocRecordBlockImplAllInteger(TESTALLOCATOMBLOCK0006_HEAP_SIZE,
                                       TESTALLOCATOMBLOCK0006_BLOCKS,
                                       TESTALLOCATOMBLOCK0006_FIELDS);
}

////////////////////////////////////////

const int TESTALLOCATOMBLOCK0007_HEAP_SIZE = 1024;
const int TESTALLOCATOMBLOCK0007_BLOCKS = 3;
const int TESTALLOCATOMBLOCK0007_FIELDS = 1;
const Bitmap TESTALLOCATOMBLOCK0007_BITMAP = 0xFFFFFFFF;

void
HeapTest0003::testAllocRecordBlock0007()
{
    testAllocRecordBlockImplAllPointer(TESTALLOCATOMBLOCK0007_HEAP_SIZE,
                                       TESTALLOCATOMBLOCK0007_BITMAP,
                                       TESTALLOCATOMBLOCK0007_BLOCKS,
                                       TESTALLOCATOMBLOCK0007_FIELDS);
}

////////////////////////////////////////

const int TESTALLOCATOMBLOCK0008_HEAP_SIZE = 1024;
const int TESTALLOCATOMBLOCK0008_BLOCKS = 3;
const int TESTALLOCATOMBLOCK0008_FIELDS = 32;
const Bitmap TESTALLOCATOMBLOCK0008_BITMAP = 0xAAAAAAAA;// 1010 ... 1010 B

void
HeapTest0003::testAllocRecordBlock0008()
{
    testAllocRecordBlockImplMixed(TESTALLOCATOMBLOCK0008_HEAP_SIZE,
                                  TESTALLOCATOMBLOCK0008_BITMAP,
                                  TESTALLOCATOMBLOCK0008_BLOCKS,
                                  TESTALLOCATOMBLOCK0008_FIELDS);
}

///////////////////////////////////////////////////////////////////////////////

void
HeapTest0003::testAllocRecordBlockImplAllInteger(int heapSize,
                                                               int numBlocks,
                                                               int numFields)
{
    FixedHeapClient client = FixedHeapClient(NULL, 0);
    Heap heap =
    Heap(heapSize, &client);

    // set up test values
    SInt32Value fieldValues[numBlocks][numFields];
    for(int blockIndex = 0; blockIndex < numBlocks; blockIndex += 1)
    {
        for(int fieldIndex = 0; fieldIndex < numFields; fieldIndex += 1)
        {
            fieldValues[blockIndex][fieldIndex] =
            (blockIndex * 100) + fieldIndex;
        }
    }

    ////////////////////////////////////////

    Cell* blocks[numBlocks];

    for(int blockIndex = 0; blockIndex < numBlocks; blockIndex += 1)
    {
        blocks[blockIndex] = heap.allocRecordBlock((Bitmap)0, numFields);

        for(int fieldIndex = 0; fieldIndex < numFields; fieldIndex += 1)
        {
            Cell value;
            value.sint32 = fieldValues[blockIndex][fieldIndex];
            heap.initializeField(blocks[blockIndex], fieldIndex, value);
        }
    }

    for(int blockIndex = 0; blockIndex < numBlocks; blockIndex += 1)
    {
        // record block has an extra field for bitmap.
        assertLongsEqual(numFields, heap.getPayloadSize(blocks[blockIndex]));
        assertLongsEqual((Bitmap)0, heap.getBitmap(blocks[blockIndex]));

        for(int fieldIndex = 0; fieldIndex < numFields; fieldIndex += 1)
        {
            assertLongsEqual
            (fieldValues[blockIndex][fieldIndex],
             blocks[blockIndex][fieldIndex].sint32);
        }
    }
}

void
HeapTest0003::testAllocRecordBlockImplAllPointer(int heapSize,
                                                               Bitmap bitmap,
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
        blocks[blockIndex] = heap.allocRecordBlock(bitmap, numFields);

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
        assertLongsEqual(bitmap, heap.getBitmap(blocks[blockIndex]));

        for(int fieldIndex = 0; fieldIndex < numFields; fieldIndex += 1)
        {
            assert(fieldValues[blockIndex][fieldIndex] ==
                   blocks[blockIndex][fieldIndex].blockRef);
        }
    }
}

void
HeapTest0003::testAllocRecordBlockImplMixed(int heapSize,
                                                          Bitmap bitmap,
                                                          int numBlocks,
                                                          int numFields)
{
    FixedHeapClient client = FixedHeapClient(NULL, 0);
    Heap heap =
    Heap(heapSize, &client);

    // set up test values
    Cell fieldValues[numBlocks][numFields];
    for(int blockIndex = 0; blockIndex < numBlocks; blockIndex += 1)
    {
        for(int fieldIndex = 0; fieldIndex < numFields; fieldIndex += 1)
        {
            if(0 != ((bitmap >> fieldIndex) & 1)){
                fieldValues[blockIndex][fieldIndex].blockRef =
                heap.allocAtomBlock(1);
            }
            else{
                fieldValues[blockIndex][fieldIndex].sint32 = fieldIndex;
            }
        }
    }

    ////////////////////////////////////////

    Cell* blocks[numBlocks];

    for(int blockIndex = 0; blockIndex < numBlocks; blockIndex += 1)
    {
        blocks[blockIndex] = heap.allocRecordBlock(bitmap, numFields);

        for(int fieldIndex = 0; fieldIndex < numFields; fieldIndex += 1)
        {
            Cell value;
            value = fieldValues[blockIndex][fieldIndex];
            heap.initializeField(blocks[blockIndex], fieldIndex, value);
        }
    }

    for(int blockIndex = 0; blockIndex < numBlocks; blockIndex += 1)
    {
        assertLongsEqual(numFields, heap.getPayloadSize(blocks[blockIndex]));
        assertLongsEqual(bitmap, heap.getBitmap(blocks[blockIndex]));

        for(int fieldIndex = 0; fieldIndex < numFields; fieldIndex += 1)
        {
            if(0 != ((bitmap >> fieldIndex) & 1)){
                assert(fieldValues[blockIndex][fieldIndex].blockRef ==
                       blocks[blockIndex][fieldIndex].blockRef);
            }
            else{
                assertLongsEqual(fieldValues[blockIndex][fieldIndex].sint32,
                                 blocks[blockIndex][fieldIndex].sint32);
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////////

HeapTest0003::Suite::Suite()
{
    addTest(new TestCaller<HeapTest0003>
            ("testAllocRecordBlock0001",
             &HeapTest0003::testAllocRecordBlock0001));
    addTest(new TestCaller<HeapTest0003>
            ("testAllocRecordBlock0002",
             &HeapTest0003::testAllocRecordBlock0002));
    addTest(new TestCaller<HeapTest0003>
            ("testAllocRecordBlock0003",
             &HeapTest0003::testAllocRecordBlock0003));
    addTest(new TestCaller<HeapTest0003>
            ("testAllocRecordBlock0004",
             &HeapTest0003::testAllocRecordBlock0004));
    addTest(new TestCaller<HeapTest0003>
            ("testAllocRecordBlock0005",
             &HeapTest0003::testAllocRecordBlock0005));
    addTest(new TestCaller<HeapTest0003>
            ("testAllocRecordBlock0006",
             &HeapTest0003::testAllocRecordBlock0006));
    addTest(new TestCaller<HeapTest0003>
            ("testAllocRecordBlock0007",
             &HeapTest0003::testAllocRecordBlock0007));
    addTest(new TestCaller<HeapTest0003>
            ("testAllocRecordBlock0008",
             &HeapTest0003::testAllocRecordBlock0008));
}

///////////////////////////////////////////////////////////////////////////////

}
