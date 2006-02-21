// VirtualMachineTest0003
// jp_ac_jaist_iml_runtime

#include "SystemDef.hh"
#include "VirtualMachineTest0003.hh"
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
VirtualMachineTest0003::setUp()
{
    // setup facades
}

void
VirtualMachineTest0003::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const int TESTGC0001_HEAPSIZE = 10;
const int TESTGC0001_STACKSIZE = 1024;
const SInt32Value TESTGC0001_EXPECTED = -123;
const SInt32Value TESTGC0001_UNEXPECTED = 321;
const UInt32Value TESTGC0001_BLOCKSIZE = TESTGC0001_HEAPSIZE - 3;

void
VirtualMachineTest0003::testGC0001()
{
    Heap heap(TESTGC0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(3, 3); // pointer = 3, atoms = 3

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = blockSize
    code[offset++] = TESTGC0001_BLOCKSIZE;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v2 = expected
    code[offset++] = TESTGC0001_EXPECTED;
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(MakeArray_S, 0);// p1 = Arr{v0,v2}
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = funInfo.getPointerEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(Access_S, 0);// p1 = p0
    code[offset++] = funInfo.getPointerEntry(0);    
    code[offset++] = funInfo.getPointerEntry(1);

    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v2 = unexpected
    code[offset++] = TESTGC0001_UNEXPECTED;
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(MakeArray_S, 0);// p2= Arr{v0,v2}, GC
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = funInfo.getPointerEntry(2);

    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);// exit
    UInt32Value exitOffset = offset;

    Executable *executable = buildExecutable(sizeof(code)/sizeof(code[0]), code);

    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);

    GCCountHeapMonitor heapMonitor;
    Heap::addMonitor(&heapMonitor);

    VirtualMachine::execute(executable);

    // verify the machine registers
    assertLongsEqual(1, heapMonitor.minorGCCount_);
    assertLongsEqual(exitOffset, afterMonitor.PC_ - beforeMonitor.PC_);
    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    // verify that boxed global table holds valid pointers to blocks.
    assertLongsEqual(TESTGC0001_EXPECTED,
                     ((Cell*)*(afterMonitor.SP_ + funInfo.getPointerEntry(0)))
                     [0].sint32);
    assertLongsEqual(*(afterMonitor.SP_ + funInfo.getPointerEntry(0)),
                     *(afterMonitor.SP_ + funInfo.getPointerEntry(1)));
}

///////////////////////////////////////////////////////////////////////////////

VirtualMachineTest0003::Suite::Suite()
{
    addTest(new TestCaller<VirtualMachineTest0003>
            ("testGC0001",
             &VirtualMachineTest0003::testGC0001));
}

///////////////////////////////////////////////////////////////////////////////

}
