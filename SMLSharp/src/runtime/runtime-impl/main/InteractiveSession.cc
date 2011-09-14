#include "InteractiveSession.hh"
#include "ProtocolException.hh"
#include "Constants.hh"
#include "Debug.hh"
#include "Log.hh"

#include <unistd.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

#define MINOR_CODE_EXECUTION 1

///////////////////////////////////////////////////////////////////////////////

InteractiveSession::InteractiveSession(InputChannel* messageInputChannel,
                                       OutputChannel* messageOutputChannel)
    : SessionBase(),
      messageInputChannel_(messageInputChannel),
      messageOutputChannel_(messageOutputChannel)
{
    standardInputReader_ =
    new RemoteTerminalReader(this, "stdin", STDIN_FILENO);
    standardOutputWriter_ =
    new RemoteTerminalWriter(this, "stdout", STDOUT_FILENO);
    standardErrorWriter_ =
    new RemoteTerminalWriter(this, "stderr", STDERR_FILENO);
}

InteractiveSession::~InteractiveSession()
{
}

///////////////////////////////////////////////////////////////////////////////

void
InteractiveSession::sendUInt32Value(UInt32Value value)
{
    // transmit 32bit word in network byte order (= big endian)
    UInt32Value inBigEndian = value;
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
    reverseQuadByte(&inBigEndian);
#endif
    messageOutputChannel_->sendArray(sizeof(UInt32Value),
                                     (ByteValue*)&inBigEndian);
}

void
InteractiveSession::sendSInt32Value(SInt32Value value)
{
    // transmit 32bit word in network byte order (= big endian)
    UInt32Value inBigEndian = value;
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
    reverseQuadByte(&inBigEndian);
#endif
    messageOutputChannel_->sendArray(sizeof(SInt32Value),
                                     (ByteValue*)&inBigEndian);
}

UInt32Value
InteractiveSession::receiveUInt32Value()
{
    // transmit 32bit word in network byte order (= big endian)
    UInt32Value inBigEndian;
    UInt32Value n;
    n = messageInputChannel_->receive(sizeof(UInt32Value),
				      (ByteValue*)&inBigEndian);
    if (n < sizeof(UInt32Value)) {
        DBGWRAP(LOG.error("receiveUInt32Value: invalid received length"));
        throw ProtocolException();
    }
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
    reverseQuadByte(&inBigEndian);
#endif
    return inBigEndian;
}

SInt32Value
InteractiveSession::receiveSInt32Value()
{
    // transmit 32bit word in network byte order (= big endian)
    SInt32Value inBigEndian;
    UInt32Value n;
    n = messageInputChannel_->receive(sizeof(SInt32Value),
                                      (ByteValue*)&inBigEndian);
    if (n < sizeof(UInt32Value)) {
        DBGWRAP(LOG.error("receiveSInt32Value: invalid received length"));
        throw ProtocolException();
    }
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
    reverseQuadByte((UInt32Value*)&inBigEndian);
#endif
    return inBigEndian;
}

void
InteractiveSession::sendByteArray(UInt32Value length, const ByteValue* data)
{
    sendUInt32Value(length);
    messageOutputChannel_->sendArray(length, data);
}

UInt32Value
InteractiveSession::receiveByteArray(UInt32Value *length, ByteValue** buffer)
{
    UInt32Value arrayLength = receiveUInt32Value();
    ByteValue* readBuffer = new ByteValue[arrayLength];
    if(arrayLength != messageInputChannel_->receive(arrayLength, readBuffer)){
        DBGWRAP(LOG.error("invalid received length::IMLRuntimeException"));
        throw ProtocolException();
    }
    *length = arrayLength;
    *buffer = readBuffer;
    return arrayLength;
}

void
InteractiveSession::sendResult(Result *result)
{
    messageOutputChannel_->send(result->majorCode);
    if(MAJOR_CODE_SUCCESS != result->majorCode){
        messageOutputChannel_->send(result->minorCode);
        sendByteArray(result->descriptionLength, result->description);
    }
}

InteractiveSession::Result*
InteractiveSession::receiveResult()
{
    ByteValue majorCode;
    UInt32Value n;
    n = messageInputChannel_->receive(1, &majorCode);
    if (n < 1) {
        DBGWRAP(LOG.error("receiveResult:major: invalid received length"));
        throw ProtocolException();
    }
    if(MAJOR_CODE_SUCCESS == majorCode){
        return new Result(majorCode);
    }
    else{
        ByteValue minorCode;
        n = messageInputChannel_->receive(1, &minorCode);
        if (n < 1) {
            DBGWRAP(LOG.error("receiveResult:minor: invalid received length"));
            throw ProtocolException();
        }
        UInt32Value arrayLength;
        ByteValue *array;
        receiveByteArray(&arrayLength, &array);
        return
        new Result(majorCode, minorCode, arrayLength, array, BOOLVALUE_TRUE);
    }
}

void
InteractiveSession::sendInitializationResult(Result* result)
{
    messageOutputChannel_->send(MESSAGE_TYPE_INITIALIZATION_RESULT);
    sendResult(result);
}

void
InteractiveSession::sendExecutionResult(Result* result)
{
    messageOutputChannel_->send(MESSAGE_TYPE_EXECUTION_RESULT);
    sendResult(result);
}

void
InteractiveSession::sendExitRequest(SInt32Value exitCode)
{
    messageOutputChannel_->send(MESSAGE_TYPE_EXIT_REQUEST);
    sendSInt32Value(exitCode);
}

void
InteractiveSession::sendChangeDirectoryRequest(const char* directory)
{
    messageOutputChannel_->send(MESSAGE_TYPE_CHANGE_DIRECTORY_REQUEST);
    sendByteArray(::strlen(directory), directory);
}

void 
InteractiveSession::sendInputRequest(UInt32Value length)
{
    messageOutputChannel_->send(MESSAGE_TYPE_INPUT_REQUEST);
    sendUInt32Value(length);
}

void
InteractiveSession::sendOutputRequest(FileDescriptor descriptor,
                                      UInt32Value length,
                                      const ByteValue* data)
{
    messageOutputChannel_->send(MESSAGE_TYPE_OUTPUT_REQUEST);
    sendUInt32Value(descriptor);
    sendByteArray(length, data);
}

SInt32Value
InteractiveSession::start()
    throw(IMLException)
{
    Result successResult(MAJOR_CODE_SUCCESS);

    SInt32Value exitCode;

    sendInitializationResult(&successResult);

    while(BOOLVALUE_FALSE == messageInputChannel_->isEOF())
    {
        ByteValue messageType;
	UInt32Value n;
        n = messageInputChannel_->receive(1, &messageType);
	if (n == 0) break;
        switch(messageType){
          case MESSAGE_TYPE_EXECUTION_REQUEST:
            {
                try{
                    Executable* executable =
                    receiveExecutionRequest(messageInputChannel_);
                    linkAndExecute(executable);
                    sendExecutionResult(&successResult);
                }
                catch(UserException &exception)
                {
                    const char* what = exception.what();
                    Result failure(MAJOR_CODE_FAILURE,
                                   MINOR_CODE_EXECUTION, // ToDo : 
                                   strlen(what),
                                   what,
                                   BOOLVALUE_FALSE);
                    DBGWRAP(LOG.error(what));
                    sendExecutionResult(&failure);
                }
                catch(IMLRuntimeException &exception)
                {
                    const char* what = exception.what();
                    Result failure(MAJOR_CODE_FAILURE,
                                   MINOR_CODE_EXECUTION, // ToDo : 
                                   strlen(what),
                                   what,
                                   BOOLVALUE_FALSE);
                    DBGWRAP(LOG.error(what));
                    sendExecutionResult(&failure);
                }
                catch(SystemError &exception)
                {
                    const char* what = exception.what();
                    DBGWRAP(LOG.error("fatal error:%s", what));
                    Result failure(MAJOR_CODE_FATAL,
                                   MINOR_CODE_EXECUTION, // ToDo : 
                                   strlen(what),
                                   what,
                                   BOOLVALUE_FALSE);
                    DBGWRAP(LOG.error(what));
                    sendExecutionResult(&failure);
                    ::exit(MAJOR_CODE_FATAL); // FIXME: we can exit here ?
                }
                fflush(stdout);
                fflush(stderr);
                break;
            }
          case MESSAGE_TYPE_EXIT_REQUEST:
            n = messageInputChannel_->receive
                (sizeof(SInt32Value), (ByteValue*)&exitCode);
            if (n < sizeof(SInt32Value)) {
                DBGWRAP(LOG.error("MESSAGE_TYPE_EXIT_REQUEST: "
                                  "invalid received length"));
                throw ProtocolException();
            }
            goto LOOP_EXIT;
          default:
            DBGWRAP(LOG.error("protocol error:invalid message type."));
            throw ProtocolException();
        }
    }
  LOOP_EXIT:
    return exitCode;
}

UInt32Value
InteractiveSession::
readFromRemoteTerminal(UInt32Value length, ByteValue* buffer)
{
    sendInputRequest(length);

    ByteValue messageType;
    UInt32Value n;
    n = messageInputChannel_->receive(1, &messageType);
    if (n == 0) return 0;
    switch(messageType){
      case MESSAGE_TYPE_INPUT_RESULT:
        {
            Result* result = receiveResult();
            if(MAJOR_CODE_SUCCESS == result->majorCode){
                delete result;
                UInt32Value readLength;
                ByteValue* readBuffer;
                receiveByteArray(&readLength, &readBuffer);
                if(length < readLength){
                    readLength = length; // ToDo : throw exception ??
                }
                COPY_MEMORY(buffer, readBuffer, readLength);
                delete readBuffer;
                return readLength;
            }
            else{
                delete result;
                DBGWRAP(LOG.error("input request fail."));
                throw IMLRuntimeException(); // ToDo : io exception
            }
            break;
        }
      default:
        DBGWRAP(LOG.error("INPUT_RESULT expected."));
        throw ProtocolException();
    }
}

UInt32Value
InteractiveSession::
writeToRemoteTerminal(FileDescriptor descriptor,
                      UInt32Value length,
                      const ByteValue* buffer)
{
    sendOutputRequest(descriptor, length, buffer);
    ByteValue messageType;
    UInt32Value n;
    n = messageInputChannel_->receive(1, &messageType);
    if (n == 0) return 0;
    switch(messageType){
      case MESSAGE_TYPE_OUTPUT_RESULT:
        {
            Result* result = receiveResult();
            if(MAJOR_CODE_SUCCESS == result->majorCode){
            }
            else{
            }
            delete result;
            return length;// ToDo : return actual written size???
        }
      default:
        DBGWRAP(LOG.error("OUTPUT_RESULT expected."));
        throw ProtocolException();
    }
}

///////////////////////////////////////////////////////////////////////////////

InteractiveSession::RemoteTerminalReader::
RemoteTerminalReader(InteractiveSession* session,
                     const char* fileName,
                     FileDescriptor descriptor)
    :Reader(),
     session_(session),
     fileName_(fileName),
     descriptor_(descriptor)
{
}

InteractiveSession::RemoteTerminalReader::~RemoteTerminalReader()
{
}

const char*
InteractiveSession::RemoteTerminalReader::getName()
{
    return fileName_;
}

UInt32Value
InteractiveSession::RemoteTerminalReader::getChunkSize()
{
    return 1;// ???
}

UInt32Value
InteractiveSession::RemoteTerminalReader::
read(UInt32Value length, ByteValue* buffer)
{
    return session_->readFromRemoteTerminal(length, buffer);
}

UInt32Value
InteractiveSession::RemoteTerminalReader::
readNB(UInt32Value length, ByteValue* buffer)
{
    return 0; // not implemented
}

void InteractiveSession::RemoteTerminalReader::block()
{
    // not implemented
}

BoolValue InteractiveSession::RemoteTerminalReader::canInput()
{
    // not implemented
}

UInt32Value InteractiveSession::RemoteTerminalReader::avail()
{
    // not implemented
    return 0xFFFFFFFF;
}

UInt32Value InteractiveSession::RemoteTerminalReader::getPos()
{
    // not implemented
}

void InteractiveSession::RemoteTerminalReader::setPos(UInt32Value position)
{
    // not implemented
}

UInt32Value InteractiveSession::RemoteTerminalReader::endPos()
{
    // not implemented
    return 0;
}

UInt32Value InteractiveSession::RemoteTerminalReader::verifyPos()
{
    return getPos();
}

void InteractiveSession::RemoteTerminalReader::close()
{

}

int InteractiveSession::RemoteTerminalReader::ioDesc()
{
    return descriptor_;
}

UInt32Value InteractiveSession::RemoteTerminalReader::getAvailableOperations()
{
    return 0xFFFFFFFF;
}

///////////////////////////////////////////////////////////////////////////////

InteractiveSession::RemoteTerminalWriter::
RemoteTerminalWriter(InteractiveSession* session,
                     const char* fileName,
                     FileDescriptor descriptor)
    :Writer(),
     session_(session),
     fileName_(fileName),
     descriptor_(descriptor)
{
}

InteractiveSession::RemoteTerminalWriter::~RemoteTerminalWriter()
{
}

const char*
InteractiveSession::RemoteTerminalWriter::getName()
{
    return fileName_;
}

UInt32Value
InteractiveSession::RemoteTerminalWriter::getChunkSize()
{
    return 1;// ???
}

UInt32Value
InteractiveSession::RemoteTerminalWriter::
write(UInt32Value length, const ByteValue* buffer)
{
    return session_->writeToRemoteTerminal(descriptor_, length, buffer);
}

UInt32Value
InteractiveSession::RemoteTerminalWriter::
writeNB(UInt32Value length, const ByteValue* buffer)
{
    return 0; // not implemented
}

void InteractiveSession::RemoteTerminalWriter::block()
{
    // not implemented
}

BoolValue InteractiveSession::RemoteTerminalWriter::canOutput()
{
    return BOOLVALUE_TRUE;
}

UInt32Value InteractiveSession::RemoteTerminalWriter::getPos()
{
    return 0;
}

void InteractiveSession::RemoteTerminalWriter::setPos(UInt32Value position)
{
    
}

UInt32Value InteractiveSession::RemoteTerminalWriter::endPos()
{
    return 0;// not implemented
}

UInt32Value InteractiveSession::RemoteTerminalWriter::verifyPos()
{
    return getPos();
}

void InteractiveSession::RemoteTerminalWriter::close()
{
}

int InteractiveSession::RemoteTerminalWriter::ioDesc()
{
    return descriptor_;
}

UInt32Value InteractiveSession::RemoteTerminalWriter::getAvailableOperations()
{
    return 0xFFFFFFFF;
}

///////////////////////////////////////////////////////////////////////////////

DBGWRAP(LogAdaptor InteractiveSession::LOG =
        LogAdaptor("InteractiveSession"));

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
