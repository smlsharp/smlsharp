#ifndef InteractiveSession_hh_
#define InteractiveSession_hh_

#include "Session.hh"
#include "VirtualMachine.hh"
#include "InputChannel.hh"
#include "OutputChannel.hh"
#include "SessionBase.hh"
#include "ExecutablePreProcessor.hh"
#include "Log.hh"
#include "Debug.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 *
 */
class InteractiveSession
    :public SessionBase
{
    ///////////////////////////////////////////////////////////////////////////
  private:

    /**
     * the input channel from which messages are read.
     */
    InputChannel* messageInputChannel_;

    /**
     * the output channel from which messages are writen to.
     */
    OutputChannel* messageOutputChannel_;

    /**
     * log writer
     */
    DBGWRAP(static LogAdaptor LOG);

    ///////////////////////////////////////////////////////////////////////////
  public:

    /**
     * constructor
     *
     * @param messageInputChannel the session reads messages from this
     *                        input channel.
     * @param messageOutputChannel the session writes messages to this
     *                        input channel.
     */
    InteractiveSession(InputChannel* messageInputChannel,
                       OutputChannel* messageOutputChannel);

    /**
     * destructor
     */
    virtual
    ~InteractiveSession();

    ///////////////////////////////////////////////////////////////////////////
  public:

    virtual
    SInt32Value start()
        throw(IMLRuntimeException,
              UserException,
              SystemError);

    ///////////////////////////////////////////////////////////////////////////
  private:

    class RemoteTerminalReader;
    class RemoteTerminalWriter;

    friend class RemoteTerminalReader;
    friend class RemoteTerminalWriter;

    struct Result
    {
        ByteValue majorCode;
        ByteValue minorCode;
        UInt32Value descriptionLength;
        const ByteValue* description;
        BoolValue needsDeleteDescription;

        Result(ByteValue mj,
               ByteValue mn = 0,
               UInt32Value len = 0,
               const ByteValue* desc = 0,
               BoolValue del = BOOLVALUE_FALSE)
            :majorCode(mj),
             minorCode(mn),
             descriptionLength(len),
             description(desc),
             needsDeleteDescription(del)
        {
        }

        ~Result()
        {
            if(description && (BOOLVALUE_TRUE == needsDeleteDescription)){
                delete description;
            }
        }
    };

    ///////////////////////////////////////////////////////////////////////////
  private:

    void sendUInt32Value(UInt32Value value);

    UInt32Value receiveUInt32Value();

    void sendByteArray(UInt32Value length, const ByteValue* data);

    UInt32Value receiveByteArray(UInt32Value *length, ByteValue** buffer);

    void sendResult(Result* result);

    Result* receiveResult();

    void sendInitializationResult(Result* result);

    void sendExecutionResult(Result* result);

    void sendInputRequest(UInt32Value length);

    void sendOutputRequest(FileDescriptor descriptor,
                           UInt32Value length,
                           const ByteValue* data);

    UInt32Value readFromRemoteTerminal(UInt32Value length, ByteValue* buffer);

    UInt32Value writeToRemoteTerminal(FileDescriptor descriptor,
                                      UInt32Value length,
                                      const ByteValue* buffer);

};

///////////////////////////////////////////////////////////////////////////////

class InteractiveSession::RemoteTerminalReader
    :public Reader
{
    //////////////////////////////////////////////////////////////////////////
  private:

    InteractiveSession* session_;

    const char* fileName_;

    FileDescriptor descriptor_;

    ///////////////////////////////////////////////////////////////////////////
  public:

    RemoteTerminalReader(InteractiveSession* session,
                         const char* fileName,
                         FileDescriptor descriptor);

    virtual
    ~RemoteTerminalReader();

    ///////////////////////////////////////////////////////////////////////////
  public:

    virtual const char* getName();

    virtual UInt32Value getChunkSize();

    virtual UInt32Value read(UInt32Value length, ByteValue* buffer);

    virtual UInt32Value readNB(UInt32Value length, ByteValue* buffer);

    virtual void block();

    virtual BoolValue canInput();

    virtual UInt32Value avail();

    virtual UInt32Value getPos();

    virtual void setPos(UInt32Value position);

    virtual UInt32Value endPos();

    virtual UInt32Value verifyPos();

    virtual void close();

    virtual int ioDesc();

    virtual UInt32Value getAvailableOperations();
};

class InteractiveSession::RemoteTerminalWriter
    :public Writer
{
    ///////////////////////////////////////////////////////////////////////////
  private:

    InteractiveSession* session_;

    const char* fileName_;

    FileDescriptor descriptor_;

    ///////////////////////////////////////////////////////////////////////////
  public:

    RemoteTerminalWriter(InteractiveSession* session,
                         const char* fileName,
                         FileDescriptor descriptor);

    virtual
    ~RemoteTerminalWriter();

    ///////////////////////////////////////////////////////////////////////////
  public:

    virtual const char* getName();

    virtual UInt32Value getChunkSize();

    virtual UInt32Value write(UInt32Value length, const ByteValue* buffer);

    virtual UInt32Value writeNB(UInt32Value length, const ByteValue* buffer);

    virtual void block();

    virtual BoolValue canOutput();

    virtual UInt32Value getPos();

    virtual void setPos(UInt32Value position);

    virtual UInt32Value endPos();

    virtual UInt32Value verifyPos();

    virtual void close();

    virtual int ioDesc();

    virtual UInt32Value getAvailableOperations();

};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // InteractiveSession_hh_
