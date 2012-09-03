#ifndef StreamOutputChannelBase_hh_
#define StreamOutputChannelBase_hh_

#include "OutputChannel.hh"
#include "SystemDef.hh"
#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 * A channel for reading a file.
 */
class StreamOutputChannelBase
    : public OutputChannel
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
    StreamOutputChannelBase(FileDescriptor descriptor);

    /**
     * destructor
     *
     * The destructor does not perform any release operation of the descriptor.
     */
    virtual
    ~StreamOutputChannelBase();

    ///////////////////////////////////////////////////////////////////////////
    // Concretization of class OutputChannel
  public:

    virtual
    UInt32Value send(ByteValue value);

    virtual
    UInt32Value sendArray(UInt32Value byteLength, const ByteValue* buffer);

};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // StreamOutputChannelBase_hh_
