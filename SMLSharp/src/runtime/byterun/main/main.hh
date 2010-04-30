#ifndef main_hh_
#define main_hh_

/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: main.hh,v 1.6 2008/01/11 14:07:41 kiyoshiy Exp $
 */
#include "StandAloneSession.hh"
#include "InteractiveSession.hh"
#include "VirtualMachine.hh"
#include "FFI.hh"
#include "Heap.hh"
#include "ExecutableLinker.hh"
#include "FileLogFacade.hh"
#include "ByteArrayInputChannel.hh"
#include "FileInputChannel.hh"
#include "FileOutputChannel.hh"
#include "ServerSocketChannel.hh"
#include "ClientSocketChannel.hh"
#include "Reader.hh"
#include "Writer.hh"
#include "WordOperations.hh"
#include "IMLException.hh"
#include "Instructions.hh"

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <signal.h>
#ifdef HAVE_SYS_SOCKET_H
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#endif /* HAVE_SYS_SOCKET_H */
#include <strings.h>
#include <ctype.h>
#include <unistd.h>

#define IML_ENV_ENABLE_INSTTRACE "IML_instTrace"
#define IML_ENV_ENABLE_ALLOCTRACE "IML_allocTrace"
#define IML_ENV_HEAPSIZE "IML_VMHeapSize"
#define IML_ENV_STACKSIZE "IML_VMStackSize"

///////////////////////////////////////////////////////////////////////////////

#ifdef USE_NAMESPACE

using namespace jp_ac_jaist_iml_runtime;
#endif

#define DEFAULT_HEAPSIZE 4096000
#define DEFAULT_STACKSIZE 4096000

class InstructionTracer
    : public VirtualMachineExecutionMonitor
{

  public:
    
    InstructionTracer(){}

    virtual
    ~InstructionTracer(){}

  public:

    virtual
    void beforeInstruction(UInt32Value* &PC,
                           Cell* &ENV,
                           UInt32Value* &SP)
    {
      if(_enableTrace){
        printf("%s\n", instructionToString((instruction)*((UInt8Value*)PC)));
      }
    };

  public:
  static bool _enableTrace;
};

bool InstructionTracer::_enableTrace = false;

class HeapAllocationTracer
    : public HeapMonitor
{

  public:
    
    HeapAllocationTracer()
        :_allocatedFields(0)
    {}

    virtual
    ~HeapAllocationTracer(){}

  public:

    int _allocatedFields;

    virtual
    void afterAllocRecordBlock(Bitmap &bitmap, int &number, Cell* &block)
    {
        _allocatedFields += number;
    };

    virtual
    void afterAllocAtomBlock(int &number, Cell* &block)
    {
        _allocatedFields += number;
    };

    virtual
    void afterAllocPointerBlock(int &number, Cell* &block)
    {
        _allocatedFields += number;
    };

    virtual
    void afterAllocAtomArray(int &number, Cell* &block)
    {
        _allocatedFields += number;
    };

    virtual
    void afterAllocPointerArray(int &number, Cell* &block)
    {
        _allocatedFields += number;
    };

  public:
  static bool _enableTrace;
};

bool HeapAllocationTracer::_enableTrace = false;

#endif // main_hh_
