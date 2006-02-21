// HeapTest0009
// jp_ac_jaist_iml_runtime

#include "HeapTest0009.hh"
#include "FixedHeapClient.hh"
#include "Heap.hh"
#include "SystemDef.hh"

#include "TestCaller.h"

#include <stdio.h>

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

void
HeapTest0009::setUp()
{
    // setup facades
}

void
HeapTest0009::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const int TESTGC0001_HEAP_SIZE = 4;

void
HeapTest0009::testGC0001()
{
    int heapSize = TESTGC0001_HEAP_SIZE;
    Cell* sourceBlocks[1],* originalSourceBlocks[1];
    Cell* destBlocks[1];
    Cell** roots[1] = { &sourceBlocks[0] };
    FixedHeapClient client = FixedHeapClient(roots, 1);
    Heap heap =
    Heap(heapSize, &client);
    Cell value;

    originalSourceBlocks[0] =
    sourceBlocks[0] = heap.allocPointerBlock(1);// 2 cell
    value.blockRef = sourceBlocks[0];
    heap.initializeField(sourceBlocks[0], 0, value);

    heap.allocAtomBlock(2);// 3 cell (minor GC occurs)

    assert(originalSourceBlocks[0] != sourceBlocks[0]);

    destBlocks[0] = heap.allocAtomBlock(1);// 2 cell (minor GC happens)
    value.sint32 = 0;
    heap.initializeField(destBlocks[0], 0, value);

    // make an IGP
    value.blockRef = destBlocks[0];
    heap.updateField(sourceBlocks[0], 0, value);

    heap.allocAtomBlock(2);// 3 cell minor GC occurs

    Cell* destBlock = sourceBlocks[0][ 0].blockRef;
    assert(NULL != destBlock);
    assertLongsEqual(0, destBlock[ 0].sint32);
    
}

////////////////////////////////////////

const int TESTGC0002_HEAP_SIZE = 5;// (3 * 1) + (2 * 1)

void
HeapTest0009::testGC0002()
{
    int heapSize = TESTGC0002_HEAP_SIZE;
    Cell* sourceBlocks[1],* originalSourceBlocks[1];
    Cell* destBlocks[1];
    Cell** roots[1] = { &sourceBlocks[0] };
    FixedHeapClient client = FixedHeapClient(roots, 1);
    Heap heap =
    Heap(heapSize, &client);
    Cell value;

    originalSourceBlocks[0] =
    sourceBlocks[0] = heap.allocPointerBlock(2);// 3 cell
    value.blockRef = sourceBlocks[0];
    heap.initializeField(sourceBlocks[0], 0, value);
    heap.initializeField(sourceBlocks[0], 1, value);

    heap.allocAtomBlock(3);// 4 cell (minor GC occurs)

    assert(originalSourceBlocks[0] != sourceBlocks[0]);

    destBlocks[0] = heap.allocAtomBlock(1);// 2 cell (minor GC happens)
    value.sint32 = 0;
    heap.initializeField(destBlocks[0], 0, value);

    // make an IGP
    value.blockRef = destBlocks[0];
    heap.updateField(sourceBlocks[0], 0, value);
    heap.updateField(sourceBlocks[0], 1, value);

    heap.allocAtomBlock(3);// 4 cell minor GC occurs

    // verifies that S1[0] and S1[1] point to the same block D1.
    {
        Cell* destBlock = sourceBlocks[0][ 0].blockRef;
        assert(NULL != destBlock);
        assert(destBlocks[0] != destBlock);
        assertLongsEqual(0, destBlock[ 0].sint32);
        assertLongsEqual((long)destBlock,
                         (long)sourceBlocks[0][ 1].blockRef);
    }
}

////////////////////////////////////////

const int TESTGC0003_HEAP_SIZE = 7;// (3 * 1) + (2 * 2)

void
HeapTest0009::testGC0003()
{
    int heapSize = TESTGC0003_HEAP_SIZE;
    Cell* sourceBlocks[1],* originalSourceBlocks[1];
    Cell* destBlocks[2];
    Cell** roots[1] = { &sourceBlocks[0] };
    FixedHeapClient client = FixedHeapClient(roots, 1);
    Heap heap =
    Heap(heapSize, &client);
    Cell value;

    originalSourceBlocks[0] =
    sourceBlocks[0] = heap.allocPointerBlock(2);// 3 cell
    value.blockRef = sourceBlocks[0];
    heap.initializeField(sourceBlocks[0], 0, value);
    heap.initializeField(sourceBlocks[0], 1, value);

    heap.allocAtomBlock(5);// 6 cell (minor GC occurs)

    assert(originalSourceBlocks[0] != sourceBlocks[0]);

    destBlocks[0] = heap.allocAtomBlock(1);// 2 cell (minor GC occurs)
    value.sint32 = 0;
    heap.initializeField(destBlocks[0], 0, value);
    destBlocks[1] = heap.allocAtomBlock(1);// 2 cell
    value.sint32 = 1;
    heap.initializeField(destBlocks[1], 0, value);

    // make an IGP
    value.blockRef = destBlocks[0];
    heap.updateField(sourceBlocks[0], 0, value);
    value.blockRef = destBlocks[1];
    heap.updateField(sourceBlocks[0], 1, value);

    heap.allocAtomBlock(3);// 4 cell minor GC occurs

    // verifies that S1[0] points to D1, S1[1] points to D2.
    {
        Cell* destBlock = sourceBlocks[0][ 0].blockRef;
        assert(NULL != destBlock);
        assert(destBlocks[0] != destBlock);
        assertLongsEqual(0, destBlock[ 0].sint32);
    }
    {
        Cell* destBlock = sourceBlocks[0][ 1].blockRef;
        assert(NULL != destBlock);
        assert(destBlocks[1] != destBlock);
        assertLongsEqual(1, destBlock[ 0].sint32);
    }
}

////////////////////////////////////////

const int TESTGC0004_HEAP_SIZE = 6;// (2 * 2) + (2 * 1)

void
HeapTest0009::testGC0004()
{
    int heapSize = TESTGC0004_HEAP_SIZE;
    Cell* sourceBlocks[2],* originalSourceBlocks[2];
    Cell* destBlocks[1];
    Cell** roots[2] = { &sourceBlocks[0], &sourceBlocks[1] };
    FixedHeapClient client = FixedHeapClient(roots, 2);
    Heap heap =
    Heap(heapSize, &client);
    Cell value;

    originalSourceBlocks[0] =
    sourceBlocks[0] = heap.allocPointerBlock(1);// 2 cell
    value.blockRef = sourceBlocks[0];
    heap.initializeField(sourceBlocks[0], 0, value);

    originalSourceBlocks[1] =
    sourceBlocks[1] = heap.allocPointerBlock(1);// 2 cell
    value.blockRef = sourceBlocks[1];
    heap.initializeField(sourceBlocks[1], 0, value);

    heap.allocAtomBlock(2);// 3 cell (minor GC occurs)

    assert(originalSourceBlocks[0] != sourceBlocks[0]);
    assert(originalSourceBlocks[1] != sourceBlocks[1]);

    destBlocks[0] = heap.allocAtomBlock(1);// 2 cell
    value.sint32 = 0;
    heap.initializeField(destBlocks[0], 0, value);

    // make an IGP
    value.blockRef = destBlocks[0];
    heap.updateField(sourceBlocks[0], 0, value);
    heap.updateField(sourceBlocks[1], 0, value);

    heap.allocAtomBlock(1);// 2 cell minor GC occurs

    // verifies that S1[0] and S2[0] point to the same block D1.
    {
        Cell* destBlock = sourceBlocks[0][ 0].blockRef;
        assert(NULL != destBlock);
        assert(destBlocks[0] != destBlock);
        assertLongsEqual(0, destBlock[ 0].sint32);

        assertLongsEqual((long)destBlock,
                         (long)sourceBlocks[1][ 0].blockRef);
    }
}

////////////////////////////////////////

const int TESTGC0005_HEAP_SIZE = 8;// (2 * 2) + (2 * 2)

void
HeapTest0009::testGC0005()
{
    int heapSize = TESTGC0005_HEAP_SIZE;
    Cell* sourceBlocks[2],* originalSourceBlocks[2];
    Cell* destBlocks[2];
    Cell** roots[2] = { &sourceBlocks[0], &sourceBlocks[1] };
    FixedHeapClient client = FixedHeapClient(roots, 2);
    Heap heap =
    Heap(heapSize, &client);
    Cell value;

    heap.allocAtomBlock(1);// 2 cell

    originalSourceBlocks[0] =
    sourceBlocks[0] = heap.allocPointerBlock(1);// 2 cell
    value.blockRef = sourceBlocks[0];
    heap.initializeField(sourceBlocks[0], 0, value);

    originalSourceBlocks[1] =
    sourceBlocks[1] = heap.allocPointerBlock(1);// 2 cell
    value.blockRef = sourceBlocks[1];
    heap.initializeField(sourceBlocks[1], 0, value);

    heap.allocAtomBlock(2);// 3 cell (minor GC occurs)

    assert(originalSourceBlocks[0] != sourceBlocks[0]);
    assert(originalSourceBlocks[1] != sourceBlocks[1]);

    destBlocks[0] = heap.allocAtomBlock(1);// 2 cell
    value.sint32 = 0;
    heap.initializeField(destBlocks[0], 0, value);

    destBlocks[1] = heap.allocAtomBlock(1);// 2 cell
    value.sint32 = 1;
    heap.initializeField(destBlocks[1], 0, value);

    // make an IGP
    value.blockRef = destBlocks[0];
    heap.updateField(sourceBlocks[0], 0, value);
    value.blockRef = destBlocks[1];
    heap.updateField(sourceBlocks[1], 0, value);

    heap.allocAtomBlock(1);// 2 cell minor GC occurs

    // verifies that S1[0] points to D1, S2[0] points to D2.
    {
        Cell* destBlock = sourceBlocks[0][ 0].blockRef;
        assert(NULL != destBlock);
        assert(destBlocks[0] != destBlock);
        assertLongsEqual(0, destBlock[ 0].sint32);
    }
    {
        Cell* destBlock = sourceBlocks[1][ 0].blockRef;
        assert(NULL != destBlock);
        assert(destBlocks[1] != destBlock);
        assertLongsEqual(1, destBlock[ 0].sint32);
    }
}

///////////////////////////////////////////////////////////////////////////////

HeapTest0009::Suite::Suite()
{
    addTest(new TestCaller<HeapTest0009>
            ("testGC0001",
             &HeapTest0009::testGC0001));
    addTest(new TestCaller<HeapTest0009>
            ("testGC0002",
             &HeapTest0009::testGC0002));
    addTest(new TestCaller<HeapTest0009>
            ("testGC0003",
             &HeapTest0009::testGC0003));
    addTest(new TestCaller<HeapTest0009>
            ("testGC0004",
             &HeapTest0009::testGC0004));
    addTest(new TestCaller<HeapTest0009>
            ("testGC0005",
             &HeapTest0009::testGC0005));
}

///////////////////////////////////////////////////////////////////////////////

}
