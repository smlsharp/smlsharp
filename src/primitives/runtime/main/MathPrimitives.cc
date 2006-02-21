#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

#include <stdio.h>
#include <math.h>

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

/*
 *    val sqrt  : real -> real
 */
void 
IMLPrim_Math_sqrtImpl(UInt32Value argsCount,
                      Cell* argumentRefs[],
                      Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);

    Real64Value resultValue = ::sqrt(realValue);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val sin   : real -> real
 */
void
IMLPrim_Math_sinImpl(UInt32Value argsCount, 
                     Cell* argumentRefs[],
                     Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value resultValue = ::sin(realValue);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val cos   : real -> real
 */
void
IMLPrim_Math_cosImpl(UInt32Value argsCount, 
                     Cell* argumentRefs[],
                     Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value resultValue = ::cos(realValue);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val tan   : real -> real
 */
void
IMLPrim_Math_tanImpl(UInt32Value argsCount, 
                     Cell* argumentRefs[],
                     Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value resultValue = ::tan(realValue);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val asin  : real -> real
 */
void
IMLPrim_Math_asinImpl(UInt32Value argsCount, 
                      Cell* argumentRefs[],
                      Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value resultValue = ::asin(realValue);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val acos  : real -> real
 */
void
IMLPrim_Math_acosImpl(UInt32Value argsCount, 
                      Cell* argumentRefs[],
                      Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value resultValue = ::acos(realValue);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val atan  : real -> real
 */
void
IMLPrim_Math_atanImpl(UInt32Value argsCount, 
                      Cell* argumentRefs[],
                      Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value resultValue = ::atan(realValue);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val atan2 : real * real -> real
 */
void
IMLPrim_Math_atan2Impl(UInt32Value argsCount, 
                       Cell* argumentRefs[],
                       Cell* resultRef)
{
    Real64Value realValue1 = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value realValue2 = PrimitiveSupport::cellRefToReal64(argumentRefs[1]);
    Real64Value resultValue = ::atan2(realValue1, realValue2);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val exp   : real -> real
 */
void
IMLPrim_Math_expImpl(UInt32Value argsCount, 
                     Cell* argumentRefs[],
                     Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value resultValue = ::exp(realValue);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val pow   : real * real -> real
 */
void
IMLPrim_Math_powImpl(UInt32Value argsCount, 
                     Cell* argumentRefs[],
                     Cell* resultRef)
{
    Real64Value realValue1 = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value realValue2 = PrimitiveSupport::cellRefToReal64(argumentRefs[1]);
    Real64Value resultValue = ::pow(realValue1, realValue2);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val ln    : real -> real
 */
void
IMLPrim_Math_lnImpl(UInt32Value argsCount, 
                    Cell* argumentRefs[],
                    Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value resultValue = ::log(realValue);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val log10 : real -> real
 */
void
IMLPrim_Math_log10Impl(UInt32Value argsCount, 
                       Cell* argumentRefs[],
                       Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value resultValue = ::log10(realValue);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val sinh  : real -> real
 */
void
IMLPrim_Math_sinhImpl(UInt32Value argsCount, 
                      Cell* argumentRefs[],
                      Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value resultValue = ::sinh(realValue);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val cosh  : real -> real
 */
void
IMLPrim_Math_coshImpl(UInt32Value argsCount, 
                      Cell* argumentRefs[],
                      Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value resultValue = ::cosh(realValue);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};

/*
 *    val tanh  : real -> real
 */
void
IMLPrim_Math_tanhImpl(UInt32Value argsCount, 
                      Cell* argumentRefs[],
                      Cell* resultRef)
{
    Real64Value realValue = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    Real64Value resultValue = ::tanh(realValue);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    return;
};


Primitive IMLPrim_Math_sqrt = IMLPrim_Math_sqrtImpl;
Primitive IMLPrim_Math_sin = IMLPrim_Math_sinImpl;
Primitive IMLPrim_Math_cos = IMLPrim_Math_cosImpl;
Primitive IMLPrim_Math_tan = IMLPrim_Math_tanImpl;
Primitive IMLPrim_Math_asin = IMLPrim_Math_asinImpl;
Primitive IMLPrim_Math_acos = IMLPrim_Math_acosImpl;
Primitive IMLPrim_Math_atan = IMLPrim_Math_atanImpl;
Primitive IMLPrim_Math_atan2 = IMLPrim_Math_atan2Impl;
Primitive IMLPrim_Math_exp = IMLPrim_Math_expImpl;
Primitive IMLPrim_Math_pow = IMLPrim_Math_powImpl;
Primitive IMLPrim_Math_ln = IMLPrim_Math_lnImpl;
Primitive IMLPrim_Math_log10 = IMLPrim_Math_log10Impl;
Primitive IMLPrim_Math_sinh = IMLPrim_Math_sinhImpl;
Primitive IMLPrim_Math_cosh = IMLPrim_Math_coshImpl;
Primitive IMLPrim_Math_tanh = IMLPrim_Math_tanhImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
