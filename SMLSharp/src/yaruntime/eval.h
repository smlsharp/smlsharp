/*
 * eval.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: eval.h,v 1.5 2008/12/11 10:22:51 katsu Exp $
 */
#ifndef SMLSHARP__EVAL_H__
#define SMLSHARP__EVAL_H__

#include "error.h"
#include "vm.h"

status_t eval32(vm_t *vm);

#define eval32_init()  eval32(NULL)

struct eval_optable {
	const void * const *entry;
	const void *exit_entry;
	const void *abort_entry;
};
extern const struct eval_optable *eval32_optable;

/* arithmetic operations */

/* absolute */

ml_int_t abs_N(ml_int_t);
ml_long_t abs_NL(ml_long_t);
float abs_FS(float);
double abs_F(double);
long double abs_FL(long double);

ml_int_t abso_N(ml_int_t);
ml_long_t abso_NL(ml_long_t);

/* integer arithmetic operations with overflow check */

ml_int_t addo_N(ml_int_t, ml_int_t);
ml_long_t addo_L(ml_long_t, ml_long_t);
ml_int_t subo_N(ml_int_t, ml_int_t);
ml_long_t subo_NL(ml_long_t, ml_long_t);
ml_int_t mulo_N(ml_int_t, ml_int_t);
ml_long_t mulo_NL(ml_long_t, ml_long_t);

/* div and mod : division, rounding to -Inf */

typedef struct {ml_int_t quot, rem;} div_t_N;
typedef struct {ml_long_t quot, rem;} div_t_NL;

div_t_N divmod_N(ml_int_t, ml_int_t);
div_t_NL divmod_NL(ml_long_t, ml_long_t);
div_t_N divmodo_N(ml_int_t, ml_int_t);
div_t_NL divmodo_NL(ml_long_t, ml_long_t);

/* quot and rem : division, rounding to 0 */

div_t_N quotrem_N(ml_int_t, ml_int_t);
div_t_NL quotrem_NL(ml_long_t, ml_long_t);
div_t_N quotremo_N(ml_int_t, ml_int_t);
div_t_NL quotremo_NL(ml_long_t, ml_long_t);

/* shift operations */

ml_int_t rashift_N(ml_int_t, unsigned int);
ml_long_t rashift_NL(ml_long_t, unsigned int);
ml_uint_t rashift_W(ml_uint_t, unsigned int);
ml_ulong_t rashift_L(ml_ulong_t, unsigned int);

#endif /* SMLSHARP__EVAL_H__ */
