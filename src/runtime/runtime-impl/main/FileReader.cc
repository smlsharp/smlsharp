#include "FileReader.hh"
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

FileReader::
FileReader(const char* fileName, FILE* stream, BoolValue DontClose)
    :Reader(),
     fileName_(fileName),
     stream_(stream),
     DontClose_(DontClose)
{
    descriptor_ = fileno(stream);
}

FileReader::
FileReader(const char* fileName, int descriptor, BoolValue DontClose)
    :Reader(),
     fileName_(fileName),
     descriptor_(descriptor),
     DontClose_(DontClose)
{
    stream_ = fdopen(descriptor, "rb");
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
    return fread(buffer, 1, length, stream_);
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
    return feof(stream_) ? BOOLVALUE_FALSE : BOOLVALUE_TRUE;
}

UInt32Value FileReader::avail()
{
    // not implemented
    return 0xFFFFFFFF;
}

UInt32Value FileReader::getPos()
{
    return ftell(stream_);
}

void FileReader::setPos(UInt32Value position)
{
    fseek(stream_, position, SEEK_SET);
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
        fclose(stream_);
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
