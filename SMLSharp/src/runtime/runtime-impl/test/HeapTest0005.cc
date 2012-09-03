// HeapTest0005
// jp_ac_jaist_iml_runtime

#include "HeapTest0005.hh"
#include "FixedHeapClient.hh"
#include "Heap.hh"
#include "SystemDef.hh"

#include "TestCaller.h"

#include <stdio.h>

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

void
HeapTest0005::setUp()
{
    // setup facades
}

void
HeapTest0005::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const int TESTGETPAYLOAD0001_HEAP_SIZE = 1024;
const int TESTGETPAYLOAD0001_CELLS = 32;

void
HeapTest0005::testGetPayload0001()
{
    FixedHeapClient client = FixedHeapClient(NULL, 0);
    Heap heap =
    Heap(TESTGETPAYLOAD0001_HEAP_SIZE, &client);

    Cell* block = heap.allocAtomBlock(TESTGETPAYLOAD0001_CELLS);

    for(int cellIndex = 0;
        cellIndex < TESTGETPAYLOAD0001_CELLS;
        cellIndex += 1)
    {
        Cell value;
        value.sint32 = cellIndex * 10;
        heap.initializeField(block, cellIndex, value);
    }

    SInt32Value* payload = (SInt32Value*)(block);
    for(int cellIndex = 0;
        cellIndex < TESTGETPAYLOAD0001_CELLS;
        cellIndex += 1)
    {
        payload[cellIndex] = cellIndex;
    }

    for(int cellIndex = 0;
        cellIndex < TESTGETPAYLOAD0001_CELLS;
        cellIndex += 1)
    {
        assertLongsEqual(cellIndex, block[cellIndex].sint32);
    }
}


///////////////////////////////////////////////////////////////////////////////

HeapTest0005::Suite::Suite()
{
    addTest(new TestCaller<HeapTest0005>
            ("testGetPayload0001",
             &HeapTest0005::testGetPayload0001));
}

///////////////////////////////////////////////////////////////////////////////

}
