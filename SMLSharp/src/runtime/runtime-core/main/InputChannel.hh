#ifndef InputChannel_hh_
#define InputChannel_hh_

#include "SystemDef.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 *  This class represents connection to input strems such as file, socket and
 * memory.
 */
class InputChannel
{
    ///////////////////////////////////////////////////////////////////////////
  public:

    /**
     * constructor
     */
    InputChannel(){}
    
    /**
     * destructor
     */
    virtual
    ~InputChannel(){}

    ///////////////////////////////////////////////////////////////////////////
  public:

    /**
     * receive message from the input stream.
     *
     * @param requiredLength the maximum number of bytes to read.
     * @param receiveBuffer the buffer where the received message is stored
     * @return the byte length of the bytes stored in the
     *      <code>receiveBuffer</code>.
     */
    virtual
    UInt32Value receive(UInt32Value requiredLength, ByteValue* receiveBuffer)
        = 0;

    /**
     * indicates the channel has reached at EOF.
     *
     * @return true if the channel has reached at EOF.
     */
    virtual
    BoolValue isEOF()
        = 0;
};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // InputChannel_hh_
