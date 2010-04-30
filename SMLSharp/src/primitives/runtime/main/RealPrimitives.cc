#include "config.h"

#include <stdio.h>
#include <errno.h>

#ifdef HAVE_GMP_H
#include <gmp.h>
#else
#error ---- SML# requires GMP library ----
#endif

#include "SystemDef.hh"
#include "Primitives.hh"
#include "PrimitiveSupport.hh"
#include "Log.hh"
#include "Debug.hh"

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
    tupleElementsToCell(0, elements, sizeof(elements) / sizeof(elements[0]));
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
    tupleElementsToCell(0, elements, sizeof(elements)/sizeof(elements[0]));
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
 * val toFloat : real -> float
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
 * val fromFloat : float -> real
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

/*
 * val dtoa : (real * int) -> string * int
 * argument is real and precision.
 * return is string and exponential.
 */
void
IMLPrim_Real_dtoaImpl(UInt32Value argsCount,
                      Cell* argumentRefs[],
                      Cell* resultRef)
{
    mpf_t z;
    mp_exp_t exp;
    char* buf = NULL;
    Cell MLstring;

    Real64Value real = PrimitiveSupport::cellRefToReal64(argumentRefs[0]);
    SInt32Value prec = argumentRefs[1]->sint32;
    DBGWRAP(LOG.debug("dtoa: (%g, %d)", real, prec));

    switch(IEEEREAL_CLASS(real)){
      case IEEEREAL_CLASS_SNAN:
        buf = "nan"; break;
      case IEEEREAL_CLASS_QNAN:
        buf = "nan"; break;
      case IEEEREAL_CLASS_NINF:
        buf = "~inf"; break;
      case IEEEREAL_CLASS_PINF:
        buf = "inf"; break;
      case IEEEREAL_CLASS_NDENORM:
      case IEEEREAL_CLASS_PDENORM:
        break;
      case IEEEREAL_CLASS_NZERO:
        buf = "~0"; break;
      case IEEEREAL_CLASS_PZERO:
        buf = "0"; break;
      case IEEEREAL_CLASS_NNORM:
      case IEEEREAL_CLASS_PNORM:
        break;
    }
    if(buf){
        MLstring = PrimitiveSupport::stringToCell(buf);
        exp = 0;
    }
    else {
        mpf_init_set_d(z, real);
        buf = mpf_get_str((char*)NULL, &exp, 10, prec, z);

        // converts buf from the GMP format to the format of Real.toString.
        if('-' == buf[0]){buf[0] = '~';}
        MLstring = PrimitiveSupport::stringToCell(buf);

        free(buf);// GMP allocates memory by 'malloc'.
        mpf_clear(z);
    }

    Bitmap BITMAP = 0x1; // The first field of tuple is a pointer.
    Cell elements[2];
    elements[0] = MLstring;
    TemporaryRoot root1(&elements[0]);
    elements[1].sint32 = exp;
    *resultRef = PrimitiveSupport::tupleElementsToCell(BITMAP, elements, 2);

    return;
};

/*
 * val strtod : string -> real
 */
void
IMLPrim_Real_strtodImpl(UInt32Value argsCount,
                        Cell* argumentRefs[],
                        Cell* resultRef)
{
    mpf_t z;
    char* buf;
    mp_exp_t exp;

    char* arg = PrimitiveSupport::cellToString(*argumentRefs[0]);
    int argLen = ::strlen(arg);

    /* converts arg from the format of Real.fromString to the format GMP
     * accepts.
     */
    buf = (char*)ALLOCATE_MEMORY(argLen + 1);
    if(0 == buf){
        char* message = ::strerror(errno);
        if(0 == message){message = "memory alloc fail.";}
        Cell exn = PrimitiveSupport::constructExnSysErr(errno, message);
        PrimitiveSupport::raiseException(exn);
        return;
    }

    // copys sign. '+' is ignored.
    int i = 0, j = 0;
    switch(arg[0]){
      case '-': 
      case '~':
        buf[0] = '-'; i = j = 1; break;
      case '+':
        i = 1; break;
    }
    // copys remains. '~' in exp (ex. 2.3E~10) is changed to '-' (ex. 2.3E-10).
    for(; i < argLen; i += 1, j += 1){
        if('~' == arg[i]){buf[j] = '-';}
        else{buf[j] = arg[i];}
    }
    buf[j] = '\0';

    // converts the string to a real.
    mpf_init_set_str(z, buf, 10);
    Real64Value resultValue = (Real64Value)mpf_get_d(z);
    PrimitiveSupport::real64ToCellRef(resultValue, resultRef);
    DBGWRAP(LOG.debug("strtod: arg = [%s], buf = [%s], result = [%f]",
                      arg, buf, resultValue));

    mpf_clear(z);
    RELEASE_MEMORY(buf);

    return;
}

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
Primitive IMLPrim_Real_dtoa = IMLPrim_Real_dtoaImpl;
Primitive IMLPrim_Real_strtod = IMLPrim_Real_strtodImpl;

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE
