// HeapTest0006
// jp_ac_jaist_iml_runtime

#include "HeapTest0006.hh"
#include "FixedHeapClient.hh"
#include "Heap.hh"
#include "SystemDef.hh"

#include "TestCaller.h"

#include <stdio.h>

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

void
HeapTest0006::setUp()
{
    // setup facades
}

void
HeapTest0006::tearDown()
{
    //
}

////////////////////////////////////////

void
HeapTest0006::testGCForPointerBlockImpl(int fields)
{
    // size of heap is equal to
    //   (POINTER(fields + 1 cells) * 1) + (ATOM(2 cells) * fields) cells
    int heapSize = ((fields + 1) * 1) + (2 * fields);
    Cell value;
    Cell* block, *originalBlock;
    Cell* atomBlock[fields],*originalAtomBlock[fields];
    Cell** pblocks[1] = { &block };
    FixedHeapClient client = FixedHeapClient(pblocks, 1);
    Heap heap =
    Heap(heapSize, &client);

    ////////////////////////////////////////

    for(int index = 0; index < fields; index += 1){
        originalAtomBlock[index] = heap.allocAtomBlock(1);// 2 cell
        value.sint32 = index;
        heap.initializeField(originalAtomBlock[index], 0, value);
    }
    originalBlock = block = heap.allocPointerBlock(fields);// 2 cell
    for(int index = 0; index < fields; index += 1){
        value.blockRef = originalAtomBlock[index];
        heap.initializeField(block, index, value);
    }

    ////////////////////////////////////////

    // lets the heap manager start GC
    heap.allocAtomBlock(2);

    ////////////////////////////////////////

    // verifies that the block has been moved by GC.
    assert(originalBlock != block);
    for(int index = 0; index < fields; index += 1){
        atomBlock[index] = block[index].blockRef;
        assert(originalAtomBlock[index] != atomBlock[index]);
        // verifies that the contents is not changed.
        assertLongsEqual(index, atomBlock[index][0].sint32);
    }
}

////////////////////////////////////////

const int MAX_FIELDS = 32;

void
HeapTest0006::testGCForRecordBlockImpl
(int fields, int pointerFields, Bitmap bitmap)
{
    int heapSize = ((fields + 2) * 1) + (2 * pointerFields);
    int allocatedAtomBlocks = 0; // for check
    Cell value;
    Cell* block, *originalBlock;
    Cell* atomBlock[MAX_FIELDS],* originalAtomBlock[MAX_FIELDS];
    Cell** pblocks[1] = { &block };
    FixedHeapClient client = FixedHeapClient(pblocks, 1);
    Heap heap =
    Heap(heapSize, &client);

    ////////////////////////////////////////

    for(int index = 0; index < fields; index += 1){
        if(bitmap & (1 << index)){
            originalAtomBlock[index] = heap.allocAtomBlock(1);
            value.sint32 = index;
            heap.initializeField(originalAtomBlock[index], 0, value);
            allocatedAtomBlocks += 1;
        }
    }
    assertLongsEqual(pointerFields, allocatedAtomBlocks);// 
    originalBlock = block = heap.allocRecordBlock(bitmap, fields);
    for(int index = 0; index < fields; index += 1){
        if(bitmap & (1 << index)){
            value.blockRef = originalAtomBlock[index];
        }
        else{
            value.sint32 = index;
        }
        heap.initializeField(block, index, value);
    }

    ////////////////////////////////////////

    // lets the heap manager start GC
    heap.allocAtomBlock(2);

    ////////////////////////////////////////

    // verifies that the block has been moved by GC.
    assert(originalBlock != block);
    for(int index = 0; index < fields; index += 1){
        if(bitmap & (1 << index)){
            atomBlock[index] = block[index].blockRef;
            assert(originalAtomBlock[index] != atomBlock[index]);
            // verifies that the contents is not changed.
            assertLongsEqual(index, atomBlock[index][0].sint32);
        }
        else{
            assertLongsEqual(index, block[index].sint32);
        }
    }
}

///////////////////////////////////////////////////////////////////////////////

const int TESTGC0001_HEAP_SIZE = 34;
const int TESTGC0001_FIELDS = 32;

void
HeapTest0006::testGC0001()
{
    Cell* block, * originalBlock;
    Cell** pblocks[1] = { &block };
    FixedHeapClient client = FixedHeapClient(pblocks, 1);
    Heap heap =
    Heap(TESTGC0001_HEAP_SIZE, &client);

    originalBlock = block = heap.allocAtomBlock(TESTGC0001_FIELDS);
    Cell value;
    value.sint32 = 0;
    heap.initializeField(block, 0, value);

    heap.allocAtomBlock(TESTGC0001_HEAP_SIZE - TESTGC0001_FIELDS);
    // assert that the block has been moved by GC.
    assert(originalBlock != block);
    // assert that the contents is not changed.
    assertLongsEqual(0, block[0].sint32);
}

////////////////////////////////////////

const int TESTGC0002_FIELDS = 1;

void
HeapTest0006::testGC0002()
{
    testGCForPointerBlockImpl(TESTGC0002_FIELDS);
}

////////////////////////////////////////

const int TESTGC0003_FIELDS = 17;

void
HeapTest0006::testGC0003()
{
    testGCForPointerBlockImpl(TESTGC0003_FIELDS);
}

////////////////////////////////////////

const int TESTGC0004_FIELDS = 32;

void
HeapTest0006::testGC0004()
{
    testGCForPointerBlockImpl(TESTGC0004_FIELDS);
}

////////////////////////////////////////

const int TESTGC0005_FIELDS = 1;
const int TESTGC0005_POINTERFIELDS = 0;
const Bitmap TESTGC0005_BITMAP = 0;

void
HeapTest0006::testGC0005()
{
    testGCForRecordBlockImpl(TESTGC0005_FIELDS,
                             TESTGC0005_POINTERFIELDS,
                             TESTGC0005_BITMAP);
}

////////////////////////////////////////

const int TESTGC0006_FIELDS = 1;
const int TESTGC0006_POINTERFIELDS = 1;
const Bitmap TESTGC0006_BITMAP = 1;

void
HeapTest0006::testGC0006()
{
    testGCForRecordBlockImpl(TESTGC0006_FIELDS,
                             TESTGC0006_POINTERFIELDS,
                             TESTGC0006_BITMAP);
}

////////////////////////////////////////

const int TESTGC0007_FIELDS = 2;
const int TESTGC0007_POINTERFIELDS = 0;
const Bitmap TESTGC0007_BITMAP = 0;

void
HeapTest0006::testGC0007()
{
    testGCForRecordBlockImpl(TESTGC0007_FIELDS,
                             TESTGC0007_POINTERFIELDS,
                             TESTGC0007_BITMAP);
}

////////////////////////////////////////

const int TESTGC0008_FIELDS = 2;
const int TESTGC0008_POINTERFIELDS = 1;
const Bitmap TESTGC0008_BITMAP = 1;

void
HeapTest0006::testGC0008()
{
    testGCForRecordBlockImpl(TESTGC0008_FIELDS,
                             TESTGC0008_POINTERFIELDS,
                             TESTGC0008_BITMAP);
}

////////////////////////////////////////

const int TESTGC0009_FIELDS = 2;
const int TESTGC0009_POINTERFIELDS = 1;
const Bitmap TESTGC0009_BITMAP = 2;// = 10B

void
HeapTest0006::testGC0009()
{
    testGCForRecordBlockImpl(TESTGC0009_FIELDS,
                             TESTGC0009_POINTERFIELDS,
                             TESTGC0009_BITMAP);
}

////////////////////////////////////////

const int TESTGC0010_FIELDS = 2;
const int TESTGC0010_POINTERFIELDS = 2;
const Bitmap TESTGC0010_BITMAP = 3;// = 11B

void
HeapTest0006::testGC0010()
{
    testGCForRecordBlockImpl(TESTGC0010_FIELDS,
                             TESTGC0010_POINTERFIELDS,
                             TESTGC0010_BITMAP);
}

////////////////////////////////////////

const int TESTGC0011_FIELDS = 32;
const int TESTGC0011_POINTERFIELDS = 0;
const Bitmap TESTGC0011_BITMAP = 0;// = 0B

void
HeapTest0006::testGC0011()
{
    testGCForRecordBlockImpl(TESTGC0011_FIELDS,
                             TESTGC0011_POINTERFIELDS,
                             TESTGC0011_BITMAP);
}

////////////////////////////////////////

const int TESTGC0012_FIELDS = 32;
const int TESTGC0012_POINTERFIELDS = 3;
const Bitmap TESTGC0012_BITMAP = 0x80010001;// = 10000000 00000001 00000000 00000001B

void
HeapTest0006::testGC0012()
{
    testGCForRecordBlockImpl(TESTGC0012_FIELDS,
                             TESTGC0012_POINTERFIELDS,
                             TESTGC0012_BITMAP);
}

////////////////////////////////////////

const int TESTGC0013_FIELDS = 32;
const int TESTGC0013_POINTERFIELDS = 32;
const Bitmap TESTGC0013_BITMAP = 0xFFFFFFFF;// = 0B

void
HeapTest0006::testGC0013()
{
    testGCForRecordBlockImpl(TESTGC0013_FIELDS,
                             TESTGC0013_POINTERFIELDS,
                             TESTGC0013_BITMAP);
}

///////////////////////////////////////////////////////////////////////////////

HeapTest0006::Suite::Suite()
{
    addTest(new TestCaller<HeapTest0006>
            ("testGC0001",
             &HeapTest0006::testGC0001));
    addTest(new TestCaller<HeapTest0006>
            ("testGC0002",
             &HeapTest0006::testGC0002));
    addTest(new TestCaller<HeapTest0006>
            ("testGC0003",
             &HeapTest0006::testGC0003));
    addTest(new TestCaller<HeapTest0006>
            ("testGC0004",
             &HeapTest0006::testGC0004));
    addTest(new TestCaller<HeapTest0006>
            ("testGC0005",
             &HeapTest0006::testGC0005));
    addTest(new TestCaller<HeapTest0006>
            ("testGC0006",
             &HeapTest0006::testGC0006));
    addTest(new TestCaller<HeapTest0006>
            ("testGC0007",
             &HeapTest0006::testGC0007));
    addTest(new TestCaller<HeapTest0006>
            ("testGC0008",
             &HeapTest0006::testGC0008));
    addTest(new TestCaller<HeapTest0006>
            ("testGC0009",
             &HeapTest0006::testGC0009));
    addTest(new TestCaller<HeapTest0006>
            ("testGC0010",
             &HeapTest0006::testGC0010));
    addTest(new TestCaller<HeapTest0006>
            ("testGC0011",
             &HeapTest0006::testGC0011));
    addTest(new TestCaller<HeapTest0006>
            ("testGC0012",
             &HeapTest0006::testGC0012));
    addTest(new TestCaller<HeapTest0006>
            ("testGC0013",
             &HeapTest0006::testGC0013));
}

///////////////////////////////////////////////////////////////////////////////

}
