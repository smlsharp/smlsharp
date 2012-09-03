#ifndef StreamInputChannelBase_hh_
#define StreamInputChannelBase_hh_

#include "InputChannel.hh"
#include "SystemDef.hh"
#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 * A channel for reading a file.
 */
class StreamInputChannelBase
    : public InputChannel
{
    ///////////////////////////////////////////////////////////////////////////
  protected:

    /**
     * the base stream
     */
    FileDescriptor descriptor_;

    ///////////////////////////////////////////////////////////////////////////
  public:

    /**
     * constructor
     *
     * @param descriptor the descriptor of the stream to read.
     */
    StreamInputChannelBase(FileDescriptor descriptor);

    /**
     * destructor
     *
     * The destructor does not perform any release operation of the descriptor.
     */
    virtual
    ~StreamInputChannelBase();

    ///////////////////////////////////////////////////////////////////////////
    // Concretization of class InputChannel

  public:

    virtual
    UInt32Value receive(UInt32Value requiredLength, ByteValue* receiveBuffer);

};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // StreamInputChannelBase_hh_
