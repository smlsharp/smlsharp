#include "StreamInputChannelBase.hh"
#include <unistd.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

StreamInputChannelBase::StreamInputChannelBase(FileDescriptor descriptor)
    : InputChannel(),
      descriptor_(descriptor)
{
}

StreamInputChannelBase::~StreamInputChannelBase()
{
}

///////////////////////////////////////////////////////////////////////////////

UInt32Value
StreamInputChannelBase::
receive(UInt32Value requiredSize, ByteValue* receiveBuffer)
{
    ByteValue* currentPosition = receiveBuffer;
    UInt32Value leftSize = requiredSize;
    UInt32Value chunkSize = 40960;

    while(0 < leftSize)
    {
        size_t requiredSize = leftSize < chunkSize ? leftSize : chunkSize;
        size_t readSize = ::read(descriptor_, currentPosition, requiredSize);
        if(readSize < 0){
            return readSize;
        }
        else if(0 == readSize){
            break;
        }
        leftSize -= readSize;
        currentPosition += readSize;
    }
    return (requiredSize - leftSize);
}

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
