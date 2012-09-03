#include "SessionBase.hh"
#include "ProtocolException.hh"
#include "Debug.hh"
#include "Log.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

SessionBase::SessionBase()
    : Session(),
      executablePreProcessors_()
{
}

SessionBase::~SessionBase()
{
}

///////////////////////////////////////////////////////////////////////////////


Reader* SessionBase::getStandardInputReader()
{
    return standardInputReader_;
}

Writer* 
SessionBase::getStandardOutputWriter()
{
    return standardOutputWriter_;
}

Writer*
SessionBase::getStandardErrorWriter()
{
    return standardErrorWriter_;
}

void
SessionBase::
addExecutablePreProcessor(ExecutablePreProcessor* preProcessor)
{
    executablePreProcessors_.push_front(preProcessor);
}

void
SessionBase::linkAndExecute(Executable* executable)
    throw(IMLException)
{
    for(PreProcessorList::iterator i = executablePreProcessors_.begin() ;
        i != executablePreProcessors_.end ();
        i++)
    {
        ExecutablePreProcessor* preProcessor = *i;
        if(0 != preProcessor){
            preProcessor->process(executable);
        }
    }
    VirtualMachine::execute(executable);

    /* NOTE: Do not release the executable, because this executable may be
     *      referred to from a closure which has been registerred in the global
     *      table.
     */
//    releaseExecutable(executable);
}

Executable*
SessionBase::receiveExecutionRequest(InputChannel* channel)
{
    // UInt32Value totalByteLength (NOTE: the number of BYTEs)
    UInt32Value totalByteLength;
    channel->receive(sizeof(UInt32Value), (ByteValue*)&totalByteLength);
    totalByteLength = NetToNativeOrderQuadByte(totalByteLength);
    if(0 != totalByteLength % sizeof(UInt32Value)){
        DBGWRAP(LOG.error("total length not multi 4 bytes."));
        throw ProtocolException();// ToDo : illegal format executable
    }
    UInt32Value totalWordLength = totalByteLength / sizeof(UInt32Value);

    // allocate
    UInt32Value* executableBuffer =
    (UInt32Value*)ALLOCATE_MEMORY(totalByteLength);
    if(NULL == executableBuffer){throw OutOfMemoryException();}

    // receive serialized executable
    UInt32Value readByteLength =
    channel->receive(totalByteLength, (ByteValue*)executableBuffer);
    if(readByteLength != totalByteLength){
        delete[] executableBuffer;
        DBGWRAP(LOG.error("code cannot be read."));
        throw ProtocolException();// ToDo : illegal format executable
    }

    Executable *executable = new Executable(totalWordLength, executableBuffer);

    return executable;
}

Executable*
SessionBase::deserializeExecutionRequestFromBuffer(UInt32Value* &buffer)
{
    // UInt32Value totalByteLength (NOTE: the number of BYTEs)
    UInt32Value totalByteLength = *buffer;
    buffer += 1;
    totalByteLength = NetToNativeOrderQuadByte(totalByteLength);
    if(0 != totalByteLength % sizeof(UInt32Value)){
        DBGWRAP(LOG.error("total length not multi 4 bytes."));
        throw ProtocolException();// ToDo : illegal format executable
    }
    UInt32Value totalWordLength = totalByteLength / sizeof(UInt32Value);

    UInt32Value* executableBuffer = buffer;
    buffer += totalWordLength;

    Executable *executable = new Executable(totalWordLength, executableBuffer);

    return executable;
}

void
SessionBase::releaseExecutable(Executable* executable)
{
    // NOTE : 'code' is not released.

    delete executable;
}

///////////////////////////////////////////////////////////////////////////////

DBGWRAP(LogAdaptor SessionBase::LOG =
        LogAdaptor("SessionBase"));

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

