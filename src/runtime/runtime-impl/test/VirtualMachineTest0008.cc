// VirtualMachineTest0008
// jp_ac_jaist_iml_runtime

/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: VirtualMachineTest0008.cc,v 1.2 2005/09/30 01:03:03 kiyoshiy Exp $
 */
#include "SystemDef.hh"
#include "VirtualMachineTest0008.hh"
#include "VirtualMachineTestUtil.hh"
#include "FixedHeapClient.hh"
#include "Heap.hh"
#include "VirtualMachine.hh"

#include "TestCaller.h"

#include <stdio.h>

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

void
VirtualMachineTest0008::setUp()
{
    // setup facades
}

void
VirtualMachineTest0008::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

void
VirtualMachineTest0008::testFunEntry0111Apply()
{
    UInt32Value recordArgValues[] = {123, 456};
    testApplyCommon(false, 1, 1, 1, recordArgValues);
}

////////////////////////////////////////

void
VirtualMachineTest0008::testFunEntry0111TailApply()
{
    UInt32Value recordArgValues[] = {123, 456};
    testApplyCommon(true, 1, 1, 1, recordArgValues);
}

////////////////////////////////////////

void
VirtualMachineTest0008::testFunEntry0111CallStatic()
{
    UInt32Value recordArgValues[] = {123, 456};
    testCallStaticCommon(false, 1, 1, 1, recordArgValues);
}

////////////////////////////////////////

void
VirtualMachineTest0008::testFunEntry0111TailCallStatic()
{
    UInt32Value recordArgValues[] = {123, 456};
    testCallStaticCommon(true, 1, 1, 1, recordArgValues);
}

////////////////////////////////////////

void
VirtualMachineTest0008::testFunEntry0212Apply()
{
    UInt32Value recordArgValues[] = {123, 456, 789, 012};
    testApplyCommon(false, 2, 1, 2, recordArgValues);
}

////////////////////////////////////////

void
VirtualMachineTest0008::testFunEntry0212TailApply()
{
    UInt32Value recordArgValues[] = {123, 456, 789, 012};
    testApplyCommon(true, 2, 1, 2, recordArgValues);
}

////////////////////////////////////////

void
VirtualMachineTest0008::testFunEntry0212CallStatic()
{
    UInt32Value recordArgValues[] = {123, 456, 789, 012};
    testCallStaticCommon(false, 2, 1, 2, recordArgValues);
}

////////////////////////////////////////

void
VirtualMachineTest0008::testFunEntry0212TailCallStatic()
{
    UInt32Value recordArgValues[] = {123, 456, 789, 012};
    testCallStaticCommon(true, 2, 1, 2, recordArgValues);
}

////////////////////////////////////////

const int TESTAPPLYCOMMON_HEAPSIZE = 1024;
const int TESTAPPLYCOMMON_STACKSIZE = 1024;

void
VirtualMachineTest0008::
testApplyCommon(bool isTailCall,
                int atomArgs,
                int freeVars,
                int recordArgs,
                UInt32Value* recordArgValues)
{
    Heap heap(TESTAPPLYCOMMON_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    instruction callInstruction = isTailCall ? TailApply_S : Apply_S;

    UInt32Value recordGroupsCount = atomArgs + freeVars;
    UInt32Value recordArgsCount = recordGroupsCount * recordArgs;
    UInt32Value recordGroups[recordGroupsCount];
    for(int index = 0; index < recordGroupsCount; index += 1){
        recordGroups[index] = recordArgs;
    }
    UInt32Value arity = atomArgs + recordArgsCount;
    UInt32Value bitmapvalsArgs[atomArgs];
    for(int index = 0; index < atomArgs; index += 1){
        bitmapvalsArgs[index] = index;// 1 for the first ENV argument
    }
    UInt32Value bitmapvalsFrees[freeVars];
    for(int index = 0; index < freeVars; index += 1){
        bitmapvalsFrees[index] = index;
    }
    UInt32Value argsDest[arity];

    FunInfo funInfo(3 + recordArgsCount + 1, 1 + recordGroupsCount + 1);
    FunInfo calleeFunInfo(arity,
                          argsDest,
                          atomArgs,
                          bitmapvalsArgs,
                          freeVars,
                          bitmapvalsFrees,
                          1, // a slot for ENV
                          atomArgs,
                          recordGroupsCount,
                          recordGroups);

    // pass atom args prior to pointer args.
    for(int index = 0; index < atomArgs; index += 1){
        argsDest[index] = calleeFunInfo.getAtomEntry(index);
    }
    for(int index = 0; index < recordArgsCount; index += 1){
        argsDest[atomArgs + index] = calleeFunInfo.getRecordEntry(index);
    }

    UInt32Value code[200];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    Bitmap bitmap = 0x1;
    // build ENV of free variables
    for(int index = 0; index < freeVars; index += 1){
        code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1,.. = 0b1 << i
        code[offset++] = 1;
        code[offset++] = funInfo.getAtomEntry(1 + index);
        bitmap <<= 1;
    }
    //p1 = Block{v0,[v1...]}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = freeVars;
    for(int index = 0; index < freeVars; index += 1){
        code[offset++] = funInfo.getAtomEntry(1 + index);
    }
    code[offset++] = funInfo.getPointerEntry(1);
    // store atom args used for bitmap
    for(int index = 0; index < atomArgs; index += 1){
        code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// vi = 0b1 << i
        code[offset++] = 1;
        code[offset++] = funInfo.getAtomEntry(1 + freeVars + index);// vi,...
        bitmap <<= 1;
    }
    // build record argument blocks
    for(int groupIndex = 0; groupIndex < recordGroupsCount; groupIndex += 1){
        for(int index = 0; index < recordArgs; index += 1){
            UInt32Value atomIndex =
            funInfo.getAtomEntry(1 + recordGroupsCount);// vtemp
            UInt32Value pointerIndex =
            funInfo.getPointerEntry(3 + (groupIndex * recordArgs) + index);
            code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = expected 
            code[offset++] = recordArgValues[index];
            code[offset++] = atomIndex;
            //pi = Blk
            code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
            code[offset++] = funInfo.getAtomEntry(0);
            code[offset++] = 1;
            code[offset++] = atomIndex;
            code[offset++] = pointerIndex;// p3, p4, ...
        }
    }
    // builda a closure
    code[offset++] = EMBED_INSTRUCTION_3(MakeClosure, 0);// p2 = Clos(f, p1)
    UInt32Value callerOffset = offset;
    code[offset++] = 0; // entry point of f, to be filled later
    code[offset++] = funInfo.getPointerEntry(1);// ENV
    code[offset++] = funInfo.getPointerEntry(2);
    // call the function
    code[offset++] = EMBED_INSTRUCTION_3(callInstruction, 0);// p3 = p2(vi,pj)
    code[offset++] = funInfo.getPointerEntry(2);
    code[offset++] = arity;
    for(int index = 0; index < atomArgs; index += 1){
        code[offset++] = funInfo.getAtomEntry(1 + freeVars + index);// vi,...
    }
    for(int index = 0; index < recordArgsCount; index += 1){
        code[offset++] = funInfo.getPointerEntry(3 + index);// p3, p4, ...
    }
    if(false == isTailCall){
        code[offset++] = funInfo.getPointerEntry(3);// return slot(never used)
    }
    code[callerOffset] = (UInt32Value)&code[offset];
    offset = calleeFunInfo.embedFunEntry(code, offset);// callee function F
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);// exit
    UInt32Value exitOffset = offset;

    Executable *executable = buildExecutable(sizeof(code)/sizeof(code[0]), code);

    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);

    VirtualMachine::execute(executable);

    // verify the machine registers
    assertLongsEqual(exitOffset, afterMonitor.PC_ - beforeMonitor.PC_);
    bitmap = (Bitmap)0;
    for(int index = 0; index < recordGroupsCount; index += 1){
        bitmap = (bitmap << 1) | 1;
    }
    assertLongsEqual(bitmap, FRAME_BITMAP(afterMonitor.SP_));
    for(int groupIndex = 0; groupIndex < recordGroupsCount; groupIndex += 1){
        for(int index = 0; index < recordArgs; index += 1){
            UInt32Value recordVarIndex =
            calleeFunInfo.getRecordEntry((groupIndex * recordArgs) + index);
            Cell* block = (Cell*)*(afterMonitor.SP_ + recordVarIndex);
            assertLongsEqual(recordArgValues[index], block[0].uint32);
        }
    }
}

////////////////////////////////////////

const int TESTCALLSTATICCOMMON_HEAPSIZE = 1024;
const int TESTCALLSTATICCOMMON_STACKSIZE = 1024;

void
VirtualMachineTest0008::
testCallStaticCommon(bool isTailCall,
                int atomArgs,
                int freeVars,
                int recordArgs,
                UInt32Value* recordArgValues)
{
    Heap heap(TESTCALLSTATICCOMMON_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    instruction callInstruction = isTailCall ? TailCallStatic_S : CallStatic_S;

    UInt32Value recordGroupsCount = atomArgs + freeVars;
    UInt32Value recordArgsCount = recordGroupsCount * recordArgs;
    UInt32Value recordGroups[recordGroupsCount];
    for(int index = 0; index < recordGroupsCount; index += 1){
        recordGroups[index] = recordArgs;
    }
    UInt32Value arity = atomArgs + recordArgsCount;
    UInt32Value bitmapvalsArgs[atomArgs];
    for(int index = 0; index < atomArgs; index += 1){
        bitmapvalsArgs[index] = index;// 1 for the first ENV argument
    }
    UInt32Value bitmapvalsFrees[freeVars];
    for(int index = 0; index < freeVars; index += 1){
        bitmapvalsFrees[index] = index;
    }
    UInt32Value argsDest[arity];

    FunInfo funInfo(3 + recordArgsCount + 1, 1 + recordGroupsCount + 1);
    FunInfo calleeFunInfo(arity,
                          argsDest,
                          atomArgs,
                          bitmapvalsArgs,
                          freeVars,
                          bitmapvalsFrees,
                          1, // a slot for ENV
                          atomArgs,
                          recordGroupsCount,
                          recordGroups);

    // pass atom args prior to pointer args.
    for(int index = 0; index < atomArgs; index += 1){
        argsDest[index] = calleeFunInfo.getAtomEntry(index);
    }
    for(int index = 0; index < recordArgsCount; index += 1){
        argsDest[atomArgs + index] = calleeFunInfo.getRecordEntry(index);
    }

    UInt32Value code[200];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    Bitmap bitmap = 0x1;
    // build ENV of free variables
    for(int index = 0; index < freeVars; index += 1){
        code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1,.. = 0b1 << i
        code[offset++] = 1;
        code[offset++] = funInfo.getAtomEntry(1 + index);
        bitmap <<= 1;
    }
    //p1 = Block{v0,[v1...]}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = freeVars;
    for(int index = 0; index < freeVars; index += 1){
        code[offset++] = funInfo.getAtomEntry(1 + index);
    }
    code[offset++] = funInfo.getPointerEntry(1);
    // store atom args used for bitmap
    for(int index = 0; index < atomArgs; index += 1){
        code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// vi = 0b1 << i
        code[offset++] = 1;
        code[offset++] = funInfo.getAtomEntry(1 + freeVars + index);// vi,...
        bitmap <<= 1;
    }
    // build record argument blocks
    for(int groupIndex = 0; groupIndex < recordGroupsCount; groupIndex += 1){
        for(int index = 0; index < recordArgs; index += 1){
            UInt32Value atomIndex =
            funInfo.getAtomEntry(1 + recordGroupsCount);// vtemp
            UInt32Value pointerIndex =
            funInfo.getPointerEntry(3 + (groupIndex * recordArgs) + index);
            code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = expected 
            code[offset++] = recordArgValues[index];
            code[offset++] = atomIndex;
            //pi = Blk
            code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
            code[offset++] = funInfo.getAtomEntry(0);
            code[offset++] = 1;
            code[offset++] = atomIndex;
            code[offset++] = pointerIndex;// p3, p4, ...
        }
    }
    // call the function
    code[offset++] = EMBED_INSTRUCTION_3(callInstruction, 0);// p3 = p2(vi,pj)
    UInt32Value callerOffset = offset;
    code[offset++] = 0;
    code[offset++] = arity + 1; // for ENV
    code[offset++] = funInfo.getPointerEntry(1);// ENV
    for(int index = 0; index < atomArgs; index += 1){
        code[offset++] = funInfo.getAtomEntry(1 + freeVars + index);// vi,...
    }
    for(int index = 0; index < recordArgsCount; index += 1){
        code[offset++] = funInfo.getPointerEntry(3 + index);// p3, p4, ...
    }
    if(false == isTailCall){
        code[offset++] = funInfo.getPointerEntry(3);// return slot(never used)
    }
    code[callerOffset] = (UInt32Value)&code[offset];
    offset = calleeFunInfo.embedFunEntry(code, offset);// callee function F
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);// exit
    UInt32Value exitOffset = offset;

    Executable *executable = buildExecutable(sizeof(code)/sizeof(code[0]), code);

    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);

    VirtualMachine::execute(executable);

    // verify the machine registers
    assertLongsEqual(exitOffset, afterMonitor.PC_ - beforeMonitor.PC_);
    bitmap = (Bitmap)0;
    for(int index = 0; index < recordGroupsCount; index += 1){
        bitmap = (bitmap << 1) | 1;
    }
    assertLongsEqual(bitmap, FRAME_BITMAP(afterMonitor.SP_));
    for(int groupIndex = 0; groupIndex < recordGroupsCount; groupIndex += 1){
        for(int index = 0; index < recordArgs; index += 1){
            UInt32Value recordVarIndex =
            calleeFunInfo.getRecordEntry((groupIndex * recordArgs) + index);
            Cell* block = (Cell*)*(afterMonitor.SP_ + recordVarIndex);
            assertLongsEqual(recordArgValues[index], block[0].uint32);
        }
    }
}

///////////////////////////////////////////////////////////////////////////////

VirtualMachineTest0008::Suite::Suite()
{
    addTest(new TestCaller<VirtualMachineTest0008>
            ("testFunEntry0111Apply",
             &VirtualMachineTest0008::testFunEntry0111Apply));
    addTest(new TestCaller<VirtualMachineTest0008>
            ("testFunEntry0111TailApply",
             &VirtualMachineTest0008::testFunEntry0111TailApply));
    addTest(new TestCaller<VirtualMachineTest0008>
            ("testFunEntry0111CallStatic",
             &VirtualMachineTest0008::testFunEntry0111CallStatic));
    addTest(new TestCaller<VirtualMachineTest0008>
            ("testFunEntry0111TailCallStatic",
             &VirtualMachineTest0008::testFunEntry0111TailCallStatic));
    addTest(new TestCaller<VirtualMachineTest0008>
            ("testFunEntry0212Apply",
             &VirtualMachineTest0008::testFunEntry0212Apply));
    addTest(new TestCaller<VirtualMachineTest0008>
            ("testFunEntry0212TailApply",
             &VirtualMachineTest0008::testFunEntry0212TailApply));
    addTest(new TestCaller<VirtualMachineTest0008>
            ("testFunEntry0212CallStatic",
             &VirtualMachineTest0008::testFunEntry0212CallStatic));
    addTest(new TestCaller<VirtualMachineTest0008>
            ("testFunEntry0212TailCallStatic",
             &VirtualMachineTest0008::testFunEntry0212TailCallStatic));
}

///////////////////////////////////////////////////////////////////////////////

}
