#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <dirent.h>
#include <errno.h>
#if defined(HAVE_POLL_H)
#include <poll.h>
#endif
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <utime.h>
#if defined(__MINGW32__) || defined(__CYGWIN32__)
# include <windows.h>
#endif

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

typedef int FILE_DESCRIPTOR;

void
raiseSysErr()
{
    int errorNumber = errno;
    char* message = ::strerror(errorNumber);
    if(0 == message){message = "Unknown system error number";}
    DBGWRAP(printf("raiseSysErr: %s \n", message);)
    errno = 0;

    Cell exception =
    PrimitiveSupport::constructExnSysErr(errorNumber, message);
    VirtualMachine::getInstance()->setPrimitiveException(exception);
}

void
raiseFail(const char* message)
{
    DBGWRAP(printf("raiseFail: %s \n", message);)

    Cell exception = PrimitiveSupport::constructExnFail(message);
    VirtualMachine::getInstance()->setPrimitiveException(exception);
}

// int -> string
void
IMLPrim_GenericOS_errorNameImpl(UInt32Value argsCount,
                                Cell* argumentRefs[],
                                Cell* resultRef)
{
    // Only errors which are defined in both Posix and Cygwin are handled.
    // For example, ECANCELED is not handled because the Cygwin does not
    // define it, although the Posix defines.

    SInt32Value error = argumentRefs[0]->sint32;
    char* name;
    switch(error){
      case EACCES:{name = "acces"; break;}
      case EAGAIN:{name = "again"; break;}
      case EBADF:{name = "badf"; break;}
#ifdef EBADMSG
      case EBADMSG:{name = "badmsg"; break;}
#endif
      case EBUSY:{name = "busy"; break;}
/*
      case ECANCELED:{name = "canceled"; break;}
*/
      case ECHILD:{name = "child"; break;}
#ifdef EDEADLK
      case EDEADLK:{name = "deadlk"; break;}
#endif
      case EDOM:{name = "dom"; break;}
      case EEXIST:{name = "exist"; break;}
      case EFAULT:{name = "fault"; break;}
      case EFBIG:{name = "fbig"; break;}
#ifdef EINPROGRESS
      case EINPROGRESS:{name = "inprogress"; break;}
#endif
      case EINTR:{name = "intr"; break;}
      case EINVAL:{name = "inval"; break;}
      case EIO:{name = "io"; break;}
      case EISDIR:{name = "isdir"; break;}
#ifdef ELOOP
      case ELOOP:{name = "loop"; break;}
#endif
      case EMFILE:{name = "mfile"; break;}
      case EMLINK:{name = "mlink"; break;}
#ifdef EMSGSIZE
      case EMSGSIZE:{name = "msgsize"; break;}
#endif
      case ENAMETOOLONG:{name = "nametoolong"; break;}
      case ENFILE:{name = "nfile"; break;}
      case ENODEV:{name = "nodev"; break;}
      case ENOENT:{name = "noent"; break;}
      case ENOEXEC:{name = "noexec"; break;}
#ifdef ENOLCK
      case ENOLCK:{name = "nolck"; break;}
#endif
      case ENOMEM:{name = "nomem"; break;}
      case ENOSPC:{name = "nospc"; break;}
#ifdef ENOSYS
      case ENOSYS:{name = "nosys"; break;}
#endif
      case ENOTDIR:{name = "notdir"; break;}
      case ENOTEMPTY:{name = "notempty"; break;}
#ifdef ENOTSUP
      case ENOTSUP:{name = "notsup"; break;}
#endif
      case ENOTTY:{name = "notty"; break;}
      case ENXIO:{name = "nxio"; break;}
      case EPERM:{name = "perm"; break;}
      case EPIPE:{name = "pipe"; break;}
      case ERANGE:{name = "range"; break;}
      case EROFS:{name = "rofs"; break;}
      case ESPIPE:{name = "spipe"; break;}
      case ESRCH:{name = "srch"; break;}
      case E2BIG:{name = "toobig"; break;}
      case EXDEV:{name = "xdev"; break;}
      default:{name = "unknown"; break;}
    }
    *resultRef = PrimitiveSupport::stringToCell(name);
    return;
};

// int -> string
void
IMLPrim_GenericOS_errorMsgImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    SInt32Value error = argumentRefs[0]->sint32;
    char* message = ::strerror(error);
    if(0 == message){message = "Unknown error number";}
    *resultRef = PrimitiveSupport::stringToCell(message);
    return;
};

// string -> (int) option
void
IMLPrim_GenericOS_syserrorImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    char* name = PrimitiveSupport::cellToString(*argumentRefs[0]);
    int errorNumber =
    (0 == strcmp(name, "acces")) ? EACCES 
    : (0 == strcmp(name, "again")) ? EAGAIN 
    : (0 == strcmp(name, "badf")) ? EBADF 
#ifdef EBADMSG 
    : (0 == strcmp(name, "badmsg")) ? EBADMSG 
#endif
    : (0 == strcmp(name, "busy")) ? EBUSY 
/*
    : (0 == strcmp(name, "canceled")) ? ECANCELED 
*/
    : (0 == strcmp(name, "child")) ? ECHILD 
#ifdef EDEADLK
    : (0 == strcmp(name, "deadlk")) ? EDEADLK 
#endif
    : (0 == strcmp(name, "dom")) ? EDOM 
    : (0 == strcmp(name, "exist")) ? EEXIST 
    : (0 == strcmp(name, "fault")) ? EFAULT 
    : (0 == strcmp(name, "fbig")) ? EFBIG 
#ifdef EINPROGRESS
    : (0 == strcmp(name, "inprogress")) ? EINPROGRESS 
#endif
    : (0 == strcmp(name, "intr")) ? EINTR 
    : (0 == strcmp(name, "inval")) ? EINVAL 
    : (0 == strcmp(name, "io")) ? EIO 
    : (0 == strcmp(name, "isdir")) ? EISDIR 
#ifdef ELOOP
    : (0 == strcmp(name, "loop")) ? ELOOP 
#endif
    : (0 == strcmp(name, "mfile")) ? EMFILE 
    : (0 == strcmp(name, "mlink")) ? EMLINK 
#ifdef EMSGSIZE
    : (0 == strcmp(name, "msgsize")) ? EMSGSIZE 
#endif
    : (0 == strcmp(name, "nametoolong")) ? ENAMETOOLONG 
    : (0 == strcmp(name, "nfile")) ? ENFILE 
    : (0 == strcmp(name, "nodev")) ? ENODEV 
    : (0 == strcmp(name, "noent")) ? ENOENT 
    : (0 == strcmp(name, "noexec")) ? ENOEXEC 
#ifdef ENOLCK
    : (0 == strcmp(name, "nolck")) ? ENOLCK 
#endif
    : (0 == strcmp(name, "nomem")) ? ENOMEM 
    : (0 == strcmp(name, "nospc")) ? ENOSPC
#ifdef ENOSYS 
    : (0 == strcmp(name, "nosys")) ? ENOSYS 
#endif
    : (0 == strcmp(name, "notdir")) ? ENOTDIR 
    : (0 == strcmp(name, "notempty")) ? ENOTEMPTY 
#ifdef ENOTSUP
    : (0 == strcmp(name, "notsup")) ? ENOTSUP 
#endif
    : (0 == strcmp(name, "notty")) ? ENOTTY 
    : (0 == strcmp(name, "nxio")) ? ENXIO 
    : (0 == strcmp(name, "perm")) ? EPERM 
    : (0 == strcmp(name, "pipe")) ? EPIPE 
    : (0 == strcmp(name, "range")) ? ERANGE 
    : (0 == strcmp(name, "rofs")) ? EROFS 
    : (0 == strcmp(name, "spipe")) ? ESPIPE 
    : (0 == strcmp(name, "srch")) ? ESRCH 
    : (0 == strcmp(name, "toobig")) ? E2BIG
    : (0 == strcmp(name, "xdev")) ? EXDEV 
    : 0;// ToDo : OK ?

    if(errorNumber){
        Cell errorCell;
        errorCell.sint32 = errorNumber;
        *resultRef = PrimitiveSupport::constructOptionSOME(&errorCell, false);
    }
    else{
        *resultRef = PrimitiveSupport::constructOptionNONE();
    }
    return;
};

void
IMLPrim_GenericOS_getSTDINImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    resultRef->uint32 = (UInt32Value)STDIN_FILENO;
    return;
};

void
IMLPrim_GenericOS_getSTDOUTImpl(UInt32Value argsCount,
                                Cell* argumentRefs[],
                                Cell* resultRef)
{
    resultRef->uint32 = (UInt32Value)STDOUT_FILENO;
    return;
};

void
IMLPrim_GenericOS_getSTDERRImpl(UInt32Value argsCount,
                                Cell* argumentRefs[],
                                Cell* resultRef)
{
    resultRef->uint32 = (UInt32Value)STDERR_FILENO;
    return;
};

void
IMLPrim_GenericOS_fileOpenImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    char* fileName =
    PrimitiveSupport::cellToString(*argumentRefs[0]);
    char* mode = PrimitiveSupport::cellToString(*argumentRefs[1]);
    FILE* file = ::fopen(fileName, mode);
    if(NULL == file){
        raiseSysErr();
        resultRef->uint32 = 0;
    }
    else{
        resultRef->uint32 = (UInt32Value)fileno(file);
    }
    return;
};

void
IMLPrim_GenericOS_fileCloseImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    FILE_DESCRIPTOR file = (FILE_DESCRIPTOR)(argumentRefs[0]->uint32);
    ::close(file);
    *resultRef = PrimitiveSupport::constructUnit();
    return;
};

void
IMLPrim_GenericOS_fileReadImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    // char* fileRead(file, int nbytes)
    FILE_DESCRIPTOR file = (FILE_DESCRIPTOR)(argumentRefs[0]->uint32);
    SInt32Value nBytes = argumentRefs[1]->sint32;
    char buffer[nBytes + 1];
    size_t readBytes = ::read(file, buffer, nBytes);
    // ToDo : check if error occurs
    *resultRef = PrimitiveSupport::byteArrayToCell(buffer, readBytes);
    return;
};

void
IMLPrim_GenericOS_fileReadBufImpl(UInt32Value argsCount,
                                  Cell* argumentRefs[],
                                  Cell* resultRef)
{
    // int fileReadBuf(file, char* buffer, int start, int nbytes)
    FILE_DESCRIPTOR file = (FILE_DESCRIPTOR)(argumentRefs[0]->uint32);
    char* buffer = PrimitiveSupport::cellToString(*argumentRefs[1]);
    SInt32Value start = argumentRefs[2]->sint32;
    SInt32Value nBytes = argumentRefs[3]->sint32;
    size_t readBytes = ::read(file, buffer, nBytes);
    // ToDo : check if error occurs
    *resultRef = PrimitiveSupport::byteArrayToCell(buffer, readBytes);
    resultRef->sint32 = (SInt32Value)readBytes;
    return;
};

void
IMLPrim_GenericOS_fileWriteImpl(UInt32Value argsCount,
                                Cell* argumentRefs[],
                                Cell* resultRef)
{
    // int fileWrite(file, char*, int start, int nbytes)
    FILE_DESCRIPTOR file = (FILE_DESCRIPTOR)(argumentRefs[0]->uint32);
    char* buffer = PrimitiveSupport::cellToString(*argumentRefs[1]);
    SInt32Value start = argumentRefs[2]->sint32;
    SInt32Value nBytes = argumentRefs[3]->sint32;
    size_t writtenBytes;
    switch(file){
      case STDOUT_FILENO:
        writtenBytes = PrimitiveSupport::writeToSTDOUT(nBytes, buffer + start);
        break;
      case STDERR_FILENO:
        writtenBytes = PrimitiveSupport::writeToSTDERR(nBytes, buffer + start);
        break;
      default: 
        writtenBytes = ::write(file, buffer + start, nBytes);
        break;
    }
    // ToDo : check error flag of the stream.
    resultRef->sint32 = (SInt32Value)writtenBytes;
    return;
};

void
IMLPrim_GenericOS_fileSetPositionImpl(UInt32Value argsCount,
                                      Cell* argumentRefs[],
                                      Cell* resultRef)
{
    // int fileSetPosition(file, int)
    FILE_DESCRIPTOR file = (FILE_DESCRIPTOR)(argumentRefs[0]->uint32);
    SInt32Value offset = argumentRefs[1]->sint32;
    if(::lseek(file, offset, SEEK_SET)){
        raiseSysErr();        
    }
    else{
        SInt32Value newOffset = ::lseek(file, 0, SEEK_CUR);
        resultRef->sint32 = newOffset;
    }
    return;
};

void
IMLPrim_GenericOS_fileGetPositionImpl(UInt32Value argsCount,
                                      Cell* argumentRefs[],
                                      Cell* resultRef)
{
    // int fileGetPosition(file)
    FILE_DESCRIPTOR file = (FILE_DESCRIPTOR)(argumentRefs[0]->uint32);
    SInt32Value newOffset = ::lseek(file, 0, SEEK_CUR);
    if(newOffset < 0){
        raiseSysErr();
    }
    else{
        resultRef->sint32 = newOffset;
    }
    return;
};

void
IMLPrim_GenericOS_fileNoImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    // int fileNo(FILE)
    SInt32Value descriptor = (FILE_DESCRIPTOR)(argumentRefs[0]->uint32);
    resultRef->sint32 = descriptor;
    return;
};

void
IMLPrim_GenericOS_fileSizeImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    // int fileSize(file)
    struct stat file_stats;
    SInt32Value descriptor = (FILE_DESCRIPTOR)(argumentRefs[0]->uint32);
    if(::fstat(descriptor, &file_stats)){
        raiseSysErr();
    }
    else{
        resultRef->sint32 = file_stats.st_size;
    }
    return;
};

void
IMLPrim_GenericOS_systemImpl(UInt32Value argsCount,
                             Cell* argumentRefs[],
                             Cell* resultRef)
{
    // int system(char* name)
    char* command = PrimitiveSupport::cellToString(*argumentRefs[0]);
    int result = ::system(command);
    if(result < 0){
        raiseSysErr();
    }
    else{
        resultRef->sint32 = result;
    }
    return;
};

void
IMLPrim_GenericOS_exitImpl(UInt32Value argsCount,
                           Cell* argumentRefs[],
                           Cell* resultRef)
{
    // void exit(int)
    int status = argumentRefs[0]->sint32;
    VirtualMachine::getInstance()->getSession()->sendExitRequest(status);
    ::exit(status);
    // never reach here
    *resultRef = PrimitiveSupport::constructUnit();
    return;
};

void
IMLPrim_GenericOS_getEnvImpl(UInt32Value argsCount,
                             Cell* argumentRefs[],
                             Cell* resultRef)
{
    char* name = PrimitiveSupport::cellToString(*argumentRefs[0]);
    char* value = ::getenv(name);
    if(value){
        Cell valueBlock = PrimitiveSupport::stringToCell(value);
        *resultRef = PrimitiveSupport::constructOptionSOME(&valueBlock, true);
    }
    else{
        *resultRef = PrimitiveSupport::constructOptionNONE();
    }
    return;
};

#if defined(__MINGW32__) || defined(__CYGWIN32__)
#define sleep Sleep
#endif

void
IMLPrim_GenericOS_sleepImpl(UInt32Value argsCount,
                            Cell* argumentRefs[],
                            Cell* resultRef)
{
    // void sleep(unsigned int seconds)
    sleep(argumentRefs[0]->uint32);
    *resultRef = PrimitiveSupport::constructUnit();
    return;
};

// string  -> word
void
IMLPrim_GenericOS_openDirImpl(UInt32Value argsCount,
                              Cell* argumentRefs[],
                              Cell* resultRef)
{
    char* dirName =
    PrimitiveSupport::cellToString(*argumentRefs[0]);
    DIR* dir = ::opendir(dirName);
    if(NULL == dir){
        raiseSysErr();
    }
    else{
        resultRef->uint32 = (UInt32Value)dir;
    }
    return;
}

// word  -> string option
void
IMLPrim_GenericOS_readDirImpl(UInt32Value argsCount,
                              Cell* argumentRefs[],
                              Cell* resultRef)
{
    DIR* dir = (DIR*)(argumentRefs[0]->uint32);
    while(true){
        struct dirent *dirent = ::readdir(dir);
        if(NULL == dirent){
            *resultRef = PrimitiveSupport::constructOptionNONE();
            break;
        }
        /*
         * Basis specification of OS.FileSys.readDir says:
         *   readDir filters out the names corresponding to the current and
         *  parent arcs. 
         */
        if(!strcmp(dirent->d_name, ".") || !strcmp(dirent->d_name, "..")){
            continue;
        }
        Cell nameValue = PrimitiveSupport::stringToCell(dirent->d_name);
        *resultRef = PrimitiveSupport::constructOptionSOME(&nameValue, true);
        break;
    }
    return;
}

// word  -> unit
void
IMLPrim_GenericOS_rewindDirImpl(UInt32Value argsCount,
                                Cell* argumentRefs[],
                                Cell* resultRef)
{
    DIR* dir = (DIR*)(argumentRefs[0]->uint32);
    ::rewinddir(dir);
    *resultRef = PrimitiveSupport::constructUnit();
    return;
}

// word  -> unit
void
IMLPrim_GenericOS_closeDirImpl(UInt32Value argsCount,
                   Cell* argumentRefs[],
                    Cell* resultRef)
{
    DIR* dir = (DIR*)(argumentRefs[0]->uint32);
    ::closedir(dir);
    *resultRef = PrimitiveSupport::constructUnit();
    return;
}

// string  -> unit
void
IMLPrim_GenericOS_chDirImpl(UInt32Value argsCount,
                   Cell* argumentRefs[],
                    Cell* resultRef)
{
    char* dirName = PrimitiveSupport::cellToString(*argumentRefs[0]);
    if(::chdir(dirName)){
        raiseSysErr();
    }
    else{
        VirtualMachine::getInstance()
            ->getSession()->sendChangeDirectoryRequest(dirName);
        *resultRef = PrimitiveSupport::constructUnit();
    }
    return;
}

// int  -> string
void
IMLPrim_GenericOS_getDirImpl(UInt32Value argsCount,
                             Cell* argumentRefs[],
                             Cell* resultRef)
{
    char buffer[FILENAME_MAX];
    if(0 == ::getcwd(buffer, sizeof(buffer))){
        raiseSysErr();
    }
    else{
        *resultRef = PrimitiveSupport::stringToCell(buffer);
    }
    return;
}

#if defined(__MINGW32__)
#define mkdir(name, mode) mkdir(name)
#endif

// string  -> unit
void
IMLPrim_GenericOS_mkDirImpl(UInt32Value argsCount,
                            Cell* argumentRefs[],
                            Cell* resultRef)
{
    char* dirName = PrimitiveSupport::cellToString(*argumentRefs[0]);
    if(::mkdir(dirName, 0777)){
        raiseSysErr();
    }
    *resultRef = PrimitiveSupport::constructUnit();
    return;
}

// string  -> unit
void
IMLPrim_GenericOS_rmDirImpl(UInt32Value argsCount,
                            Cell* argumentRefs[],
                            Cell* resultRef)
{
    char* dirName = PrimitiveSupport::cellToString(*argumentRefs[0]);
    if(::rmdir(dirName)){
        raiseSysErr();
    }
    *resultRef = PrimitiveSupport::constructUnit();
    return;
}

static
struct stat fileStat(const char *path)
{
    struct stat stat;
    if(::stat(path, &stat)){
        raiseSysErr();
    }
    else{
        return stat;
    }
}

static
struct stat fdStat(int fd)
{
    struct stat stat;
    if(::fstat(fd, &stat)){
        raiseSysErr();
    }
    else{
        return stat;
    }
}

// string  -> bool
void
IMLPrim_GenericOS_isDirImpl(UInt32Value argsCount,
                   Cell* argumentRefs[],
                    Cell* resultRef)
{
    char* dirName = PrimitiveSupport::cellToString(*argumentRefs[0]);
    struct stat stat = fileStat(dirName);
    bool isDir = stat.st_mode & S_IFDIR;
    *resultRef = PrimitiveSupport::boolToCell(isDir);
    return;
}

// string  -> bool
void
IMLPrim_GenericOS_isLinkImpl(UInt32Value argsCount,
                             Cell* argumentRefs[],
                             Cell* resultRef)
{
    // ToDo : how can we judge whether the file is link or not ?
    *resultRef = PrimitiveSupport::boolToCell(false);
    return;
}

// string  -> string
void
IMLPrim_GenericOS_readLinkImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    *resultRef = *argumentRefs[0];
    return;
}

// string  -> int
void
IMLPrim_GenericOS_getFileModTimeImpl(UInt32Value argsCount,
                                     Cell* argumentRefs[],
                                     Cell* resultRef)
{
    char* name = PrimitiveSupport::cellToString(*argumentRefs[0]);
    struct stat stat = fileStat(name);
/*
    int seconds = ::stime(&stat.st_mtime);
*/
    int seconds = 0;// ToDo : cygwin does not provide stime.
    resultRef->sint32 = seconds;
    return;
}

// string * int  -> unit
void
IMLPrim_GenericOS_setFileTimeImpl(UInt32Value argsCount,
                                  Cell* argumentRefs[],
                                  Cell* resultRef)
{
    char* name = PrimitiveSupport::cellToString(*argumentRefs[0]);
    int seconds = argumentRefs[1]->sint32;
    struct utimbuf utimebuf;
    utimebuf.actime = seconds;
    utimebuf.modtime = seconds;
    if(::utime(name, &utimebuf)){
        raiseSysErr();
    }
    else{
        *resultRef = PrimitiveSupport::constructUnit();
    }
    return;
}

// string  -> int
void
IMLPrim_GenericOS_getFileSizeImpl(UInt32Value argsCount,
                                  Cell* argumentRefs[],
                                  Cell* resultRef)
{
    char* name = PrimitiveSupport::cellToString(*argumentRefs[0]);
    struct stat stat = fileStat(name);
    resultRef->sint32 = stat.st_size;
    return;
}

// string  -> unit
void
IMLPrim_GenericOS_removeImpl(UInt32Value argsCount,
                             Cell* argumentRefs[],
                             Cell* resultRef)
{
    char* name = PrimitiveSupport::cellToString(*argumentRefs[0]);
    if(::unlink(name)){
        raiseSysErr();
    }
    else{
        *resultRef = PrimitiveSupport::constructUnit();
    }
    return;
}

// string * string  -> unit
void
IMLPrim_GenericOS_renameImpl(UInt32Value argsCount,
                             Cell* argumentRefs[],
                             Cell* resultRef)
{
    char* oldName = PrimitiveSupport::cellToString(*argumentRefs[0]);
    char* newName = PrimitiveSupport::cellToString(*argumentRefs[1]);
    if(::rename(oldName, newName)){
        raiseSysErr();
    }
    else{
        *resultRef = PrimitiveSupport::constructUnit();
    }
    return;
}

// string  -> bool
void
IMLPrim_GenericOS_isFileExistsImpl(UInt32Value argsCount,
                                   Cell* argumentRefs[],
                                   Cell* resultRef)
{
    char* name = PrimitiveSupport::cellToString(*argumentRefs[0]);
    // assume that fileStat raises an error if the file does not exist.
    struct stat stat = fileStat(name);
    *resultRef = PrimitiveSupport::boolToCell(true);
    return;
}

// string  -> bool
void
IMLPrim_GenericOS_isFileReadableImpl(UInt32Value argsCount,
                                     Cell* argumentRefs[],
                                     Cell* resultRef)
{
    char* name = PrimitiveSupport::cellToString(*argumentRefs[0]);
    struct stat stat = fileStat(name);
    *resultRef = PrimitiveSupport::boolToCell(S_IRUSR & stat.st_mode);
    return;
}

// string  -> bool
void
IMLPrim_GenericOS_isFileWritableImpl(UInt32Value argsCount,
                                     Cell* argumentRefs[],
                                     Cell* resultRef)
{
    char* name = PrimitiveSupport::cellToString(*argumentRefs[0]);
    struct stat stat = fileStat(name);
    *resultRef = PrimitiveSupport::boolToCell(S_IWUSR & stat.st_mode);
    return;
}

// string  -> bool
void
IMLPrim_GenericOS_isFileExecutableImpl(UInt32Value argsCount,
                                       Cell* argumentRefs[],
                                       Cell* resultRef)
{
    char* name = PrimitiveSupport::cellToString(*argumentRefs[0]);
    struct stat stat = fileStat(name);
    *resultRef = PrimitiveSupport::boolToCell(S_IXUSR & stat.st_mode);
    return;
}

// unit  -> string
void
IMLPrim_GenericOS_tempFileNameImpl(UInt32Value argsCount,
                                   Cell* argumentRefs[],
                                   Cell* resultRef)

{
    char* name = ::tmpnam(NULL);
    *resultRef = PrimitiveSupport::stringToCell(name);
    return;
}

// string  -> word
void
IMLPrim_GenericOS_getFileIDImpl(UInt32Value argsCount,
                                Cell* argumentRefs[],
                                Cell* resultRef)
{
    char* name = PrimitiveSupport::cellToString(*argumentRefs[0]);
    struct stat stat = fileStat(name);
    // this is temporary solution.
    // It can be possible that the same id is generated for multiple files.
    resultRef->sint32 = stat.st_ino | (stat.st_dev << 24);
    return;
}

// word  -> bool
void
IMLPrim_GenericOS_isRegFDImpl(UInt32Value argsCount,
                              Cell* argumentRefs[],
                              Cell* resultRef)
{
    UInt32Value fd = argumentRefs[0]->uint32;
    struct stat stat = fdStat(fd);
    *resultRef = PrimitiveSupport::boolToCell(S_IFREG & stat.st_mode);
    return;
}

// word  -> bool
void
IMLPrim_GenericOS_isDirFDImpl(UInt32Value argsCount,
                              Cell* argumentRefs[],
                              Cell* resultRef)
{
    UInt32Value fd = argumentRefs[0]->uint32;
    struct stat stat = fdStat(fd);
    *resultRef = PrimitiveSupport::boolToCell(S_IFDIR & stat.st_mode);
    return;
}

// word  -> bool
void
IMLPrim_GenericOS_isChrFDImpl(UInt32Value argsCount,
                              Cell* argumentRefs[],
                              Cell* resultRef)
{
    UInt32Value fd = argumentRefs[0]->uint32;
    struct stat stat = fdStat(fd);
    *resultRef = PrimitiveSupport::boolToCell(S_IFCHR & stat.st_mode);
    return;
}

// word  -> bool
void
IMLPrim_GenericOS_isBlkFDImpl(UInt32Value argsCount,
                              Cell* argumentRefs[],
                              Cell* resultRef)
{
    UInt32Value fd = argumentRefs[0]->uint32;
    struct stat stat = fdStat(fd);
    *resultRef = PrimitiveSupport::boolToCell(S_IFBLK & stat.st_mode);
    return;
}

// word  -> bool
void
IMLPrim_GenericOS_isLinkFDImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    // ToDo : how can we judge the fd is link or not ?
    *resultRef = PrimitiveSupport::boolToCell(false);
    return;
}

// word  -> bool
void
IMLPrim_GenericOS_isFIFOFDImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    UInt32Value fd = argumentRefs[0]->uint32;
    struct stat stat = fdStat(fd);
    *resultRef = PrimitiveSupport::boolToCell(S_IFIFO & stat.st_mode);
    return;
}

// word  -> bool
void
IMLPrim_GenericOS_isSockFDImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    // ToDo : how can we judge the fd is socket or not ?
    *resultRef = PrimitiveSupport::boolToCell(false);
    return;
}

// ((int * word) list * (int * int) option)  -> (int * word) list
void
IMLPrim_GenericOS_pollImpl(UInt32Value argsCount,
                           Cell* argumentRefs[],
                           Cell* resultRef)
{
#if defined(HAVE_POLL_H)
    // extract the first argument
    Cell pollDescList = *argumentRefs[0];
    int pollDescListLength = PrimitiveSupport::cellToListLength(pollDescList);
    struct pollfd fds[pollDescListLength];
    Cell head;
    Cell tail = pollDescList;
    for(int index = 0; index < pollDescListLength; index += 1)
    {
        assert(0 != tail.uint32);
        PrimitiveSupport::cellToListGetItem(tail, &head, &tail);
        Cell pollDescElements[2];
        PrimitiveSupport::cellToTupleElements(head, pollDescElements, 2);
        fds[index].fd = pollDescElements[0].sint32;
        fds[index].events = (short)(pollDescElements[1].uint32);
        fds[index].revents = (short)0;
    }

    // extract the second argument
    Cell timeOutOption = *argumentRefs[1];
    Cell timeOut;
    int optionTag = PrimitiveSupport::cellToOption(timeOutOption, &timeOut);
    int timeOutMilliSeconds;
    if(TAG_option_SOME == optionTag){
        Cell timeOutElements[2];
        PrimitiveSupport::cellToTupleElements(timeOut, timeOutElements, 2);
        int seconds = timeOutElements[0].sint32;
        int microSeconds = timeOutElements[1].sint32;// not used.
        timeOutMilliSeconds = seconds * 1000;
    }
    else{
        timeOutMilliSeconds = -1; // wait indefinitely
    }

    // third argument is milli-secs.
    int numberOfChanged = ::poll(fds, pollDescListLength, timeOutMilliSeconds);
    if(numberOfChanged < 0){
        raiseSysErr();
        return;
    }

    //  constructs a list including only the elements whose conditions are
    // enabled.
    Cell resultList = PrimitiveSupport::constructListNil();
    for(int index = 0; index < pollDescListLength; index += 1){
        short revents = fds[index].revents;
        if(revents){
            Cell elements[2];
            elements[0].sint32 = fds[index].fd;
            elements[1].uint32 = revents;
            Cell tuple = PrimitiveSupport::tupleElementsToCell(elements, 2);
            resultList =
            PrimitiveSupport::constructListCons(&tuple, &resultList, true);
        }
    }
    *resultRef = resultList;
    
    return;
#else /* HAVE_POLL_H */
    raiseFail("poll is not implemented.");
    return;
#endif 
}

// int -> word
void 
IMLPrim_GenericOS_getPOLLINFlagImpl(UInt32Value argsCount,
                                    Cell* argumentRefs[],
                                    Cell* resultRef)
{
#if defined(HAVE_POLL_H)
    resultRef->uint32 = POLLIN;
    return;
#else /* HAVE_POLL_H */
    resultRef->uint32 = -1;
//    raiseFail("getPOLLINFlag is not implemented.");
    return;
#endif 
}

// int -> word
void 
IMLPrim_GenericOS_getPOLLOUTFlagImpl(UInt32Value argsCount,
                                     Cell* argumentRefs[],
                                     Cell* resultRef)
{
#if defined(HAVE_POLL_H)
    resultRef->uint32 = POLLOUT;
    return;
#else /* HAVE_POLL_H */
    resultRef->uint32 = -1;
//    raiseFail("getPOLLOUTFlag is not implemented.");
    return;
#endif 
}

// int -> word
void 
IMLPrim_GenericOS_getPOLLPRIFlagImpl(UInt32Value argsCount,
                                     Cell* argumentRefs[],
                                     Cell* resultRef)
{
#if defined(HAVE_POLL_H)
    resultRef->uint32 = POLLPRI;
    return;
#else /* HAVE_POLL_H */
    resultRef->uint32 = -1;
//    raiseFail("getPOLLPRIFlag is not implemented.");
    return;
#endif 
}

////////////////////////////////////////

Primitive IMLPrim_GenericOS_errorName = IMLPrim_GenericOS_errorNameImpl;
Primitive IMLPrim_GenericOS_errorMsg = IMLPrim_GenericOS_errorMsgImpl;
Primitive IMLPrim_GenericOS_syserror = IMLPrim_GenericOS_syserrorImpl;

Primitive IMLPrim_GenericOS_getSTDIN = IMLPrim_GenericOS_getSTDINImpl;
Primitive IMLPrim_GenericOS_getSTDOUT = IMLPrim_GenericOS_getSTDOUTImpl;
Primitive IMLPrim_GenericOS_getSTDERR = IMLPrim_GenericOS_getSTDERRImpl;
Primitive IMLPrim_GenericOS_fileOpen = IMLPrim_GenericOS_fileOpenImpl;
Primitive IMLPrim_GenericOS_fileClose = IMLPrim_GenericOS_fileCloseImpl;
Primitive IMLPrim_GenericOS_fileRead = IMLPrim_GenericOS_fileReadImpl;
Primitive IMLPrim_GenericOS_fileReadBuf = IMLPrim_GenericOS_fileReadBufImpl;
Primitive IMLPrim_GenericOS_fileWrite = IMLPrim_GenericOS_fileWriteImpl;
Primitive IMLPrim_GenericOS_fileSetPosition =
IMLPrim_GenericOS_fileSetPositionImpl;
Primitive IMLPrim_GenericOS_fileGetPosition =
IMLPrim_GenericOS_fileGetPositionImpl;
Primitive IMLPrim_GenericOS_fileNo = IMLPrim_GenericOS_fileNoImpl;
Primitive IMLPrim_GenericOS_fileSize = IMLPrim_GenericOS_fileSizeImpl;
Primitive IMLPrim_GenericOS_system = IMLPrim_GenericOS_systemImpl;
Primitive IMLPrim_GenericOS_exit = IMLPrim_GenericOS_exitImpl;
Primitive IMLPrim_GenericOS_getEnv = IMLPrim_GenericOS_getEnvImpl;
Primitive IMLPrim_GenericOS_sleep = IMLPrim_GenericOS_sleepImpl;
Primitive IMLPrim_GenericOS_openDir = IMLPrim_GenericOS_openDirImpl;
Primitive IMLPrim_GenericOS_readDir = IMLPrim_GenericOS_readDirImpl;
Primitive IMLPrim_GenericOS_rewindDir = IMLPrim_GenericOS_rewindDirImpl;
Primitive IMLPrim_GenericOS_closeDir = IMLPrim_GenericOS_closeDirImpl;
Primitive IMLPrim_GenericOS_chDir = IMLPrim_GenericOS_chDirImpl;
Primitive IMLPrim_GenericOS_getDir = IMLPrim_GenericOS_getDirImpl;
Primitive IMLPrim_GenericOS_mkDir = IMLPrim_GenericOS_mkDirImpl;
Primitive IMLPrim_GenericOS_rmDir = IMLPrim_GenericOS_rmDirImpl;
Primitive IMLPrim_GenericOS_isDir = IMLPrim_GenericOS_isDirImpl;
Primitive IMLPrim_GenericOS_isLink = IMLPrim_GenericOS_isLinkImpl;
Primitive IMLPrim_GenericOS_readLink = IMLPrim_GenericOS_readLinkImpl;
Primitive IMLPrim_GenericOS_getFileModTime =
IMLPrim_GenericOS_getFileModTimeImpl;
Primitive IMLPrim_GenericOS_setFileTime = IMLPrim_GenericOS_setFileTimeImpl;
Primitive IMLPrim_GenericOS_getFileSize = IMLPrim_GenericOS_getFileSizeImpl;
Primitive IMLPrim_GenericOS_remove = IMLPrim_GenericOS_removeImpl;
Primitive IMLPrim_GenericOS_rename = IMLPrim_GenericOS_renameImpl;
Primitive IMLPrim_GenericOS_isFileExists = IMLPrim_GenericOS_isFileExistsImpl;
Primitive IMLPrim_GenericOS_isFileReadable =
IMLPrim_GenericOS_isFileReadableImpl;
Primitive IMLPrim_GenericOS_isFileWritable =
IMLPrim_GenericOS_isFileWritableImpl;
Primitive IMLPrim_GenericOS_isFileExecutable =
IMLPrim_GenericOS_isFileExecutableImpl;
Primitive IMLPrim_GenericOS_tempFileName = IMLPrim_GenericOS_tempFileNameImpl;
Primitive IMLPrim_GenericOS_getFileID = IMLPrim_GenericOS_getFileIDImpl;
Primitive IMLPrim_GenericOS_isRegFD = IMLPrim_GenericOS_isRegFDImpl;
Primitive IMLPrim_GenericOS_isDirFD = IMLPrim_GenericOS_isDirFDImpl;
Primitive IMLPrim_GenericOS_isChrFD = IMLPrim_GenericOS_isChrFDImpl;
Primitive IMLPrim_GenericOS_isBlkFD = IMLPrim_GenericOS_isBlkFDImpl;
Primitive IMLPrim_GenericOS_isLinkFD = IMLPrim_GenericOS_isLinkFDImpl;
Primitive IMLPrim_GenericOS_isFIFOFD = IMLPrim_GenericOS_isFIFOFDImpl;
Primitive IMLPrim_GenericOS_isSockFD = IMLPrim_GenericOS_isSockFDImpl;
Primitive IMLPrim_GenericOS_poll = IMLPrim_GenericOS_pollImpl;
Primitive IMLPrim_GenericOS_getPOLLINFlag =
IMLPrim_GenericOS_getPOLLINFlagImpl;
Primitive IMLPrim_GenericOS_getPOLLOUTFlag =
IMLPrim_GenericOS_getPOLLOUTFlagImpl;
Primitive IMLPrim_GenericOS_getPOLLPRIFlag =
IMLPrim_GenericOS_getPOLLPRIFlagImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
