#include "StreamOutputChannelBase.hh"
#include <unistd.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

StreamOutputChannelBase::StreamOutputChannelBase(FileDescriptor descriptor)
    : OutputChannel(),
      descriptor_(descriptor)
{
}

StreamOutputChannelBase::~StreamOutputChannelBase()
{
}

///////////////////////////////////////////////////////////////////////////////

UInt32Value
StreamOutputChannelBase::send(ByteValue value)
{
    return write(descriptor_, &value, 1);
}

UInt32Value
StreamOutputChannelBase::sendArray(UInt32Value byteLength,
                                   const ByteValue* buffer)
{
    const ByteValue* currentPosition = buffer;
    int	leftLength;
    int writtenLength;

    leftLength = byteLength;
    while (leftLength > 0) {
        writtenLength = write(descriptor_, currentPosition, leftLength);
        if(writtenLength <= 0){
            return(writtenLength);
        }
        
        leftLength -= writtenLength;
        currentPosition += writtenLength;
    }
    return(byteLength - leftLength);
}

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
