// VirtualMachineTest0005
// jp_ac_jaist_iml_runtime

#include "SystemDef.hh"
#include "VirtualMachineTest0005.hh"
#include "VirtualMachineTestUtil.hh"
#include "HeapTestUtil.hh"
#include "FixedHeapClient.hh"
#include "Heap.hh"
#include "VirtualMachine.hh"

#include "TestCaller.h"

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

void
VirtualMachineTest0005::setUp()
{
    // setup facades
}

void
VirtualMachineTest0005::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const int TESTGC0001_HEAPSIZE = 10;
const int TESTGC0001_STACKSIZE = 1024;
const UInt32Value TESTGC0001_ARRAYSIZE = TESTGC0001_HEAPSIZE - 3;
const UInt32Value TESTGC0001_EXPECTED1 = 0x12345678;
const UInt32Value TESTGC0001_EXPECTED2 = 0x12345678;

void
VirtualMachineTest0005::testGC0001()
{
    Heap heap(TESTGC0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(3, 2); // pointer = 3, atom = 2
    FunInfo callee1FunInfo(3, 3); // pointer = 3, atom = 3
    FunInfo callee2FunInfo(3, 2); // pointer = 3, atom = 2

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    //p1 = Blk{v0,[]}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = 0;
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(CallStatic_S, 0);// p2 = f(p1,p1)
    UInt32Value caller1Offset = offset;
    code[offset++] = 0; // entry point, to be filled later
    code[offset++] = 2;
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = funInfo.getPointerEntry(2);// return slot

    //////////
    code[caller1Offset] = (UInt32Value)&code[offset];
    offset = callee1FunInfo.embedFunEntry(code, offset);// callee function F

    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = callee1FunInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = size
    code[offset++] = TESTGC0001_ARRAYSIZE;
    code[offset++] = callee1FunInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v2 = initial value
    code[offset++] = TESTGC0001_EXPECTED1;
    code[offset++] = callee1FunInfo.getAtomEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(MakeArray_S, 0);// p1 = Arr(v0,v1,v2)
    code[offset++] = callee1FunInfo.getAtomEntry(0);
    code[offset++] = callee1FunInfo.getAtomEntry(1);
    code[offset++] = callee1FunInfo.getAtomEntry(2);
    code[offset++] = callee1FunInfo.getPointerEntry(1);

    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    //p2 = Blk{v0,[]}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
    code[offset++] = callee1FunInfo.getAtomEntry(0);
    code[offset++] = 0;
    code[offset++] = callee1FunInfo.getPointerEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(CallStatic_S, 0);// p2 = f(p2,p2)
    UInt32Value caller2Offset = offset;
    code[offset++] = 0; // entry point, to be filled later
    code[offset++] = 2;
    code[offset++] = callee1FunInfo.getPointerEntry(2);
    code[offset++] = callee1FunInfo.getPointerEntry(2);
    code[offset++] = callee1FunInfo.getPointerEntry(2);// return slot

    //////////
    code[caller2Offset] = (UInt32Value)&code[offset];
    offset = callee2FunInfo.embedFunEntry(code, offset);// callee function F

    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = callee2FunInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = size
    code[offset++] = TESTGC0001_ARRAYSIZE;
    code[offset++] = callee2FunInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v2 = initial value
    code[offset++] = TESTGC0001_EXPECTED2;
    code[offset++] = callee2FunInfo.getAtomEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(MakeArray_S, 0);// p1 = Arr(v0,v1,v2)
    code[offset++] = callee2FunInfo.getAtomEntry(0);
    code[offset++] = callee2FunInfo.getAtomEntry(1);
    code[offset++] = callee2FunInfo.getAtomEntry(2);
    code[offset++] = callee2FunInfo.getPointerEntry(1);

    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);// exit
    UInt32Value exitOffset = offset;
    //////////

    Executable *executable = buildExecutable(sizeof(code)/sizeof(code[0]), code);

    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);

    VirtualMachine::execute(executable);

    // verify the machine registers
    assertLongsEqual(exitOffset, afterMonitor.PC_ - beforeMonitor.PC_);
    // both of caller's frame and callee's frame remain
    assertLongsEqual(funInfo.getFrameSize()
                     + callee1FunInfo.getFrameSize()
                     + callee2FunInfo.getFrameSize(),
                     beforeMonitor.SP_ - afterMonitor.SP_);
    Cell* blockInCallee1 = 
    (Cell*)(*(afterMonitor.SP_
              + callee2FunInfo.getFrameSize()
              + callee1FunInfo.getPointerEntry(1)));
    assertLongsEqual(TESTGC0001_EXPECTED1, blockInCallee1[0].uint32);
    Cell* blockInCallee2 = 
    (Cell*)(*(afterMonitor.SP_
              + callee2FunInfo.getPointerEntry(1)));
    assertLongsEqual(TESTGC0001_EXPECTED2, blockInCallee2[0].uint32);
}

///////////////////////////////////////////////////////////////////////////////

VirtualMachineTest0005::Suite::Suite()
{
    addTest(new TestCaller<VirtualMachineTest0005>
            ("testGC0001",
             &VirtualMachineTest0005::testGC0001));
}

///////////////////////////////////////////////////////////////////////////////

}
