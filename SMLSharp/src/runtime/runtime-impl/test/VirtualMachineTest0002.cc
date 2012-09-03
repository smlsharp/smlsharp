// VirtualMachineTest0002
// jp_ac_jaist_iml_runtime

#include "SystemDef.hh"
#include "VirtualMachineTest0002.hh"
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
VirtualMachineTest0002::setUp()
{
    // setup facades
}

void
VirtualMachineTest0002::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const int TESTGC0001_HEAPSIZE = 10;
const int TESTGC0001_STACKSIZE = 1024;
const UInt32Value TESTGC0001_ACVALUE = 0x12345678;
const UInt32Value TESTGC0001_BLOCKSIZE = TESTGC0001_HEAPSIZE - 3;

void
VirtualMachineTest0002::testGC0001()
{
    Heap heap(TESTGC0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(2, 2); // pointer = 2, atoms = 2

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = blockSize
    code[offset++] = TESTGC0001_BLOCKSIZE;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(MakeArray_S, 0);// p1 = Arr{v0,v1}
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getAtomEntry(1);// reuse for initial value
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(MakeArray_S, 0);// invoke GC
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);
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
    assertLongsEqual(exitOffset, afterMonitor.PC_ - beforeMonitor.PC_);
    assertLongsEqual(1, heapMonitor.minorGCCount_);
    assertLongsEqual(0, (long)afterMonitor.ENV_);
}

////////////////////////////////////////

const int TESTGC0002_HEAPSIZE = 10;
const int TESTGC0002_STACKSIZE = 1024;
const SInt32Value TESTGC0002_EXPECTED = -123;
const UInt32Value TESTGC0002_BLOCKSIZE = TESTGC0002_HEAPSIZE - 3;

void
VirtualMachineTest0002::testGC0002()
{
    Heap heap(TESTGC0002_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(5, 6); // pointer = 5, atoms = 6

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = blockSize
    code[offset++] = TESTGC0002_BLOCKSIZE;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v2 = expected
    code[offset++] = TESTGC0002_EXPECTED;
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(MakeArray_S, 0);// p1 = Arr{v0,v2}
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = funInfo.getPointerEntry(1);

    code[offset++] = EMBED_INSTRUCTION_3(SetGlobalBoxed, 0);// bg0 = p1
    code[offset++] = 0;
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(SetGlobalBoxed, 0);// bg2 = p1
    code[offset++] = 2;
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(SetGlobalBoxed, 0);// bg4 = p1
    code[offset++] = 4;
    code[offset++] = funInfo.getPointerEntry(1);

    code[offset++] = EMBED_INSTRUCTION_3(SetGlobalUnboxed, 0);// ug0 = v2
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(SetGlobalUnboxed, 0);// ug2 = v2
    code[offset++] = 2;
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(SetGlobalUnboxed, 4);// ug4 = v2
    code[offset++] = 4;
    code[offset++] = funInfo.getAtomEntry(2);

    code[offset++] = EMBED_INSTRUCTION_3(MakeArray_S, 0);// invoke GC
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = funInfo.getPointerEntry(1);

    code[offset++] = EMBED_INSTRUCTION_3(GetGlobalBoxed, 0);// p2 = bg0
    code[offset++] = 0;
    code[offset++] = funInfo.getPointerEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(GetGlobalBoxed, 0);// p3 = bg2
    code[offset++] = 2;
    code[offset++] = funInfo.getPointerEntry(3);
    code[offset++] = EMBED_INSTRUCTION_3(GetGlobalBoxed, 0);// p4 = bg4
    code[offset++] = 4;
    code[offset++] = funInfo.getPointerEntry(4);
    code[offset++] = EMBED_INSTRUCTION_3(GetGlobalUnboxed, 0);// v3 = ug0
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(3);
    code[offset++] = EMBED_INSTRUCTION_3(GetGlobalUnboxed, 0);// v4 = ug2
    code[offset++] = 2;
    code[offset++] = funInfo.getAtomEntry(4);
    code[offset++] = EMBED_INSTRUCTION_3(GetGlobalUnboxed, 0);// v5 = ug4
    code[offset++] = 4;
    code[offset++] = funInfo.getAtomEntry(5);
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
    assertLongsEqual(TESTGC0002_EXPECTED,
                     *(afterMonitor.SP_ + funInfo.getAtomEntry(3)));
    assertLongsEqual(TESTGC0002_EXPECTED,
                     *(afterMonitor.SP_ + funInfo.getAtomEntry(4)));
    assertLongsEqual(TESTGC0002_EXPECTED,
                     *(afterMonitor.SP_ + funInfo.getAtomEntry(5)));
    assertLongsEqual(TESTGC0002_EXPECTED,
                     ((Cell*)*(afterMonitor.SP_ + funInfo.getPointerEntry(2)))
                     [0].sint32);
    assertLongsEqual(*(afterMonitor.SP_ + funInfo.getPointerEntry(2)),
                     *(afterMonitor.SP_ + funInfo.getPointerEntry(3)));
    assertLongsEqual(*(afterMonitor.SP_ + funInfo.getPointerEntry(2)),
                     *(afterMonitor.SP_ + funInfo.getPointerEntry(4)));
}

///////////////////////////////////////////////////////////////////////////////

VirtualMachineTest0002::Suite::Suite()
{
    addTest(new TestCaller<VirtualMachineTest0002>
            ("testGC0001",
             &VirtualMachineTest0002::testGC0001));
    addTest(new TestCaller<VirtualMachineTest0002>
            ("testGC0002",
             &VirtualMachineTest0002::testGC0002));
}

///////////////////////////////////////////////////////////////////////////////

}
