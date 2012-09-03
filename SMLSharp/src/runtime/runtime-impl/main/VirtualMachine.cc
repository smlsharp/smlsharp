/**
 * Implementation of IML Virtual Machine.
 * @author YAMATODANI Kiyoshi
 * @version $Id: VirtualMachine.cc,v 1.91 2008/01/12 09:27:58 kiyoshiy Exp $
 */
#include <stdio.h>
#include <string>
#include <signal.h>

#include "Heap.hh"
#include "Primitives.hh"
#include "Constants.hh"
#include "PrimitiveSupport.hh"
#include "Instructions.hh"
#include "LargeInt.hh"
#include "NoEnoughHeapException.hh"
#include "VirtualMachine.hh"
#include "IllegalArgumentException.hh"
#include "IllegalStateException.hh"
#include "FFIException.hh"
#include "InterruptedException.hh"
#include "Log.hh"
#include "Debug.hh"
#include "FFI.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

typedef LargeInt::largeInt largeInt;

///////////////////////////////////////////////////////////////////////////////

const SInt32Value MIN_SINT32 = -0x80000000L;
const SInt32Value MAX_SINT32 = 0x7FFFFFFFL;

const int PRIMITIVE_MAX_ARGUMENTS = 256;

const int CLOSURE_ENTRYPOINT_INDEX = 0;
const int CLOSURE_ENV_INDEX = 1;
const int CLOSURE_BITMAP = 2;
const int CLOSURE_FIELDS_COUNT = 2;
const int FUNENTRY_FRAMESIZE_INDEX = 1;
const int FUNENTRY_STARTADDRESS_INDEX = 2;
const int FUNENTRY_ARGDESTS_INDEX = 4;

const int FINALIZABLE_BITMAP = 3;

const int INDEX_OF_NEST_POINTER = 0;

// Use non-NULL as dummy, to avoid assertion failure
UInt32Value * const RETURN_ADDRESS_OF_INITIAL_FRAME = (UInt32Value*)-1;

///////////////////////////////////////////////////////////////////////////////
// macro for heap access

#define HEAP_GETFIELD(block, index) \
(block)[(index)]

#define HEAP_GETREAL64FIELD(block, index) \
*(Real64Value*)((block) + (index))


///////////////////////////////////////////////////////////////////////////////

UInt32Value* VirtualMachine::SP_ = 0;

UInt32Value* VirtualMachine::FrameStack::frameStack_ = 0;
UInt32Value* VirtualMachine::FrameStack::frameStackBottom_ = 0;

VirtualMachine* VirtualMachine::instance_ = 0;
Session* VirtualMachine::session_ = 0;

const char* VirtualMachine::name_ = 0;
const char* VirtualMachine::executableImageName_ = NULL;
int VirtualMachine::argumentsCount_ = 0;
const char** VirtualMachine::arguments_ = 0;

bool VirtualMachine::isPrimitiveExceptionRaised_ = false;
Cell VirtualMachine::primitiveException_;

UInt32Value* VirtualMachine::HandlerStack::stack_ = 0;
UInt32Value* VirtualMachine::HandlerStack::stackTop_ = 0;
UInt32Value* VirtualMachine::HandlerStack::currentTop_ = 0;

VirtualMachine::BlockPointerVector VirtualMachine::globalArrays_;

VirtualMachine::BlockPointerRefList VirtualMachine::temporaryPointers_;

bool VirtualMachine::interrupted_ = false;
void (*VirtualMachine::prevSIGINTHandler_)(int) = NULL;
jmp_buf VirtualMachine::onSIGFPE_jmp_buf;
void (*VirtualMachine::prevSIGFPEHandler_)(int) = NULL;
void (*VirtualMachine::prevSIGPIPEHandler_)(int) = NULL;

VirtualMachine::ImportSymbolMap VirtualMachine::importSymbolMap_;
VirtualMachine::ExportSymbolMap VirtualMachine::exportSymbolMap_;

#ifdef IML_ENABLE_EXECUTION_MONITORING
VirtualMachine::MonitorList VirtualMachine::executionMonitors_;
#endif

///////////////////////////////////////////////////////////////////////////////
// Primitive operators.

INLINE_FUN
static
SInt32Value divInt(SInt32Value left, SInt32Value right){
    /* div rounds toward negative infinity. */
    if(0 == right){
        Cell exn = PrimitiveSupport::constructExnDiv();
        PrimitiveSupport::raiseException(exn);
        return 0;
    }
    if((MIN_SINT32 == left) && (-1 == right)){
        Cell exn = PrimitiveSupport::constructExnOverflow();
        PrimitiveSupport::raiseException(exn);
        return 0;
    }
    div_t temp;
    /* The return value of of ::div is rounded towards 0.
     * We have to adjust it towards negative infinity, if the denominator is
     * negative.
     * This calculation should be the same with native backend.
     * See src/compiler/rtl/main/X86Select.sml.
     */
    temp = ::div(left, right);
    SInt32Value q = temp.quot + ((temp.quot < 0 && temp.rem != 0) ? -1 : 0);
    return q;
}

INLINE_FUN
static
SInt32Value quotInt(SInt32Value left, SInt32Value right){
    /* quot rounds toward 0. */
    if(0 == right){
        Cell exn = PrimitiveSupport::constructExnDiv();
        PrimitiveSupport::raiseException(exn);
        return 0;
    }
    if((MIN_SINT32 == left) && (-1 == right)){
        Cell exn = PrimitiveSupport::constructExnOverflow();
        PrimitiveSupport::raiseException(exn);
        return 0;
    }
    div_t temp;
    /* ::div rounds toward 0 always. */
    temp = ::div(left, right);
    return temp.quot;
}

INLINE_FUN
static
SInt32Value modInt(SInt32Value left, SInt32Value right){
    if(0 == right){
        Cell exn = PrimitiveSupport::constructExnDiv();
        PrimitiveSupport::raiseException(exn);
        return 0;
    }
    if((MIN_SINT32 == left) && (-1 == right)){
        /* On cygwin, ::div(MIN_SINT32, -1) raises an arithmetic signal. */
        return 0;
    }
    div_t temp;
    /* modInt is the partner of divInt.
     * See divInt.
     */
    temp = ::div(left, right);
    SInt32Value r = temp.rem + ((temp.quot < 0 && temp.rem != 0) ? right : 0);
    return r;
}

INLINE_FUN
static
SInt32Value remInt(SInt32Value left, SInt32Value right){
    if(0 == right){
        Cell exn = PrimitiveSupport::constructExnDiv();
        PrimitiveSupport::raiseException(exn);
        return 0;
    }
    if((MIN_SINT32 == left) && (-1 == right)){
        /* On cygwin, ::div(MIN_SINT32, -1) raises an arithmetic signal. */
        return 0;
    }
    div_t temp;
    /* remInt is the partner of quotInt. */
    temp = ::div(left, right);
    return temp.rem;
}

INLINE_FUN
static
UInt32Value divWord(UInt32Value left, UInt32Value right){
    if(0 == right){
        Cell exn = PrimitiveSupport::constructExnDiv();
        PrimitiveSupport::raiseException(exn);
        return 0;
    }
    UInt32Value q = left / right;
    return q;
}

INLINE_FUN
static
UInt32Value modWord(UInt32Value left, UInt32Value right){
    if(0 == right){
        Cell exn = PrimitiveSupport::constructExnDiv();
        PrimitiveSupport::raiseException(exn);
        return 0;
    }
    UInt32Value r = left % right;
    return r;
}

INLINE_FUN
static
ByteValue divByte(ByteValue left, ByteValue right){
    if(0 == right){
        Cell exn = PrimitiveSupport::constructExnDiv();
        PrimitiveSupport::raiseException(exn);
        return 0;
    }
    ByteValue q = left / right;
    return q;
}

INLINE_FUN
static
ByteValue modByte(ByteValue left, ByteValue right){
    if(0 == right){
        Cell exn = PrimitiveSupport::constructExnDiv();
        PrimitiveSupport::raiseException(exn);
        return 0;
    }
    ByteValue r = left % right;
    return r;
}

INLINE_FUN
static
UInt32Value leftShift(UInt32Value left, UInt32Value right){
    if(right < 32){
        return left << right;
    }
    else{return 0;}
}

INLINE_FUN
static
UInt32Value logicalRightShift(UInt32Value left, UInt32Value right)
{
    UInt32Value result = 0;
    /* Shift instruction of x86 architecture considers only lower 5bits of
     * shift count (= right).
     * It results incorrect value, if shift count is equal or mora then 32.
     * In those cases, 0 should be returned.
     */
    if(right < 32){
        /* It is undefined in C that >> operator is logical or arithmetic.
         * So, we first right-shift bits except the MSB.
         * Then, we obtain right-shift value of the MSB by left-shifting 1.
         */
        result = (0x7FFFFFFFUL & left) >> right;
        if(0x80000000UL & left){// MSB is 1
            result |= 0x1UL << (31 - right);// if right = 31, shift 0 bit.
        }
    }
    return result;
}

INLINE_FUN
static
UInt32Value arithmeticRightShift(UInt32Value left, UInt32Value right)
{
    if(right < 32){
        UInt32Value result = left >> right;
        if(0x80000000UL & left){// MSB is 1
            // set all bits higher than (31 - right)th bit.
            result |= ((UInt32Value)-1L) << (32 - right);
        }
        return result;
    }
    else{
        return ((SInt32Value)left) < 0 ? (UInt32Value)-1 : 0;
    }
}

INLINE_FUN
static
UInt32Value byteToIntX(UInt32Value arg)
{
    if(arg & 0x80){
        return (arg | 0xFFFFFF00);
    }
    else{
        return arg;
    }
}

INLINE_FUN
static
UInt32Value intToByte(UInt32Value arg)
{
    return (arg & 0xFF);
}

///////////////////////////////////////////////////////////////////////////////

VirtualMachine::VirtualMachine(const char* name,
                               const char* executableImageName,
                               const int argumentsCount,
                               const char** arguments,
                               const int stackSize)
{
    name_ = name;
    executableImageName_ = executableImageName;
    argumentsCount_ = argumentsCount;
    arguments_ = arguments;
    DBGWRAP(LOG.debug("VM: argc = %d", argumentsCount_);)

    FrameStack::initialize(stackSize);
    SP_ = FrameStack::getBottom();

    HandlerStack::initialize(stackSize);

    globalArrays_.clear();
    temporaryPointers_.clear();
    importSymbolMap_.clear();
    exportSymbolMap_.clear();

#ifdef IML_ENABLE_EXECUTION_MONITORING
    executionMonitors_.clear();
#endif

    instance_ = this;
}

VirtualMachine::~VirtualMachine()
{
    FrameStack::finalize();
    HandlerStack::finalize();
}

///////////////////////////////////////////////////////////////////////////////

void
VirtualMachine::setSession(Session* session)
{
    session_ = session;
}

Session*
VirtualMachine::getSession()
{
    return session_;
}

void
VirtualMachine::
addExecutionMonitor(VirtualMachineExecutionMonitor* monitor)
{
#ifdef IML_ENABLE_EXECUTION_MONITORING
    executionMonitors_.push_front(monitor);
#endif
}

///////////////////////////////////////////////////////////////////////////////

/**
 * <code>INVOKE_ON_MONITORS</code>(<i>methodCall</i>) invokes <i>methodCall</i>
 * on each monitors in the <code>executionMonitors_</code>.
 *
 * <p>
 *  <i>methodCall</i> specifies the method and arguments to be passed.
 * </p>
 *
 */
#ifdef IML_ENABLE_EXECUTION_MONITORING
#define INVOKE_ON_MONITORS(methodCall) \
    { \
        for(MonitorList::iterator _i_ = executionMonitors_.begin() ; \
            _i_ != executionMonitors_.end() ; \
            _i_++){ \
            VirtualMachineExecutionMonitor* _monitor_ = *_i_; \
            _monitor_->methodCall; \
        } \
    }
#else
#define INVOKE_ON_MONITORS(method)
#endif

////////////////////////////////////////

#define SAVE_REGISTERS \
{ SP_ = SP; }

#define RESTORE_REGISTERS \
{ /* restore of SP is not needed. */ }

#define ALLOCATE_RECORDBLOCK(ret, bitmap, number) \
{ \
    SAVE_REGISTERS; \
    Cell* _block_ = Heap::allocRecordBlock((bitmap), (number)); \
    RESTORE_REGISTERS; \
    ret = _block_; \
}

#define ALLOCATE_ATOMBLOCK(ret, number) \
{ \
    SAVE_REGISTERS; \
    Cell* _block_ = Heap::allocAtomBlock((number)); \
    RESTORE_REGISTERS; \
    ret = _block_; \
}

#define ALLOCATE_POINTERBLOCK(ret, number) \
{ \
    SAVE_REGISTERS; \
    Cell* _block_ = Heap::allocPointerBlock((number)); \
    RESTORE_REGISTERS; \
    ret = _block_; \
}

#define ALLOCATE_SINGLEATOMARRAY(ret, number, isMutable) \
{ \
    SAVE_REGISTERS; \
    Cell* _block_ = Heap::allocSingleAtomArray((number), isMutable); \
    RESTORE_REGISTERS; \
    ret = _block_; \
}

#define ALLOCATE_DOUBLEATOMARRAY(ret, number, isMutable) \
{ \
    SAVE_REGISTERS; \
    Cell* _block_ = Heap::allocDoubleAtomArray((number), isMutable); \
    RESTORE_REGISTERS; \
    ret = _block_; \
}

#define ALLOCATE_POINTERARRAY(ret, number, isMutable) \
{ \
    SAVE_REGISTERS; \
    Cell* _block_ = Heap::allocPointerArray((number), isMutable); \
    RESTORE_REGISTERS; \
    ret = _block_; \
}

#define ALLOCATE_STRINGBLOCK(ret, buffer, length) \
{ \
    SAVE_REGISTERS; \
    Cell _block_ = \
    PrimitiveSupport::stringToCell((const char*)(buffer), (length)); \
    RESTORE_REGISTERS; \
    ret = _block_.blockRef; \
}

#define ALLOCATE_LARGEINTBLOCK(ret, largeIntPtr) \
{ \
    SAVE_REGISTERS; \
    Cell* _block_ = Heap::allocLargeIntBlock((largeIntPtr)); \
    RESTORE_REGISTERS; \
    ret = _block_; \
}

#define ALLOCATE_EMPTYBLOC(ret) \
{ \
    ret = Heap::allocEmptyBlock(); \
}

/**
 * fetches 4-byte word from an instruction stream and increment the pointer.
 *
 * @param pc head of an instruction stream
 * @return the 4-byte word which <code>pc</code> points to.
 */
INLINE_FUN
static
UInt32Value getWordAndInc(UInt32Value* &pc)
{
    // the following codes are equal to "return *(pc++);"
    UInt32Value value = *pc;
    pc += 1;
    return value;
}

///////////////////////////////////////////////////////////////////////////////

//  The below macro for register optimization is copied from 'interp.c' in
// the OCaml distribution.

/* Register optimization.
   Some compilers underestimate the use of the local variables representing
   the abstract machine registers, and don't put them in hardware registers,
   which slows down the interpreter considerably.
   For GCC, I have hand-assigned hardware registers for several architectures.
*/
/*
#if defined(__GNUC__) && !defined(IML_DEBUG)
#ifdef __mips__
#define PC_REG asm("$16")
#define SP_REG asm("$17")
#define AC_REG asm("$18")
#endif
#ifdef __sparc__
#define PC_REG asm("%l0")
#define SP_REG asm("%l1")
#define AC_REG asm("%l2")
#endif
#ifdef __alpha__
#ifdef __CRAY__
#define PC_REG asm("r9")
#define SP_REG asm("r10")
#define AC_REG asm("r11")
#define JUMPTBL_BASE_REG asm("r12")
#else
#define PC_REG asm("$9")
#define SP_REG asm("$10")
#define AC_REG asm("$11")
#define JUMPTBL_BASE_REG asm("$12")
#endif
#endif
#ifdef __i386__
//#define PC_REG asm("%esi")
//#define SP_REG asm("%edi")
#define PC_REG
#define SP_REG
#define AC_REG
#endif
#if defined(PPC) || defined(_POWER) || defined(_IBMR2)
#define PC_REG asm("26")
#define SP_REG asm("27")
#define AC_REG asm("28")
#endif
#ifdef __hppa__
#define PC_REG asm("%r18")
#define SP_REG asm("%r17")
#define AC_REG asm("%r16")
#endif
#ifdef __mc68000__
#define PC_REG asm("a5")
#define SP_REG asm("a4")
#define AC_REG asm("d7")
#endif
#ifdef __arm__
#define PC_REG asm("r9")
#define SP_REG asm("r8")
#define AC_REG asm("r7")
#endif
#ifdef __ia64__
#define PC_REG asm("36")
#define SP_REG asm("37")
#define AC_REG asm("38")
#define JUMPTBL_BASE_REG asm("39")
#endif
#ifdef __x86_64__
#define PC_REG asm("%r15")
#define SP_REG asm("%r14")
#define AC_REG asm("%r13")
#endif
#endif
*/
////////////////////////////////////////

INLINE_FUN
void
VirtualMachine::expandClosure(UInt32Value* SP,
                              UInt32Value closureIndex,
                              UInt32Value* &entryPoint,
                              Cell* &calleeENV)
{
    ASSERT(FrameStack::isPointerSlot(SP, closureIndex));
    Cell* closure = FRAME_ENTRY(SP, closureIndex).blockRef;
    ASSERT(Heap::isValidBlockPointer(closure));
    ASSERT(CLOSURE_FIELDS_COUNT == Heap::getPayloadSize(closure));
    ASSERT(CLOSURE_BITMAP == Heap::getBitmap(closure));

    entryPoint =
    (UInt32Value*)(HEAP_GETFIELD(closure, CLOSURE_ENTRYPOINT_INDEX).uint32);

    ASSERT(Heap::isPointerField(closure, CLOSURE_ENV_INDEX));
    calleeENV = (Cell*)(HEAP_GETFIELD(closure, CLOSURE_ENV_INDEX).uint32);
    ASSERT(Heap::isValidBlockPointer(calleeENV));
}

void
VirtualMachine::printStackTrace(UInt32Value *PC, UInt32Value* SP)
{
    char buffer[256];

    Executable* executable = FrameStack::getExecutableOfFrame(SP);
    UInt32Value offset = PC - (UInt32Value*)(executable->code_);
    IPToString(buffer, sizeof(buffer), executable, offset);
    PrimitiveSupport::writeToSTDOUT(strlen(buffer), buffer);
    PrimitiveSupport::writeToSTDOUT(strlen("\n"), "\n");

    UInt32Value *cursorSP = SP;
    UInt32Value* const stackBottom = FrameStack::getBottom();
    while((!interrupted_) && (stackBottom != cursorSP))
    {
        /*  get the instruction offset and the Executable of
         * the call instruction which created the current
         * frame. The offset of the call instruction is stored
         * in the current (= callee) frame. The Executable is
         * obtained in the upper (= caller) frame.
         */
        UInt32Value* returnAddress = FrameStack::getReturnAddress(cursorSP);
        if(RETURN_ADDRESS_OF_INITIAL_FRAME == returnAddress)
        {
            /* The initial frame does not have its return
             * address. */
            break;
        }

        cursorSP = FrameStack::getNextFrame(cursorSP);
        ASSERT(cursorSP);

        executable = FrameStack::getExecutableOfFrame(cursorSP);
        offset = returnAddress - executable->code_;

        IPToString(buffer, sizeof(buffer), executable, offset);
        PrimitiveSupport::writeToSTDOUT(strlen(buffer), buffer);
        PrimitiveSupport::writeToSTDOUT(strlen("\n"), "\n");
    }
    if(interrupted_){
        DBGWRAP(LOG.debug("printStackTrace is interrupted.");)
    }
}

INLINE_FUN
UInt32Value*
VirtualMachine::getFunInfo(UInt32Value *entryPoint,
                           UInt32Value &frameSize,
                           UInt32Value &arity,
                           UInt32Value* &argDests,
                           UInt32Value &bitmapvalsFreesCount,
                           UInt32Value * &bitmapvalsFrees,
                           UInt32Value &bitmapvalsArgsCount,
                           UInt32Value * &bitmapvalsArgs,
                           UInt32Value * &funInfoAddress)
{
    /* get function parameter out of FunEntry instruction */
    UInt32Value *PC = entryPoint;
    funInfoAddress = entryPoint;
    PC += 1;
    frameSize = getWordAndInc(PC);
    UInt32Value* startAddress = (UInt32Value*)getWordAndInc(PC);
    arity = getWordAndInc(PC); // arity does not include ENV.
    argDests = PC; // argDests does not include ENV.
    PC += arity;
    bitmapvalsFreesCount = getWordAndInc(PC);
    bitmapvalsFrees = PC;
    PC += bitmapvalsFreesCount;
    bitmapvalsArgsCount = getWordAndInc(PC);
    bitmapvalsArgs = PC;
    return startAddress;
}

INLINE_FUN
Bitmap
VirtualMachine::composeBitmap(UInt32Value* SP,
                              UInt32Value* argIndexes,
                              Cell* calleeENV,
                              UInt32Value bitmapvalsFreesCount,
                              UInt32Value * bitmapvalsFrees,
                              UInt32Value bitmapvalsArgsCount,
                              UInt32Value * bitmapvalsArgs)
{
    /* compose bitmap value */
    Bitmap bitmap = (Bitmap)0;
    ASSERT((0 == bitmapvalsFreesCount) || (bitmapvalsFreesCount == 1));
    if(bitmapvalsFreesCount){
        bitmap = HEAP_GETFIELD(calleeENV, *bitmapvalsFrees).uint32;
    }
/*
    for(int index = 0; index < bitmapvalsFreesCount; index += 1){
        ASSERT(!Heap::isPointerField(calleeENV, *bitmapvalsFrees));
        bitmap << 1;
        bitmap |= HEAP_GETFIELD(calleeENV, *bitmapvalsFrees).uint32;
        bitmapvalsFrees += 1;
    }
*/
    /* the least significant bit of the frame bitmap is obtained from the bit
     * which is obtained from the first bitmap argument.
     */
    for(int index = bitmapvalsArgsCount - 1; 0 <= index ; index -= 1)
    {
        UInt32Value bitmapvalsArgIndex = bitmapvalsArgs[index];
        UInt32Value argIndex = argIndexes[bitmapvalsArgIndex];
        ASSERT(!FrameStack::isPointerSlot(SP, argIndex));

        Bitmap newBit = FRAME_ENTRY(SP, argIndex).uint32;
        // assert that the new bit is 1 bit width.
        ASSERT((0 == newBit) || (1 == newBit));
        // assert that the most significant bit of bitmap is zero.
        ASSERT(0 == (bitmap & (1 << (FrameStack::BITMAP_BIT_WIDTH - 1))));

        bitmap <<= 1;
        bitmap |= newBit;
    }
    return bitmap;
}

INLINE_FUN
UInt32Value*
VirtualMachine::getFunInfoAndBitmap(UInt32Value* SP,
                                    UInt32Value *entryPoint,
                                    Cell* calleeENV,
                                    UInt32Value* argIndexes,
                                    UInt32Value &frameSize,
                                    UInt32Value &arity,
                                    UInt32Value* &argDests,
                                    UInt32Value* &funInfoAddress,
                                    Bitmap &bitmap)
{
    UInt32Value bitmapvalsFreesCount;
    UInt32Value *bitmapvalsFrees;
    UInt32Value bitmapvalsArgsCount;
    UInt32Value *bitmapvalsArgs;

    UInt32Value* PC = getFunInfo(entryPoint,
                                 frameSize,
                                 arity,
                                 argDests,
                                 bitmapvalsFreesCount,
                                 bitmapvalsFrees,
                                 bitmapvalsArgsCount,
                                 bitmapvalsArgs,
                                 funInfoAddress);

    bitmap = composeBitmap(SP,
                           argIndexes,
                           calleeENV,
                           bitmapvalsFreesCount,
                           bitmapvalsFrees,
                           bitmapvalsArgsCount,
                           bitmapvalsArgs);

    return PC;
}

INLINE_FUN
void
VirtualMachine::tailCallFunction_0(UInt32Value* &PC,
                                   UInt32Value* &SP,
                                   Cell* &ENV,
                                   UInt32Value *entryPoint,
                                   Cell* calleeENV)
{
    UInt32Value frameSize;
    UInt32Value arity;
    UInt32Value* argDests; 
    UInt32Value *funInfoAddress;
    Bitmap bitmap;

    PC = getFunInfoAndBitmap(SP,
                             entryPoint,
                             calleeENV,
                             (UInt32Value *)NULL,
                             frameSize,
                             arity,
                             argDests,
                             funInfoAddress,
                             bitmap);

    SP = FrameStack::replaceFrame(SP, frameSize, bitmap, funInfoAddress);

    /* set registers */
    ENV = calleeENV;
}


INLINE_FUN
void
VirtualMachine::callFunction_0(UInt32Value* &PC,
                               UInt32Value* &SP,
                               Cell* &ENV,
                               UInt32Value *entryPoint,
                               Cell* calleeENV,
                               UInt32Value* returnAddress)
{
    UInt32Value frameSize;
    UInt32Value arity;
    UInt32Value* argDests; 
    UInt32Value *funInfoAddress;
    Bitmap bitmap;

    PC = getFunInfoAndBitmap(SP,
                             entryPoint,
                             calleeENV,
                             (UInt32Value *)NULL,
                             frameSize,
                             arity,
                             argDests,
                             funInfoAddress,
                             bitmap);

    ASSERT(returnAddress);
    /* allocate new frame for non tail-call */
    SP = FrameStack::allocateFrame(SP,
                                   frameSize,
                                   bitmap,
                                   funInfoAddress,
                                   returnAddress);
    
    /* set registers */
    ENV = calleeENV;
}


INLINE_FUN
void
VirtualMachine::tailCallFunction_S(UInt32Value* &PC,
                                   UInt32Value* &SP,
                                   Cell* &ENV,
                                   UInt32Value *entryPoint,
                                   Cell* calleeENV,
                                   UInt32Value argIndex)
{
    UInt32Value frameSize;
    UInt32Value arity;
    UInt32Value* argDests;
    UInt32Value *funInfoAddress;
    Bitmap bitmap;

    PC = getFunInfoAndBitmap(SP,
                             entryPoint,
                             calleeENV,
                             &argIndex,
                             frameSize,
                             arity,
                             argDests,
                             funInfoAddress,
                             bitmap);


    Cell savedArg = FRAME_ENTRY(SP, argIndex);    

    /* replace frame for tail call */
    UInt32Value* calleeSP =
    FrameStack::replaceFrame(SP, frameSize, bitmap, funInfoAddress);

    /* copy arguments from the caller to the callee */
    FRAME_ENTRY(calleeSP, *argDests) = savedArg;
    ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);

    SP = calleeSP;

    /* set registers */
    ENV = calleeENV;
}

INLINE_FUN
void
VirtualMachine::callFunction_S(UInt32Value* &PC,
                               UInt32Value* &SP,
                               Cell* &ENV,
                               UInt32Value *entryPoint,
                               Cell* calleeENV,
                               UInt32Value argIndex,
                               UInt32Value* returnAddress)
{
    UInt32Value frameSize;
    UInt32Value arity;
    UInt32Value* argDests;
    UInt32Value *funInfoAddress;
    Bitmap bitmap;

    PC = getFunInfoAndBitmap(SP,
                             entryPoint,
                             calleeENV,
                             &argIndex,
                             frameSize,
                             arity,
                             argDests,
                             funInfoAddress,
                             bitmap);

    ASSERT(returnAddress);
    /* allocate new frame for non tail-call */
    UInt32Value* calleeSP = FrameStack::allocateFrame(SP,
                                                      frameSize,
                                                      bitmap,
                                                      funInfoAddress,
                                                      returnAddress);

    /* copy arguments from the caller to the callee */
    ASSERT_SAME_TYPE_SLOTS(calleeSP, *argDests, SP, argIndex);
    FRAME_ENTRY(calleeSP, *argDests) = FRAME_ENTRY(SP, argIndex);
    ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);

    SP = calleeSP;

    /* set registers */
    ENV = calleeENV;
}

INLINE_FUN
void
VirtualMachine::tailCallFunction_D(UInt32Value* &PC,
                                   UInt32Value* &SP,
                                   Cell* &ENV,
                                   UInt32Value *entryPoint,
                                   Cell* calleeENV,
                                   UInt32Value argIndex)
{
    UInt32Value frameSize;
    UInt32Value arity;
    UInt32Value* argDests;
    UInt32Value *funInfoAddress;
    Bitmap bitmap;

    PC = getFunInfoAndBitmap(SP,
                             entryPoint,
                             calleeENV,
                             &argIndex,
                             frameSize,
                             arity,
                             argDests,
                             funInfoAddress,
                             bitmap);


    Real64Value savedArg;
    ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, argIndex));
    savedArg = *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, argIndex);
    
    /* replace frame for tail call */
    UInt32Value* calleeSP =
    FrameStack::replaceFrame(SP, frameSize, bitmap, funInfoAddress);

    /* copy arguments from the caller to the callee */
    ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(calleeSP, *argDests));
    *(Real64Value*)FRAME_ENTRY_ADDRESS(calleeSP, *argDests) = savedArg;
    ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
    ASSERT_VALID_FRAME_VAR(calleeSP, (*argDests) + 1);

    SP = calleeSP;

    /* set registers */
    ENV = calleeENV;
}

INLINE_FUN
void
VirtualMachine::callFunction_D(UInt32Value* &PC,
                               UInt32Value* &SP,
                               Cell* &ENV,
                               UInt32Value *entryPoint,
                               Cell* calleeENV,
                               UInt32Value argIndex,
                               UInt32Value* returnAddress)
{
    UInt32Value frameSize;
    UInt32Value arity;
    UInt32Value* argDests;
    UInt32Value *funInfoAddress;
    Bitmap bitmap;

    PC = getFunInfoAndBitmap(SP,
                             entryPoint,
                             calleeENV,
                             &argIndex,
                             frameSize,
                             arity,
                             argDests,
                             funInfoAddress,
                             bitmap);

    ASSERT(returnAddress);
    /* allocate new frame for non tail-call */
    UInt32Value* calleeSP = FrameStack::allocateFrame(SP,
                                                      frameSize,
                                                      bitmap,
                                                      funInfoAddress,
                                                      returnAddress);

    /* copy arguments from the caller to the callee */
    ASSERT_SAME_TYPE_SLOTS(calleeSP, *argDests, SP, argIndex);
    ASSERT_SAME_TYPE_SLOTS(calleeSP, (*argDests) + 1, SP, argIndex + 1);

    ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(calleeSP, *argDests));
    ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, argIndex));
    *(Real64Value*)FRAME_ENTRY_ADDRESS(calleeSP, *argDests) =
    *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, argIndex);
    ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
    ASSERT_VALID_FRAME_VAR(calleeSP, (*argDests) + 1);

    SP = calleeSP;

    /* set registers */
    ENV = calleeENV;
}

INLINE_FUN
void
VirtualMachine::tailCallFunction_MS(UInt32Value* &PC,
                                    UInt32Value* &SP,
                                    Cell* &ENV,
                                    UInt32Value *entryPoint,
                                    Cell* calleeENV,
                                    UInt32Value* argIndexes)
{
    UInt32Value frameSize;
    UInt32Value arity;
    UInt32Value* argDests;
    UInt32Value *funInfoAddress;
    Bitmap bitmap;

    PC = getFunInfoAndBitmap(SP,
                             entryPoint,
                             calleeENV,
                             argIndexes,
                             frameSize,
                             arity,
                             argDests,
                             funInfoAddress,
                             bitmap);

    Cell savedArgs[arity];
    for(int index = 0; index < arity; index += 1){
        savedArgs[index] = FRAME_ENTRY(SP, *argIndexes);
        argIndexes += 1;
    }
    
    /* replace frame for tail call */
    UInt32Value* calleeSP =
    FrameStack::replaceFrame(SP, frameSize, bitmap, funInfoAddress);

    /* copy arguments from the caller to the callee */
    for(int index = 0; index < arity; index += 1){
        FRAME_ENTRY(calleeSP, *argDests) = savedArgs[index];
        ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
        argDests += 1;
    }

    SP = calleeSP;

    /* set registers */
    ENV = calleeENV;
}


INLINE_FUN
void
VirtualMachine::callFunction_MS(UInt32Value* &PC,
                                UInt32Value* &SP,
                                Cell* &ENV,
                                UInt32Value *entryPoint,
                                Cell* calleeENV,
                                UInt32Value* argIndexes,
                                UInt32Value* returnAddress)
{
    UInt32Value frameSize;
    UInt32Value arity;
    UInt32Value* argDests;
    UInt32Value *funInfoAddress;
    Bitmap bitmap;

    PC = getFunInfoAndBitmap(SP,
                             entryPoint,
                             calleeENV,
                             argIndexes,
                             frameSize,
                             arity,
                             argDests,
                             funInfoAddress,
                             bitmap);

    ASSERT(returnAddress);
    /* allocate new frame for non tail-call */
    UInt32Value* calleeSP = FrameStack::allocateFrame(SP,
                                                      frameSize,
                                                      bitmap,
                                                      funInfoAddress,
                                                      returnAddress);

    /* copy arguments from the caller to the callee */
    for(int index = 0; index < arity; index += 1){
        ASSERT_SAME_TYPE_SLOTS(calleeSP, *argDests, SP, *argIndexes);
        FRAME_ENTRY(calleeSP, *argDests) = FRAME_ENTRY(SP, *argIndexes);
        ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
        argIndexes += 1;
        argDests += 1;
    }

    SP = calleeSP;

    /* set registers */
    ENV = calleeENV;
}

INLINE_FUN
void
VirtualMachine::tailCallFunction_MLD(UInt32Value* &PC,
                                     UInt32Value* &SP,
                                     Cell* &ENV,
                                     UInt32Value *entryPoint,
                                     Cell* calleeENV,
                                     UInt32Value* argIndexes)
{
    UInt32Value frameSize;
    UInt32Value arity;
    UInt32Value* argDests;
    UInt32Value *funInfoAddress;
    Bitmap bitmap;

    PC = getFunInfoAndBitmap(SP,
                             entryPoint,
                             calleeENV,
                             argIndexes,
                             frameSize,
                             arity,
                             argDests,
                             funInfoAddress,
                             bitmap);

    Cell savedArgs[arity+1];
    Cell *ptr = savedArgs;
    for(int index = 1; index < arity; index += 1){
        *ptr = FRAME_ENTRY(SP, *argIndexes);
        argIndexes += 1;
        ptr += 1;
    }
    ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, *argIndexes));
    *ptr = FRAME_ENTRY(SP, *argIndexes);
    *(ptr + 1) = FRAME_ENTRY(SP, (*argIndexes) + 1);


    
    /* replace frame for tail call */
    UInt32Value* calleeSP =
    FrameStack::replaceFrame(SP, frameSize, bitmap, funInfoAddress);

    /* copy arguments from the caller to the callee */
    ptr = savedArgs;
    for(int index = 1; index < arity; index += 1){
        FRAME_ENTRY(calleeSP, *argDests) = *ptr;
        ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
        argDests += 1;
        ptr += 1;
    }
    ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(calleeSP, *argDests));
    FRAME_ENTRY(calleeSP, *argDests) = *ptr;
    FRAME_ENTRY(calleeSP, (*argDests) + 1) = *(ptr + 1);
    ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
    ASSERT_VALID_FRAME_VAR(calleeSP, (*argDests) + 1);
    SP = calleeSP;

    /* set registers */
    ENV = calleeENV;
}

INLINE_FUN
void
VirtualMachine::callFunction_MLD(UInt32Value* &PC,
                                 UInt32Value* &SP,
                                 Cell* &ENV,
                                 UInt32Value *entryPoint,
                                 Cell* calleeENV,
                                 UInt32Value* argIndexes,
                                 UInt32Value* returnAddress)
{
    UInt32Value frameSize;
    UInt32Value arity;
    UInt32Value* argDests;
    UInt32Value *funInfoAddress;
    Bitmap bitmap;

    PC = getFunInfoAndBitmap(SP,
                             entryPoint,
                             calleeENV,
                             argIndexes,
                             frameSize,
                             arity,
                             argDests,
                             funInfoAddress,
                             bitmap);

    ASSERT(returnAddress);
    /* allocate new frame for non tail-call */
    UInt32Value* calleeSP = FrameStack::allocateFrame(SP,
                                                      frameSize,
                                                      bitmap,
                                                      funInfoAddress,
                                                      returnAddress);

    /* copy arguments from the caller to the callee */
    for(int index = 1; index < arity; index += 1){
        ASSERT_SAME_TYPE_SLOTS(calleeSP, *argDests, SP, *argIndexes);
        FRAME_ENTRY(calleeSP, *argDests) = FRAME_ENTRY(SP, *argIndexes);
        ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
        argIndexes += 1;
        argDests += 1;
    }
    ASSERT_SAME_TYPE_SLOTS(calleeSP, *argDests, SP, *argIndexes);
    ASSERT_SAME_TYPE_SLOTS(calleeSP, (*argDests) + 1, SP, (*argIndexes) + 1);
    ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, *argIndexes));
    ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(calleeSP, *argDests));
    *(Real64Value*)FRAME_ENTRY_ADDRESS(calleeSP, *argDests) = 
    *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, *argIndexes);
    ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
    ASSERT_VALID_FRAME_VAR(calleeSP, (*argDests) + 1);
    SP = calleeSP;

    /* set registers */
    ENV = calleeENV;
}

INLINE_FUN
void
VirtualMachine::tailCallFunction_MF(UInt32Value* &PC,
                                    UInt32Value* &SP,
                                    Cell* &ENV,
                                    UInt32Value *entryPoint,
                                    Cell* calleeENV,
                                    UInt32Value* argIndexes,
                                    UInt32Value* argSizes)
{
    UInt32Value frameSize;
    UInt32Value arity;
    UInt32Value* argDests;
    UInt32Value *funInfoAddress;
    Bitmap bitmap;

    PC = getFunInfoAndBitmap(SP,
                             entryPoint,
                             calleeENV,
                             argIndexes,
                             frameSize,
                             arity,
                             argDests,
                             funInfoAddress,
                             bitmap);

    Cell savedArgs[arity * 2];
    Cell *ptr = savedArgs;
    for(int index = 0; index < arity; index += 1){
        UInt32Value argSize = argSizes[index];
        ASSERT((1 == argSize) || (2 == argSize));
        if ( 1 == argSize) {
            *ptr = FRAME_ENTRY(SP, *argIndexes);
            ptr += 1;
        } else {
            ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, *argIndexes));
            *ptr = FRAME_ENTRY(SP, *argIndexes);
            *(ptr + 1) = FRAME_ENTRY(SP, (*argIndexes) + 1);
            ptr += 2;
        }
        argIndexes += 1;
    }
    
    /* replace frame for tail call */
    UInt32Value* calleeSP =
    FrameStack::replaceFrame(SP, frameSize, bitmap, funInfoAddress);

    /* copy arguments from the caller to the callee */
    ptr = savedArgs;
    for(int index = 0; index < arity; index += 1){
        if (1 == argSizes[index]) {
            FRAME_ENTRY(calleeSP, *argDests) = *ptr;
            ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
            ptr += 1;
        } else {
            ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(calleeSP, *argDests));
            FRAME_ENTRY(calleeSP, *argDests) = *ptr;
            FRAME_ENTRY(calleeSP, (*argDests) + 1) = *(ptr + 1);
            ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
            ASSERT_VALID_FRAME_VAR(calleeSP, (*argDests) + 1);
            ptr += 2;
        }
        argDests += 1;
    }

    SP = calleeSP;

    /* set registers */
    ENV = calleeENV;
}

INLINE_FUN
void
VirtualMachine::callFunction_MF(UInt32Value* &PC,
                                UInt32Value* &SP,
                                Cell* &ENV,
                                UInt32Value *entryPoint,
                                Cell* calleeENV,
                                UInt32Value* argIndexes,
                                UInt32Value* argSizes,
                                UInt32Value* returnAddress)
{
    UInt32Value frameSize;
    UInt32Value arity;
    UInt32Value* argDests;
    UInt32Value *funInfoAddress;
    Bitmap bitmap;

    PC = getFunInfoAndBitmap(SP,
                             entryPoint,
                             calleeENV,
                             argIndexes,
                             frameSize,
                             arity,
                             argDests,
                             funInfoAddress,
                             bitmap);

    ASSERT(returnAddress);
    /* allocate new frame for non tail-call */
    UInt32Value* calleeSP = FrameStack::allocateFrame(SP,
                                                      frameSize,
                                                      bitmap,
                                                      funInfoAddress,
                                                      returnAddress);

    /* copy arguments from the caller to the callee */
    for(int index = 0; index < arity; index += 1){
        UInt32Value argSize = argSizes[index];
        ASSERT((1 == argSize) || (2 == argSize));
        ASSERT_SAME_TYPE_SLOTS(calleeSP, *argDests, SP, *argIndexes);
        if (1 == argSize) {
            FRAME_ENTRY(calleeSP, *argDests) = FRAME_ENTRY(SP, *argIndexes);
            ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
        } else {
            ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, *argIndexes));
            ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(calleeSP, *argDests));
            *(Real64Value*)FRAME_ENTRY_ADDRESS(calleeSP, *argDests) = 
            *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, *argIndexes);
            ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
            ASSERT_VALID_FRAME_VAR(calleeSP, (*argDests) + 1);
        }
        argIndexes += 1;
        argDests += 1;
    }

    SP = calleeSP;

    /* set registers */
    ENV = calleeENV;
}

INLINE_FUN
void
VirtualMachine::tailCallFunction_MV(UInt32Value* &PC,
                                    UInt32Value* &SP,
                                    Cell* &ENV,
                                    UInt32Value *entryPoint,
                                    Cell* calleeENV,
                                    UInt32Value* argIndexes,
                                    UInt32Value* argSizeIndexes)
{
    UInt32Value frameSize;
    UInt32Value arity;
    UInt32Value* argDests;
    UInt32Value *funInfoAddress;
    Bitmap bitmap;

    PC = getFunInfoAndBitmap(SP,
                             entryPoint,
                             calleeENV,
                             argIndexes,
                             frameSize,
                             arity,
                             argDests,
                             funInfoAddress,
                             bitmap);

    Cell savedArgs[arity * 2];
    UInt32Value savedArgSizes[arity];
    Cell *ptr = savedArgs;
    for(int index = 0; index < arity; index += 1){
        UInt32Value argSize = FRAME_ENTRY(SP, argSizeIndexes[index]).uint32;
        ASSERT((1 == argSize) || (2 == argSize));
        if (1 == argSize) {
            *ptr = FRAME_ENTRY(SP, *argIndexes);
            ptr += 1;
        } else {
            ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, *argIndexes));
            *ptr = FRAME_ENTRY(SP, *argIndexes);
            *(ptr + 1) = FRAME_ENTRY(SP, (*argIndexes) + 1);
            ptr += 2;
        }
        savedArgSizes[index] = argSize;
        argIndexes += 1;
    }
    
    /* replace frame for tail call */
    UInt32Value* calleeSP =
    FrameStack::replaceFrame(SP, frameSize, bitmap, funInfoAddress);

    /* copy arguments from the caller to the callee */
    ptr = savedArgs;
    for(int index = 0; index < arity; index += 1){
        UInt32Value argSize = savedArgSizes[index];
        if (1 == argSize) {
            FRAME_ENTRY(calleeSP, *argDests) = *ptr;
            ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
            ptr += 1;
        } else {
            ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(calleeSP, *argDests));
            FRAME_ENTRY(calleeSP, *argDests) = *ptr;
            FRAME_ENTRY(calleeSP, (*argDests) + 1) = *(ptr + 1);
            ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
            ASSERT_VALID_FRAME_VAR(calleeSP, (*argDests) + 1);
            ptr += 2;
        }
        argDests += 1;
    }

    SP = calleeSP;

    /* set registers */
    ENV = calleeENV;
}

INLINE_FUN
void
VirtualMachine::callFunction_MV(UInt32Value* &PC,
                                UInt32Value* &SP,
                                Cell* &ENV,
                                UInt32Value *entryPoint,
                                Cell* calleeENV,
                                UInt32Value* argIndexes,
                                UInt32Value* argSizeIndexes,
                                UInt32Value* returnAddress)
{
    UInt32Value frameSize;
    UInt32Value arity;
    UInt32Value* argDests;
    UInt32Value *funInfoAddress;
    Bitmap bitmap;

    PC = getFunInfoAndBitmap(SP,
                             entryPoint,
                             calleeENV,
                             argIndexes,
                             frameSize,
                             arity,
                             argDests,
                             funInfoAddress,
                             bitmap);

    ASSERT(returnAddress);
    /* allocate new frame for non tail-call */
    UInt32Value* calleeSP = FrameStack::allocateFrame(SP,
                                                      frameSize,
                                                      bitmap,
                                                      funInfoAddress,
                                                      returnAddress);

    /* copy arguments from the caller to the callee */
    for(int index = 0; index < arity; index += 1){
        ASSERT_SAME_TYPE_SLOTS(calleeSP, *argDests, SP, *argIndexes);
        UInt32Value argSize = FRAME_ENTRY(SP, argSizeIndexes[index]).uint32;
        ASSERT((1 == argSize) || (2 == argSize));
        if (1 == argSize) {
            FRAME_ENTRY(calleeSP, *argDests) = FRAME_ENTRY(SP, *argIndexes);
            ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
        } else {
            ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, *argIndexes));
            ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(calleeSP, *argDests));
            *(Real64Value*)FRAME_ENTRY_ADDRESS(calleeSP, *argDests) = 
            *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, *argIndexes);
            ASSERT_VALID_FRAME_VAR(calleeSP, *argDests);
            ASSERT_VALID_FRAME_VAR(calleeSP, (*argDests) + 1);
        }
        argIndexes += 1;
        argDests += 1;
    }

    SP = calleeSP;

    /* set registers */
    ENV = calleeENV;
}

/**
 * recursive call can optimize frame allocation.
 * Tail call can reuse the caller frame.
 * Non-tail call has only to copy the caller frame.
 */
INLINE_FUN
void
VirtualMachine::tailCallRecursiveFunction_0(UInt32Value* &PC,
                                            UInt32Value *entryPoint)
{
    PC = (UInt32Value *)(entryPoint[FUNENTRY_STARTADDRESS_INDEX]);
}

INLINE_FUN
void
VirtualMachine::callRecursiveFunction_0(UInt32Value* &PC,
                                        UInt32Value* &SP,
                                        UInt32Value *entryPoint,
                                        UInt32Value* returnAddress)
{
    UInt32Value frameSize =  entryPoint[FUNENTRY_FRAMESIZE_INDEX];
    PC = (UInt32Value *) (entryPoint[FUNENTRY_STARTADDRESS_INDEX]);
    ASSERT(returnAddress);
    SP = FrameStack::duplicateFrame(SP, frameSize, returnAddress);
}

INLINE_FUN
void
VirtualMachine::tailCallRecursiveFunction_S(UInt32Value* &PC,
                                            UInt32Value* &SP,
                                            UInt32Value *entryPoint,
                                            UInt32Value argIndex)
{


//     UInt32Value frameSize;
//     UInt32Value* argDests;
//     UInt32Value* funInfoAddress;
//     PC = getFunInfoForSelfRecursiveCall(entryPoint,frameSize,argDests,funInfoAddress);

    UInt32Value *argDests = entryPoint + FUNENTRY_ARGDESTS_INDEX;
    PC = (UInt32Value *) (entryPoint[FUNENTRY_STARTADDRESS_INDEX]);

    ASSERT_SAME_TYPE_SLOTS(SP, *argDests, SP, argIndex);
    FRAME_ENTRY(SP, *argDests) = FRAME_ENTRY(SP, argIndex);
}

INLINE_FUN
void
VirtualMachine::callRecursiveFunction_S(UInt32Value* &PC,
                                        UInt32Value* &SP,
                                        UInt32Value *entryPoint,
                                        UInt32Value argIndex,
                                        UInt32Value* returnAddress)
{
    UInt32Value *argDests = entryPoint + FUNENTRY_ARGDESTS_INDEX;
    UInt32Value frameSize =  entryPoint[FUNENTRY_FRAMESIZE_INDEX];
    PC = (UInt32Value *) (entryPoint[FUNENTRY_STARTADDRESS_INDEX]);

    UInt32Value* calleeSP;
    ASSERT(returnAddress);
    calleeSP = FrameStack::duplicateFrame(SP, frameSize, returnAddress);

    ASSERT_SAME_TYPE_SLOTS(calleeSP, *argDests, SP, argIndex);
    FRAME_ENTRY(calleeSP, *argDests) = FRAME_ENTRY(SP, argIndex);

    SP = calleeSP;
}

INLINE_FUN
void
VirtualMachine::tailCallRecursiveFunction_D(UInt32Value* &PC,
                                            UInt32Value* &SP,
                                            UInt32Value *entryPoint,
                                            UInt32Value argIndex)
{
    UInt32Value *argDests = entryPoint + FUNENTRY_ARGDESTS_INDEX;
    PC = (UInt32Value *) (entryPoint[FUNENTRY_STARTADDRESS_INDEX]);

    ASSERT_SAME_TYPE_SLOTS(SP, *argDests, SP, argIndex);
    ASSERT_SAME_TYPE_SLOTS(SP, (*argDests) + 1, SP, argIndex + 1);
    ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, *argDests));
    ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, argIndex));

    *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, *argDests) = 
    *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, argIndex);
}

INLINE_FUN
void
VirtualMachine::callRecursiveFunction_D(UInt32Value* &PC,
                                        UInt32Value* &SP,
                                        UInt32Value *entryPoint,
                                        UInt32Value argIndex,
                                        UInt32Value* returnAddress)
{
    UInt32Value *argDests = entryPoint + FUNENTRY_ARGDESTS_INDEX;
    UInt32Value frameSize =  entryPoint[FUNENTRY_FRAMESIZE_INDEX];
    PC = (UInt32Value *) (entryPoint[FUNENTRY_STARTADDRESS_INDEX]);

    UInt32Value* calleeSP;
    ASSERT(returnAddress);
    calleeSP = FrameStack::duplicateFrame(SP, frameSize, returnAddress);

    ASSERT_SAME_TYPE_SLOTS(calleeSP, *argDests, SP, argIndex);
    ASSERT_SAME_TYPE_SLOTS(calleeSP, (*argDests) + 1, SP, argIndex + 1);
    ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(calleeSP, *argDests));
    ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, argIndex));

    *(Real64Value*)FRAME_ENTRY_ADDRESS(calleeSP, *argDests) = 
    *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, argIndex);

    SP = calleeSP;
}

INLINE_FUN
void
VirtualMachine::tailCallRecursiveFunction_MS(UInt32Value* &PC,
                                             UInt32Value* &SP,
                                             UInt32Value *entryPoint,
                                             UInt32Value argsCount,
                                             UInt32Value *argIndexes)
{
    UInt32Value *argDests = entryPoint + FUNENTRY_ARGDESTS_INDEX;
    PC = (UInt32Value *) (entryPoint[FUNENTRY_STARTADDRESS_INDEX]);

    Cell savedArgs[argsCount];
    for(int index = 0; index < argsCount; index += 1){
        savedArgs[index] = FRAME_ENTRY(SP, *argIndexes);
        argIndexes += 1;
    }

    for(int index = 0; index < argsCount; index += 1){
        FRAME_ENTRY(SP, *argDests) = savedArgs[index];
        argDests += 1;
    }
}

INLINE_FUN
void
VirtualMachine::callRecursiveFunction_MS(UInt32Value* &PC,
                                         UInt32Value* &SP,
                                         UInt32Value *entryPoint,
                                         UInt32Value argsCount,
                                         UInt32Value *argIndexes,
                                         UInt32Value* returnAddress)
{
    UInt32Value *argDests = entryPoint + FUNENTRY_ARGDESTS_INDEX;
    UInt32Value frameSize =  entryPoint[FUNENTRY_FRAMESIZE_INDEX];
    PC = (UInt32Value *) (entryPoint[FUNENTRY_STARTADDRESS_INDEX]);

    UInt32Value* calleeSP;
    ASSERT(returnAddress);
    calleeSP = FrameStack::duplicateFrame(SP, frameSize, returnAddress);
        
    for(int index = 0; index < argsCount; index += 1){
        ASSERT_SAME_TYPE_SLOTS(calleeSP, *argDests, SP, *argIndexes);
        FRAME_ENTRY(calleeSP, *argDests) = FRAME_ENTRY(SP, *argIndexes);
        argIndexes += 1;
        argDests += 1;
    }

    SP = calleeSP;
}

INLINE_FUN
void
VirtualMachine::tailCallRecursiveFunction_MLD(UInt32Value* &PC,
                                              UInt32Value* &SP,
                                              UInt32Value *entryPoint,
                                              UInt32Value argsCount,
                                              UInt32Value *argIndexes)
{
    UInt32Value *argDests = entryPoint + FUNENTRY_ARGDESTS_INDEX;
    PC = (UInt32Value *) (entryPoint[FUNENTRY_STARTADDRESS_INDEX]);

    Cell savedArgs[argsCount + 1];
    Cell *ptr = savedArgs;
    for(int index = 1; index < argsCount; index += 1){
        *ptr = FRAME_ENTRY(SP, *argIndexes);
        argIndexes += 1;
        ptr += 1;
    }
    *ptr = FRAME_ENTRY(SP, *argIndexes);
    *(ptr + 1) = FRAME_ENTRY(SP, (*argIndexes) + 1);

    ptr = savedArgs;
    for(int index = 1; index < argsCount; index += 1){
        FRAME_ENTRY(SP, *argDests) = *ptr;
        argDests += 1;
        ptr += 1;
    }
    FRAME_ENTRY(SP, *argDests) = *ptr;
    FRAME_ENTRY(SP, (*argDests) + 1) = *(ptr + 1);
}

INLINE_FUN
void
VirtualMachine::callRecursiveFunction_MLD(UInt32Value* &PC,
                                          UInt32Value* &SP,
                                          UInt32Value *entryPoint,
                                          UInt32Value argsCount,
                                          UInt32Value *argIndexes,
                                          UInt32Value* returnAddress)
{
    UInt32Value *argDests = entryPoint + FUNENTRY_ARGDESTS_INDEX;
    UInt32Value frameSize =  entryPoint[FUNENTRY_FRAMESIZE_INDEX];
    PC = (UInt32Value *) (entryPoint[FUNENTRY_STARTADDRESS_INDEX]);

    UInt32Value* calleeSP;
    ASSERT(returnAddress);
    calleeSP = FrameStack::duplicateFrame(SP, frameSize, returnAddress);
        
    for(int index = 1; index < argsCount; index += 1){
        ASSERT_SAME_TYPE_SLOTS(calleeSP, *argDests, SP, *argIndexes);
        FRAME_ENTRY(calleeSP, *argDests) = FRAME_ENTRY(SP, *argIndexes);
        argIndexes += 1;
        argDests += 1;
    }
    *(Real64Value*)FRAME_ENTRY_ADDRESS(calleeSP, *argDests) = 
    *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, *argIndexes);

    SP = calleeSP;
}

INLINE_FUN
void
VirtualMachine::tailCallRecursiveFunction_MF(UInt32Value* &PC,
                                             UInt32Value* &SP,
                                             UInt32Value *entryPoint,
                                             UInt32Value argsCount,
                                             UInt32Value *argIndexes,
                                             UInt32Value *argSizes)
{
    UInt32Value *argDests = entryPoint + FUNENTRY_ARGDESTS_INDEX;
    PC = (UInt32Value *) (entryPoint[FUNENTRY_STARTADDRESS_INDEX]);

    Cell savedArgs[argsCount * 2];
    Cell *ptr = savedArgs;
    for(int index = 0; index < argsCount; index += 1){
        UInt32Value argSize = argSizes[index];
        ASSERT((argSize == 1) || (argSize == 2))
        if (1 == argSize) {
            *ptr = FRAME_ENTRY(SP, *argIndexes);
            ptr += 1;
        } else {
            *ptr = FRAME_ENTRY(SP, *argIndexes);
            *(ptr + 1) = FRAME_ENTRY(SP, (*argIndexes) + 1);
            ptr += 2;
        }
        argIndexes += 1;
    }
    ptr = savedArgs;
    for(int index = 0; index < argsCount; index += 1){
        UInt32Value argSize = argSizes[index];
        if (1 == argSize) {
            FRAME_ENTRY(SP, *argDests) = *ptr;
            ptr += 1;
        } else {
            FRAME_ENTRY(SP, *argDests) = *ptr;
            FRAME_ENTRY(SP, (*argDests) + 1) = *(ptr + 1);
            ptr += 2;
        }
        argDests += 1;
    }
}

INLINE_FUN
void
VirtualMachine::callRecursiveFunction_MF(UInt32Value* &PC,
                                         UInt32Value* &SP,
                                         UInt32Value *entryPoint,
                                         UInt32Value argsCount,
                                         UInt32Value *argIndexes,
                                         UInt32Value *argSizes,
                                         UInt32Value* returnAddress)
{
    UInt32Value *argDests = entryPoint + FUNENTRY_ARGDESTS_INDEX;
    UInt32Value frameSize =  entryPoint[FUNENTRY_FRAMESIZE_INDEX];
    PC = (UInt32Value *) (entryPoint[FUNENTRY_STARTADDRESS_INDEX]);

    UInt32Value* calleeSP;
    ASSERT(returnAddress);
    calleeSP = FrameStack::duplicateFrame(SP, frameSize, returnAddress);
        
    for(int index = 0; index < argsCount; index += 1){
        UInt32Value argSize = argSizes[index];
        ASSERT_SAME_TYPE_SLOTS(calleeSP, *argDests, SP, *argIndexes);
        ASSERT((argSize == 1) || (argSize == 2))
        if (1 == argSize) {
            FRAME_ENTRY(calleeSP, *argDests) = FRAME_ENTRY(SP, *argIndexes);
        } else {
            *(Real64Value*)FRAME_ENTRY_ADDRESS(calleeSP, *argDests) = 
            *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, *argIndexes);
        }
        argIndexes += 1;
        argDests += 1;
    }

    SP = calleeSP;
}

INLINE_FUN
void
VirtualMachine::tailCallRecursiveFunction_MV(UInt32Value* &PC,
                                             UInt32Value* &SP,
                                             UInt32Value *entryPoint,
                                             UInt32Value argsCount,
                                             UInt32Value *argIndexes,
                                             UInt32Value *argSizeIndexes)
{
    UInt32Value *argDests = entryPoint + FUNENTRY_ARGDESTS_INDEX;
    PC = (UInt32Value *) (entryPoint[FUNENTRY_STARTADDRESS_INDEX]);

    Cell savedArgs[argsCount * 2];
    UInt32Value argSizes[argsCount];
    Cell *ptr = savedArgs;
    for(int index = 0; index < argsCount; index += 1){
        UInt32Value argSize = FRAME_ENTRY(SP, *argSizeIndexes).uint32;
        ASSERT((argSize == 1) || (argSize == 2))
        if (1 == argSize) {
            *ptr = FRAME_ENTRY(SP, *argIndexes);
            ptr += 1;
        } else {
            *ptr = FRAME_ENTRY(SP, *argIndexes);
            *(ptr + 1) = FRAME_ENTRY(SP, (*argIndexes) + 1);
            ptr += 2;
        }
        argSizes[index] = argSize;
        argIndexes += 1;
        argSizeIndexes += 1;
    }
    ptr = savedArgs;
    for(int index = 0; index < argsCount; index += 1){
        UInt32Value argSize = argSizes[index];
        if (1 == argSize) {
            FRAME_ENTRY(SP, *argDests) = *ptr;
            ptr += 1;
        } else {
            FRAME_ENTRY(SP, *argDests) = *ptr;
            FRAME_ENTRY(SP, (*argDests) + 1) = *(ptr + 1);
            ptr += 2;
        }
        argDests += 1;
    }
}

INLINE_FUN
void
VirtualMachine::callRecursiveFunction_MV(UInt32Value* &PC,
                                         UInt32Value* &SP,
                                         UInt32Value *entryPoint,
                                         UInt32Value argsCount,
                                         UInt32Value *argIndexes,
                                         UInt32Value *argSizeIndexes,
                                         UInt32Value* returnAddress)
{
    UInt32Value *argDests = entryPoint + FUNENTRY_ARGDESTS_INDEX;
    UInt32Value frameSize =  entryPoint[FUNENTRY_FRAMESIZE_INDEX];
    PC = (UInt32Value *) (entryPoint[FUNENTRY_STARTADDRESS_INDEX]);

    UInt32Value* calleeSP;
    ASSERT(returnAddress);
    calleeSP = FrameStack::duplicateFrame(SP, frameSize, returnAddress);
        
    for(int index = 0; index < argsCount; index += 1){
        UInt32Value argSize = FRAME_ENTRY(SP, *argSizeIndexes).uint32;
        ASSERT((argSize == 1) || (argSize == 2))
        if (1 == argSize) {
            ASSERT_SAME_TYPE_SLOTS(calleeSP, *argDests, SP, *argIndexes);
            FRAME_ENTRY(calleeSP, *argDests) = FRAME_ENTRY(SP, *argIndexes);
        } else {
            ASSERT_SAME_TYPE_SLOTS(calleeSP, *argDests, SP, *argIndexes);
            ASSERT_SAME_TYPE_SLOTS(calleeSP, (*argDests + 1), SP, (*argIndexes) + 1);
            *(Real64Value*)FRAME_ENTRY_ADDRESS(calleeSP, *argDests) = 
            *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, *argIndexes);
        }
        argIndexes += 1;
        argSizeIndexes += 1;
        argDests += 1;
    }

    SP = calleeSP;
}

INLINE_FUN
void 
VirtualMachine::raiseException(UInt32Value* &SP,
                               UInt32Value* &PC,
                               Cell* &ENV,
                               Cell exceptionValue)
{
    DBGWRAP(LOG.debug("raiseException begin");)
    ASSERT(Heap::isValidBlockPointer(exceptionValue.blockRef));

    // find the handler to invoke
    UInt32Value* restoredSP;
    UInt32Value exceptionDestinationIndex;
    UInt32Value* handlerAddress;
    HandlerStack::pop(restoredSP, exceptionDestinationIndex, handlerAddress);
    FrameStack::popFramesUntil(SP, restoredSP);
    FrameStack::loadENV(SP, ENV);

    ASSERT(FrameStack::isPointerSlot(SP, exceptionDestinationIndex));
    FRAME_ENTRY(SP, exceptionDestinationIndex) = exceptionValue;
    PC = handlerAddress;
    DBGWRAP(LOG.debug("raiseException end");)
}

INLINE_FUN
void
VirtualMachine::LoadConstString(UInt32Value* ConstStringAddress,
                                UInt32Value* length,
                                UInt32Value** stringBuffer)
{
    ConstStringAddress += 1;
    *length = getWordAndInc(ConstStringAddress);
    *stringBuffer = ConstStringAddress;
}

INLINE_FUN
Real64Value
VirtualMachine::LoadConstReal64(UInt32Value* ConstRealAddress)
{
    Real64Value buffer;
    *(UInt32Value*)&buffer = *ConstRealAddress;
    *(((UInt32Value*)&buffer) + 1) = *(ConstRealAddress + 1);
    return buffer;
}

INLINE_FUN
Real32Value
VirtualMachine::LoadConstReal32(UInt32Value* ConstRealAddress)
{
    Real32Value buffer;
    *(UInt32Value*)&buffer = *ConstRealAddress;
    return buffer;
}

INLINE_FUN
Cell*
VirtualMachine::getNestedBlock(Cell* block, UInt32Value nestLevel)
{
    Cell* current = block;
    for(int index = nestLevel; 0 < index; index -= 1){
        ASSERT(Heap::isPointerField(current, INDEX_OF_NEST_POINTER));
        current = HEAP_GETFIELD(current, INDEX_OF_NEST_POINTER).blockRef;
        ASSERT(Heap::isValidBlockPointer(current));
    }
    return current;
}

void
VirtualMachine::execute(Executable* executable)
    throw(IMLException)
{
    // initialize machine registers
    UInt32Value* PC = (UInt32Value*)(executable->code_);
    Cell* ENV = NULL;
    SP_ = FrameStack::getBottom();
    HandlerStack::clear();

    interrupted_ = false;
    setSignalHandler();

    isPrimitiveExceptionRaised_ = false;
    temporaryPointers_.clear();

    DBGWRAP(UInt32Value* const frameStackTop = SP_);
    DBGWRAP(UInt32Value* const handlerStackTop = HandlerStack::getTop());
    DBGWRAP(int const temporaryPointersCount = temporaryPointers_.size());

    // NOTE : the state of this machine might be modified by monitors.
    INVOKE_ON_MONITORS(beforeExecution(executable, PC, ENV, SP_));

    // Call the main function. This sets up initial frame.
    UInt32Value* entryPoint = (UInt32Value*)(executable->code_);
    // the main function never refers to arguments
    UInt32Value argIndexes[] = {0, 0};
    Cell* emptyENV = 0;
    callFunction_MS(PC,
                    SP_,
                    ENV, // emptyEnv is assigned to ENV there.
                    entryPoint,
                    emptyENV,
                    argIndexes,
                    RETURN_ADDRESS_OF_INITIAL_FRAME);

    executeLoop(PC, ENV);
    // main code ends with Exit instruciton, not with Return instruction.
    FrameStack::popFrameAndReturn(SP_, PC);

    // global status should not leave any change.
    ASSERT(temporaryPointersCount == temporaryPointers_.size());
    ASSERT(frameStackTop == SP_);
    ASSERT(handlerStackTop == HandlerStack::getTop());
}

UInt32Value VirtualMachine::executeFunction(UncaughtExceptionHandleMode mode,
                                            UInt32Value *entryPoint,
                                            Cell *env,
                                            Cell *returnValue,
                                            bool returnBoxed,
                                            FFI::Arguments &args)
    throw(IMLException)
{
    /* Calculate layout of caller stack frame */
    UInt32Value arity = args.arity();
    // pointers
    UInt32Value exnIndex       = FRAME_FIRST_POINTER_SLOT;
    UInt32Value boxedReturn    = exnIndex       + 1;
    UInt32Value boxedArgs      = boxedReturn    + 1;
    // atoms
    UInt32Value argIndexes     = boxedArgs      + arity;
    UInt32Value argSizeIndexes = argIndexes     + arity;
    UInt32Value argSizes       = argSizeIndexes + arity;
    UInt32Value unboxedReturn  = argSizes       + arity + argSizes % 2;
    UInt32Value unboxedArgs    = unboxedReturn  + 2;
    UInt32Value frameSize      = unboxedArgs    + 2 * arity - 1;
    frameSize += frameSize % 2;

    UInt32Value returnEntry = returnBoxed ? boxedReturn : unboxedReturn;

    UInt32Value pointersCount  = argIndexes - exnIndex;
    UInt32Value atomsCount     = frameSize + 1 - argIndexes;

    /* Body of caller */
    UInt32Value insn[] = {
        5,   /* word length of instructions, excluding this header. */
        /* 1: */ LoadInt,                  // dummy
        /* 2: */ 0,                        // dummy
        /* 3: */ 0,                        // returnEntry
        /* 4: */ PopHandler,
        /* 5: */ Exit,
    };
    Executable executable(insn[0], insn);

    UInt32Value *returnAddress = &insn[3];
    UInt32Value *dummyStartAddress = &insn[1];
    UInt32Value *handlerAddress = &insn[5];
    *returnAddress = returnEntry;

    /* FunInfo of caller */
    UInt32Value funinfo[] = {
        (UInt32Value)&executable,        // executable (dummy)
        frameSize,                       // frame size
        (UInt32Value)&dummyStartAddress, // startAddress (dummy)
        0,                               // arity
        0,                               // bitmapvalsFreesCount
        0,                               // bitmapvalsArgsCount
        pointersCount,                   // pointersCount
        atomsCount,                      // atomsCount
        0,                               // recordGroupsCount
    };

    UInt32Value* PC = 0;

    /* Allocate frame stack of caller */
    SP_ = FrameStack::allocateFrame(SP_,
                                    frameSize,   // frame size
                                    0x0,         // bitmap
				    funinfo,
				    PC);// this return address is never used.

    /* Get informations of callee */
    UInt32Value closFrameSize;
    UInt32Value closArity, *closArgDests;
    UInt32Value closFreesCount, *closFrees;
    UInt32Value closArgsCount, *closArgs;
    UInt32Value *closFunInfoAddr;

    getFunInfo(entryPoint, closFrameSize, closArity, closArgDests,
               closFreesCount, closFrees, closArgsCount, closArgs,
               closFunInfoAddr);

    ASSERT(args.arity() == closArity);

    /* Setup arguments */
    for (UInt32Value i = 0; i < closArity; ++i, ++args) {
        Cell *value = args.value();
        UInt32Value size = args.size();
        bool boxed = args.boxed();
        UInt32Value &index = boxed ? boxedArgs : unboxedArgs;

        FRAME_ENTRY(SP_, argSizes + i).uint32 = size;
        FRAME_ENTRY(SP_, argSizeIndexes + i).uint32 = argSizes + i;

        FRAME_ENTRY(SP_, argIndexes + i).uint32 = index;
        FRAME_ENTRY(SP_, index++) = value[0];
        if (size > 1) FRAME_ENTRY(SP_, index++) = value[1];
    }

    /* PushHandler */
    HandlerStack::push(SP_, exnIndex, handlerAddress);

    /* Apply_M */
    Cell* dummyENV = NULL;
    FrameStack::storeENV(SP_, dummyENV);
    callFunction_MV(PC,                        /* PC is changed here.*/
                    SP_,                        /* SP */
                    dummyENV,                  /* ENV */
                    entryPoint,                 /* entryPoint */
                    env,                        /* calleeENV */
                    &FRAME_ENTRY(SP_, argIndexes).uint32,    /* argIndexes */
                    &FRAME_ENTRY(SP_, argSizeIndexes).uint32,/* argSizeIndexes */
                    returnAddress);             /* returnAddress */
    executeLoop(PC, dummyENV);
    
    /* check whether exception was raised */
    if (FRAME_ENTRY(SP_, FRAME_FIRST_POINTER_SLOT + 0).blockRef != 0) {
        /* FIXME: an exception was raised */
        switch(mode){
          case Ignore:
            break;
          case Longjump:
            break;
        }
    }

    returnValue[0] = FRAME_ENTRY(SP_, returnEntry);
    returnValue[1] = FRAME_ENTRY(SP_, returnEntry + 1);

    FrameStack::popFrameAndReturn(SP_, PC);
}

class SinglePointerArgument
    : public FFI::Arguments
{
  protected:
    void next() {}
    
  public:
    SinglePointerArgument(Cell *p) : FFI::Arguments(p) {}
    UInt32Value arity() { return 1; }
    UInt32Value size() { return 1; }
    bool boxed() { return true; }
};

/*
 * 'PA' means 
 *   P - the 1st argument is Pointer type.
 *   A - the return type is Atom type.
 */
UInt32Value VirtualMachine::executeClosure_PA(UncaughtExceptionHandleMode mode,
                                              Cell closure,
                                              Cell *arg)
    throw(IMLException)
{
    Cell ret[2];
    // Note : initialize args with a pointer to the argument.
    SinglePointerArgument args((Cell*)&arg);

    ASSERT(Heap::isValidBlockPointer(closure.blockRef));
    ASSERT(CLOSURE_FIELDS_COUNT == Heap::getPayloadSize(closure.blockRef));
    ASSERT(CLOSURE_BITMAP == Heap::getBitmap(closure.blockRef));
    UInt32Value *entryPoint = 
        (UInt32Value*)
        (HEAP_GETFIELD(closure.blockRef, CLOSURE_ENTRYPOINT_INDEX).uint32);
    Cell *env =
    (Cell*)(HEAP_GETFIELD(closure.blockRef, CLOSURE_ENV_INDEX).uint32);

    // false indicates return type is Atom.
    executeFunction(mode, entryPoint, env, ret, false, args);
    return ret[0].uint32;
}

void
VirtualMachine::executeLoop(UInt32Value* startPC, Cell* initialENV)
    throw(IMLException)
{
    register UInt32Value* PC = startPC;
    register UInt32Value* SP = SP_;
    Cell* ENV = initialENV;
    TemporaryRoot rootENV((Cell*)&ENV);
    UInt32Value* previousPC = startPC;

    try{
	if(setjmp(onSIGFPE_jmp_buf))
	{
	    /* NOTE: All values of auto variables are undcidable here,
	     *       even if one of them doninates a hardware register. */
	    Cell exception =
	    PrimitiveSupport::constructExnSysErr(1, "arithmetic exception");
	    raiseException(SP, PC, ENV, exception);
	    /* fall through */
	}
	    
	// execution loop
        while(true)
        {
            if(interrupted_){ throw InterruptedException(); }

            INVOKE_ON_MONITORS(beforeInstruction(PC, ENV, SP));
#ifdef IML_ENABLE_EXECUTION_MONITORING
            previousPC = PC;
#endif
            instruction opcode = static_cast<instruction>(*PC);
            PC += 1;
            
            switch(opcode)
            {
              case LoadInt:
              case LoadWord:
              case LoadChar:
              case LoadFloat:
                {
                    UInt32Value constant = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, destination));
                    FRAME_ENTRY(SP, destination).uint32 = constant;
                    break;
                }
              case LoadLargeInt:
                {
                    largeInt *largeIntPtr = (largeInt*)getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);
//                    DBGWRAP(LOG.debug("LoadLargeInt(%d)", LargeInt::toInt(*largeIntPtr)));
                    ASSERT(FrameStack::isPointerSlot(SP, destination));
                    Cell* block;
                    ALLOCATE_LARGEINTBLOCK(block, largeIntPtr);
                    FRAME_ENTRY(SP, destination).blockRef = block;
                    break;
                }
              case LoadString:
                {
                    UInt32Value *ConstStringAddress =
                    (UInt32Value*)getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    /* 
                     * string constant is stored in the operand of ConstString
                     * instruction.
                     * The string is stored in the first W fields.
                     * W is the number of words occupied by the string.
                     * In the last field, the length(bytes) of the string is
                     * stored
                     */
                    UInt32Value stringLength;
                    UInt32Value* stringBuffer;
                    LoadConstString
                    (ConstStringAddress, &stringLength, &stringBuffer);

                    Cell* block;
                    ALLOCATE_STRINGBLOCK(block, stringBuffer, stringLength);

                    ASSERT(FrameStack::isPointerSlot(SP, destination));
                    FRAME_ENTRY(SP, destination).blockRef = block;
                    break;
                }
              case LoadReal:
                {
                    UInt32Value *floatBuffer = PC;
                    PC += (sizeof(Real64Value) / sizeof(Cell));
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, destination));
                    ASSERT(!FrameStack::isPointerSlot(SP, destination + 1));
                    ASSERT_REAL64_ALIGNED
                        (FRAME_ENTRY_ADDRESS(SP, destination));

                    /* Because instruction operand is not aligned, 
                     * we must copy word by word. */
                    FRAME_ENTRY(SP, destination).uint32 = floatBuffer[0];
                    FRAME_ENTRY(SP, destination + 1).uint32 = floatBuffer[1];
                    break;
                }
              case LoadBoxedReal:
                {
                    UInt32Value *floatBuffer = PC;
                    PC += (sizeof(Real64Value) / sizeof(Cell));
                    UInt32Value destination = getWordAndInc(PC);

                    Cell* block;
                    ALLOCATE_ATOMBLOCK
                    (block, sizeof(Real64Value) / sizeof(Cell));
                    COPY_MEMORY(block, floatBuffer, sizeof(Real64Value));

                    ASSERT(FrameStack::isPointerSlot(SP, destination));
                    FRAME_ENTRY(SP, destination).blockRef = block;
                    break;
                }
              case LoadEmptyBlock:
                {
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(FrameStack::isPointerSlot(SP, destination));
                    Cell* block;
                    ALLOCATE_EMPTYBLOC(block);
                    FRAME_ENTRY(SP, destination).blockRef = block;
                    break;
                }
              case LoadAddress:
                {
                    UInt32Value address = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, destination));
                    FRAME_ENTRY(SP, destination).uint32 = address;
                    break;
                }
              case Access_S:
                {
                    UInt32Value variableIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT_SAME_TYPE_SLOTS(SP, destination, SP, variableIndex);
                    ASSERT_VALID_FRAME_VAR(SP, variableIndex);
                    FRAME_ENTRY(SP, destination) =
                    FRAME_ENTRY(SP, variableIndex);
                    break;
                }
              case Access_D:
                {
                    UInt32Value variableIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT_SAME_TYPE_SLOTS(SP, destination, SP, variableIndex);
                    ASSERT_SAME_TYPE_SLOTS
                        (SP, destination + 1, SP, variableIndex + 1);

                    ASSERT_VALID_FRAME_VAR(SP, variableIndex);
                    ASSERT_VALID_FRAME_VAR(SP, variableIndex + 1);
                    ASSERT_REAL64_ALIGNED
                        (FRAME_ENTRY_ADDRESS(SP, destination));
                    ASSERT_REAL64_ALIGNED
                        (FRAME_ENTRY_ADDRESS(SP, variableIndex));

                    *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, destination) =
                    *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, variableIndex);

                    break;
                }
              case Access_V:
                {
                    UInt32Value variableIndex = getWordAndInc(PC);
                    UInt32Value variableSizeIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);
                    
                    ASSERT(!FrameStack::isPointerSlot(SP, variableSizeIndex));
                    UInt32Value variableSize =
                    FRAME_ENTRY(SP, variableSizeIndex).uint32;
                    if (1 == variableSize) {
                        ASSERT_SAME_TYPE_SLOTS(SP, destination, SP, variableIndex);
                        FRAME_ENTRY(SP, destination) = FRAME_ENTRY(SP, variableIndex);
                    } else {
                        ASSERT_SAME_TYPE_SLOTS(SP, destination, SP, variableIndex);
                        ASSERT_SAME_TYPE_SLOTS(SP, destination + 1, SP, variableIndex + 1);
                        *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, destination) = 
                        *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, variableIndex);
                    } 
                    break;
                }
              case AccessEnv_S:
                {
                    UInt32Value variableIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination, ENV, variableIndex);

                    FRAME_ENTRY(SP, destination) =
                    HEAP_GETFIELD(ENV, variableIndex);
                    break;
                }
              case AccessEnv_D:
                {
                    UInt32Value variableIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination, ENV, variableIndex);
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination + 1, ENV, variableIndex + 1);
                    ASSERT_REAL64_ALIGNED
                        (FRAME_ENTRY_ADDRESS(SP, destination));

                    FRAME_ENTRY(SP, destination) =
                        HEAP_GETFIELD(ENV, variableIndex);
                    FRAME_ENTRY(SP, destination + 1) =
                        HEAP_GETFIELD(ENV, variableIndex + 1);

                    break;
                }
              case AccessEnv_V:
                {
                    UInt32Value variableIndex = getWordAndInc(PC);
                    UInt32Value variableSizeIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, variableSizeIndex));
                    UInt32Value variableSize =
                        FRAME_ENTRY(SP, variableSizeIndex).uint32;

                    if (1 == variableSize) {
                        ASSERT_SAME_TYPE_SLOT_FIELD(SP, destination, ENV, variableIndex);
                        FRAME_ENTRY(SP, destination) = HEAP_GETFIELD(ENV, variableIndex);
                    } else {
                        ASSERT_SAME_TYPE_SLOT_FIELD(SP, destination, ENV, variableIndex);
                        ASSERT_SAME_TYPE_SLOT_FIELD(SP, destination + 1, ENV, variableIndex + 1);
                        *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, destination) = 
                        HEAP_GETREAL64FIELD(ENV, variableIndex);
                    }
                    break;
                }
              case AccessNestedEnv_S:
                {
                    UInt32Value nestLevel = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    Cell* block = getNestedBlock(ENV, nestLevel);

                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination, block, variableIndex);

                    FRAME_ENTRY(SP, destination) =
                        HEAP_GETFIELD(block, variableIndex);
                    break;
                }
              case AccessNestedEnv_D:
                {
                    UInt32Value nestLevel = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    Cell* block = getNestedBlock(ENV, nestLevel);

                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination, block, variableIndex);
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination + 1, block, variableIndex + 1);
                    ASSERT_REAL64_ALIGNED
                        (FRAME_ENTRY_ADDRESS(SP, destination));

                    FRAME_ENTRY(SP, destination) =
                        HEAP_GETFIELD(block, variableIndex);
                    FRAME_ENTRY(SP, destination + 1) =
                        HEAP_GETFIELD(block, variableIndex + 1);

                    break;
                }
              case AccessNestedEnv_V:
                {
                    UInt32Value nestLevel = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);
                    UInt32Value variableSizeIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    Cell* block = getNestedBlock(ENV, nestLevel);
                    ASSERT(!FrameStack::isPointerSlot(SP, variableSizeIndex));
                    UInt32Value variableSize =
                        FRAME_ENTRY(SP, variableSizeIndex).uint32;

                    if (1 == variableSize) {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                            (SP, destination,block, variableIndex);
                        FRAME_ENTRY(SP, destination) =
                            HEAP_GETFIELD(block, variableIndex);
                    } else {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                            (SP, destination,block, variableIndex);
                        ASSERT_SAME_TYPE_SLOT_FIELD
                            (SP, destination + 1,block, variableIndex + 1);
                        *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, destination) =
                            HEAP_GETREAL64FIELD(block, variableIndex);
                    }
                    break;
                }
              case GetField_S:
                {
                    UInt32Value fieldIndex = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* block = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT(fieldIndex < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination, block, fieldIndex);

                    FRAME_ENTRY(SP, destination) =
                        HEAP_GETFIELD(block, fieldIndex);
                    break;
                }
              case GetField_D:
                {
                    UInt32Value fieldIndex = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* block = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT(fieldIndex + 1 < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination, block, fieldIndex);
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination + 1, block, fieldIndex + 1);
                    ASSERT_REAL64_ALIGNED
                        (FRAME_ENTRY_ADDRESS(SP, destination));

                    FRAME_ENTRY(SP, destination) = HEAP_GETFIELD(block, fieldIndex);
                    FRAME_ENTRY(SP, destination + 1) = HEAP_GETFIELD(block, fieldIndex + 1);

                    break;
                }
              case GetField_V:
                {
                    UInt32Value fieldIndex = getWordAndInc(PC);
                    UInt32Value fieldSizeIndex = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, fieldSizeIndex));
                    UInt32Value fieldSize =
                        FRAME_ENTRY(SP, fieldSizeIndex).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* block = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT((fieldIndex + fieldSize - 1)
                           < Heap::getPayloadSize(block));
                    if (1 == fieldSize) {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                          (SP, destination, block, fieldIndex);
                        FRAME_ENTRY(SP, destination) =
                            HEAP_GETFIELD(block, fieldIndex);
                    } else {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                          (SP, destination, block, fieldIndex);
                        ASSERT_SAME_TYPE_SLOT_FIELD
                          (SP, destination + 1, block, fieldIndex + 1);
                        FRAME_ENTRY(SP, destination) = HEAP_GETFIELD(block, fieldIndex);
                        FRAME_ENTRY(SP, destination + 1) = HEAP_GETFIELD(block, fieldIndex + 1);
                    }
                    break;
                }
              case GetFieldIndirect_S:
                {
                    UInt32Value indirectOffset = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, indirectOffset));
                    UInt32Value fieldIndex =
                        FRAME_ENTRY(SP, indirectOffset).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* block = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT(fieldIndex < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination, block, fieldIndex);

                    FRAME_ENTRY(SP, destination) = HEAP_GETFIELD(block, fieldIndex);
                    break;
                }
              case GetFieldIndirect_D:
                {
                    UInt32Value indirectOffset = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, indirectOffset));
                    UInt32Value fieldIndex =
                        FRAME_ENTRY(SP, indirectOffset).uint32;

                    Cell* block = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT(fieldIndex + 1 < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination, block, fieldIndex);
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination + 1, block, fieldIndex + 1);
                    ASSERT_REAL64_ALIGNED
                        (FRAME_ENTRY_ADDRESS(SP, destination));

                    FRAME_ENTRY(SP, destination) = HEAP_GETFIELD(block, fieldIndex);
                    FRAME_ENTRY(SP, destination + 1) = HEAP_GETFIELD(block, fieldIndex + 1);

                    break;
                }
              case GetFieldIndirect_V:
                {
                    UInt32Value indirectOffset = getWordAndInc(PC);
                    UInt32Value fieldSizeIndex = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, fieldSizeIndex));
                    UInt32Value fieldSize =
                        FRAME_ENTRY(SP, fieldSizeIndex).uint32;

                    ASSERT(!FrameStack::isPointerSlot(SP, indirectOffset));
                    UInt32Value fieldIndex =
                        FRAME_ENTRY(SP, indirectOffset).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* block = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT((fieldIndex + fieldSize - 1)
                           < Heap::getPayloadSize(block));
                    ASSERT((fieldSize == 1) || (fieldSize == 2))
                    if (1 == fieldSize) {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination, block, fieldIndex);
                        FRAME_ENTRY(SP, destination) =
                            HEAP_GETFIELD(block, fieldIndex);
                    } else {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination, block, fieldIndex);
                        ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination + 1, block, fieldIndex + 1);
                        FRAME_ENTRY(SP, destination) = HEAP_GETFIELD(block, fieldIndex);
                        FRAME_ENTRY(SP, destination + 1) = HEAP_GETFIELD(block, fieldIndex + 1);
                    }
                    break;
                }
              case GetNestedField_S:
                {
                    UInt32Value nestLevel = getWordAndInc(PC);
                    UInt32Value fieldOffset = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* root = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(root));

                    Cell* block = getNestedBlock(root, nestLevel);

                    ASSERT(fieldOffset < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination, block, fieldOffset);
                    FRAME_ENTRY(SP, destination) =
                        HEAP_GETFIELD(block, fieldOffset);
                    break;
                }
              case GetNestedField_D:
                {
                    UInt32Value nestLevel = getWordAndInc(PC);
                    UInt32Value fieldOffset = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* root = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(root));

                    Cell* block = getNestedBlock(root, nestLevel);

                    ASSERT(fieldOffset + 1 < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination, block, fieldOffset);
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination + 1, block, fieldOffset + 1);
                    ASSERT_REAL64_ALIGNED
                        (FRAME_ENTRY_ADDRESS(SP, destination));

                    FRAME_ENTRY(SP, destination) = HEAP_GETFIELD(block, fieldOffset);
                    FRAME_ENTRY(SP, destination + 1) = HEAP_GETFIELD(block, fieldOffset + 1);

                    break;
                }
              case GetNestedField_V:
                {
                    UInt32Value nestLevel = getWordAndInc(PC);
                    UInt32Value fieldOffset = getWordAndInc(PC);
                    UInt32Value fieldSizeIndex = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, fieldSizeIndex));
                    UInt32Value fieldSize =
                        FRAME_ENTRY(SP, fieldSizeIndex).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* root = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(root));

                    Cell* block = getNestedBlock(root, nestLevel);

                    ASSERT((fieldOffset + fieldSize - 1)
                           < Heap::getPayloadSize(block));

                    if (1 == fieldSize) {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                          (SP, destination, block, fieldOffset);
                        FRAME_ENTRY(SP, destination) =
                          HEAP_GETFIELD(block, fieldOffset);
                    } else {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                          (SP, destination, block, fieldOffset);
                        ASSERT_SAME_TYPE_SLOT_FIELD
                          (SP, destination + 1, block, fieldOffset + 1);
                        FRAME_ENTRY(SP, destination) = HEAP_GETFIELD(block, fieldOffset);
                        FRAME_ENTRY(SP, destination + 1) = HEAP_GETFIELD(block, fieldOffset + 1);
                    }
                    break;
                }
              case GetNestedFieldIndirect_S:
                {
                    UInt32Value nestLevelOffset = getWordAndInc(PC);
                    UInt32Value indirectOffset = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, nestLevelOffset));
                    UInt32Value nestLevel =
                        FRAME_ENTRY(SP, nestLevelOffset).uint32;

                    ASSERT(!FrameStack::isPointerSlot(SP, indirectOffset));
                    UInt32Value fieldIndex =
                        FRAME_ENTRY(SP, indirectOffset).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* root = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(root));

                    Cell* block = getNestedBlock(root, nestLevel);

                    ASSERT(fieldIndex < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination, block, fieldIndex);
                    FRAME_ENTRY(SP, destination) =
                        HEAP_GETFIELD(block, fieldIndex);
                    break;
                }
              case GetNestedFieldIndirect_D:
                {
                    UInt32Value nestLevelOffset = getWordAndInc(PC);
                    UInt32Value indirectOffset = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, nestLevelOffset));
                    UInt32Value nestLevel =
                        FRAME_ENTRY(SP, nestLevelOffset).uint32;

                    ASSERT(!FrameStack::isPointerSlot(SP, indirectOffset));
                    UInt32Value fieldIndex =
                        FRAME_ENTRY(SP, indirectOffset).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* root = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(root));

                    Cell* block = getNestedBlock(root, nestLevel);

                    ASSERT(fieldIndex + 1 < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination, block, fieldIndex);
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination + 1, block, fieldIndex + 1);
                    ASSERT_REAL64_ALIGNED
                        (FRAME_ENTRY_ADDRESS(SP, destination));

                    FRAME_ENTRY(SP, destination) = HEAP_GETFIELD(block, fieldIndex);
                    FRAME_ENTRY(SP, destination + 1) = HEAP_GETFIELD(block, fieldIndex + 1);

                    break;
                }
              case GetNestedFieldIndirect_V:
                {
                    UInt32Value nestLevelOffset = getWordAndInc(PC);
                    UInt32Value indirectOffset = getWordAndInc(PC);
                    UInt32Value fieldSizeIndex = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, nestLevelOffset));
                    UInt32Value nestLevel =
                        FRAME_ENTRY(SP, nestLevelOffset).uint32;

                    ASSERT(!FrameStack::isPointerSlot(SP, indirectOffset));
                    UInt32Value fieldIndex =
                        FRAME_ENTRY(SP, indirectOffset).uint32;

                    ASSERT(!FrameStack::isPointerSlot(SP, fieldSizeIndex));
                    UInt32Value fieldSize =
                        FRAME_ENTRY(SP, fieldSizeIndex).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* root = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(root));

                    Cell* block = getNestedBlock(root, nestLevel);

                    ASSERT((fieldIndex + fieldSize - 1)
                           < Heap::getPayloadSize(block));
                    
                    if (1 == fieldSize) {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                          (SP, destination, block, fieldIndex);
                        FRAME_ENTRY(SP, destination) =
                          HEAP_GETFIELD(block, fieldIndex);
                    } else {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                          (SP, destination, block, fieldIndex);
                        ASSERT_SAME_TYPE_SLOT_FIELD
                          (SP, destination + 1, block, fieldIndex + 1);
                        FRAME_ENTRY(SP, destination) = HEAP_GETFIELD(block, fieldIndex);
                        FRAME_ENTRY(SP, destination + 1) = HEAP_GETFIELD(block, fieldIndex + 1);
                    }
                    break;
                }
              case SetField_S:
                {
                    UInt32Value fieldIndex = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* block = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT(fieldIndex < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);
                    Cell variableValue = FRAME_ENTRY(SP, variableIndex);
                    Heap::updateField(block, fieldIndex, variableValue);
                    break;
                }
              case SetField_D:
                {
                    UInt32Value fieldIndex = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* block = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT(fieldIndex + 1 < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex + 1, block, fieldIndex + 1);
                    ASSERT_REAL64_ALIGNED
                        (FRAME_ENTRY_ADDRESS(SP, variableIndex));

                    Real64Value fieldValue =
                      *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, variableIndex);
                    Heap::updateField_D(block, fieldIndex, fieldValue);
                    break;
                }
              case SetField_V:
                {
                    UInt32Value fieldIndex = getWordAndInc(PC);
                    UInt32Value fieldSizeIndex = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, fieldSizeIndex));
                    UInt32Value fieldSize =
                        FRAME_ENTRY(SP, fieldSizeIndex).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* block = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT((fieldIndex + fieldSize - 1)
                           < Heap::getPayloadSize(block));
                    if ( 1 == fieldSize) {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);

                        Cell variableValue = FRAME_ENTRY(SP, variableIndex);
                        Heap::updateField(block, fieldIndex, variableValue);
                    } else {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);
                        ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex + 1, block, fieldIndex + 1);

                        Real64Value variableValue = *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, variableIndex);
                        Heap::updateField_D(block, fieldIndex, variableValue);
                    }
                    break;
                }
              case SetFieldIndirect_S:
                {
                    UInt32Value indirectOffset = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, indirectOffset));
                    UInt32Value fieldIndex =
                        FRAME_ENTRY(SP, indirectOffset).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* block = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT(fieldIndex < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);
                    Cell variableValue = FRAME_ENTRY(SP, variableIndex);
                    Heap::updateField(block, fieldIndex, variableValue);
                    break;
                }
              case SetFieldIndirect_D:
                {
                    UInt32Value indirectOffset = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, indirectOffset));
                    UInt32Value fieldIndex =
                        FRAME_ENTRY(SP, indirectOffset).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* block = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT(fieldIndex + 1 < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex + 1, block, fieldIndex + 1);
                    ASSERT_REAL64_ALIGNED
                        (FRAME_ENTRY_ADDRESS(SP, variableIndex));

                    Real64Value fieldValue =
                        *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, variableIndex);
                    Heap::updateField_D(block, fieldIndex, fieldValue);

                    break;
                }
              case SetFieldIndirect_V:
                {
                    UInt32Value indirectOffset = getWordAndInc(PC);
                    UInt32Value fieldSizeIndex = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, fieldSizeIndex));
                    UInt32Value fieldSize =
                        FRAME_ENTRY(SP, fieldSizeIndex).uint32;

                    ASSERT(!FrameStack::isPointerSlot(SP, indirectOffset));
                    UInt32Value fieldIndex =
                        FRAME_ENTRY(SP, indirectOffset).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* block = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT((fieldIndex + fieldSize - 1)
                           < Heap::getPayloadSize(block));

                    if ( 1 == fieldSize) {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);

                        Cell variableValue = FRAME_ENTRY(SP, variableIndex);
                        Heap::updateField(block, fieldIndex, variableValue);
                    } else {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);
                        ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex + 1, block, fieldIndex + 1);

                        Real64Value variableValue = *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, variableIndex);
                        Heap::updateField_D(block, fieldIndex, variableValue);
                    }
                    break;
                }
              case SetNestedField_S:
                {
                    UInt32Value nestLevel = getWordAndInc(PC);
                    UInt32Value fieldIndex = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* root = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(root));

                    Cell* block = getNestedBlock(root, nestLevel);
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT(fieldIndex < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);
                    Cell variableValue = FRAME_ENTRY(SP, variableIndex);
                    Heap::updateField(block, fieldIndex, variableValue);
                    break;
                }
              case SetNestedField_D:
                {
                    UInt32Value nestLevel = getWordAndInc(PC);
                    UInt32Value fieldIndex = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* root = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(root));

                    Cell* block = getNestedBlock(root, nestLevel);
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT(fieldIndex + 1 < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex + 1, block, fieldIndex + 1);
                    ASSERT_REAL64_ALIGNED
                        (FRAME_ENTRY_ADDRESS(SP, variableIndex));

                    Real64Value fieldValue =
                        *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, variableIndex);
                    Heap::updateField_D(block, fieldIndex, fieldValue);

                    break;
                }
              case SetNestedField_V:
                {
                    UInt32Value nestLevel = getWordAndInc(PC);
                    UInt32Value fieldIndex = getWordAndInc(PC);
                    UInt32Value fieldSizeIndex = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, fieldSizeIndex));
                    UInt32Value fieldSize =
                        FRAME_ENTRY(SP, fieldSizeIndex).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* root = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(root));

                    Cell* block = getNestedBlock(root, nestLevel);
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT((fieldIndex + fieldSize - 1)
                           < Heap::getPayloadSize(block));
                    if ( 1 == fieldSize) {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);

                        Cell variableValue = FRAME_ENTRY(SP, variableIndex);
                        Heap::updateField(block, fieldIndex, variableValue);
                    } else {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);
                        ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex + 1, block, fieldIndex + 1);

                        Real64Value variableValue = *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, variableIndex);
                        Heap::updateField_D(block, fieldIndex, variableValue);
                    }
                    break;
                }
              case SetNestedFieldIndirect_S:
                {
                    UInt32Value nestLevelOffset = getWordAndInc(PC);
                    UInt32Value indirectOffset = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, nestLevelOffset));
                    UInt32Value nestLevel =
                        FRAME_ENTRY(SP, nestLevelOffset).uint32;

                    ASSERT(!FrameStack::isPointerSlot(SP, indirectOffset));
                    UInt32Value fieldIndex =
                        FRAME_ENTRY(SP, indirectOffset).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* root = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(root));

                    Cell* block = getNestedBlock(root, nestLevel);
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT(fieldIndex < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);
                    Cell variableValue = FRAME_ENTRY(SP, variableIndex);
                    Heap::updateField(block, fieldIndex, variableValue);
                    break;
                }
              case SetNestedFieldIndirect_D:
                {
                    UInt32Value nestLevelOffset = getWordAndInc(PC);
                    UInt32Value indirectOffset = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, nestLevelOffset));
                    UInt32Value nestLevel =
                        FRAME_ENTRY(SP, nestLevelOffset).uint32;

                    ASSERT(!FrameStack::isPointerSlot(SP, indirectOffset));
                    UInt32Value fieldIndex =
                        FRAME_ENTRY(SP, indirectOffset).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* root = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(root));

                    Cell* block = getNestedBlock(root, nestLevel);
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT(fieldIndex + 1 < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex + 1, block, fieldIndex + 1);
                    ASSERT_REAL64_ALIGNED
                        (FRAME_ENTRY_ADDRESS(SP, variableIndex));

                    Real64Value fieldValue =
                        *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, variableIndex);
                    Heap::updateField_D(block, fieldIndex, fieldValue);

                    break;
                }
              case SetNestedFieldIndirect_V:
                {
                    UInt32Value nestLevelOffset = getWordAndInc(PC);
                    UInt32Value indirectOffset = getWordAndInc(PC);
                    UInt32Value fieldSizeIndex = getWordAndInc(PC);
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, nestLevelOffset));
                    UInt32Value nestLevel =
                        FRAME_ENTRY(SP, nestLevelOffset).uint32;

                    ASSERT(!FrameStack::isPointerSlot(SP, indirectOffset));
                    UInt32Value fieldIndex =
                        FRAME_ENTRY(SP, indirectOffset).uint32;

                    ASSERT(!FrameStack::isPointerSlot(SP, fieldSizeIndex));
                    UInt32Value fieldSize =
                        FRAME_ENTRY(SP, fieldSizeIndex).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* root = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(root));

                    Cell* block = getNestedBlock(root, nestLevel);
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT((fieldIndex + fieldSize - 1)
                           < Heap::getPayloadSize(block));
                    if ( 1 == fieldSize) {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);

                        Cell variableValue = FRAME_ENTRY(SP, variableIndex);
                        Heap::updateField(block, fieldIndex, variableValue);
                    } else {
                        ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, fieldIndex);
                        ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex + 1, block, fieldIndex + 1);

                        Real64Value variableValue = *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, variableIndex);
                        Heap::updateField_D(block, fieldIndex, variableValue);
                    }
                    break;
                }
              case CopyBlock:
                {
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value nestLevelOffset = getWordAndInc(PC);
                    UInt32Value destinationIndex = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, nestLevelOffset));
                    UInt32Value nestLevel =
                        FRAME_ENTRY(SP, nestLevelOffset).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell *block = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(block));

                    ASSERT(FrameStack::isPointerSlot(SP, destinationIndex));
                    FRAME_ENTRY(SP, destinationIndex).blockRef = block;

                    for (int level = 0; level <= nestLevel; level += 1) {
                        Cell *origBlock, *destBlock;
                        origBlock = getNestedBlock(block, level);

                        Bitmap bitmap = Heap::getBitmap(origBlock);
                        int fieldsCount = Heap::getPayloadSize(origBlock);
                        ALLOCATE_RECORDBLOCK(destBlock, bitmap, fieldsCount);
                        ASSERT(Heap::isValidBlockPointer(destBlock));

                        /* get the block pointer again, because GC may occur
                         * in the above allocation.
                         */
                        block = FRAME_ENTRY(SP, destinationIndex).blockRef;
                        ASSERT(Heap::isValidBlockPointer(block));

                        if (level == 0) {
                            COPY_MEMORY
                                (destBlock, block, fieldsCount * sizeof(Cell));
                            FRAME_ENTRY(SP, destinationIndex).blockRef =
                                destBlock;
                            continue;
                        }

                        Cell *parent = getNestedBlock(block, level - 1);
                        ASSERT(Heap::isValidBlockPointer(parent));
                        origBlock = getNestedBlock(parent, 1);
                        ASSERT(Heap::isValidBlockPointer(origBlock));
                        COPY_MEMORY
                            (destBlock, origBlock, fieldsCount * sizeof(Cell));

                        Cell nest;
                        nest.blockRef = destBlock;
                        Heap::updateField(parent, INDEX_OF_NEST_POINTER, nest);
                    }
                    break;
                }

              case CopyArray_S:
              case CopyArray_D:
              case CopyArray_V:
                {
                    UInt32Value srcIndex = getWordAndInc(PC);
                    UInt32Value srcOffsetIndex = getWordAndInc(PC);
                    UInt32Value dstIndex = getWordAndInc(PC);
                    UInt32Value dstOffsetIndex = getWordAndInc(PC);
                    UInt32Value lengthIndex = getWordAndInc(PC);
                    UInt32Value elementSizeIndex;
                    if(CopyArray_V == opcode){
                        elementSizeIndex = getWordAndInc(PC);
                    }

                    ASSERT(FrameStack::isPointerSlot(SP, srcIndex));
                    Cell *src = FRAME_ENTRY(SP, srcIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(src));

                    ASSERT(!FrameStack::isPointerSlot(SP, srcOffsetIndex));
                    UInt32Value srcOffset =
                        FRAME_ENTRY(SP, srcOffsetIndex).uint32;

                    ASSERT(FrameStack::isPointerSlot(SP, dstIndex));
                    Cell *dst = FRAME_ENTRY(SP, dstIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(dst));

                    ASSERT(!FrameStack::isPointerSlot(SP, dstOffsetIndex));
                    UInt32Value dstOffset =
                        FRAME_ENTRY(SP, dstOffsetIndex).uint32;

                    ASSERT(!FrameStack::isPointerSlot(SP, lengthIndex));
                    UInt32Value length = FRAME_ENTRY(SP, lengthIndex).uint32;

                    UInt32Value copyCells;
                    switch(opcode){
                      case CopyArray_S: copyCells = length; break;
                      case CopyArray_D: copyCells = length * 2; break;
                      case CopyArray_V:
                        ASSERT(!FrameStack::isPointerSlot(SP, elementSizeIndex));
                        copyCells =
                            length * FRAME_ENTRY(SP, elementSizeIndex).uint32;
                        break;
                    }
/*
                    DBGWRAP(LOG.debug("CopyArray"
                                      "srcOffset=%d, dstOffset=%d, "
                                      "length=%d",
                                      srcOffset, dstOffset, length));
*/
                    ASSERT(srcOffset + copyCells <= Heap::getPayloadSize(src));
                    ASSERT(dstOffset + copyCells <= Heap::getPayloadSize(dst));

                    /* NOTE: srcOffset and dstOffset are already adjusted
                     * according to elementSize by compiler. */
                    COPY_MEMORY(dst + dstOffset,
                                src + srcOffset,
                                copyCells * sizeof(Cell));

                    break;
                }
              case GetGlobal_S:
              case GetGlobal_D:
                {
                    UInt32Value arrayIndex = getWordAndInc(PC);
                    UInt32Value offset = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

/*
                    ASSERT(arrayIndex < globalArrays_.size());
*/
                    Cell* block = globalArrays_[arrayIndex];
                        
                    ASSERT(Heap::isValidBlockPointer(block));
/*
                    DBGWRAP(LOG.debug("GetGlobal: "
                                   "arrayIndex=%d, offset=%d, block=%x",
                                   arrayIndex, offset, block);)
*/
                    ASSERT(offset < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, destination, block, offset);
                    FRAME_ENTRY(SP, destination) =
                        HEAP_GETFIELD(block, offset);
                    if(GetGlobal_D == opcode){
                        FRAME_ENTRY(SP, destination + 1) =
                            HEAP_GETFIELD(block, offset + 1);
                    }
                    break;
                }
              case SetGlobal_S:
              case SetGlobal_D:
                {
                    UInt32Value arrayIndex = getWordAndInc(PC);
                    UInt32Value offset = getWordAndInc(PC);
                    UInt32Value variableIndex = getWordAndInc(PC);

/*
                    ASSERT(arrayIndex < globalArrays_.size());
*/
                    Cell* block = globalArrays_[arrayIndex];
                    ASSERT(Heap::isValidBlockPointer(block));
/*
                    DBGWRAP(LOG.debug("SetGlobal: "
                                   "arrayIndex=%d, offset=%d, block=%x",
                                   arrayIndex, offset, block);)
*/
                    ASSERT(offset < Heap::getPayloadSize(block));
                    ASSERT_SAME_TYPE_SLOT_FIELD
                        (SP, variableIndex, block, offset);
                    Cell value = FRAME_ENTRY(SP, variableIndex);
                    Heap::updateField(block, offset, value);
                    if(SetGlobal_D == opcode){
                        ASSERT(offset + 1 < Heap::getPayloadSize(block));
                        value = FRAME_ENTRY(SP, variableIndex + 1);
                        Heap::updateField(block, offset + 1, value);
                    }
                    break;
                }
              case InitGlobalArrayUnboxed:
              case InitGlobalArrayBoxed:
              case InitGlobalArrayDouble:
                {
                    UInt32Value arrayIndex = getWordAndInc(PC);
                    UInt32Value arraySize = getWordAndInc(PC);

                    Cell* block;
                    Cell initialValue;
                    switch(opcode){
                      case InitGlobalArrayUnboxed:
                        {
                            ALLOCATE_SINGLEATOMARRAY(block, arraySize, true);
                            initialValue.uint32 = 0;
                            break;
                        }
                      case InitGlobalArrayBoxed:
                        {
                            ALLOCATE_POINTERARRAY(block, arraySize, true);
                            initialValue.blockRef = block; // dummy 
                            break;
                        }
                      case InitGlobalArrayDouble:
                        {
                            ALLOCATE_DOUBLEATOMARRAY(block, arraySize, true);
                            initialValue.uint32 = 0;
                            break;
                        }
                    }

                    for(int index = 0; index < arraySize; index += 1){
                        Heap::initializeField
                            (block, index, initialValue);
                    }
/*                    
                    DBGWRAP(LOG.debug("InitGlobalArray: "
                                   "arrayIndex=%d, arraySize=%d, block=%x",
                                   arrayIndex, arraySize, block);)
*/
                    if(globalArrays_.size() <= arrayIndex){
                        globalArrays_.resize(arrayIndex + 1);
                    }
                    globalArrays_[arrayIndex] = block;
                    break;
                }
              case GetEnv:
                {
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(FrameStack::isPointerSlot(SP, destination));
                    FRAME_ENTRY(SP, destination).blockRef = ENV;
                    break;
                }
              case CallPrim:
                {
                    Cell* argRefsBuffer[PRIMITIVE_MAX_ARGUMENTS];

                    UInt32Value primitiveIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value *argIndexes = PC;
                    PC += argsCount;
                    UInt32Value destination = getWordAndInc(PC);

#ifdef IML_DEBUG
                    if(NUMBER_OF_PRIMITIVES <= primitiveIndex){
                        DBGWRAP
                        (LOG.error("callPrim::IllegalArgumentException"));
                        throw IllegalArgumentException();// IllegalArgument???
                    }
#endif
                    PrimitiveEntry *primitive = &primitives[primitiveIndex];

                    // copy argument values into the buffer array.
                    for(int index = 0; index < argsCount; index += 1){
                        argRefsBuffer[index] = &FRAME_ENTRY(SP, *argIndexes);
                        argIndexes += 1;
                    }
                    Cell *resultBuf = &FRAME_ENTRY(SP, destination);

                    // Because GC may be caused by allocation in primitive,
                    // save registers.
                    SAVE_REGISTERS;
                    primitive->prim(argsCount, argRefsBuffer, resultBuf);
                    RESTORE_REGISTERS;

                    if(isPrimitiveExceptionRaised_){
                        raiseException(SP, PC, ENV, primitiveException_);
                        resetPrimitiveException();
                    }
                    break;
                }
              case Apply_0_0:
              case Apply_0_1:
              case Apply_0_M:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    /* jump to the function */
                    callFunction_0(PC,
                                   SP,
                                   ENV,
                                   entryPoint,
                                   restoredENV,
                                   returnAddress);
                    break;
                }
              case Apply_S_0:
              case Apply_S_1:
              case Apply_S_M:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argIndex = getWordAndInc(PC);
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    /* jump to the function */
                    callFunction_S(PC,
                                   SP,
                                   ENV,
                                   entryPoint,
                                   restoredENV,
                                   argIndex,
                                   returnAddress);
                    break;
                }
              case Apply_D_0:
              case Apply_D_1:
              case Apply_D_M:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argIndex = getWordAndInc(PC);
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    /* jump to the function */
                    callFunction_D(PC,
                                   SP,
                                   ENV,
                                   entryPoint,
                                   restoredENV,
                                   argIndex,
                                   returnAddress);
                    break;
                }
              case Apply_V_0:
              case Apply_V_1:
              case Apply_V_M:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argIndex = getWordAndInc(PC);
                    UInt32Value argSizeIndex = getWordAndInc(PC);
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    UInt32Value argSize = FRAME_ENTRY(SP, argSizeIndex).uint32;

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    /* jump to the function */
                    if ( 1 == argSize ) {
                        callFunction_S(PC,
                                       SP,
                                       ENV,
                                       entryPoint,
                                       restoredENV,
                                       argIndex,
                                       returnAddress);
                    } else {
                        callFunction_D(PC,
                                       SP,
                                       ENV,
                                       entryPoint,
                                       restoredENV,
                                       argIndex,
                                       returnAddress);
                    }
                    break;
                }
              case Apply_MS_0:
              case Apply_MS_1:
              case Apply_MS_M:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    /* jump to the function */
                    callFunction_MS(PC,
                                    SP,
                                    ENV,
                                    entryPoint,
                                    restoredENV,
                                    argIndexes,
                                    returnAddress);
                    break;
                }
              case Apply_MLD_0:
              case Apply_MLD_1:
              case Apply_MLD_M:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    /* jump to the function */
                    callFunction_MLD(PC,
                                     SP,
                                     ENV,
                                     entryPoint,
                                     restoredENV,
                                     argIndexes,
                                     returnAddress);
                    break;
                }
              case Apply_MLV_0:
              case Apply_MLV_1:
              case Apply_MLV_M:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value lastArgSizeIndex = getWordAndInc(PC);
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    UInt32Value lastArgSize = FRAME_ENTRY(SP, lastArgSizeIndex).uint32;

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    /* jump to the function */
                    if (1 == lastArgSize) {
                        callFunction_MS(PC,
                                        SP,
                                        ENV,
                                        entryPoint,
                                        restoredENV,
                                        argIndexes,
                                        returnAddress);

                    } else {
                        callFunction_MLD(PC,
                                         SP,
                                         ENV,
                                         entryPoint,
                                         restoredENV,
                                         argIndexes,
                                         returnAddress);
                    }
                    break;
                }
              case Apply_MF_0:
              case Apply_MF_1:
              case Apply_MF_M:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value* argSizes = PC;
                    PC += argsCount;
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    /* jump to the function */
                    callFunction_MF(PC,
                                    SP,
                                    ENV,
                                    entryPoint,
                                    restoredENV,
                                    argIndexes,
                                    argSizes,
                                    returnAddress);
                    break;
                }
              case Apply_MV_0:
              case Apply_MV_1:
              case Apply_MV_M:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value* argSizeIndexes = PC;
                    PC += argsCount;
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    /* jump to the function */
                    callFunction_MV(PC,
                                    SP,
                                    ENV,
                                    entryPoint,
                                    restoredENV,
                                    argIndexes,
                                    argSizeIndexes,
                                    returnAddress);
                    break;
                }
              case TailApply_0:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    tailCallFunction_0(PC,
                                       SP,
                                       ENV,
                                       entryPoint,
                                       restoredENV);
                    break;
                }
              case TailApply_S:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argIndex = getWordAndInc(PC);

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    tailCallFunction_S(PC,
                                       SP,
                                       ENV,
                                       entryPoint,
                                       restoredENV,
                                       argIndex);
                    break;
                }
              case TailApply_D:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argIndex = getWordAndInc(PC);

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    tailCallFunction_D(PC,
                                       SP,
                                       ENV,
                                       entryPoint,
                                       restoredENV,
                                       argIndex);
                    break;
                }
              case TailApply_V:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argIndex = getWordAndInc(PC);
                    UInt32Value argSizeIndex = getWordAndInc(PC);

                    UInt32Value argSize = FRAME_ENTRY(SP, argSizeIndex).uint32;

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    if ( 1 == argSize ) {
                        tailCallFunction_S(PC,
                                           SP,
                                           ENV,
                                           entryPoint,
                                           restoredENV,
                                           argIndex);
                    } else {
                        tailCallFunction_D(PC,
                                           SP,
                                           ENV,
                                           entryPoint,
                                           restoredENV,
                                           argIndex);
                    }
                    break;
                }
              case TailApply_MS:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    tailCallFunction_MS(PC,
                                        SP,
                                        ENV,
                                        entryPoint,
                                        restoredENV,
                                        argIndexes);
                    break;
                }
              case TailApply_MLD:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    tailCallFunction_MLD(PC,
                                         SP,
                                         ENV,
                                         entryPoint,
                                         restoredENV,
                                         argIndexes);
                    break;
                }
              case TailApply_MLV:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value lastArgSizeIndex = getWordAndInc(PC);

                    UInt32Value lastArgSize = FRAME_ENTRY(SP, lastArgSizeIndex).uint32;

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    if (1 == lastArgSize) {
                        tailCallFunction_MS(PC,
                                            SP,
                                            ENV,
                                            entryPoint,
                                            restoredENV,
                                            argIndexes);

                    } else {
                        tailCallFunction_MLD(PC,
                                             SP,
                                             ENV,
                                             entryPoint,
                                             restoredENV,
                                             argIndexes);
                    }
                    break;
                }
              case TailApply_MF:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value* argSizes = PC;
                    PC += argsCount;

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    tailCallFunction_MF(PC,
                                        SP,
                                        ENV,
                                        entryPoint,
                                        restoredENV,
                                        argIndexes,
                                        argSizes);
                    break;
                }
              case TailApply_MV:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value* argSizeIndexes = PC;
                    PC += argsCount;

                    /* expand closure */
                    UInt32Value* entryPoint;
                    Cell* restoredENV;
                    expandClosure(SP, closureIndex, entryPoint, restoredENV);

                    tailCallFunction_MV(PC,
                                        SP,
                                        ENV,
                                        entryPoint,
                                        restoredENV,
                                        argIndexes,
                                        argSizeIndexes);
                    break;
                }
              case CallStatic_0_0:
              case CallStatic_0_1:
              case CallStatic_0_M:
                {
                    UInt32Value* entryPoint = (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    callFunction_0(PC,
                                   SP,
                                   ENV,
                                   entryPoint,
                                   calleeENV,
                                   returnAddress);
                    break;
                }

              case CallStatic_S_0:
              case CallStatic_S_1:
              case CallStatic_S_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argIndex = getWordAndInc(PC);
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    callFunction_S(PC,
                                   SP,
                                   ENV,
                                   entryPoint,
                                   calleeENV,
                                   argIndex,
                                   returnAddress);
                    break;
                }
              case CallStatic_D_0:
              case CallStatic_D_1:
              case CallStatic_D_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argIndex = getWordAndInc(PC);
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    callFunction_D(PC,
                                   SP,
                                   ENV,
                                   entryPoint,
                                   calleeENV,
                                   argIndex,
                                   returnAddress);
                    break;
                }
              case CallStatic_V_0:
              case CallStatic_V_1:
              case CallStatic_V_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argIndex = getWordAndInc(PC);
                    UInt32Value argSizeIndex = getWordAndInc(PC);
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    UInt32Value argSize =
                    FRAME_ENTRY(SP, argSizeIndex).uint32;

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    if (1 == argSize) {
                        callFunction_S(PC,
                                       SP,
                                       ENV,
                                       entryPoint,
                                       calleeENV,
                                       argIndex,
                                       returnAddress);
                    } else {
                        callFunction_D(PC,
                                       SP,
                                       ENV,
                                       entryPoint,
                                       calleeENV,
                                       argIndex,
                                       returnAddress);
                    }
                    break;
                }
              case CallStatic_MS_0:
              case CallStatic_MS_1:
              case CallStatic_MS_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    callFunction_MS(PC,
                                    SP,
                                    ENV,
                                    entryPoint,
                                    calleeENV,
                                    argIndexes,
                                    returnAddress);
                    break;
                }
              case CallStatic_MLD_0:
              case CallStatic_MLD_1:
              case CallStatic_MLD_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    callFunction_MLD(PC,
                                     SP,
                                     ENV,
                                     entryPoint,
                                     calleeENV,
                                     argIndexes,
                                     returnAddress);
                    break;
                }
              case CallStatic_MLV_0:
              case CallStatic_MLV_1:
              case CallStatic_MLV_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value lastArgSizeIndex = getWordAndInc(PC);
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    UInt32Value lastArgSize = FRAME_ENTRY(SP, lastArgSizeIndex).uint32;
                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);
                    if ( 1 == lastArgSize) {
                        callFunction_MS(PC,
                                        SP,
                                        ENV,
                                        entryPoint,
                                        calleeENV,
                                        argIndexes,
                                        returnAddress);
                    } else {
                        callFunction_MLD(PC,
                                         SP,
                                         ENV,
                                         entryPoint,
                                         calleeENV,
                                         argIndexes,
                                         returnAddress);
                    }
                    break;
                }
              case CallStatic_MF_0:
              case CallStatic_MF_1:
              case CallStatic_MF_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value* argSizes = PC;
                    PC += argsCount;
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    callFunction_MF(PC,
                                    SP,
                                    ENV,
                                    entryPoint,
                                    calleeENV,
                                    argIndexes,
                                    argSizes,
                                    returnAddress);
                    break;
                }
              case CallStatic_MV_0:
              case CallStatic_MV_1:
              case CallStatic_MV_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value* argSizeIndexes = PC;
                    PC += argsCount;
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    callFunction_MV(PC,
                                    SP,
                                    ENV,
                                    entryPoint,
                                    calleeENV,
                                    argIndexes,
                                    argSizeIndexes,
                                    returnAddress);
                    break;
                }
              case TailCallStatic_0:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    tailCallFunction_0(PC,
                                       SP,
                                       ENV,
                                       entryPoint,
                                       calleeENV);
                    break;
                }
              case TailCallStatic_S:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argIndex = getWordAndInc(PC);

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    tailCallFunction_S(PC,
                                       SP,
                                       ENV,
                                       entryPoint,
                                       calleeENV,
                                       argIndex);
                    break;
                }
              case TailCallStatic_D:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argIndex = getWordAndInc(PC);

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    tailCallFunction_D(PC,
                                       SP,
                                       ENV,
                                       entryPoint,
                                       calleeENV,
                                       argIndex);
                    break;
                }
              case TailCallStatic_V:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argIndex = getWordAndInc(PC);
                    UInt32Value argSizeIndex = getWordAndInc(PC);

                    UInt32Value argSize =
                    FRAME_ENTRY(SP, argSizeIndex).uint32;

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    if ( 1 == argSize ) {
                        tailCallFunction_S(PC,
                                           SP,
                                           ENV,
                                           entryPoint,
                                           calleeENV,
                                           argIndex);
                    } else {
                        tailCallFunction_D(PC,
                                           SP,
                                           ENV,
                                           entryPoint,
                                           calleeENV,
                                           argIndex);
                    }
                    break;
                }
              case TailCallStatic_MS:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    tailCallFunction_MS(PC,
                                        SP,
                                        ENV,
                                        entryPoint,
                                        calleeENV,
                                        argIndexes);
                    break;
                }
              case TailCallStatic_MLD:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    tailCallFunction_MLD(PC,
                                         SP,
                                         ENV,
                                         entryPoint,
                                         calleeENV,
                                         argIndexes);
                    break;
                }
              case TailCallStatic_MLV:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value lastArgSizeIndex = getWordAndInc(PC);

                    UInt32Value lastArgSize = FRAME_ENTRY(SP, lastArgSizeIndex).uint32;
                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    if (1 == lastArgSize) {
                        tailCallFunction_MS(PC,
                                            SP,
                                            ENV,
                                            entryPoint,
                                            calleeENV,
                                            argIndexes);
                    } else {
                       tailCallFunction_MLD(PC,
                                            SP,
                                            ENV,
                                            entryPoint,
                                            calleeENV,
                                            argIndexes);
                    }
                    break;
                }
              case TailCallStatic_MF:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value* argSizes = PC;
                    PC += argsCount;

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    tailCallFunction_MF(PC,
                                        SP,
                                        ENV,
                                        entryPoint,
                                        calleeENV,
                                        argIndexes,
                                        argSizes);
                    break;
                }
              case TailCallStatic_MV:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value* argSizeIndexes = PC;
                    PC += argsCount;

                    // get the ENV block for callee.
                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell* calleeENV = FRAME_ENTRY(SP, ENVIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(calleeENV));

                    tailCallFunction_MV(PC,
                                        SP,
                                        ENV,
                                        entryPoint,
                                        calleeENV,
                                        argIndexes,
                                        argSizeIndexes);
                    break;
                }
              case RecursiveCallStatic_0_0:
              case RecursiveCallStatic_0_1:
              case RecursiveCallStatic_0_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    callRecursiveFunction_0(PC,
                                            SP,
                                            entryPoint,
                                            returnAddress);
                    break;
                }
              case RecursiveCallStatic_S_0:
              case RecursiveCallStatic_S_1:
              case RecursiveCallStatic_S_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argIndex = getWordAndInc(PC);
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    callRecursiveFunction_S(PC,
                                            SP,
                                            entryPoint,
                                            argIndex,
                                            returnAddress);
                    break;
                }
              case RecursiveCallStatic_D_0:
              case RecursiveCallStatic_D_1:
              case RecursiveCallStatic_D_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argIndex = getWordAndInc(PC);
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    callRecursiveFunction_D(PC,
                                            SP,
                                            entryPoint,
                                            argIndex,
                                            returnAddress);
                    break;
                }
              case RecursiveCallStatic_V_0:
              case RecursiveCallStatic_V_1:
              case RecursiveCallStatic_V_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argIndex = getWordAndInc(PC);
                    UInt32Value argSizeIndex = getWordAndInc(PC);
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    UInt32Value argSize = FRAME_ENTRY(SP, argSizeIndex).uint32;

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    if ( 1 == argSize ) {
                        callRecursiveFunction_S(PC,
                                                SP,
                                                entryPoint,
                                                argIndex,
                                                returnAddress);
                    } else {
                        callRecursiveFunction_D(PC,
                                                SP,
                                                entryPoint,
                                                argIndex,
                                                returnAddress);
                    }
                    break;
                }
              case RecursiveCallStatic_MS_0:
              case RecursiveCallStatic_MS_1:
              case RecursiveCallStatic_MS_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    callRecursiveFunction_MS(PC,
                                             SP,
                                             entryPoint,
                                             argsCount,
                                             argIndexes,
                                             returnAddress);
                    break;
                }
              case RecursiveCallStatic_MLD_0:
              case RecursiveCallStatic_MLD_1:
              case RecursiveCallStatic_MLD_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    callRecursiveFunction_MLD(PC,
                                              SP,
                                              entryPoint,
                                              argsCount,
                                              argIndexes,
                                              returnAddress);
                    break;
                }
              case RecursiveCallStatic_MLV_0:
              case RecursiveCallStatic_MLV_1:
              case RecursiveCallStatic_MLV_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value lastArgSizeIndex = getWordAndInc(PC);
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;
                    UInt32Value lastArgSize = FRAME_ENTRY(SP, lastArgSizeIndex).uint32;
                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);
                    if (1 == lastArgSize) {
                        callRecursiveFunction_MS(PC,
                                                 SP,
                                                 entryPoint,
                                                 argsCount,
                                                 argIndexes,
                                                 returnAddress);
                    } else {
                        callRecursiveFunction_MLD(PC,
                                                  SP,
                                                  entryPoint,
                                                  argsCount,
                                                  argIndexes,
                                                  returnAddress);
                    }
                    break;
                }
              case RecursiveCallStatic_MF_0:
              case RecursiveCallStatic_MF_1:
              case RecursiveCallStatic_MF_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value* argSizes = PC;
                    PC += argsCount;
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    callRecursiveFunction_MF(PC,
                                             SP,
                                             entryPoint,
                                             argsCount,
                                             argIndexes,
                                             argSizes,
                                             returnAddress);
                    break;
                }
              case RecursiveCallStatic_MV_0:
              case RecursiveCallStatic_MV_1:
              case RecursiveCallStatic_MV_M:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value* argSizeIndexes = PC;
                    PC += argsCount;
                    // now, PC points to destination operand.
                    UInt32Value* returnAddress = PC;

                    /* save ENV registers to the current frame. */
                    FrameStack::storeENV(SP, ENV);

                    callRecursiveFunction_MV(PC,
                                             SP,
                                             entryPoint,
                                             argsCount,
                                             argIndexes,
                                             argSizeIndexes,
                                             returnAddress);
                    break;
                }
              case RecursiveTailCallStatic_0:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));

                    tailCallRecursiveFunction_0(PC,
                                                entryPoint);
                    break;
                }
              case RecursiveTailCallStatic_S:
                {

                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argIndex = getWordAndInc(PC);
                    tailCallRecursiveFunction_S(PC,
                                                SP,
                                                entryPoint,
                                                argIndex);
                    break;
                }
              case RecursiveTailCallStatic_D:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argIndex = getWordAndInc(PC);

                    tailCallRecursiveFunction_D(PC,
                                                SP,
                                                entryPoint,
                                                argIndex);
                    break;
                }
              case RecursiveTailCallStatic_V:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argIndex = getWordAndInc(PC);
                    UInt32Value argSizeIndex = getWordAndInc(PC);

                    UInt32Value argSize = FRAME_ENTRY(SP, argSizeIndex).uint32;

                    if ( 1 == argSize ) {
                        tailCallRecursiveFunction_S(PC,
                                                    SP,
                                                    entryPoint,
                                                    argIndex);
                    } else {
                        tailCallRecursiveFunction_D(PC,
                                                    SP,
                                                    entryPoint,
                                                    argIndex);
                    }
                    break;
                }
              case RecursiveTailCallStatic_MS:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;

                    tailCallRecursiveFunction_MS(PC,
                                                 SP,
                                                 entryPoint,
                                                 argsCount,
                                                 argIndexes);
                    break;
                }
              case RecursiveTailCallStatic_MLD:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;

                    tailCallRecursiveFunction_MLD(PC,
                                                  SP,
                                                  entryPoint,
                                                  argsCount,
                                                  argIndexes);
                    break;
                }
              case RecursiveTailCallStatic_MLV:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value lastArgSizeIndex = getWordAndInc(PC);

                    UInt32Value lastArgSize = FRAME_ENTRY(SP, lastArgSizeIndex).uint32;

                    if ( 1 == lastArgSize) {
                        tailCallRecursiveFunction_MS(PC,
                                                     SP,
                                                     entryPoint,
                                                     argsCount,
                                                     argIndexes);
                    } else {
                        tailCallRecursiveFunction_MLD(PC,
                                                      SP,
                                                      entryPoint,
                                                      argsCount,
                                                      argIndexes);
                    }
                    break;
                }
              case RecursiveTailCallStatic_MF:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value* argSizes = PC;
                    PC += argsCount;

                    tailCallRecursiveFunction_MF(PC,
                                                 SP,
                                                 entryPoint,
                                                 argsCount,
                                                 argIndexes,
                                                 argSizes);
                    break;
                }
              case RecursiveTailCallStatic_MV:
                {
                    UInt32Value* entryPoint =
                    (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value* argSizeIndexes = PC;
                    PC += argsCount;

                    tailCallRecursiveFunction_MV(PC,
                                                 SP,
                                                 entryPoint,
                                                 argsCount,
                                                 argIndexes,
                                                 argSizeIndexes);
                    break;
                }
              case MakeBlock:
                {
                    UInt32Value bitmapIndex = getWordAndInc(PC);
                    UInt32Value sizeIndex = getWordAndInc(PC);
                    UInt32Value fieldsCount = getWordAndInc(PC);
                    UInt32Value *fieldValueIndexes = PC;
                    PC += fieldsCount;
                    UInt32Value *fieldSizeIndexes = PC;
                    PC += fieldsCount;
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, bitmapIndex));
                    Bitmap bitmap =
                    (Bitmap)(FRAME_ENTRY(SP, bitmapIndex).uint32);

                    ASSERT(!FrameStack::isPointerSlot(SP, sizeIndex));
                    UInt32Value size = FRAME_ENTRY(SP, sizeIndex).uint32;

                    Cell* block;
                    ALLOCATE_RECORDBLOCK(block, bitmap, size);

                    UInt32Value fieldOffset = 0;
                    for(int fieldIndex = 0;
                        fieldIndex < fieldsCount;
                        fieldIndex += 1)
                    {
                        UInt32Value fieldValueIndex = *fieldValueIndexes;
                        UInt32Value fieldSizeIndex = *fieldSizeIndexes;
                        fieldValueIndexes += 1;
                        fieldSizeIndexes += 1;

                        ASSERT(!FrameStack::isPointerSlot(SP, fieldSizeIndex));
                        UInt32Value fieldSize =
                        FRAME_ENTRY(SP, fieldSizeIndex).uint32;
                        ASSERT((1 == fieldSize) || (2 == fieldSize) || (0 == fieldSize));
                        switch (fieldSize) {
                        case 0: break;
                        case 1: 
                          {
                            ASSERT_SAME_TYPE_SLOT_FIELD
                                (SP, fieldValueIndex,
                                 block, fieldOffset);
                            Cell fieldValue =
                            FRAME_ENTRY(SP, fieldValueIndex);
                            Heap::initializeField
                            (block, fieldOffset, fieldValue);
                            break;
                          }
                        case 2:
                          {
                            ASSERT(!FrameStack::isPointerSlot (SP, fieldValueIndex))
                            ASSERT(!FrameStack::isPointerSlot (SP, fieldValueIndex + 1))
                            ASSERT(!Heap::isPointerField (block, fieldOffset));
                            ASSERT(!Heap::isPointerField (block, fieldOffset + 1));

                            ASSERT_SAME_TYPE_SLOT_FIELD
                                (SP, fieldValueIndex,
                                 block, fieldOffset);
                            ASSERT_SAME_TYPE_SLOT_FIELD
                                (SP, fieldValueIndex + 1,
                                 block, fieldOffset + 1);
                            Real64Value fieldValue =
                            *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, fieldValueIndex);
                            Heap::initializeField_D
                            (block, fieldOffset, fieldValue);
                            break;
                          }
                        default: ASSERT(false);break;
                        }
                        fieldOffset += fieldSize;
                    }
                    ASSERT(FrameStack::isPointerSlot(SP, destination));
                    FRAME_ENTRY(SP, destination).blockRef = block;
                    break;
                }
              case MakeFixedSizeBlock:
                {
                    UInt32Value bitmapIndex = getWordAndInc(PC);
                    UInt32Value size = getWordAndInc(PC);
                    UInt32Value fieldsCount = getWordAndInc(PC);
                    UInt32Value *fieldValueIndexes = PC;
                    PC += fieldsCount;
                    UInt32Value *fieldSizes = PC;
                    PC += fieldsCount;
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, bitmapIndex));
                    Bitmap bitmap =
                    (Bitmap)(FRAME_ENTRY(SP, bitmapIndex).uint32);

                    Cell* block;
                    ALLOCATE_RECORDBLOCK(block, bitmap, size);

                    UInt32Value fieldOffset = 0;
                    for(int index = 0; index < fieldsCount; index += 1)
                    {
                        UInt32Value fieldValueIndex = *fieldValueIndexes;
                        UInt32Value fieldSize = *fieldSizes;
                        ASSERT((1 == fieldSize) || (2 == fieldSize) || (0 == fieldSize));
                        switch (fieldSize) {
                        case 0: break;
                        case 1: 
                          {
                            ASSERT_SAME_TYPE_SLOT_FIELD
                                (SP, fieldValueIndex,
                                 block, fieldOffset);
                            Cell fieldValue =
                            FRAME_ENTRY(SP, fieldValueIndex);
                            Heap::initializeField
                            (block, fieldOffset, fieldValue);
                            break;
                          }
                        case 2:
                          {
                            ASSERT_SAME_TYPE_SLOT_FIELD
                                (SP, fieldValueIndex,
                                 block, fieldOffset);
                            Cell fieldValue = FRAME_ENTRY(SP, fieldValueIndex);
                            Heap::initializeField(block, fieldOffset, fieldValue);
                            fieldValue = FRAME_ENTRY(SP, fieldValueIndex + 1);
                            Heap::initializeField(block, fieldOffset + 1, fieldValue);
                            break;
                          }
                        default: ASSERT(false);break;
                        }
                        fieldOffset += fieldSize;
                        fieldValueIndexes += 1;
                        fieldSizes += 1;
                    }
                    ASSERT(FrameStack::isPointerSlot(SP, destination));
                    FRAME_ENTRY(SP, destination).blockRef = block;
                    break;
                }
              case MakeBlockOfSingleValues:
                {
                    UInt32Value bitmapIndex = getWordAndInc(PC);
                    UInt32Value fieldsCount = getWordAndInc(PC);
                    UInt32Value *fieldValueIndexes = PC;
                    PC += fieldsCount;
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, bitmapIndex));
                    Bitmap bitmap =
                    (Bitmap)(FRAME_ENTRY(SP, bitmapIndex).uint32);

                    Cell* block;
                    ALLOCATE_RECORDBLOCK(block, bitmap, fieldsCount);
                    for(int index = 0; index < fieldsCount; index += 1){
                        UInt32Value fieldValueIndex = *fieldValueIndexes;
                        fieldValueIndexes += 1;

                        ASSERT_SAME_TYPE_SLOT_FIELD
                            (SP, fieldValueIndex, block, index);
                        Cell fieldValue = FRAME_ENTRY(SP, fieldValueIndex);
                        Heap::initializeField(block, index, fieldValue);
                    }
                    ASSERT(FrameStack::isPointerSlot(SP, destination));
                    FRAME_ENTRY(SP, destination).blockRef = block;

                    break;
                }
              case MakeArray_S:
                {
                    UInt32Value bitmapIndex = getWordAndInc(PC);
                    UInt32Value sizeIndex = getWordAndInc(PC);
                    UInt32Value initialValueIndex = getWordAndInc(PC);
                    UInt32Value isMutable = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, bitmapIndex));
                    Bitmap bitmap =
                    (Bitmap)(FRAME_ENTRY(SP, bitmapIndex).uint32);

                    ASSERT(!FrameStack::isPointerSlot(SP, sizeIndex));
                    UInt32Value size = FRAME_ENTRY(SP, sizeIndex).uint32;

                    Cell* block;
                    if(0 == bitmap){
                        ALLOCATE_SINGLEATOMARRAY(block, size, isMutable);
                    }
                    else {
                        ALLOCATE_POINTERARRAY(block, size, isMutable);
                    }
                    Cell initialValue = FRAME_ENTRY(SP, initialValueIndex);
#ifdef IML_DEBUG
                    if(bitmap){
                        ASSERT(FrameStack::isPointerSlot (SP, initialValueIndex));
                        ASSERT(Heap::isValidBlockPointer (initialValue.blockRef));
                    }
#endif
                    for(int index = 0; index < size; index += 1){
                        Heap::initializeField(block, index, initialValue);
                    }
                    ASSERT(FrameStack::isPointerSlot(SP, destination));
                    FRAME_ENTRY(SP, destination).blockRef = block;
                    break;
                }
              case MakeArray_D:
                {
                    UInt32Value bitmapIndex = getWordAndInc(PC);
                    UInt32Value sizeIndex = getWordAndInc(PC);
                    UInt32Value initialValueIndex = getWordAndInc(PC);
                    UInt32Value isMutable = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, bitmapIndex));
                    Bitmap bitmap =
                    (Bitmap)(FRAME_ENTRY(SP, bitmapIndex).uint32);

                    ASSERT(!FrameStack::isPointerSlot(SP, sizeIndex));
                    UInt32Value size = FRAME_ENTRY(SP, sizeIndex).uint32;

                    Cell* block;
                    ASSERT(0 == bitmap);
                    ALLOCATE_DOUBLEATOMARRAY(block, size, isMutable);

                    Real64Value initialValue =
                        *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, initialValueIndex);
                    for(int index = 0; index < size; index += 2){
                        Heap::initializeField_D(block, index, initialValue);
                    }
                    ASSERT(FrameStack::isPointerSlot(SP, destination));
                    FRAME_ENTRY(SP, destination).blockRef = block;
                    break;
                }
              case MakeArray_V:
                {
                    UInt32Value bitmapIndex = getWordAndInc(PC);
                    UInt32Value sizeIndex = getWordAndInc(PC);
                    UInt32Value initialValueIndex = getWordAndInc(PC);
                    UInt32Value initialValueSizeIndex = getWordAndInc(PC);
                    UInt32Value isMutable = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, bitmapIndex));
                    Bitmap bitmap =
                    (Bitmap)(FRAME_ENTRY(SP, bitmapIndex).uint32);

                    ASSERT(!FrameStack::isPointerSlot(SP, sizeIndex));
                    UInt32Value size = FRAME_ENTRY(SP, sizeIndex).uint32;

                    ASSERT(!FrameStack::isPointerSlot
                               (SP, initialValueSizeIndex));
                    UInt32Value initialValueSize =
                    FRAME_ENTRY(SP, initialValueSizeIndex).uint32;

                    Cell* block;
                    if ( 1 == initialValueSize ) {
                        if (0 == bitmap) {
                            ALLOCATE_SINGLEATOMARRAY(block, size, isMutable);
                        } else {
                            ALLOCATE_POINTERARRAY(block, size, isMutable);
                        }
                        Cell initialValue = FRAME_ENTRY(SP, initialValueIndex);
#ifdef IML_DEBUG
                        // assert runtime type
                        if(bitmap){
                            ASSERT(FrameStack::isPointerSlot
                                   (SP, initialValueIndex));
                            ASSERT(Heap::isValidBlockPointer
                                   (initialValue.blockRef));
                        }
#endif

                        for(int index = 0; index < size; index += 1) {
                            Heap::initializeField
                              (block, index, initialValue);
                        }
                    } else {
                        ALLOCATE_DOUBLEATOMARRAY(block, size, isMutable);
                        Real64Value initialValue = 
                          *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, initialValueIndex);

                        for(int index = 0; index < size; index += 2) {
                            Heap::initializeField_D
                              (block, index, initialValue);
                        }
                    }

                    ASSERT(FrameStack::isPointerSlot(SP, destination));
                    FRAME_ENTRY(SP, destination).blockRef = block;
                    break;
                }
              case MakeClosure:
                {
                    Cell entryPoint;
                    entryPoint.uint32 = getWordAndInc(PC);
                    UInt32Value ENVIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    Bitmap bitmap = CLOSURE_BITMAP;

                    Cell* block;
                    ALLOCATE_RECORDBLOCK
                    (block, bitmap, CLOSURE_FIELDS_COUNT);

                    Heap::initializeField(block,
                                         CLOSURE_ENTRYPOINT_INDEX,
                                         entryPoint);

                    ASSERT(FrameStack::isPointerSlot(SP, ENVIndex));
                    Cell ENVBlock = FRAME_ENTRY(SP, ENVIndex);
                    ASSERT(Heap::isValidBlockPointer(ENVBlock.blockRef));
                    Heap::initializeField(block,
                                         CLOSURE_ENV_INDEX,
                                         ENVBlock);

                    ASSERT(FrameStack::isPointerSlot(SP, destination));
                    FRAME_ENTRY(SP, destination).blockRef = block;
                    break;
                }
              case Raise:
                {
                    UInt32Value exceptionIndex = getWordAndInc(PC);

                    ASSERT(FrameStack::isPointerSlot(SP, exceptionIndex));
                    Cell exceptionValue = FRAME_ENTRY(SP, exceptionIndex);
                    raiseException(SP, PC, ENV, exceptionValue);
                    break;
                }
              case PushHandler:
                {
                    UInt32Value* handler = (UInt32Value*)(getWordAndInc(PC));
                    UInt32Value exceptionIndex = getWordAndInc(PC);

                    HandlerStack::push(SP, exceptionIndex, handler);
                    break;
                }
              case PopHandler:
                {

                    HandlerStack::remove();
                    break;
                }
	      case RegisterCallback:
		{
		    UInt32Value closureIndex = getWordAndInc(PC);
		    UInt32Value sizeTag = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);
                    UInt32Value *entryPoint;
                    Cell *env;
		    Cell returnValue;

                    expandClosure(SP, closureIndex, entryPoint, env);

		    returnValue.uint32 =
		    (UInt32Value)FFI::instance().callback(entryPoint, env,
                                                          sizeTag);

		    FRAME_ENTRY(SP, destination) = returnValue;
		    break;
		}
/* case branch consists of two words: Constant, offset to jump destination. */
#define WORDS_OF_CASE 2 
              case SwitchInt:
              case SwitchWord:
              case SwitchChar:
                {
                    UInt32Value targetIndex = getWordAndInc(PC);
                    UInt32Value casesCount = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, targetIndex));
                    UInt32Value targetValue =
                    FRAME_ENTRY(SP, targetIndex).uint32;
                    // binary search
                    UInt32Value* start = PC;
                    UInt32Value* end = PC + ((casesCount - 1) * WORDS_OF_CASE);
                    // default
                    PC = (UInt32Value*)(getQuadByte(end + WORDS_OF_CASE));
                    while(start <= end)
                    {
                        /* CAUTION: To calculate center, simply
                         *    start + (end - start) / 2
                         * is wrong.
                         * Division by WORDS_OF_CASE and multiplicaton by
                         * WORDS_OF_CASE are necessary to truncate address to
                         * WORDS_OF_CASE boundary.
                         */
                        UInt32Value* center =
                        start
                        + ((((end - start) / WORDS_OF_CASE) // number of elems
                            / 2)  // index of the center
                           * WORDS_OF_CASE); // number of words to the center
                        ASSERT(0 == ((center - start) % WORDS_OF_CASE));
                        /* NOTE: constant is regarded as unsigned, even for
                         *      SwitchInt. Compiler must take care of this.
                         */
                        UInt32Value constant = *center;
                        if (targetValue < constant){
                            end = center - WORDS_OF_CASE;
                        }
                        else if(constant < targetValue){
                            start = center + WORDS_OF_CASE;
                        }
                        else{
                            PC = (UInt32Value*)(getQuadByte(center + 1));
                            break;
                        }
                    }
/*
                    for(int index = 0; index < casesCount; index += 1){
                        UInt32Value constant = getWordAndInc(PC);
                        UInt32Value* destination =
                        (UInt32Value*)(getWordAndInc(PC));
                        if(constant == targetValue){
                            PC = destination;
                            goto SWITCH_TARGET_FOUND;
                        }
                    }
                    PC = (UInt32Value*)(getQuadByte(PC));
                  SWITCH_TARGET_FOUND:
*/
                    break;
                }
              case SwitchLargeInt:
                {
                    UInt32Value targetIndex = getWordAndInc(PC);
                    UInt32Value casesCount = getWordAndInc(PC);

                    ASSERT(FrameStack::isPointerSlot(SP, targetIndex));
                    Cell* targetBlock = FRAME_ENTRY(SP, targetIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(targetBlock));
                    largeInt* targetPtr = (largeInt*)targetBlock;
//                    DBGWRAP(LOG.debug("SwitchLargeInt(%d)", LargeInt::toInt(*targetPtr)));

                    /* CAUTION : The binary search requires that list of
                     * constants is sorted in ascending order.
                     * This, then, requires that the compiler and the runtime
                     * agree about comparation method of string values.
                     * That is, String.compare and strcmp must return same
                     * order for all string pairs.
                     */
                    // binary search
                    UInt32Value* start = PC;
                    UInt32Value* end = PC + ((casesCount - 1) * WORDS_OF_CASE);
                    // default
                    PC = (UInt32Value*)(getQuadByte(end + WORDS_OF_CASE));
                    while(start <= end)
                    {
                        UInt32Value* center =
                        start
                        + ((((end - start) / WORDS_OF_CASE) // number of elems
                            / 2)  // index of the center
                           * WORDS_OF_CASE); // number of words to the center
                        ASSERT(0 == ((center - start) % WORDS_OF_CASE));

                        largeInt* constPtr = (largeInt*)(*center);
                        int compare = LargeInt::compare(*constPtr, *targetPtr);
                        if (0 < compare){// target < constant
                            end = center - WORDS_OF_CASE;
                        }
                        else if(compare < 0){// constant < target
                            start = center + WORDS_OF_CASE;
                        }
                        else{
                            PC = (UInt32Value*)(getQuadByte(center + 1));
                            break;
                        }
                    }
/*
                    for(int index = 0; index < casesCount; index += 1){
                        UInt32Value* constantAddress =
                        (UInt32Value*)getWordAndInc(PC);
                        UInt32Value* destination =
                        (UInt32Value*)(getWordAndInc(PC));
                        UInt32Value constantLength;
                        UInt32Value* constantBuffer;
                        LoadConstString
                        (constantAddress, &constantLength, &constantBuffer);

                        // compare string
                        if((targetLength == constantLength) &&
                           (0 ==
                            COMPARE_MEMORY
                            (targetBuffer, constantBuffer, constantLength)))
                        {
                            PC = destination;
                            goto SWITCH_STRING_TARGET_FOUND;
                        }
                    }
                    PC = (UInt32Value*)(getQuadByte(PC));
                  SWITCH_STRING_TARGET_FOUND:
*/
                    break;
                }
              case SwitchString:
                {
                    UInt32Value targetIndex = getWordAndInc(PC);
                    UInt32Value casesCount = getWordAndInc(PC);

                    ASSERT(FrameStack::isPointerSlot(SP, targetIndex));
                    Cell* targetBlock = FRAME_ENTRY(SP, targetIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(targetBlock));

                    int blockSize = Heap::getPayloadSize(targetBlock);
                    const UInt32Value targetLength =
                    HEAP_GETFIELD(targetBlock, blockSize - 1).uint32;
                    UInt32Value* targetBuffer =
                    (UInt32Value*)(&targetBlock[0]);

                    /* CAUTION : The binary search requires that list of
                     * constants is sorted in ascending order.
                     * This, then, requires that the compiler and the runtime
                     * agree about comparation method of string values.
                     * That is, String.compare and strcmp must return same
                     * order for all string pairs.
                     */
                    // binary search
                    UInt32Value* start = PC;
                    UInt32Value* end = PC + ((casesCount - 1) * WORDS_OF_CASE);
                    // default
                    PC = (UInt32Value*)(getQuadByte(end + WORDS_OF_CASE));
                    while(start <= end)
                    {
                        UInt32Value* center =
                        start
                        + ((((end - start) / WORDS_OF_CASE) // number of elems
                            / 2)  // index of the center
                           * WORDS_OF_CASE); // number of words to the center
                        ASSERT(0 == ((center - start) % WORDS_OF_CASE));

                        UInt32Value* constantAddress = (UInt32Value*)(*center);
                        UInt32Value constantLength;
                        UInt32Value* constantBuffer;
                        LoadConstString
                        (constantAddress, &constantLength, &constantBuffer);
                        int compare =
                        strcmp((char*)constantBuffer, (char*)targetBuffer);
                        if (0 < compare){// target < constant
                            end = center - WORDS_OF_CASE;
                        }
                        else if(compare < 0){// constant < target
                            start = center + WORDS_OF_CASE;
                        }
                        else{
                            PC = (UInt32Value*)(getQuadByte(center + 1));
                            break;
                        }
                    }
/*
                    for(int index = 0; index < casesCount; index += 1){
                        UInt32Value* constantAddress =
                        (UInt32Value*)getWordAndInc(PC);
                        UInt32Value* destination =
                        (UInt32Value*)(getWordAndInc(PC));
                        UInt32Value constantLength;
                        UInt32Value* constantBuffer;
                        LoadConstString
                        (constantAddress, &constantLength, &constantBuffer);

                        // compare string
                        if((targetLength == constantLength) &&
                           (0 ==
                            COMPARE_MEMORY
                            (targetBuffer, constantBuffer, constantLength)))
                        {
                            PC = destination;
                            goto SWITCH_STRING_TARGET_FOUND;
                        }
                    }
                    PC = (UInt32Value*)(getQuadByte(PC));
                  SWITCH_STRING_TARGET_FOUND:
*/
                    break;
                }
              case Jump:
                {
                    PC = (UInt32Value*)(getQuadByte(PC));
                    break;
                }
              case IndirectJump:
                {
                    UInt32Value variableIndex = getWordAndInc(PC);

                    ASSERT_VALID_FRAME_VAR(SP, variableIndex);
                    PC = (UInt32Value*)FRAME_ENTRY(SP, variableIndex).uint32;
                    break;
                }
              case Exit:
                {
                    goto EXIT_LOOP;
                }
              case Return_0:
                {
                    UInt32Value* calleeSP = SP;
                    FrameStack::popFrameAndReturn(SP, PC);// SP,PC are updated.
                    FrameStack::loadENV(SP, ENV);

                    /* The destination operand of caller CallStatic/Apply
                       instruction is stored at the return address. */
                    break;
                }
              case Return_S:
                {
                    UInt32Value variableIndex = getWordAndInc(PC);

                    UInt32Value* calleeSP = SP;
                    ASSERT_VALID_FRAME_VAR(SP, variableIndex);
                    FrameStack::popFrameAndReturn(SP, PC);// SP,PC are updated.
                    FrameStack::loadENV(SP, ENV);

                    /* The destination operand of caller CallStatic/Apply
                       instruction is stored at the return address. */
                    UInt32Value destination = getWordAndInc(PC);
                    ASSERT_SAME_TYPE_SLOTS(calleeSP, variableIndex,
                                           SP, destination);
                    FRAME_ENTRY(SP, destination) = FRAME_ENTRY(calleeSP,variableIndex);
                    break;
                }
              case Return_D:
                {
                    UInt32Value variableIndex = getWordAndInc(PC);

                    UInt32Value *calleeSP = SP;
                    ASSERT_VALID_FRAME_VAR(SP, variableIndex);
                    ASSERT_VALID_FRAME_VAR(SP, variableIndex + 1);
                    FrameStack::popFrameAndReturn(SP, PC);// SP,PC are updated.
                    FrameStack::loadENV(SP, ENV);

                    /* The destination operand of caller CallStatic/Apply
                       instruction is stored at the return address. */
                    UInt32Value destination = getWordAndInc(PC);
                    ASSERT_SAME_TYPE_SLOTS(calleeSP, variableIndex,
                                           SP, destination);
                    ASSERT_SAME_TYPE_SLOTS(calleeSP, variableIndex + 1,
                                           SP, destination + 1);

                    *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, destination) = 
                    *(Real64Value*)FRAME_ENTRY_ADDRESS(calleeSP, variableIndex);
                    break;
                }
              case Return_V:
                {
                    UInt32Value variableIndex = getWordAndInc(PC);
                    UInt32Value variableSizeIndex = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, variableSizeIndex));
                    UInt32Value variableSize =
                    FRAME_ENTRY(SP, variableSizeIndex).uint32;

                    UInt32Value *calleeSP = SP;
                    FrameStack::popFrameAndReturn(SP, PC);// SP,PC are updated.
                    FrameStack::loadENV(SP, ENV);

                    /* The destination operand of caller CallStatic/Apply
                       instruction is stored at the return address. */
                    UInt32Value destination = getWordAndInc(PC);
                    if ( 1 == variableSize) {
                        ASSERT_SAME_TYPE_SLOTS(calleeSP, variableIndex,
                                               SP, destination);
                        FRAME_ENTRY(SP, destination) = FRAME_ENTRY(calleeSP,variableIndex);
                    } else {
                        ASSERT_SAME_TYPE_SLOTS(calleeSP, variableIndex,
                                               SP, destination);
                        ASSERT_SAME_TYPE_SLOTS(calleeSP, variableIndex + 1,
                                               SP, destination + 1);
                        *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, destination) = 
                        *(Real64Value*)FRAME_ENTRY_ADDRESS(calleeSP, variableIndex);
                    }
                    break;
                }
              case Return_MS:
                {
                    UInt32Value variablesCount = getWordAndInc(PC);
                    UInt32Value *variableIndexes = PC;
                    PC += variablesCount;

                    UInt32Value *calleeSP = SP;
                    FrameStack::popFrameAndReturn(SP, PC);// SP,PC are updated.
                    FrameStack::loadENV(SP, ENV);

                    /* The destination operand of caller CallStatic/Apply
                       instruction is stored at the return address. */
                    PC += 1; /**/
                    UInt32Value *destIndexes = PC;
                    PC += variablesCount;
                    for (int index = 0 ; index < variablesCount ; index += 1) {
                        ASSERT_SAME_TYPE_SLOTS(calleeSP, *variableIndexes,
                                               SP, *destIndexes);
                        FRAME_ENTRY(SP, *destIndexes) = FRAME_ENTRY(calleeSP, *variableIndexes);
                        destIndexes += 1;
                        variableIndexes += 1;
                    }
                    break;
                }
              case Return_MLD:
                {
                    UInt32Value variablesCount = getWordAndInc(PC);
                    UInt32Value *variableIndexes = PC;
                    PC += variablesCount;

                    UInt32Value *calleeSP = SP;
                    FrameStack::popFrameAndReturn(SP, PC);// SP,PC are updated.
                    FrameStack::loadENV(SP, ENV);

                    /* The destination operand of caller CallStatic/Apply
                       instruction is stored at the return address. */
                    PC += 1; /**/
                    UInt32Value *destIndexes = PC;
                    PC += variablesCount;
                    for (int index = 1 ; index < variablesCount ; index += 1) {
                        ASSERT_SAME_TYPE_SLOTS(calleeSP, *variableIndexes,
                                               SP, *destIndexes);
                        FRAME_ENTRY(SP, *destIndexes) = FRAME_ENTRY(calleeSP, *variableIndexes);
                        destIndexes += 1;
                        variableIndexes += 1;
                    }
                    ASSERT_SAME_TYPE_SLOTS(calleeSP, *variableIndexes,
                                           SP, *destIndexes);
                    ASSERT_SAME_TYPE_SLOTS(calleeSP, (*variableIndexes) + 1,
                                           SP, (*destIndexes) + 1);
                    *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, *destIndexes) = 
                    *(Real64Value*)FRAME_ENTRY_ADDRESS(calleeSP, *variableIndexes);
                    break;
                }
              case Return_MLV:
                {
                    UInt32Value variablesCount = getWordAndInc(PC);
                    UInt32Value *variableIndexes = PC;
                    PC += variablesCount;
                    UInt32Value lastVariableSizeIndex = getWordAndInc(PC);

                    ASSERT(!FrameStack::isPointerSlot(SP, lastVariableSizeIndex));
                    UInt32Value lastVariableSize =
                    FRAME_ENTRY(SP, lastVariableSizeIndex).uint32;


                    UInt32Value *calleeSP = SP;
                    FrameStack::popFrameAndReturn(SP, PC);// SP,PC are updated.
                    FrameStack::loadENV(SP, ENV);

                    /* The destination operand of caller CallStatic/Apply
                       instruction is stored at the return address. */
                    PC += 1; /**/
                    UInt32Value *destIndexes = PC;
                    PC += variablesCount;
                    for (int index = 1 ; index < variablesCount ; index += 1) {
                        ASSERT_SAME_TYPE_SLOTS(calleeSP, *variableIndexes,
                                               SP, *destIndexes);
                        FRAME_ENTRY(SP, *destIndexes) = FRAME_ENTRY(calleeSP, *variableIndexes);
                        destIndexes += 1;
                        variableIndexes += 1;
                    }
                    if ( 1 == lastVariableSize) {
                        ASSERT_SAME_TYPE_SLOTS(calleeSP, *variableIndexes,
                                               SP, *destIndexes);
                        FRAME_ENTRY(SP, *destIndexes) = FRAME_ENTRY(calleeSP, *variableIndexes);
                    } else {
                        ASSERT_SAME_TYPE_SLOTS(calleeSP, *variableIndexes,
                                               SP, *destIndexes);
                        ASSERT_SAME_TYPE_SLOTS(calleeSP, (*variableIndexes) + 1,
                                               SP, (*destIndexes) + 1);
                        *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, *destIndexes) = 
                        *(Real64Value*)FRAME_ENTRY_ADDRESS(calleeSP, *variableIndexes);
                    }
                    break;
                }
              case Return_MF:
                {
                    UInt32Value variablesCount = getWordAndInc(PC);
                    UInt32Value *variableIndexes = PC;
                    PC += variablesCount;
                    UInt32Value *variableSizes = PC;
                    PC += variablesCount;

                    UInt32Value *calleeSP = SP;
                    FrameStack::popFrameAndReturn(SP, PC);// SP,PC are updated.
                    FrameStack::loadENV(SP, ENV);

                    /* The destination operand of caller CallStatic/Apply
                       instruction is stored at the return address. */
                    PC += 1; /**/
                    UInt32Value *destIndexes = PC;
                    PC += variablesCount;
                    for (int index = 0 ; index < variablesCount ; index += 1) {
                        if (1 == (*variableSizes)) {
                            ASSERT_SAME_TYPE_SLOTS(calleeSP, *variableIndexes,
                                                   SP, *destIndexes);
                            FRAME_ENTRY(SP, *destIndexes) = FRAME_ENTRY(calleeSP, *variableIndexes);
                        } else {
                            ASSERT_SAME_TYPE_SLOTS(calleeSP, *variableIndexes,
                                                   SP, *destIndexes);
                            ASSERT_SAME_TYPE_SLOTS(calleeSP, (*variableIndexes) + 1,
                                                   SP, (*destIndexes) + 1);
                            *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, *destIndexes) = 
                            *(Real64Value*)FRAME_ENTRY_ADDRESS(calleeSP, *variableIndexes);
                        }
                        variableIndexes += 1;
                        destIndexes += 1;
                        variableSizes += 1;
                    }
                    break;
                }
              case Return_MV:
                {
                    UInt32Value variablesCount = getWordAndInc(PC);
                    UInt32Value *variableIndexes = PC;
                    PC += variablesCount;
                    UInt32Value *variableSizeIndexes = PC;
                    PC += variablesCount;

                    UInt32Value *calleeSP = SP;
                    FrameStack::popFrameAndReturn(SP, PC);// SP,PC are updated.
                    FrameStack::loadENV(SP, ENV);

                    /* The destination operand of caller CallStatic/Apply
                       instruction is stored at the return address. */
                    PC += 1; /**/
                    UInt32Value *destIndexes = PC;
                    PC += variablesCount;
                    for (int index = 0 ; index < variablesCount ; index += 1) {
                        UInt32Value variableSize = FRAME_ENTRY(calleeSP, *variableSizeIndexes).uint32;
                        if (1 == variableSize) {
                            ASSERT_SAME_TYPE_SLOTS(calleeSP, *variableIndexes,
                                                   SP, *destIndexes);
                            FRAME_ENTRY(SP, *destIndexes) = FRAME_ENTRY(calleeSP, *variableIndexes);
                        } else {
                            ASSERT_SAME_TYPE_SLOTS(calleeSP, *variableIndexes,
                                                   SP, *destIndexes);
                            ASSERT_SAME_TYPE_SLOTS(calleeSP, (*variableIndexes) + 1,
                                                   SP, (*destIndexes) + 1);
                            *(Real64Value*)FRAME_ENTRY_ADDRESS(SP, *destIndexes) = 
                            *(Real64Value*)FRAME_ENTRY_ADDRESS(calleeSP, *variableIndexes);
                        }
                        variableIndexes += 1;
                        destIndexes += 1;
                        variableSizeIndexes += 1;
                    }
                    break;
                }
              case Nop:
                {
                    break;
                }
              case ForeignApply:
                {
                    UInt32Value closureIndex = getWordAndInc(PC);
                    UInt32Value argsCount = getWordAndInc(PC);
                    UInt32Value switchTag = getWordAndInc(PC);
                    UInt32Value convention = getWordAndInc(PC);
                    UInt32Value* argIndexes = PC;
                    PC += argsCount;
                    UInt32Value destination = getWordAndInc(PC);

                    void* function =
                      (void*)(FRAME_ENTRY(SP, closureIndex).uint32);
                    if(0 == function){
                        DBGWRAP(LOG.debug("null function pointer");)
                        throw FFIException("null function pointer");
                    }

		    SP_ = SP;

		    FFI::instance().call(&FRAME_ENTRY(SP, destination),
                                         function, SP,
                                         switchTag, convention,
                                         argIndexes, argsCount);

                    ASSERT(!FrameStack::isUpperFrameThan(SP_, SP));
		    SP = SP_;

                    break;
                }

/* Functions which are called in macros PRIMITIVE_*_fun may set an exception.
 * CHECK_EXCEPTION detects it and invokes VM exception handler. */
#define CHECK_EXCEPTION \
                if(isPrimitiveExceptionRaised_){ \
                     raiseException(SP, PC, ENV, primitiveException_); \
                     resetPrimitiveException(); \
                     break; \
                }
#define PRIMITIVE_I_I_op(op) \
            { \
                UInt32Value argIndex = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).sint32 = \
                op (FRAME_ENTRY(SP, argIndex).sint32); \
                break; \
            } 
#define PRIMITIVE_L_L_fun(f) \
            { \
                UInt32Value argIndex = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                Cell* block; \
                ALLOCATE_LARGEINTBLOCK(block, NULL); \
                f(*(largeInt*)block, \
                   *(largeInt*)(FRAME_ENTRY(SP, argIndex).blockRef)); \
                FRAME_ENTRY(SP, destination).blockRef = block; \
                CHECK_EXCEPTION; \
                break; \
            } 
#define PRIMITIVE_W_W_op(op) \
            { \
                UInt32Value argIndex = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).uint32 = \
                op (FRAME_ENTRY(SP, argIndex).uint32); \
                break; \
            } 
#define PRIMITIVE_W_W_fun(f) \
            { \
                UInt32Value argIndex = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).uint32 = \
                f(FRAME_ENTRY(SP, argIndex).uint32); \
                CHECK_EXCEPTION; \
                break; \
            } 
#ifdef FLOAT_UNBOXING
/*
#define PRIMITIVE_R_R_op(op) \
            { \
                UInt32Value argIndex = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, argIndex)); \
                ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, destination)); \
                Real64Value arg = \
                  PrimitiveSupport::WORDS_TO_REAL64 \
                                 (FRAME_ENTRY(SP, argIndex).uint32, \
                                  FRAME_ENTRY(SP, argIndex + 1).uint32); \
                Real64Value result = op (arg); \
                PrimitiveSupport::REAL64_TO_WORDS \
                               (result, \
                                &FRAME_ENTRY(SP, destination).uint32, \
                                &FRAME_ENTRY(SP, destination + 1).uint32); \
                break; \
            }
*/
#define PRIMITIVE_R_R_op(op) \
            { \
                UInt32Value argIndex = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, argIndex)); \
                ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, destination)); \
                Real64Value arg = \
                  *(Real64Value*)(FRAME_ENTRY_ADDRESS(SP, argIndex)); \
                Real64Value result = op (arg); \
                *(Real64Value*)(FRAME_ENTRY_ADDRESS(SP, destination)) = \
                  result; \
                break; \
            } 
#else // FLOAT_UNBOXING
#define PRIMITIVE_R_R_op(op) \
            { \
                UInt32Value argIndex = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                Real64Value arg = \
                  BLOCK_TO_REAL64(FRAME_ENTRY(SP, argIndex).blockRef); \
                Real64Value result = op (arg); \
                FRAME_ENTRY(SP, destination).blockRef = \
                  REAL64_TO_BLOCK(result); \
                break; \
            } 
#endif // FLOAT_UNBOXING
#define PRIMITIVE_F_F_op(op) \
            { \
                UInt32Value argIndex = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).real32 = \
                op (FRAME_ENTRY(SP, argIndex).real32); \
                break; \
            } 
#define PRIMITIVE_II_I_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).sint32 = \
                FRAME_ENTRY(SP, argIndex1).sint32 \
                op FRAME_ENTRY(SP, argIndex2).sint32; \
                break; \
            } 
#define PRIMITIVE_II_I_fun(f) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).sint32 = \
                f(FRAME_ENTRY(SP, argIndex1).sint32, \
                  FRAME_ENTRY(SP, argIndex2).sint32); \
                CHECK_EXCEPTION; \
                break; \
            } 
#define PRIMITIVE_II_I_Const_1_op(op) \
            { \
                SInt32Value arg1 = (SInt32Value)getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).sint32 = \
                arg1 op FRAME_ENTRY(SP, argIndex2).sint32; \
                break; \
            } 
#define PRIMITIVE_II_I_Const_1_fun(f) \
            { \
                SInt32Value arg1 = (SInt32Value)getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).sint32 = \
                f(arg1, FRAME_ENTRY(SP, argIndex2).sint32); \
                CHECK_EXCEPTION; \
                break; \
            } 
#define PRIMITIVE_II_I_Const_2_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                SInt32Value arg2 = (SInt32Value)getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).sint32 = \
                FRAME_ENTRY(SP, argIndex1).sint32 op arg2; \
                break; \
            } 
#define PRIMITIVE_II_I_Const_2_fun(f) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                SInt32Value arg2 = (SInt32Value)getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).sint32 = \
                f(FRAME_ENTRY(SP, argIndex1).sint32, arg2); \
                CHECK_EXCEPTION; \
                break; \
            } 
#define PRIMITIVE_LL_L_fun(f) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                Cell* block; \
                ALLOCATE_LARGEINTBLOCK(block, NULL); \
                f(*(largeInt*)block, \
                    *(largeInt*)(FRAME_ENTRY(SP, argIndex1).blockRef), \
                    *(largeInt*)(FRAME_ENTRY(SP, argIndex2).blockRef)); \
                CHECK_EXCEPTION; \
                FRAME_ENTRY(SP, destination).blockRef = block; \
                break; \
            } 
#define PRIMITIVE_LL_L_Const_1_fun(f) \
            { \
                largeInt* argPtr1 = (largeInt*)getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                Cell* block; \
                ALLOCATE_LARGEINTBLOCK(block, NULL); \
                f(*(largeInt*)block, \
                    *argPtr1, \
                    *(largeInt*)(FRAME_ENTRY(SP, argIndex2).blockRef)); \
                CHECK_EXCEPTION; \
                FRAME_ENTRY(SP, destination).blockRef = block; \
                break; \
            } 
#define PRIMITIVE_LL_L_Const_2_fun(f) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                largeInt* argPtr2 = (largeInt*)getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                Cell* block; \
                ALLOCATE_LARGEINTBLOCK(block, NULL); \
                f(*(largeInt*)block, \
                    *(largeInt*)(FRAME_ENTRY(SP, argIndex1).blockRef), \
                    *argPtr2); \
                CHECK_EXCEPTION; \
                FRAME_ENTRY(SP, destination).blockRef = block; \
                break; \
            } 
#define PRIMITIVE_WW_W_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).uint32 = \
                FRAME_ENTRY(SP, argIndex1).uint32 \
                op FRAME_ENTRY(SP, argIndex2).uint32; \
                break; \
            } 
#define PRIMITIVE_WW_W_fun(f) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).uint32 = \
                f(FRAME_ENTRY(SP, argIndex1).uint32, \
                  FRAME_ENTRY(SP, argIndex2).uint32); \
                CHECK_EXCEPTION; \
                break; \
            } 
#define PRIMITIVE_WW_W_Const_1_op(op) \
            { \
                UInt32Value arg1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).uint32 = \
                arg1 op FRAME_ENTRY(SP, argIndex2).uint32; \
                break; \
            } 
#define PRIMITIVE_WW_W_Const_1_fun(f) \
            { \
                UInt32Value arg1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).uint32 = \
                f(arg1, FRAME_ENTRY(SP, argIndex2).uint32); \
                CHECK_EXCEPTION; \
                break; \
            } 
#define PRIMITIVE_WW_W_Const_2_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value arg2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).uint32 = \
                FRAME_ENTRY(SP, argIndex1).uint32 op arg2; \
                break; \
            } 
#define PRIMITIVE_WW_W_Const_2_fun(f) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value arg2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).uint32 = \
                f(FRAME_ENTRY(SP, argIndex1).uint32, arg2); \
                CHECK_EXCEPTION; \
                break; \
            } 
#define PRIMITIVE_BB_B_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).uint32 = \
                (ByteValue) \
                  ((ByteValue)(FRAME_ENTRY(SP, argIndex1).uint32) \
                   op ((ByteValue)FRAME_ENTRY(SP, argIndex2).uint32)); \
                break; \
            } 
#define PRIMITIVE_BB_B_fun(f) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).uint32 = \
                (ByteValue) \
                  f((ByteValue)(FRAME_ENTRY(SP, argIndex1).uint32), \
                    ((ByteValue)FRAME_ENTRY(SP, argIndex2).uint32)); \
                CHECK_EXCEPTION; \
                break; \
            } 
#define PRIMITIVE_BB_B_Const_1_op(op) \
            { \
                ByteValue arg1 = (ByteValue)getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).uint32 = \
                (ByteValue) \
                  (arg1 op ((ByteValue)FRAME_ENTRY(SP, argIndex2).uint32)); \
                break; \
            } 
#define PRIMITIVE_BB_B_Const_1_fun(f) \
            { \
                ByteValue arg1 = (ByteValue)getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).uint32 = \
                (ByteValue) \
                  f(arg1, ((ByteValue)FRAME_ENTRY(SP, argIndex2).uint32)); \
                CHECK_EXCEPTION; \
                break; \
            } 
#define PRIMITIVE_BB_B_Const_2_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                ByteValue arg2 = (ByteValue)getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).uint32 = \
                (ByteValue) \
                  (((ByteValue)FRAME_ENTRY(SP, argIndex1).uint32) op arg2); \
                break; \
            } 
#define PRIMITIVE_BB_B_Const_2_fun(f) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                ByteValue arg2 = (ByteValue)getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).uint32 = \
                (ByteValue) \
                  f(((ByteValue)FRAME_ENTRY(SP, argIndex1).uint32), arg2); \
                CHECK_EXCEPTION; \
                break; \
            } 
#ifdef FLOAT_UNBOXING
#define PRIMITIVE_RR_R_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, argIndex1)); \
                ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, argIndex2)); \
                ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, destination)); \
                Real64Value arg1 = \
                  *(Real64Value*)(FRAME_ENTRY_ADDRESS(SP, argIndex1)); \
                Real64Value arg2 = \
                  *(Real64Value*)(FRAME_ENTRY_ADDRESS(SP, argIndex2)); \
                Real64Value result = arg1 op arg2; \
                *(Real64Value*)(FRAME_ENTRY_ADDRESS(SP, destination)) = \
                  result; \
                break; \
            } 
#define PRIMITIVE_RR_R_Const_1_op(op) \
            { \
                Real64Value arg1 = LoadConstReal64(PC); \
                PC += 2; \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, argIndex2)); \
                ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, destination)); \
                Real64Value arg2 = \
                  *(Real64Value*)(FRAME_ENTRY_ADDRESS(SP, argIndex2)); \
                Real64Value result = arg1 op arg2; \
                *(Real64Value*)(FRAME_ENTRY_ADDRESS(SP, destination)) = \
                  result; \
                break; \
            } 
#define PRIMITIVE_RR_R_Const_2_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                Real64Value arg2 = LoadConstReal64(PC); \
                PC += 2; \
                UInt32Value destination = getWordAndInc(PC); \
                ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, argIndex1)); \
                ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, destination)); \
                Real64Value arg1 = \
                  *(Real64Value*)(FRAME_ENTRY_ADDRESS(SP, argIndex1)); \
                Real64Value result = arg1 op arg2; \
                *(Real64Value*)(FRAME_ENTRY_ADDRESS(SP, destination)) = \
                  result; \
                break; \
            } 
#else
#define PRIMITIVE_RR_R_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                Real64Value arg1 = \
                  BLOCK_TO_REAL64(FRAME_ENTRY(SP, argIndex1).blockRef); \
                Real64Value arg2 = \
                  BLOCK_TO_REAL64(FRAME_ENTRY(SP, argIndex2).blockRef); \
                Real64Value result = arg1 op arg2; \
                FRAME_ENTRY(SP, destination).blockRef = \
                  REAL64_TO_BLOCK(result); \
                break; \
            } 
#endif // FLOAT_UNBOXING
#define PRIMITIVE_FF_F_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).real32 = \
                  (FRAME_ENTRY(SP, argIndex1).real32) \
                   op (FRAME_ENTRY(SP, argIndex2).real32); \
                break; \
            } 
#define PRIMITIVE_FF_F_Const_1_op(op) \
            { \
                Real32Value arg1 = LoadConstReal32(PC); \
                PC += 1; \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).real32 = \
                  (arg1 op (FRAME_ENTRY(SP, argIndex2).real32)); \
                break; \
            } 
#define PRIMITIVE_FF_F_Const_2_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                Real32Value arg2 = LoadConstReal32(PC); \
                PC += 1; \
                UInt32Value destination = getWordAndInc(PC); \
                FRAME_ENTRY(SP, destination).real32 = \
                  ((FRAME_ENTRY(SP, argIndex1).real32) op arg2); \
                break; \
            } 
#define PRIMITIVE_II_T_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                bool result = \
                     FRAME_ENTRY(SP, argIndex1).sint32 \
                     op FRAME_ENTRY(SP, argIndex2).sint32; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#define PRIMITIVE_II_T_Const_1_op(op) \
            { \
                SInt32Value arg1 = (SInt32Value)getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                bool result = arg1 op FRAME_ENTRY(SP, argIndex2).sint32; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#define PRIMITIVE_II_T_Const_2_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                SInt32Value arg2 = (SInt32Value)getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                bool result = FRAME_ENTRY(SP, argIndex1).sint32 op arg2; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#define PRIMITIVE_LL_T_fun(f) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                bool result = \
                  f(*(largeInt*)(FRAME_ENTRY(SP, argIndex1).blockRef), \
                    *(largeInt*)(FRAME_ENTRY(SP, argIndex2).blockRef)); \
                CHECK_EXCEPTION; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#define PRIMITIVE_LL_T_Const_1_fun(f) \
            { \
                largeInt* argPtr1 = (largeInt*)getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                bool result = \
                  f(*argPtr1, \
                    *(largeInt*)(FRAME_ENTRY(SP, argIndex2).blockRef)); \
                CHECK_EXCEPTION; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#define PRIMITIVE_LL_T_Const_2_fun(f) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                largeInt* argPtr2 = (largeInt*)getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                bool result = \
                  f(*(largeInt*)(FRAME_ENTRY(SP, argIndex1).blockRef), \
                    *argPtr2); \
                CHECK_EXCEPTION; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#define PRIMITIVE_WW_T_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                bool result = \
                     FRAME_ENTRY(SP, argIndex1).uint32 \
                     op FRAME_ENTRY(SP, argIndex2).uint32; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#define PRIMITIVE_WW_T_Const_1_op(op) \
            { \
                UInt32Value arg1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                bool result = arg1 op FRAME_ENTRY(SP, argIndex2).uint32; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#define PRIMITIVE_WW_T_Const_2_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value arg2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                bool result = FRAME_ENTRY(SP, argIndex1).uint32 op arg2; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#ifdef FLOAT_UNBOXING
#define PRIMITIVE_RR_T_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, argIndex1)); \
                ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, argIndex2)); \
                Real64Value arg1 = \
                  *(Real64Value*)(FRAME_ENTRY_ADDRESS(SP, argIndex1)); \
                Real64Value arg2 = \
                  *(Real64Value*)(FRAME_ENTRY_ADDRESS(SP, argIndex2)); \
                bool result = arg1 op arg2; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#define PRIMITIVE_RR_T_Const_1_op(op) \
            { \
                Real64Value arg1 = LoadConstReal64(PC); \
                PC += 2; \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, argIndex2)); \
                Real64Value arg2 = \
                  *(Real64Value*)(FRAME_ENTRY_ADDRESS(SP, argIndex2)); \
                bool result = arg1 op arg2; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#define PRIMITIVE_RR_T_Const_2_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                Real64Value arg2 = LoadConstReal64(PC); \
                PC += 2; \
                UInt32Value destination = getWordAndInc(PC); \
                ASSERT_REAL64_ALIGNED(FRAME_ENTRY_ADDRESS(SP, argIndex1)); \
                Real64Value arg1 = \
                  *(Real64Value*)(FRAME_ENTRY_ADDRESS(SP, argIndex1)); \
                bool result = arg1 op arg2; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#else // FLOAT_UNBOXING
#define PRIMITIVE_RR_T_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                Real64Value arg1 = \
                  BLOCK_TO_REAL64(FRAME_ENTRY(SP, argIndex1).blockRef); \
                Real64Value arg2 = \
                  BLOCK_TO_REAL64(FRAME_ENTRY(SP, argIndex2).blockRef); \
                bool result = arg1 op arg2; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#endif // FLOAT_UNBOXING
#define PRIMITIVE_FF_T_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                bool result = \
                     FRAME_ENTRY(SP, argIndex1).real32 \
                     op FRAME_ENTRY(SP, argIndex2).real32; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#define PRIMITIVE_FF_T_Const_1_op(op) \
            { \
                Real32Value arg1 = LoadConstReal32(PC); \
                PC += 1; \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                bool result = arg1 op FRAME_ENTRY(SP, argIndex2).real32; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#define PRIMITIVE_FF_T_Const_2_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                Real32Value arg2 = LoadConstReal32(PC); \
                PC += 1; \
                UInt32Value destination = getWordAndInc(PC); \
                bool result = FRAME_ENTRY(SP, argIndex1).real32 op arg2; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 
#define PRIMITIVE_COMPARE_SS_T_op(op) \
            { \
                UInt32Value argIndex1 = getWordAndInc(PC); \
                UInt32Value argIndex2 = getWordAndInc(PC); \
                UInt32Value destination = getWordAndInc(PC); \
                const char* arg1 = \
                  PrimitiveSupport::cellToString(FRAME_ENTRY(SP, argIndex1)); \
                const char* arg2 = \
                  PrimitiveSupport::cellToString(FRAME_ENTRY(SP, argIndex2)); \
                bool result = strcmp(arg1, arg2) op; \
                FRAME_ENTRY(SP, destination) = \
                  PrimitiveSupport::boolToCell(result); \
                break; \
            } 

              case Equal:
                {
                    UInt32Value arg1Index = getWordAndInc(PC);
                    UInt32Value arg2Index = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT_SAME_TYPE_SLOTS(SP, arg1Index, SP, arg2Index);
                    Cell arg1Value = FRAME_ENTRY(SP, arg1Index);
                    Cell arg2Value = FRAME_ENTRY(SP, arg2Index);

                    bool isEqual;
                    if(arg1Value.uint32 == arg2Value.uint32){ isEqual = true; }
                    else if(FrameStack::isPointerSlot(SP, arg1Index)){
                        isEqual =
                        Heap::isSimilarBlockGraph
                        (arg1Value.blockRef, arg2Value.blockRef);
                    }
                    else{ isEqual = false; }

                    FRAME_ENTRY(SP, destination) =
                    PrimitiveSupport::boolToCell(isEqual);
                    break;
                }
              case AddInt: PRIMITIVE_II_I_op(+);
              case AddInt_Const_1: PRIMITIVE_II_I_Const_1_op(+);
              case AddInt_Const_2: PRIMITIVE_II_I_Const_2_op(+);
              case AddLargeInt: PRIMITIVE_LL_L_fun(LargeInt::add);
              case AddLargeInt_Const_1:
                PRIMITIVE_LL_L_Const_1_fun(LargeInt::add);
              case AddLargeInt_Const_2:
                PRIMITIVE_LL_L_Const_2_fun(LargeInt::add);
              case AddReal: PRIMITIVE_RR_R_op(+);
              case AddReal_Const_1: PRIMITIVE_RR_R_Const_1_op(+);
              case AddReal_Const_2: PRIMITIVE_RR_R_Const_2_op(+);
              case AddFloat: PRIMITIVE_FF_F_op(+);
              case AddFloat_Const_1: PRIMITIVE_FF_F_Const_1_op(+);
              case AddFloat_Const_2: PRIMITIVE_FF_F_Const_2_op(+);
              case AddWord: PRIMITIVE_WW_W_op(+);
              case AddWord_Const_1: PRIMITIVE_WW_W_Const_1_op(+);
              case AddWord_Const_2: PRIMITIVE_WW_W_Const_2_op(+);
              case AddByte: PRIMITIVE_BB_B_op(+);
              case AddByte_Const_1: PRIMITIVE_BB_B_Const_1_op(+);
              case AddByte_Const_2: PRIMITIVE_BB_B_Const_2_op(+);
              case SubInt: PRIMITIVE_II_I_op(-);
              case SubInt_Const_1: PRIMITIVE_II_I_Const_1_op(-);
              case SubInt_Const_2: PRIMITIVE_II_I_Const_2_op(-);
              case SubLargeInt: PRIMITIVE_LL_L_fun(LargeInt::sub);
              case SubLargeInt_Const_1:
                PRIMITIVE_LL_L_Const_1_fun(LargeInt::sub);
              case SubLargeInt_Const_2:
                PRIMITIVE_LL_L_Const_2_fun(LargeInt::sub);
              case SubReal: PRIMITIVE_RR_R_op(-);
              case SubReal_Const_1: PRIMITIVE_RR_R_Const_1_op(-);
              case SubReal_Const_2: PRIMITIVE_RR_R_Const_2_op(-);
              case SubFloat: PRIMITIVE_FF_F_op(-);
              case SubFloat_Const_1: PRIMITIVE_FF_F_Const_1_op(-);
              case SubFloat_Const_2: PRIMITIVE_FF_F_Const_2_op(-);
              case SubWord: PRIMITIVE_WW_W_op(-);
              case SubWord_Const_1: PRIMITIVE_WW_W_Const_1_op(-);
              case SubWord_Const_2: PRIMITIVE_WW_W_Const_2_op(-);
              case SubByte: PRIMITIVE_BB_B_op(-);
              case SubByte_Const_1: PRIMITIVE_BB_B_Const_1_op(-);
              case SubByte_Const_2: PRIMITIVE_BB_B_Const_2_op(-);
              case MulInt: PRIMITIVE_II_I_op(*);
              case MulInt_Const_1: PRIMITIVE_II_I_Const_1_op(*);
              case MulInt_Const_2: PRIMITIVE_II_I_Const_2_op(*);
              case MulLargeInt: PRIMITIVE_LL_L_fun(LargeInt::mul);
              case MulLargeInt_Const_1:
                PRIMITIVE_LL_L_Const_1_fun(LargeInt::mul);
              case MulLargeInt_Const_2:
                PRIMITIVE_LL_L_Const_2_fun(LargeInt::mul);
              case MulReal: PRIMITIVE_RR_R_op(*);
              case MulReal_Const_1: PRIMITIVE_RR_R_Const_1_op(*);
              case MulReal_Const_2: PRIMITIVE_RR_R_Const_2_op(*);
              case MulFloat: PRIMITIVE_FF_F_op(*);
              case MulFloat_Const_1: PRIMITIVE_FF_F_Const_1_op(*);
              case MulFloat_Const_2: PRIMITIVE_FF_F_Const_2_op(*);
              case MulWord: PRIMITIVE_WW_W_op(*);
              case MulWord_Const_1: PRIMITIVE_WW_W_Const_1_op(*);
              case MulWord_Const_2: PRIMITIVE_WW_W_Const_2_op(*);
              case MulByte: PRIMITIVE_BB_B_op(*);
              case MulByte_Const_1: PRIMITIVE_BB_B_Const_1_op(*);
              case MulByte_Const_2: PRIMITIVE_BB_B_Const_2_op(*);
              case DivInt: PRIMITIVE_II_I_fun(divInt);
              case DivInt_Const_1: PRIMITIVE_II_I_Const_1_fun(divInt);
              case DivInt_Const_2: PRIMITIVE_II_I_Const_2_fun(divInt);
              case DivLargeInt: PRIMITIVE_LL_L_fun(LargeInt::div);
              case DivLargeInt_Const_1:
                PRIMITIVE_LL_L_Const_1_fun(LargeInt::div);
              case DivLargeInt_Const_2:
                PRIMITIVE_LL_L_Const_2_fun(LargeInt::div);
              case DivWord: PRIMITIVE_WW_W_fun(divWord);
              case DivWord_Const_1: PRIMITIVE_WW_W_Const_1_fun(divWord);
              case DivWord_Const_2: PRIMITIVE_WW_W_Const_2_fun(divWord);
              case DivByte: PRIMITIVE_BB_B_fun(divByte);
              case DivByte_Const_1: PRIMITIVE_BB_B_Const_1_fun(divByte);
              case DivByte_Const_2: PRIMITIVE_BB_B_Const_2_fun(divByte);
              case DivReal: PRIMITIVE_RR_R_op(/);
              case DivReal_Const_1: PRIMITIVE_RR_R_Const_1_op(/);
              case DivReal_Const_2: PRIMITIVE_RR_R_Const_2_op(/);
              case DivFloat: PRIMITIVE_FF_F_op(/);
              case DivFloat_Const_1: PRIMITIVE_FF_F_Const_1_op(/);
              case DivFloat_Const_2: PRIMITIVE_FF_F_Const_2_op(/);
              case ModInt: PRIMITIVE_II_I_fun(modInt);
              case ModInt_Const_1: PRIMITIVE_II_I_Const_1_fun(modInt);
              case ModInt_Const_2: PRIMITIVE_II_I_Const_2_fun(modInt);
              case ModLargeInt: PRIMITIVE_LL_L_fun(LargeInt::mod);
              case ModLargeInt_Const_1:
                PRIMITIVE_LL_L_Const_1_fun(LargeInt::mod);
              case ModLargeInt_Const_2:
                PRIMITIVE_LL_L_Const_2_fun(LargeInt::mod);
              case ModWord: PRIMITIVE_WW_W_fun(modWord);
              case ModWord_Const_1: PRIMITIVE_WW_W_Const_1_fun(modWord);
              case ModWord_Const_2: PRIMITIVE_WW_W_Const_2_fun(modWord);
              case ModByte: PRIMITIVE_BB_B_fun(modByte);
              case ModByte_Const_1: PRIMITIVE_BB_B_Const_1_fun(modByte);
              case ModByte_Const_2: PRIMITIVE_BB_B_Const_2_fun(modByte);
              case QuotInt: PRIMITIVE_II_I_fun(quotInt);
              case QuotInt_Const_1: PRIMITIVE_II_I_Const_1_fun(quotInt);
              case QuotInt_Const_2: PRIMITIVE_II_I_Const_2_fun(quotInt);
              case QuotLargeInt: PRIMITIVE_LL_L_fun(LargeInt::quot);
              case QuotLargeInt_Const_1:
                PRIMITIVE_LL_L_Const_1_fun(LargeInt::quot);
              case QuotLargeInt_Const_2:
                PRIMITIVE_LL_L_Const_2_fun(LargeInt::quot);
              case RemInt: PRIMITIVE_II_I_fun(remInt);
              case RemInt_Const_1: PRIMITIVE_II_I_Const_1_fun(remInt);
              case RemInt_Const_2: PRIMITIVE_II_I_Const_2_fun(remInt);
              case RemLargeInt: PRIMITIVE_LL_L_fun(LargeInt::rem);
              case RemLargeInt_Const_1:
                PRIMITIVE_LL_L_Const_1_fun(LargeInt::rem);
              case RemLargeInt_Const_2:
                PRIMITIVE_LL_L_Const_2_fun(LargeInt::rem);
              case NegInt: PRIMITIVE_I_I_op(-);
              case NegLargeInt: PRIMITIVE_L_L_fun(LargeInt::neg);
              case NegReal: PRIMITIVE_R_R_op(-);
              case NegFloat: PRIMITIVE_F_F_op(-);
              case AbsInt: PRIMITIVE_I_I_op(ABS_SINT32);
              case AbsLargeInt: PRIMITIVE_L_L_fun(LargeInt::abs);
              case AbsReal: PRIMITIVE_R_R_op(ABS_REAL64);
              case AbsFloat: PRIMITIVE_F_F_op(ABS_REAL32);
              case LtInt: PRIMITIVE_II_T_op(<);
              case LtInt_Const_1: PRIMITIVE_II_T_Const_1_op(<);
              case LtInt_Const_2: PRIMITIVE_II_T_Const_2_op(<);
              case LtLargeInt: PRIMITIVE_LL_T_fun(LargeInt::lt);
              case LtLargeInt_Const_1:
                PRIMITIVE_LL_T_Const_1_fun(LargeInt::lt);
              case LtLargeInt_Const_2:
                PRIMITIVE_LL_T_Const_2_fun(LargeInt::lt);
              case LtReal: PRIMITIVE_RR_T_op(<);
              case LtReal_Const_1: PRIMITIVE_RR_T_Const_1_op(<);
              case LtReal_Const_2: PRIMITIVE_RR_T_Const_2_op(<);
              case LtFloat: PRIMITIVE_FF_T_op(<);
              case LtFloat_Const_1: PRIMITIVE_FF_T_Const_1_op(<);
              case LtFloat_Const_2: PRIMITIVE_FF_T_Const_2_op(<);
              case LtWord: PRIMITIVE_WW_T_op(<);
              case LtWord_Const_1: PRIMITIVE_WW_T_Const_1_op(<);
              case LtWord_Const_2: PRIMITIVE_WW_T_Const_2_op(<);
              case LtByte: PRIMITIVE_WW_T_op(<);
              case LtByte_Const_1: PRIMITIVE_WW_T_Const_1_op(<);
              case LtByte_Const_2: PRIMITIVE_WW_T_Const_2_op(<);
              case LtChar: PRIMITIVE_WW_T_op(<);
              case LtChar_Const_1: PRIMITIVE_WW_T_Const_1_op(<);
              case LtChar_Const_2: PRIMITIVE_WW_T_Const_2_op(<);
              case LtString: PRIMITIVE_COMPARE_SS_T_op(< 0);
              case GtInt: PRIMITIVE_II_T_op(>);
              case GtInt_Const_1: PRIMITIVE_II_T_Const_1_op(>);
              case GtInt_Const_2: PRIMITIVE_II_T_Const_2_op(>);
              case GtLargeInt: PRIMITIVE_LL_T_fun(LargeInt::gt);
              case GtLargeInt_Const_1:
                PRIMITIVE_LL_T_Const_1_fun(LargeInt::gt);
              case GtLargeInt_Const_2:
                PRIMITIVE_LL_T_Const_2_fun(LargeInt::gt);
              case GtReal: PRIMITIVE_RR_T_op(>);
              case GtReal_Const_1: PRIMITIVE_RR_T_Const_1_op(>);
              case GtReal_Const_2: PRIMITIVE_RR_T_Const_2_op(>);
              case GtFloat: PRIMITIVE_FF_T_op(>);
              case GtFloat_Const_1: PRIMITIVE_FF_T_Const_1_op(>);
              case GtFloat_Const_2: PRIMITIVE_FF_T_Const_2_op(>);
              case GtWord: PRIMITIVE_WW_T_op(>);
              case GtWord_Const_1: PRIMITIVE_WW_T_Const_1_op(>);
              case GtWord_Const_2: PRIMITIVE_WW_T_Const_2_op(>);
              case GtByte: PRIMITIVE_WW_T_op(>);
              case GtByte_Const_1: PRIMITIVE_WW_T_Const_1_op(>);
              case GtByte_Const_2: PRIMITIVE_WW_T_Const_2_op(>);
              case GtChar: PRIMITIVE_WW_T_op(>);
              case GtChar_Const_1: PRIMITIVE_WW_T_Const_1_op(>);
              case GtChar_Const_2: PRIMITIVE_WW_T_Const_2_op(>);
              case GtString: PRIMITIVE_COMPARE_SS_T_op(> 0);
              case LteqInt: PRIMITIVE_II_T_op(<=);
              case LteqInt_Const_1: PRIMITIVE_II_T_Const_1_op(<=);
              case LteqInt_Const_2: PRIMITIVE_II_T_Const_2_op(<=);
              case LteqLargeInt: PRIMITIVE_LL_T_fun(LargeInt::lteq);
              case LteqLargeInt_Const_1:
                PRIMITIVE_LL_T_Const_1_fun(LargeInt::lteq);
              case LteqLargeInt_Const_2:
                PRIMITIVE_LL_T_Const_2_fun(LargeInt::lteq);
              case LteqReal: PRIMITIVE_RR_T_op(<=);
              case LteqReal_Const_1: PRIMITIVE_RR_T_Const_1_op(<=);
              case LteqReal_Const_2: PRIMITIVE_RR_T_Const_2_op(<=);
              case LteqFloat: PRIMITIVE_FF_T_op(<=);
              case LteqFloat_Const_1: PRIMITIVE_FF_T_Const_1_op(<=);
              case LteqFloat_Const_2: PRIMITIVE_FF_T_Const_2_op(<=);
              case LteqWord: PRIMITIVE_WW_T_op(<=);
              case LteqWord_Const_1: PRIMITIVE_WW_T_Const_1_op(<=);
              case LteqWord_Const_2: PRIMITIVE_WW_T_Const_2_op(<=);
              case LteqByte: PRIMITIVE_WW_T_op(<=);
              case LteqByte_Const_1: PRIMITIVE_WW_T_Const_1_op(<=);
              case LteqByte_Const_2: PRIMITIVE_WW_T_Const_2_op(<=);
              case LteqChar: PRIMITIVE_WW_T_op(<=);
              case LteqChar_Const_1: PRIMITIVE_WW_T_Const_1_op(<=);
              case LteqChar_Const_2: PRIMITIVE_WW_T_Const_2_op(<=);
              case LteqString: PRIMITIVE_COMPARE_SS_T_op(<= 0);
              case GteqInt: PRIMITIVE_II_T_op(>=);
              case GteqInt_Const_1: PRIMITIVE_II_T_Const_1_op(>=);
              case GteqInt_Const_2: PRIMITIVE_II_T_Const_2_op(>=);
              case GteqLargeInt: PRIMITIVE_LL_T_fun(LargeInt::gteq);
              case GteqLargeInt_Const_1:
                PRIMITIVE_LL_T_Const_1_fun(LargeInt::gteq);
              case GteqLargeInt_Const_2:
                PRIMITIVE_LL_T_Const_2_fun(LargeInt::gteq);
              case GteqReal: PRIMITIVE_RR_T_op(>=);
              case GteqReal_Const_1: PRIMITIVE_RR_T_Const_1_op(>=);
              case GteqReal_Const_2: PRIMITIVE_RR_T_Const_2_op(>=);
              case GteqFloat: PRIMITIVE_FF_T_op(>=);
              case GteqFloat_Const_1: PRIMITIVE_FF_T_Const_1_op(>=);
              case GteqFloat_Const_2: PRIMITIVE_FF_T_Const_2_op(>=);
              case GteqWord: PRIMITIVE_WW_T_op(>=);
              case GteqWord_Const_1: PRIMITIVE_WW_T_Const_1_op(>=);
              case GteqWord_Const_2: PRIMITIVE_WW_T_Const_2_op(>=);
              case GteqByte: PRIMITIVE_WW_T_op(>=);
              case GteqByte_Const_1: PRIMITIVE_WW_T_Const_1_op(>=);
              case GteqByte_Const_2: PRIMITIVE_WW_T_Const_2_op(>=);
              case GteqChar: PRIMITIVE_WW_T_op(>=);
              case GteqChar_Const_1: PRIMITIVE_WW_T_Const_1_op(>=);
              case GteqChar_Const_2: PRIMITIVE_WW_T_Const_2_op(>=);
              case GteqString: PRIMITIVE_COMPARE_SS_T_op(>= 0);
              case Byte_toIntX: PRIMITIVE_W_W_fun(byteToIntX);
              case Byte_fromInt: PRIMITIVE_W_W_fun(intToByte);
              case Word_toIntX: PRIMITIVE_W_W_op(+);// argument unchanged
              case Word_fromInt: PRIMITIVE_W_W_op(+);// argument unchanged
              case Word_andb: PRIMITIVE_WW_W_op(&);
              case Word_andb_Const_1: PRIMITIVE_WW_W_Const_1_op(&);
              case Word_andb_Const_2: PRIMITIVE_WW_W_Const_2_op(&);
              case Word_orb: PRIMITIVE_WW_W_op(|);
              case Word_orb_Const_1: PRIMITIVE_WW_W_Const_1_op(|);
              case Word_orb_Const_2: PRIMITIVE_WW_W_Const_2_op(|);
              case Word_xorb: PRIMITIVE_WW_W_op(^);
              case Word_xorb_Const_1: PRIMITIVE_WW_W_Const_1_op(^);
              case Word_xorb_Const_2: PRIMITIVE_WW_W_Const_2_op(^);
              case Word_notb: PRIMITIVE_W_W_op(~);
              case Word_leftShift: PRIMITIVE_WW_W_fun(leftShift);
              case Word_leftShift_Const_1:
                PRIMITIVE_WW_W_Const_1_fun(leftShift);
              case Word_leftShift_Const_2:
                PRIMITIVE_WW_W_Const_2_fun(leftShift);
              case Word_logicalRightShift:
                PRIMITIVE_WW_W_fun(logicalRightShift);
              case Word_logicalRightShift_Const_1:
                PRIMITIVE_WW_W_Const_1_fun(logicalRightShift);
              case Word_logicalRightShift_Const_2:
                PRIMITIVE_WW_W_Const_2_fun(logicalRightShift);
              case Word_arithmeticRightShift:
                PRIMITIVE_WW_W_fun(arithmeticRightShift);
              case Word_arithmeticRightShift_Const_1:
                PRIMITIVE_WW_W_Const_1_fun(arithmeticRightShift);
              case Word_arithmeticRightShift_Const_2:
                PRIMITIVE_WW_W_Const_2_fun(arithmeticRightShift);

              case Array_length:
                {
                    UInt32Value blockIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    ASSERT(FrameStack::isPointerSlot(SP, blockIndex));
                    Cell* block = FRAME_ENTRY(SP, blockIndex).blockRef;
                    ASSERT(Heap::isValidBlockPointer(block));

                    int length = PrimitiveSupport::getArrayLength(block);

                    FRAME_ENTRY(SP, destination).sint32 = length;
                    break;
                }
              case CurrentIP: 
                {
                    UInt32Value argIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    Executable* currentExecutable =
                    FrameStack::getExecutableOfFrame(SP);

                    /*  constructs a 2-tuple consisting of a pointer to the
                     * executable and the offset of the current instruction
                     * from the beginning of the code block.
                     */
                    Cell elements[2];
                    elements[0].uint32 = (UInt32Value)currentExecutable;
                    // adjust by 3 (= words of operands).
                    elements[1].uint32 =
                    PC - (UInt32Value*)(currentExecutable->code_) - 3;

                    SAVE_REGISTERS;
                    Cell tuple =
                      PrimitiveSupport::tupleElementsToCell(0, elements, 2);
                    RESTORE_REGISTERS;

                    FRAME_ENTRY(SP, destination) = tuple;
                    break;
                }

              case StackTrace:
                {
                    UInt32Value argIndex = getWordAndInc(PC);
                    UInt32Value destination = getWordAndInc(PC);

                    /* excludes the initial frame which does not have return
                     * address. */
                    int frames = FrameStack::getFramesCount(SP) - 1;
                    Cell* array;
                    ALLOCATE_POINTERARRAY(array, frames, true);
                    FRAME_ENTRY(SP, destination).blockRef = array;
                    DBGWRAP(LOG.debug("frames=%d", frames));
                    
                    UInt32Value *cursorSP = SP;
                    for(int index = 0; index < frames; index += 1)
                    {
                        DBGWRAP(LOG.debug("index=%d", index));
                        /*  get the instruction offset and the Executable of
                         * the call instruction which created the current
                         * frame. The offset of the call instruction is stored
                         * in the current (= callee) frame. The Executable is
                         * obtained in the upper (= caller) frame.
                         */
                        UInt32Value* returnAddress =
                        FrameStack::getReturnAddress(cursorSP);
                        ASSERT(RETURN_ADDRESS_OF_INITIAL_FRAME
                               != returnAddress);

                        cursorSP = FrameStack::getNextFrame(cursorSP);
                        ASSERT(cursorSP);

                        Executable* callerExecutable =
                        FrameStack::getExecutableOfFrame(cursorSP);

                        Cell elements[2];
                        elements[0].uint32 = (UInt32Value)callerExecutable;
                        elements[1].uint32 =
                        returnAddress - callerExecutable->code_;

                        SAVE_REGISTERS;
                        Cell tuple =
                        PrimitiveSupport::tupleElementsToCell(0, elements, 2);
                        Heap::initializeField(array, index, tuple);
                        RESTORE_REGISTERS;
                    }

                    break;
                }

              default:
                // ToDo : IllegalInstructionException ?
                DBGWRAP(LOG.error("invalid opcode::IllegalArgumentException"));
                throw IllegalArgumentException();
            }
            INVOKE_ON_MONITORS(afterInstruction(PC, previousPC, ENV, SP));
        }
      EXIT_LOOP:
        resetSignalHandler();
        INVOKE_ON_MONITORS(afterExecution(PC, ENV, SP));
    }
    catch(IMLException &exception)
    {
        DBGWRAP(LOG.debug("IMLException at instruction = %s",
                          instructionToString
                          (static_cast<instruction>
                           (*previousPC)));)

        interrupted_ = false;

        const char* what = exception.what();
        PrimitiveSupport::writeToSTDOUT(strlen(what), what);
        PrimitiveSupport::writeToSTDOUT(strlen("\n"), "\n");

        printStackTrace(PC, SP);

        resetSignalHandler();
        INVOKE_ON_MONITORS(afterExecution(PC, ENV, SP));
        DBGWRAP(LOG.debug("VM.executeLoop: throw uncaught IMLException.");)

	SP_ = SP;
        throw;
    }
    catch(...) {
        DBGWRAP(LOG.debug("exception at instruction = %s",
                          instructionToString
                          (static_cast<instruction>
                           (*previousPC)));)

	SP_ = SP;
        throw;
    }
    SP_ = SP;
}

void
VirtualMachine::signalHandler(int signal)
{
    //DBGWRAP(LOG.debug("SIGNAL caught: %d", signal));
    switch(signal){
      case SIGINT:
        interrupted_ = true;
        break;
      case SIGFPE:
        longjmp(onSIGFPE_jmp_buf, signal);
        break;// never reach here
#if defined(SIGPIPE)
      case SIGPIPE:// ignore
        break;
#endif
      default:
        ASSERT(false);
    }
}

void
VirtualMachine::setSignalHandler()
{
    /* Note : It is better to use sigaction, not signal.
     *        But MinGW does not provide sigaction.
     */
    prevSIGINTHandler_ = signal(SIGINT, &signalHandler);
    prevSIGFPEHandler_ = signal(SIGFPE, &signalHandler);
#if defined(SIGPIPE)
    prevSIGPIPEHandler_ = signal(SIGPIPE, &signalHandler);
#endif
}

void
VirtualMachine::resetSignalHandler()
{
    signal(SIGINT, prevSIGINTHandler_);
    signal(SIGFPE, prevSIGFPEHandler_);
#if defined(SIGPIPE)
    signal(SIGPIPE, prevSIGPIPEHandler_);
#endif
}

void
VirtualMachine::trace(RootTracer* tracer)
    throw(IMLException)
{
    // walk through stack frames
    FrameStack::trace(tracer, SP_);

    // global arrays
    // some elements in globalArrays might hold NULL pointer.
    for(BlockPointerVector::iterator i = globalArrays_.begin();
        i != globalArrays_.end();
        i++)
    {
        if(*i){ *i = tracer->trace(*i); }
    }

    ASSERT(0 < temporaryPointers_.size());
    for(BlockPointerRefList::iterator i = temporaryPointers_.begin();
        i != temporaryPointers_.end();
        i++)
    {
        **i = tracer->trace(**i);
    }

    if(isPrimitiveExceptionRaised_){
        primitiveException_.blockRef =
            tracer->trace(primitiveException_.blockRef);
    }

    FFI::instance().trace(tracer);
}

void
VirtualMachine::executeFinalizer(Cell* finalizable)
        throw(IMLException)
{
    /* A finalizable has a type of
     * 'a ref * ('a ref -> unit) ref
     */
    ASSERT(2 == Heap::getPayloadSize(finalizable));
    ASSERT(FINALIZABLE_BITMAP == Heap::getBitmap(finalizable));
    Cell elements[2];
    PrimitiveSupport::blockToTupleElements(finalizable, elements, 2);

    Cell* arg = elements[0].blockRef;// 'a ref
    ASSERT(Heap::isValidBlockPointer(arg));

    Cell* closureRef = elements[1].blockRef;// 'a ref -> unit
    Cell closure = closureRef[0];
    ASSERT(Heap::isValidBlockPointer(closure.blockRef));
    ASSERT(CLOSURE_FIELDS_COUNT == Heap::getPayloadSize(closure.blockRef));
    ASSERT(CLOSURE_BITMAP == Heap::getBitmap(closure.blockRef));

    DBGWRAP(LOG.debug("begin finalizer."));
    /* save all registers. not necessary ? */
    UInt32Value* originalSP = SP_;
    /* execute finalizer */
    UInt32Value result = executeClosure_PA(Ignore, closure, arg);

    SP_ = originalSP;
    DBGWRAP(LOG.debug("finalizer returned."));
}

void* VirtualMachine::importSymbol(const char* symbol)
{
    ImportSymbolMap::iterator i = importSymbolMap_.find(symbol);
    if(i == importSymbolMap_.end()){
        return NULL;
    }
    return i->second;
}

void VirtualMachine::addImportedSymbol(const char* symbol, void* fptr)
{
    importSymbolMap_[symbol] = fptr;
}

void VirtualMachine::exportSymbol(const char* symbol, void* fptr)
{
    exportSymbolMap_[symbol] = fptr;
}

void* VirtualMachine::findExportedSymbol(const char* symbol)
{
    ExportSymbolMap::iterator i = exportSymbolMap_.find(symbol);
    if(i == exportSymbolMap_.end()){
        return NULL;
    }
    return i->second;
}

///////////////////////////////////////////////////////////////////////////////

    DBGWRAP(LogAdaptor VirtualMachine::LOG =
            LogAdaptor("VirtualMachine"));

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
