// HeapTest0008
// jp_ac_jaist_iml_runtime

#include "HeapTest0008.hh"
#include "FixedHeapClient.hh"
#include "Heap.hh"
#include "SystemDef.hh"

#include "TestCaller.h"

#include <stdio.h>

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

void
HeapTest0008::setUp()
{
    // setup facades
}

void
HeapTest0008::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const int TESTGC0001_HEAP_SIZE = 3;

void
HeapTest0008::testGC0001()
{
    Cell* blocks[1], * originalBlocks[1];
    Cell** roots[1] = { &blocks[0] };
    FixedHeapClient client = FixedHeapClient(roots, 1);
    Heap heap =
    Heap(TESTGC0001_HEAP_SIZE, &client);
    Cell value;

    originalBlocks[0] = blocks[0] = heap.allocPointerBlock(1);// 2 cell
    value.blockRef = blocks[0];
    heap.initializeField(blocks[0], 0, value);// link to self

    heap.allocAtomBlock(1);// 2 cell (minor GC occurs)

    assert(originalBlocks[0] != blocks[0]);
    assertLongsEqual((long)(blocks[0]),
                     (long)(blocks[0][0].blockRef));
}

////////////////////////////////////////

const int TESTGC0002_HEAP_SIZE = 4;

void
HeapTest0008::testGC0002()
{
    Cell* blocks[2], * originalBlocks[2];
    Cell** roots[2] = { &blocks[0], &blocks[1] };
    FixedHeapClient client = FixedHeapClient(roots, 2);
    Heap heap =
    Heap(TESTGC0002_HEAP_SIZE, &client);
    Cell value;

    originalBlocks[0] = blocks[0] = heap.allocPointerBlock(1);// 2 cell
    originalBlocks[1] = blocks[1] = heap.allocPointerBlock(1);// 2 cell
    value.blockRef = blocks[0];
    heap.initializeField(blocks[1], 0, value);// link S2 -> S1
    value.blockRef = blocks[1];
    heap.updateField(blocks[0], 0, value);// link S1 -> S2

    heap.allocAtomBlock(1);// 2 cell (minor GC occurs)

    assert(originalBlocks[0] != blocks[0]);
    assert(originalBlocks[1] != blocks[1]);
    // verifies S2 -> S1
    assertLongsEqual((long)(blocks[0]), (long)(blocks[1][0].blockRef));
    // verifies S1 -> S2
    assertLongsEqual((long)(blocks[1]), (long)(blocks[0][0].blockRef));
}

////////////////////////////////////////

const int TESTGC0003_HEAP_SIZE = 9;// 3 cells * 3 blocks

void
HeapTest0008::testGC0003()
{
    Cell* blocks[3], * originalBlocks[3];
    Cell** roots[3] = { &blocks[0], NULL, NULL };
    FixedHeapClient client = FixedHeapClient(roots, 1, 3);// elems = 1,cap = 3
    Heap heap =
    Heap(TESTGC0003_HEAP_SIZE, &client);
    Cell value;

    // alloc S1
    originalBlocks[0] = blocks[0] = heap.allocPointerBlock(2);// 3 cell
    value.blockRef = blocks[0];
    heap.initializeField(blocks[0], 0, value);
    heap.initializeField(blocks[0], 1, value);

    // alloc S2
    originalBlocks[1] = blocks[1] = heap.allocPointerBlock(2);// 3 cell
    value.blockRef = blocks[0];
    heap.initializeField(blocks[1], 0, value);// link S2[0] -> S1
    heap.initializeField(blocks[1], 1, value);// link S2[1] -> S1
    client.add(&blocks[1]);// not required...

    heap.allocAtomBlock(3);// 4 cell (minor GC occurs, moves S1,S2 to elder)
    assert(originalBlocks[0] != blocks[0]);
    assert(originalBlocks[1] != blocks[1]);

    // alloc S3
    originalBlocks[2] = blocks[2] = heap.allocPointerBlock(2);// 3 cell
    value.blockRef = blocks[1];
    heap.initializeField(blocks[2], 0, value);// link S3[0] -> S2
    heap.initializeField(blocks[2], 1, value);// link S3[1] -> S2
    client.add(&blocks[2]);// not required...

    // establish a cycle
    value.blockRef = blocks[2];
    heap.updateField(blocks[0], 0, value);// link S1[0] -> S3
    heap.updateField(blocks[0], 1, value);// link S1[1] -> S3

    heap.allocAtomBlock(2);// 3 cell (minor GC occurs)

    // verification
    assert(originalBlocks[0] != blocks[0]);
    assert(originalBlocks[1] != blocks[1]);
    assert(originalBlocks[2] != blocks[2]);
    // verifies S2 -> S1
    assertLongsEqual((long)(blocks[0]),
                     (long)(blocks[1][ 0].blockRef));
    assertLongsEqual((long)(blocks[0]),
                     (long)(blocks[1][ 1].blockRef));
    // verifies S3 -> S2
    assertLongsEqual((long)(blocks[1]),
                     (long)(blocks[2][ 0].blockRef));
    assertLongsEqual((long)(blocks[1]),
                     (long)(blocks[2][ 1].blockRef));
    // verifies S1 -> S3
    assertLongsEqual((long)(blocks[2]),
                     (long)(blocks[0][ 0].blockRef));
    assertLongsEqual((long)(blocks[2]),
                     (long)(blocks[0][ 1].blockRef));
}

///////////////////////////////////////////////////////////////////////////////

HeapTest0008::Suite::Suite()
{
    addTest(new TestCaller<HeapTest0008>
            ("testGC0001",
             &HeapTest0008::testGC0001));
    addTest(new TestCaller<HeapTest0008>
            ("testGC0002",
             &HeapTest0008::testGC0002));
    addTest(new TestCaller<HeapTest0008>
            ("testGC0003",
             &HeapTest0008::testGC0003));
}

///////////////////////////////////////////////////////////////////////////////

}
