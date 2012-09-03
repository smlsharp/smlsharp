/**
 * intinf.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: intinf.h,v 1.2 2008/02/08 05:17:57 katsu Exp $
 */
#ifndef SMLSHARP__INTINF_H__
#define SMLSHARP__INTINF_H__

#include <gmp.h>
#include "value.h"

struct intinf {
	mpz_t value;
};
typedef struct intinf intinf_t;

intinf_t *intinf_alloc(void);
intinf_t *intinf_alloc_with_si(ml_int_t n);
intinf_t *intinf_alloc_with_ui(ml_uint_t n);
intinf_t *intinf_alloc_with_str(const char *str);
intinf_t *intinf_alloc_with(intinf_t *n);

#define intinf_init(v)        mpz_init((v)->value)
#define intinf_get_si(v)      mpz_get_si((v)->value)
#define intinf_get_ui(v)      mpz_get_ui((v)->value)
#define intinf_add(z,x,y)     mpz_add((z)->value, (x)->value, (y)->value)
#define intinf_sub(z,x,y)     mpz_sub((z)->value, (x)->value, (y)->value)
#define intinf_neg(z,x)       mpz_neg((z)->value, (x)->value)
#define intinf_mul(z,x,y)     mpz_mul((z)->value, (x)->value, (y)->value)
#define intinf_div(z,x,y)     mpz_fdiv_q((z)->value, (x)->value, (y)->value)
#define intinf_mod(z,x,y)     mpz_fdiv_r((z)->value, (x)->value, (y)->value)
#define intinf_quot(z,x,y)    mpz_tdiv_q((z)->value, (x)->value, (y)->value)
#define intinf_rem(z,x,y)     mpz_tdiv_r((z)->value, (x)->value, (y)->value)
#define intinf_ior(z,x,y)     mpz_ior((z)->value, (x)->value, (y)->value)
#define intinf_xor(z,x,y)     mpz_xor((z)->value, (x)->value, (y)->value)
#define intinf_and(z,x,y)     mpz_and((z)->value, (x)->value, (y)->value)
#define intinf_com(z,x)       mpz_com((z)->value, (x)->value)
#define intinf_pow(z,x,y)     mpz_pow_ui((z)->value, (x)->value, (y))
#define intinf_log2(z)        mpz_sizeinbase((z)->value, 2)
#define intinf_cmp(x,y)       mpz_cmp((x)->value, (y)->value)

#endif /* SMLSHARP__INTINF_H__ */
