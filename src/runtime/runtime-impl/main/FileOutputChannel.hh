#ifndef FileOutputChannel_hh_
#define FileOutputChannel_hh_

#include "StreamOutputChannelBase.hh"
#include "SystemDef.hh"
#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 * A channel for reading a file.
 */
class FileOutputChannel
    : public StreamOutputChannelBase
{
    ///////////////////////////////////////////////////////////////////////////
  private:

    /**
     * the base file stream
     */
    FILE* stream_;

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
    FileOutputChannel(FileDescriptor descriptor);

    /**
     * destructor
     *
     * The destructor does not perform any release operation of the descriptor.
     */
    virtual
    ~FileOutputChannel();

    ///////////////////////////////////////////////////////////////////////////
    // Concretization of class OutputChannel

};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // FileOutputChannel_hh_
