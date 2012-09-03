#include "ClientSocketChannel.hh"

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

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
