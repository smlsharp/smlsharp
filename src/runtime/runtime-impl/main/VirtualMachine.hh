/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: VirtualMachine.hh,v 1.22 2006/02/17 13:29:25 kiyoshiy Exp $
 */
#ifndef VirtualMachine_hh_
#define VirtualMachine_hh_

#include <signal.h>
#include <stdio.h>
#include <setjmp.h>

#include "ExecutableLinker.hh"
#include "Heap.hh"
#include "Session.hh"
#include "VariableLengthArray.hh"
#include "WordOperations.hh"
#include "EmptyHandlerStackException.hh"
#include "IllegalStateException.hh"
#include "NoEnoughFrameStackException.hh"
#include "NoEnoughHandlerStackException.hh"
#include "Log.hh"
#include "Debug.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

class VirtualMachineExecutionMonitor;

/**
 * The implementation of the IML virtual machine specification.
 */
class VirtualMachine
    : public RootSet,
      public WordOperations 
{
    ///////////////////////////////////////////////////////////////////////////

  private:

    static Session* session_;
    static VirtualMachine* instance_;

    /*
     * machine registers
     *
     * ToDo : To optimize access speed, change these machine registers to
     * local variables of the 'execute' method, and hold those addresses as
     * member fields.
     * The 'trace' method passes those addressed to the 'RootTracer'(= garbage
     * collector).
     */

    static Cell* savedENV_;
    static UInt32Value* savedSP_;

    /**
     * global table of boxed(= block pointer) type variables
     */
    static VariableLengthArray boxedGlobals_;

    /**
     * global table of unboxed(= non-pointer) type variables
     */
    static VariableLengthArray unboxedGlobals_;

    /**
     * a stack to save pointers to blocks temporarily.
     */
    static VariableLengthArray temporaryPointers_;

    /** SIGINT handler which is overriden by VM's handler. */
    static void (*prevSIGINTHandler_)(int);
    /** a flag which is set to true when an signal is caught. */
    static bool interrupted_;

    /** SIGFPE handler which is overriden by VM's handler. */
    static void (*prevSIGFPEHandler_)(int);

    /** SIGPIPE handler which is overriden by VM's handler. */
    static void (*prevSIGPIPEHandler_)(int);

    /** SIGSEGV handler which is overriden by VM's handler. */
    static void (*prevSIGSEGVHandler_)(int);

    /** used to jump from signalHandler to 'execute' function */
    static jmp_buf onSignal_jmp_buf;

    /** the name of VM instance. */
    static const char* name_;
    /** command line arguments, exluding name */
    static const char** arguments_;
    /** the number of command line arguments */
    static int argumentsCount_;

    /** a flag indicating that an exception is set by a primitive operator or
     * foreign function. */
    static bool isPrimitiveExceptionRaised_;
    /** an exception which is set by primitive operator or foreign function. */
    static Cell primitiveException_;

#ifdef IML_ENABLE_EXECUTION_MONITORING
    static VariableLengthArray executionMonitors_;
#endif

/*
 * About the layout of stack frame, refer to the
 *   compiler/asssemble/main/Assemblre.sml
 */
#define FRAME_ENTRY(sp,n) (*(Cell*)((sp) + (n)))
#define FRAME_ENTRY_ADDRESS(sp,n) ((sp) + (n))

#define FRAME_TOP_ADDRESS(sp) ((sp) + 1)
#define FRAME_SIZE(sp) (*((sp) + 1))
#define FRAME_FUNINFO(sp) (*(UInt32Value**)((sp) + 2))
#define FRAME_BITMAP(sp) (*(Bitmap*)((sp) + 3))
#define FRAME_RETURN_ADDRESS(sp) (*(UInt32Value**)((sp) + 4))
#define FRAME_FIRST_POINTER_SLOT 5
#define FRAME_FIRST_POINTER_SLOT_ADDRESS(sp) \
    ((Cell*)((sp) + FRAME_FIRST_POINTER_SLOT))
#define FRAME_VAR_SLOTS_COUNT(frameSize) \
    ((frameSize)- FRAME_FIRST_POINTER_SLOT + 1)

    class FrameStack
    {

      private:
        static UInt32Value* frameStack_;
        static UInt32Value* frameStackBottom_;

        INLINE_FUN static
        int getAvailableSize(UInt32Value* SP)
        {
            return (SP - frameStack_);
        }

      private:

        INLINE_FUN static
        void getSlotLayoutOfFunInfo(UInt32Value* funinfoAddress,
                                    UInt32Value &pointersCount,
                                    UInt32Value &atomsCount,
                                    UInt32Value &recordGroupsCount,
                                    UInt32Value* &recordsCounts)
        {
            // extract funinfo
            // executable = *funinfoAddress
            // frameSize = *funinfoAddress + 1;
            // startAddress = *funinfoAddress + 2;
            UInt32Value* cursor = funinfoAddress + 3;
            UInt32Value arity = *cursor;
            cursor += 1 + arity;
            UInt32Value bitmapvalsFreesCount = *cursor;
            cursor += 1 + bitmapvalsFreesCount;
            UInt32Value bitmapvalsArgsCount = *cursor;
            cursor += 1 + bitmapvalsArgsCount;
            pointersCount = *cursor;
            cursor += 1;
            atomsCount = *cursor;
            cursor += 1;
            recordGroupsCount = *cursor;
            cursor += 1;
            recordsCounts = cursor;
        }

        INLINE_FUN static
        void traceRange(RootTracer* tracer,
                        Cell* start,
                        UInt32Value count)
        {
#ifdef IML_DEBUG
            Cell* beforeGC[count];
            for(int index = 0; index < count; index += 1){
                Cell value = *(start + index);
                if(value.blockRef){
                    ASSERT(Heap::isValidBlockPointer
                           (value.blockRef));
                }
                beforeGC[index] = value.blockRef;
            }
#endif
            // elements from start to start + count are all pointers (= Cell*)
            tracer->trace((Cell**)start, count);
#ifdef IML_DEBUG
            for(int index = 0; index < count; index += 1){
                Cell afterGC = start[index];
                if(beforeGC[index]){
                    ASSERT(Heap::isValidBlockPointer
                           (afterGC.blockRef));
                }else{
                    ASSERT(0 == afterGC.blockRef);
                }
            }
#endif
        }

        INLINE_FUN static
        UInt32Value* traceFrame(RootTracer* tracer, UInt32Value* &SP)
        {
            // extract frame header
            UInt32Value frameSize = FRAME_SIZE(SP);
            Bitmap bitmap = FRAME_BITMAP(SP);
            UInt32Value* funinfoAddress = FRAME_FUNINFO(SP);

            UInt32Value pointersCount;
            UInt32Value atomsCount;
            UInt32Value recordGroupsCount;
            UInt32Value* recordsCounts;
            getSlotLayoutOfFunInfo(funinfoAddress,
                                   pointersCount,
                                   atomsCount,
                                   recordGroupsCount,
                                   recordsCounts);

            // trace pointers and records whose bit is set.
            Cell* startAddress = FRAME_FIRST_POINTER_SLOT_ADDRESS(SP);
            traceRange(tracer, startAddress, pointersCount); // trace pointers
            startAddress += pointersCount;
            startAddress += atomsCount; // skip atoms

            /* Assume k record groups.
             * The least significant bit indicates the type of the first
             * record group. The k-1th bit of the bitmap indicates the type of
             * the last record group. 
             */
            for(int remainGroups = recordGroupsCount; // trace record group
                0 < remainGroups;
                remainGroups -= 1)
            {
                UInt32Value recordsCount = *recordsCounts;
                if(bitmap & 1){
                    traceRange(tracer, startAddress, recordsCount);
                }
                startAddress += recordsCount;
                recordsCounts += 1;
                bitmap >>= 1;
            }
            ASSERT(0 == bitmap);

            // startAddress points now to the next frame
            ASSERT(SP + frameSize + 1 == (UInt32Value*)startAddress);

            return (SP + frameSize);
        }

      public:
        static const UInt32Value BITMAP_BIT_WIDTH = 32;
        static const int FRAME_ALIGNMENT = sizeof(Real64Value);

      public:
        INLINE_FUN static
        void initialize(int stackSize)
        {
            frameStack_ =
            (UInt32Value*)(ALLOCATE_MEMORY(sizeof(UInt32Value) * stackSize));
            if(NULL == frameStack_){throw OutOfMemoryException();}
            frameStackBottom_ = frameStack_ + (stackSize - 1);

            /* ensure that the first slot of a frame is placed at
             * FRAME_ALIGNMENT boundary. */
            int modulo = ((UInt32Value)FRAME_TOP_ADDRESS(frameStackBottom_))
                         % FRAME_ALIGNMENT;
            switch(modulo){
              case 0: break;
              case 4: 
                frameStackBottom_ =
                (UInt32Value*)((UInt32Value)frameStackBottom_ + 4);
                break;
              default:
                DBGWRAP(LOG.error("FrameStack::initialize: invalid modulo"));
                throw IllegalStateException();
            }
            ASSERT(0 ==
                   (((UInt32Value)FRAME_TOP_ADDRESS(frameStackBottom_))
                    % FRAME_ALIGNMENT));
        }

        INLINE_FUN static
        void finalize()
        {
            RELEASE_MEMORY(frameStack_);
        }

        INLINE_FUN static
        UInt32Value* getBottom()
        {
            return frameStackBottom_;            
        }

        INLINE_FUN static
        void loadENV(UInt32Value* &SP, Cell* &ENV)
        {
            ENV = FRAME_FIRST_POINTER_SLOT_ADDRESS(SP)->blockRef;
        };

        INLINE_FUN static
        void storeENV(UInt32Value* &SP, Cell* ENV)
        {
            FRAME_FIRST_POINTER_SLOT_ADDRESS(SP)->blockRef = ENV;
        };

        INLINE_FUN static
        Executable* getExecutableOfFrame(UInt32Value* SP)
        {
            // *funInfoAddress is a pointer to the executable
            return (Executable*)(*FRAME_FUNINFO(SP));
        };

        INLINE_FUN static
        Bitmap getBitmap(UInt32Value* SP){
            return FRAME_BITMAP(SP);
        }

        INLINE_FUN static
        UInt32Value* getReturnAddress(UInt32Value* SP)
        {
            return (UInt32Value*)FRAME_RETURN_ADDRESS(SP);
        }

        INLINE_FUN static
        UInt32Value* getNextFrame(UInt32Value* SP)
        {
            if(SP == frameStackBottom_){
                return 0;
            }
            UInt32Value frameSize = FRAME_SIZE(SP);
            return SP + frameSize;
        }

        INLINE_FUN static
        UInt32Value* allocateFrame(UInt32Value* SP,
                                   UInt32Value frameSize,
                                   Bitmap bitmap,
                                   UInt32Value* funInfoAddress,
                                   UInt32Value* returnAddress)
        {
            // *funInfoAddress is a pointer to the executable
            // The next entry is the frameSize.
            ASSERT(*(funInfoAddress + 1) == frameSize);
            if(getAvailableSize(SP) < frameSize){
                throw NoEnoughFrameStackException();
            }

            SP -= frameSize; // extend the stack to lower address
            FRAME_SIZE(SP) = frameSize;
            FRAME_FUNINFO(SP) = funInfoAddress;
            FRAME_BITMAP(SP) = bitmap;
            FRAME_RETURN_ADDRESS(SP) = returnAddress;

            FILL_MEMORY(FRAME_FIRST_POINTER_SLOT_ADDRESS(SP),
                        0,
                        FRAME_VAR_SLOTS_COUNT(frameSize) * sizeof(Cell));
            return SP;
        };

        INLINE_FUN static
        UInt32Value* duplicateFrame(UInt32Value* SP,
                                    UInt32Value frameSize,
                                    UInt32Value* returnAddress)
        {
            ASSERT(returnAddress);
            ASSERT(FRAME_SIZE(SP) == frameSize);
            if(getAvailableSize(SP) < frameSize){
                throw NoEnoughFrameStackException();
            }

            // extend the stack to lower address
            UInt32Value* newSP = SP - frameSize; 

            /* copy the entire frame.
             * NOTE: the first slot of a frame is right after the SP.
             */
            COPY_MEMORY(newSP + 1, SP + 1, frameSize * sizeof(Cell));

            FRAME_RETURN_ADDRESS(newSP) = returnAddress;

            return newSP;
        };

        INLINE_FUN static
        UInt32Value* replaceFrame(UInt32Value* SP,
                                  UInt32Value newFrameSize,
                                  Bitmap bitmap,
                                  UInt32Value* funInfoAddress)
        {
            UInt32Value currentFrameSize = FRAME_SIZE(SP);
            ASSERT(*(funInfoAddress + 1) == newFrameSize);
            UInt32Value* returnAddress = FRAME_RETURN_ADDRESS(SP);

            if(getAvailableSize(SP + currentFrameSize) < newFrameSize){
                throw NoEnoughFrameStackException();
            }

            SP += currentFrameSize; // shrink the stack to higher address
            SP -= newFrameSize; // extend the stack to lower address

            FRAME_SIZE(SP) = newFrameSize;
            FRAME_FUNINFO(SP) = funInfoAddress;
            FRAME_BITMAP(SP) = bitmap;
            FRAME_RETURN_ADDRESS(SP) = returnAddress;
            FILL_MEMORY(FRAME_FIRST_POINTER_SLOT_ADDRESS(SP),
                        0,
                        FRAME_VAR_SLOTS_COUNT(newFrameSize) * sizeof(Cell));

            return SP;
        };

        INLINE_FUN static
        void popFramesUntil(UInt32Value* &SP, UInt32Value* &restoredSP)
        {
            SP = restoredSP;
        };

        INLINE_FUN static
        void popFrameAndReturn(UInt32Value* &SP, UInt32Value* &PC)
        {
            UInt32Value frameSize = FRAME_SIZE(SP);
            PC = FRAME_RETURN_ADDRESS(SP);
            SP += frameSize; // shrink the stack to higher address
        };

        INLINE_FUN static
        void trace(RootTracer* tracer, UInt32Value* &SP)
        {
            // trace frames
            // scan from the lower address to the higher address (= bottom)
            UInt32Value* cursorSP = SP;
            while(cursorSP < frameStackBottom_){
                cursorSP = traceFrame(tracer, cursorSP);
            }
            ASSERT(cursorSP == frameStackBottom_);
        };

        /*  Because this function is used only for debug, optimization is
         * unnecessary.
         */
        INLINE_FUN static
        bool isPointerSlot(UInt32Value* &SP, UInt32Value index)
        {
            // extract frame header
            UInt32Value frameSize = FRAME_SIZE(SP);
            Bitmap bitmap = FRAME_BITMAP(SP);
            UInt32Value* funinfoAddress = FRAME_FUNINFO(SP);

            UInt32Value pointersCount;
            UInt32Value atomsCount;
            UInt32Value recordGroupsCount;
            UInt32Value* recordsCounts;
            getSlotLayoutOfFunInfo(funinfoAddress,
                                   pointersCount,
                                   atomsCount,
                                   recordGroupsCount,
                                   recordsCounts);

            index -= FRAME_FIRST_POINTER_SLOT;

            if((0 <= index) && (index < pointersCount)){ return true; }
            index -= pointersCount;

            if((0 <= index) && (index < atomsCount)){ return false; }
            index -= atomsCount;

            for(int groupIndex = 0;
                groupIndex < recordGroupsCount;
                groupIndex += 1)
            {
                UInt32Value recordsCount = recordsCounts[groupIndex];
                if(index < recordsCount){
                    // NOTE : don't return the bitmap directly.
                    return ((bitmap >> groupIndex) & 1L) ? true : false;
                }
                index -= recordsCount;
            }
            DBGWRAP(LOG.error("isPointerSlot: too big slot index"));
            throw IllegalStateException();
        }

    };

    class HandlerStack
    {

      private:
        static const UInt32Value WORDS_OF_HANDLERSTACK_ENTRY = 3;
        static const UInt32Value INDEX_OF_FRAME_HANDLERSTACK = 0;
        static const UInt32Value INDEX_OF_DESTINATION_HANDLERSTACK = 1;
        static const UInt32Value INDEX_OF_HANDLER_HANDLERSTACK = 2;

        /**
         * stack of exception handlers.
         * stack extends from lower address to higher address.
         */
        static UInt32Value* stack_;
        /**
         * the end of stack region.
         */
        static UInt32Value* stackTop_;
        /*
         * current top of stack
         */
        static UInt32Value* currentTop_;

      public:

        INLINE_FUN static
        void initialize(int stackSize)
        {
            stack_ =
            (UInt32Value*)(ALLOCATE_MEMORY(sizeof(UInt32Value) * stackSize));
            if(NULL == stack_){throw OutOfMemoryException();}
            currentTop_ = stack_;
            stackTop_ = stack_ + (stackSize - 1);
        }

        INLINE_FUN static
        void finalize()
        {
            RELEASE_MEMORY(stack_);
        }

        /**
         * remove top entries whose frame field is equals to the specified SP.
         */
        INLINE_FUN static
        void removeHandlersOfFrame(UInt32Value* SP)
        {
            while(true)
            {
                if(currentTop_ == stack_){ break; }
                UInt32Value* nextEntry =
                currentTop_ - WORDS_OF_HANDLERSTACK_ENTRY;
                if(SP !=
                   (UInt32Value*)(nextEntry[INDEX_OF_FRAME_HANDLERSTACK]))
                { break; }
                currentTop_ = nextEntry;
            }
        };

        /**
         * remove the top entry.
         */
        INLINE_FUN static
        void remove()
        {
            currentTop_ -= WORDS_OF_HANDLERSTACK_ENTRY;
        };

        /**
         * push a entry onto the stack.
         */
        INLINE_FUN static
        void push(UInt32Value* SP,
                  UInt32Value exceptionIndex,
                  UInt32Value* handler)
            throw(IMLRuntimeException)
        {
            if(stackTop_ < currentTop_ + WORDS_OF_HANDLERSTACK_ENTRY){
                // stack overflow
                throw NoEnoughHandlerStackException();
            }
            currentTop_[INDEX_OF_FRAME_HANDLERSTACK] = (UInt32Value)SP;
            currentTop_[INDEX_OF_DESTINATION_HANDLERSTACK] = exceptionIndex;
            currentTop_[INDEX_OF_HANDLER_HANDLERSTACK] = (UInt32Value)handler;
            currentTop_ += WORDS_OF_HANDLERSTACK_ENTRY;
        };

        INLINE_FUN static
        void pop(UInt32Value* &SP,
                 UInt32Value &exceptionIndex,
                 UInt32Value* &handler)
            throw(EmptyHandlerStackException)
        {
            currentTop_ -= WORDS_OF_HANDLERSTACK_ENTRY;
            if(currentTop_ < stack_){// handler is not found. stack underflow
                throw EmptyHandlerStackException();
            }
            SP = (UInt32Value*)(currentTop_[INDEX_OF_FRAME_HANDLERSTACK]);
            exceptionIndex = currentTop_[INDEX_OF_DESTINATION_HANDLERSTACK];
            handler =
            (UInt32Value*)(currentTop_[INDEX_OF_HANDLER_HANDLERSTACK]);
        };

        INLINE_FUN static
        void clear()
        {
            currentTop_ = stack_;
        };

    };

    /**
     * log writer
     */
    DBGWRAP(static LogAdaptor LOG;)

    ///////////////////////////////////////////////////////////////////////////

  public:

    /**
     * constructor
     *
     * @param name the name of the VM instance.
     * @param arguments initialize arguments
     * @param argumentsCount the number of arguments
     * @param stackSize the size of stack (in words)
     */
    VirtualMachine
    (
      const char* name = "noname",
      const int argumentsCount = 0,
      const char** arguments = 0,
      const int stackSize = 10240
    );

    /**
     * destructor
     */
    virtual
    ~VirtualMachine();

    ///////////////////////////////////////////////////////////////////////////
  public:

    static
    VirtualMachine* getInstance(){ return instance_; }

    static
    void setSession(Session* session);

    static
    Session* getSession();

    static
    void execute(Executable* executable)
        throw(UserException,
              IMLRuntimeException,
              SystemError);

    static
    int addExecutionMonitor(VirtualMachineExecutionMonitor* monitor);

    static
    VirtualMachineExecutionMonitor* removeExecutionMonitor(int index);

    static
    const char* getName(){
        return name_;
    }

    static
    int getArguments(const char*** argumentsRef){
        *argumentsRef = arguments_;
        return argumentsCount_;
    }

    static
    void pushTemporaryRoot(Cell** blockRef){
        temporaryPointers_.push((void*)blockRef);
    }

    static
    Cell** popTemporaryRoot(){
        return (Cell**)temporaryPointers_.pop();
    }

    static
    void setPrimitiveException(Cell exception){
        isPrimitiveExceptionRaised_ = true;
        primitiveException_ = exception;
    }

    static
    void resetPrimitiveException(){
        isPrimitiveExceptionRaised_ = false;
    }

    static
    void IPToString(char* buffer,
                    int buffserSize,
                    Executable* executable,
                    UInt32Value offset)
    {
        const char *fileName;
        UInt32Value leftLine, leftCol, rightLine, rightCol;
        ExecutableLinker::getLocationOfCodeRef(executable,
                                               offset,
                                               &fileName,
                                               &leftLine,
                                               &leftCol,
                                               &rightLine,
                                               &rightCol);

        snprintf(buffer, buffserSize, "%s:%d.%d-%d.%d",
                 fileName, leftLine, leftCol, rightLine, rightCol);
    }

    ///////////////////////////////////////////////////////////////////////////
  private:

    static
    void
    expandClosure(UInt32Value* SP,
                  UInt32Value closureIndex,
                  UInt32Value* &entryPoint,
                  Cell* &calleeENV);

    static
    UInt32Value* getFunInfoForSelfRecursiveCall(UInt32Value *entryPoint,
                                                UInt32Value &frameSize,
                                                UInt32Value* &argDests,
                                                UInt32Value* &funInfoAddress);

    static
    UInt32Value* getFunInfoForRecursiveCall(UInt32Value *entryPoint,
                                            UInt32Value &frameSize,
                                            UInt32Value &arity,
                                            UInt32Value* &argDests,
                                            UInt32Value &bitmapvalsFreesCount,
                                            UInt32Value &bitmapvalsFrees,
                                            UInt32Value* &funInfoAddress);

    static
    UInt32Value* getFunInfo(UInt32Value *entryPoint,
                            UInt32Value &frameSize,
                            UInt32Value &arity,
                            UInt32Value* &argDests,
                            UInt32Value &bitmapvalsFreesCount,
                            UInt32Value * &bitmapvalsFrees,
                            UInt32Value &bitmapvalsArgsCount,
                            UInt32Value * &bitmapvalsArgs,
                            UInt32Value * &funInfoAddress);

    static
    Bitmap composeBitmap(UInt32Value* SP,
                         UInt32Value* argIndexes,
                         Cell* calleeENV,
                         UInt32Value bitmapvalsFreesCount,
                         UInt32Value * bitmapvalsFrees,
                         UInt32Value bitmapvalsArgsCount,
                         UInt32Value * bitmapvalsArgs);

    static
    UInt32Value* getFunInfoAndBitmap(UInt32Value* SP,
                                     UInt32Value *entryPoint,
                                     Cell* calleeENV,
                                     UInt32Value* argIndexes,
                                     UInt32Value &frameSize,
                                     UInt32Value &arity,
                                     UInt32Value* &argDests,
                                     UInt32Value* &funInfoAddress,
                                     Bitmap &bitmap);

    static
    UInt32Value* fillFrameForTailCall_S(UInt32Value* funInfoAddress,
                                        UInt32Value frameSize,
                                        Bitmap bitmap,
                                        UInt32Value argIndex,
                                        UInt32Value argDest,
                                        UInt32Value* SP);

    static
    UInt32Value* fillFrameForNonTailCall_S(UInt32Value* funInfoAddress,
                                           UInt32Value frameSize,
                                           Bitmap bitmap,
                                           UInt32Value argIndex,
                                           UInt32Value argDest,
                                           UInt32Value* returnAddress,
                                           UInt32Value* SP);
    
    static
    UInt32Value* fillFrameForTailCall_D(UInt32Value* funInfoAddress,
                                        UInt32Value frameSize,
                                        Bitmap bitmap,
                                        UInt32Value argIndex,
                                        UInt32Value argDest,
                                        UInt32Value* SP);

    static
    UInt32Value* fillFrameForNonTailCall_D(UInt32Value* funInfoAddress,
                                           UInt32Value frameSize,
                                           Bitmap bitmap,
                                           UInt32Value argIndex,
                                           UInt32Value argDest,
                                           UInt32Value* returnAddress,
                                           UInt32Value* SP);

    static
    UInt32Value* fillFrameForTailCall_ML_S(UInt32Value* funInfoAddress,
                                           UInt32Value frameSize,
                                           UInt32Value arity,
                                           Bitmap bitmap,
                                           UInt32Value* argIndexes,
                                           UInt32Value* argDests,
                                           UInt32Value* SP);

    static
    UInt32Value* fillFrameForNonTailCall_ML_S(UInt32Value* funInfoAddress,
                                              UInt32Value frameSize,
                                              UInt32Value arity,
                                              Bitmap bitmap,
                                              UInt32Value* argIndexes,
                                              UInt32Value* argDests,
                                              UInt32Value* returnAddress,
                                              UInt32Value* SP);
    
    static
    UInt32Value* fillFrameForTailCall_ML_D(UInt32Value* funInfoAddress,
                                           UInt32Value frameSize,
                                           UInt32Value arity,
                                           Bitmap bitmap,
                                           UInt32Value* argIndexes,
                                           UInt32Value* argDests,
                                           UInt32Value* SP);

    static
    UInt32Value* fillFrameForNonTailCall_ML_D(UInt32Value* funInfoAddress,
                                              UInt32Value frameSize,
                                              UInt32Value arity,
                                              Bitmap bitmap,
                                              UInt32Value* argIndexes,
                                              UInt32Value* argDests,
                                              UInt32Value* returnAddress,
                                              UInt32Value* SP);

    static
    UInt32Value* fillFrameForTailCall_M(UInt32Value* funInfoAddress,
                                        UInt32Value frameSize,
                                        UInt32Value arity,
                                        Bitmap bitmap,
                                        UInt32Value* argIndexes,
                                        UInt32Value* argSizeIndexes,
                                        UInt32Value* argDests,
                                        UInt32Value* SP);

    static
    UInt32Value* fillFrameForNonTailCall_M(UInt32Value* funInfoAddress,
                                           UInt32Value frameSize,
                                           UInt32Value arity,
                                           Bitmap bitmap,
                                           UInt32Value* argIndexes,
                                           UInt32Value* argSizeIndexes,
                                           UInt32Value* argDests,
                                           UInt32Value* returnAddress,
                                           UInt32Value* SP);

    static
    void callFunction_S(bool isTailCall,
                        UInt32Value* &PC,
                        UInt32Value* &SP,
                        Cell* &ENV,
                        UInt32Value *entryPoint,
                        Cell* restoredENV,
                        UInt32Value argIndex,
                        UInt32Value* returnAddress);

    static
    void callFunction_D(bool isTailCall,
                        UInt32Value* &PC,
                        UInt32Value* &SP,
                        Cell* &ENV,
                        UInt32Value *entryPoint,
                        Cell* restoredENV,
                        UInt32Value argIndex,
                        UInt32Value* returnAddress);

    static
    void callFunction_V(bool isTailCall,
                        UInt32Value* &PC,
                        UInt32Value* &SP,
                        Cell* &ENV,
                        UInt32Value *entryPoint,
                        Cell* calleeENV,
                        UInt32Value argIndex,
                        UInt32Value argSize,
                        UInt32Value* returnAddress);

    static
    void callFunction_ML_S(bool isTailCall,
                           UInt32Value* &PC,
                           UInt32Value* &SP,
                           Cell* &ENV,
                           UInt32Value *entryPoint,
                           Cell* restoredENV,
                           UInt32Value* argIndexes,
                           UInt32Value* returnAddress);

    static
    void callFunction_ML_D(bool isTailCall,
                           UInt32Value* &PC,
                           UInt32Value* &SP,
                           Cell* &ENV,
                           UInt32Value *entryPoint,
                           Cell* restoredENV,
                           UInt32Value* argIndexes,
                           UInt32Value* returnAddress);

    static
    void callFunction_ML_V(bool isTailCall,
                           UInt32Value* &PC,
                           UInt32Value* &SP,
                           Cell* &ENV,
                           UInt32Value *entryPoint,
                           Cell* calleeENV,
                           UInt32Value* argIndexes,
                           UInt32Value lastArgSize,
                           UInt32Value* returnAddress);

    static
    void callFunction_M(bool isTailCall,
                        UInt32Value* &PC,
                        UInt32Value* &SP,
                        Cell* &ENV,
                        UInt32Value *entryPoint,
                        Cell* restoredENV,
                        UInt32Value* argIndexes,
                        UInt32Value* argSizeIndexes,
                        UInt32Value* returnAddress);

    static
    void callRecursiveFunction_S(bool isTailCall,
                                 UInt32Value* &PC,
                                 UInt32Value* &SP,
                                 Cell* &ENV,
                                 UInt32Value *entryPoint,
                                 UInt32Value argIndex,
                                 UInt32Value* returnAddress);

    static
    void callRecursiveFunction_D(bool isTailCall,
                                 UInt32Value* &PC,
                                 UInt32Value* &SP,
                                 Cell* &ENV,
                                 UInt32Value *entryPoint,
                                 UInt32Value argIndex,
                                 UInt32Value* returnAddress);

    static
    void callRecursiveFunction_V(bool isTailCall,
                                 UInt32Value* &PC,
                                 UInt32Value* &SP,
                                 Cell* &ENV,
                                 UInt32Value *entryPoint,
                                 UInt32Value argIndex,
                                 UInt32Value lastArgSize,
                                 UInt32Value* returnAddress);

    static
    void callRecursiveFunction_M(bool isTailCall,
                                 UInt32Value* &PC,
                                 UInt32Value* &SP,
                                 Cell* &ENV,
                                 UInt32Value *entryPoint,
                                 UInt32Value *argIndexes,
                                 UInt32Value *argSizeIndexes,
                                 UInt32Value* returnAddress);

    static
    void callSelfRecursiveFunction_S(bool isTailCall,
                                     UInt32Value* &PC,
                                     UInt32Value* &SP,
                                     UInt32Value *entryPoint,
                                     UInt32Value argIndex,
                                     UInt32Value* returnAddress);

    static
    void callSelfRecursiveFunction_D(bool isTailCall,
                                     UInt32Value* &PC,
                                     UInt32Value* &SP,
                                     UInt32Value *entryPoint,
                                     UInt32Value argIndex,
                                     UInt32Value* returnAddress);

    static
    void callSelfRecursiveFunction_V(bool isTailCall,
                                     UInt32Value* &PC,
                                     UInt32Value* &SP,
                                     UInt32Value *entryPoint,
                                     UInt32Value argIndex,
                                     UInt32Value lastArgSize,
                                     UInt32Value* returnAddress);

    static
    void callSelfRecursiveFunction_M(bool isTailCall,
                                     UInt32Value* &PC,
                                     UInt32Value* &SP,
                                     UInt32Value *entryPoint,
                                     UInt32Value argsCount,
                                     UInt32Value *argIndexes,
                                     UInt32Value *argSizeIndexes,
                                     UInt32Value* returnAddress);

    static
    void raiseException
    (UInt32Value* &SP, UInt32Value* &PC, Cell* &ENV, Cell exceptionValue);

    INLINE_FUN static
    void LoadConstString(UInt32Value* ConstStringAddress,
                         UInt32Value* length,
                         UInt32Value** stringBuffer);

    INLINE_FUN static
    Cell* getNestedBlock(Cell* block, UInt32Value nestLevel);

    static
    void printStackTrace(UInt32Value *PC, UInt32Value* SP);

    static 
    void signalHandler(int signal);

    static
    void setSignalHandler();

    static
    void resetSignalHandler();

    ///////////////////////////////////////////////////////////////////////////
    // Concretization of class RootSet
  public:

    virtual
    void trace(RootTracer* tracer)
        throw(IMLRuntimeException);

};

/**
 *
 *  The execution monitoring facility is enabled if the
 * IML_ENABLE_EXECUTION_MONITORING compilation flag is set.
 *
 * ToDo : this name is too lengthy...
 */
class VirtualMachineExecutionMonitor
{
    ///////////////////////////////////////////////////////////////////////////

  public:

    /**
     *  The virtual machine calls this method just before execution of a
     * executable.
     *
     * @param executable the executable to be executed
     * @param PC the PC register
     * @param ENV the ENV register
     * @param SP the SP register
     */
    virtual
    void beforeExecution(Executable* &executable,
                         UInt32Value* &PC,
                         Cell* &ENV,
                         UInt32Value* &SP)
    {
        // default implementation
    };

    /**
     *  The virtual machine calls this method just after execution of a
     * executable.
     *
     *  The machine state at the end of execution is passed as arguments.
     * 
     * @param PC the PC register
     * @param ENV the ENV register
     * @param SP the SP register
     */
    virtual
    void afterExecution(UInt32Value* &PC,
                        Cell* &ENV,
                        UInt32Value* &SP)
    {
        // default implementation
    };

    /**
     *  The virtual machine calls this method just before executing each
     * instruction.
     *
     *  The machine state is passed as arguments.
     *  
     * @param PC the PC register
     * @param ENV the ENV register
     * @param SP the SP register
     */
    virtual
    void beforeInstruction(UInt32Value* &PC,
                           Cell* &ENV,
                           UInt32Value* &SP)
    {
        // default implementation
    };

    /**
     *  The virtual machine calls this method just after executing each
     * instruction.
     *
     *  The machine state is passed as arguments.
     *  
     * @param PC the PC register
     * @param previousPC points to the instruction last executed
     * @param ENV the ENV register
     * @param SP the SP register
     */
    virtual
    void afterInstruction(UInt32Value* &PC,
                          UInt32Value* &previousPC,
                          Cell* &ENV,
                          UInt32Value* &SP)
    {
        // default implementation
    };

};

END_NAMESPACE

#endif // VirtualMachine_hh_
