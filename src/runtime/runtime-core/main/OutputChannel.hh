#ifndef OutputChannel_hh_
#define OutputChannel_hh_

#include "SystemDef.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 *  This class represents connection to output streams such as file, socket
 * and memory.
 */
class OutputChannel
{
    ///////////////////////////////////////////////////////////////////////////
  public:

    /**
     * constructor
     */
    OutputChannel(){}
    
    /**
     * destructor
     */
    virtual
    ~OutputChannel(){}

    ///////////////////////////////////////////////////////////////////////////
  public:

    virtual
    UInt32Value send(ByteValue value)
        = 0;

    /**
     * writes message to the output stream.
     *
     * @param byteLength the number of bytes to send
     * @param buffer the data to send
     * @return the number of bytes actually written to the stream
     */
    virtual
    UInt32Value sendArray(UInt32Value byteLength, const ByteValue* buffer)
        = 0;
};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // OutputChannel_hh_
