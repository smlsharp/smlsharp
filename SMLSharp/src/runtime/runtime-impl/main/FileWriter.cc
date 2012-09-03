#include "FileWriter.hh"
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <unistd.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

FileWriter::
FileWriter(const char* fileName, int descriptor, BoolValue DontClose)
    :Writer(),
     fileName_(fileName),
     descriptor_(descriptor),
     DontClose_(DontClose)
{
}

FileWriter::~FileWriter()
{
}

const char*
FileWriter::getName()
{
    return fileName_;
}

UInt32Value
FileWriter::getChunkSize()
{
    return 1;// ???
}

UInt32Value
FileWriter::write(UInt32Value length, const ByteValue* buffer)
{
    const ByteValue* currentPosition = buffer;
    int	leftLength;
    int writtenLength;

    leftLength = length;
    while (leftLength > 0) {
        writtenLength = ::write(descriptor_, currentPosition, leftLength);
        if(writtenLength <= 0){
            return(writtenLength);
        }
        
        leftLength -= writtenLength;
        currentPosition += writtenLength;
    }
    return(length - leftLength);
}

UInt32Value
FileWriter::writeNB(UInt32Value length, const ByteValue* buffer)
{
    return 0; // not implemented
}

void FileWriter::block()
{
    // not implemented
}

BoolValue FileWriter::canOutput()
{
    return BOOLVALUE_TRUE;
}

UInt32Value FileWriter::getPos()
{
    return lseek(descriptor_, 0, SEEK_CUR);
}

void FileWriter::setPos(UInt32Value position)
{
    lseek(descriptor_, position, SEEK_SET);
}

UInt32Value FileWriter::endPos()
{
    // ToDo : cannot stat on stream ?
    struct stat stat;
    fstat(descriptor_, &stat);
    return stat.st_size;
}

UInt32Value FileWriter::verifyPos()
{
    return getPos();
}

void FileWriter::close()
{
    if(BOOLVALUE_FALSE == DontClose_){
        ::close(descriptor_);
    }
}

int FileWriter::ioDesc()
{
    return descriptor_;// ToDo : cannot get descriptor from stream ?
}

UInt32Value FileWriter::getAvailableOperations()
{
    return 0xFFFFFFFF;
}

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
