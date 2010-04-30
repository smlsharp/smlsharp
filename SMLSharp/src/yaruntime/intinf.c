/**
 * intinf.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: intinf.c,v 1.1 2008/01/23 08:20:07 katsu Exp $
 */

#include <gmp.h>
#include "error.h"
#include "value.h"
#include HEAP_H
#include "intinf.h"

#ifdef HEAP_HAVE_FINALIZER
static void
intinf_free(void *obj, void *data ATTR_UNUSED)
{
	mpz_clear(((intinf_t*)obj)->value);
}
#endif

static intinf_t *
intinf_new()
{
	intinf_t *obj;
	obj = obj_alloc(OBJTYPE_INTINF, sizeof(intinf_t));
#ifdef HEAP_HAVE_FINALIZER
	heap_add_finalizer(obj, intinf_free, NULL);
#else
	warn(0, "Finalizer is not implemented. Memory leak may occur.");
#endif
	return obj;
}

intinf_t *
intinf_alloc()
{
	intinf_t *obj = intinf_new();
	mpz_init(obj->value);
	return obj;
}

intinf_t *
intinf_alloc_with_si(ml_int_t n)
{
	intinf_t *obj = intinf_new();
	mpz_init_set_si(obj->value, n);
	return obj;
}

intinf_t *
intinf_alloc_with_ui(ml_uint_t n)
{
	intinf_t *obj = intinf_new();
	mpz_init_set_ui(obj->value, n);
	return obj;
}

intinf_t *
intinf_alloc_with_str(const char *str)
{
	intinf_t *obj = intinf_new();
	mpz_init_set_str(obj->value, str, 10);
	return obj;
}

intinf_t *
intinf_alloc_with(intinf_t *n)
{
	intinf_t v = *n;  /* save from GC */
	intinf_t *obj = intinf_new();
	mpz_init_set(obj->value, v.value);
	return obj;
}
