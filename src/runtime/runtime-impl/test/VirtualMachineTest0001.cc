// VirtualMachineTest0001
// jp_ac_jaist_iml_runtime

/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: VirtualMachineTest0001.cc,v 1.2 2005/09/30 01:03:03 kiyoshiy Exp $
 */
#include "SystemDef.hh"
#include "VirtualMachineTest0001.hh"
#include "VirtualMachineTestUtil.hh"
#include "FixedHeapClient.hh"
#include "Heap.hh"
#include "VirtualMachine.hh"

#include "TestCaller.h"

#include <stdio.h>
#include <string.h>

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

void
VirtualMachineTest0001::setUp()
{
    // setup facades
}

void
VirtualMachineTest0001::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const int TESTLOADINT0001_HEAPSIZE = 1024;
const int TESTLOADINT0001_STACKSIZE = 1024;
const SInt32Value TESTLOADINT0001_EXPECTEDRESULT = 10;

void
VirtualMachineTest0001::testLoadInt0001()
{
    Heap heap(TESTLOADINT0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(1, 1); // pointer = 1, atoms = 1

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0); // v0 = unexpected result
    code[offset++] = TESTLOADINT0001_EXPECTEDRESULT;
    code[offset++] = funInfo.getAtomEntry(0);
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
    assertLongsEqual(TESTLOADINT0001_EXPECTEDRESULT,
                     *(afterMonitor.SP_ + funInfo.getAtomEntry(0)));
}

////////////////////////////////////////

const int TESTLOADINT0002_HEAPSIZE = 1024;
const int TESTLOADINT0002_STACKSIZE = 1024;
const SInt32Value TESTLOADINT0002_EXPECTEDRESULT = -10;

void
VirtualMachineTest0001::testLoadInt0002()
{
    Heap heap(TESTLOADINT0002_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(1, 1); // pointer = 1, atoms = 1

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0); // v0 = unexpected result
    code[offset++] = TESTLOADINT0002_EXPECTEDRESULT;
    code[offset++] = funInfo.getAtomEntry(0);
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
    assertLongsEqual(TESTLOADINT0002_EXPECTEDRESULT,
                     *(afterMonitor.SP_ + funInfo.getAtomEntry(0)));
}

////////////////////////////////////////

const int TESTLOADWORD0001_HEAPSIZE = 1024;
const int TESTLOADWORD0001_STACKSIZE = 1024;
const UInt32Value TESTLOADWORD0001_EXPECTEDRESULT = 0x12345678;

void
VirtualMachineTest0001::testLoadWord0001()
{
    Heap heap(TESTLOADWORD0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(1, 1); // pointer = 1, atoms = 1

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = expected result
    code[offset++] = TESTLOADWORD0001_EXPECTEDRESULT;
    code[offset++] = funInfo.getAtomEntry(0);
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
    assertLongsEqual(TESTLOADWORD0001_EXPECTEDRESULT,
                     *(afterMonitor.SP_ + funInfo.getAtomEntry(0)));
}

////////////////////////////////////////

const int TESTLOADSTRING0001_HEAPSIZE = 1024;
const int TESTLOADSTRING0001_STACKSIZE = 1024;
const int TESTLOADSTRING0001_STRINGLENGTH = 10;
const ByteValue TESTLOADSTRING0001_STRING[] =
{
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 0, 0
};

void
VirtualMachineTest0001::testLoadString0001()
{
    Heap heap(TESTLOADSTRING0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(2, 0); // pointer = 2

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadString, 0); // v1 = string
    UInt32Value loadStringOffset = offset;
    code[offset++] = 0; // to be filled later.
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);
    UInt32Value exitOffset = offset;
    UInt32Value constStringOffset = offset;
    code[offset++] = EMBED_INSTRUCTION_3(ConstString, 0);
    code[offset++] = TESTLOADSTRING0001_STRINGLENGTH;
    code[offset++] = PACK_4BYTES_TO_WORD32(&TESTLOADSTRING0001_STRING[0]);
    code[offset++] = PACK_4BYTES_TO_WORD32(&TESTLOADSTRING0001_STRING[4]);
    code[offset++] = PACK_4BYTES_TO_WORD32(&TESTLOADSTRING0001_STRING[8]);

    code[loadStringOffset] = (UInt32Value)&(code[constStringOffset]);
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
    // the length of string is stored in the last field.
    Cell* stringBlock =
    (Cell*)(*(afterMonitor.SP_ + funInfo.getPointerEntry(1)));
    assertLongsEqual(TESTLOADSTRING0001_STRINGLENGTH, stringBlock[3].uint32);
    // string data is stored in first fields.
    ByteValue* block = (ByteValue*)(stringBlock);
    for(int index = 0 ; index < TESTLOADSTRING0001_STRINGLENGTH ; index += 1){
        assertLongsEqual(block[index],
                         TESTLOADSTRING0001_STRING[index]);
    }

}

////////////////////////////////////////

const int TESTLOADREAL0001_HEAPSIZE = 1024;
const int TESTLOADREAL0001_STACKSIZE = 1024;
const Real64Value TESTLOADREAL0001_REAL = 1.234;

void
VirtualMachineTest0001::testLoadReal0001()
{
    Heap heap(TESTLOADREAL0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    UInt32Value* realAddress = (UInt32Value*)&TESTLOADREAL0001_REAL;

    FunInfo funInfo(2, 2); // pointer = 2, atoms = 2

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadReal, 0);
    code[offset++] = realAddress[0];
    code[offset++] = realAddress[1];
    code[offset++] = funInfo.getAtomEntry(0);
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
    assertLongsEqual(realAddress[0],
                     *(afterMonitor.SP_ + funInfo.getAtomEntry(0)));
    assertLongsEqual(realAddress[1],
                     *(afterMonitor.SP_ + funInfo.getAtomEntry(1)));
}

////////////////////////////////////////

const int TESTLOADBOXEDREAL0001_HEAPSIZE = 1024;
const int TESTLOADBOXEDREAL0001_STACKSIZE = 1024;
const Real64Value TESTLOADBOXEDREAL0001_REAL = 1.234;

void
VirtualMachineTest0001::testLoadBoxedReal0001()
{
    Heap heap(TESTLOADBOXEDREAL0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    UInt32Value* realAddress = (UInt32Value*)&TESTLOADBOXEDREAL0001_REAL;

    FunInfo funInfo(2, 0); // pointer = 2

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadBoxedReal, 0);
    code[offset++] = realAddress[0];
    code[offset++] = realAddress[1];
    code[offset++] = funInfo.getPointerEntry(1);
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
    Cell* realBlock =
    (Cell*)(*(afterMonitor.SP_ + funInfo.getPointerEntry(1)));
    assertLongsEqual(realAddress[0], realBlock[0].uint32);
    assertLongsEqual(realAddress[1], realBlock[1].uint32);
}

////////////////////////////////////////

const int TESTLOADCHAR0001_HEAPSIZE = 1024;
const int TESTLOADCHAR0001_STACKSIZE = 1024;
const UInt32Value TESTLOADCHAR0001_EXPECTEDRESULT = 0x12345678;

void
VirtualMachineTest0001::testLoadChar0001()
{
    Heap heap(TESTLOADCHAR0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(1, 1); // pointer = 1, atoms = 1

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadChar, 0);// v0 = expected result
    code[offset++] = TESTLOADCHAR0001_EXPECTEDRESULT;
    code[offset++] = funInfo.getAtomEntry(0);
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
    assertLongsEqual(TESTLOADCHAR0001_EXPECTEDRESULT,
                     *(afterMonitor.SP_ + funInfo.getAtomEntry(0)));
}

////////////////////////////////////////

const int TESTACCESS0001_HEAPSIZE = 1024;
const int TESTACCESS0001_STACKSIZE = 1024;
const SInt32Value TESTACCESS0001_UNEXPECTEDRESULT = 1;
const SInt32Value TESTACCESS0001_EXPECTEDRESULT = -2;
const UInt32Value TESTACCESS0001_EXPECTEDSLOT = 0;
const UInt32Value TESTACCESS0001_UNEXPECTEDSLOT = 1;
const UInt32Value TESTACCESS0001_RESULTSLOT = 2;

void
VirtualMachineTest0001::testAccess0001()
{
    Heap heap(TESTACCESS0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(1, 3); // pointer = 1, atoms = 2

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0); // v0 = expected result
    code[offset++] = TESTACCESS0001_EXPECTEDRESULT;
    code[offset++] = funInfo.getAtomEntry(TESTACCESS0001_EXPECTEDSLOT);
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0); // v1 = unexpected result
    code[offset++] = TESTACCESS0001_UNEXPECTEDRESULT;
    code[offset++] = funInfo.getAtomEntry(TESTACCESS0001_UNEXPECTEDSLOT);
    code[offset++] = EMBED_INSTRUCTION_3(Access_S, 0); // v2 = v0
    code[offset++] = funInfo.getAtomEntry(TESTACCESS0001_EXPECTEDSLOT);
    code[offset++] = funInfo.getAtomEntry(TESTACCESS0001_RESULTSLOT);
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
    assertLongsEqual(TESTACCESS0001_EXPECTEDRESULT,
                     *(afterMonitor.SP_ +
                       funInfo.getAtomEntry(TESTACCESS0001_RESULTSLOT)));
}

////////////////////////////////////////

const int TESTACCESSENV0001_HEAPSIZE = 1024;
const int TESTACCESSENV0001_STACKSIZE = 1024;
const UInt32Value TESTACCESSENV0001_UNEXPECTEDRESULT = 0x654321;
const UInt32Value TESTACCESSENV0001_EXPECTEDRESULT = 0x123456;

void
VirtualMachineTest0001::testAccessEnv0001()
{
    Heap heap(TESTACCESSENV0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo callerFunInfo(1, 3); // pointer = 1, atoms = 3
    // NOTE: arity does not include passed ENV, which is the first argument.
    FunInfo calleeFunInfo(0, 1, 1);// arity = 0, pointer = 1 (ENV), atom = 1

    UInt32Value code[100];
    UInt32Value offset = 0;

    //////////
    offset = callerFunInfo.embedFunEntry(code, offset);

    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0); // v0 = unexpected result
    code[offset++] = TESTACCESSENV0001_UNEXPECTEDRESULT;
    code[offset++] = callerFunInfo.getAtomEntry(0);

    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0); // v1 = expected result
    code[offset++] = TESTACCESSENV0001_EXPECTEDRESULT;
    code[offset++] = callerFunInfo.getAtomEntry(1);

    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0); // v2 = bitmap
    code[offset++] = 0;
    code[offset++] = callerFunInfo.getAtomEntry(2);

    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);//make a ENV {v0,v1}
    code[offset++] = callerFunInfo.getAtomEntry(2);// bitmap = v2
    code[offset++] = 2; // fields count
    code[offset++] = callerFunInfo.getAtomEntry(0);
    code[offset++] = callerFunInfo.getAtomEntry(1);
    code[offset++] = callerFunInfo.getPointerEntry(0);

    code[offset++] = EMBED_INSTRUCTION_3(CallStatic_S, 0); // call(callee, ENV)
    UInt32Value callerOffset = offset;
    code[offset++] = 0; // entry point, to be filled later
    code[offset++] = 1; // args count
    code[offset++] = callerFunInfo.getPointerEntry(0);
    code[offset++] = callerFunInfo.getAtomEntry(2); // store result to v2

    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);
    UInt32Value exitOffset = offset;

    UInt32Value calleeOffset = offset;
    offset = calleeFunInfo.embedFunEntry(code, offset); // FunEntry

    code[offset++] = EMBED_INSTRUCTION_3(AccessEnv_S, 0); // get a free var
    code[offset++] = 1; // the index of fiels storing exepcted result
    code[offset++] = calleeFunInfo.getAtomEntry(0);

    code[offset++] = EMBED_INSTRUCTION_3(Return_S, 0);// return expected result
    code[offset++] = calleeFunInfo.getAtomEntry(0);
    //////////

    code[callerOffset] = (UInt32Value)&(code[calleeOffset]);
    Executable *executable = buildExecutable(sizeof(code)/sizeof(code[0]), code);

    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);

    VirtualMachine::execute(executable);

    // verify the machine registers
    assertLongsEqual(exitOffset, afterMonitor.PC_ - beforeMonitor.PC_);
//    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    assertLongsEqual(callerFunInfo.getFrameSize(), 
                     beforeMonitor.SP_ - afterMonitor.SP_ );
    // check v2 holds the expected value
    assertLongsEqual(TESTACCESSENV0001_EXPECTEDRESULT,
                     *(afterMonitor.SP_ + callerFunInfo.getAtomEntry(2)));
}

////////////////////////////////////////

const int TESTACCESSENVINDIRECT0001_HEAPSIZE = 1024;
const int TESTACCESSENVINDIRECT0001_STACKSIZE = 1024;
const UInt32Value TESTACCESSENVINDIRECT0001_UNEXPECTEDRESULT = 0x654321;
const UInt32Value TESTACCESSENVINDIRECT0001_EXPECTEDRESULT = 0x123456;

void
VirtualMachineTest0001::testAccessEnvIndirect0001()
{
    Heap heap(TESTACCESSENVINDIRECT0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo callerFunInfo(1, 4); // pointer = 1, atoms = 4
    // NOTE: arity does not include passed ENV, which is the first argument.
    FunInfo calleeFunInfo(0, 1, 1);// arity = 0, pointer = 1 (ENV), atom = 1

    UInt32Value code[100];
    UInt32Value offset = 0;

    //////////
    offset = callerFunInfo.embedFunEntry(code, offset);

    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0); // v0 = unexpected result
    code[offset++] = TESTACCESSENVINDIRECT0001_UNEXPECTEDRESULT;
    code[offset++] = callerFunInfo.getAtomEntry(0);

    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0); // v1 = expected result
    code[offset++] = TESTACCESSENVINDIRECT0001_EXPECTEDRESULT;
    code[offset++] = callerFunInfo.getAtomEntry(1);

    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0); // v2 = index of expected
    code[offset++] = 1;// the index of the field in ENV which stores v1
    code[offset++] = callerFunInfo.getAtomEntry(2);

    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0); // v2 = bitmap
    code[offset++] = 0;
    code[offset++] = callerFunInfo.getAtomEntry(3);

    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);//make a ENV {v0,v1,v2}
    code[offset++] = callerFunInfo.getAtomEntry(3);// bitmap = v3
    code[offset++] = 3; // fields count
    code[offset++] = callerFunInfo.getAtomEntry(0);
    code[offset++] = callerFunInfo.getAtomEntry(1);
    code[offset++] = callerFunInfo.getAtomEntry(2);
    code[offset++] = callerFunInfo.getPointerEntry(0);

    code[offset++] = EMBED_INSTRUCTION_3(CallStatic_S, 0); // call(callee, ENV)
    UInt32Value callerOffset = offset;
    code[offset++] = 0; // entry point, to be filled later
    code[offset++] = 1; // args count
    code[offset++] = callerFunInfo.getPointerEntry(0);
    code[offset++] = callerFunInfo.getAtomEntry(3); // store result to v3

    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);
    UInt32Value exitOffset = offset;

    UInt32Value calleeOffset = offset;
    offset = calleeFunInfo.embedFunEntry(code, offset); // FunEntry

    // get a free var
    code[offset++] = EMBED_INSTRUCTION_3(AccessEnvIndirect_S, 0);
    code[offset++] = 2; // the index of fiels storing the index of the exepcted result
    code[offset++] = calleeFunInfo.getAtomEntry(0);

    code[offset++] = EMBED_INSTRUCTION_3(Return_S, 0);// return expected result
    code[offset++] = calleeFunInfo.getAtomEntry(0);
    //////////

    code[callerOffset] = (UInt32Value)&(code[calleeOffset]);
    Executable *executable = buildExecutable(sizeof(code)/sizeof(code[0]), code);

    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);

    VirtualMachine::execute(executable);

    // verify the machine registers
    assertLongsEqual(exitOffset, afterMonitor.PC_ - beforeMonitor.PC_);
//    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    assertLongsEqual(callerFunInfo.getFrameSize(), 
                     beforeMonitor.SP_ - afterMonitor.SP_ );
    // check v3 holds the expected value
    assertLongsEqual(TESTACCESSENVINDIRECT0001_EXPECTEDRESULT,
                     *(afterMonitor.SP_ + callerFunInfo.getAtomEntry(3)));
}

////////////////////////////////////////

const int TESTGETFIELD0001_HEAPSIZE = 1024;
const int TESTGETFIELD0001_STACKSIZE = 1024;
const int TESTGETFIELD0001_EXPECTED = 0x123456;
const int TESTGETFIELD0001_UNEXPECTED = 0xFEDCBA;
const int TESTGETFIELD0001_BLOCKSIZE = 2;

void
VirtualMachineTest0001::testGetField0001()
{
    Heap heap(TESTGETFIELD0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(2, 4); // pointer = 2, atom = 4

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = expected
    code[offset++] = TESTGETFIELD0001_EXPECTED;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v2 = unexpected
    code[offset++] = TESTGETFIELD0001_UNEXPECTED;
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);//p1 = Block{v0,[v1,v2]}
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = TESTGETFIELD0001_BLOCKSIZE;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(GetField_S, 0);// v3 = p1[0]
    code[offset++] = 0;
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = funInfo.getAtomEntry(3);
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
    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    assertLongsEqual(funInfo.getFrameSize(), 
                     beforeMonitor.SP_ - afterMonitor.SP_ );

    assertLongsEqual(TESTGETFIELD0001_EXPECTED,
                     *(afterMonitor.SP_ + funInfo.getAtomEntry(3)));
}

////////////////////////////////////////

const int TESTGETFIELDINDIRECT0001_HEAPSIZE = 1024;
const int TESTGETFIELDINDIRECT0001_STACKSIZE = 1024;
const int TESTGETFIELDINDIRECT0001_EXPECTED = 0x123456;
const int TESTGETFIELDINDIRECT0001_UNEXPECTED = 0xFEDCBA;
const int TESTGETFIELDINDIRECT0001_BLOCKSIZE = 2;

void
VirtualMachineTest0001::testGetFieldIndirect0001()
{
    Heap heap(TESTGETFIELDINDIRECT0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(2, 5); // pointer = 2, atom = 5

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = unexpected
    code[offset++] = TESTGETFIELDINDIRECT0001_UNEXPECTED;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v2 = expected
    code[offset++] = TESTGETFIELDINDIRECT0001_EXPECTED;
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);//p1 = Block{v0,[v1,v2]}
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = TESTGETFIELDINDIRECT0001_BLOCKSIZE;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v3 = 1
    code[offset++] = 1;
    code[offset++] = funInfo.getAtomEntry(3);
    code[offset++] = EMBED_INSTRUCTION_3(GetFieldIndirect_S, 0);// v4 = p1[v3]
    code[offset++] = funInfo.getAtomEntry(3);
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = funInfo.getAtomEntry(4);
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
    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    assertLongsEqual(funInfo.getFrameSize(), 
                     beforeMonitor.SP_ - afterMonitor.SP_ );

    assertLongsEqual(TESTGETFIELDINDIRECT0001_EXPECTED,
                     *(afterMonitor.SP_ + funInfo.getAtomEntry(4)));
}

////////////////////////////////////////

const int TESTSETFIELD0001_HEAPSIZE = 1024;
const int TESTSETFIELD0001_STACKSIZE = 1024;
const int TESTSETFIELD0001_EXPECTED = 0x123456;
const int TESTSETFIELD0001_UNEXPECTED = 0xFEDCBA;
const int TESTSETFIELD0001_BLOCKSIZE = 2;

void
VirtualMachineTest0001::testSetField0001()
{
    Heap heap(TESTSETFIELD0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(2, 4); // pointer = 2, atom = 4

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = unexpected
    code[offset++] = TESTSETFIELD0001_UNEXPECTED;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v2 = unexpected
    code[offset++] = TESTSETFIELD0001_UNEXPECTED;
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);//p1 = Block{v0,[v1,v2]}
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = TESTSETFIELD0001_BLOCKSIZE;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v3 = expected
    code[offset++] = TESTSETFIELD0001_EXPECTED;
    code[offset++] = funInfo.getAtomEntry(3);
    code[offset++] = EMBED_INSTRUCTION_3(SetField_S, 0);// p1[1] = v3
    code[offset++] = 1;
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = funInfo.getAtomEntry(3);
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
    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    assertLongsEqual(funInfo.getFrameSize(), 
                     beforeMonitor.SP_ - afterMonitor.SP_ );

    Cell* blockRef = (Cell*)*(afterMonitor.SP_ + funInfo.getPointerEntry(1));
    assertLongsEqual(TESTSETFIELD0001_EXPECTED, (blockRef + 1)->uint32);
}

////////////////////////////////////////

const int TESTSETFIELDINDIRECT0001_HEAPSIZE = 1024;
const int TESTSETFIELDINDIRECT0001_STACKSIZE = 1024;
const int TESTSETFIELDINDIRECT0001_EXPECTED = 0x123456;
const int TESTSETFIELDINDIRECT0001_UNEXPECTED = 0xFEDCBA;
const int TESTSETFIELDINDIRECT0001_BLOCKSIZE = 2;

void
VirtualMachineTest0001::testSetFieldIndirect0001()
{
    Heap heap(TESTSETFIELDINDIRECT0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(2, 4); // pointer = 2, atom = 4

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = unexpected
    code[offset++] = TESTSETFIELDINDIRECT0001_UNEXPECTED;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v2 = unexpected
    code[offset++] = TESTSETFIELDINDIRECT0001_UNEXPECTED;
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);//p1 = Block{v0,[v1,v2]}
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = TESTSETFIELDINDIRECT0001_BLOCKSIZE;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v3 = expected
    code[offset++] = TESTSETFIELDINDIRECT0001_EXPECTED;
    code[offset++] = funInfo.getAtomEntry(3);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = 1
    code[offset++] = 1;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(SetFieldIndirect_S, 0);// p1[v0] = v3
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = funInfo.getAtomEntry(3);
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
    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    assertLongsEqual(funInfo.getFrameSize(), 
                     beforeMonitor.SP_ - afterMonitor.SP_ );

    Cell* blockRef = (Cell*)*(afterMonitor.SP_ + funInfo.getPointerEntry(1));
    assertLongsEqual(TESTSETFIELDINDIRECT0001_EXPECTED,
                     (blockRef + 1)->uint32);
}

////////////////////////////////////////

const int TESTCOPYBLOCK0001_HEAPSIZE = 1024;
const int TESTCOPYBLOCK0001_STACKSIZE = 1024;
const int TESTCOPYBLOCK0001_EXPECTED_SRC0 = 0x12345678;
const int TESTCOPYBLOCK0001_EXPECTED_SRC1 = 0x23456789;
const int TESTCOPYBLOCK0001_BLOCKSIZE = 2;

void
VirtualMachineTest0001::testCopyBlock0001()
{
    Heap heap(TESTCOPYBLOCK0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(3, 4); // pointer = 3, atom = 4

    UInt32Value code[100];
    UInt32Value offset = 0;

    // make a block of two fields, and copyAndUpdate its second field.
    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = expected src 0
    code[offset++] = TESTCOPYBLOCK0001_EXPECTED_SRC0;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v2 = expected src 1
    code[offset++] = TESTCOPYBLOCK0001_EXPECTED_SRC1;
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);//p1 = Block{v0,[v1,v2]}
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = TESTCOPYBLOCK0001_BLOCKSIZE;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = funInfo.getPointerEntry(1);
    // p2 = copy p1
    code[offset++] = EMBED_INSTRUCTION_3(CopyBlock, 0);
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = funInfo.getPointerEntry(2);
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
    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    assertLongsEqual(funInfo.getFrameSize(), 
                     beforeMonitor.SP_ - afterMonitor.SP_ );

    Cell* srcBlockRef =
    (Cell*)*(afterMonitor.SP_ + funInfo.getPointerEntry(1));
    Cell* destBlockRef =
    (Cell*)*(afterMonitor.SP_ + funInfo.getPointerEntry(2));
    // source block and dest block should be distinct from each other.
    assertLongsEqual(false, srcBlockRef == destBlockRef);
    // source block should be unchanged.
    assertLongsEqual(TESTCOPYBLOCK0001_EXPECTED_SRC0,
                     srcBlockRef->uint32);
    assertLongsEqual(TESTCOPYBLOCK0001_EXPECTED_SRC1,
                     (srcBlockRef + 1)->uint32);
    // dest block should be different only in the modified field.
    assertLongsEqual(TESTCOPYBLOCK0001_EXPECTED_SRC0,
                     destBlockRef->uint32);
    assertLongsEqual(TESTCOPYBLOCK0001_EXPECTED_SRC1,
                     (destBlockRef + 1)->uint32);
}

////////////////////////////////////////

const int TESTGETGLOBALBOXED0001_HEAPSIZE = 1024;
const int TESTGETGLOBALBOXED0001_STACKSIZE = 1024;
const int TESTGETGLOBALBOXED0001_GLOBAL_INDEX = 1;
const int TESTGETGLOBALBOXED0001_VALUE = 0x123456;
const int TESTGETGLOBALBOXED0001_UNEXPECTED = 0xFEDCBA;
const int TESTGETGLOBALBOXED0001_BLOCKSIZE = 1;

void
VirtualMachineTest0001::testGetGlobalBoxed0001()
{
    Heap heap(TESTGETGLOBALBOXED0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(3, 2); // pointer = 3, atom = 2

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// v0 = expected
    code[offset++] = TESTGETGLOBALBOXED0001_VALUE;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0); //p1 = Block{v1, [v0]}
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = TESTGETGLOBALBOXED0001_BLOCKSIZE;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(SetGlobalBoxed, 0);// addGlobal p1
    code[offset++] = TESTGETGLOBALBOXED0001_GLOBAL_INDEX;
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(GetGlobalBoxed, 0);// p2 = get global 
    code[offset++] = TESTGETGLOBALBOXED0001_GLOBAL_INDEX;
    code[offset++] = funInfo.getPointerEntry(2);
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
    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    assertLongsEqual(funInfo.getFrameSize(), 
                     beforeMonitor.SP_ - afterMonitor.SP_ );

    Cell* blockRef = (Cell*)(*(afterMonitor.SP_ + funInfo.getPointerEntry(2)));
    assertLongsEqual(TESTGETGLOBALBOXED0001_BLOCKSIZE,
                     Heap::getPayloadSize(blockRef));
    assertLongsEqual(TESTGETGLOBALBOXED0001_VALUE, blockRef->uint32);
}

////////////////////////////////////////

void
VirtualMachineTest0001::testSetGlobalBoxed0001()
{
    //  The test case for GetGlobalBoxed serves as the test for
    // SetGlobalBoxed.
}

////////////////////////////////////////

const int TESTGETGLOBALUNBOXED0001_HEAPSIZE = 1024;
const int TESTGETGLOBALUNBOXED0001_STACKSIZE = 1024;
const int TESTGETGLOBALUNBOXED0001_GLOBAL_INDEX = 1;
const int TESTGETGLOBALUNBOXED0001_VALUE = 0x123456;
const int TESTGETGLOBALUNBOXED0001_UNEXPECTED = 0xFEDCBA;

void
VirtualMachineTest0001::testGetGlobalUnboxed0001()
{
    Heap heap(TESTGETGLOBALUNBOXED0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(1, 2); // pointer = 1, atom = 2

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// v0 = expected
    code[offset++] = TESTGETGLOBALUNBOXED0001_VALUE;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(SetGlobalUnboxed, 0);// addGlobal v0
    code[offset++] = TESTGETGLOBALUNBOXED0001_GLOBAL_INDEX;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// v0 = unexpected
    code[offset++] = TESTGETGLOBALUNBOXED0001_UNEXPECTED;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(GetGlobalUnboxed, 0);// get global
    code[offset++] = TESTGETGLOBALUNBOXED0001_GLOBAL_INDEX;
    code[offset++] = funInfo.getAtomEntry(1);
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
    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    assertLongsEqual(funInfo.getFrameSize(), 
                     beforeMonitor.SP_ - afterMonitor.SP_ );
    assertLongsEqual(TESTGETGLOBALUNBOXED0001_VALUE,
                     *(afterMonitor.SP_ + funInfo.getAtomEntry(1)));

}

////////////////////////////////////////

void
VirtualMachineTest0001::testSetGlobalUnboxed0001()
{
    //  The test case for GetGlobalUnboxed serves as the test for
    // SetGlobalUnboxed.
}

////////////////////////////////////////

const int TESTGETENV0001_HEAPSIZE = 1024;
const int TESTGETENV0001_STACKSIZE = 1024;
const int TESTGETENV0001_EXPECTED0 = 0x12345678;
const int TESTGETENV0001_EXPECTED1 = 0xFEDCBA09;
const int TESTGETENV0001_BLOCKSIZE = 2;

void
VirtualMachineTest0001::testGetEnv0001()
{
    Heap heap(TESTGETENV0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(3, 3); // pointer = 3, atom = 3
    FunInfo calleeFunInfo(2, 0); // pointer = 2, atom = 0

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = expected0
    code[offset++] = TESTGETENV0001_EXPECTED0;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v2 = expected1
    code[offset++] = TESTGETENV0001_EXPECTED1;
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);//p1 = Block{v0,[v1,v2]}
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = TESTGETENV0001_BLOCKSIZE;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(CallStatic_S, 0);// p2 = f(p1)
    UInt32Value callerOffset = offset;
    code[offset++] = 0; // entry point, to be filled later
    code[offset++] = 1;
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = funInfo.getPointerEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);// exit
    UInt32Value exitOffset = offset;
    UInt32Value calleeOffset = offset;
    offset = calleeFunInfo.embedFunEntry(code, offset);// callee function F
    code[offset++] = EMBED_INSTRUCTION_3(GetEnv, 0);// p1 = ENV
    code[offset++] = calleeFunInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(Return_S, 0);// return p1
    code[offset++] = calleeFunInfo.getPointerEntry(1);

    code[callerOffset] = (UInt32Value)&code[calleeOffset];
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

    Cell* srcEnv = (Cell*)*(afterMonitor.SP_ + funInfo.getPointerEntry(1));
    Cell* destEnv = (Cell*)*(afterMonitor.SP_ + funInfo.getPointerEntry(2));
    assertLongsEqual((UInt32Value)srcEnv, (UInt32Value)destEnv);
//    assertLongsEqual(TESTGETENV0001_EXPECTED0,
//                     *(afterMonitor.SP_ + funInfo.getAtomEntry(3)));
}

////////////////////////////////////////

void
VirtualMachineTest0001::testCallPrim0001()
{
    fail("not implemented.", __LINE__, __FILE__);
}

////////////////////////////////////////

void
VirtualMachineTest0001::testApply0001()
{
    testApplyCommon0001(false);
}

////////////////////////////////////////

void
VirtualMachineTest0001::testTailApply0001()
{
    testApplyCommon0001(true);
}

////////////////////////////////////////

void
VirtualMachineTest0001::testCallStatic0001()
{
    testCallStaticCommon0001(false);
}

////////////////////////////////////////

void
VirtualMachineTest0001::testTailCallStatic0001()
{
    testCallStaticCommon0001(true);
}

////////////////////////////////////////

const int TESTAPPLYCOMMON0001_HEAPSIZE = 1024;
const int TESTAPPLYCOMMON0001_STACKSIZE = 1024;
const UInt32Value TESTAPPLYCOMMON0001_ENVVALUE0 = 0x12345678;
const UInt32Value TESTAPPLYCOMMON0001_ARGVALUE0 = 0x23456789;

void
VirtualMachineTest0001::testApplyCommon0001(bool isTailCall)
{
    Heap heap(TESTAPPLYCOMMON0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    instruction callInstruction = isTailCall ? TailApply_S : Apply_S;

    FunInfo funInfo(3, 3); // pointer = 4, atom = 3
    FunInfo calleeFunInfo(1, 0); // pointer = 1, atom = 0

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = expected free var
    code[offset++] = TESTAPPLYCOMMON0001_ENVVALUE0;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);//p1 = Block{v0,[v1]}
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = 1;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v2 = expected arg
    code[offset++] = TESTAPPLYCOMMON0001_ARGVALUE0;
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(MakeClosure, 0);// p2 = Clos(f, p1)
    UInt32Value callerOffset = offset;
    code[offset++] = 0; // entry point of f, to be filled later
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = funInfo.getPointerEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(callInstruction, 0);// p3 = p2(v2)
    code[offset++] = funInfo.getPointerEntry(2);
    code[offset++] = 1;
    code[offset++] = funInfo.getAtomEntry(2);
    if(false == isTailCall){
        code[offset++] = funInfo.getPointerEntry(3);// return slot
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
    // passed should be set to the ENV for callee function.
    assertLongsEqual(TESTAPPLYCOMMON0001_ENVVALUE0,
                     afterMonitor.ENV_[0].uint32);
    if(isTailCall)
    {
        // caller's frame are replaced by callee's frame
        assertLongsEqual(calleeFunInfo.getFrameSize(), 
                         beforeMonitor.SP_ - afterMonitor.SP_);
    }
    else{
        // both of caller's frame and callee's frame remain
        assertLongsEqual(funInfo.getFrameSize()
                         + calleeFunInfo.getFrameSize(), 
                         beforeMonitor.SP_ - afterMonitor.SP_);
    }
}

////////////////////////////////////////

const int TESTCALLSTATICCOMMON0001_HEAPSIZE = 1024;
const int TESTCALLSTATICCOMMON0001_STACKSIZE = 1024;
const UInt32Value TESTCALLSTATICCOMMON0001_ENVVALUE0 = 0x12345678;

void
VirtualMachineTest0001::testCallStaticCommon0001(bool isTailCall)
{
    Heap heap(TESTCALLSTATICCOMMON0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    instruction callInstruction = isTailCall ? TailCallStatic_S : CallStatic_S;

    FunInfo funInfo(3, 2); // pointer = 3, atom = 2
    FunInfo calleeFunInfo(1, 0); // pointer = 1, atom = 0

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = expected free var
    code[offset++] = TESTCALLSTATICCOMMON0001_ENVVALUE0;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);//p1 = Block{v0,[v1]}
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = 1;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(callInstruction, 0);// p2 = f(p1)
    UInt32Value callerOffset = offset;
    code[offset++] = 0; // entry point, to be filled later
    code[offset++] = 1;
    code[offset++] = funInfo.getPointerEntry(1);
    if(false == isTailCall){
        code[offset++] = funInfo.getPointerEntry(2);// return slot
    }
    UInt32Value calleeOffset = offset;
    offset = calleeFunInfo.embedFunEntry(code, offset);// callee function F
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);// exit
    UInt32Value exitOffset = offset;

    code[callerOffset] = (UInt32Value)&code[calleeOffset];
    Executable *executable = buildExecutable(sizeof(code)/sizeof(code[0]), code);

    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);

    VirtualMachine::execute(executable);

    // verify the machine registers
    assertLongsEqual(exitOffset, afterMonitor.PC_ - beforeMonitor.PC_);
    // passed should be set to the ENV for callee function.
    assertLongsEqual(TESTCALLSTATICCOMMON0001_ENVVALUE0,
                     afterMonitor.ENV_[0].uint32);
    if(isTailCall)
    {
        // caller's frame are replaced by callee's frame
        assertLongsEqual(calleeFunInfo.getFrameSize(), 
                         beforeMonitor.SP_ - afterMonitor.SP_);
    }
    else{
        // both of caller's frame and callee's frame remain
        assertLongsEqual(funInfo.getFrameSize()
                         + calleeFunInfo.getFrameSize(), 
                         beforeMonitor.SP_ - afterMonitor.SP_);
    }
}

////////////////////////////////////////

const int TESTMAKEBLOCK0001_HEAPSIZE = 1024;
const int TESTMAKEBLOCK0001_STACKSIZE = 1024;
const Bitmap TESTMAKEBLOCK0001_BITMAP = 0x9;// 1001B
const int TESTMAKEBLOCK0001_SIZE = 4;
const int TESTMAKEBLOCK0001_FIELDS = 3;
const SInt32Value TESTMAKEBLOCK0001_EXPECTEDVAL1 = 0x123456;
const SInt32Value TESTMAKEBLOCK0001_EXPECTEDVAL2 = 0x345678;
const SInt32Value TESTMAKEBLOCK0001_EXPECTEDVAL3 = 0x56789A;
const SInt32Value TESTMAKEBLOCK0001_EXPECTEDVAL4 = 0x6789AB;
const SInt32Value TESTMAKEBLOCK0001_FIELDSIZE1 = 1;
const SInt32Value TESTMAKEBLOCK0001_FIELDSIZE2 = 2;
const SInt32Value TESTMAKEBLOCK0001_FIELDSIZE3 = 1;

void
VirtualMachineTest0001::testMakeBlock0001()
{
    Heap heap(TESTMAKEBLOCK0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(3, 6); // pointer = 3, atom = 6

    // make a hierarchy of three blocks.
    //   {
    //     bitmap = 101,
    //     size = 4,
    //     fields =
    //         [{0, [expected1]}, (expected2, expected3), {0, [expected4]}],
    //     fieldSizes = [1, 2, 1]
    //   }
    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    // v0 = bitmap(0)
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0); 
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);

    // v1 = expected 1
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);
    code[offset++] = TESTMAKEBLOCK0001_EXPECTEDVAL1;
    code[offset++] = funInfo.getAtomEntry(1);
    // p1 = block{v0, [v1]}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = 1;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getPointerEntry(1); 

    // v1 = expected 4
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);
    code[offset++] = TESTMAKEBLOCK0001_EXPECTEDVAL4;
    code[offset++] = funInfo.getAtomEntry(1);
    // p2 = block{v0, [v1]}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0); 
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = 1;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getPointerEntry(2); 

    // v2 = expected 2
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);
    code[offset++] = TESTMAKEBLOCK0001_EXPECTEDVAL2;
    code[offset++] = funInfo.getAtomEntry(2);
    // v3 = expected 3  (NOTE: assume v3 is the next slot to v2. *)
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);
    code[offset++] = TESTMAKEBLOCK0001_EXPECTEDVAL3;
    code[offset++] = funInfo.getAtomEntry(3);

    // v0 = bitmap(1001)
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0); 
    code[offset++] = TESTMAKEBLOCK0001_BITMAP;
    code[offset++] = funInfo.getAtomEntry(0);
    // v1 = size
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0); 
    code[offset++] = TESTMAKEBLOCK0001_SIZE;
    code[offset++] = funInfo.getAtomEntry(1);
    // v4 = fieldsize(1)
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0); 
    code[offset++] = 1;
    code[offset++] = funInfo.getAtomEntry(4);
    // v5 = fieldsize(2)
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0); 
    code[offset++] = 2;
    code[offset++] = funInfo.getAtomEntry(5);

    // p1 = {v0, v1, [p1, v2, p2], [v4, v5, v4]}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlock, 0);
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = TESTMAKEBLOCK0001_FIELDS;
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = funInfo.getPointerEntry(2);
    code[offset++] = funInfo.getAtomEntry(4);
    code[offset++] = funInfo.getAtomEntry(5);
    code[offset++] = funInfo.getAtomEntry(4);
    code[offset++] = funInfo.getPointerEntry(1);

    //exit
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

    Cell* blockRef = (Cell*)*(afterMonitor.SP_ + funInfo.getPointerEntry(1));
    assertLongsEqual(TESTMAKEBLOCK0001_SIZE,
                     Heap::getPayloadSize(blockRef));
    assertLongsEqual(TESTMAKEBLOCK0001_BITMAP,
                     Heap::getBitmap(blockRef));
    assertLongsEqual(TESTMAKEBLOCK0001_EXPECTEDVAL1,
                     blockRef->blockRef->sint32);
    assertLongsEqual(TESTMAKEBLOCK0001_EXPECTEDVAL2,
                     (blockRef + 1)->sint32);
    assertLongsEqual(TESTMAKEBLOCK0001_EXPECTEDVAL3,
                     (blockRef + 2)->sint32);
    assertLongsEqual(TESTMAKEBLOCK0001_EXPECTEDVAL4,
                     (blockRef + 3)->blockRef->sint32);
}

////////////////////////////////////////

const int TESTMAKEBLOCKOFSINGLEVALUES0001_HEAPSIZE = 1024;
const int TESTMAKEBLOCKOFSINGLEVALUES0001_STACKSIZE = 1024;
const Bitmap TESTMAKEBLOCKOFSINGLEVALUES0001_BITMAP = 0x5;// 101B
const int TESTMAKEBLOCKOFSINGLEVALUES0001_FIELDS = 3;
const SInt32Value TESTMAKEBLOCKOFSINGLEVALUES0001_EXPECTEDVAL1 = 0x123456;
const SInt32Value TESTMAKEBLOCKOFSINGLEVALUES0001_EXPECTEDVAL2 = 0x345678;
const SInt32Value TESTMAKEBLOCKOFSINGLEVALUES0001_EXPECTEDVAL3 = 0x56789A;

void
VirtualMachineTest0001::testMakeBlockOfSingleValues0001()
{
    Heap heap(TESTMAKEBLOCKOFSINGLEVALUES0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(3, 2); // pointer = 3, atom = 2

    // make a hierarchy of three blocks.
    //   {101, [{0, [expected1]}, expected2, {0, [expected3]}]}
    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    // v0 = bitmap(0)
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0); 
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    // v1 = expected 1
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);
    code[offset++] = TESTMAKEBLOCKOFSINGLEVALUES0001_EXPECTEDVAL1;
    code[offset++] = funInfo.getAtomEntry(1);
    // p1 = block{v0, [v1]}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = 1;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getPointerEntry(1); 
    // v1 = expected 3
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);
    code[offset++] = TESTMAKEBLOCKOFSINGLEVALUES0001_EXPECTEDVAL3;
    code[offset++] = funInfo.getAtomEntry(1);
    // p2 = block{v0, [v1]}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0); 
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = 1;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getPointerEntry(2); 
    // v1 = expected 2
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);
    code[offset++] = TESTMAKEBLOCKOFSINGLEVALUES0001_EXPECTEDVAL2;
    code[offset++] = funInfo.getAtomEntry(1);
    // v0 = bitmap(101)
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0); 
    code[offset++] = TESTMAKEBLOCKOFSINGLEVALUES0001_BITMAP;
    code[offset++] = funInfo.getAtomEntry(0);
    // p1 = {v0, [p1, v1, p2]}
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = TESTMAKEBLOCKOFSINGLEVALUES0001_FIELDS;
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getPointerEntry(2);
    code[offset++] = funInfo.getPointerEntry(1);
    //exit
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

    Cell* blockRef = (Cell*)*(afterMonitor.SP_ + funInfo.getPointerEntry(1));
    assertLongsEqual(TESTMAKEBLOCKOFSINGLEVALUES0001_FIELDS,
                     Heap::getPayloadSize(blockRef));
    assertLongsEqual(TESTMAKEBLOCKOFSINGLEVALUES0001_BITMAP,
                     Heap::getBitmap(blockRef));
    assertLongsEqual(TESTMAKEBLOCKOFSINGLEVALUES0001_EXPECTEDVAL1,
                     blockRef->blockRef->sint32);
    assertLongsEqual(TESTMAKEBLOCKOFSINGLEVALUES0001_EXPECTEDVAL2,
                     (blockRef + 1)->sint32);
    assertLongsEqual(TESTMAKEBLOCKOFSINGLEVALUES0001_EXPECTEDVAL3,
                     (blockRef + 2)->blockRef->sint32);
}

////////////////////////////////////////

const int TESTMAKEARRAY0001_HEAPSIZE = 1024;
const int TESTMAKEARRAY0001_STACKSIZE = 1024;
const UInt32Value TESTMAKEARRAY0001_BITMAP = 0;
const UInt32Value TESTMAKEARRAY0001_ARRAYSIZE = 3;
const UInt32Value TESTMAKEARRAY0001_EXPECTEDVAL = 0x12345678;

void
VirtualMachineTest0001::testMakeArray0001()
{
    Heap heap(TESTMAKEARRAY0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(2, 3); // pointer = 2, atom = 3

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0); // v0 = bitmap(0)
    code[offset++] = TESTMAKEARRAY0001_BITMAP;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// v1 = size
    code[offset++] = TESTMAKEARRAY0001_ARRAYSIZE;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);// v2 = expected 1
    code[offset++] = TESTMAKEARRAY0001_EXPECTEDVAL;
    code[offset++] = funInfo.getAtomEntry(2);
    // p1 = array{bitmap = v0, size = v1, value = v2}
    code[offset++] = EMBED_INSTRUCTION_3(MakeArray_S, 0);
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = funInfo.getPointerEntry(1); 
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);//exit
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

    Cell* blockRef = (Cell*)*(afterMonitor.SP_ + funInfo.getPointerEntry(1));
    assertLongsEqual(TESTMAKEARRAY0001_ARRAYSIZE,
                     Heap::getPayloadSize(blockRef));
    // array block has no bitmap tag. Shoud be returned 0 or 1 ?
//    assertLongsEqual(TESTMAKEARRAY0001_BITMAP, Heap::getBitmap(blockRef));
    for(int index = 0; index < TESTMAKEARRAY0001_ARRAYSIZE; index += 1){
        assertLongsEqual(TESTMAKEARRAY0001_EXPECTEDVAL,
                         (blockRef + index)->uint32);
    }
}

////////////////////////////////////////

const int TESTMAKECLOSURE0001_HEAPSIZE = 1024;
const int TESTMAKECLOSURE0001_STACKSIZE = 1024;
const int TESTMAKECLOSURE0001_EXPECTED = 0x123456;
const int TESTMAKECLOSURE0001_UNEXPECTED = 0xFEDCBA;
const int TESTMAKECLOSURE0001_BLOCKSIZE = 2;

void
VirtualMachineTest0001::testMakeClosure0001()
{
    Heap heap(TESTMAKECLOSURE0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(3, 3); // pointer = 3, atom = 3

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = bitmap(0)
    code[offset++] = 0;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v1 = expected
    code[offset++] = TESTMAKECLOSURE0001_EXPECTED;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v2 = unexpected
    code[offset++] = TESTMAKECLOSURE0001_UNEXPECTED;
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);//p1 = Block{v0,[v1,v2]}
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = TESTMAKECLOSURE0001_BLOCKSIZE;
    code[offset++] = funInfo.getAtomEntry(1);
    code[offset++] = funInfo.getAtomEntry(2);
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = EMBED_INSTRUCTION_3(MakeClosure, 0);// p2 = Clo(f, p1)
    UInt32Value makeClosureOperandOffset = offset;
    code[offset++] = 0; // entry point, to be filled later
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = funInfo.getPointerEntry(2);
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);// exit
    UInt32Value exitOffset = offset;
    UInt32Value entryPointOffset = offset;
    code[offset++] = EMBED_INSTRUCTION_3(Nop, 0);// dummy f

    code[makeClosureOperandOffset] = (UInt32Value)&(code[entryPointOffset]);

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
    Cell* closureRef = (Cell*)*(afterMonitor.SP_ + funInfo.getPointerEntry(2));
    Cell* envRef = (Cell*)*(afterMonitor.SP_ + funInfo.getPointerEntry(1));
    assertLongsEqual(2, Heap::getPayloadSize(closureRef));
    assertLongsEqual(entryPointOffset,
                     (UInt32Value*)(closureRef[0].uint32) - code);
    assertLongsEqual((UInt32Value)envRef,
                     (UInt32Value)(closureRef[1].blockRef));
}

////////////////////////////////////////

const int TESTSWITCHATOM_HEAPSIZE = 1024;
const int TESTSWITCHATOM_STACKSIZE = 1024;

void
VirtualMachineTest0001::
testSwitchAtom(const instruction switchInstruction,
               const UInt32Value casesCount,
               const UInt32Value* cases,
               const UInt32Value targetValue)
{
    Heap heap(TESTSWITCHATOM_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(1, 1); // pointer = 1, atoms = 1

    UInt32Value code[100];
    UInt32Value offset = 0;
    UInt32Value jumpSrcOffsets[casesCount];
    UInt32Value destinationOffsets[casesCount];
    UInt32Value exitOffsets[casesCount];
/*
    UInt32Value* jumpSrcOffsets = new UInt32Value[casesCount];
    UInt32Value* destinationOffsets = new UInt32Value[casesCount];
    UInt32Value* exitOffsets = new UInt32Value[casesCount];
*/

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0); // v0 = target value
    code[offset++] = targetValue;
    code[offset++] = funInfo.getAtomEntry(0);

    code[offset++] = EMBED_INSTRUCTION_3(switchInstruction, 0);
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = casesCount; // cases count
    
    for(int index = 0; index < casesCount; index += 1){
        code[offset++] = cases[index];
        jumpSrcOffsets[index] = offset;
        code[offset++] = 0; // destination address, to be filled later
    }
    UInt32Value jumpSrcOffsetDefault = offset;
    code[offset++] = 0; // destination address, to be filled later
    for(int index = 0; index < casesCount; index += 1){
        destinationOffsets[index] = offset;
        code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);
        exitOffsets[index] = offset;
    }
    // LD
    UInt32Value destinationOffsetDefault = offset;
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);
    UInt32Value exitOffsetDefault = offset;
    //////////

    for(int index = 0; index < casesCount; index += 1){
        code[jumpSrcOffsets[index]] =
        (UInt32Value)&(code[destinationOffsets[index]]);
    }
    code[jumpSrcOffsetDefault] =
    (UInt32Value)&(code[destinationOffsetDefault]);

    Executable *executable = buildExecutable(sizeof(code)/sizeof(code[0]), code);

    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);

    VirtualMachine::execute(executable);

    // verify the machine registers
    int matchCaseIndex = 0;
    for(; matchCaseIndex < casesCount; matchCaseIndex += 1){
        if(cases[matchCaseIndex] == targetValue){
            assertLongsEqual(exitOffsets[matchCaseIndex],
                             afterMonitor.PC_ - beforeMonitor.PC_);
            break;
        }
    }
    if(casesCount == matchCaseIndex){
        assertLongsEqual(exitOffsetDefault,
                         afterMonitor.PC_ - beforeMonitor.PC_);
    }
    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    assertLongsEqual(funInfo.getFrameSize(), 
                     beforeMonitor.SP_ - afterMonitor.SP_ );
}

////////////////////////////////////////

const UInt32Value TESTSWITCHINT0001_TARGETVALUE = 1;
const UInt32Value TESTSWITCHINT0001_CASESCOUNT = 3;
const UInt32Value TESTSWITCHINT0001_CASEVALUES[] = {~1, 0, 1};

void
VirtualMachineTest0001::testSwitchInt0001()
{
    testSwitchAtom(SwitchInt,
                   TESTSWITCHINT0001_CASESCOUNT,
                   TESTSWITCHINT0001_CASEVALUES,
                   TESTSWITCHINT0001_TARGETVALUE);
}

////////////////////////////////////////

const UInt32Value TESTSWITCHINT0002_TARGETVALUE = 2;
const UInt32Value TESTSWITCHINT0002_CASESCOUNT = 3;
const UInt32Value TESTSWITCHINT0002_CASEVALUES[] = {~1, 0, 1};

void
VirtualMachineTest0001::testSwitchInt0002()
{
    testSwitchAtom(SwitchInt,
                   TESTSWITCHINT0002_CASESCOUNT,
                   TESTSWITCHINT0002_CASEVALUES,
                   TESTSWITCHINT0002_TARGETVALUE);
}

////////////////////////////////////////

const UInt32Value TESTSWITCHWORD0001_TARGETVALUE = 2;
const UInt32Value TESTSWITCHWORD0001_CASESCOUNT = 3;
const UInt32Value TESTSWITCHWORD0001_CASEVALUES[] = {1, 0, 2};

void
VirtualMachineTest0001::testSwitchWord0001()
{
    testSwitchAtom(SwitchWord,
                   TESTSWITCHWORD0001_CASESCOUNT,
                   TESTSWITCHWORD0001_CASEVALUES,
                   TESTSWITCHWORD0001_TARGETVALUE);
}

////////////////////////////////////////

const UInt32Value TESTSWITCHWORD0002_TARGETVALUE = 3;
const UInt32Value TESTSWITCHWORD0002_CASESCOUNT = 3;
const UInt32Value TESTSWITCHWORD0002_CASEVALUES[] = {1, 0, 2};

void
VirtualMachineTest0001::testSwitchWord0002()
{
    testSwitchAtom(SwitchWord,
                   TESTSWITCHWORD0002_CASESCOUNT,
                   TESTSWITCHWORD0002_CASEVALUES,
                   TESTSWITCHWORD0002_TARGETVALUE);
}

////////////////////////////////////////

const UInt32Value TESTSWITCHCHAR0001_TARGETVALUE = '1';
const UInt32Value TESTSWITCHCHAR0001_CASESCOUNT = 3;
const UInt32Value TESTSWITCHCHAR0001_CASEVALUES[] = {'a', 'z', '1'};

void
VirtualMachineTest0001::testSwitchChar0001()
{
    testSwitchAtom(SwitchChar,
                   TESTSWITCHCHAR0001_CASESCOUNT,
                   TESTSWITCHCHAR0001_CASEVALUES,
                   TESTSWITCHCHAR0001_TARGETVALUE);
}

////////////////////////////////////////

const UInt32Value TESTSWITCHCHAR0002_TARGETVALUE = 'A';
const UInt32Value TESTSWITCHCHAR0002_CASESCOUNT = 3;
const UInt32Value TESTSWITCHCHAR0002_CASEVALUES[] = {'a', 'z', '1'};

void
VirtualMachineTest0001::testSwitchChar0002()
{
    testSwitchAtom(SwitchChar,
                   TESTSWITCHCHAR0002_CASESCOUNT,
                   TESTSWITCHCHAR0002_CASEVALUES,
                   TESTSWITCHCHAR0002_TARGETVALUE);
}

////////////////////////////////////////

const char* TESTSWITCHSTRING0001_TARGETVALUE = "abc";
const UInt32Value TESTSWITCHSTRING0001_CASESCOUNT = 3;
const char* TESTSWITCHSTRING0001_CASEVALUES[] = {"def", "ghq", "abc"};

void
VirtualMachineTest0001::testSwitchString0001()
{
    testSwitchString(TESTSWITCHSTRING0001_CASESCOUNT,
                     TESTSWITCHSTRING0001_CASEVALUES,
                     TESTSWITCHSTRING0001_TARGETVALUE);
}

////////////////////////////////////////

const char* TESTSWITCHSTRING0002_TARGETVALUE = "abc";
const UInt32Value TESTSWITCHSTRING0002_CASESCOUNT = 3;
const char* TESTSWITCHSTRING0002_CASEVALUES[] = {"def", "g", "xxxx"};

void
VirtualMachineTest0001::testSwitchString0002()
{
    testSwitchString(TESTSWITCHSTRING0002_CASESCOUNT,
                     TESTSWITCHSTRING0002_CASEVALUES,
                     TESTSWITCHSTRING0002_TARGETVALUE);
}

////////////////////////////////////////

const int TESTSWITCHSTRING_HEAPSIZE = 1024;
const int TESTSWITCHSTRING_STACKSIZE = 1024;

void
VirtualMachineTest0001::
testSwitchString(const UInt32Value casesCount,
                 const char* cases[],
                 const char* targetValue)
{
    Heap heap(TESTSWITCHSTRING_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(2, 0); // pointer = 2, atoms = 0

    UInt32Value code[100];
    UInt32Value offset = 0;
    UInt32Value targetLoadStringOffset;
    UInt32Value caseLoadStringOffsets[casesCount];
    UInt32Value jumpSrcOffsets[casesCount];
    UInt32Value exitOffsets[casesCount];
/*
    UInt32Value* caseLoadStringOffsets = new UInt32Value[casesCount];
    UInt32Value* jumpSrcOffsets = new UInt32Value[casesCount];
    UInt32Value* destinationOffsets = new UInt32Value[casesCount];
    UInt32Value* exitOffsets = new UInt32Value[casesCount];
*/

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadString, 0); // p1 = target value
    targetLoadStringOffset = offset;
    code[offset++] = 0;// offset of ConstString
    code[offset++] = funInfo.getPointerEntry(1);

    code[offset++] = EMBED_INSTRUCTION_3(SwitchString, 0);
    code[offset++] = funInfo.getPointerEntry(1);
    code[offset++] = casesCount; // cases count
    
    for(int index = 0; index < casesCount; index += 1){
        caseLoadStringOffsets[index] = offset;
        code[offset++] = 0; // offset of ConstString, to be filled later
        jumpSrcOffsets[index] = offset;
        code[offset++] = 0; // destination address, to be filled later
    }
    UInt32Value jumpSrcOffsetDefault = offset;
    code[offset++] = 0; // destination address, to be filled later
    // destination of switch jumps
    for(int index = 0; index < casesCount; index += 1){
        code[jumpSrcOffsets[index]] = (UInt32Value)&code[offset];
        code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);
        exitOffsets[index] = offset;
    }
    // LD
    code[jumpSrcOffsetDefault] = (UInt32Value)&code[offset];
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);
    UInt32Value exitOffsetDefault = offset;
    for(int index = 0; index < casesCount; index += 1){
        code[caseLoadStringOffsets[index]] = (UInt32Value)&(code[offset]);
        code[offset++] = EMBED_INSTRUCTION_3(ConstString, 0);
        code[offset++] = ::strlen(cases[index]);
        offset = embedString(code, offset, cases[index]);
    }
    code[targetLoadStringOffset] = (UInt32Value)&code[offset];
    code[offset++] = EMBED_INSTRUCTION_3(ConstString, 0);
    code[offset++] = ::strlen(targetValue);
    offset = embedString(code, offset, targetValue);
    
    //////////

    Executable *executable = buildExecutable(sizeof(code)/sizeof(code[0]), code);

    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);

    VirtualMachine::execute(executable);

    // verify the machine registers
    int matchCaseIndex = 0;
    for(; matchCaseIndex < casesCount; matchCaseIndex += 1){
        if(0 == ::strcmp(cases[matchCaseIndex], targetValue)){
            // matched case
            assertLongsEqual(exitOffsets[matchCaseIndex],
                             afterMonitor.PC_ - beforeMonitor.PC_);
            break;
        }
    }
    if(casesCount == matchCaseIndex){ // default case
        assertLongsEqual(exitOffsetDefault,
                         afterMonitor.PC_ - beforeMonitor.PC_);
    }
    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    assertLongsEqual(funInfo.getFrameSize(), 
                     beforeMonitor.SP_ - afterMonitor.SP_ );
}

////////////////////////////////////////

const int TESTJUMP0001_HEAPSIZE = 1024;
const int TESTJUMP0001_STACKSIZE = 1024;
const SInt32Value TESTJUMP0001_UNEXPECTEDRESULT = 1;
const SInt32Value TESTJUMP0001_EXPECTEDRESULT = -2;

void
VirtualMachineTest0001::testJump0001()
{
    Heap heap(TESTJUMP0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(1, 1); // pointer = 1, atoms = 1

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(Jump, 0);
    UInt32Value jumpOperandOffset = offset;
    code[offset++] = 0; // destination address, to be filled later
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0); // v0 = unexpected result
    code[offset++] = TESTJUMP0001_UNEXPECTEDRESULT;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);
    UInt32Value destinationOffset = offset;
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0); // v0 = expected result
    code[offset++] = TESTJUMP0001_EXPECTEDRESULT;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);
    UInt32Value exitOffset = offset;

    code[jumpOperandOffset] = (UInt32Value)&(code[destinationOffset]);
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
    assertLongsEqual(TESTJUMP0001_EXPECTEDRESULT,
                     *(afterMonitor.SP_ + funInfo.getAtomEntry(0)));
}

////////////////////////////////////////

const int TESTEXIT0001_HEAPSIZE = 1024;
const int TESTEXIT0001_STACKSIZE = 1024;
const UInt32Value TESTEXIT0001_EXPECTEDRESULT = 0x12345678;
const UInt32Value TESTEXIT0001_UNEXPECTEDRESULT = 0x23456789;

void
VirtualMachineTest0001::testExit0001()
{
    Heap heap(TESTEXIT0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(1, 1); // pointer = 1, atoms = 1

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = expected result
    code[offset++] = TESTEXIT0001_EXPECTEDRESULT;
    code[offset++] = funInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);
    UInt32Value exitOffset = offset;
    code[offset++] = EMBED_INSTRUCTION_3(LoadWord, 0);// v0 = unexpected result
    code[offset++] = TESTEXIT0001_UNEXPECTEDRESULT;
    code[offset++] = funInfo.getAtomEntry(0);

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
    assertLongsEqual(TESTEXIT0001_EXPECTEDRESULT,
                     *(afterMonitor.SP_ + funInfo.getAtomEntry(0)));
}

////////////////////////////////////////

const int TESTRETURN0001_HEAPSIZE = 1024;
const int TESTRETURN0001_STACKSIZE = 1024;
const UInt32Value TESTRETURN0001_UNEXPECTEDRESULT = 0x654321;
const UInt32Value TESTRETURN0001_EXPECTEDRESULT = 0x123456;

void
VirtualMachineTest0001::testReturn0001()
{
    Heap heap(TESTRETURN0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo callerFunInfo(1, 1); // pointer = 1, atoms = 1
    FunInfo calleeFunInfo(1, 1, 1);// arity = 1, pointer = 1 (ENV), atoms = 1
    calleeFunInfo.argsDest_[0] = calleeFunInfo.getAtomEntry(0);

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = callerFunInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(MakeBlockOfSingleValues, 0);//make a ENV block
    code[offset++] = callerFunInfo.getAtomEntry(0);// dummy bitmap
    code[offset++] = 0; // fields count
    code[offset++] = callerFunInfo.getPointerEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0); // v0 = unexpected result
    code[offset++] = TESTRETURN0001_UNEXPECTEDRESULT;
    code[offset++] = callerFunInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(CallStatic_S, 0); // call(callee, v0)
    UInt32Value callerOffset = offset;
    code[offset++] = 0; // entry point, to be filled later
    code[offset++] = 2; // args count
    code[offset++] = callerFunInfo.getPointerEntry(0);
    code[offset++] = callerFunInfo.getAtomEntry(0); // argument v0
    code[offset++] = callerFunInfo.getAtomEntry(0); // store result to v0
    code[offset++] = EMBED_INSTRUCTION_3(Exit, 0);
    UInt32Value exitOffset = offset;
    UInt32Value calleeOffset = offset;
    offset = calleeFunInfo.embedFunEntry(code, offset); // FunEntry
    code[offset++] = EMBED_INSTRUCTION_3(LoadInt, 0);
    code[offset++] = TESTRETURN0001_EXPECTEDRESULT;
    code[offset++] = calleeFunInfo.getAtomEntry(0);
    code[offset++] = EMBED_INSTRUCTION_3(Return_S, 0);// return expected result
    code[offset++] = calleeFunInfo.getAtomEntry(0);

    code[callerOffset] = (UInt32Value)&(code[calleeOffset]);
    Executable *executable = buildExecutable(sizeof(code)/sizeof(code[0]), code);

    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);

    VirtualMachine::execute(executable);

    // verify the machine registers
    assertLongsEqual(exitOffset, afterMonitor.PC_ - beforeMonitor.PC_);
//    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    assertLongsEqual(callerFunInfo.getFrameSize(), 
                     beforeMonitor.SP_ - afterMonitor.SP_ );
    assertLongsEqual(TESTRETURN0001_EXPECTEDRESULT,
                     *(afterMonitor.SP_ + callerFunInfo.getAtomEntry(0)));
}

////////////////////////////////////////

const int TESTNOP0001_HEAPSIZE = 1024;
const int TESTNOP0001_STACKSIZE = 1024;

void
VirtualMachineTest0001::testNop0001()
{
    Heap heap(TESTNOP0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);

    FunInfo funInfo(1, 1); // pointer = 1, atoms = 1

    UInt32Value code[100];
    UInt32Value offset = 0;

    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = EMBED_INSTRUCTION_3(Nop, 0);
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
}

///////////////////////////////////////////////////////////////////////////////

VirtualMachineTest0001::Suite::Suite()
{
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testLoadInt0001",
             &VirtualMachineTest0001::testLoadInt0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testLoadInt0002",
             &VirtualMachineTest0001::testLoadInt0002));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testLoadWord0001",
             &VirtualMachineTest0001::testLoadWord0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testLoadString0001",
             &VirtualMachineTest0001::testLoadString0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testLoadReal0001",
             &VirtualMachineTest0001::testLoadReal0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testLoadBoxedReal0001",
             &VirtualMachineTest0001::testLoadBoxedReal0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testLoadChar0001",
             &VirtualMachineTest0001::testLoadChar0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testAccess0001",
             &VirtualMachineTest0001::testAccess0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testAccessEnv0001",
             &VirtualMachineTest0001::testAccessEnv0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testAccessEnvIndirect0001",
             &VirtualMachineTest0001::testAccessEnvIndirect0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testGetField0001",
             &VirtualMachineTest0001::testGetField0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testGetFieldIndirect0001",
             &VirtualMachineTest0001::testGetFieldIndirect0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testSetField0001",
             &VirtualMachineTest0001::testSetField0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testSetFieldIndirect0001",
             &VirtualMachineTest0001::testSetFieldIndirect0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testCopyBlock0001",
             &VirtualMachineTest0001::testCopyBlock0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testGetGlobalBoxed0001",
             &VirtualMachineTest0001::testGetGlobalBoxed0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testSetGlobalBoxed0001",
             &VirtualMachineTest0001::testSetGlobalBoxed0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testGetGlobalUnboxed0001",
             &VirtualMachineTest0001::testGetGlobalUnboxed0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testSetGlobalUnboxed0001",
             &VirtualMachineTest0001::testSetGlobalUnboxed0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testGetEnv0001",
             &VirtualMachineTest0001::testGetEnv0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testCallPrim0001",
             &VirtualMachineTest0001::testCallPrim0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testApply0001",
             &VirtualMachineTest0001::testApply0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testTailApply0001",
             &VirtualMachineTest0001::testTailApply0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testCallStatic0001",
             &VirtualMachineTest0001::testCallStatic0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testTailCallStatic0001",
             &VirtualMachineTest0001::testTailCallStatic0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testMakeBlock0001",
             &VirtualMachineTest0001::testMakeBlock0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testMakeBlockOfSingleValues0001",
             &VirtualMachineTest0001::testMakeBlockOfSingleValues0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testMakeArray0001",
             &VirtualMachineTest0001::testMakeArray0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testMakeClosure0001",
             &VirtualMachineTest0001::testMakeClosure0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testSwitchInt0001",
             &VirtualMachineTest0001::testSwitchInt0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testSwitchInt0002",
             &VirtualMachineTest0001::testSwitchInt0002));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testSwitchWord0001",
             &VirtualMachineTest0001::testSwitchWord0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testSwitchWord0002",
             &VirtualMachineTest0001::testSwitchWord0002));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testSwitchChar0001",
             &VirtualMachineTest0001::testSwitchChar0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testSwitchChar0002",
             &VirtualMachineTest0001::testSwitchChar0002));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testSwitchString0001",
             &VirtualMachineTest0001::testSwitchString0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testSwitchString0002",
             &VirtualMachineTest0001::testSwitchString0002));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testJump0001",
             &VirtualMachineTest0001::testJump0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testExit0001",
             &VirtualMachineTest0001::testExit0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testReturn0001",
             &VirtualMachineTest0001::testReturn0001));
    addTest(new TestCaller<VirtualMachineTest0001>
            ("testNop0001",
             &VirtualMachineTest0001::testNop0001));

}

///////////////////////////////////////////////////////////////////////////////

}
