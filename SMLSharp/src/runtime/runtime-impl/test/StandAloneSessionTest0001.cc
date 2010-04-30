// StandAloneSessionTest0001
// jp_ac_jaist_iml_runtime

#include "StandAloneSessionTest0001.hh"
#include "StandAloneSession.hh"
#include "VirtualMachine.hh"
#include "Heap.hh"
#include "ExecutableLinker.hh"
#include "ByteArrayInputChannel.hh"
#include "VirtualMachineTestUtil.hh"

#include "TestCaller.h"

namespace jp_ac_jaist_iml_runtime
{

///////////////////////////////////////////////////////////////////////////////

void
StandAloneSessionTest0001::setUp()
{
    // setup facades
}

void
StandAloneSessionTest0001::tearDown()
{
    //
}

///////////////////////////////////////////////////////////////////////////////

const int TESTSTART0001_HEAPSIZE = 409600;
const int TESTSTART0001_STACKSIZE = 409600;

void
StandAloneSessionTest0001::testStart0001()
{
    FunInfo funInfo(1, 0);

    // a function which exits instantly.
    UInt32Value executableBuffer[100];
    UInt32Value *code = &executableBuffer[1];
    UInt32Value offset = 0;
    offset = funInfo.embedFunEntry(code, offset);
    code[offset++] = pack_1_3(Exit, 0);
    UInt32Value codeWordLength = offset;
    executableBuffer[0] = codeWordLength;// length of [FunEntry, Exit] 

    UInt32Value nativeExecutableByteLength =
    sizeof(UInt32Value) * (1 + codeWordLength);
    UInt32Value netExecutableByteLength =
    NativeToNetOrderQuadByte(nativeExecutableByteLength);

    UInt32Value messageByteLength =
    1 + sizeof(netExecutableByteLength) + nativeExecutableByteLength;
    ByteValue message[messageByteLength];
    message[0] = NATIVE_BYTE_ORDER;
    COPY_MEMORY(&message[1],
                &netExecutableByteLength,
                sizeof(netExecutableByteLength));
    COPY_MEMORY(&message[1 + sizeof(nativeExecutableByteLength)],
                executableBuffer,
                nativeExecutableByteLength);
    ByteArrayInputChannel executableChannel(sizeof(message), message);

    StandAloneSession session(&executableChannel);

    Heap heap(TESTSTART0001_HEAPSIZE);
    VirtualMachine vm;
    Heap::setRootSet(&vm);
    BeforeExecutionMonitor beforeMonitor;
    AfterExecutionMonitor afterMonitor;
    VirtualMachine::addExecutionMonitor(&beforeMonitor);
    VirtualMachine::addExecutionMonitor(&afterMonitor);
    VirtualMachine::setSession(&session);

    ExecutableLinker linker;
    session.addExecutablePreProcessor(&linker);

    session.start();

    ////////////////////////////////////////

    assertLongsEqual(offset, afterMonitor.PC_ - beforeMonitor.PC_);
    assertLongsEqual((long)(beforeMonitor.ENV_), (long)(afterMonitor.ENV_));
    assertLongsEqual((long)(beforeMonitor.SP_)
                     - (funInfo.getFrameSize() * sizeof(UInt32Value)),
                     (long)(afterMonitor.SP_));
}

///////////////////////////////////////////////////////////////////////////////

StandAloneSessionTest0001::Suite::Suite()
{
    addTest(new TestCaller<StandAloneSessionTest0001>
            ("testStart0001",
             &StandAloneSessionTest0001::testStart0001));
}

///////////////////////////////////////////////////////////////////////////////

}
