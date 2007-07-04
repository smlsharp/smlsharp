#ifndef FileWriter_hh_
#define FileWriter_hh_

#include "SystemDef.hh"
#include "Writer.hh"
#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

class FileWriter
    :public Writer
{
    ///////////////////////////////////////////////////////////////////////////
  private:

    const char* fileName_;
    int descriptor_;
    BoolValue DontClose_;

    ///////////////////////////////////////////////////////////////////////////
  public:

    FileWriter(const char* fileName, int descriptor, BoolValue DontClose);

    virtual
    ~FileWriter();

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

#endif // Writer_hh_
