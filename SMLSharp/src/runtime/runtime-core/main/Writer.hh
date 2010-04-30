#ifndef Writer_hh_
#define Writer_hh_

#include "SystemDef.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

class Writer
{
    ///////////////////////////////////////////////////////////////////////////
  public:

    enum OperationFlag
    {
        Write = 1,
        WriteNB = 2,
        Block = 4,
        CanOutput = 8,
        GetPos = 16,
        SetPos = 32,
        EndPos = 64,
        VerifyPos = 128,
        IoDesc = 256
    };

    ///////////////////////////////////////////////////////////////////////////
  public:

    Writer(){}

    virtual
    ~Writer(){}

    ///////////////////////////////////////////////////////////////////////////
  public:

    virtual const char* getName() = 0;

    virtual UInt32Value getChunkSize() = 0;

    virtual UInt32Value write(UInt32Value length, const ByteValue* buffer) = 0;

    virtual UInt32Value writeNB(UInt32Value length, const ByteValue* buffer) = 0;

    virtual void block() = 0;

    virtual BoolValue canOutput() = 0;

    virtual UInt32Value getPos() = 0;

    virtual void setPos(UInt32Value position) = 0;

    virtual UInt32Value endPos() = 0;

    virtual UInt32Value verifyPos() = 0;

    virtual void close() = 0;

    virtual int ioDesc() = 0;

    virtual UInt32Value getAvailableOperations() = 0;
};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // Writer_hh_
