/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: main.cc,v 1.27.4.1 2007/03/26 11:16:14 katsu Exp $
 */
/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: main.cc,v 1.27.4.1 2007/03/26 11:16:14 katsu Exp $
 */
#include "main.hh"

#ifndef O_BINARY
#define O_BINARY 0
#endif

#ifdef USE_NAMESPACE
using namespace jp_ac_jaist_iml_runtime;
#endif

///////////////////////////////////////////////////////////////////////////////

Session* session_ = 0;

///////////////////////////////////////////////////////////////////////////////

void
usage(const char* exeName){
    fprintf(stderr,
            "usage : %s [-heap heapsize] [-stack heapsize] -file filename\n"
            "        %s [-heap heapsize] [-stack heapsize] -client port\n"
            "        %s [-heap heapsize] [-stack heapsize] -server port\n"
            "        %s [-heap heapsize] [-stack heapsize] -pipe infd outfd\n",
            exeName, exeName, exeName, exeName);
    exit(1);
}

///////////////////////////////////////////////////////////////////////////////

enum ChannelType{
  CHANNEL_TYPE_UNSPECIFIED,
  CHANNEL_TYPE_FILE,
  CHANNEL_TYPE_SERVER_SOCKET,
  CHANNEL_TYPE_CLIENT_SOCKET,
  CHANNEL_TYPE_PIPE
};

/**
 * discard a header line of the file if it starts with "#!".
 */
void
skipMagicNumberHeaderLine(int fd)
{
    char bytes[2];
    if(2 != ::read(fd, bytes, 2)){
        // ToDo : throw a correct exception.
        ::fprintf(stderr, "wrong format file.");
        return;
    }
    
    if(('#' == bytes[0]) && ('!' == bytes[1])){
        char byte = 0;
        ::read(fd, &byte, 1);
        while('\n' != byte){
            if(0 == ::read(fd, &byte, 1)){
                // ToDo : throw a correct exception.
                ::fprintf(stderr, "wrong format file.");
                break;
            }
        }
    }
    else{
        ::lseek(fd, 0, SEEK_SET);
    }
}

int
main(int argc, const char** argv)
{
    DBGWRAP(FileLogFacade::setup(stdout));

    if(argc < 2){
        usage(argv[0]);
    }
    int heapSize = 4096000; // default 
    int stackSize = 4096000; // default

//    ChannelType channelType = CHANNEL_TYPE_UNSPECIFIED;
    ChannelType channelType = CHANNEL_TYPE_FILE;// use file default.

    const char** nextArg = argv + 1;
    const char** lastArg = argv + argc;
    while(nextArg < lastArg){
        if(0 == strcmp("-heap", nextArg[0])){
            nextArg += 1;
            if(0 == nextArg[0]){ usage(argv[0]); }
            heapSize = atol(nextArg[0]);
        }
        else if(0 == strcmp("-stack", nextArg[0])){
            nextArg += 1;
            if(0 == nextArg[0]){ usage(argv[0]); }
            stackSize = atol(nextArg[0]);
        }
        else if(0 == strcmp("-file", nextArg[0])){
            channelType = CHANNEL_TYPE_FILE;
        }
        else if(0 == strcmp("-client", nextArg[0])){
#ifdef HAVE_SYS_SOCKET_H
            channelType = CHANNEL_TYPE_CLIENT_SOCKET;
#else
            usage("-client is not supported in this platform.");
#endif
        }
        else if(0 == strcmp("-server", nextArg[0])){
#ifdef HAVE_SYS_SOCKET_H
            channelType = CHANNEL_TYPE_SERVER_SOCKET;
#else
            usage("-server is not supported in this platform.");
#endif
        }
        else if(0 == strcmp("-pipe", nextArg[0])){
            channelType = CHANNEL_TYPE_PIPE;
        }
        else{
            break;
        }
        nextArg += 1;
    }
    if(0 == nextArg[0]){ usage(argv[0]); }
    if(CHANNEL_TYPE_UNSPECIFIED == channelType){ usage(argv[0]); }

    /*
     * The socket channel type is used only in Windows platform.
     * Because SML/NJ for Windows does not provide unsynchronized exec,
     * the runtime implements it by spawning a copy process and exiting itself.
     * But, this strategy is not beautiful...
     */
    if((CHANNEL_TYPE_SERVER_SOCKET == channelType)
       || (CHANNEL_TYPE_CLIENT_SOCKET == channelType)){
#if defined(HAVE_FORK)
        if(fork()){
            exit(0);
        }
#endif
    }

    ////////////////////////////////////////

    FileDescriptor executableFileDesc = 0;
    int serverSocket = 0;
    int	acceptedSocket = 0;
    int clientSocket = 0;

    FileInputChannel* executableChannel = 0;
    ServerSocketChannel* serverSocketChannel = 0;
    ClientSocketChannel* clientSocketChannel = 0;

    FileDescriptor inFD = 0;
    FileDescriptor outFD = 0;
    InputChannel* inputChannel = 0;
    OutputChannel* outputChannel = 0;

    switch(channelType){
      case CHANNEL_TYPE_FILE:
        {
            const char* executableFileName = nextArg[0];
            nextArg += 1;

            executableFileDesc = open(executableFileName, O_RDONLY | O_BINARY);
            if(executableFileDesc < 0){
                perror(executableFileName);
                exit(1);
            }

            skipMagicNumberHeaderLine(executableFileDesc);

            executableChannel = new FileInputChannel(executableFileDesc);
            session_ = new StandAloneSession(executableChannel);
            break;
        }
#ifdef HAVE_SYS_SOCKET_H
      case CHANNEL_TYPE_SERVER_SOCKET:
        {
            int port = atoi(nextArg[0]);
            nextArg += 1;

            socklen_t clilen;
            struct sockaddr_in cli_addr, serv_addr;
            int one = 1;
            int nofork = 0;

            /*
             *  If the counterpart of socket shuts down the connection in
             * the mid of communication, SIGPIPE is sent to this process.
             * We ignore this signal. Error can be detected by the return-
             * value of 'write' system call.
             */
            signal(SIGPIPE, SIG_IGN);
    
            if ((serverSocket = socket(AF_INET, SOCK_STREAM, 0)) < 0){
                fprintf(stderr, "socket failed.");
                exit(1);
            }

            /*
             *  By set the SO_REUSEADDR option, we can restart this server
             * immediately.
             */
            if(-1 ==
               (setsockopt(serverSocket,
                           SOL_SOCKET,
                           SO_REUSEADDR,
                           (char *)&one,
                           sizeof(one))))
            {
                perror("setsockopt failed.");
                exit(1);
            }

            bzero((char *)&serv_addr, sizeof(serv_addr));
            serv_addr.sin_family = AF_INET;
            serv_addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
            serv_addr.sin_port = htons(port);

            if (bind(serverSocket,
                     (struct sockaddr *)&serv_addr,
                     sizeof(serv_addr)) < 0)
            {
                perror("bind fail");
                exit(1);
            }

            listen(serverSocket, 5);

            clilen = sizeof(cli_addr);
            acceptedSocket =
            accept(serverSocket, (struct sockaddr *)&cli_addr, &clilen);

            serverSocketChannel = new ServerSocketChannel(acceptedSocket);
            session_ =
            new InteractiveSession(serverSocketChannel, serverSocketChannel);
            break;
        }
      case CHANNEL_TYPE_CLIENT_SOCKET:
        {
            int port = atoi(nextArg[0]);
            nextArg += 1;

            socklen_t servlen;
            struct sockaddr_in serv_addr;

            /*
             *  If the counterpart of socket shuts down the connection in
             * the mid of communication, SIGPIPE is sent to this process.
             * We ignore this signal. Error can be detected by the return-
             * value of 'write' system call.
             */
            signal(SIGPIPE, SIG_IGN);
    
            if ((clientSocket = socket(AF_INET, SOCK_STREAM, 0)) < 0){
                fprintf(stderr, "socket failed.");
                exit(1);
            }

            bzero((char *)&serv_addr, sizeof(serv_addr));
            serv_addr.sin_family = AF_INET;
            serv_addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
            serv_addr.sin_port = htons(port);
    
            if(connect(clientSocket,
                       (struct sockaddr *)&serv_addr,
                       sizeof(serv_addr)) < 0)
            {
                fprintf(stderr, "connect failed.");
                exit(1);
            }

            clientSocketChannel = new ClientSocketChannel(clientSocket);
            session_ =
            new InteractiveSession(clientSocketChannel, clientSocketChannel);
            break;
        }
#endif
    case CHANNEL_TYPE_PIPE:
        {
            const char* inFDString = nextArg[0];
            const char* outFDString = nextArg[1];
            nextArg += 2;

            inFD = atoi(inFDString);
            outFD = atoi(outFDString);
            inputChannel = new FileInputChannel(inFD);
            outputChannel = new FileOutputChannel(outFD);
            session_ = new InteractiveSession(inputChannel, outputChannel);
            break;
        }
      default:
        {
            fprintf(stderr, "unsupported channel type.\n");
            exit(1);
        }
    }

    ////////////////////////////////////////

    if(CHANNEL_TYPE_FILE != channelType){
        signal(SIGINT, SIG_IGN);
    }

    ////////////////////////////////////////

    DBGWRAP(printf("heapSize = %d, stackSize = %d\n", heapSize, stackSize);)
    DBGWRAP(printf("argc = %d, nextArg - argv = %d\n", argc, nextArg - argv);)

    Heap::initialize(heapSize);
    VirtualMachine vm(argv[0], argc - (nextArg - argv), nextArg, stackSize);
    Heap::setRootSet(&vm);
    Heap::setFinalizerExecutor(&vm);
    VirtualMachine::setSession(session_);

    FFI::init();

#ifdef IML_ENABLE_EXECUTION_MONITORING
    InstructionTracer instructionTracer;
    {
        DBGWRAP(printf("execution monitoring is enabled.\n");)
        char* envValue = getenv(IML_ENV_ENABLE_INSTTRACE);
        DBGWRAP(printf("getenv(%s) = %s\n",
                       IML_ENV_ENABLE_INSTTRACE,
                       envValue ? envValue : "(null)");)
        if(envValue && (0 == strcmp(envValue, "yes")))
        {
            DBGWRAP(printf("enable instTrace\n");)
            InstructionTracer::_enableTrace = true;
        }
        if(InstructionTracer::_enableTrace){
            VirtualMachine::addExecutionMonitor
            ((VirtualMachineExecutionMonitor*)&instructionTracer);
        }
    }
#endif

#ifdef IML_ENABLE_ALLOCATION_MONITORING
    HeapAllocationTracer allocationTracer;
    {
        DBGWRAP(printf("heap allocation monitoring is enabled.\n");)
        char* envValue = getenv(IML_ENV_ENABLE_ALLOCTRACE);
        DBGWRAP(printf("getenv(%s) = %s\n",
                       IML_ENV_ENABLE_ALLOCTRACE,
                       envValue ? envValue : "(null)");)
        if(envValue && (0 == strcmp(envValue, "yes")))
        {
            DBGWRAP(printf("enable allocationTrace\n");)
            HeapAllocationTracer::_enableTrace = true;
        }
        if(HeapAllocationTracer::_enableTrace){
            Heap::addMonitor((HeapMonitor*)&allocationTracer);
        }
    }
#endif

    ExecutableLinker linker;
    session_->addExecutablePreProcessor(&linker);

    int exitCode;
    try{
        exitCode = session_->start();
    }
    catch(IMLException& exception){ fprintf(stderr, exception.what()); }

    ////////////////////////////////////////

    delete session_;
    FFI::finalize();

    if(executableChannel){ delete executableChannel; }
    if(executableFileDesc){ close(executableFileDesc); }

    if(serverSocketChannel){ delete serverSocketChannel; }
    if(serverSocket){ close(serverSocket); }
    if(acceptedSocket){ close(acceptedSocket); }

    if(inFD){ close(inFD); }
    if(outFD){ close(outFD); }
    if(inputChannel){ delete inputChannel; }
    if(outputChannel){ delete outputChannel; }

    ////////////////////////////////////////

#ifdef IML_ENABLE_ALLOCATION_MONITORING
    printf("allocated fields: %d\n", allocationTracer._allocatedFields);
#endif

    return exitCode;
}

///////////////////////////////////////////////////////////////////////////////
