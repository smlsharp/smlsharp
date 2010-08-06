/**
 * @author UENO Katsuhiro
 * @version $Id: FFI.hh,v 1.4 2007/06/11 00:47:57 kiyoshiy Exp $
 */
#ifndef FFI_hh_
#define FFI_hh_

#if 0
#include <signal.h>
#include <stdio.h>
#include <setjmp.h>

#include "ExecutableLinker.hh"
#include "Heap.hh"
#include "Session.hh"
#include "VariableLengthArray.hh"
#include "WordOperations.hh"
#include "IllegalStateException.hh"
#include "NoEnoughFrameStackException.hh"
#include "NoEnoughHandlerStackException.hh"
#endif
#include "RuntimeTypes.hh"
#include "EmptyHandlerStackException.hh"
#include "IllegalStateException.hh"
#include "SystemError.hh"
#include "Debug.hh"
#include "Log.hh"

#include <iterator>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

/** singleton class providing foreign function interface. */
class FFI
    : public RootSet
{
  protected:
    FFI() {}
    static FFI *instance_;

  public:
    static void init();

    static INLINE_FUN FFI &instance() {
        ASSERT(instance_ != 0);
        return *instance_;
    }

    static INLINE_FUN void finalize() {
        if (instance_) delete instance_;
        instance_ = 0;
    }

    virtual void trace(RootTracer *tracer)
        throw(IMLException) = 0;

    virtual void call(Cell *returnValue, void *function, UInt32Value *SP,
                      UInt32Value switchTag, UInt32Value convention,
                      UInt32Value *argIndexes, UInt32Value argsCount)
        throw(IMLException) = 0;
    
    virtual void *callback(UInt32Value *entryPoint, Cell *env,
                           UInt32Value sizeTag)
        throw(IMLException) = 0;

    class Arguments
    /*
        : public std::iterator<std::input_iterator_tag, UInt32Value *>
    */
    {
      protected:
        Cell *pointer;
        Arguments(Cell *p) : pointer(p) {}
        virtual void next() = 0;

      public:
        virtual UInt32Value arity() = 0;
        virtual UInt32Value size() = 0;
        virtual bool boxed() = 0;
        inline Cell *value() { return pointer; }
        inline Arguments &operator++() { next(); return *this; }
        /*
        inline UInt32Value &operator*() { return value(); }
        iterator &operator=(const Arguments &);
        bool operator==(const FFI::Arguments::iterator &other);
        inline bool operator!=(const FFI::Arguments::iterator &other)
        { return !(*this == other); }
        */
    };
};

END_NAMESPACE

#endif // FFI_hh_
