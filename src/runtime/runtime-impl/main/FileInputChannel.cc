#include "FileInputChannel.hh"
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <unistd.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

FileInputChannel::FileInputChannel(FileDescriptor descriptor)
    : StreamInputChannelBase(descriptor)
{
    stream_ = ::fdopen(descriptor, "rb");

    struct stat stat;
    fstat(descriptor, &stat);
    fileLength_ = stat.st_size;
}

FileInputChannel::~FileInputChannel()
{
}

///////////////////////////////////////////////////////////////////////////////

BoolValue
FileInputChannel::isEOF()
{
//    long currentPosition = ftell(stream_);
    long currentPosition = lseek(descriptor_, 0, SEEK_CUR);
    return (fileLength_ <= currentPosition) ? BOOLVALUE_TRUE : BOOLVALUE_FALSE;
/*
    return ((0 == (::feof)(stream_)) ? BOOLVALUE_FALSE : BOOLVALUE_TRUE);
*/
}

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
