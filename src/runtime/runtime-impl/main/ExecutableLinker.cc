/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: ExecutableLinker.cc,v 1.44 2006/02/25 02:39:50 kiyoshiy Exp $
 */
#include "ExecutableLinker.hh"
#include "Instructions.hh"
#include "SystemError.hh"
#include "IMLRuntimeException.hh"
#include "IllegalArgumentException.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

INLINE_FUN
void
ExecutableLinker::convertOffsetToAddress(UInt32Value* base, UInt32Value* PC)
{
    *PC = (UInt32Value)(base + getQuadByte(PC));
}

#define ASSERT_INSTRUCTION(opcode, address) \
ASSERT((opcode) == *((UInt32Value*)address))

static const UInt32Value SIZE_OF_LOCATION_TABLE_ENTRY = 6;
static const UInt32Value SIZE_OF_NAMESLOT_TABLE_ENTRY = 4;

///////////////////////////////////////////////////////////////////////////////

void
ExecutableLinker::process(Executable* executable)
    throw(IMLRuntimeException,
          SystemError)
{
    switch(executable->byteOrder_){
      case Executable::LittleEndian:
        {
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
            link<
            ExecutableLinker::nullFunctionWithIndex,
            ExecutableLinker::nullFunction,
            ExecutableLinker::nullFunction,
            ExecutableLinker::nullFunction
            >(executable);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
            link<
            WordOperations::reverseDoubleByte,
            WordOperations::reverseTriByte,
            WordOperations::reverseQuadByte,
            WordOperations::reverseDoubleQuadByte
            >(executable);
#endif
            break;
        }
      case Executable::BigEndian:
        {
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
            link<
            WordOperations::reverseDoubleByte,
            WordOperations::reverseTriByte,
            WordOperations::reverseQuadByte,
            WordOperations::reverseDoubleQuadByte
            >(executable);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
            link<
            ExecutableLinker::nullFunctionWithIndex,
            ExecutableLinker::nullFunction,
            ExecutableLinker::nullFunction,
            ExecutableLinker::nullFunction
            >(executable);
#endif
        }
    }
    executable->byteOrder_ = NATIVE_BYTE_ORDER;
}

template
 <
 void toNativeOrderDouble(UInt32Value*, int),
 void toNativeOrderTri(UInt32Value*),
 void toNativeOrderQuad(UInt32Value*),
 void toNativeOrderDoubleQuad(UInt32Value*)
 >
void
ExecutableLinker::link(Executable *executable)
    throw(IMLRuntimeException,
          SystemError)
{
    toNativeOrderQuad(executable->buffer_);
    executable->codeWordLength_ = *(executable->buffer_);
    executable->code_ = executable->buffer_ + 1;

    UInt32Value* code = executable->code_;
    UInt32Value* PC = code;

    while(PC - code < executable->codeWordLength_)
    {
/*
        DBGWRAP(fprintf(stderr,
                        "%d %s\n",
                        PC - code,
                        instructionToString((instruction)*PC)));
*/
        switch(static_cast<instruction>(*PC))
        {

          case LoadInt:
          case LoadWord:
          case LoadChar:
            {
                PC += 1;
                toNativeOrderQuad(PC); // value
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case LoadString:
            {
                PC += 1;
                toNativeOrderQuad(PC); // string
                convertOffsetToAddress(code, PC); // address of ConstString
                ASSERT_INSTRUCTION(ConstString, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case LoadReal:
          case LoadBoxedReal:
            {
                PC += 1;
                toNativeOrderDoubleQuad(PC); // value
                PC += 2;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case LoadEmptyBlock:
            {
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Access_S:
          case Access_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // variableOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Access_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // variableOffset
                PC += 1;
                toNativeOrderQuad(PC); // variableSize
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case AccessEnv_S:
          case AccessEnv_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // offset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case AccessEnv_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // offset
                PC += 1;
                toNativeOrderQuad(PC); // variableSize
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case AccessEnvIndirect_S:
          case AccessEnvIndirect_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // offset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case AccessEnvIndirect_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // offset
                PC += 1;
                toNativeOrderQuad(PC); // variableSize
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case AccessNestedEnv_S:
          case AccessNestedEnv_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevel
                PC += 1;
                toNativeOrderQuad(PC); // offset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case AccessNestedEnv_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevel
                PC += 1;
                toNativeOrderQuad(PC); // offset
                PC += 1;
                toNativeOrderQuad(PC); // variableSize
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case AccessNestedEnvIndirect_S:
          case AccessNestedEnvIndirect_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevel
                PC += 1;
                toNativeOrderQuad(PC); // offset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case AccessNestedEnvIndirect_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevel
                PC += 1;
                toNativeOrderQuad(PC); // offset
                PC += 1;
                toNativeOrderQuad(PC); // variableSize
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case GetField_S:
          case GetField_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffset
                PC += 1;
                toNativeOrderQuad(PC); // blockOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case GetField_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffset
                PC += 1;
                toNativeOrderQuad(PC); // fieldSize
                PC += 1;
                toNativeOrderQuad(PC); // blockOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case GetFieldIndirect_S:
          case GetFieldIndirect_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // fieldVarOffset
                PC += 1;
                toNativeOrderQuad(PC); // blockOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case GetFieldIndirect_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // fieldVarOffset
                PC += 1;
                toNativeOrderQuad(PC); // fieldSize
                PC += 1;
                toNativeOrderQuad(PC); // blockOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case GetNestedFieldIndirect_S:
          case GetNestedFieldIndirect_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevel
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffset
                PC += 1;
                toNativeOrderQuad(PC); // blockOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case GetNestedFieldIndirect_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevel
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffset
                PC += 1;
                toNativeOrderQuad(PC); // fieldSize
                PC += 1;
                toNativeOrderQuad(PC); // blockOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case SetField_S:
          case SetField_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffset
                PC += 1;
                toNativeOrderQuad(PC); // blockOfset
                PC += 1;
                toNativeOrderQuad(PC); // variableOffset
                PC += 1;
                break;
            }
          case SetField_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffset
                PC += 1;
                toNativeOrderQuad(PC); // fieldSize
                PC += 1;
                toNativeOrderQuad(PC); // blockOfset
                PC += 1;
                toNativeOrderQuad(PC); // variableOffset
                PC += 1;
                break;
            }
          case SetFieldIndirect_S:
          case SetFieldIndirect_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // fieldVarOffset
                PC += 1;
                toNativeOrderQuad(PC); // blockOffset
                PC += 1;
                toNativeOrderQuad(PC); // variableOffset
                PC += 1;
                break;
            }
          case SetFieldIndirect_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // fieldVarOffset
                PC += 1;
                toNativeOrderQuad(PC); // fieldSize
                PC += 1;
                toNativeOrderQuad(PC); // blockOffset
                PC += 1;
                toNativeOrderQuad(PC); // variableOffset
                PC += 1;
                break;
            }
          case SetNestedFieldIndirect_S:
          case SetNestedFieldIndirect_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevel
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffset
                PC += 1;
                toNativeOrderQuad(PC); // blockOfset
                PC += 1;
                toNativeOrderQuad(PC); // variableOffset
                PC += 1;
                break;
            }
          case SetNestedFieldIndirect_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevel
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffset
                PC += 1;
                toNativeOrderQuad(PC); // fieldSize
                PC += 1;
                toNativeOrderQuad(PC); // blockOfset
                PC += 1;
                toNativeOrderQuad(PC); // variableOffset
                PC += 1;
                break;
            }
          case CopyBlock:
            {
                PC += 1;
                toNativeOrderQuad(PC); // blockOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case GetGlobal_S:
            {
                PC += 1;
                toNativeOrderQuad(PC); // globalArrayIndex
                PC += 1;
                toNativeOrderQuad(PC); // Offset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case GetGlobal_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // globalArrayIndex
                PC += 1;
                toNativeOrderQuad(PC); // Offset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case SetGlobal_S:
            {
                PC += 1;
                toNativeOrderQuad(PC); // globalArrayIndex
                PC += 1;
                toNativeOrderQuad(PC); // globalOffset
                PC += 1;
                toNativeOrderQuad(PC); // variableOffset
                PC += 1;
                break;
            }
          case SetGlobal_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // globalArrayIndex
                PC += 1;
                toNativeOrderQuad(PC); // globalOffset
                PC += 1;
                toNativeOrderQuad(PC); // variableOffset
                PC += 1;
                break;
            }
          case InitGlobalArrayUnboxed:
            {
                PC += 1;
                toNativeOrderQuad(PC); // globalArrayIndex
                PC += 1;
                toNativeOrderQuad(PC); // arraySize
                PC += 1;
                break;
            }
          case InitGlobalArrayBoxed:
            {
                PC += 1;
                toNativeOrderQuad(PC); // globalArrayIndex
                PC += 1;
                toNativeOrderQuad(PC); // arraySize
                PC += 1;
                break;
            }
          case InitGlobalArrayDouble:
            {
                PC += 1;
                toNativeOrderQuad(PC); // globalArrayIndex
                PC += 1;
                toNativeOrderQuad(PC); // arraySize
                PC += 1;
                break;
            }
          case GetEnv:
            {
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case CallPrim:
            {
                PC += 1;
                toNativeOrderQuad(PC); // primitiveIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffset
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Apply_S:
          case Apply_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureOffset
                PC += 1;
                toNativeOrderQuad(PC); // argOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Apply_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureOffset
                PC += 1;
                toNativeOrderQuad(PC); // argOffset
                PC += 1;
                toNativeOrderQuad(PC); // argSizeOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Apply_ML_S:
          case Apply_ML_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureOffset
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffsets
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Apply_ML_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureOffset
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffsets
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSizeOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Apply_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureOffset
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffsets
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeOffsets
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case TailApply_S:
          case TailApply_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureOffset
                PC += 1;
                toNativeOrderQuad(PC); // argOffset
                PC += 1;
                break;
            }
          case TailApply_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureOffset
                PC += 1;
                toNativeOrderQuad(PC); // argOffset
                PC += 1;
                toNativeOrderQuad(PC); // argSizeOffset
                PC += 1;
                break;
            }
          case TailApply_ML_S:
          case TailApply_ML_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureOffset
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffsets
                    PC += 1;
                }
                break;
            }
          case TailApply_ML_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureOffset
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffsets
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSizeOffset
                PC += 1;
                break;
            }
          case TailApply_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureOffset
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffsets
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeOffsets
                    PC += 1;
                }
                break;
            }
          case CallStatic_S:
          case CallStatic_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // envOffset
                PC += 1;
                toNativeOrderQuad(PC); // argOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case CallStatic_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // envOffset
                PC += 1;
                toNativeOrderQuad(PC); // argOffset
                PC += 1;
                toNativeOrderQuad(PC); // argSizeOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case CallStatic_ML_S:
          case CallStatic_ML_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // envOffset
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffset
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case CallStatic_ML_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // envOffset
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffset
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSizeOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case CallStatic_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // envOffset
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffset
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeOffset
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case TailCallStatic_S:
          case TailCallStatic_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // envOffset
                PC += 1;
                toNativeOrderQuad(PC); // argOffset
                PC += 1;
                break;
            }
          case TailCallStatic_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // envOffset
                PC += 1;
                toNativeOrderQuad(PC); // argOffset
                PC += 1;
                toNativeOrderQuad(PC); // argSizeOffset
                PC += 1;
                break;
            }
          case TailCallStatic_ML_S:
          case TailCallStatic_ML_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // envOffset
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffset
                    PC += 1;
                }
                break;
            }
          case TailCallStatic_ML_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // envOffset
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffset
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSizeOffset
                PC += 1;
                break;
            }
          case TailCallStatic_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // envOffset
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffset
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeOffset
                    PC += 1;
                }
                break;
            }

          case RecursiveCallStatic_S:
          case RecursiveCallStatic_D:
          case SelfRecursiveCallStatic_S:
          case SelfRecursiveCallStatic_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // argOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case RecursiveCallStatic_V:
          case SelfRecursiveCallStatic_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // argOffset
                PC += 1;
                toNativeOrderQuad(PC); // argSizeOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case RecursiveCallStatic_M:
          case SelfRecursiveCallStatic_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffset
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeOffset
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case RecursiveTailCallStatic_S:
          case RecursiveTailCallStatic_D:
          case SelfRecursiveTailCallStatic_S:
          case SelfRecursiveTailCallStatic_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // argOffset
                PC += 1;
                break;
            }
          case RecursiveTailCallStatic_V:
          case SelfRecursiveTailCallStatic_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // argOffset
                PC += 1;
                toNativeOrderQuad(PC); // argSizeOffset
                PC += 1;
                break;
            }
          case RecursiveTailCallStatic_M:
          case SelfRecursiveTailCallStatic_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffset
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeOffset
                    PC += 1;
                }
                break;
            }

          case MakeBlock:
            {
                PC += 1;
                toNativeOrderQuad(PC); // bitmapOffset
                PC += 1;
                toNativeOrderQuad(PC); // sizeOffset
                PC += 1;
                toNativeOrderQuad(PC); // fieldsCount
                UInt32Value fieldsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < fieldsCount; index += 1){
                    toNativeOrderQuad(PC); // fieldOffset
                    PC += 1;
                }
                for(int index = 0; index < fieldsCount; index += 1){
                    toNativeOrderQuad(PC); // fieldSizeOffset
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case MakeBlockOfSingleValues:
            {
                PC += 1;
                toNativeOrderQuad(PC); // bitmapOffset
                PC += 1;
                toNativeOrderQuad(PC); // fieldsCount
                UInt32Value fieldsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < fieldsCount; index += 1){
                    toNativeOrderQuad(PC); // fieldOffset
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case MakeArray_S:
          case MakeArray_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // bitmapOffset
                PC += 1;
                toNativeOrderQuad(PC); // sizeOffset
                PC += 1;
                toNativeOrderQuad(PC); // initialValueOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case MakeArray_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // bitmapOffset
                PC += 1;
                toNativeOrderQuad(PC); // sizeOffset
                PC += 1;
                toNativeOrderQuad(PC); // initialValueOffset
                PC += 1;
                toNativeOrderQuad(PC); // initialValueSize
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case MakeClosure:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
//                ASSERT_INSTRUCTION(FunEntry, *PC);
                PC += 1;
                toNativeOrderQuad(PC); // ENVOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Raise:
            {
                PC += 1;
                toNativeOrderQuad(PC); // exceptionOffset
                PC += 1;
                break;
            }
          case PushHandler:
            {
                PC += 1;
                toNativeOrderQuad(PC); // handler
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // exceptionOffset
                PC += 1;
                break;
            }
          case PopHandler:
            {
                PC += 1;
                break;
            }
          case SwitchInt:
          case SwitchWord:
          case SwitchChar:
            {
                PC += 1;
                toNativeOrderQuad(PC); // targetOffset
                PC += 1;
                toNativeOrderQuad(PC); // casesCount
                UInt32Value casesCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < casesCount; index += 1){
                    toNativeOrderQuad(PC); // constant
                    PC += 1;
                    toNativeOrderQuad(PC); // destination
                    convertOffsetToAddress(code, PC);
                    PC += 1;
                }
                toNativeOrderQuad(PC); // defaultDestination
                convertOffsetToAddress(code, PC);
                PC += 1;
                break;
            }
          case SwitchString:
            {
                PC += 1;
                toNativeOrderQuad(PC); // targetOffset
                PC += 1;
                toNativeOrderQuad(PC); // casesCount
                UInt32Value casesCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < casesCount; index += 1){
                    toNativeOrderQuad(PC); // constant
                    convertOffsetToAddress(code, PC);// address of ConstString
                    ASSERT_INSTRUCTION(ConstString, *PC);
                    PC += 1;
                    toNativeOrderQuad(PC); // destination
                    convertOffsetToAddress(code, PC); // address of destination
                    PC += 1;
                }
                toNativeOrderQuad(PC); // defaultDestination
                convertOffsetToAddress(code, PC);
                PC += 1;
                break;
            }
          case Jump:
            {
                PC += 1;
                toNativeOrderQuad(PC); // destination
                convertOffsetToAddress(code, PC);
                PC += 1;
                break;
            }
          case Exit:
            {
                PC += 1;
                break;
            }
          case Return_S:
          case Return_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // variableOffset
                PC += 1;
                break;
            }
          case Return_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // variableOffset
                PC += 1;
                toNativeOrderQuad(PC); // variableSize
                PC += 1;
                break;
            }
          case FunEntry:
            {
                // replace opcode with a pointer to executable
                *PC = (UInt32Value)executable;
                PC += 1;
                toNativeOrderQuad(PC); // frameSize
                PC += 1;
                toNativeOrderQuad(PC); // startOffset
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // arity
                UInt32Value arity = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < arity; index += 1){
                    toNativeOrderQuad(PC); // argsDest
                    PC += 1;
                }
                toNativeOrderQuad(PC); // bitmapvalsArgsCount
                UInt32Value bitmapvalsArgsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < bitmapvalsArgsCount; index += 1){
                    toNativeOrderQuad(PC); // bitmapvalsArgs
                    PC += 1;
                }
                toNativeOrderQuad(PC); // bitmapvalsFreesCount
                UInt32Value bitmapvalsFreesCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < bitmapvalsFreesCount; index += 1){
                    toNativeOrderQuad(PC); // bitmapvalsFrees
                    PC += 1;
                }
                toNativeOrderQuad(PC); // pointers
                PC += 1;
                toNativeOrderQuad(PC); // atoms
                PC += 1;
                toNativeOrderQuad(PC); // recordGroupsCount
                UInt32Value recordGroupsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < recordGroupsCount; index += 1){
                    toNativeOrderQuad(PC); // recordGroups
                    PC += 1;
                }
                break;
            }
          case ConstString:
            {
                PC += 1;
                toNativeOrderQuad(PC); // length
                UInt32Value length = getQuadByte(PC);
                PC += 1;
                UInt32Value wordsLength =
                (length + sizeof(UInt32Value)) / sizeof(UInt32Value);
                PC += wordsLength;
                break;
            }
          case Nop:
            {
                PC += 1;
                break;
            }
          case FFIVal:
            {
                PC += 1;
                toNativeOrderQuad(PC); // funNameOffset
                PC += 1;
                toNativeOrderQuad(PC); // libNameOffset
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case ForeignApply:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureOffset
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argOffsets
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }

// 1 arg primitive
#define LINK_PRIM_1 \
            { \
                PC += 1; \
                toNativeOrderQuad(PC); /* argOffset */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* destination */ \
                PC += 1; \
                break; \
            }

// 2 args primitive
#define LINK_PRIM_2 \
            { \
                PC += 1; \
                toNativeOrderQuad(PC); /* argOffset1 */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* argOffset2 */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* destination */ \
                PC += 1; \
                break; \
            }

// 3 args primitive
#define LINK_PRIM_3 \
            { \
                PC += 1; \
                toNativeOrderQuad(PC); /* argOffset1 */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* argOffset2 */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* argOffset3 */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* destination */ \
                PC += 1; \
                break; \
            }

// 2 args primitive. Its 1st argument is single word constant.
#define LINK_PRIM_2_CONST_1S \
            { \
                PC += 1; \
                toNativeOrderQuad(PC); /* constant */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* argOffset */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* destination */ \
                PC += 1; \
                break; \
            }

// 2 args primitive. Its 2nd argument is single word constant.
#define LINK_PRIM_2_CONST_2S LINK_PRIM_2_CONST_1S

// 2 args primitive. Its 1st argument is double word constant.
#define LINK_PRIM_2_CONST_1D \
            { \
                PC += 1; \
                toNativeOrderDoubleQuad(PC); /* constant */ \
                PC += 2; \
                toNativeOrderQuad(PC); /* argOffset */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* destination */ \
                PC += 1; \
                break; \
            }
// 2 args primitive. Its 2nd argument is double word constant.
#define LINK_PRIM_2_CONST_2D \
            { \
                PC += 1; \
                toNativeOrderQuad(PC); /* argOffset */ \
                PC += 1; \
                toNativeOrderDoubleQuad(PC); /* constant */ \
                PC += 2; \
                toNativeOrderQuad(PC); /* destination */ \
                PC += 1; \
                break; \
            }

          case Equal: LINK_PRIM_2;
          case AddInt: LINK_PRIM_2;
          case AddInt_Const_1: LINK_PRIM_2_CONST_1S;
          case AddInt_Const_2: LINK_PRIM_2_CONST_2S;
          case AddReal: LINK_PRIM_2;
          case AddReal_Const_1: LINK_PRIM_2_CONST_1D;
          case AddReal_Const_2: LINK_PRIM_2_CONST_2D;
          case AddWord: LINK_PRIM_2;
          case AddWord_Const_1: LINK_PRIM_2_CONST_1S;
          case AddWord_Const_2: LINK_PRIM_2_CONST_2S;
          case AddByte: LINK_PRIM_2;
          case AddByte_Const_1: LINK_PRIM_2_CONST_1S;
          case AddByte_Const_2: LINK_PRIM_2_CONST_2S;
          case SubInt: LINK_PRIM_2;
          case SubInt_Const_1: LINK_PRIM_2_CONST_1S;
          case SubInt_Const_2: LINK_PRIM_2_CONST_2S;
          case SubReal: LINK_PRIM_2;
          case SubReal_Const_1: LINK_PRIM_2_CONST_1D;
          case SubReal_Const_2: LINK_PRIM_2_CONST_2D;
          case SubWord: LINK_PRIM_2;
          case SubWord_Const_1: LINK_PRIM_2_CONST_1S;
          case SubWord_Const_2: LINK_PRIM_2_CONST_2S;
          case SubByte: LINK_PRIM_2;
          case SubByte_Const_1: LINK_PRIM_2_CONST_1S;
          case SubByte_Const_2: LINK_PRIM_2_CONST_2S;
          case MulInt: LINK_PRIM_2;
          case MulInt_Const_1: LINK_PRIM_2_CONST_1S;
          case MulInt_Const_2: LINK_PRIM_2_CONST_2S;
          case MulReal: LINK_PRIM_2;
          case MulReal_Const_1: LINK_PRIM_2_CONST_1D;
          case MulReal_Const_2: LINK_PRIM_2_CONST_2D;
          case MulWord: LINK_PRIM_2;
          case MulWord_Const_1: LINK_PRIM_2_CONST_1S;
          case MulWord_Const_2: LINK_PRIM_2_CONST_2S;
          case MulByte: LINK_PRIM_2;
          case MulByte_Const_1: LINK_PRIM_2_CONST_1S;
          case MulByte_Const_2: LINK_PRIM_2_CONST_2S;
          case DivInt: LINK_PRIM_2;
          case DivInt_Const_1: LINK_PRIM_2_CONST_1S;
          case DivInt_Const_2: LINK_PRIM_2_CONST_2S;
          case DivWord: LINK_PRIM_2;
          case DivWord_Const_1: LINK_PRIM_2_CONST_1S;
          case DivWord_Const_2: LINK_PRIM_2_CONST_2S;
          case DivReal: LINK_PRIM_2;
          case DivReal_Const_1: LINK_PRIM_2_CONST_1D;
          case DivReal_Const_2: LINK_PRIM_2_CONST_2D;
          case DivByte: LINK_PRIM_2;
          case DivByte_Const_1: LINK_PRIM_2_CONST_1S;
          case DivByte_Const_2: LINK_PRIM_2_CONST_2S;
          case ModInt: LINK_PRIM_2;
          case ModInt_Const_1: LINK_PRIM_2_CONST_1S;
          case ModInt_Const_2: LINK_PRIM_2_CONST_2S;
          case ModWord: LINK_PRIM_2;
          case ModWord_Const_1: LINK_PRIM_2_CONST_1S;
          case ModWord_Const_2: LINK_PRIM_2_CONST_2S;
          case ModByte: LINK_PRIM_2;
          case ModByte_Const_1: LINK_PRIM_2_CONST_1S;
          case ModByte_Const_2: LINK_PRIM_2_CONST_2S;
          case QuotInt: LINK_PRIM_2;
          case QuotInt_Const_1: LINK_PRIM_2_CONST_1S;
          case QuotInt_Const_2: LINK_PRIM_2_CONST_2S;
          case RemInt: LINK_PRIM_2;
          case RemInt_Const_1: LINK_PRIM_2_CONST_1S;
          case RemInt_Const_2: LINK_PRIM_2_CONST_2S;
          case NegInt: LINK_PRIM_1;
          case NegReal: LINK_PRIM_1;
          case AbsInt: LINK_PRIM_1;
          case AbsReal: LINK_PRIM_1;
          case LtInt: LINK_PRIM_2;
          case LtReal: LINK_PRIM_2;
          case LtWord: LINK_PRIM_2;
          case LtByte: LINK_PRIM_2;
          case LtChar: LINK_PRIM_2;
          case LtString: LINK_PRIM_2;
          case GtInt: LINK_PRIM_2;
          case GtReal: LINK_PRIM_2;
          case GtWord: LINK_PRIM_2;
          case GtByte: LINK_PRIM_2;
          case GtChar: LINK_PRIM_2;
          case GtString: LINK_PRIM_2;
          case LteqInt: LINK_PRIM_2;
          case LteqReal: LINK_PRIM_2;
          case LteqWord: LINK_PRIM_2;
          case LteqByte: LINK_PRIM_2;
          case LteqChar: LINK_PRIM_2;
          case LteqString: LINK_PRIM_2;
          case GteqInt: LINK_PRIM_2;
          case GteqReal: LINK_PRIM_2;
          case GteqWord: LINK_PRIM_2;
          case GteqByte: LINK_PRIM_2;
          case GteqChar: LINK_PRIM_2;
          case GteqString: LINK_PRIM_2;
          case Word_toIntX: LINK_PRIM_1;
          case Word_fromInt: LINK_PRIM_1;
          case Word_andb: LINK_PRIM_2;
          case Word_andb_Const_1: LINK_PRIM_2_CONST_1S;
          case Word_andb_Const_2: LINK_PRIM_2_CONST_2S;
          case Word_orb: LINK_PRIM_2;
          case Word_orb_Const_1: LINK_PRIM_2_CONST_1S;
          case Word_orb_Const_2: LINK_PRIM_2_CONST_2S;
          case Word_xorb: LINK_PRIM_2;
          case Word_xorb_Const_1: LINK_PRIM_2_CONST_1S;
          case Word_xorb_Const_2: LINK_PRIM_2_CONST_2S;
          case Word_notb: LINK_PRIM_1;
          case Word_leftShift: LINK_PRIM_2;
          case Word_leftShift_Const_1: LINK_PRIM_2_CONST_1S;
          case Word_leftShift_Const_2: LINK_PRIM_2_CONST_2S;
          case Word_logicalRightShift: LINK_PRIM_2;
          case Word_logicalRightShift_Const_1: LINK_PRIM_2_CONST_1S;
          case Word_logicalRightShift_Const_2: LINK_PRIM_2_CONST_2S;
          case Word_arithmeticRightShift: LINK_PRIM_2;
          case Word_arithmeticRightShift_Const_1: LINK_PRIM_2_CONST_1S;
          case Word_arithmeticRightShift_Const_2: LINK_PRIM_2_CONST_2S;

          case Array_length: LINK_PRIM_1;
          case CurrentIP: LINK_PRIM_1;
          case StackTrace: LINK_PRIM_1;

          default:
            DBGWRAP
            (LOG.error("ExecutableLinker::link: unknown instruction"));
            // ToDo : IllegalInstructionException ?
            throw IllegalArgumentException();
        }
    }
    ASSERT((PC - code) == executable->codeWordLength_);

    /*****************************************
     * deserialize locationTable
     */

    toNativeOrderQuad(PC);
    UInt32Value locationTableWordLength = *PC;
/*
fprintf(stderr, "locationTableWordLength = %d\n", locationTableWordLength);
*/
    PC += 1;

    UInt32Value *locationTable = PC;

    toNativeOrderQuad(PC);
    executable->locationsCount_ = *PC;
/*
fprintf(stderr, "executable->locationsCount_ = %d\n", executable->locationsCount_);
*/
    PC += 1;

    UInt32Value locationsWordLength =
    executable->locationsCount_ * SIZE_OF_LOCATION_TABLE_ENTRY;

    executable->locations_ = PC;
    PC += locationsWordLength;

    toNativeOrderQuad(PC);
    executable->fileNamesCount_ = *PC;
/*
fprintf(stderr, "executable->fileNamesCount_ = %d\n", executable->fileNamesCount_);
*/
    PC += 1;

    executable->fileNames_ = (void**)PC;
    PC += executable->fileNamesCount_;

    void** fileNameStrings = (void**)PC;

    for(int index = 0; index < executable->fileNamesCount_; index += 1)
    {
        UInt32Value offset = (UInt32Value)(executable->fileNames_[index]);
        executable->fileNames_[index] = fileNameStrings + offset;
/*
        UInt32Value length = *(UInt32Value*)(fileNameStrings + offset);
        const char* string = (const char*)(fileNameStrings + offset + 1);
        fprintf(stderr, "length = %d, string = \"%s\"\n", length, string);
*/
    }

    PC = locationTable + locationTableWordLength;
/*
fprintf(stderr, "locationTable = %x, locationTableWordLength = %d, executable->totalWordLength_ = %d\n", locationTable, locationTableWordLength, executable->totalWordLength_);
*/

    /*****************************************
     * deserialize nameSlotTable
     */

    toNativeOrderQuad(PC);
    UInt32Value nameSlotTableWordLength = *PC;
/*
fprintf(stderr, "nameSlotTableWordLength = %d\n", nameSlotTableWordLength);
*/
    PC += 1;

    UInt32Value *nameSlotTable = PC;

    toNativeOrderQuad(PC);
    executable->nameSlotsCount_ = *PC;
/*
fprintf(stderr, "executable->nameSlotsCount_ = %d\n", executable->nameSlotsCount_);
*/
    PC += 1;

    UInt32Value nameSlotsWordLength =
    executable->nameSlotsCount_ * SIZE_OF_NAMESLOT_TABLE_ENTRY;

    executable->nameSlots_ = PC;
    PC += nameSlotsWordLength;

    toNativeOrderQuad(PC);
    executable->boundNamesCount_ = *PC;
/*
fprintf(stderr, "executable->boundNamesCount_ = %d\n", executable->boundNamesCount_);
*/
    PC += 1;

    executable->boundNames_ = (void**)PC;
    PC += executable->boundNamesCount_;

    void** boundNameStrings = (void**)PC;

    for(int index = 0; index < executable->boundNamesCount_; index += 1)
    {
        UInt32Value offset = (UInt32Value)(executable->boundNames_[index]);
        executable->boundNames_[index] = boundNameStrings + offset;

        UInt32Value length = *(UInt32Value*)(boundNameStrings + offset);
        const char* string = (const char*)(boundNameStrings + offset + 1);
/*
fprintf(stderr, "index = %d, offset = %d, length = %d, string = \"%s\"\n", index, offset, length, string);
*/
    }

    PC = nameSlotTable + nameSlotTableWordLength;
/*
fprintf(stderr, "nameSlotTable = %x, nameSlotTableWordLength = %d, executable->totalWordLength_ = %d\n", nameSlotTable, nameSlotTableWordLength, executable->totalWordLength_);
*/

    /****************************************/

    ASSERT(PC == executable->buffer_ + executable->totalWordLength_);
}

/*
 * ToDo : I am not certain whether this function should be defined here or
 *       in the Executable class.
 */
void 
ExecutableLinker::getLocationOfCodeRef(Executable* executable,
                                       UInt32Value offset,
                                       const char** fileName,
                                       UInt32Value* leftLine,
                                       UInt32Value* leftCol,
                                       UInt32Value* rightLine,
                                       UInt32Value* rightCol)
{
    UInt32Value* entry = 0;
    UInt32Value* next = executable->locations_;
    for(int index = 0; index < executable->locationsCount_; index += 1)
    {
        if(offset < *next){
            break;
        }
        entry = next;
        next += SIZE_OF_LOCATION_TABLE_ENTRY;
    }
    if(0 == entry){
        *fileName = "???";
        *leftLine = *leftCol = *rightLine = *rightCol = 0;
    }
    else{
        UInt32Value fileNameIndex = *(entry + 1);
        UInt32Value *fileNameAddress =
        (UInt32Value *)(executable->fileNames_[fileNameIndex]);
        *fileName = (const char*)(fileNameAddress + 1);
        *leftLine = *(entry + 2);
        *leftCol = *(entry + 3);
        *rightLine = *(entry + 4);
        *rightCol = *(entry + 5);
    }
    return;
}

///////////////////////////////////////////////////////////////////////////////

DBGWRAP(LogAdaptor ExecutableLinker::LOG = LogAdaptor("ExecutableLinker"));

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
