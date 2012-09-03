// VirtualMachineTest0004
// jp_ac_jaist_iml_runtime

#include "SystemDef.hh"
#include "VirtualMachineTest0004.hh"
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
VirtualMachineTest0004::setUp()
{
    // setup facades
}

void
VirtualMachineTest0004::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

void
VirtualMachineTest0004::testGC0001()
{
    testRecordCommon(0UL, 1, 1);
}

////////////////////////////////////////

void
VirtualMachineTest0004::testGC0002()
{
    testRecordCommon(1UL, 1, 1);
}

////////////////////////////////////////

void
VirtualMachineTest0004::testGC0003()
{
    testRecordCommon(0UL, 32, 1);
}

////////////////////////////////////////

void
VirtualMachineTest0004::testGC0004()
{
    testRecordCommon(0xF0F0F0FUL, 32, 1);
}

////////////////////////////////////////

void
VirtualMachineTest0004::testGC0005()
{
    testRecordCommon(0xFFFFFFFFUL, 32, 2);
}

////////////////////////////////////////

void
VirtualMachineTest0004::testGC0011()
{
    testRecordCommon(0UL, 1, 2);
}

////////////////////////////////////////

void
VirtualMachineTest0004::testGC0012()
{
    testRecordCommon(1UL, 1, 2);
}

////////////////////////////////////////

void
VirtualMachineTest0004::testGC0013()
{
    testRecordCommon(0UL, 32, 2);
}

////////////////////////////////////////

void
VirtualMachineTest0004::testGC0014()
{
    testRecordCommon(0xF0F0F0FUL, 32, 2);
}

////////////////////////////////////////

void
VirtualMachineTest0004::testGC0015()
{
    testRecordCommon(0xFFFFFFFFUL, 32, 2);
}

////////////////////////////////////////

const int TESTRECORDCOMMON_HEAPSIZE = 1024;
const int TESTRECORDCOMMON_STACKSIZE = 1024;

void
VirtualMachineTest0004::testRecordCommon(Bitmap bitmap,
                                         int recordGroupsCount,
                                         int recordArgs)
{
    Heap heap(TESTRECORDCOMMON_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    UInt32Value recordGroups[recordGroupsCount];
    for(int index = 0; index < recordGroupsCount; index += 1){
        recordGroups[index] = recordArgs;
    }
    UInt32Value bitmapvalsFrees[1];
    UInt32Value argsDest[1];

    FunInfo funInfo(3, 2);
    FunInfo calleeFunInfo(1, // arity
                          argsDest,
                          0, // bitmapvalsArgsCount
                          NULL,
                          1, // bitmapfreesCount
                          bitmapvalsFrees,
                          2, // pointers
                          2, // atoms
                          recordGroupsCount,
                          recordGroups);

    // pass atom args prior to pointer args.
    argsDest[0] = calleeFunInfo.getAtomEntry(0);
    // frame bitmap is in the first slot of the env block argument.
    bitmapvalsFrees[0] = 0;

    UInt32Value allocatedHeapSize = 0;

    UInt32Value code[500];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    // v0 = bitmap(0)
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    // v1 = passed bitmap (reused as the dummy argument)
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);
    code[offset++] = bitmap;
    code[offset++] = funInfo.getAtomEntry(1);
    // p1 = Blk(v0, [v1])
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = 1;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getPointerEntry(1);
    allocatedHeapSize += 0;// because unit block.
    // build ENV of free variables

    // call the function
    code[offset++] = EMBED_INSTRUCTION_3(CallStatic_S, 0);// p2 = f(p1,v1)
    UInt32Value callerOffset = offset;
    code[offset++] = 0;
    code[offset++] = 2;
    code[offset++] = funInfo.getPointerEntry(1);// ENV
    code[offset++] = funInfo.getAtomEntry(1);// dummy argument
    code[offset++] = funInfo.getPointerEntry(2);// return slot(never used)

    //////////
    code[callerOffset] = (UInt32Value)&code[offset];
    offset = calleeFunInfo.embedFunEntry(code, offset);// callee function F

    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);//v0 = 0
    code[offset++] = 0;
    code[offset++] = calleeFunInfo.getAtomEntry(0);
    for(int groupIndex = 0; groupIndex < recordGroupsCount; groupIndex += 1)
    {
        code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// expected value
        code[offset++] = groupIndex;
        code[offset++] = calleeFunInfo.getAtomEntry(1);
        for(int index = 0; index < recordArgs; index += 1){
            int recordEntry = ((groupIndex * recordArgs) + index);
            if(bitmap & (1UL << groupIndex)){
                //pi = Blk
                code[offset++] =
                EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
                code[offset++] = calleeFunInfo.getAtomEntry(0);
                code[offset++] = 1;
                code[offset++] = calleeFunInfo.getAtomEntry(1);
                code[offset++] = calleeFunInfo.getRecordEntry(recordEntry);
                allocatedHeapSize += 2;
            }
            else{
                //vi = expected
                code[offset++] = EMBED_INSTRUCTION_3(Access_S, 0);
                code[offset++] = calleeFunInfo.getAtomEntry(1);
                code[offset++] = calleeFunInfo.getRecordEntry(recordEntry);
            }
        }
    }
    // invoke GC
    UInt32Value size = TESTRECORDCOMMON_HEAPSIZE - allocatedHeapSize - 1;
    
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// v0 = bitmap
    code[offset++] = 0;
    code[offset++] = calleeFunInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// v1 = size
    code[offset++] = size;
    code[offset++] = calleeFunInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(MakeArray_S, 0);// p1 = Arr(v0,v1,v0)
    code[offset++] = calleeFunInfo.getAtomEntry(0);
    code[offset++] = calleeFunInfo.getAtomEntry(1);
    code[offset++] = calleeFunInfo.getAtomEntry(0);
    code[offset++] = calleeFunInfo.getPointerEntry(1);

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

    // verify the machine registers
    assertLongsEqual(exitOffset, afterMonitor.PC_ - beforeMonitor.PC_);

    // verify the contents of record blocks
    // expectd value equals to group index
    for(int groupIndex = 0; groupIndex < recordGroupsCount; groupIndex += 1)
    {
        if(bitmap & (1UL << groupIndex)){
            for(int index = 0; index < recordArgs; index += 1){
                UInt32Value recordVarIndex =
                calleeFunInfo.getRecordEntry
                ((groupIndex * recordArgs) + index);
                Cell* block = (Cell*)*(afterMonitor.SP_ + recordVarIndex);
                assertLongsEqual(groupIndex, block[0].uint32);
            }
        }
    }

}

///////////////////////////////////////////////////////////////////////////////

VirtualMachineTest0004::Suite::Suite()
{
    addTest(new TestCaller<VirtualMachineTest0004>
            ("testGC0001",
             &VirtualMachineTest0004::testGC0001));
    addTest(new TestCaller<VirtualMachineTest0004>
            ("testGC0002",
             &VirtualMachineTest0004::testGC0002));
    addTest(new TestCaller<VirtualMachineTest0004>
            ("testGC0003",
             &VirtualMachineTest0004::testGC0003));
    addTest(new TestCaller<VirtualMachineTest0004>
            ("testGC0004",
             &VirtualMachineTest0004::testGC0004));
    addTest(new TestCaller<VirtualMachineTest0004>
            ("testGC0005",
             &VirtualMachineTest0004::testGC0005));
    addTest(new TestCaller<VirtualMachineTest0004>
            ("testGC0011",
             &VirtualMachineTest0004::testGC0011));
    addTest(new TestCaller<VirtualMachineTest0004>
            ("testGC0012",
             &VirtualMachineTest0004::testGC0012));
    addTest(new TestCaller<VirtualMachineTest0004>
            ("testGC0013",
             &VirtualMachineTest0004::testGC0013));
    addTest(new TestCaller<VirtualMachineTest0004>
            ("testGC0014",
             &VirtualMachineTest0004::testGC0014));
    addTest(new TestCaller<VirtualMachineTest0004>
            ("testGC0015",
             &VirtualMachineTest0004::testGC0015));
}

///////////////////////////////////////////////////////////////////////////////

}
