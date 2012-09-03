/**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PrimitiveSupport.hh,v 1.35 2008/01/12 09:27:58 kiyoshiy Exp $
 */
#ifndef PRIMITIVESUPPORT_HH
#define PRIMITIVESUPPORT_HH

#include <string.h>
#include <assert.h>

#include "Constants.hh"
#include "Heap.hh"
#include "VirtualMachine.hh"
#include "Writer.hh"
#include "UserException.hh"
#include "Log.hh"
#include "Debug.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/**
 * log writer
 */
DBGWRAP(static LogAdaptor LOG = LogAdaptor("Primitive");)

///////////////////////////////////////////////////////////////////////////////

/**
 * A utility class to wrap rootset management for a pointer to a heap block.
 */
class TemporaryRoot
{

  private:
    bool isPointer_;

  public:

    /**
     * constructor.
     *  The second argument is for utility in a case where it is impossible to
     * judge statically whether the valueRef holds a block pointer or not.
     */
    TemporaryRoot(Cell* valueRef, bool isPointer = true)
        :isPointer_(isPointer)
    {
        if(isPointer){
            VirtualMachine::getInstance()
            ->pushTemporaryRoot(&(valueRef->blockRef));
        }
    }

    virtual ~TemporaryRoot()
    {
        if(isPointer_){
            VirtualMachine::getInstance()->popTemporaryRoot();
        }
    }

};

class PrimitiveSupport
{
  public:

    ///////////////////////////////////////////////////////////////////////////
    // real

    static
    INLINE_FUN
    Real64Value WORDS_TO_REAL64(UInt32Value word1, UInt32Value word2)
    {
        Real64Value result;
        *((UInt32Value*)&result) = word1;
        *(((UInt32Value*)&result) + 1) = word2;
        return result;
    }

    static
    INLINE_FUN
    void
    REAL64_TO_WORDS(Real64Value real,
                    UInt32Value* wordRef1,
                    UInt32Value* wordRef2)
    {
        *(wordRef1) = *((UInt32Value*)&(real));
        *(wordRef2) = *(((UInt32Value*)&(real)) + 1);
        return;
    }

    static
    INLINE_FUN
    Real64Value
    cellRefToReal64(Cell* argumentRef)
    {
#ifdef FLOAT_UNBOXING
        Real64Value realValue = *(Real64Value*)(&(argumentRef->uint32));
#else
        Real64Value realValue;
        COPY_MEMORY(&realValue, argumentRef->blockRef, sizeof(Real64Value));
#endif
        return realValue;
    }

    static
    INLINE_FUN
    void
    real64ToCellRef(Real64Value real, Cell* resultBuf)
    {
#ifdef FLOAT_UNBOXING
        *(Real64Value*)(&(resultBuf->uint32)) = real;
#else
        resultBuf->blockRef =
        Heap::allocAtomBlock(sizeof(Real64Value) / sizeof(Cell));
        COPY_MEMORY(resultBuf->blockRef, &real, sizeof(Real64Value));
#endif
        return;
    }

    ///////////////////////////////////////////////////////////////////////////
    // float

    static
    INLINE_FUN
    Real32Value
    cellRefToReal32(Cell* argumentRef)
    {
        Real32Value real32Value = argumentRef->real32;
        return real32Value;
    }

    static
    INLINE_FUN
    void
    real32ToCellRef(Real32Value real32, Cell* resultBuf)
    {
        resultBuf->real32 = real32;
        return;
    }

    ///////////////////////////////////////////////////////////////////////////
    // bool

    static
    INLINE_FUN
    Cell boolToCell(bool value)
    {
        Cell dest;
        dest.uint32 = value ? TAG_bool_true : TAG_bool_false;
        return dest;
    }

    static
    INLINE_FUN
    bool cellToBool(Cell cell)
    {
        return (TAG_bool_true == cell.uint32);
    }

    ///////////////////////////////////////////////////////////////////////////
    // block

    static
    INLINE_FUN
    Cell* allocateAtomBlock(int fields, Cell* fieldValues)
    {
        Cell* block = Heap::allocAtomBlock(fields);
        if(fieldValues){
            for(int index = 0; index < fields; index += 1)
            {
                Heap::updateField(block, index, fieldValues[index]);
            }
        }
        return block;
    }

    ///////////////////////////////////////////////////////////////////////////
    // String

    /*
     * allocates a heap block and copy the string to it.
     * If string is NULL, allocates only.
     */
    static
    INLINE_FUN
    Cell stringToCell(const char* string, int length, bool isMutable = false)
    {
        // add space for '\0' trailer.
        UInt32Value stringWords = (length + sizeof(Cell)) / sizeof(Cell);
        Cell* block = Heap::allocSingleAtomArray(1 + stringWords, isMutable);
        Cell cell;
        cell.uint32 = length;
        Heap::initializeField(block, stringWords, cell);
        // set '\0' trailer
        cell.uint32 = 0;
        Heap::initializeField(block, stringWords - 1, cell);
        // copy the contents
        if(NULL != string){
            COPY_MEMORY(&block[0], string, length);
        }

        Cell result;
        result.blockRef = block;
        return result;
    }

    static
    INLINE_FUN
    Cell stringToCell(const char* buffer)
    {
        ASSERT(buffer);
        return stringToCell(buffer, ::strlen(buffer));
    }

    static
    INLINE_FUN
    char* cellToString(Cell cell)
    {
        return (char*)(cell.blockRef);
    }

    static
    INLINE_FUN
    UInt32Value cellToStringLength(Cell cell)
    {
        int blockSize = Heap::getPayloadSize(cell.blockRef);
        return cell.blockRef[blockSize - 1].uint32;
    }

    static
    INLINE_FUN
    Cell byteArrayToCell(const char* buffer, int size)
    {
        ASSERT(buffer);
        Cell result = stringToCell(buffer, size);
        return result;
    }

    ///////////////////////////////////////////////////////////////////////////
    // array

    static
    INLINE_FUN
    Cell* allocatePointerArray(int fields, bool isMutable)
    {
        Cell* block = Heap::allocPointerArray(fields, isMutable);
        return block;
    }

    static
    INLINE_FUN
    int getArrayLength(Cell* block)
    {
        int blockSize = Heap::getPayloadSize(block);
        int length;
        switch(Heap::getBlockType(block)){
          case Heap::BLOCKTYPE_SINGLE_ATOM_MUTABLE_ARRAY:
          case Heap::BLOCKTYPE_POINTER_MUTABLE_ARRAY:
          case Heap::BLOCKTYPE_SINGLE_ATOM_IMMUTABLE_ARRAY:
          case Heap::BLOCKTYPE_POINTER_IMMUTABLE_ARRAY:
            length = blockSize;
            break;
          case Heap::BLOCKTYPE_DOUBLE_ATOM_MUTABLE_ARRAY:
          case Heap::BLOCKTYPE_DOUBLE_ATOM_IMMUTABLE_ARRAY:
            length = blockSize >> 1;
            break;
          default:
            // empty array is a unit block.
            ASSERT(0 == blockSize);
            length = 0;
            break;
        }
        return length;
    }

    ///////////////////////////////////////////////////////////////////////////
    // IO

    static
    INLINE_FUN
    UInt32Value writeToSTDOUT(UInt32Value length, const ByteValue* buffer)
    {
        ASSERT(buffer);
        Writer* writer = 
        VirtualMachine::getInstance()
        ->getSession()
        ->getStandardOutputWriter();
        ASSERT(writer);
        UInt32Value result = writer->write(length, buffer);
        return result;
    }

    static
    INLINE_FUN
    UInt32Value writeToSTDERR(UInt32Value length, const ByteValue* buffer)
    {
        ASSERT(buffer);
        Writer* writer = 
        VirtualMachine::getInstance()
        ->getSession()
        ->getStandardErrorWriter();
        ASSERT(writer);
        UInt32Value result = writer->write(length, buffer);
        return result;
    }

    ///////////////////////////////////////////////////////////////////////////
    // unit

    static
    INLINE_FUN
    Cell constructUnit()
    {
        Cell result;
        result.uint32 = 0;
        return result;
    }

  /*
   *  The representation of Unit type has been changed from the empty record to 0.
   *     static
   *     INLINE_FUN
   *     Cell constructUnit()
   *     {
   *        Cell result;
   *        result.blockRef = Heap::allocAtomBlock(0);
   *         return result;
   *     }
   */
    ///////////////////////////////////////////////////////////////////////////
    // Option

    static
    INLINE_FUN
    Cell constructOptionNONE()
    {
        Cell tag;
        tag.sint32 = TAG_option_NONE;
        Cell result;
        result.blockRef = Heap::allocRecordBlock(0, 1);
        Heap::initializeField(result.blockRef, 0, tag);
        return result;
    }

    static
    INLINE_FUN
    Cell constructOptionSOME(Cell* argumentRef, bool isPointerArgument)
    {
        Cell tag;
        tag.sint32 = TAG_option_SOME;
        Bitmap bitmap = isPointerArgument ? 2 : 0;
        TemporaryRoot(argumentRef, isPointerArgument);

        Cell result;
        result.blockRef = Heap::allocRecordBlock(bitmap, 2);

        Heap::initializeField(result.blockRef, 0, tag);
        Heap::initializeField(result.blockRef, 1, *argumentRef);
        return result;
    }

    static
    INLINE_FUN
    int cellToOption(Cell option, Cell* argumentRef)
    {
        ASSERT(Heap::isValidBlockPointer(option.blockRef));
        int tag = option.blockRef[0].uint32;
        if(TAG_option_SOME == tag)
        {
            *argumentRef = option.blockRef[1];
        }
        return tag;
    }

    ///////////////////////////////////////////////////////////////////////////
    // list

    static
    INLINE_FUN
    int cellToListLength(Cell list)
    {
        ASSERT(Heap::isValidBlockPointer(list.blockRef));
        int length = 0;
        while(TAG_list_cons == list.blockRef[0].uint32){
            length += 1;
            list = list.blockRef[2];
            ASSERT(Heap::isValidBlockPointer(list.blockRef));
        }
        return length;
    }

    static
    INLINE_FUN
    int cellToListGetItem(Cell list, Cell* headRef, Cell* tailRef)
    {
        ASSERT(Heap::isValidBlockPointer(list.blockRef));
        int tag = list.blockRef[0].uint32;
        if(TAG_list_cons == tag)
        {
            *headRef = list.blockRef[1];
            *tailRef = list.blockRef[2];
        }
        return tag;
    }

    static
    INLINE_FUN
    Cell constructListNil()
    {
        Cell tag;
        tag.sint32 = TAG_list_nil;
        Bitmap bitmap = 0;
        
        Cell result;
        result.blockRef = Heap::allocRecordBlock(bitmap, 1);

        Heap::initializeField(result.blockRef, 0, tag);
        return result;
    }

    static
    INLINE_FUN
    Cell constructListCons(Cell *headRef, Cell *tailRef, bool isPointerHead)
    {
        Cell tag;
        tag.sint32 = TAG_list_cons;
        Bitmap bitmap = isPointerHead ? 6 : 4;

        TemporaryRoot(headRef, isPointerHead);
        TemporaryRoot(tailRef, true);

        Cell result;
        result.blockRef = Heap::allocRecordBlock(bitmap, 3);

        Heap::initializeField(result.blockRef, 0, tag);
        Heap::initializeField(result.blockRef, 1, *headRef);
        Heap::initializeField(result.blockRef, 2, *tailRef);
        return result;
    }

    ///////////////////////////////////////////////////////////////////////////
    // tuple

    static
    INLINE_FUN
    void blockToTupleElements(Cell* tuple, Cell* elementsRef, int numElements)
    {
        ASSERT(Heap::isValidBlockPointer(tuple));

        int blockSize = Heap::getPayloadSize(tuple);
        assert(numElements <= blockSize);// ToDo : raise an error.
        
        for(int index = 0; index < numElements; index += 1){
            elementsRef[index] = tuple[index];
        }
        return;
    }

    static
    INLINE_FUN
    void cellToTupleElements(Cell tuple, Cell* elementsRef, int numElements)
    {
        blockToTupleElements(tuple.blockRef, elementsRef, numElements);
        return;
    }

    static
    INLINE_FUN
    Cell tupleElementsToCell(Bitmap bitmap, Cell *elements, int numElements)
    {
        Cell result;
        result.blockRef = Heap::allocRecordBlock(bitmap, numElements);
        for(int index = 0; index < numElements; index += 1)
        {
            Heap::initializeField(result.blockRef, index, elements[index]);
        }
        return result;
    }

    ///////////////////////////////////////////////////////////////////////////
    // exception

    static
    INLINE_FUN
    Cell
    constructExnDiv()
    {
        // we will construct Div

        Bitmap bitmap = 0; // (tag) = (0)
        Cell tag;
        tag.sint32 = TAG_exn_Div;
        Cell exception;
        exception.blockRef = Heap::allocRecordBlock(bitmap, 1);
        Heap::initializeField(exception.blockRef, 0, tag);
        
        return exception;
    }

    static
    INLINE_FUN
    Cell
    constructExnOverflow()
    {
        // we will construct Overflow

        Bitmap bitmap = 0; // (tag) = (0)
        Cell tag;
        tag.sint32 = TAG_exn_Overflow;
        Cell exception;
        exception.blockRef = Heap::allocRecordBlock(bitmap, 1);
        Heap::initializeField(exception.blockRef, 0, tag);
        
        return exception;
    }

    static
    INLINE_FUN
    Cell
    constructExnSysErr(int errorNumber, const char* message)
    {
        // we will construct SysErr(message, SOME errorNumber)
        ASSERT(message);

        Cell messageValue = stringToCell(message);
        TemporaryRoot(&messageValue, true);

        Cell errorNumberValue;
        errorNumberValue.sint32 = errorNumber;
        Cell errorNumberOptValue =
        constructOptionSOME(&errorNumberValue, false);
        TemporaryRoot(&errorNumberOptValue, true);

        Bitmap bitmap = 6; // (tag, messageValue, errorNumOpt) = (0, 1, 1)
        Cell tag;
        tag.sint32 = TAG_exn_SysErr;
        Cell exception;
        exception.blockRef = Heap::allocRecordBlock(bitmap, 3);
        Heap::initializeField(exception.blockRef, 0, tag);
        Heap::initializeField(exception.blockRef, 1, messageValue);
        Heap::initializeField(exception.blockRef, 2, errorNumberOptValue);
        
        return exception;
    }

    static
    INLINE_FUN
    Cell
    constructExnFail(const char* message)
    {
        // we will construct Fail(message)
        ASSERT(message);

        Cell messageValue = stringToCell(message);
        TemporaryRoot(&messageValue, true);

        Bitmap bitmap = 2; // (tag, messageValue) = (0, 1)
        Cell tag;
        tag.sint32 = TAG_exn_Fail;
        Cell exception;
        exception.blockRef = Heap::allocRecordBlock(bitmap, 2);
        Heap::initializeField(exception.blockRef, 0, tag);
        Heap::initializeField(exception.blockRef, 1, messageValue);
        
        return exception;
    }

    static
    INLINE_FUN
    void
    raiseFail(const char* message)
    {
        DBGWRAP(LOG.debug("raiseFail: %s", message);)

        Cell exception = constructExnFail(message);
        VirtualMachine::getInstance()->setPrimitiveException(exception);
    }

    static
    INLINE_FUN
    void
    raiseException(Cell& exn)
    {
        VirtualMachine::getInstance()->setPrimitiveException(exn);
    }

}; // class PrimitiveSupport

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif
