#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void 
IMLPrim_Real_toStringImpl(UInt32Value argsCount,
                          Cell* argumentRefs[],
                          Cell* resultRef)
{
  Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    
    char buffer[32];
    sprintf(buffer, "%g", realValue);
    if('-' == buffer[0]){buffer[0] = '~';}
    *resultRef = PrimitiveSupport::stringToCell(buffer);
    return;
};

void
IMLPrim_Real_floorImpl(UInt32Value argsCount,
                       Cell* argumentRefs[],
                       Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    resultRef->sint32 = (SInt32Value)::floor(realValue);
    return;
};

void
IMLPrim_Real_ceilImpl(UInt32Value argsCount,
                      Cell* argumentRefs[],
                      Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    resultRef->sint32 = (SInt32Value)::ceil(realValue);
    return;
};

void
IMLPrim_Real_truncImpl(UInt32Value argsCount,
                       Cell* argumentRefs[],
                       Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    resultRef->sint32 = (SInt32Value)realValue;
    return;
};

void
IMLPrim_Real_roundImpl(UInt32Value argsCount,
                       Cell* argumentRefs[],
                       Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value integral;
    Real64Value fraction = ::modf(realValue, &integral);
    SInt32Value returnValue = (SInt32Value)realValue;
    if(0.5 <= fraction){
        assert(0 < returnValue);
        returnValue += 1;
    }
    else if(fraction <= -0.5){
        assert(returnValue < 0);
        returnValue -= 1;
    }
    resultRef->sint32 = returnValue;
    return;
};

void
IMLPrim_Real_fromIntImpl(UInt32Value argsCount,
                         Cell* argumentRefs[],
                         Cell* resultRef)
{
    Real64Value realValue = (Real64Value)(argumentRefs[0]->sint32);

    PrimitiveSupport::real64ToCellRef(realValue, resultRef);
    return;
};

/*
 * real -> real * real
 */
void
IMLPrim_Real_splitImpl(UInt32Value argsCount,
                       Cell* argumentRefs[],
                       Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value integral;
    Real64Value fractional = ::modf(realValue, &integral);
    Cell elements[4]; // ToDo : use macro instead of 4
    PrimitiveSupport::real64ToCellRef(integral, &elements[0]);
    PrimitiveSupport::real64ToCellRef(fractional, &elements[2]);
    *resultRef =
    PrimitiveSupport::
    tupleElementsToCell(elements, sizeof(elements) / sizeof(elements[0]));
    return;
};

/*
 * real -> real * int
 */
void
IMLPrim_Real_toManExpImpl(UInt32Value argsCount,
                          Cell* argumentRefs[],
                          Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    SInt32Value exp;
    Real64Value man = ::frexp(realValue, &exp);
    Cell elements[4]; // ToDo : use macro instead of 4
    PrimitiveSupport::real64ToCellRef(man, &elements[0]);
    elements[2].sint32 = exp;
    *resultRef =
    PrimitiveSupport::
    tupleElementsToCell(elements, sizeof(elements)/sizeof(elements[0]));
    return;
};

/*
 * real * int -> real
 */
void
IMLPrim_Real_fromManExpImpl(UInt32Value argsCount,
                            Cell* argumentRefs[],
                            Cell* resultRef)
{
    Real64Value man = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    SInt32Value exp = argumentRefs[1]->sint32;
    Real64Value resultValue = ::ldexp(man, exp);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val copySign   : real * real -> real
 */
void
IMLPrim_Real_copySignImpl(UInt32Value argsCount, 
                          Cell* argumentRefs[],
                          Cell* resultRef)
{
    Real64Value realValue1 =
    PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value realValue2 =
    PrimitiveSupport::cellRefToReal64(argumentRefs[1]);
    Real64Value resultValue = ::copysign(realValue1, realValue2);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val equal   : real * real -> bool
 */
void
IMLPrim_Real_equalImpl(UInt32Value argsCount, 
                       Cell* argumentRefs[],
                       Cell* resultRef)
{
    Real64Value realValue1 =
    PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value realValue2 =
    PrimitiveSupport::cellRefToReal64(argumentRefs[1]);
    // bitwise equality
    *resultRef = PrimitiveSupport::boolToCell(realValue1 == realValue2);
    return;
};

/*
 * val class : real -> int
 */
void
IMLPrim_Real_classImpl(UInt32Value argsCount,
                       Cell* argumentRefs[],
                       Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    resultRef->sint32 = IEEEREAL_CLASS(realValue);

    return;
};

/*
 * val class : real -> float
 */
void
IMLPrim_Real_toFloatImpl(UInt32Value argsCount,
                         Cell* argumentRefs[],
                         Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    resultRef->real32 = (Real32Value)realValue;
    return;
};

/*
 * val class : float -> real
 */
void
IMLPrim_Real_fromFloatImpl(UInt32Value argsCount,
                           Cell* argumentRefs[],
                           Cell* resultRef)
{
    Real32Value realValue = argumentRefs[0]->real32;
    Real64Value resultValue = (Real64Value)realValue;
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

Primitive IMLPrim_Real_toString = IMLPrim_Real_toStringImpl;
Primitive IMLPrim_Real_fromInt = IMLPrim_Real_fromIntImpl;
Primitive IMLPrim_Real_floor = IMLPrim_Real_floorImpl;
Primitive IMLPrim_Real_ceil = IMLPrim_Real_ceilImpl;
Primitive IMLPrim_Real_trunc = IMLPrim_Real_truncImpl;
Primitive IMLPrim_Real_round = IMLPrim_Real_roundImpl;
Primitive IMLPrim_Real_split = IMLPrim_Real_splitImpl;
Primitive IMLPrim_Real_toManExp = IMLPrim_Real_toManExpImpl;
Primitive IMLPrim_Real_fromManExp = IMLPrim_Real_fromManExpImpl;
Primitive IMLPrim_Real_copySign = IMLPrim_Real_copySignImpl;
Primitive IMLPrim_Real_equal = IMLPrim_Real_equalImpl;
Primitive IMLPrim_Real_class = IMLPrim_Real_classImpl;
Primitive IMLPrim_Real_toFloat = IMLPrim_Real_toFloatImpl;
Primitive IMLPrim_Real_fromFloat = IMLPrim_Real_fromFloatImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
