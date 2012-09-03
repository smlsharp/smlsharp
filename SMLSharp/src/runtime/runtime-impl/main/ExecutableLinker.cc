/**
 * @author YAMATODANI Kiyoshi
 * @version $Id: ExecutableLinker.cc,v 1.60 2007/12/19 02:00:56 kiyoshiy Exp $
 */
#include "Configuration.hh"
#include "ExecutableLinker.hh"
#include "Instructions.hh"
#include "LargeInt.hh"
#include "SystemError.hh"
#include "IMLRuntimeException.hh"
#include "IllegalArgumentException.hh"
#include "IncompatibleExecutableException.hh"
#include "MalformedExecutableException.hh"
#include "Primitives.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

typedef LargeInt::largeInt largeInt;

///////////////////////////////////////////////////////////////////////////////

//FIXME: Who use this?
static
UInt32Value tagToSize(UInt32Value tag){
  UInt32Value k = 0;
  UInt32Value allOne = 1;  
  while (tag != 0) {
    if (tag % 2 == 0){
	allOne = 0;
	}
  tag = tag / 2;
  k = k + 1; 
  }
  if (allOne == 1) {return k - 1;}
  else {return k - 2;}
}

INLINE_FUN
void
ExecutableLinker::convertOffsetToAddress(UInt32Value* base, UInt32Value* PC)
{
    *PC = (UInt32Value)(base + getQuadByte(PC));
}

#define ASSERT_INSTRUCTION(opcode, address) \
ASSERT((opcode) == *((UInt32Value*)address))

#undef ASSERT_INSTRUCTION
#define ASSERT_INSTRUCTION(opcode, address) \
do { UInt32Value op__ = *((UInt32Value*)address); \
     toNativeOrderQuad(&op__); \
     ASSERT((opcode) == op__) } while (0)

static const UInt32Value SIZE_OF_LOCATION_TABLE_ENTRY = 6;
static const UInt32Value SIZE_OF_NAMESLOT_TABLE_ENTRY = 4;

///////////////////////////////////////////////////////////////////////////////

void
ExecutableLinker::process(Executable* executable)
    throw(IMLException)
{
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
    // convert from network byte order.
    WordOperations::reverseQuadByte(executable->buffer_); // magic
    WordOperations::reverseQuadByte(executable->buffer_ + 1); // version
    WordOperations::reverseQuadByte(executable->buffer_ + 2); // byte order
#endif

    // check magic number.
    UInt32Value magic = *(executable->buffer_);
    if(EXECUTABLE_HEADER_MAGIC != magic){
        throw MalformedExecutableException();
    }

    // check binary version compatibility.
    UInt32Value version = *(executable->buffer_ + 1);
    UInt16Value minor = 0xFFFF & (version >> 16);
    UInt16Value major = 0xFFFF & version;
/*
    DBGWRAP(LOG.debug("version = %x, minor = %d, major = %d",
                      version, minor, major));
*/
    // ToDo : We should implement a version checker in another module.
    /* In future (after official release of 1.0), we should write
     * a version-checker which takes upper compatibility between versions
     * into consideration. */
    if((BinaryMinorVersion != minor) || (BinaryMajorVersion != major)){
        throw IncompatibleExecutableException();
    }

    UInt32Value byteOrder = *(executable->buffer_ + 2);

    switch(byteOrder){
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
    throw(IMLException)
{
    // executable->buffer_[0] = magic
    // executable->buffer_[1] = version
    // executable->buffer_[2] = byteOrder

    // executable->buffer_[3] = linkSymbolTableLength
    toNativeOrderQuad(executable->buffer_ + 3);
    UInt32Value symtabLength = executable->buffer_[3];
    const char *symtab = (char*)(executable->buffer_ + 4);

    // executable->buffer_[4+N] = codeWordLength
    toNativeOrderQuad(executable->buffer_ + 4 + symtabLength);
    executable->codeWordLength_ = *(executable->buffer_ + 4 + symtabLength);
    // executable->buffer_[5+N] = start of code
    executable->code_ = executable->buffer_ + 4 + symtabLength + 1;

    UInt32Value* code = executable->code_;
    UInt32Value* PC = code;

    while(PC - code < executable->codeWordLength_)
    {
        toNativeOrderQuad(PC);
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
          case LoadFloat:
            {
                PC += 1;
                toNativeOrderQuad(PC); // value
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case LoadLargeInt:
            {
                PC += 1;
                toNativeOrderQuad(PC); // string
                convertOffsetToAddress(code, PC); // address of ConstString
                ASSERT_INSTRUCTION(ConstString, *PC);
                // convert the string to a largeInt and replace operand.
                writeLargeInt(PC);
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
          case LoadAddress:
            {
                PC += 1;
                toNativeOrderQuad(PC); // address
                convertOffsetToAddress(code, PC); // address of an instruction
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Access_S:
          case Access_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // variableIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Access_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // variableIndex
                PC += 1;
                toNativeOrderQuad(PC); // variableSizeIndex
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
                toNativeOrderQuad(PC); // variableSizeIndex
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
                toNativeOrderQuad(PC); // variableSizeIndex
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
                toNativeOrderQuad(PC); // blockIndex
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
                toNativeOrderQuad(PC); // fieldSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // blockIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case GetFieldIndirect_S:
          case GetFieldIndirect_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffsetIndex
                PC += 1;
                toNativeOrderQuad(PC); // blockIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case GetFieldIndirect_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffsetIndex
                PC += 1;
                toNativeOrderQuad(PC); // fieldSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // blockIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case GetNestedField_S:
          case GetNestedField_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevel
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffset
                PC += 1;
                toNativeOrderQuad(PC); // blockIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case GetNestedField_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevel
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffset
                PC += 1;
                toNativeOrderQuad(PC); // fieldSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // blockIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case GetNestedFieldIndirect_S:
          case GetNestedFieldIndirect_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevelIndex
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffsetIndex
                PC += 1;
                toNativeOrderQuad(PC); // blockIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case GetNestedFieldIndirect_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevelIndex
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffsetIndex
                PC += 1;
                toNativeOrderQuad(PC); // fieldSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // blockIndex
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
                toNativeOrderQuad(PC); // blockIndex
                PC += 1;
                toNativeOrderQuad(PC); // newValueIndex
                PC += 1;
                break;
            }
          case SetField_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffset
                PC += 1;
                toNativeOrderQuad(PC); // fieldSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // blockIndex
                PC += 1;
                toNativeOrderQuad(PC); // newValueIndex
                PC += 1;
                break;
            }
          case SetFieldIndirect_S:
          case SetFieldIndirect_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffsetIndex
                PC += 1;
                toNativeOrderQuad(PC); // blockIndex
                PC += 1;
                toNativeOrderQuad(PC); // newValueIndex
                PC += 1;
                break;
            }
          case SetFieldIndirect_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffsetIndex
                PC += 1;
                toNativeOrderQuad(PC); // fieldSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // blockIndex
                PC += 1;
                toNativeOrderQuad(PC); // newValueIndex
                PC += 1;
                break;
            }
          case SetNestedField_S:
          case SetNestedField_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevel
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffset
                PC += 1;
                toNativeOrderQuad(PC); // blockIndex
                PC += 1;
                toNativeOrderQuad(PC); // newValueIndex
                PC += 1;
                break;
            }
          case SetNestedField_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevel
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffset
                PC += 1;
                toNativeOrderQuad(PC); // fieldSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // blockIndex
                PC += 1;
                toNativeOrderQuad(PC); // newValueIndex
                PC += 1;
                break;
            }
          case SetNestedFieldIndirect_S:
          case SetNestedFieldIndirect_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevelIndex
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffsetIndex
                PC += 1;
                toNativeOrderQuad(PC); // blockIndex
                PC += 1;
                toNativeOrderQuad(PC); // newValueIndex
                PC += 1;
                break;
            }
          case SetNestedFieldIndirect_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // nestLevelIndex
                PC += 1;
                toNativeOrderQuad(PC); // fieldOffsetIndex
                PC += 1;
                toNativeOrderQuad(PC); // fieldSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // blockIndex
                PC += 1;
                toNativeOrderQuad(PC); // newValueIndex
                PC += 1;
                break;
            }
          case CopyBlock:
            {
                PC += 1;
                toNativeOrderQuad(PC); // blockIndex
                PC += 1;
                toNativeOrderQuad(PC); // nestLevelIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case CopyArray_S:
          case CopyArray_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // srcIndex
                PC += 1;
                toNativeOrderQuad(PC); // srcOffsetIndex
                PC += 1;
                toNativeOrderQuad(PC); // dstIndex
                PC += 1;
                toNativeOrderQuad(PC); // dstOffsetIndex
                PC += 1;
                toNativeOrderQuad(PC); // lengthIndex
                PC += 1;
                break;
            }
          case CopyArray_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // srcIndex
                PC += 1;
                toNativeOrderQuad(PC); // srcOffsetIndex
                PC += 1;
                toNativeOrderQuad(PC); // dstIndex
                PC += 1;
                toNativeOrderQuad(PC); // dstOffsetIndex
                PC += 1;
                toNativeOrderQuad(PC); // lengthIndex
                PC += 1;
                toNativeOrderQuad(PC); // elementSizeIndex
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
                toNativeOrderQuad(PC); // variableIndex
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
                toNativeOrderQuad(PC); // variableIndex
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
                toNativeOrderQuad(PC); // primitiveSymbolNameIndex
		*PC = find_primitive_index(symtab + *PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Apply_0_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                break;
            }
          case Apply_S_0:
          case Apply_D_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                break;
            }
          case Apply_V_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // argSizeIndex
                PC += 1;
                break;
            }
          case Apply_MS_0:
          case Apply_MLD_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                break;
            }
          case Apply_MLV_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSize
                PC += 1;
                break;
            }
          case Apply_MF_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizes
                    PC += 1;
                }
                break;
            }
          case Apply_MV_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeIndexes
                    PC += 1;
                }
                break;
            }
          case Apply_0_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Apply_S_1:
          case Apply_D_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Apply_V_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // argSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Apply_MS_1:
          case Apply_MLD_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Apply_MLV_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSize
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Apply_MF_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Apply_MV_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Apply_0_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case Apply_S_M:
          case Apply_D_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case Apply_V_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // argSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case Apply_MS_M:
          case Apply_MLD_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case Apply_MLV_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSize
                PC += 1;
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case Apply_MF_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case Apply_MV_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case TailApply_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                break;
            }
          case TailApply_S:
          case TailApply_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                break;
            }
          case TailApply_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // argSizeIndex
                PC += 1;
                break;
            }
          case TailApply_MS:
          case TailApply_MLD:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                break;
            }
          case TailApply_MLV:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSizeIndex
                PC += 1;
                break;
            }
          case TailApply_MF:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizes
                    PC += 1;
                }
                break;
            }
          case TailApply_MV:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeIndexes
                    PC += 1;
                }
                break;
            }
          case CallStatic_0_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                break;
            }
          case CallStatic_S_0:
          case CallStatic_D_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                break;
            }
          case CallStatic_V_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // argSizeIndex
                PC += 1;
                break;
            }
          case CallStatic_MS_0:
          case CallStatic_MLD_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                break;
            }
          case CallStatic_MLV_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSizeIndex
                PC += 1;
                break;
            }
          case CallStatic_MF_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizes
                    PC += 1;
                }
                break;
            }
          case CallStatic_MV_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeIndexes
                    PC += 1;
                }
                break;
            }
          case CallStatic_0_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case CallStatic_S_1:
          case CallStatic_D_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case CallStatic_V_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // argSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case CallStatic_MS_1:
          case CallStatic_MLD_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case CallStatic_MLV_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case CallStatic_MF_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case CallStatic_MV_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case CallStatic_0_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case CallStatic_S_M:
          case CallStatic_D_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case CallStatic_V_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // argSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case CallStatic_MS_M:
          case CallStatic_MLD_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case CallStatic_MLV_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case CallStatic_MF_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case CallStatic_MV_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }

          case TailCallStatic_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                break;
            }
          case TailCallStatic_S:
          case TailCallStatic_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                break;
            }
          case TailCallStatic_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // argSizeIndex
                PC += 1;
                break;
            }
          case TailCallStatic_MS:
          case TailCallStatic_MLD:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                break;
            }
          case TailCallStatic_MLV:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSizeIndex
                PC += 1;
                break;
            }
          case TailCallStatic_MF:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizes
                    PC += 1;
                }
                break;
            }
          case TailCallStatic_MV:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeIndexes
                    PC += 1;
                }
                break;
            }
          case RecursiveCallStatic_0_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                break;
            }
          case RecursiveCallStatic_S_0:
          case RecursiveCallStatic_D_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                break;
            }
          case RecursiveCallStatic_V_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // argSizeIndex
                PC += 1;
                break;
            }
          case RecursiveCallStatic_MS_0:
          case RecursiveCallStatic_MLD_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                break;
            }
          case RecursiveCallStatic_MLV_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSizeIndex
                PC += 1;
                break;
            }
          case RecursiveCallStatic_MF_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizes
                    PC += 1;
                }
                break;
            }
          case RecursiveCallStatic_MV_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeIndexes
                    PC += 1;
                }
                break;
            }
          case RecursiveCallStatic_0_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case RecursiveCallStatic_S_1:
          case RecursiveCallStatic_D_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case RecursiveCallStatic_V_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // argSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case RecursiveCallStatic_MS_1:
          case RecursiveCallStatic_MLD_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case RecursiveCallStatic_MLV_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case RecursiveCallStatic_MF_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case RecursiveCallStatic_MV_1:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case RecursiveCallStatic_0_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case RecursiveCallStatic_S_M:
          case RecursiveCallStatic_D_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case RecursiveCallStatic_V_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // argSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case RecursiveCallStatic_MS_M:
          case RecursiveCallStatic_MLD_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case RecursiveCallStatic_MLV_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case RecursiveCallStatic_MF_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case RecursiveCallStatic_MV_M:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destsCount
                UInt32Value destsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < destsCount; index += 1){
                    toNativeOrderQuad(PC); // destinations
                    PC += 1;
                }
                break;
            }
          case RecursiveTailCallStatic_0:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                break;
            }
          case RecursiveTailCallStatic_S:
          case RecursiveTailCallStatic_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                break;
            }
          case RecursiveTailCallStatic_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argIndex
                PC += 1;
                toNativeOrderQuad(PC); // argSizeIndex
                PC += 1;
                break;
            }
          case RecursiveTailCallStatic_MS:
          case RecursiveTailCallStatic_MLD:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                break;
            }
          case RecursiveTailCallStatic_MLV:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastArgSizeIndex
                PC += 1;
                break;
            }
          case RecursiveTailCallStatic_MF:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizes
                    PC += 1;
                }
                break;
            }
          case RecursiveTailCallStatic_MV:
            {
                PC += 1;
                toNativeOrderQuad(PC); // entryPoint
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
                    PC += 1;
                }
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argSizeIndexes
                    PC += 1;
                }
                break;
            }
          case MakeBlock:
            {
                PC += 1;
                toNativeOrderQuad(PC); // bitmapIndex
                PC += 1;
                toNativeOrderQuad(PC); // sizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // fieldsCount
                UInt32Value fieldsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < fieldsCount; index += 1){
                    toNativeOrderQuad(PC); // fieldIndexes
                    PC += 1;
                }
                for(int index = 0; index < fieldsCount; index += 1){
                    toNativeOrderQuad(PC); // fieldSizeIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case MakeFixedSizeBlock:
            {
                PC += 1;
                toNativeOrderQuad(PC); // bitmapIndex
                PC += 1;
                toNativeOrderQuad(PC); // size
                PC += 1;
                toNativeOrderQuad(PC); // fieldsCount
                UInt32Value fieldsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < fieldsCount; index += 1){
                    toNativeOrderQuad(PC); // fieldIndexes
                    PC += 1;
                }
                for(int index = 0; index < fieldsCount; index += 1){
                    toNativeOrderQuad(PC); // fieldSizes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case MakeBlockOfSingleValues:
            {
                PC += 1;
                toNativeOrderQuad(PC); // bitmapIndex
                PC += 1;
                toNativeOrderQuad(PC); // fieldsCount
                UInt32Value fieldsCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < fieldsCount; index += 1){
                    toNativeOrderQuad(PC); // fieldIndexes
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
                toNativeOrderQuad(PC); // bitmapIndex
                PC += 1;
                toNativeOrderQuad(PC); // sizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // initialValueIndex
                PC += 1;
                toNativeOrderQuad(PC); // isMutable
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case MakeArray_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // bitmapIndex
                PC += 1;
                toNativeOrderQuad(PC); // sizeIndex
                PC += 1;
                toNativeOrderQuad(PC); // initialValueIndex
                PC += 1;
                toNativeOrderQuad(PC); // initialValueSize
                PC += 1;
                toNativeOrderQuad(PC); // isMutable
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
                toNativeOrderQuad(PC); // envIndex
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Raise:
            {
                PC += 1;
                toNativeOrderQuad(PC); // exceptionIndex
                PC += 1;
                break;
            }
          case PushHandler:
            {
                PC += 1;
                toNativeOrderQuad(PC); // handler
                convertOffsetToAddress(code, PC);
                PC += 1;
                toNativeOrderQuad(PC); // exceptionIndex
                PC += 1;
                break;
            }
          case PopHandler:
            {
                PC += 1;
                break;
            }
	  case RegisterCallback:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // sizeTag
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case SwitchInt:
          case SwitchWord:
          case SwitchChar:
            {
                PC += 1;
                toNativeOrderQuad(PC); // targetIndex
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
          case SwitchLargeInt:
            {
                PC += 1;
                toNativeOrderQuad(PC); // targetIndex
                PC += 1;
                toNativeOrderQuad(PC); // casesCount
                UInt32Value casesCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < casesCount; index += 1){
                    toNativeOrderQuad(PC); // constant
                    convertOffsetToAddress(code, PC);// address of ConstString
                    ASSERT_INSTRUCTION(ConstString, *PC);
                    writeLargeInt(PC);
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
          case SwitchString:
            {
                PC += 1;
                toNativeOrderQuad(PC); // targetIndex
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
          case IndirectJump:
            {
                PC += 1;
                toNativeOrderQuad(PC); // destination
                PC += 1;
                break;
            }
          case Exit:
            {
                PC += 1;
                break;
            }
          case Return_0:
            {
                PC += 1;
                break;
            }
          case Return_S:
          case Return_D:
            {
                PC += 1;
                toNativeOrderQuad(PC); // variableIndex
                PC += 1;
                break;
            }
          case Return_V:
            {
                PC += 1;
                toNativeOrderQuad(PC); // variableIndex
                PC += 1;
                toNativeOrderQuad(PC); // variableSizeIndex
                PC += 1;
                break;
            }
          case Return_MS:
          case Return_MLD:
            {
                PC += 1;
                toNativeOrderQuad(PC); // variablesCount
                UInt32Value variablesCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < variablesCount; index += 1){
                    toNativeOrderQuad(PC); // variableIndexes
                    PC += 1;
                }
                break;
            }
          case Return_MLV:
            {
                PC += 1;
                toNativeOrderQuad(PC); // variablesCount
                UInt32Value variablesCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < variablesCount; index += 1){
                    toNativeOrderQuad(PC); // variableIndexes
                    PC += 1;
                }
                toNativeOrderQuad(PC); // lastVariableSizeIndex
                PC += 1;
                break;
            }
          case Return_MF:
            {
                PC += 1;
                toNativeOrderQuad(PC); // variablesCount
                UInt32Value variablesCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < variablesCount; index += 1){
                    toNativeOrderQuad(PC); // variableIndexes
                    PC += 1;
                }
                for(int index = 0; index < variablesCount; index += 1){
                    toNativeOrderQuad(PC); // variableSizes
                    PC += 1;
                }
                break;
            }
          case Return_MV:
            {
                PC += 1;
                toNativeOrderQuad(PC); // variablesCount
                UInt32Value variablesCount = getQuadByte(PC);
                PC += 1;
                for(int index = 0; index < variablesCount; index += 1){
                    toNativeOrderQuad(PC); // variableIndexes
                    PC += 1;
                }
                for(int index = 0; index < variablesCount; index += 1){
                    toNativeOrderQuad(PC); // variableSizeIndexes
                    PC += 1;
                }
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
          case ForeignApply:
            {
                PC += 1;
                toNativeOrderQuad(PC); // closureIndex
                PC += 1;
                toNativeOrderQuad(PC); // argsCount
                UInt32Value argsCount = getQuadByte(PC);
                PC += 1;
                toNativeOrderQuad(PC); // switchTag
                PC += 1;
                toNativeOrderQuad(PC); // convention
                PC += 1;
                for(int index = 0; index < argsCount; index += 1){
                    toNativeOrderQuad(PC); // argIndexes
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
                toNativeOrderQuad(PC); /* argIndex */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* destination */ \
                PC += 1; \
                break; \
            }

// 2 args primitive
#define LINK_PRIM_2 \
            { \
                PC += 1; \
                toNativeOrderQuad(PC); /* argIndex1 */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* argIndex2 */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* destination */ \
                PC += 1; \
                break; \
            }

// 3 args primitive
#define LINK_PRIM_3 \
            { \
                PC += 1; \
                toNativeOrderQuad(PC); /* argIndex1 */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* argIndex2 */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* argIndex3 */ \
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
                toNativeOrderQuad(PC); /* argIndex */ \
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
                toNativeOrderQuad(PC); /* argIndex */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* destination */ \
                PC += 1; \
                break; \
            }
// 2 args primitive. Its 2nd argument is double word constant.
#define LINK_PRIM_2_CONST_2D \
            { \
                PC += 1; \
                toNativeOrderQuad(PC); /* argIndex */ \
                PC += 1; \
                toNativeOrderDoubleQuad(PC); /* constant */ \
                PC += 2; \
                toNativeOrderQuad(PC); /* destination */ \
                PC += 1; \
                break; \
            }

// 2 args primitive. Its 1st argument is largeInt constant.
#define LINK_PRIM_2_CONST_1L \
            { \
                PC += 1; \
                toNativeOrderQuad(PC); /* constant */ \
                convertOffsetToAddress(code, PC);/* address of ConstString */ \
                ASSERT_INSTRUCTION(ConstString, *PC); \
                /* convert the string to a largeInt and replace operand. */ \
                writeLargeInt(PC); \
                PC += 1; \
                toNativeOrderQuad(PC); /* argIndex */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* destination */ \
                PC += 1; \
                break; \
            }

// 2 args primitive. Its 2nd argument is largeInt constant.
#define LINK_PRIM_2_CONST_2L \
            { \
                PC += 1; \
                toNativeOrderQuad(PC); /* argIndex */ \
                PC += 1; \
                toNativeOrderQuad(PC); /* constant */ \
                convertOffsetToAddress(code, PC);/* address of ConstString */ \
                ASSERT_INSTRUCTION(ConstString, *PC); \
                /* convert the string to a largeInt and replace operand. */ \
                writeLargeInt(PC); \
                PC += 1; \
                toNativeOrderQuad(PC); /* destination */ \
                PC += 1; \
                break; \
            }

          case Equal: LINK_PRIM_2;
          case AddInt: LINK_PRIM_2;
          case AddInt_Const_1: LINK_PRIM_2_CONST_1S;
          case AddInt_Const_2: LINK_PRIM_2_CONST_2S;
          case AddLargeInt: LINK_PRIM_2;
          case AddLargeInt_Const_1: LINK_PRIM_2_CONST_1L;
          case AddLargeInt_Const_2: LINK_PRIM_2_CONST_2L;
          case AddReal: LINK_PRIM_2;
          case AddReal_Const_1: LINK_PRIM_2_CONST_1D;
          case AddReal_Const_2: LINK_PRIM_2_CONST_2D;
          case AddFloat: LINK_PRIM_2;
          case AddFloat_Const_1: LINK_PRIM_2_CONST_1S;
          case AddFloat_Const_2: LINK_PRIM_2_CONST_2S;
          case AddWord: LINK_PRIM_2;
          case AddWord_Const_1: LINK_PRIM_2_CONST_1S;
          case AddWord_Const_2: LINK_PRIM_2_CONST_2S;
          case AddByte: LINK_PRIM_2;
          case AddByte_Const_1: LINK_PRIM_2_CONST_1S;
          case AddByte_Const_2: LINK_PRIM_2_CONST_2S;
          case SubInt: LINK_PRIM_2;
          case SubInt_Const_1: LINK_PRIM_2_CONST_1S;
          case SubInt_Const_2: LINK_PRIM_2_CONST_2S;
          case SubLargeInt: LINK_PRIM_2;
          case SubLargeInt_Const_1: LINK_PRIM_2_CONST_1L;
          case SubLargeInt_Const_2: LINK_PRIM_2_CONST_2L;
          case SubReal: LINK_PRIM_2;
          case SubReal_Const_1: LINK_PRIM_2_CONST_1D;
          case SubReal_Const_2: LINK_PRIM_2_CONST_2D;
          case SubFloat: LINK_PRIM_2;
          case SubFloat_Const_1: LINK_PRIM_2_CONST_1S;
          case SubFloat_Const_2: LINK_PRIM_2_CONST_2S;
          case SubWord: LINK_PRIM_2;
          case SubWord_Const_1: LINK_PRIM_2_CONST_1S;
          case SubWord_Const_2: LINK_PRIM_2_CONST_2S;
          case SubByte: LINK_PRIM_2;
          case SubByte_Const_1: LINK_PRIM_2_CONST_1S;
          case SubByte_Const_2: LINK_PRIM_2_CONST_2S;
          case MulInt: LINK_PRIM_2;
          case MulInt_Const_1: LINK_PRIM_2_CONST_1S;
          case MulInt_Const_2: LINK_PRIM_2_CONST_2S;
          case MulLargeInt: LINK_PRIM_2;
          case MulLargeInt_Const_1: LINK_PRIM_2_CONST_1L;
          case MulLargeInt_Const_2: LINK_PRIM_2_CONST_2L;
          case MulReal: LINK_PRIM_2;
          case MulReal_Const_1: LINK_PRIM_2_CONST_1D;
          case MulReal_Const_2: LINK_PRIM_2_CONST_2D;
          case MulFloat: LINK_PRIM_2;
          case MulFloat_Const_1: LINK_PRIM_2_CONST_1S;
          case MulFloat_Const_2: LINK_PRIM_2_CONST_2S;
          case MulWord: LINK_PRIM_2;
          case MulWord_Const_1: LINK_PRIM_2_CONST_1S;
          case MulWord_Const_2: LINK_PRIM_2_CONST_2S;
          case MulByte: LINK_PRIM_2;
          case MulByte_Const_1: LINK_PRIM_2_CONST_1S;
          case MulByte_Const_2: LINK_PRIM_2_CONST_2S;
          case DivInt: LINK_PRIM_2;
          case DivInt_Const_1: LINK_PRIM_2_CONST_1S;
          case DivInt_Const_2: LINK_PRIM_2_CONST_2S;
          case DivLargeInt: LINK_PRIM_2;
          case DivLargeInt_Const_1: LINK_PRIM_2_CONST_1L;
          case DivLargeInt_Const_2: LINK_PRIM_2_CONST_2L;
          case DivWord: LINK_PRIM_2;
          case DivWord_Const_1: LINK_PRIM_2_CONST_1S;
          case DivWord_Const_2: LINK_PRIM_2_CONST_2S;
          case DivReal: LINK_PRIM_2;
          case DivReal_Const_1: LINK_PRIM_2_CONST_1D;
          case DivReal_Const_2: LINK_PRIM_2_CONST_2D;
          case DivFloat: LINK_PRIM_2;
          case DivFloat_Const_1: LINK_PRIM_2_CONST_1S;
          case DivFloat_Const_2: LINK_PRIM_2_CONST_2S;
          case DivByte: LINK_PRIM_2;
          case DivByte_Const_1: LINK_PRIM_2_CONST_1S;
          case DivByte_Const_2: LINK_PRIM_2_CONST_2S;
          case ModInt: LINK_PRIM_2;
          case ModInt_Const_1: LINK_PRIM_2_CONST_1S;
          case ModInt_Const_2: LINK_PRIM_2_CONST_2S;
          case ModLargeInt: LINK_PRIM_2;
          case ModLargeInt_Const_1: LINK_PRIM_2_CONST_1L;
          case ModLargeInt_Const_2: LINK_PRIM_2_CONST_2L;
          case ModWord: LINK_PRIM_2;
          case ModWord_Const_1: LINK_PRIM_2_CONST_1S;
          case ModWord_Const_2: LINK_PRIM_2_CONST_2S;
          case ModByte: LINK_PRIM_2;
          case ModByte_Const_1: LINK_PRIM_2_CONST_1S;
          case ModByte_Const_2: LINK_PRIM_2_CONST_2S;
          case QuotInt: LINK_PRIM_2;
          case QuotInt_Const_1: LINK_PRIM_2_CONST_1S;
          case QuotInt_Const_2: LINK_PRIM_2_CONST_2S;
          case QuotLargeInt: LINK_PRIM_2;
          case QuotLargeInt_Const_1: LINK_PRIM_2_CONST_1L;
          case QuotLargeInt_Const_2: LINK_PRIM_2_CONST_2L;
          case RemInt: LINK_PRIM_2;
          case RemInt_Const_1: LINK_PRIM_2_CONST_1S;
          case RemInt_Const_2: LINK_PRIM_2_CONST_2S;
          case RemLargeInt: LINK_PRIM_2;
          case RemLargeInt_Const_1: LINK_PRIM_2_CONST_1L;
          case RemLargeInt_Const_2: LINK_PRIM_2_CONST_2L;
          case NegInt: LINK_PRIM_1;
          case NegLargeInt: LINK_PRIM_1;
          case NegReal: LINK_PRIM_1;
          case NegFloat: LINK_PRIM_1;
          case AbsInt: LINK_PRIM_1;
          case AbsLargeInt: LINK_PRIM_1;
          case AbsReal: LINK_PRIM_1;
          case AbsFloat: LINK_PRIM_1;
          case LtInt: LINK_PRIM_2;
          case LtInt_Const_1: LINK_PRIM_2_CONST_1S;
          case LtInt_Const_2: LINK_PRIM_2_CONST_2S;
          case LtLargeInt: LINK_PRIM_2;
          case LtLargeInt_Const_1: LINK_PRIM_2_CONST_1L;
          case LtLargeInt_Const_2: LINK_PRIM_2_CONST_2L;
          case LtReal: LINK_PRIM_2;
          case LtReal_Const_1: LINK_PRIM_2_CONST_1D;
          case LtReal_Const_2: LINK_PRIM_2_CONST_2D;
          case LtFloat: LINK_PRIM_2;
          case LtFloat_Const_1: LINK_PRIM_2_CONST_1S;
          case LtFloat_Const_2: LINK_PRIM_2_CONST_2S;
          case LtWord: LINK_PRIM_2;
          case LtWord_Const_1: LINK_PRIM_2_CONST_1S;
          case LtWord_Const_2: LINK_PRIM_2_CONST_2S;
          case LtByte: LINK_PRIM_2;
          case LtByte_Const_1: LINK_PRIM_2_CONST_1S;
          case LtByte_Const_2: LINK_PRIM_2_CONST_2S;
          case LtChar: LINK_PRIM_2;
          case LtChar_Const_1: LINK_PRIM_2_CONST_1S;
          case LtChar_Const_2: LINK_PRIM_2_CONST_2S;
          case LtString: LINK_PRIM_2;
          case GtInt: LINK_PRIM_2;
          case GtInt_Const_1: LINK_PRIM_2_CONST_1S;
          case GtInt_Const_2: LINK_PRIM_2_CONST_2S;
          case GtLargeInt: LINK_PRIM_2;
          case GtLargeInt_Const_1: LINK_PRIM_2_CONST_1L;
          case GtLargeInt_Const_2: LINK_PRIM_2_CONST_2L;
          case GtReal: LINK_PRIM_2;
          case GtReal_Const_1: LINK_PRIM_2_CONST_1D;
          case GtReal_Const_2: LINK_PRIM_2_CONST_2D;
          case GtFloat: LINK_PRIM_2;
          case GtFloat_Const_1: LINK_PRIM_2_CONST_1S;
          case GtFloat_Const_2: LINK_PRIM_2_CONST_2S;
          case GtWord: LINK_PRIM_2;
          case GtWord_Const_1: LINK_PRIM_2_CONST_1S;
          case GtWord_Const_2: LINK_PRIM_2_CONST_2S;
          case GtByte: LINK_PRIM_2;
          case GtByte_Const_1: LINK_PRIM_2_CONST_1S;
          case GtByte_Const_2: LINK_PRIM_2_CONST_2S;
          case GtChar: LINK_PRIM_2;
          case GtChar_Const_1: LINK_PRIM_2_CONST_1S;
          case GtChar_Const_2: LINK_PRIM_2_CONST_2S;
          case GtString: LINK_PRIM_2;
          case LteqInt: LINK_PRIM_2;
          case LteqInt_Const_1: LINK_PRIM_2_CONST_1S;
          case LteqInt_Const_2: LINK_PRIM_2_CONST_2S;
          case LteqLargeInt: LINK_PRIM_2;
          case LteqLargeInt_Const_1: LINK_PRIM_2_CONST_1L;
          case LteqLargeInt_Const_2: LINK_PRIM_2_CONST_2L;
          case LteqReal: LINK_PRIM_2;
          case LteqReal_Const_1: LINK_PRIM_2_CONST_1D;
          case LteqReal_Const_2: LINK_PRIM_2_CONST_2D;
          case LteqFloat: LINK_PRIM_2;
          case LteqFloat_Const_1: LINK_PRIM_2_CONST_1S;
          case LteqFloat_Const_2: LINK_PRIM_2_CONST_2S;
          case LteqWord: LINK_PRIM_2;
          case LteqWord_Const_1: LINK_PRIM_2_CONST_1S;
          case LteqWord_Const_2: LINK_PRIM_2_CONST_2S;
          case LteqByte: LINK_PRIM_2;
          case LteqByte_Const_1: LINK_PRIM_2_CONST_1S;
          case LteqByte_Const_2: LINK_PRIM_2_CONST_2S;
          case LteqChar: LINK_PRIM_2;
          case LteqChar_Const_1: LINK_PRIM_2_CONST_1S;
          case LteqChar_Const_2: LINK_PRIM_2_CONST_2S;
          case LteqString: LINK_PRIM_2;
          case GteqInt: LINK_PRIM_2;
          case GteqInt_Const_1: LINK_PRIM_2_CONST_1S;
          case GteqInt_Const_2: LINK_PRIM_2_CONST_2S;
          case GteqLargeInt: LINK_PRIM_2;
          case GteqLargeInt_Const_1: LINK_PRIM_2_CONST_1L;
          case GteqLargeInt_Const_2: LINK_PRIM_2_CONST_2L;
          case GteqReal: LINK_PRIM_2;
          case GteqReal_Const_1: LINK_PRIM_2_CONST_1D;
          case GteqReal_Const_2: LINK_PRIM_2_CONST_2D;
          case GteqFloat: LINK_PRIM_2;
          case GteqFloat_Const_1: LINK_PRIM_2_CONST_1S;
          case GteqFloat_Const_2: LINK_PRIM_2_CONST_2S;
          case GteqWord: LINK_PRIM_2;
          case GteqWord_Const_1: LINK_PRIM_2_CONST_1S;
          case GteqWord_Const_2: LINK_PRIM_2_CONST_2S;
          case GteqByte: LINK_PRIM_2;
          case GteqByte_Const_1: LINK_PRIM_2_CONST_1S;
          case GteqByte_Const_2: LINK_PRIM_2_CONST_2S;
          case GteqChar: LINK_PRIM_2;
          case GteqChar_Const_1: LINK_PRIM_2_CONST_1S;
          case GteqChar_Const_2: LINK_PRIM_2_CONST_2S;
          case GteqString: LINK_PRIM_2;
          case Byte_toIntX: LINK_PRIM_1;
          case Byte_fromInt: LINK_PRIM_1;
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

    for (int index = 0; index < locationsWordLength; index += 1)
    {
        toNativeOrderQuad(&executable->locations_[index]);
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
 * ToDo : this function is a copy from VirtualMachine::LoadConstString.
 */
INLINE_FUN
void
ExecutableLinker::writeLargeInt(UInt32Value* PC)
{
    UInt32Value stringLength;
    char* stringBuffer;
    UInt32Value *ConstStringAddress = *(UInt32Value**)PC;
    ConstStringAddress += 1;// skip ConstString opcode.
    ConstStringAddress += 1;// skip string length.
    stringBuffer = (char*)ConstStringAddress;
    largeInt* largeIntPtr = (largeInt*)ALLOCATE_MEMORY(sizeof(largeInt));
    LargeInt::initFromString(*largeIntPtr, stringBuffer);
    *PC = (UInt32Value)largeIntPtr;// store the address of largeInt
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
