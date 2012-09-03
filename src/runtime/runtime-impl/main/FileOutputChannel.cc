#include "FileOutputChannel.hh"
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <unistd.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

FileOutputChannel::FileOutputChannel(FileDescriptor descriptor)
    : StreamOutputChannelBase(descriptor)
{
    stream_ = ::fdopen(descriptor, "wb");

    struct stat stat;
    fstat(descriptor, &stat);
    fileLength_ = stat.st_size;
}

FileOutputChannel::~FileOutputChannel()
{
}

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
