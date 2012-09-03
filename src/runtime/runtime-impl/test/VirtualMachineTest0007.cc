// VirtualMachineTest0007
// jp_ac_jaist_iml_runtime

/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: VirtualMachineTest0007.cc,v 1.1 2005/09/29 16:45:14 kiyoshiy Exp $
 */
#include "SystemDef.hh"
#include "VirtualMachineTest0007.hh"
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
VirtualMachineTest0007::setUp()
{
    // setup facades
}

void
VirtualMachineTest0007::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

void
VirtualMachineTest0007::testFunEntry011Apply()
{
    UInt32Value pointerArgValues[] = {123};
    UInt32Value atomArgValues[] = {456};
    testApplyCommon(false, 1, pointerArgValues, 1, atomArgValues);
}

////////////////////////////////////////

void
VirtualMachineTest0007::testFunEntry011TailApply()
{
    UInt32Value pointerArgValues[] = {123};
    UInt32Value atomArgValues[] = {456};
    testApplyCommon(true, 1, pointerArgValues, 1, atomArgValues);
}

////////////////////////////////////////

void
VirtualMachineTest0007::testFunEntry011CallStatic()
{
    UInt32Value pointerArgValues[] = {123};
    UInt32Value atomArgValues[] = {456};
    testCallStaticCommon(false, 1, pointerArgValues, 1, atomArgValues);
}

////////////////////////////////////////

void
VirtualMachineTest0007::testFunEntry011TailCallStatic()
{
    UInt32Value pointerArgValues[] = {123};
    UInt32Value atomArgValues[] = {456};
    testCallStaticCommon(true, 1, pointerArgValues, 1, atomArgValues);
}

////////////////////////////////////////

void
VirtualMachineTest0007::testFunEntry022Apply()
{
    UInt32Value pointerArgValues[] = {123, 456};
    UInt32Value atomArgValues[] = {234, 567};
    testApplyCommon(false, 2, pointerArgValues, 2, atomArgValues);
}

////////////////////////////////////////

void
VirtualMachineTest0007::testFunEntry022TailApply()
{
    UInt32Value pointerArgValues[] = {123, 456};
    UInt32Value atomArgValues[] = {234, 567};
    testApplyCommon(true, 2, pointerArgValues, 2, atomArgValues);
}

////////////////////////////////////////

void
VirtualMachineTest0007::testFunEntry022CallStatic()
{
    UInt32Value pointerArgValues[] = {123, 456};
    UInt32Value atomArgValues[] = {234, 567};
    testCallStaticCommon(false, 2, pointerArgValues, 2, atomArgValues);
}

////////////////////////////////////////

void
VirtualMachineTest0007::testFunEntry022TailCallStatic()
{
    UInt32Value pointerArgValues[] = {123, 456};
    UInt32Value atomArgValues[] = {234, 567};
    testCallStaticCommon(true, 2, pointerArgValues, 2, atomArgValues);
}

////////////////////////////////////////

const int TESTAPPLYCOMMON_HEAPSIZE = 1024;
const int TESTAPPLYCOMMON_STACKSIZE = 1024;

void
VirtualMachineTest0007::
testApplyCommon(bool isTailCall,
                int pointerArgs,
                UInt32Value* pointerArgValues,
                int atomArgs,
                UInt32Value* atomArgValues)
{
    Heap heap(TESTAPPLYCOMMON_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    instruction callInstruction = isTailCall ? TailApply_S : Apply_S;

    UInt32Value arity = pointerArgs + atomArgs;
    UInt32Value argsDest[arity];

    FunInfo funInfo(3 + pointerArgs, 1 + atomArgs);
    FunInfo calleeFunInfo(arity,
                          argsDest,
                          0,
                          NULL,
                          0,
                          NULL,
                          pointerArgs + 1, // a slot for ENV
                          atomArgs,
                          0,
                          NULL);

    // pass atom args prior to pointer args.
    for(int index = 0; index < atomArgs; index += 1){
        argsDest[index] = calleeFunInfo.getAtomEntry(index);
    }
    for(int index = 0; index < pointerArgs; index += 1){
        // the first pointer slot is reserved for ENV.
        argsDest[atomArgs + index] = calleeFunInfo.getPointerEntry(index + 1);
    }

    UInt32Value code[200];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    //p1 = Block{v0,[]}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = 0;
    code[offset++] = funInfo.getPointerEntry(1);
    for(int index = 0; index < pointerArgs; index += 1){
        code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = expected 
        code[offset++] = pointerArgValues[index];
        code[offset++] = funInfo.getAtomEntry(1);
        //pi = Block{v0,[]}
        code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
        code[offset++] = funInfo.getAtomEntry(0);
        code[offset++] = 1;
        code[offset++] = funInfo.getAtomEntry(1);
        code[offset++] = funInfo.getPointerEntry(3 + index);// p3, p4, ...
    }
    for(int index = 0; index < atomArgs; index += 1){
        code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// vi = expected
        code[offset++] = atomArgValues[index];
        code[offset++] = funInfo.getAtomEntry(1 + index);// v1, v2, ...
    }
    code[offset++] = EMBED_INSTRUCTION_3(MakeClosure, 0);// p2 = Clos(f, p1)
    UInt32Value callerOffset = offset;
    code[offset++] = 0; // entry point of f, to be filled later
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = funInfo.getPointerEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(callInstruction, 0);// p3 = p2(vi,pj)
    code[offset++] = funInfo.getPointerEntry(2);
    code[offset++] = arity;
    for(int index = 0; index < atomArgs; index += 1){
        code[offset++] = funInfo.getAtomEntry(1 + index);// v1, v2, ...
    }
    for(int index = 0; index < pointerArgs; index += 1){
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
    for(int index = 0; index < atomArgs; index += 1){
        assertLongsEqual(atomArgValues[index],
                         *(afterMonitor.SP_ + argsDest[index]));
    }
    for(int index = 0; index < pointerArgs; index += 1){
        Cell* block = (Cell*)*(afterMonitor.SP_ + argsDest[atomArgs + index]);
        assertLongsEqual(pointerArgValues[index], block[0].uint32);
    }
}

////////////////////////////////////////

const int TESTCALLSTATICCOMMON_HEAPSIZE = 1024;
const int TESTCALLSTATICCOMMON_STACKSIZE = 1024;

void
VirtualMachineTest0007::
testCallStaticCommon(bool isTailCall,
                int pointerArgs,
                UInt32Value* pointerArgValues,
                int atomArgs,
                UInt32Value* atomArgValues)
{
    Heap heap(TESTCALLSTATICCOMMON_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    instruction callInstruction = isTailCall ? TailCallStatic_S : CallStatic_S;

    UInt32Value arity = pointerArgs + atomArgs;
    UInt32Value argsDest[arity];

    FunInfo funInfo(2 + pointerArgs, 1 + atomArgs);
    FunInfo calleeFunInfo(arity,
                          argsDest,
                          0,
                          NULL,
                          0,
                          NULL,
                          pointerArgs + 1, // a slot for ENV
                          atomArgs,
                          0,
                          NULL);

    // store arguments in reverse order of passed order.
    // And, pass atom args prior to pointer args.
    for(int index = 0; index < atomArgs; index += 1){
        argsDest[index] = calleeFunInfo.getAtomEntry(index);
    }
    for(int index = 0; index < pointerArgs; index += 1){
        // the first pointer slot is reserved for ENV.
        argsDest[atomArgs + index] = calleeFunInfo.getPointerEntry(index + 1);
    }

    UInt32Value code[200];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    //p1 = Block{v0,[]}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = 0;
    code[offset++] = funInfo.getPointerEntry(1);
    for(int index = 0; index < pointerArgs; index += 1){
        // v1 = expected 
        code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);
        code[offset++] = pointerArgValues[index];
        code[offset++] = funInfo.getAtomEntry(1);
        //pi = Blk{v0,[v1]}
        code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
        code[offset++] = funInfo.getAtomEntry(0);
        code[offset++] = 1;
        code[offset++] = funInfo.getAtomEntry(1);
        code[offset++] = funInfo.getPointerEntry(2 + index);// p2, p3, ...
    }
    for(int index = 0; index < atomArgs; index += 1){
        code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// vi = expected
        code[offset++] = atomArgValues[index];
        code[offset++] = funInfo.getAtomEntry(1 + index);// v1, v2, ...
    }
    code[offset++] = EMBED_INSTRUCTION_3(callInstruction, 0);//p2 = f(p1,vi,pj)
    UInt32Value callerOffset = offset;
    code[offset++] = 0; // entry point of f, to be filled later
    code[offset++] = arity + 1;// including ENV
    code[offset++] = funInfo.getPointerEntry(1);// ENV is first argument
    for(int index = 0; index < atomArgs; index += 1){
        code[offset++] = funInfo.getAtomEntry(1 + index);// v1, v2, ...
    }
    for(int index = 0; index < pointerArgs; index += 1){
        code[offset++] = funInfo.getPointerEntry(2 + index);// p2, p3, ...
    }
    if(false == isTailCall){
        code[offset++] = funInfo.getPointerEntry(2);// return slot(never used)
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
    for(int index = 0; index < atomArgs; index += 1){
        assertLongsEqual(atomArgValues[index],
                         *(afterMonitor.SP_ + argsDest[index]));
    }
    for(int index = 0; index < pointerArgs; index += 1){
        Cell* block = (Cell*)*(afterMonitor.SP_ + argsDest[atomArgs + index]);
        assertLongsEqual(pointerArgValues[index], block[0].uint32);
    }
}

///////////////////////////////////////////////////////////////////////////////

VirtualMachineTest0007::Suite::Suite()
{
    addTest(new TestCaller<VirtualMachineTest0007>
            ("testFunEntry011Apply",
             &VirtualMachineTest0007::testFunEntry011Apply));
    addTest(new TestCaller<VirtualMachineTest0007>
            ("testFunEntry011TailApply",
             &VirtualMachineTest0007::testFunEntry011TailApply));
    addTest(new TestCaller<VirtualMachineTest0007>
            ("testFunEntry011CallStatic",
             &VirtualMachineTest0007::testFunEntry011CallStatic));
    addTest(new TestCaller<VirtualMachineTest0007>
            ("testFunEntry011TailCallStatic",
             &VirtualMachineTest0007::testFunEntry011TailCallStatic));
    addTest(new TestCaller<VirtualMachineTest0007>
            ("testFunEntry022Apply",
             &VirtualMachineTest0007::testFunEntry022Apply));
    addTest(new TestCaller<VirtualMachineTest0007>
            ("testFunEntry022TailApply",
             &VirtualMachineTest0007::testFunEntry022TailApply));
    addTest(new TestCaller<VirtualMachineTest0007>
            ("testFunEntry022CallStatic",
             &VirtualMachineTest0007::testFunEntry022CallStatic));
    addTest(new TestCaller<VirtualMachineTest0007>
            ("testFunEntry022TailCallStatic",
             &VirtualMachineTest0007::testFunEntry022TailCallStatic));
}

///////////////////////////////////////////////////////////////////////////////

}
