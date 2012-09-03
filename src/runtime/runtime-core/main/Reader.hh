#ifndef Reader_hh_
#define Reader_hh_

#include "SystemDef.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

class Reader
{
    ///////////////////////////////////////////////////////////////////////////
  public:

    enum OperationFlag
    {
        Read = 1,
        ReadNB = 2,
        Block = 4,
        CanInput = 8,
        Avail = 16,
        GetPos = 32,
        SetPos = 64,
        EndPos = 128,
        VerifyPos = 256,
        IoDesc = 512
    };

    ///////////////////////////////////////////////////////////////////////////
  public:

    Reader(){}

    virtual
    ~Reader(){}

    ///////////////////////////////////////////////////////////////////////////
  public:

    virtual const char* getName() = 0;

    virtual UInt32Value getChunkSize() = 0;

    virtual UInt32Value read(UInt32Value length, ByteValue* buffer) = 0;

    virtual UInt32Value readNB(UInt32Value length, ByteValue* buffer) = 0;

    virtual void block() = 0;

    virtual BoolValue canInput() = 0;

    virtual UInt32Value avail() = 0;

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

#endif // Reader_hh_
