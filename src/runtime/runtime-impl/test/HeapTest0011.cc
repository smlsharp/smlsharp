// HeapTest0011
// jp_ac_jaist_iml_runtime

#include "HeapTest0011.hh"
#include "FixedHeapClient.hh"
#include "Heap.hh"
#include "SystemDef.hh"

#include "TestCaller.h"

#include <stdio.h>

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

void
HeapTest0011::setUp()
{
    // setup facades
}

void
HeapTest0011::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const SInt32Value TESTGC_CONTENTS_OF_DESTINATION = 0x1234ABCD;

////////////////////////////////////////

const int TESTGC0001_HEAP_SIZE = 4;

void
HeapTest0011::testGC0001()
{
    // S : younger
    // D : younger
    // GC : minor
    Cell* S;
    Cell* D, *originalD;
    Cell** roots[2] = { &D, &S };
    FixedHeapClient client = FixedHeapClient(roots, 2);
    Heap heap =
    Heap(TESTGC0001_HEAP_SIZE, &client);
    Cell value;

    originalD = D = heap.allocAtomBlock(1); // 2 cell (2:2,0)
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);

    S = heap.allocPointerBlock(1); // 2 cell (4:4,0)
    value.blockRef = D;
    heap.initializeField(S, 0, value);

    //  Because D is in front of S in the rootset, GC reaches and copies D
    // before S.
    //  When GC reaches S, it will find that S[0] points to D in younger and
    // the D has been forwarded to elder-from.
    heap.allocAtomBlock(1); // minor GC occurs

    // verifies that S refers the new location of D
    Cell* newD = S[0].blockRef;
    assert(originalD != newD);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION, newD[0].sint32);
}

////////////////////////////////////////

const int TESTGC0002_HEAP_SIZE = 4;

void
HeapTest0011::testGC0002()
{
    // S : younger
    // D : younger
    // E : elder-from (refers D)
    // GC : major
    Cell* S;
    Cell* D;
    Cell* E;
    Cell** roots[1] = { &E };
    FixedHeapClient client = FixedHeapClient(roots, 1);
    Heap heap =
    Heap(TESTGC0002_HEAP_SIZE, &client);
    Cell value;

    E = heap.allocPointerBlock(1);// 2 cell (2:2,0)
    value.blockRef = E;
    heap.initializeField(E, 0, value);
    heap.allocAtomBlock(2);// 2 cell (4:2,0)

    D = heap.allocAtomBlock(1); // 2 cell (minor GC) -> (2:0,2:2)
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);

    value.blockRef = D;
    heap.updateField(E, 0, value);// add a pointer to D from E -> (2:2,2:2)

    S = heap.allocPointerBlock(1); // 2 cell (4:2,2:2)
    value.blockRef = D;
    heap.initializeField(S, 0, value);

    client.update(0, &S); // remove E/add S from/to rootset -> (4:4,2:0)

    //  The next allocation invokes GC.
    //  GC starts in minor mode, and minor GC scans the assignments before the
    // pointers provided by the client.
    //  Because D is referred by an IGP (stored E), minor GC reaches and copies
    // D and leave a forward pointer in the previous location of D.
    //  By copying D to elder-from region, the region become full.
    // When GC tries to copy S to the elder-from region, it finds the region
    // full and switches to major GC.
    //  In major GC, the assignments is not included in the rootset. GC reaches
    // D through only the pass from the S.
    //  When GC reaches S, it will find that S[0] points to D in younger and
    // the D has been forwarded to elder-from. Then, GC moves D once more to
    // elder-to region.
    heap.allocAtomBlock(1); // major GC occurs

    // verifies that S refers the new location of D
    Cell* newD = S[0].blockRef;
    assert(D != newD);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION, newD[0].sint32);
}

////////////////////////////////////////

const int TESTGC0003_HEAP_SIZE = 4;

void
HeapTest0011::testGC0003()
{
    Cell* S;
    Cell* D, *originalD;
    Cell* B; // dummy
    Cell** roots[2] = { &B };
    FixedHeapClient client = FixedHeapClient(roots, 1, 2);
    Heap heap =
    Heap(TESTGC0003_HEAP_SIZE, &client);
    Cell value;

    B = heap.allocAtomBlock(3); // 4 cell (4:4,0)

    originalD = D = heap.allocAtomBlock(1); // 2 cell (minor GC) -> (2:0,4:4)
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);

    client.update(0, &D);// remove B/add D to/from rootset -> (2:2,4:0)

    S = heap.allocPointerBlock(1); // 2 cell (4:2,4:0)
    value.blockRef = D;
    heap.initializeField(S, 0, value);

    client.add(&S); // (4:4,4:0)

    //  The next allocation invokes GC.
    //  Because D is in front of S in the rootset, GC reaches and copies D
    // before S. When tries to copy the block D, GC finds that the elder-from
    // region is full and switches to major GC.
    //  The major GC moves the block D to the elder-to region from the younger
    // region directly.
    //  When GC reaches S, it will find that S[0] points to D in younger and
    // the D has been forwarded to elder-to.
    heap.allocAtomBlock(1); // major GC occurs

    // verifies that S refers the new location of D
    Cell* newD = S[0].blockRef;
    assert(originalD != newD);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION, newD[0].sint32);
}

////////////////////////////////////////

const int TESTGC0004_HEAP_SIZE = 4;

void
HeapTest0011::testGC0004()
{
    Cell* S;
    Cell* D, *originalD;
    Cell* B; // dummy
    Cell** roots[3] = { &D, &B, &S };
    FixedHeapClient client = FixedHeapClient(roots, 2, 3);
    Heap heap =
    Heap(TESTGC0004_HEAP_SIZE, &client);
    Cell value;

    B = heap.allocAtomBlock(1); // 2 cell (2:2, 0)

    D = heap.allocAtomBlock(1); // 2 cell (4:4,0)
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);

    S = heap.allocPointerBlock(1); // 2 cell (minor GC) -> (2:0,4:4)
    value.blockRef = D;
    heap.initializeField(S, 0, value);
    client.add(&S);// (2:2,4:4)

    heap.allocAtomBlock(1); // 2 cell (4:2,4:4)
    client.remove(1);// remove B from the rootset -> (4:2,4:2)

    originalD = D;

    //  The next allocation invokes GC.
    //  Because D is in front of S in the rootset, GC reaches and copies D
    // before S. When tries to copy the block B, GC finds that the elder-from
    // region is full and switches to major GC.
    //  The major GC moves the block D to the elder-to region from the
    // elder-from region.
    //  When GC reaches S, it will find that S[0] points to D in elder-from and
    // the D has been forwarded to elder-to.
    heap.allocAtomBlock(1); // 2 cell (major GC occurs) -> (2:0,4:4)

    // verifies that S refers the new location of D
    Cell* newD = S[0].blockRef;
    assert(originalD != newD);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION, newD[0].sint32);
}

////////////////////////////////////////

const int TESTGC0005_HEAP_SIZE = 4;

void
HeapTest0011::testGC0005()
{
    Cell* S;
    Cell* D, *originalD;
    Cell* B; // dummy
    Cell** roots[3] = { &B };
    FixedHeapClient client = FixedHeapClient(roots, 1, 3);
    Heap heap =
    Heap(TESTGC0005_HEAP_SIZE, &client);
    Cell value;

    B = heap.allocAtomBlock(1); // 2 cell (2:2,0)
    heap.allocAtomBlock(1);// 2 cell (4:2,0)

    D = heap.allocAtomBlock(1); // 2 cell (minor GC) (2:0,2:2)
    value.sint32 = TESTGC_CONTENTS_OF_DESTINATION;
    heap.initializeField(D, 0, value);
    client.add(&D);// (2:2,2:2)

    S = heap.allocPointerBlock(1); // 2 cell (4:2,2:2)
    value.blockRef = D;
    heap.initializeField(S, 0, value);
    client.add(&S);// (4:4,2:2)

    client.remove(0);// remove B from the rootset -> (4:4,2:0)

    originalD = D;

    //  The next allocation invokes GC.
    //  Because D is in front of S in the rootset, GC reaches and copies D
    // before S. When tries to copy the block B, GC finds that the elder-from
    // region is full and switches to major GC.
    //  The major GC moves the block D to the elder-to region from the
    // elder-from region.
    //  When GC reaches S, it will find that S[0] points to D in elder-from and
    // the D has been forwarded to elder-to.
    heap.allocAtomBlock(1); // 2 cell (major GC occurs) -> (2:0,4:4)

    // verifies that S refers the new location of D
    Cell* newD = S[0].blockRef;
    assert(originalD != newD);
    assertLongsEqual(TESTGC_CONTENTS_OF_DESTINATION, newD[0].sint32);
}

///////////////////////////////////////////////////////////////////////////////

HeapTest0011::Suite::Suite()
{
    addTest(new TestCaller<HeapTest0011>
            ("testGC0001",
             &HeapTest0011::testGC0001));
    addTest(new TestCaller<HeapTest0011>
            ("testGC0002",
             &HeapTest0011::testGC0002));
    addTest(new TestCaller<HeapTest0011>
            ("testGC0003",
             &HeapTest0011::testGC0003));
    addTest(new TestCaller<HeapTest0011>
            ("testGC0004",
             &HeapTest0011::testGC0004));
    addTest(new TestCaller<HeapTest0011>
            ("testGC0005",
             &HeapTest0011::testGC0005));
}

///////////////////////////////////////////////////////////////////////////////

}
