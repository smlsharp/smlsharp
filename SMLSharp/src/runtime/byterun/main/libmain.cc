#include "main.hh"

#include <string.h>

#ifdef USE_NAMESPACE
using namespace jp_ac_jaist_iml_runtime;
#endif

///////////////////////////////////////////////////////////////////////////////

extern "C"{

/** initialize an interactive session.
 * @param heapSize the size of runtime heap.
 *                Default size is allocated if 0 is specified.
 * @param stackSize the size of runtime frame stack.
 *                Default size is allocated if 0 is specified.
 * @param isInteractive non-zero if the compiler runs in interactive mode.
 * @param commandName the name that CommandLine.name returns.
 * @param commandArgsCount the number of elements of commandArgs.
 * @param commandArgs strings that CommandLine.arguments returns.
 */
void smlsharp_initialize(int heapSize,
                         int stackSize,
                         int isInteractive,
                         const char* commandName,
                         int commandArgsCount,
                         const char** commandArgs);

/** execute ExecutionRquest messages.
 * <p>
 * The buffer contains serialized form of a sequence of ExecutionRequest 
 * messages.
 * <p>
 * You have to call smlsharp_initialize before call this function.
 * and have to call smlsharp_finalize after the last call of smlsharp_execute.
 * Between smlsharp_initialize and smlsharp_finalize, you can call this
 * function any times.
 * </p>
 * @param bufferByteLength the number of bytes of buffer.
 * @param buffer serialized form of a sequence of ExecutionRequest messages.
 */
int smlsharp_execute(UInt32Value bufferByteLength, ByteValue* buffer);

/** execute an executable.
 * <p>
 * The buffer is a serialized form of an Executable.
 * <p>
 * This function is used internally to build SML# by MLton.
 * See src/compiler/commands/smlsharp/main/InteractiveSession_MLton.sml .
 * </p>
 * <p>
 * You have to call smlsharp_initialize before call this function.
 * and have to call smlsharp_finalize after the last call of smlsharp_execute.
 * Between smlsharp_initialize and smlsharp_finalize, you can call this
 * function any times.
 * </p>
 * @param bufferByteLength the number of bytes of buffer.
 * @param buffer serialized form of an Executable.
 */
int smlsharp_executeRawExecutable(UInt32Value bufferByteLength,
                                  ByteValue* buffer);

/** finalize an interactive session.
 */
void smlsharp_finalize();

void* smlsharp_importSymbol(const char* name);
void smlsharp_exportSymbol(const char* name, void* ptr);

} /* extern "C" */

///////////////////////////////////////////////////////////////////////////////

DBGWRAP(static LogAdaptor LOG = LogAdaptor("libmain"));

#ifdef IML_ENABLE_EXECUTION_MONITORING
#define SETUP_EXECUTION_MONITORING \
    InstructionTracer instructionTracer; \
    { \
        DBGWRAP(LOG.debug("execution monitoring is enabled.");) \
        char* envValue = getenv(IML_ENV_ENABLE_INSTTRACE); \
        DBGWRAP(LOG.debug("getenv(%s) = %s", \
                       IML_ENV_ENABLE_INSTTRACE, \
                       envValue ? envValue : "(null)");) \
        if(envValue && (0 == strcmp(envValue, "yes"))) \
        { \
            DBGWRAP(LOG.debug("enable instTrace");) \
            InstructionTracer::_enableTrace = true; \
        } \
        if(InstructionTracer::_enableTrace){ \
            VirtualMachine::addExecutionMonitor \
            ((VirtualMachineExecutionMonitor*)&instructionTracer); \
        } \
    } 
#else
#define SETUP_EXECUTION_MONITORING
#endif

#ifdef IML_ENABLE_ALLOCATION_MONITORING
#define SETUP_ALLOCATION_MONITORING \
    HeapAllocationTracer allocationTracer; \
    { \
        DBGWRAP(LOG.debug("heap allocation monitoring is enabled.");) \
        char* envValue = getenv(IML_ENV_ENABLE_ALLOCTRACE); \
        DBGWRAP(LOG.debug("getenv(%s) = %s", \
                       IML_ENV_ENABLE_ALLOCTRACE, \
                       envValue ? envValue : "(null)");) \
        if(envValue && (0 == strcmp(envValue, "yes"))) \
        { \
            DBGWRAP(LOG.debug("enable allocationTrace");) \
            HeapAllocationTracer::_enableTrace = true; \
        } \
        if(HeapAllocationTracer::_enableTrace){ \
            Heap::addMonitor((HeapMonitor*)&allocationTracer); \
        } \
    }
#else
#define SETUP_ALLOCATION_MONITORING
#endif

////////////////////

StandAloneSession* session_ = 0;
VirtualMachine* vm_ = 0;
ExecutableLinker* linker_ = 0;

////////////////////

void 
smlsharp_initialize(int heapSize,
                    int stackSize,
                    int isInteractive,
                    const char* commandName,
                    int commandArgsCount,
                    const char** commandArgs)
{
    DBGWRAP(FileLogFacade::setup(stdout));

    session_ = new StandAloneSession();

    ////////////////////////////////////////

    /*  The process ignores SIGINT in interactive mode, so that user's
     * Ctrl-C to cancel current input does not terminate the process.
     */
    if(isInteractive){
        signal(SIGINT, SIG_IGN);
    }

    ////////////////////////////////////////

    if(0 == heapSize){heapSize = DEFAULT_HEAPSIZE;}
    if(0 == stackSize){stackSize = DEFAULT_STACKSIZE;}

    /* These buffers are retained forever.
     */
    const char* name = strdup(commandName);
    const int argsCount = commandArgsCount;
    const char** args = new const char*[argsCount];
    for(int i = 0; i < argsCount; i += 1){
        args[i] = strdup(commandArgs[i]);
    }

    ////////////////////////////////////////

    Heap::initialize(heapSize);
    vm_ = new VirtualMachine(name, NULL, argsCount, args, stackSize);
    Heap::setRootSet(vm_);
    Heap::setFinalizerExecutor(vm_);
    VirtualMachine::setSession(session_);

    SETUP_EXECUTION_MONITORING;
    SETUP_ALLOCATION_MONITORING;

    linker_ = new ExecutableLinker();
    session_->addExecutablePreProcessor(linker_);

    FFI::init();
}

/**
 * buffer contains a sequence of serialized form of ExecutionRequest messages.
 */
int
smlsharp_execute(UInt32Value bufferByteLength, ByteValue* buffer)
{
    int exitCode;
    try{
        exitCode = session_->run(bufferByteLength, (UInt32Value*)buffer);
    }
    catch(IMLException& exception){ fprintf(stderr, exception.what()); }

#ifdef IML_ENABLE_ALLOCATION_MONITORING
    DBGWRAP(LOG.debug("allocated fields: %d",
                      allocationTracer._allocatedFields);)
#endif

    return exitCode;
}

/**
 * buffer contains a serialized form of an Executable.
 */
int
smlsharp_executeRawExecutable(UInt32Value bufferByteLength, ByteValue* buffer)
{

    ByteValue* executableBuffer;
    /* buffer is copied, because buffer will be garbage-collected by MLton
     * runtime GC. 
     * And, session->run takes serialized form of ExecutionRequestMessages,
     * not of Executable, a 32-bit word is prepended to indicate byte length
     * of Executable (see ExecutableSpecification and MessageSpecification in
     * doc/formal/Protocol/Design directory in the source tree ).
     */
    executableBuffer = new ByteValue[sizeof(UInt32Value) + bufferByteLength];
    *(UInt32Value*)executableBuffer = 
        WordOperations::NativeToNetOrderQuadByte(bufferByteLength);
    COPY_MEMORY(executableBuffer + sizeof(UInt32Value),
                buffer, bufferByteLength);

    int exitCode;
    try{
        exitCode =
        session_->run(bufferByteLength, (UInt32Value*)executableBuffer);
    }
    catch(IMLException& exception){ fprintf(stderr, exception.what()); }

#ifdef IML_ENABLE_ALLOCATION_MONITORING
    DBGWRAP(LOG.debug("allocated fields: %d",
                      allocationTracer._allocatedFields);)
#endif

    return exitCode;
}

void smlsharp_finalize()
{
    FFI::finalize();

    delete session_;
}

void* smlsharp_importSymbol(const char* name)
{
    return VirtualMachine::getInstance()->findExportedSymbol(name);
}
 
void smlsharp_exportSymbol(const char* name, void* ptr)
{
    VirtualMachine::getInstance()->addImportedSymbol(name, ptr);
}

///////////////////////////////////////////////////////////////////////////////
