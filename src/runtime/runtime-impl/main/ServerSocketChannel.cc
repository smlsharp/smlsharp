#include "ServerSocketChannel.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

ServerSocketChannel::ServerSocketChannel(FileDescriptor socket)
    : StreamInputChannelBase(socket),
      StreamOutputChannelBase(socket)
{
}

ServerSocketChannel::~ServerSocketChannel()
{
}

///////////////////////////////////////////////////////////////////////////////

BoolValue
ServerSocketChannel::isEOF()
{
    return BOOLVALUE_FALSE;
}

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
