/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: ByteArrayInputChannel.cc,v 1.3 2005/02/07 10:34:10 kiyoshiy Exp $
 */
#include "ByteArrayInputChannel.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

ByteArrayInputChannel::
ByteArrayInputChannel(UInt32Value bufferLength, ByteValue* buffer)
    : bufferLength_(bufferLength),
      buffer_(buffer),
      currentPosition_(0)
{

}

ByteArrayInputChannel::~ByteArrayInputChannel()
{
}

///////////////////////////////////////////////////////////////////////////////

UInt32Value
ByteArrayInputChannel::
receive(UInt32Value requiredLength, ByteValue* receiveBuffer)
{
    UInt32Value availableLength = bufferLength_ - currentPosition_;
    UInt32Value resultLength =
    (availableLength < requiredLength) ? availableLength : requiredLength;

    COPY_MEMORY(receiveBuffer, buffer_ + currentPosition_, resultLength);

    currentPosition_ += resultLength;
    return resultLength;
}

BoolValue
ByteArrayInputChannel::isEOF()
{
    return ((bufferLength_ <= currentPosition_)
            ? BOOLVALUE_TRUE
            : BOOLVALUE_FALSE);
}

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
