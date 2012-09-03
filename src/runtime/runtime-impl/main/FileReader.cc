#include "FileReader.hh"
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <unistd.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

FileReader::
FileReader(const char* fileName, int descriptor, BoolValue DontClose)
    :Reader(),
     fileName_(fileName),
     descriptor_(descriptor),
     DontClose_(DontClose)
{
}

const char*
FileReader::getName()
{
    return fileName_;
}

UInt32Value
FileReader::getChunkSize()
{
    return 1;// ???
}

UInt32Value
FileReader::read(UInt32Value length, ByteValue* buffer)
{
    return ::read(descriptor_, buffer, length);
}

UInt32Value
FileReader::readNB(UInt32Value length, ByteValue* buffer)
{
    return 0; // not implemented
}

void FileReader::block()
{
    // not implemented
}

BoolValue FileReader::canInput()
{
    FILE* stream = fdopen(descriptor_, "rb");
    return feof(stream) ? BOOLVALUE_FALSE : BOOLVALUE_TRUE;
}

UInt32Value FileReader::avail()
{
    // not implemented
    return 0xFFFFFFFF;
}

UInt32Value FileReader::getPos()
{
    return lseek(descriptor_, 0, SEEK_CUR);
}

void FileReader::setPos(UInt32Value position)
{
    lseek(descriptor_, position, SEEK_SET);
}

UInt32Value FileReader::endPos()
{
    // ToDo : cannot stat on stream ?
    struct stat stat;
    fstat(descriptor_, &stat);
    return stat.st_size;
}

UInt32Value FileReader::verifyPos()
{
    return getPos();
}

void FileReader::close()
{
    if(BOOLVALUE_FALSE == DontClose_){
        ::close(descriptor_);
    }
}

int FileReader::ioDesc()
{
    return descriptor_;// ToDo : cannot get descriptor from stream ?
}

UInt32Value FileReader::getAvailableOperations()
{
    return 0xFFFFFFFF;
}

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
