// VirtualMachineTest0006
// jp_ac_jaist_iml_runtime

/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: VirtualMachineTest0006.cc,v 1.2 2005/09/30 01:03:03 kiyoshiy Exp $
 */
#include "SystemDef.hh"
#include "VirtualMachineTest0006.hh"
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
VirtualMachineTest0006::setUp()
{
    // setup facades
}

void
VirtualMachineTest0006::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const int TESTEXCEPTION0001_HEAPSIZE = 1024;
const int TESTEXCEPTION0001_STACKSIZE = 1024;
const SInt32Value TESTEXCEPTION0001_EXPECTEDRESULT = 10;

void
VirtualMachineTest0006::testException0001()
{
    Heap heap(TESTEXCEPTION0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(1, 1); // pointer = 1, atoms = 1

    UInt32Value code[100];
    UInt32Value offset = 0;

    // no Raise, one handler
    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(PushHandler, 0); // handler(v0, f)
    UInt32Value pushHandlerOffset = offset;
    code[offset++] = 0; // handler address, to be filled later
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(PopHandler, 0);// pop handler
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);// exit
    UInt32Value exitOffset = offset;
    code[pushHandlerOffset] = (UInt32Value)&(code[offset]);// handler f
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);

    Executable *executable = buildExecutable(sizeof(code)/sizeof(code[0]), code);

    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);

    VirtualMachine::execute(executable);

    // verify the machine registers
    assertLongsEqual(exitOffset, afterMonitor.PC_ - beforeMonitor.PC_);
    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    assertLongsEqual(funInfo.getFrameSize(), 
                     beforeMonitor.SP_ - afterMonitor.SP_ );
//    assertLongsEqual(TESTEXCEPTION0001_EXPECTEDRESULT,
//                     *(afterMonitor.SP_ + funInfo.getAtomEntry(0)));
}

////////////////////////////////////////

const int TESTEXCEPTION0002_HEAPSIZE = 1024;
const int TESTEXCEPTION0002_STACKSIZE = 1024;
const SInt32Value TESTEXCEPTION0002_EXCEPTIONVALUE = 10;

void
VirtualMachineTest0006::testException0002()
{
    Heap heap(TESTEXCEPTION0002_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(2, 1); // pointer = 2, atoms = 1

    UInt32Value code[100];
    UInt32Value offset = 0;

    // no Raise, one handler
    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// v0 = ...
    code[offset++] = TESTEXCEPTION0002_EXCEPTIONVALUE;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);// p1 = {}
    code[offset++] = funInfo.getAtomEntry(0);// bitmap
    code[offset++] = 0;// count
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(Raise, 0); // raise p1
    code[offset++] = funInfo.getPointerEntry(1);
    UInt32Value raiseOffset = offset;
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);// exit
    UInt32Value exitOffset = offset;

    Executable *executable = buildExecutable(sizeof(code)/sizeof(code[0]), code);

    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);

    try{
        VirtualMachine::execute(executable);
        fail("exception should be raised.");
    }
    catch(UserException& e){
        // verify the machine registers
        assertLongsEqual(raiseOffset, afterMonitor.PC_ - beforeMonitor.PC_);
        assertLongsEqual((long)(beforeMonitor.ENV_),
                         (long)(afterMonitor.ENV_));
        assertLongsEqual(funInfo.getFrameSize(), 
                         beforeMonitor.SP_ - afterMonitor.SP_ );
//    assertLongsEqual(TESTEXCEPTION0002_EXPECTEDRESULT,
//                     *(afterMonitor.SP_ + funInfo.getAtomEntry(0)));
    }

}

////////////////////////////////////////

const int TESTEXCEPTION0003_HEAPSIZE = 1024;
const int TESTEXCEPTION0003_STACKSIZE = 1024;
const SInt32Value TESTEXCEPTION0003_EXCEPTIONVALUE = 10;

void
VirtualMachineTest0006::testException0003()
{
    Heap heap(TESTEXCEPTION0003_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(3, 2); // pointer = 3, atoms = 2

    UInt32Value code[100];
    UInt32Value offset = 0;

    // no Raise, one handler
    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(PushHandler, 0); // handler(p1, f)
    UInt32Value pushHandlerOffset = offset;
    code[offset++] = 0; // handler address, to be filled later
    code[offset++] = funInfo.getPointerEntry(1);

    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// v0 = 0 (bitmap)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);

    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// v1 = ...
    code[offset++] = TESTEXCEPTION0003_EXCEPTIONVALUE;
    code[offset++] = funInfo.getAtomEntry(1);

    // p2 = {v0: v1}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
    code[offset++] = funInfo.getAtomEntry(0);// bitmap
    code[offset++] = 1;// count
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getPointerEntry(2);

    code[offset++] = EMBED_INSTRUCTION_3(Raise, 0); // raise p2
    code[offset++] = funInfo.getPointerEntry(2);

    code[offset++] = EMBED_INSTRUCTION_3(PopHandler, 0);// pop handler
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);// exit

    code[pushHandlerOffset] = (UInt32Value)&(code[offset]);// handler f
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);
    UInt32Value exitOffset = offset;

    Executable *executable = buildExecutable(sizeof(code)/sizeof(code[0]), code);

    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);

    VirtualMachine::execute(executable);

    // verify the machine registers
    assertLongsEqual(exitOffset, afterMonitor.PC_ - beforeMonitor.PC_);
    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    assertLongsEqual(funInfo.getFrameSize(), 
                     beforeMonitor.SP_ - afterMonitor.SP_ );
    assertLongsEqual(TESTEXCEPTION0003_EXCEPTIONVALUE,
                     ((UInt32Value*)
                     *(afterMonitor.SP_ + funInfo.getPointerEntry(1)))[0]);
}

////////////////////////////////////////

const int TESTEXCEPTION0004_HEAPSIZE = 1024;
const int TESTEXCEPTION0004_STACKSIZE = 1024;
const SInt32Value TESTEXCEPTION0004_EXCEPTIONVALUE1 = 10;
const SInt32Value TESTEXCEPTION0004_EXCEPTIONVALUE2 = ~10;

void
VirtualMachineTest0006::testException0004()
{
    Heap heap(TESTEXCEPTION0004_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(3, 2); // pointer = 3, atoms = 2

    UInt32Value code[100];
    UInt32Value offset = 0;

    // no Raise, one handler
    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(PushHandler, 0); // handler(p1, f)
    UInt32Value pushHandlerOffset = offset;
    code[offset++] = 0; // handler address, to be filled later
    code[offset++] = funInfo.getPointerEntry(1);

    // raise first exception
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// v0 = 0 (bitmap)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);

    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// v1 = ...
    code[offset++] = TESTEXCEPTION0004_EXCEPTIONVALUE1;
    code[offset++] = funInfo.getAtomEntry(1);

    // p2 = {v0: v1}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
    code[offset++] = funInfo.getAtomEntry(0);// bitmap
    code[offset++] = 1;// count
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getPointerEntry(2);

    code[offset++] = EMBED_INSTRUCTION_3(Raise, 0); // raise p2
    code[offset++] = funInfo.getPointerEntry(2);

    code[offset++] = EMBED_INSTRUCTION_3(PopHandler, 0);// pop handler
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);// exit

    code[pushHandlerOffset] = (UInt32Value)&(code[offset]);// handler f
    // raise second exception
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// v1 = ...
    code[offset++] = TESTEXCEPTION0004_EXCEPTIONVALUE2;
    code[offset++] = funInfo.getAtomEntry(1);

    // p2 = {v0: v1}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
    code[offset++] = funInfo.getAtomEntry(0);// bitmap
    code[offset++] = 1;// count
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getPointerEntry(2);

    code[offset++] = EMBED_INSTRUCTION_3(Raise, 0); // raise p2
    code[offset++] = funInfo.getPointerEntry(2);
    UInt32Value raiseOffset = offset;
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);// exit handler
    UInt32Value exitOffset = offset;

    Executable *executable = buildExecutable(sizeof(code)/sizeof(code[0]), code);

    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);

    try{
        VirtualMachine::execute(executable);
        fail("exception should be raised.");
    }
    catch(IMLException &e)
    {
        // verify the machine registers
        assertLongsEqual(raiseOffset, afterMonitor.PC_ - beforeMonitor.PC_);
        assertLongsEqual((long)(beforeMonitor.ENV_),
                         (long)(afterMonitor.ENV_));
        assertLongsEqual(funInfo.getFrameSize(), 
                         beforeMonitor.SP_ - afterMonitor.SP_ );
//        assertLongsEqual(TESTEXCEPTION0004_EXCEPTIONVALUE2,
//                         *(afterMonitor.SP_ + funInfo.getPointerEntry(1)));
    }
}

////////////////////////////////////////

const int TESTEXCEPTION0005_HEAPSIZE = 1024;
const int TESTEXCEPTION0005_STACKSIZE = 1024;
const SInt32Value TESTEXCEPTION0005_EXCEPTIONVALUE = 10;

void
VirtualMachineTest0006::testException0005()
{
    Heap heap(TESTEXCEPTION0005_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(3, 2); // pointer = 3, atoms = 2

    UInt32Value code[100];
    UInt32Value offset = 0;

    // no Raise, one handler
    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(PushHandler, 0); // handler(p1, f)
    UInt32Value pushHandlerOffset = offset;
    code[offset++] = 0; // handler address, to be filled later
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(PopHandler, 0);// pop handler

    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// v0 = 0 (bitmap)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);

    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// v1 = ...
    code[offset++] = TESTEXCEPTION0005_EXCEPTIONVALUE;
    code[offset++] = funInfo.getAtomEntry(1);

    // p2 = {v0: v1}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
    code[offset++] = funInfo.getAtomEntry(0);// bitmap
    code[offset++] = 1;// count
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getPointerEntry(2);

    code[offset++] = EMBED_INSTRUCTION_3(Raise, 0); // raise p2
    code[offset++] = funInfo.getPointerEntry(2);
    UInt32Value raiseOffset = offset;
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);// exit

    code[pushHandlerOffset] = (UInt32Value)&(code[offset]);// handler f
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);
    UInt32Value exitOffset = offset;

    Executable *executable = buildExecutable(sizeof(code)/sizeof(code[0]), code);

    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);

    try{
        VirtualMachine::execute(executable);
        fail("exception should be raised.");
    }
    catch(IMLException &e)
    {
        // verify the machine registers
        assertLongsEqual(raiseOffset, afterMonitor.PC_ - beforeMonitor.PC_);
        assertLongsEqual((long)(beforeMonitor.ENV_),
                         (long)(afterMonitor.ENV_));
        assertLongsEqual(funInfo.getFrameSize(), 
                         beforeMonitor.SP_ - afterMonitor.SP_ );
//        assertLongsEqual(TESTEXCEPTION0005_EXCEPTIONVALUE,
//                         *(afterMonitor.SP_ + funInfo.getAtomEntry(0)));
    }
}

///////////////////////////////////////////////////////////////////////////////

VirtualMachineTest0006::Suite::Suite()
{
    addTest(new TestCaller<VirtualMachineTest0006>
            ("testException0001",
             &VirtualMachineTest0006::testException0001));
    addTest(new TestCaller<VirtualMachineTest0006>
            ("testException0002",
             &VirtualMachineTest0006::testException0002));
    addTest(new TestCaller<VirtualMachineTest0006>
            ("testException0003",
             &VirtualMachineTest0006::testException0003));
    addTest(new TestCaller<VirtualMachineTest0006>
            ("testException0004",
             &VirtualMachineTest0006::testException0004));
    addTest(new TestCaller<VirtualMachineTest0006>
            ("testException0005",
             &VirtualMachineTest0006::testException0005));
}

///////////////////////////////////////////////////////////////////////////////

}
