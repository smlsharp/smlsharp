#ifndef ClientSocketChannel_hh_
#define ClientSocketChannel_hh_

#include "StreamInputChannelBase.hh"
#include "StreamOutputChannelBase.hh"
#include "SystemDef.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 * A channel for reading/writing on a sever socket.
 */
class ClientSocketChannel
    : public StreamInputChannelBase,
      public StreamOutputChannelBase
{
    ///////////////////////////////////////////////////////////////////////////
  private:

    ///////////////////////////////////////////////////////////////////////////
  public:

    /**
     * constructor
     *
     * @param socket the socket which is returned by <code>accept</code>.
     */
    ClientSocketChannel(int socket);

    /**
     * destructor
     *
     * The destructor does not perform any release operation of the descriptor.
     */
    virtual
    ~ClientSocketChannel();

    ///////////////////////////////////////////////////////////////////////////
    // Concretization of class InputChannel
  public:

    virtual
    BoolValue isEOF();

};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // ClientSocketChannel_hh_
