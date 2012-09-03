#include "InteractiveSession.hh"
#include "ProtocolException.hh"
#include "Debug.hh"
#include "Log.hh"

#include <unistd.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

#define MESSAGE_TYPE_INITIALIZATION_RESULT 0
#define MESSAGE_TYPE_EXIT_REQUEST 1
#define MESSAGE_TYPE_EXECUTION_REQUEST 2
#define MESSAGE_TYPE_EXECUTION_RESULT 3
#define MESSAGE_TYPE_OUTPUT_REQUEST 4
#define MESSAGE_TYPE_OUTPUT_RESULT 5
#define MESSAGE_TYPE_INPUT_REQUEST 6
#define MESSAGE_TYPE_INPUT_RESULT 7

#define MAJOR_CODE_SUCCESS 0
#define MAJOR_CODE_FAILURE 1

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

UInt32Value
InteractiveSession::receiveUInt32Value()
{
    // transmit 32bit word in network byte order (= big endian)
    UInt32Value inBigEndian;
    messageInputChannel_->receive(sizeof(UInt32Value),
                                  (ByteValue*)&inBigEndian);
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
    reverseQuadByte(&inBigEndian);
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
    messageInputChannel_->receive(1, &majorCode);
    if(MAJOR_CODE_SUCCESS == majorCode){
        return new Result(majorCode);
    }
    else{
        ByteValue minorCode;
        messageInputChannel_->receive(1, &minorCode);
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
    throw(IMLRuntimeException,
          UserException,
          SystemError)
{
    Result successResult(MAJOR_CODE_SUCCESS);

    SInt32Value exitCode;

    sendInitializationResult(&successResult);

    while(BOOLVALUE_FALSE == messageInputChannel_->isEOF())
    {
        ByteValue messageType;
        messageInputChannel_->receive(1, &messageType);
        switch(messageType){
          case MESSAGE_TYPE_EXECUTION_REQUEST:
            {
                try{
                    Executable* executable =
                    receiveExecutable(messageInputChannel_);
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
                break;
            }
          case MESSAGE_TYPE_EXIT_REQUEST:
            messageInputChannel_->receive
            (sizeof(SInt32Value), (ByteValue*)&exitCode);
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
    messageInputChannel_->receive(1, &messageType);
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
    messageInputChannel_->receive(1, &messageType);
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
