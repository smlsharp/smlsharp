#ifndef LARGEINT_HH
#define LARGEINT_HH

#ifdef HAVE_GMP_H
#include <gmp.h>
#else
#error ---- SML# requires GMP library ----
#endif

#include "SystemDef.hh"
#include "Debug.hh"

BEGIN_NAMESPACE(jp_ac_jaist_iml_runtime)

///////////////////////////////////////////////////////////////////////////////

class LargeInt
{
  public:

    ///////////////////////////////////////////////////////////////////////////

    typedef mpz_t largeInt;

    ///////////////////////////////////////////////////////////////////////////

    static void init(largeInt x)
    {
        mpz_init(x);
    }

    static void initFromString(largeInt x, const char* str)
    {
        mpz_init_set_str(x, str, 10);
    }

    static void initAndSet(largeInt dest, largeInt src)
    {
        mpz_init_set(dest, src);
    }

    static void initFromInt(largeInt result, signed long x)
    {
        mpz_init_set_si(result, x);
    }

    static void initFromWord(largeInt result, unsigned long x)
    {
        mpz_init_set_ui(result, x);
    }

    static void release(largeInt x)
    {
        mpz_clear(x);
    }

    static void add(largeInt result, largeInt x, largeInt y)
    {
        mpz_add(result, x, y);
    }
    
    static void sub(largeInt result, largeInt x, largeInt y)
    {
        mpz_sub(result, x, y);
    }
    
    static void mul(largeInt result, largeInt x, largeInt y)
    {
        mpz_mul(result, x, y);
    }
    
    static void div(largeInt result, largeInt x, largeInt y)
    {
        mpz_fdiv_q(result, x, y);
    }
    
    static void mod(largeInt result, largeInt x, largeInt y)
    {
        mpz_fdiv_r(result, x, y);
    }
    
    static void quot(largeInt result, largeInt x, largeInt y)
    {
        mpz_tdiv_q(result, x, y);
    }
    
    static void rem(largeInt result, largeInt x, largeInt y)
    {
        mpz_tdiv_r(result, x, y);
    }
    
    static void neg(largeInt result, largeInt x)
    {
        mpz_neg(result, x);
    }
    
    static void abs(largeInt result, largeInt x)
    {
        mpz_abs(result, x);
    }
    
    static int compare(largeInt x, largeInt y)
    {
        return mpz_cmp(x, y);
    }

    static bool lt(largeInt x, largeInt y)
    {
        return (mpz_cmp(x, y) < 0);
    }
    
    static bool gt(largeInt x, largeInt y)
    {
        return (0 < mpz_cmp(x, y));
    }
    
    static bool lteq(largeInt x, largeInt y)
    {
        return (mpz_cmp(x, y) <= 0);
    }
    
    static bool gteq(largeInt x, largeInt y)
    {
        return (0 <= mpz_cmp(x, y));
    }

    static SInt32Value toInt(largeInt x)
    {
        return mpz_get_si(x);
    }

    /**
     * returns the least 32 bits of x in two's complement representation.
     *
     *     x       = x in 2's complement => toWord(x)
     *           1 =       0...000000001 => 00000001
     *  4294967295 =       0...0FFFFFFFF => FFFFFFFF
     *  4294967296 =       0..0100000000 => 00000000
     *          -1 =       F...FFFFFFFFF => FFFFFFFF
     * -4294967295 =       F...F00000001 => 00000001
     * -4294967296 =       F...F00000000 => 00000000
     */
    static UInt32Value toWord(largeInt x)
    {
        UInt32Value result = mpz_get_ui(x);

        /* mpz_get_ui(op) returns the least significant bits of absolute value
         * of "op" but this primitive requires to return the least significant
         * bits of 2's complement form of "op". 
         * For example, mpz_get_ui(-4294967295) returns 4294967295,
         * although we want 1 for this case because -4294967295 is
         * F...F00000001 in two's complement.
         * So we take 2's complement of the return value of mpz_get_ui
         * if "op" is negative.
         */
        if(mpz_sgn(x) < 0){
            result = ~result + 1;
        }

        return result;
    }

    static void toString(largeInt x)
    {
    }

    static void pow(largeInt result, largeInt x, unsigned long y)
    {
        mpz_pow_ui(result, x, y);
    }

    static int log_2(largeInt x)
    {
        /* mpz_sizeinbase returns the bit-width required to represent x.
         * It is log2(x) + 1.
         */
        return mpz_sizeinbase(x, 2) - 1;
    }

    static void orb(largeInt result, largeInt x, largeInt y)
    {
        mpz_ior(result, x, y);
    }
    
    static void xorb(largeInt result, largeInt x, largeInt y)
    {
        mpz_xor(result, x, y);
    }
    
    static void andb(largeInt result, largeInt x, largeInt y)
    {
        mpz_and(result, x, y);
    }
    
    static void notb(largeInt result, largeInt x)
    {
        mpz_com(result, x);
    }
    
    ///////////////////////////////////////////////////////////////////////////

};

///////////////////////////////////////////////////////////////////////////////

END_NAMESPACE

#endif
