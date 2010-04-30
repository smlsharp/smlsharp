#ifndef FileReader_hh_
#define FileReader_hh_

#include "SystemDef.hh"
#include "Reader.hh"
#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

class FileReader
    :public Reader
{
    ///////////////////////////////////////////////////////////////////////////
  private:

    const char* fileName_;
    int descriptor_;
    BoolValue DontClose_;

    ///////////////////////////////////////////////////////////////////////////
  public:

    FileReader(const char* fileName, int descriptor, BoolValue DontClose);

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

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // Reader_hh_
