#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "WordOperations.hh"
#include "Log.hh"
#include "Debug.hh"

#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/*
 * byte * byte * byte * byte -> word
 */
void
IMLPrim_Pack_packWord32LittleImpl(UInt32Value argsCount,
                                  Cell* argumentRefs[],
                                  Cell* resultRef)
{
    UInt8Value byte0 = (UInt8Value)argumentRefs[0]->uint32;
    UInt8Value byte1 = (UInt8Value)argumentRefs[1]->uint32;
    UInt8Value byte2 = (UInt8Value)argumentRefs[2]->uint32;
    UInt8Value byte3 = (UInt8Value)argumentRefs[3]->uint32;
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
     /* normal order */
    resultRef->uint32 = WordOperations::packUInt32(byte0, byte1, byte2, byte3);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
     /* reverse order */
    resultRef->uint32 = WordOperations::packUInt32(byte3, byte2, byte1, byte0);
#endif
}

/*
 * byte * byte * byte * byte -> word
 */
void
IMLPrim_Pack_packWord32BigImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    UInt8Value byte0 = (UInt8Value)argumentRefs[0]->uint32;
    UInt8Value byte1 = (UInt8Value)argumentRefs[1]->uint32;
    UInt8Value byte2 = (UInt8Value)argumentRefs[2]->uint32;
    UInt8Value byte3 = (UInt8Value)argumentRefs[3]->uint32;
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
    /* reverse order */
    resultRef->uint32 = WordOperations::packUInt32(byte3, byte2, byte1, byte0);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
    /* normal order */
    resultRef->uint32 = WordOperations::packUInt32(byte0, byte1, byte2, byte3);
#endif
}

/*
 * word -> byte * byte * byte * byte
 */
void
IMLPrim_Pack_unpackWord32LittleImpl(UInt32Value argsCount,
                                    Cell* argumentRefs[],
                                    Cell* resultRef)
{
    UInt32Value word = argumentRefs[0]->uint32;
    Cell elements[4];
    UInt8Value bytes[4];

/*
   We cannot do it here like this:

    WordOperations::unpackUInt32(word, 
                                   (UInt8Value*)&elements[0].uint32,
                                   (UInt8Value*)&elements[1].uint32,
                                   (UInt8Value*)&elements[2].uint32,
                                   (UInt8Value*)&elements[3].uint32);
*/

#if defined(BYTE_ORDER_LITTLE_ENDIAN)
    /* normal order */
    WordOperations::unpackUInt32(word,
                                 &bytes[0], &bytes[1], &bytes[2], &bytes[3]);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
    /* reverse order */
    WordOperations::unpackUInt32(word, 
                                 &bytes[3], &bytes[2], &bytes[1], &bytes[0]);
#endif
    elements[0].uint32 = bytes[0];
    elements[1].uint32 = bytes[1];
    elements[2].uint32 = bytes[2];
    elements[3].uint32 = bytes[3];
    *resultRef = PrimitiveSupport::tupleElementsToCell(0, elements, 4);
}

/*
 * word -> byte * byte * byte * byte
 */
void
IMLPrim_Pack_unpackWord32BigImpl(UInt32Value argsCount,
                                 Cell* argumentRefs[],
                                 Cell* resultRef)
{
    UInt32Value word = argumentRefs[0]->uint32;
    Cell elements[4];
    UInt8Value bytes[4];
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
    /* normal order */
    WordOperations::unpackUInt32(word,
                                 &bytes[3], &bytes[2], &bytes[1], &bytes[0]);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
    /* reverse order */
    WordOperations::unpackUInt32(word, 
                                 &bytes[0], &bytes[1], &bytes[2], &bytes[3]);
#endif
    elements[0].uint32 = bytes[0];
    elements[1].uint32 = bytes[1];
    elements[2].uint32 = bytes[2];
    elements[3].uint32 = bytes[3];
    *resultRef = PrimitiveSupport::tupleElementsToCell(0, elements, 4);
}

////////////////////////////////////////

/*
 * byte * byte * byte * byte * byte * byte * byte * byte -> real
 */
void
IMLPrim_Pack_packReal64LittleImpl(UInt32Value argsCount,
                                  Cell* argumentRefs[],
                                  Cell* resultRef)
{
    UInt8Value byte0 = (UInt8Value)argumentRefs[0]->uint32;
    UInt8Value byte1 = (UInt8Value)argumentRefs[1]->uint32;
    UInt8Value byte2 = (UInt8Value)argumentRefs[2]->uint32;
    UInt8Value byte3 = (UInt8Value)argumentRefs[3]->uint32;
    UInt8Value byte4 = (UInt8Value)argumentRefs[4]->uint32;
    UInt8Value byte5 = (UInt8Value)argumentRefs[5]->uint32;
    UInt8Value byte6 = (UInt8Value)argumentRefs[6]->uint32;
    UInt8Value byte7 = (UInt8Value)argumentRefs[7]->uint32;
    Real64Value result;
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
     /* normal order */
    result = WordOperations::packReal64(byte0, byte1, byte2, byte3,
                                        byte4, byte5, byte6, byte7);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
     /* reverse order */
    result = WordOperations::packReal64(byte7, byte6, byte5, byte4,
                                        byte3, byte2, byte1, byte0);
#endif
    PrimitiveSupport::real64ToCellRef(result, resultRef);
}

/*
 * byte * byte * byte * byte * byte * byte * byte * byte -> real
 */
void
IMLPrim_Pack_packReal64BigImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    UInt8Value byte0 = (UInt8Value)argumentRefs[0]->uint32;
    UInt8Value byte1 = (UInt8Value)argumentRefs[1]->uint32;
    UInt8Value byte2 = (UInt8Value)argumentRefs[2]->uint32;
    UInt8Value byte3 = (UInt8Value)argumentRefs[3]->uint32;
    UInt8Value byte4 = (UInt8Value)argumentRefs[4]->uint32;
    UInt8Value byte5 = (UInt8Value)argumentRefs[5]->uint32;
    UInt8Value byte6 = (UInt8Value)argumentRefs[6]->uint32;
    UInt8Value byte7 = (UInt8Value)argumentRefs[7]->uint32;
    Real64Value result;
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
     /* reverse order */
    result = WordOperations::packReal64(byte7, byte6, byte5, byte4,
                                        byte3, byte2, byte1, byte0);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
     /* normal order */
    result = WordOperations::packReal64(byte0, byte1, byte2, byte3,
                                        byte4, byte5, byte6, byte7);
#endif
    PrimitiveSupport::real64ToCellRef(result, resultRef);
}

/*
 * real -> byte * byte * byte * byte * byte * byte * byte * byte
 */
void
IMLPrim_Pack_unpackReal64LittleImpl(UInt32Value argsCount,
                                    Cell* argumentRefs[],
                                    Cell* resultRef)
{
    Real64Value real = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Cell elements[8];
    UInt8Value bytes[8];
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
    /* normal order */
    WordOperations::unpackReal64(real,
                                 &bytes[0], &bytes[1], &bytes[2], &bytes[3],
                                 &bytes[4], &bytes[5], &bytes[6], &bytes[7]);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
    /* reverse order */
    WordOperations::unpackReal64(real,
                                 &bytes[7], &bytes[6], &bytes[5], &bytes[4],
                                 &bytes[3], &bytes[2], &bytes[1], &bytes[0]);
#endif
    elements[0].uint32 = bytes[0];
    elements[1].uint32 = bytes[1];
    elements[2].uint32 = bytes[2];
    elements[3].uint32 = bytes[3];
    elements[4].uint32 = bytes[4];
    elements[5].uint32 = bytes[5];
    elements[6].uint32 = bytes[6];
    elements[7].uint32 = bytes[7];
    *resultRef = PrimitiveSupport::tupleElementsToCell(0, elements, 8);
}

/*
 * real -> byte * byte * byte * byte * byte * byte * byte * byte
 */
void
IMLPrim_Pack_unpackReal64BigImpl(UInt32Value argsCount,
                                 Cell* argumentRefs[],
                                 Cell* resultRef)
{
    Real64Value real = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Cell elements[8];
    UInt8Value bytes[8];
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
    /* reverse order */
    WordOperations::unpackReal64(real,
                                 &bytes[7], &bytes[6], &bytes[5], &bytes[4],
                                 &bytes[3], &bytes[2], &bytes[1], &bytes[0]);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
    /* normal order */
    WordOperations::unpackReal64(real,
                                 &bytes[0], &bytes[1], &bytes[2], &bytes[3],
                                 &bytes[4], &bytes[5], &bytes[6], &bytes[7]);
#endif
    elements[0].uint32 = bytes[0];
    elements[1].uint32 = bytes[1];
    elements[2].uint32 = bytes[2];
    elements[3].uint32 = bytes[3];
    elements[4].uint32 = bytes[4];
    elements[5].uint32 = bytes[5];
    elements[6].uint32 = bytes[6];
    elements[7].uint32 = bytes[7];
    *resultRef = PrimitiveSupport::tupleElementsToCell(0, elements, 8);
}

////////////////////////////////////////

/*
 * byte * byte * byte * byte -> float
 */
void
IMLPrim_Pack_packReal32LittleImpl(UInt32Value argsCount,
                                  Cell* argumentRefs[],
                                  Cell* resultRef)
{
    UInt8Value byte0 = (UInt8Value)argumentRefs[0]->uint32;
    UInt8Value byte1 = (UInt8Value)argumentRefs[1]->uint32;
    UInt8Value byte2 = (UInt8Value)argumentRefs[2]->uint32;
    UInt8Value byte3 = (UInt8Value)argumentRefs[3]->uint32;
    Real32Value result;
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
     /* normal order */
    result = WordOperations::packReal32(byte0, byte1, byte2, byte3);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
     /* reverse order */
    result = WordOperations::packReal32(byte3, byte2, byte1, byte0);
#endif
    PrimitiveSupport::real32ToCellRef(result, resultRef);
}

/*
 * byte * byte * byte * byte -> float
 */
void
IMLPrim_Pack_packReal32BigImpl(UInt32Value argsCount,
                               Cell* argumentRefs[],
                               Cell* resultRef)
{
    UInt8Value byte0 = (UInt8Value)argumentRefs[0]->uint32;
    UInt8Value byte1 = (UInt8Value)argumentRefs[1]->uint32;
    UInt8Value byte2 = (UInt8Value)argumentRefs[2]->uint32;
    UInt8Value byte3 = (UInt8Value)argumentRefs[3]->uint32;
    Real32Value result;
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
     /* reverse order */
    result = WordOperations::packReal32(byte3, byte2, byte1, byte0);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
     /* normal order */
    result = WordOperations::packReal32(byte0, byte1, byte2, byte3);
#endif
    PrimitiveSupport::real32ToCellRef(result, resultRef);
}

/*
 * float -> byte * byte * byte * byte
 */
void
IMLPrim_Pack_unpackReal32LittleImpl(UInt32Value argsCount,
                                    Cell* argumentRefs[],
                                    Cell* resultRef)
{
    Real32Value real = PrimitiveSupport::cellRefToReal32(argumentRefs[0]);
    Cell elements[4];
    UInt8Value bytes[4];
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
    /* normal order */
    WordOperations::unpackReal32(real,
                                 &bytes[0], &bytes[1], &bytes[2], &bytes[3]);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
    /* reverse order */
    WordOperations::unpackReal32(real,
                                 &bytes[3], &bytes[2], &bytes[1], &bytes[0]);
#endif
    elements[0].uint32 = bytes[0];
    elements[1].uint32 = bytes[1];
    elements[2].uint32 = bytes[2];
    elements[3].uint32 = bytes[3];
    *resultRef = PrimitiveSupport::tupleElementsToCell(0, elements, 4);
}

/*
 * float -> byte * byte * byte * byte
 */
void
IMLPrim_Pack_unpackReal32BigImpl(UInt32Value argsCount,
                                 Cell* argumentRefs[],
                                 Cell* resultRef)
{
    Real32Value real = PrimitiveSupport::cellRefToReal32(argumentRefs[0]);
    Cell elements[4];
    UInt8Value bytes[4];
#if defined(BYTE_ORDER_LITTLE_ENDIAN)
    /* reverse order */
    WordOperations::unpackReal32(real,
                                 &bytes[3], &bytes[2], &bytes[1], &bytes[0]);
#elif defined(BYTE_ORDER_BIG_ENDIAN)
    /* normal order */
    WordOperations::unpackReal32(real,
                                 &bytes[0], &bytes[1], &bytes[2], &bytes[3]);
#endif
    elements[0].uint32 = bytes[0];
    elements[1].uint32 = bytes[1];
    elements[2].uint32 = bytes[2];
    elements[3].uint32 = bytes[3];
    *resultRef = PrimitiveSupport::tupleElementsToCell(0, elements, 4);
}

///////////////////////////////////////////////////////////////////////////////

Primitive IMLPrim_Pack_packWord32Little = IMLPrim_Pack_packWord32LittleImpl;
Primitive IMLPrim_Pack_packWord32Big = IMLPrim_Pack_packWord32BigImpl;
Primitive IMLPrim_Pack_unpackWord32Little = IMLPrim_Pack_unpackWord32LittleImpl;
Primitive IMLPrim_Pack_unpackWord32Big = IMLPrim_Pack_unpackWord32BigImpl;
Primitive IMLPrim_Pack_packReal64Little = IMLPrim_Pack_packReal64LittleImpl;
Primitive IMLPrim_Pack_packReal64Big = IMLPrim_Pack_packReal64BigImpl;
Primitive IMLPrim_Pack_unpackReal64Little = IMLPrim_Pack_unpackReal64LittleImpl;
Primitive IMLPrim_Pack_unpackReal64Big = IMLPrim_Pack_unpackReal64BigImpl;
Primitive IMLPrim_Pack_packReal32Little = IMLPrim_Pack_packReal32LittleImpl;
Primitive IMLPrim_Pack_packReal32Big = IMLPrim_Pack_packReal32BigImpl;
Primitive IMLPrim_Pack_unpackReal32Little = IMLPrim_Pack_unpackReal32LittleImpl;
Primitive IMLPrim_Pack_unpackReal32Big = IMLPrim_Pack_unpackReal32BigImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
