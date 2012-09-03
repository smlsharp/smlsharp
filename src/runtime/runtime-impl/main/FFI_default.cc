/**
 * Foreign Function Interface (default)
 * @author UENO Katsuhiro
 * @version $Id: FFI_default.cc,v 1.5.2.3 2007/03/29 10:29:15 katsu Exp $
 */
#include <vector>
#include "Constants.hh"
#include "FFI.hh"
#include "FFIException.hh"
#include "Heap.hh"
#include "Log.hh"
#include "VirtualMachine.hh"

/*
 * The switch to turn on the large FFI Switch (fpr ForeignApply).
 * This must be set together with
 *   val LARGEFFISWITCH = ref false
 * in ~src/compiler/control/main/Control.sml
 * #define LARGEFFISWITCH
 */
#define LARGEFFISWITCH


BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

class CallbackInfo
{
  public:
    UInt32Value *entryPoint;
    Cell *env;
    UInt32Value argsCount;
    UInt32Value sizeBitmap;

  private:
    INLINE_FUN
    void parseSizeTag(UInt32Value tag)
    {
        argsCount = 0;
        sizeBitmap = 0;

        while (tag > 0) {
            sizeBitmap = (sizeBitmap << 1) | (2 - tag % 2 - 1);
            tag -= 2 - tag % 2;
            ++argsCount;
            tag = tag / 2;
        }
        --argsCount;
    }

  public:
    CallbackInfo (UInt32Value *entry, Cell *e, UInt32Value tag)
        : entryPoint(entry), env(e)
    {
        parseSizeTag(tag);
    }

    INLINE_FUN UInt32Value argSizeBitmap()
    {
        return sizeBitmap >> 1;
    }

    INLINE_FUN UInt32Value returnValueSize()
    {
        return (sizeBitmap & 0x1) + 1;
    }

    INLINE_FUN bool operator==(const CallbackInfo &other)
    {
        return (entryPoint == other.entryPoint
                && argsCount == other.argsCount
                && sizeBitmap == other.sizeBitmap
                && Heap::isSimilarBlockGraph(env, other.env));
    }
};

/* CAUTION: This might work if you are lucky ;p */
#define CALLBACKENTRYDECL(n)                                            \
UInt32Value FFIDefault::callbackEntry ## n(UInt32Value x0,              \
                                           UInt32Value x1,              \
                                           UInt32Value x2,              \
                                           UInt32Value x3,              \
                                           UInt32Value x4,              \
                                           UInt32Value x5,              \
                                           UInt32Value x6,              \
                                           UInt32Value x7,              \
                                           UInt32Value x8,              \
                                           UInt32Value x9)
#define CALLBACK_MAX_ARGS 10

class DefaultArguments
    : public FFI::Arguments
{
  protected:
    UInt32Value argsCount;
    UInt32Value sizeBitmap;
    Cell args[10];

    void next()
    {
        pointer++;
    }

  public:
    DefaultArguments(CallbackInfo &info,
                     UInt32Value arg0,
                     UInt32Value arg1,
                     UInt32Value arg2,
                     UInt32Value arg3,
                     UInt32Value arg4,
                     UInt32Value arg5,
                     UInt32Value arg6,
                     UInt32Value arg7,
                     UInt32Value arg8,
                     UInt32Value arg9)
        : FFI::Arguments(args)
    {
        ASSERT(info.argSizeBitmap() == 0);
        argsCount = info.argsCount;
        args[0].uint32 = arg0;
        args[1].uint32 = arg1;
        args[2].uint32 = arg2;
        args[3].uint32 = arg3;
        args[4].uint32 = arg4;
        args[5].uint32 = arg5;
        args[6].uint32 = arg6;
        args[7].uint32 = arg7;
        args[8].uint32 = arg8;
        args[9].uint32 = arg9;
    }

    UInt32Value arity() { return argsCount; }
    bool boxed() { return false; }

    UInt32Value size()
    {
        return 1;
    }
};

///////////////////////////////////////////////////////////////////////////////

class FFIDefault
    : public FFI
{
  private:
    static std::vector<CallbackInfo> callbackEntries;
    static CALLBACKENTRYDECL(1);
    static CALLBACKENTRYDECL(2);
    static CALLBACKENTRYDECL(3);
    static CALLBACKENTRYDECL(4);
    static CALLBACKENTRYDECL(5);
    static void * const C_callbackEntries[5];

  protected:
    FFIDefault() : FFI() {}

  public:
    static INLINE_FUN void init() {
        instance_ = new FFIDefault();
    }

    void trace(RootTracer *tracer)
        throw(IMLRuntimeException);

    void call(Cell *returnValue, void *function, UInt32Value *SP,
              UInt32Value switchTag, UInt32Value convention,
              UInt32Value *argIndexes, UInt32Value argsCount)
        throw(UserException,
              IMLRuntimeException,
              SystemError);

    void *callback(UInt32Value *entryPoint, Cell *env, UInt32Value sizeTag)
        throw(IMLRuntimeException);
};

///////////////////////////////////////////////////////////////////////////////

FFI *FFI::instance_ = 0;

void FFI::init()
{
    FFIDefault::init();
}

///////////////////////////////////////////////////////////////////////////////

#ifdef LARGEFFISWITCH

#define SWITCHFUNCDEFAULT do { \
    DBGWRAP(printf("Error:bad tag %d", tag);) \
    throw FFIException("unsupported foreign function call;" \
                       " maybe parameters are too many"); \
    break; \
} while (0)

#define CONVENTION
#define SWITCHFUNCNAME(x) funcall_default##x
#include "FFISwitchGen/LARGEFFISWITCH.cc"
#undef CONVENTION
#undef SWITCHFUNCNAME
#define CONVENTION CDECL_FUN
#define SWITCHFUNCNAME(x) funcall_cdecl##x
#include "FFISwitchGen/LARGEFFISWITCH.cc"
#undef CONVENTION
#undef SWITCHFUNCNAME
#define CONVENTION STDCALL_FUN
#define SWITCHFUNCNAME(x) funcall_stdcall##x
#include "FFISwitchGen/LARGEFFISWITCH.cc"
#undef CONVENTION
#undef SWITCHFUNCNAME

#else // LARGEFFISWITCH

static void funcall_default(Cell *returnValue, UInt32Value *SP,
                            UInt32Value *argIndexes)
{
#define CONVENSION
#include "FFISwitchGen/SMALLFFISWITCH.cc"
#undef CONVENSION
}

static void funcall_cdecl(Cell *returnValue, UInt32Value *SP,
                          UInt32Value *argIndexes)
{
#define CONVENTION CDECL_FUN
#include "FFISwitchGen/LARGEFFISWITCH.cc"
#undef CONVENTION
}

static void funcall_stdcall(Cell *returnValue, UInt32Value *SP,
                            UInt32Value *argIndexes)
{
#define CONVENTION STDCALL_FUN
#include "FFISwitchGen/LARGEFFISWITCH.cc"
#undef CONVENTION
}

#endif // LARGEFFISWITCH

///////////////////////////////////////////////////////////////////////////////

void FFIDefault::call(Cell *returnValue, void *function, UInt32Value *SP,
                      UInt32Value switchTag, UInt32Value convention,
                      UInt32Value *argIndexes, UInt32Value argsCount)
    throw(UserException,
          IMLRuntimeException,
          SystemError)
{
    switch(convention)
    {
      case FFI_CC_DEFAULT:
        funcall_default(returnValue, function, SP, switchTag, argIndexes);
        break;
      case FFI_CC_CDECL:
        funcall_cdecl(returnValue, function, SP, switchTag, argIndexes);
        break;
      case FFI_CC_STDCALL:
        funcall_stdcall(returnValue, function, SP, switchTag, argIndexes);
        break;
      default:
        DBGWRAP
            (printf("Error:bad convention %d", convention);)
        throw IllegalStateException();
        break;
    }
}

std::vector<CallbackInfo> FFIDefault::callbackEntries;

/* CAUTION: This might work if you are lucky ;p */
#define CALLBACKENTRY(n)                                                \
CALLBACKENTRYDECL(n)                                                    \
{                                                                       \
    Cell ret[2];                                                        \
    CallbackInfo &callback = callbackEntries[n-1];                      \
    DefaultArguments args(callback,x0,x1,x2,x3,x4,x5,x6,x7,x8,x9);      \
                                                                        \
    VirtualMachine::executeFunction(VirtualMachine::Longjump,           \
                                    callback.entryPoint,                \
                                    callback.env,                       \
                                    ret,                                \
                                    false,                              \
                                    args);                              \
    return ret[0].uint32;                                               \
}
CALLBACKENTRY(1)
CALLBACKENTRY(2)
CALLBACKENTRY(3)
CALLBACKENTRY(4)
CALLBACKENTRY(5)

#define NUM_CALLBACK_ENTRIES  5
void * const FFIDefault::C_callbackEntries[NUM_CALLBACK_ENTRIES] = {
    (void*)callbackEntry1,
    (void*)callbackEntry2,
    (void*)callbackEntry3,
    (void*)callbackEntry4,
    (void*)callbackEntry5,
};

void *FFIDefault::callback(UInt32Value *entryPoint, Cell *env,
                           UInt32Value sizeTag)
    throw(IMLRuntimeException)
{
    CallbackInfo callback(entryPoint, env, sizeTag);

    if (callback.argsCount > CALLBACK_MAX_ARGS
        || callback.argSizeBitmap() != 0) {
        throw FFIException("unsupported callback function");
    }

    // share an callbackEntry if already registered callbackInfo
    // and given callbackInfo are equal.
    for (std::vector<CallbackInfo>::iterator i = callbackEntries.begin();
         i != callbackEntries.end(); ++i) {
        if (callback == *i) {
            *i = callback;
            return C_callbackEntries[i - callbackEntries.begin()];
        }
    }

    if (callbackEntries.size() >= NUM_CALLBACK_ENTRIES) {
        DBGWRAP
          (printf
           ("Error: too many callbacks %d\n", callbackEntries.size());)
        throw FFIException("too many callbacks");
    }

    callbackEntries.push_back(callback);
    DBGWRAP(printf("callback: %d = (%p, %p)\n", callbackEntries.size() - 1,
                   callback.entryPoint, callback.env);)
    return C_callbackEntries[callbackEntries.size() - 1];
}

void FFIDefault::trace(RootTracer *tracer)
    throw(IMLRuntimeException)
{
    std::vector<CallbackInfo>::iterator i;
    for (i = callbackEntries.begin(); i != callbackEntries.end(); ++i) {
        if ((*i).env != 0)
            tracer->trace(&(*i).env, 1);
    }
}

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
