#ifndef WordOperations_hh_
#define WordOperations_hh_

#include "SystemDef.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

class WordOperations
{
    ///////////////////////////////////////////////////////////////////////////
  public:

    /**
     * fetches 1 byte from an instruction stream
     *
     * @param pc head of an instruction stream
     * @param index the index of the target byte in the 4byte word which the
     *       <code>pc</code> points to.
     * @return the <code>index</code>-th byte in the 4byte word which
     *       <code>pc</code> points to.
     */
    INLINE_FUN
    static
    UInt8Value getSingleByte(UInt32Value* const pc, const int index)
    {
        return ((UInt8Value*)pc)[index];
    }

    /**
     * fetches 2-byte word from an instruction stream
     *
     * @param pc head of an instruction stream
     * @param index 0 or 1.
     *        the index of the target 2 byte word in the 4byte word which the
     *        <code>pc</code> points to.
     * @return the <code>index</code>-th 2-byte word in the 4-byte word which
     *       <code>pc</code> points to.
     */
    INLINE_FUN
    static
    UInt16Value getDoubleByte(UInt32Value* const pc, const int index)
    {
        return ((UInt16Value*)pc)[index];
    }

    /**
     * fetches 3-byte word from an instruction stream
     *
     *  The first byte of a 4-byte word holds the most significant octet on
     * big-endian architecture , the least significant octet on little-endian
     * architecture.
     * 
     * @param pc head of an instruction stream
     * @return the last 3 bytes in the 4-byte word which
     *       <code>pc</code> points to.
     */
    INLINE_FUN
    static
    UInt32Value getTriByte(UInt32Value* const pc)
    {
#if defined(BYTE_ORDER_BIG_ENDIAN)
        return (*pc) & 0xffffff;
#elif defined(BYTE_ORDER_LITTLE_ENDIAN)
        return (*pc) >> 8;
#endif
    }

    INLINE_FUN
    static
    SInt32Value getTriByteSigned(UInt32Value* const pc)
    {
#if defined(BYTE_ORDER_BIG_ENDIAN)
        if((*pc) & 0x800000){
            return (SInt32Value)((*pc) | 0xff000000);
        }
        else{
            return (SInt32Value)((*pc) & 0xffffff);
        }
#elif defined(BYTE_ORDER_LITTLE_ENDIAN)
        if((*pc) & 0x80000000){
            return (SInt32Value)(((*pc) >> 8) | 0xff000000);
        }
        else{
            return (SInt32Value)((*pc) >> 8);
        }
#endif
    }

    /**
     * fetches 4-byte word from an instruction stream
     *
     * @param pc head of an instruction stream
     * @return the 4-byte word which <code>pc</code> points to.
     */
    INLINE_FUN
    static
    UInt32Value getQuadByte(UInt32Value* const pc)
    {
        return *pc;
    }

    ////////////////////////////////////////

    INLINE_FUN
    static
    UInt32Value pack_1_3(UInt8Value singleByte, UInt32Value triByte)
    {
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
        return (singleByte | (triByte << 8));
#elif defined(BYTE_ORDER_BIG_ENDIAN)
        return ((singleByte << 24) | (triByte & 0xffffff));
#endif
    }

    INLINE_FUN
    static
    UInt32Value pack_1_1_2(UInt8Value firstByte,
                           UInt8Value secondByte,
                           UInt16Value doubleByte)
    {
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
        return (firstByte | (secondByte << 8) | (doubleByte << 16));
#elif defined(BYTE_ORDER_BIG_ENDIAN)
        return ((firstByte << 24) |
                (secondByte << 16) |
                (doubleByte & 0xffffff));
#endif
    }

    INLINE_FUN
    static
    UInt32Value pack_1_1_1_1(UInt8Value firstByte,
                             UInt8Value secondByte,
                             UInt8Value thirdByte,
                             UInt8Value fourthByte)
    {
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
        return ((fourthByte << 24) |
                (thirdByte << 16) |
                (secondByte << 8) |
                firstByte);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
        return ((firstByte << 24) |
                (secondByte << 16) |
                (thirdByte << 8) |
                fourthByte);
#endif
    }

    ////////////////////////////////////////

    INLINE_FUN
    static
    void reverseDoubleByte(UInt32Value* words, int index)
    {
        UInt8Value* bytes = (UInt8Value*)(&((UInt16Value*)words)[index]);
        UInt8Value temp = bytes[0];
        bytes[0] = bytes[1];
        bytes[1] = temp;
    }

    INLINE_FUN
    static
    void reverseTriByte(UInt32Value* words)
    {
        UInt8Value* bytes = (UInt8Value*)words;
        UInt8Value temp = bytes[1];
        bytes[1] = bytes[3];
        bytes[3] = temp;
    }
    
    INLINE_FUN
    static
    void reverseQuadByte(UInt32Value* words)
    {
        UInt8Value* bytes = (UInt8Value*)words;
        UInt8Value temp;
        temp = bytes[0];
        bytes[0] = bytes[3];
        bytes[3] = temp;
        temp = bytes[1];
        bytes[1] = bytes[2];
        bytes[2] = temp;
    }

    INLINE_FUN
    static
    void reverseDoubleQuadByte(UInt32Value* words)
    {
        UInt8Value* bytes = (UInt8Value*)words;
        for(int index = 0 ; index < 4 ; index += 1)
        {
            int oppositeIndex = 8 - index - 1;
            UInt8Value temp = bytes[index];
            bytes[index] = bytes[oppositeIndex];
            bytes[oppositeIndex] = temp;
        }
    }

    ////////////////////////////////////////

    INLINE_FUN
    static
    UInt16Value NetToNativeOrderDoubleByte(UInt16Value netValue)
    {
#if defined(BYTE_ORDER_BIG_ENDIAN)
        return netValue;
#elif defined(BYTE_ORDER_LITTLE_ENDIAN)
        return
        (((netValue & 0xFF) << 8) |
         ((netValue & 0xFF00) >> 8));
#endif
    }


    INLINE_FUN
    static
    UInt16Value NativeToNetOrderDoubleByte(UInt16Value nativeValue)
    {
#if defined(BYTE_ORDER_BIG_ENDIAN)
        return nativeValue;
#elif defined(BYTE_ORDER_LITTLE_ENDIAN)
        return
        (((nativeValue & 0xFF) << 8) |
         ((nativeValue & 0xFF00) >> 8));
#endif
    }

    INLINE_FUN
    static
    UInt32Value NetToNativeOrderQuadByte(UInt32Value netValue)
    {
#if defined(BYTE_ORDER_BIG_ENDIAN)
        return netValue;
#elif defined(BYTE_ORDER_LITTLE_ENDIAN)
        return
        (((netValue & 0xFF) << 24) |
         ((netValue & 0xFF00) << 8) |
         ((netValue & 0xFF0000) >> 8) |
         ((netValue & 0xFF000000) >> 24));
#endif
    }

    INLINE_FUN
    static
    UInt32Value NativeToNetOrderQuadByte(UInt32Value nativeValue)
    {
#if defined(BYTE_ORDER_BIG_ENDIAN)
        return nativeValue;
#elif defined(BYTE_ORDER_LITTLE_ENDIAN)
        return
        (((nativeValue & 0xFF) << 24) |
         ((nativeValue & 0xFF00) << 8) |
         ((nativeValue & 0xFF0000) >> 8) |
         ((nativeValue & 0xFF000000) >> 24));
#endif
    }
};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif // WordOperations_hh_
