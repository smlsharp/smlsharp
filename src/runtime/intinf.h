/**
 * intinf.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 */
#ifndef SMLSHARP__INTINF_H__
#define SMLSHARP__INTINF_H__

#include <gmp.h>

struct sml_intinf {
	mpz_t value;
};

#define sml_intinf_init(v)       mpz_init((v)->value)
#define sml_intinf_clear(v)      mpz_clear((v)->value)
#define sml_intinf_set(v,s)      mpz_set((v)->value, (s)->value)
#define sml_intinf_set_str(v,s,b) mpz_set_str((v)->value, (s), (b))
#define sml_intinf_set_si(v,n)   mpz_set_si((v)->value, (n))
#define sml_intinf_set_ui(v,n)   mpz_set_ui((v)->value, (n))
#define sml_intinf_set_d(v,n)    mpz_set_d((v)->value, (n))
#define sml_intinf_size(v,b)     mpz_sizeinbase((v)->value, (b))
#define sml_intinf_fmt(v,b)      mpz_get_str(NULL, (b), (v)->value)
#define sml_intinf_get_si(v)     mpz_get_si((v)->value)
#define sml_intinf_get_ui(v)     mpz_get_ui((v)->value)
#define sml_intinf_get_d(v)      mpz_get_d((v)->value)
#define sml_intinf_abs(z,x)      mpz_abs((z)->value, (x)->value)
#define sml_intinf_add(z,x,y)    mpz_add((z)->value, (x)->value, (y)->value)
#define sml_intinf_sub(z,x,y)    mpz_sub((z)->value, (x)->value, (y)->value)
#define sml_intinf_neg(z,x)      mpz_neg((z)->value, (x)->value)
#define sml_intinf_mul(z,x,y)    mpz_mul((z)->value, (x)->value, (y)->value)
#define sml_intinf_div(z,x,y)    mpz_fdiv_q((z)->value, (x)->value, (y)->value)
#define sml_intinf_mod(z,x,y)    mpz_fdiv_r((z)->value, (x)->value, (y)->value)
#define sml_intinf_quot(z,x,y)   mpz_tdiv_q((z)->value, (x)->value, (y)->value)
#define sml_intinf_rem(z,x,y)    mpz_tdiv_r((z)->value, (x)->value, (y)->value)
#define sml_intinf_ior(z,x,y)    mpz_ior((z)->value, (x)->value, (y)->value)
#define sml_intinf_xor(z,x,y)    mpz_xor((z)->value, (x)->value, (y)->value)
#define sml_intinf_and(z,x,y)    mpz_and((z)->value, (x)->value, (y)->value)
#define sml_intinf_com(z,x)      mpz_com((z)->value, (x)->value)
#define sml_intinf_pow(z,x,y)    mpz_pow_ui((z)->value, (x)->value, (y))
#define sml_intinf_log2(z)       (mpz_sizeinbase((z)->value, 2) - 1)
#define sml_intinf_cmp(x,y)      mpz_cmp((x)->value, (y)->value)
#define sml_intinf_sign(x)       mpz_sgn((x)->value)

#endif /* SMLSHARP__INTINF_H__ */
