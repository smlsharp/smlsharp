#ifndef FileInputChannel_hh_
#define FileInputChannel_hh_

#include "StreamInputChannelBase.hh"
#include "SystemDef.hh"
#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 * A channel for reading a file.
 */
class FileInputChannel
    : public StreamInputChannelBase
{
    ///////////////////////////////////////////////////////////////////////////
  private:

    /**
     * file size in bytes
     */
    int fileLength_;

    ///////////////////////////////////////////////////////////////////////////
  public:

    /**
     * constructor
     *
     * @param descriptor the descriptor of the connection to the file stream
     *                  with read permission.
     */
    FileInputChannel(FileDescriptor descriptor);

    /**
     * destructor
     *
     * The destructor does not perform any release operation of the descriptor.
     */
    virtual
    ~FileInputChannel();

    ///////////////////////////////////////////////////////////////////////////
    // Concretization of class InputChannel

  public:

    virtual
    BoolValue isEOF();

};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // FileInputChannel_hh_
