// HeapTest0010
// jp_ac_jaist_iml_runtime

#include "HeapTest0010.hh"
#include "FixedHeapClient.hh"
#include "Heap.hh"
#include "SystemDef.hh"

#include "TestCaller.h"

#include <stdio.h>

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

void
HeapTest0010::setUp()
{
    // setup facades
}

void
HeapTest0010::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const SInt32Value TESTGC_CONTENTS_OF_DESTINATION = 0x1234ABCD;

////////////////////////////////////////

const int TESTGC0001_HEAP_SIZE = 4;

void
HeapTest0010::testGC0001()
{
    // S : younger
    // D : younger
    // GC : minor
    Cell* S;
    Cell* D;
    Cell** roots[1] = { &S };
    FixedHeapClient client = FixedHeapClient(roots, 1);
    Heap heap =
    Heap(TESTGC0001_HEAP_SIZE, &client);
    Cell value;

    D = heap.allocAtomBlock(1); // 2 cell
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);

    S = heap.allocPointerBlock(1); // 2 cell
    value.blockRef = D;
    heap.initializeField(S, 0, value);

    heap.allocAtomBlock(1); // minor GC occurs

    Cell* newD = S[ 0].blockRef;

    // verifies that GC moves D
    assert(D != newD);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION,
                     newD[ 0].sint32);
}

////////////////////////////////////////

const int TESTGC0002_HEAP_SIZE = 4;

void
HeapTest0010::testGC0002()
{
    // S : younger
    // D : elder-from
    // GC : minor
    Cell* S;
    Cell* D;
    Cell** roots[1] = { &D };// D is included in root at the beginning
    FixedHeapClient client = FixedHeapClient(roots, 1);
    Heap heap =
    Heap(TESTGC0002_HEAP_SIZE, &client);
    Cell value;

    D = heap.allocAtomBlock(1); // 2 cell
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);

    heap.allocAtomBlock(2);// 3 cell (minor GC occurs)

    S = heap.allocPointerBlock(1); // 2 cell
    value.blockRef = D;
    heap.initializeField(S, 0, value);
    client.update(0, &S); // removes D and add S from/to the rootset

    heap.allocAtomBlock(2); // 3 cell (minor GC occurs)

    Cell* newD = S[ 0].blockRef;

    // verifies that GC does not moves D
    assertLongsEqual((long)D, (long)newD);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION,
                     newD[ 0].sint32);
}

////////////////////////////////////////

const int TESTGC0003_HEAP_SIZE = 4;

void
HeapTest0010::testGC0003()
{
    // S : elder-from
    // D : younger
    // GC : minor
    Cell* S;
    Cell* D;
    Cell** roots[1] = { &S };
    FixedHeapClient client = FixedHeapClient(roots, 1);
    Heap heap =
    Heap(TESTGC0003_HEAP_SIZE, &client);
    Cell value;

    S = heap.allocPointerBlock(1); // 2 cell (minor GC occurs)
    value.blockRef = S;
    heap.initializeField(S, 0, value);

    heap.allocAtomBlock(2);// 3 cell (minor GC occurs)

    D = heap.allocAtomBlock(1); // 2 cell
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);
    
    value.blockRef = D;
    heap.updateField(S, 0, value);

    heap.allocAtomBlock(2); // 3 cell (minor GC occurs)

    Cell* newD = S[ 0].blockRef;

    // verifies that GC moves D
    assert(D != newD);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION,
                     newD[ 0].sint32);
}

////////////////////////////////////////

const int TESTGC0004_HEAP_SIZE = 4;

void
HeapTest0010::testGC0004()
{
    // S : elder-from
    // D : elder-from
    // GC : minor
    Cell* S, * originalS;
    Cell* D, * originalD;
    Cell** roots[1] = { &S };
    FixedHeapClient client = FixedHeapClient(roots, 1);
    Heap heap =
    Heap(TESTGC0004_HEAP_SIZE, &client);
    Cell value;

    D = heap.allocAtomBlock(1); // 2 cell
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);

    originalS = S = heap.allocPointerBlock(1); // 2 cell
    value.blockRef = D;
    heap.initializeField(S, 0, value);

    heap.allocAtomBlock(1); // 2 cell (minor GC occurs)
    assert(originalS != S);
    assert(D != S[ 0].blockRef);
    Cell* DbeforeGC = S[ 0].blockRef;

    // now, both S and D are in elder-from

    heap.allocAtomBlock(2);// 3 cell (minor GC occurs)

    Cell* newD = S[ 0].blockRef;

    // verifies that GC does not moves D
    assertLongsEqual((long)DbeforeGC, (long)newD);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION,
                     newD[ 0].sint32);
}

////////////////////////////////////////

const int TESTGC0005_HEAP_SIZE = 2;

void
HeapTest0010::testGC0005()
{
    // S : rootset
    // D : younger
    // GC : minor
    Cell* D, * originalD;
    Cell** roots[1] = { &D };
    FixedHeapClient client = FixedHeapClient(roots, 1);
    Heap heap =
    Heap(TESTGC0005_HEAP_SIZE, &client);
    Cell value;

    originalD = D = heap.allocAtomBlock(1); // 2 cell
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);

    heap.allocAtomBlock(1); // minor GC occurs

    // verifies that GC moves D
    assert(D != originalD);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION,
                     D[ 0].sint32);
}

////////////////////////////////////////

const int TESTGC0006_HEAP_SIZE = 2;

void
HeapTest0010::testGC0006()
{
    // S : rootset
    // D : elder-from
    // GC : minor
    Cell* D, * originalD, * DbeforeGC;
    Cell** roots[1] = { &D };
    FixedHeapClient client = FixedHeapClient(roots, 1);
    Heap heap =
    Heap(TESTGC0006_HEAP_SIZE, &client);
    Cell value;

    originalD = D = heap.allocAtomBlock(1); // 2 cell
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);

    heap.allocAtomBlock(1);// 2 cell (minor GC occurs)
    assert(originalD != D);
    DbeforeGC = D;

    heap.allocAtomBlock(1);// 2 cell (minor GC occurs)

    // verifies that GC does not moves D
    assertLongsEqual((long)DbeforeGC, (long)D);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION,
                     D[ 0].sint32);
}

////////////////////////////////////////

const int TESTGC0007_HEAP_SIZE = 4;

void
HeapTest0010::testGC0007()
{
    // S : younger
    // D : younger
    // GC : major
    Cell* S;
    Cell* D;
    Cell* P;
    Cell** roots[1] = { &P };
    FixedHeapClient client = FixedHeapClient(roots, 1);
    Heap heap =
    Heap(TESTGC0007_HEAP_SIZE, &client);
    Cell value;

    P = heap.allocAtomBlock(1);// 2 cell (padding block) (2,0)
    heap.allocAtomBlock(1);// 2 cell (4,0)

    D = heap.allocAtomBlock(1); // 2 cell (minor GC occurs) (2,2)
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);

    S = heap.allocPointerBlock(1); // 2 cell (4,2)
    value.blockRef = D;
    heap.initializeField(S, 0, value);

    client.update(0, &S);// remove P and add S from/to the rootset

    heap.allocAtomBlock(1); // 2 cell (major GC occurs)

    Cell* newD = S[ 0].blockRef;

    // verifies that GC moves D
    assert(D != newD);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION,
                     newD[ 0].sint32);
}

////////////////////////////////////////

const int TESTGC0008_HEAP_SIZE = 4;

void
HeapTest0010::testGC0008()
{
    // S : younger
    // D : elder-from
    // GC : major
    Cell* S;
    Cell* D;
    Cell* P;
    Cell** roots[] = { &D, &P };// D is included in root at the beginning
    FixedHeapClient client = FixedHeapClient(roots, 2);
    Heap heap =
    Heap(TESTGC0008_HEAP_SIZE, &client);
    Cell value;

    P = heap.allocAtomBlock(1); // 2 cell (2:2,0)

    D = heap.allocAtomBlock(1); // 2 cell (4:4,0)
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);

    heap.allocAtomBlock(1);// 2 cell (minor GC occurs) (2:0,4:4)

    S = heap.allocPointerBlock(1); // 2 cell (4:0,4:4)
    value.blockRef = D;
    heap.initializeField(S, 0, value);
    client.update(0, &S); // removes D and add S from/to the rootset

    client.remove(1);// removes P from the rootset

    // now, heap status is (4:2,4:2)

    heap.allocAtomBlock(1); // 2 cell (major GC occurs)

    Cell* newD = S[ 0].blockRef;

    // verifies that GC moves D
    assert(D != newD);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION,
                     newD[ 0].sint32);
}

////////////////////////////////////////

const int TESTGC0009_HEAP_SIZE = 4;

void
HeapTest0010::testGC0009()
{
    // S : elder-from
    // D : younger
    // GC : minor
    Cell* S;
    Cell* D;
    Cell* P;
    Cell** roots[2] = { &S, &P };
    FixedHeapClient client = FixedHeapClient(roots, 2);
    Heap heap =
    Heap(TESTGC0009_HEAP_SIZE, &client);
    Cell value;

    P = heap.allocAtomBlock(1); // 2 cell (2:2,0)

    S = heap.allocPointerBlock(1); // 2 cell (4:4,0)
    value.blockRef = S;
    heap.initializeField(S, 0, value);

    heap.allocAtomBlock(1);// 2 cell (minor GC occurs) (2:0,4:4)

    D = heap.allocAtomBlock(1); // 2 cell (4:0,4:4)
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);
    
    value.blockRef = D;
    heap.updateField(S, 0, value);

    client.remove(1);// remove P from the rootset

    // now, heap status is (4:2,4:2)

    heap.allocAtomBlock(1); // 2 cell (major GC occurs)

    Cell* newD = S[ 0].blockRef;

    // verifies that GC moves D
    assert(D != newD);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION,
                     newD[ 0].sint32);
}

////////////////////////////////////////

const int TESTGC0010_HEAP_SIZE = 6;

void
HeapTest0010::testGC0010()
{
    // S : elder-from
    // D : elder-from
    // GC : minor
    Cell* S, * originalS;
    Cell* D, * originalD;
    Cell* P;
    Cell** roots[2] = { &S, &P };
    FixedHeapClient client = FixedHeapClient(roots, 2);
    Heap heap =
    Heap(TESTGC0010_HEAP_SIZE, &client);
    Cell value;

    P = heap.allocAtomBlock(1); // 2 cell (2:2,0)

    D = heap.allocAtomBlock(1); // 2 cell (4:2,0)
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);

    originalS = S = heap.allocPointerBlock(1); // 2 cell (6:4,0)
    value.blockRef = D;
    heap.initializeField(S, 0, value);// (6:6,0)

    heap.allocAtomBlock(1); // 2 cell (minor GC occurs) (2:0,6:6)
    assert(originalS != S);
    assert(D != S[ 0].blockRef);
    Cell* DbeforeGC = S[ 0].blockRef;

    // now, both S and D are in elder-from

    P = heap.allocAtomBlock(1);// remove previous P from rootset, and add
    // now, heap status is (4:2,6:4)

    heap.allocAtomBlock(2);// 3 cell (major GC occurs) (3:0,6:6)

    Cell* newD = S[ 0].blockRef;

    // verifies that GC moves D
    assert(DbeforeGC != newD);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION,
                     newD[ 0].sint32);
}

////////////////////////////////////////

const int TESTGC0011_HEAP_SIZE = 2;

void
HeapTest0010::testGC0011()
{
    // S : rootset
    // D : younger
    // GC : major
    Cell* D, * originalD;
    Cell* P;
    Cell** roots[1] = { &P };
    FixedHeapClient client = FixedHeapClient(roots, 1);
    Heap heap =
    Heap(TESTGC0011_HEAP_SIZE, &client);
    Cell value;

    P = heap.allocAtomBlock(1);// 2 cell (2:2,0)

    originalD = D = heap.allocAtomBlock(1); // 2 cell (minor GC) (2:0,2:2)
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);

    client.update(0, &D);// replace P with D in the rootset (2:2,2:0)

    heap.allocAtomBlock(1); // major GC occurs (2:0,2:2)

    // verifies that GC moves D
    assert(D != originalD);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION,
                     D[ 0].sint32);
}

////////////////////////////////////////

const int TESTGC0012_HEAP_SIZE = 4;

void
HeapTest0010::testGC0012()
{
    // S : rootset
    // D : elder-from
    // GC : minor
    Cell* D, * originalD, * DbeforeGC;
    Cell* P;
    Cell** roots[2] = { &D, &P };
    FixedHeapClient client = FixedHeapClient(roots, 2);
    Heap heap =
    Heap(TESTGC0012_HEAP_SIZE, &client);
    Cell value;

    P = heap.allocAtomBlock(1);// 2 cell (2:2,0)

    originalD = D = heap.allocAtomBlock(1); // 2 cell (4:4,0)
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);

    heap.allocAtomBlock(1);// 2 cell (minor GC occurs) (2:0,4:4)
    assert(originalD != D);
    DbeforeGC = D;

    P = heap.allocAtomBlock(1); // remove P from the rootset (4:2,4:2)

    heap.allocAtomBlock(1);// 2 cell (minor GC occurs) (2:0,4:4)

    // verifies that GC does not moves D
    assert(DbeforeGC != D);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION,
                     D[ 0].sint32);
}

///////////////////////////////////////////////////////////////////////////////

HeapTest0010::Suite::Suite()
{
    addTest(new TestCaller<HeapTest0010>
            ("testGC0001",
             &HeapTest0010::testGC0001));
    addTest(new TestCaller<HeapTest0010>
            ("testGC0002",
             &HeapTest0010::testGC0002));
    addTest(new TestCaller<HeapTest0010>
            ("testGC0003",
             &HeapTest0010::testGC0003));
    addTest(new TestCaller<HeapTest0010>
            ("testGC0004",
             &HeapTest0010::testGC0004));
    addTest(new TestCaller<HeapTest0010>
            ("testGC0005",
             &HeapTest0010::testGC0005));
    addTest(new TestCaller<HeapTest0010>
            ("testGC0006",
             &HeapTest0010::testGC0006)); 
    addTest(new TestCaller<HeapTest0010>
            ("testGC0007",
             &HeapTest0010::testGC0007));
    addTest(new TestCaller<HeapTest0010>
            ("testGC0008",
             &HeapTest0010::testGC0008));
    addTest(new TestCaller<HeapTest0010>
            ("testGC0009",
             &HeapTest0010::testGC0009));
    addTest(new TestCaller<HeapTest0010>
            ("testGC0010",
             &HeapTest0010::testGC0010));
    addTest(new TestCaller<HeapTest0010>
            ("testGC0011",
             &HeapTest0010::testGC0011));
    addTest(new TestCaller<HeapTest0010>
            ("testGC0012",
             &HeapTest0010::testGC0012));
}

///////////////////////////////////////////////////////////////////////////////

}
