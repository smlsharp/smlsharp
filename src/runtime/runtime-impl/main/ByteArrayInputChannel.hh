#ifndef ByteArrayInputChannel_hh_
#define ByteArrayInputChannel_hh_

#include "InputChannel.hh"
#include "SystemDef.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 * A channel for reading bytes on memory
 */
class ByteArrayInputChannel
    : public InputChannel
{
    ///////////////////////////////////////////////////////////////////////////
  private:

    UInt32Value bufferLength_;
    ByteValue* buffer_;
    UInt32Value currentPosition_;

    ///////////////////////////////////////////////////////////////////////////
  public:

    /**
     * constructor
     *
     * @param bufferLength the number of bytes contained in the
     *                   <code>buffer</code>.
     * @param buffer the byte array
     */
    ByteArrayInputChannel(UInt32Value bufferLength, ByteValue* buffer);

    /**
     * destructor
     */
    virtual
    ~ByteArrayInputChannel();

    ///////////////////////////////////////////////////////////////////////////
    // Concretization of class InputChannel

  public:

    virtual
    UInt32Value receive(UInt32Value requiredLength, ByteValue* receiveBuffer);

    virtual
    BoolValue isEOF();

};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // ByteArrayInputChannel_hh_
