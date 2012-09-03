#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <stdio.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

void 
IMLPrim_Float_toStringImpl(UInt32Value argsCount,
                          Cell* argumentRefs[],
                          Cell* resultRef)
{
    Real32Value floatValue = argumentRefs[0]->real32;
    
    char buffer[32];
    sprintf(buffer, "%g", floatValue);
    if('-' == buffer[0]){buffer[0] = '~';}
    *resultRef = PrimitiveSupport::stringToCell(buffer);
    return;
};

void
IMLPrim_Float_floorImpl(UInt32Value argsCount,
                       Cell* argumentRefs[],
                       Cell* resultRef)
{
    Real32Value floatValue = argumentRefs[0]->real32;
    resultRef->sint32 = (SInt32Value)::floor(floatValue);
    return;
};

void
IMLPrim_Float_ceilImpl(UInt32Value argsCount,
                      Cell* argumentRefs[],
                      Cell* resultRef)
{
    Real32Value floatValue = argumentRefs[0]->real32;
    resultRef->sint32 = (SInt32Value)::ceil(floatValue);
    return;
};

void
IMLPrim_Float_truncImpl(UInt32Value argsCount,
                       Cell* argumentRefs[],
                       Cell* resultRef)
{
    Real32Value floatValue = argumentRefs[0]->real32;
    resultRef->sint32 = (SInt32Value)floatValue;
    return;
};

void
IMLPrim_Float_roundImpl(UInt32Value argsCount,
                       Cell* argumentRefs[],
                       Cell* resultRef)
{
    Real32Value floatValue = argumentRefs[0]->real32;
    Real32Value integral;
    Real32Value fraction = ::modff(floatValue, &integral);
    SInt32Value returnValue = (SInt32Value)floatValue;
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
IMLPrim_Float_fromIntImpl(UInt32Value argsCount,
                         Cell* argumentRefs[],
                         Cell* resultRef)
{
    Real32Value floatValue = (Real32Value)(argumentRefs[0]->real32);

    resultRef->real32 = floatValue;
    return;
};

/*
 * float -> float * float
 */
void
IMLPrim_Float_splitImpl(UInt32Value argsCount,
                       Cell* argumentRefs[],
                       Cell* resultRef)
{
    Real32Value floatValue = argumentRefs[0]->real32;
    Real32Value integral;
    Real32Value fractional = ::modff(floatValue, &integral);
    Cell elements[2]; // ToDo : use macro instead of 2
    elements[0].real32 = integral;
    elements[1].real32 = fractional;
    *resultRef =
    PrimitiveSupport::
    tupleElementsToCell(0, elements, sizeof(elements) / sizeof(elements[0]));
    return;
};

/*
 * float -> float * int
 */
void
IMLPrim_Float_toManExpImpl(UInt32Value argsCount,
                          Cell* argumentRefs[],
                          Cell* resultRef)
{
    Real32Value floatValue = argumentRefs[0]->real32;
    SInt32Value exp;
    Real32Value man = ::frexpf(floatValue, &exp);
    Cell elements[2]; // ToDo : use macro instead of 2
    elements[0].real32 = man;
    elements[2].sint32 = exp;
    *resultRef =
    PrimitiveSupport::
    tupleElementsToCell(0, elements, sizeof(elements)/sizeof(elements[0]));
    return;
};

/*
 * float * int -> float
 */
void
IMLPrim_Float_fromManExpImpl(UInt32Value argsCount,
                            Cell* argumentRefs[],
                            Cell* resultRef)
{
    Real32Value man = argumentRefs[0]->real32;
    SInt32Value exp = argumentRefs[1]->sint32;
    Real32Value resultValue = ::ldexpf(man, exp);
    resultRef->real32 = resultValue;
    return;
};

/*
 *    val copySign   : float * float -> float
 */
void
IMLPrim_Float_copySignImpl(UInt32Value argsCount, 
                          Cell* argumentRefs[],
                          Cell* resultRef)
{
    Real32Value floatValue1 = argumentRefs[0]->real32;
    Real32Value floatValue2 = argumentRefs[1]->real32;
    Real32Value resultValue = ::copysignf(floatValue1, floatValue2);
    resultRef->real32 = resultValue;
    return;
};

/*
 *    val equal   : float * float -> bool
 */
void
IMLPrim_Float_equalImpl(UInt32Value argsCount, 
                       Cell* argumentRefs[],
                       Cell* resultRef)
{
    Real32Value floatValue1 = argumentRefs[0]->real32;
    Real32Value floatValue2 = argumentRefs[1]->real32;
    // bitwise equality
    *resultRef = PrimitiveSupport::boolToCell(floatValue1 == floatValue2);
    return;
};

/*
 * val class : float -> int
 */
void
IMLPrim_Float_classImpl(UInt32Value argsCount,
                       Cell* argumentRefs[],
                       Cell* resultRef)
{
    Real32Value floatValue = argumentRefs[0]->real32;
    resultRef->sint32 = IEEEREAL_CLASS((double)floatValue);

    return;
};

Primitive IMLPrim_Float_toString = IMLPrim_Float_toStringImpl;
Primitive IMLPrim_Float_fromInt = IMLPrim_Float_fromIntImpl;
Primitive IMLPrim_Float_floor = IMLPrim_Float_floorImpl;
Primitive IMLPrim_Float_ceil = IMLPrim_Float_ceilImpl;
Primitive IMLPrim_Float_trunc = IMLPrim_Float_truncImpl;
Primitive IMLPrim_Float_round = IMLPrim_Float_roundImpl;
Primitive IMLPrim_Float_split = IMLPrim_Float_splitImpl;
Primitive IMLPrim_Float_toManExp = IMLPrim_Float_toManExpImpl;
Primitive IMLPrim_Float_fromManExp = IMLPrim_Float_fromManExpImpl;
Primitive IMLPrim_Float_copySign = IMLPrim_Float_copySignImpl;
Primitive IMLPrim_Float_equal = IMLPrim_Float_equalImpl;
Primitive IMLPrim_Float_class = IMLPrim_Float_classImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
