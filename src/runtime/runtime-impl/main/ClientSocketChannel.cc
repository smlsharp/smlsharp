#include "ClientSocketChannel.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

ClientSocketChannel::ClientSocketChannel(FileDescriptor socket)
    : StreamInputChannelBase(socket),
      StreamOutputChannelBase(socket)
{
}

ClientSocketChannel::~ClientSocketChannel()
{
}

///////////////////////////////////////////////////////////////////////////////

BoolValue
ClientSocketChannel::isEOF()
{
    return BOOLVALUE_FALSE;
}

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

