/**
 * prim.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: prim.c,v 1.15 2010/01/19 13:12:56 katsu Exp $
 */

#include <limits.h>
#include <string.h>
#include <math.h>
#include "error.h"
#include "env.h"
#include "vm.h"
#include HEAP_H
#include "eval.h"
#include "prim.h"
#include "interact.h"

/* for String primitive */
#include "memory.h"

/* for GenericOS primitive */
#include <unistd.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/times.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <dirent.h>

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#ifdef HAVE_IEEEFP_H
#include <ieeefp.h>
#endif

#ifndef HAVE_ISINF
#ifdef HAVE_FPCLASS
#define isinf(a) (fpclass(a) == FP_NINF || fpclass(a) == FP_PINF)
#else
#error "FIXME: isinf doesn't exist"
#endif /* HAVE_FPCLASS */
#endif /* HAVE_ISINF */

/* for LargeInt primitive */
#include "intinf.h"

/* for DynamicLink primitive */
#include <dlfcn.h>

void *
sml_obj_dup(void *obj)
{
	return obj_dup(obj);
}

ml_int_t
sml_obj_equal(void *obj1, void *obj2)
{
	return obj_equal(obj1, obj2);
}

/*
 * prim String_size : string -> int
 */
ml_int_t
prim_String_size(void *str)
{
	ASSERT(OBJ_TYPE(str) == OBJTYPE_UNBOXED_VECTOR
	       || OBJ_TYPE(str) == OBJTYPE_UNBOXED_ARRAY);
	return (ml_int_t)string_size(str);
}

/*
 * prim String_update : (string, int, char) -> () : has_effect
 */
/* FIXME: use STS instruction */
ml_int_t
prim_String_update(void *str, ml_int_t index, ml_int_t ch)
{
	ASSERT(OBJ_TYPE(str) == OBJTYPE_UNBOXED_ARRAY
	       || OBJ_TYPE(str) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(index >= 0 && (size_t)index < string_size(str));
	((unsigned char*)str)[index] = (unsigned char)ch;
	return 0;
}

/*
 * prim String_sub : (string, int) -> char : has_effect
 */
/* FIXME: use LDS instruction */
ml_uint_t
prim_String_sub(void *str, ml_int_t n)
{
	ASSERT(OBJ_TYPE(str) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(n >= 0 && (size_t)n < string_size(str));
	return (ml_uint_t)(((unsigned char*)str)[n]);
}

/*
 * prim String_substring : (string, int, int) -> string
 */
void *
prim_String_substring(void *str, ml_int_t beg, ml_int_t len)
{
	ASSERT(OBJ_TYPE(str) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(beg >= 0 && len >= 0);
	ASSERT((size_t)(beg + len) <= string_size(str));

	return string_alloc_with(&((char*)str)[beg], len);
}

/*
 * prim StrCmp : (string, string) -> int
 */
ml_int_t
prim_String_cmp(void *str1, void *str2)
{
	ml_int_t len1, len2;

	ASSERT(OBJ_TYPE(str1) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(OBJ_TYPE(str2) == OBJTYPE_UNBOXED_VECTOR);
	len1 = string_size(str1);
	len2 = string_size(str2);

	if (len1 != len2) {
		/* this is OK because both len1 and len2 are signed integer
		 * but never negative. */
		return len1 - len2;
	}
	return memcmp(str1, str2, len1);
}

/*
 * prim Char_toString : char -> string
 */
void *
prim_Char_toString(ml_uint_t ch)
{
	char c[1];
	c[0] = ch;
	return string_alloc_with(c, 1);
}

/*
 * prim String_allocateMutable : (int, char) -> string
 */
/* FIXME: use ALLOC instruction */
void *
prim_String_allocateMutable(ml_int_t len, ml_uint_t ch)
{
	void *obj;
	ASSERT(len >= 0);
	obj = bytearray_alloc(len);
	memset(obj, ch, len);
	return obj;
}

/*
 * prim String_allocateImmutable : (int, char) -> string
 */
/* FIXME: use ALLOC instruction */
void *
prim_String_allocateImmutable(ml_int_t len, ml_uint_t ch)
{
	void *p;
	ASSERT(len >= 0);
	p = string_alloc(len);
	memset(p, ch, len);
	return p;
}

/*
 * prim String_allocateMutableNoInit : word -> string
 */
/* FIXME: use ALLOC instruction */
void *
prim_String_allocateMutableNoInit(ml_uint_t len)
{
	return bytearray_alloc(len);
}

/*
 * prim String_allocateImmutableNoInit : word -> string
 */
/* FIXME: use ALLOC instruction */
void *
prim_String_allocateImmutableNoInit(ml_uint_t len)
{
	return string_alloc(len);
}

/*
 * prim String_copy : (string, int, string, int, int) -> () : has_effect
 */
/* FIXME: use CopyMemory primitive */
ml_int_t
prim_String_copy(void *src, ml_int_t si, void *dst, ml_int_t di, ml_int_t len)
{
	ASSERT(OBJ_TYPE(src) == OBJTYPE_UNBOXED_ARRAY
	       || OBJ_TYPE(src) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(OBJ_TYPE(dst) == OBJTYPE_UNBOXED_ARRAY
	       || OBJ_TYPE(src) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(len >= 0);
	ASSERT(si >= 0 && (size_t)(si + len) <= string_size(src));
	ASSERT(di >= 0 && (size_t)(di + len) <= string_size(dst));

	memcpy(dst + di, src + si, len);
	return 0;
}

static unsigned int
fmt(ml_uint_t value, unsigned int radix, char *buf, unsigned int index)
{
	const char digit[] = "0123456789ABCDEF";

	if (value == 0) {
		buf[--index] = '0';
		return index;
	}
	while (value > 0) {
		buf[--index] = digit[value % radix];
		value /= radix;
	}
	return index;
}

static void *
fmt_int(ml_int_t value, unsigned int radix)
{
	char buf[sizeof(ml_uint_t) * CHAR_BIT + sizeof("~")];
	unsigned int i = sizeof(buf);
	ml_uint_t n;

	/* assume that |INT_MIN| <= UINT_MAX */
	n = (value < 0) ? 0U - (ml_uint_t)value : (ml_uint_t)value;
	i = fmt(n, radix, buf, i);
	if (value < 0)
		buf[--i] = '~';

	return string_alloc_with(&buf[i], sizeof(buf) - i);
}

static void *
fmt_word(ml_uint_t value, unsigned int radix)
{
	char buf[sizeof(ml_uint_t) * CHAR_BIT + sizeof("")];
	unsigned int i = sizeof(buf);

	i = fmt(value, radix, buf, i);
	return string_alloc_with(&buf[i], sizeof(buf) - i);
}

/*
 * prim Int_toString : int -> string
 */
void *
prim_Int_toString(ml_int_t value)
{
	return fmt_int(value, 10);
}

/*
 * prim Word_toString : int -> string
 */
void *
prim_Word_toString(ml_int_t value)
{
	return fmt_word(value, 16);
}

/*
 * prim Real_toString : real -> string
 */
void *
prim_Real_toString(double value)
{
	char buf[32];   /* enough to sprintf "%#.12g" */
	char *p, *p2;

	if (isinf(value))
		return (value < 0)
			? string_alloc_with("~inf", sizeof("~inf") - 1)
			: string_alloc_with("inf", sizeof("inf") - 1);
	if (isnan(value))
		return string_alloc_with("nan", sizeof("nan") - 1);

	sprintf(buf, "%#.12G", value);

	/* replace "-" with "~" */
	for (p = buf; *p == '\0'; p++) {
		if (*p == '-')
			*p = '~';
	}

	/* remove "+" just after "E" */
	if ((p = strchr(buf, 'E')) && p[1] == '+')
		memmove(&p[1], &p[2], sizeof(buf) - 2 - (p - buf));

	/* remove unwanted "0"s */
	if ((p = strchr(buf, '.'))) {
		p += 2;
		p2 = p;
		while (p2 < buf + sizeof(buf) && *p2 == '0')
			p2++;
		if (p != p2)
			memmove(p, p2, sizeof(buf) - (p2 - buf));
	}

	return string_alloc_with(buf, strlen(buf));
}

/*
 * prim Real_floor : real -> int
 */
ml_int_t
prim_Real_floor(double d)
{
	return (ml_int_t)floor(d);
}

/*
 * prim Real_ceil : real -> int
 */
ml_int_t
prim_Real_ceil(double d)
{
	return (ml_int_t)ceil(d);
}

/*
 * prim Real_trunc : real -> int
 */
ml_int_t
prim_Real_trunc(double d)
{
	/* FIXME: C99 */
	return (ml_int_t)trunc(d);
}

/*
 * prim Real_round : real -> int
 */
ml_int_t
prim_Real_round(double d)
{
	/* FIXME: C99 */
	return (ml_int_t)round(d);
}

/* FIXME: move to "missing" */

#ifdef HAVE_IEEEFP_H
#include <ieeefp.h>
#endif

#define IEEEREAL_CLASS_SNAN     0
#define IEEEREAL_CLASS_QNAN     1
#define IEEEREAL_CLASS_NINF     2
#define IEEEREAL_CLASS_PINF     3
#define IEEEREAL_CLASS_NDENORM  4
#define IEEEREAL_CLASS_PDENORM  5
#define IEEEREAL_CLASS_NZERO    6
#define IEEEREAL_CLASS_PZERO    7
#define IEEEREAL_CLASS_NNORM    8
#define IEEEREAL_CLASS_PNORM    9

/*
 * prim Real_class : real -> int
 */
ml_int_t
prim_Real_class(double d)
{
#ifdef HAVE_FPCLASS
	switch(fpclass(d))
	{
	case FP_SNAN:
		return IEEEREAL_CLASS_SNAN;
	case FP_QNAN:
		return IEEEREAL_CLASS_QNAN;
	case FP_NINF:
		return IEEEREAL_CLASS_NINF;
	case FP_PINF:
		return IEEEREAL_CLASS_PINF;
	case FP_NDENORM:
		return IEEEREAL_CLASS_NDENORM;
	case FP_PDENORM:
		return IEEEREAL_CLASS_PDENORM;
	case FP_NZERO:
		return IEEEREAL_CLASS_NZERO;
	case FP_PZERO:
		return IEEEREAL_CLASS_PZERO;
	case FP_NNORM:
		return IEEEREAL_CLASS_NNORM;
	case FP_PNORM:
		return IEEEREAL_CLASS_PNORM;
	default:
		fatal(0, "unknown fpclass");
	}
#else /* HAVE_FPCLASS */
	if(isnan(d))
		return IEEEREAL_CLASS_SNAN;
	if(isinf(d))
		return (d < 0.0) ? IEEEREAL_CLASS_NINF : IEEEREAL_CLASS_PINF;
	if(d == 0.0)
		return IEEEREAL_CLASS_PZERO;
	return (d < 0.0) ? IEEEREAL_CLASS_NNORM : IEEEREAL_CLASS_PNORM;
#endif /* HAVE_FPCLASS */
}

/*
 * prim ya_Real_modf : real * real ref -> real
double
prim_Real_modf(double d, void *iptr)
{
	ASSERT(OBJ_TYPE(iptr) == OBJTYPE_UNBOXED_ARRAY);
	return modf(d, iptr);
}
 */

/*
 * prim ya_Real_frexp : real * int ref -> real
double
prim_Real_frexp(double d, void *exp)
{
	int iexp;
	double man;

	ASSERT(OBJ_TYPE(exp) == OBJTYPE_UNBOXED_ARRAY);
	man = frexp(d, &iexp);
	*(ml_int_t*)exp = iexp;
	return man;
}
 */

/*
 * prim Real_fromManExp : real * int -> real
double
prim_Real_fromManExp(double man, ml_int_t exp)
{
	return ldexp(man, exp);
}
 */

/*
 * prim Real_dtoa : (real, int) -> string * int
void *
prim_Real_dtoa(double d, ml_int_t precision)
{
	/ * FIXME: stub * /
	struct ret { void *str; ml_int_t n; } *obj;
	obj = record_alloc(sizeof(struct ret));
	OBJ_BITMAP(obj)[0] = 0x1;
	obj->str = string_alloc_with("0", 1);
	obj->n = 0;
	return obj;
}
 */
void
sml_freedtoa(char *ptr ATTR_UNUSED)
{
}

char *
sml_dtoa(double d ATTR_UNUSED, int mode ATTR_UNUSED, int ndigits ATTR_UNUSED,
	 int *decpt, int *sign, char **rve ATTR_UNUSED)
{
	*decpt = 1;
	*sign = 0;
	return string_alloc_with("0", 1);
}

/*
 * prim Real_strtod : string -> real
double
prim_Real_strtod(void *str)
{
	ASSERT(OBJ_TYPE(str) == OBJTYPE_UNBOXED_VECTOR);
	return strtod(str, NULL);
}
 */
double
sml_strtod(void *str, char **ref)
{
	ASSERT(OBJ_TYPE(str) == OBJTYPE_UNBOXED_VECTOR);
	return strtod(str, ref);
}

/*
 * prim LargeInt_toString : largeInt -> string
 */
void *
prim_IntInf_toString(void *obj ATTR_UNUSED)
{
	/* FIXME: stub */
	ASSERT(OBJ_TYPE(obj) == OBJTYPE_INTINF);
	return string_alloc(0);
}

/*
 * prim LargeInt_toInt : largeInt -> int
 */
ml_int_t
prim_IntInf_toInt(void *obj)
{
	ASSERT(OBJ_TYPE(obj) == OBJTYPE_INTINF);
	return intinf_get_si((intinf_t*)obj);
}

/*
 * prim LargeInt_toWord : largeInt -> word
 */
ml_uint_t
prim_IntInf_toWord(void *obj)
{
	ASSERT(OBJ_TYPE(obj) == OBJTYPE_INTINF);
	return intinf_get_si((intinf_t*)obj);
}

/*
 * prim LargeInt_fromInt : int -> largeInt
 */
void *
prim_IntInf_fromInt(ml_int_t x)
{
	return intinf_alloc_with_si(x);
}

/*
 * prim LargeInt_fromWord : word -> largeInt
 */
void *
prim_IntInf_fromWord(ml_uint_t x)
{
	return intinf_alloc_with_ui(x);
}

/*
 * prim loadIntInf : string -> largeInt
 */
void *
prim_IntInf_load(void *src)
{
	ASSERT(OBJ_TYPE(src) == OBJTYPE_UNBOXED_VECTOR);
	return intinf_alloc_with_str(src);
}

/*
 * prim addLargeInt : (largeInt, largeInt) -> largeInt
 */
void *
prim_IntInf_add(void *x, void *y)
{
	intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *(intinf_t*)x, yv = *(intinf_t*)y;
	z = intinf_alloc();
	intinf_add(z, &xv, &yv);
	return z;
}

/*
 * prim subLargeInt : (largeInt, largeInt) -> largeInt
 */
void *
prim_IntInf_sub(void *x, void *y)
{
	intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *(intinf_t*)x, yv = *(intinf_t*)y;
	z = intinf_alloc();
	intinf_sub(z, &xv, &yv);
	return z;
}

/*
 * prim negLargeInt : largeInt -> largeInt
 */
void *
prim_IntInf_neg(void *x)
{
	intinf_t xv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);

	xv = *(intinf_t*)x;
	z = intinf_alloc();
	intinf_neg(z, &xv);
	return z;
}

/*
 * prim mulLargeInt : (largeInt, largeInt) -> largeInt
 */
void *
prim_IntInf_mul(void *x, void *y)
{
	intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *(intinf_t*)x, yv = *(intinf_t*)y;
	z = intinf_alloc();
	intinf_mul(z, &xv, &yv);
	return z;
}

/*
 * prim divLargeInt : (largeInt, largeInt) -> largeInt
 */
void *
prim_IntInf_div(void *x, void *y)
{
	intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *(intinf_t*)x, yv = *(intinf_t*)y;
	z = intinf_alloc();
	intinf_div(z, &xv, &yv);
	return z;
}

/*
 * prim modLargeInt : (largeInt, largeInt) -> largeInt
 */
void *
prim_IntInf_mod(void *x, void *y)
{
	intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *(intinf_t*)x, yv = *(intinf_t*)y;
	z = intinf_alloc();
	intinf_mod(z, &xv, &yv);
	return z;
}

/*
 * prim quotLargeInt : (largeInt, largeInt) -> largeInt
 */
void *
prim_IntInf_quot(void *x, void *y)
{
	intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *(intinf_t*)x, yv = *(intinf_t*)y;
	z = intinf_alloc();
	intinf_quot(z, &xv, &yv);
	return z;
}

/*
 * prim remLargeInt : (largeInt, largeInt) -> largeInt
 */
void *
prim_IntInf_rem(void *x, void *y)
{
	intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *(intinf_t*)x, yv = *(intinf_t*)y;
	z = intinf_alloc();
	intinf_rem(z, &xv, &yv);
	return z;
}

/*
 * prim intInfCmp : (largeInt, largeInt) -> int
 */
int
prim_IntInf_cmp(void *x, void *y)
{
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);
	return intinf_cmp((intinf_t*)x, (intinf_t*)y);
}

/*
 * prim LargeInt_orb : (largeInt, largeInt) -> largeInt
 */
void *
prim_IntInf_orb(void *x, void *y)
{
	intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *(intinf_t*)x, yv = *(intinf_t*)y;
	z = intinf_alloc();
	intinf_ior(z, &xv, &yv);
	return z;
}

/*
 * prim LargeInt_xorb : (largeInt, largeInt) -> largeInt
 */
void *
prim_IntInf_xorb(void *x, void *y)
{
	intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *(intinf_t*)x, yv = *(intinf_t*)y;
	z = intinf_alloc();
	intinf_xor(z, &xv, &yv);
	return z;
}

/*
 * prim LargeInt_andb : (largeInt, largeInt) -> largeInt
 */
void *
prim_IntInf_andb(void *x, void *y)
{
	intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *(intinf_t*)x, yv = *(intinf_t*)y;
	z = intinf_alloc();
	intinf_and(z, &xv, &yv);
	return z;
}

/*
 * prim LargeInt_notb : largeInt -> largeInt
 */
void *
prim_IntInf_notb(void *x)
{
	intinf_t xv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);

	xv = *(intinf_t*)x;
	z = intinf_alloc();
	intinf_com(z, &xv);
	return z;
}

/*
 * prim LargeInt_pow : (largeInt, int) -> largeInt
 */
void *
prim_IntInf_pow(void *x, ml_int_t e)
{
	intinf_t xv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(e >= 0);

	xv = *(intinf_t*)x;
	z = intinf_alloc();
	intinf_pow(z, &xv, e);
	return z;
}

/*
 * prim LargeInt_log2 : largeInt -> int
 */
ml_int_t
prim_IntInf_log2(void *x)
{
	intinf_t xv;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);

	xv = *(intinf_t*)x;
	return intinf_log2(&xv);
}

/*
 * prim ya_Time_gettimeofday : int array -> int
 */
ml_int_t
prim_Time_gettimeofday(void *p)
{
	ml_uint_t *ret = p;
	struct timeval tv;
	int err;

	ASSERT(OBJ_TYPE(ret) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(OBJ_SIZE(ret) >= sizeof(ml_int_t) * 2);

	err = gettimeofday(&tv, NULL);
	ret[0] = tv.tv_sec;
	ret[1] = tv.tv_usec;
	return err;
}

/*
 * prim ya_Timer_getTimes : int array -> int
 */
ml_int_t
prim_Timer_getTimes(void *p)
{
	ml_int_t *ret = p;
	struct tms tms;
	static long clocks_per_sec = 0;
	clock_t clk;

	ASSERT(OBJ_TYPE(ret) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(OBJ_SIZE(ret) >= sizeof(ml_int_t) * 6);

	if (clocks_per_sec == 0)
		clocks_per_sec = sysconf(_SC_CLK_TCK);

	clk = times(&tms);
	ret[0] = tms.tms_stime / clocks_per_sec;
	ret[1] = (tms.tms_stime % clocks_per_sec) * 1000000 / clocks_per_sec;
	ret[2] = tms.tms_utime / clocks_per_sec;
	ret[3] = (tms.tms_utime % clocks_per_sec) * 1000000 / clocks_per_sec;
	/* FIXME: do we put GC time still here? */
	ret[4] = 0;  /* GC seconds */
	ret[5] = 0;  /* GC microseconds */

	return (clk == (clock_t)-1 ? -1 : 0);
}

/*
 * prim ya_DynamicLink_dlopen : string -> unit ptr : has_effect
 */
void *
prim_DynamicLink_dlopen(void *filename)
{
	ASSERT(OBJ_TYPE(filename) == OBJTYPE_UNBOXED_VECTOR);
	return dlopen(filename, RTLD_LAZY | RTLD_LOCAL);
}

/*
 * prim ya_DynamicLink_dlclose : unit ptr -> int : has_effect
 */
ml_int_t
prim_DynamicLink_dlclose(void *libhandle)
{
	return dlclose(libhandle);
}

/*
 * prim ya_DynamicLink_dlsym : (unit ptr, string) -> unit ptr : has_effect
 */
void *
prim_DynamicLink_dlsym(void *libhandle, void *symname)
{
	ASSERT(OBJ_TYPE(symname) == OBJTYPE_UNBOXED_VECTOR);
	return dlsym(libhandle, symname);
}

/*
 * prim ya_DynamicLink_dlerror : () -> string : has_effect
 */
void *
prim_DynamicLink_dlerror(ml_int_t unit ATTR_UNUSED)
{
	const char *msg;
	msg = dlerror();
	return string_alloc_with(msg, strlen(msg));
}

/*
 * builtin PolyEqual : [''a . (''a, ''a) -> bool] : private
 */
void
builtin_PolyEqual(vm_t *vm)
{
	void *arg1 = vm->rt->ffiarg[0];
	void *arg2 = vm->rt->ffiarg[1];
	ml_int_t size = *(ml_int_t*)vm->rt->ffiarg[2];
	ml_int_t tag = *(ml_int_t*)vm->rt->ffiarg[3];
	ml_int_t ret;

	if (tag != TAG_UNBOXED)
		ret = obj_equal(*(void**)arg1, *(void**)arg2);
	else if (size == 4)
		ret = (*(uint32_t*)arg1 == *(uint32_t*)arg2);
	else if (size == 8)
		ret = (*(uint64_t*)arg1 == *(uint64_t*)arg2);
	else
		ret = (memcmp(arg1, arg2, size) == 0);

	*(ml_int_t*)vm->rt->ffiarg[0] = ret;
}

/*
 * prim StandardC_errno : () -> int
 */
ml_int_t
prim_StandardC_errno(ml_int_t unit ATTR_UNUSED)
{
	return errno;
}

/*
 * prim StandardC_strerror : int -> string
 */
void *
prim_StandardC_strerror(ml_int_t errnum)
{
	const char *errmsg;

	errmsg = strerror(errnum);
	return string_alloc_with(errmsg, strlen(errmsg));
}

static struct {
	int errnum;
	const char *name;
} sys_errors[] = {
#ifdef EACCES
	{EACCES, "acces"},
#endif
#ifdef EAGAIN
	{EAGAIN, "again"},
#endif
#ifdef EBADF
	{EBADF, "badf"},
#endif
#ifdef EBADMSG
	{EBADMSG, "badmsg"},
#endif
#ifdef EBUSY
	{EBUSY, "busy"},
#endif
#ifdef ECANCELED
	{ECANCELED, "canceled"},
#endif
#ifdef ECHILD
	{ECHILD, "child"},
#endif
#ifdef EDEADLK
	{EDEADLK, "deadlk"},
#endif
#ifdef EDOM
	{EDOM, "dom"},
#endif
#ifdef EEXIST
	{EEXIST, "exist"},
#endif
#ifdef EFAULT
	{EFAULT, "fault"},
#endif
#ifdef EFBIG
	{EFBIG, "fbig"},
#endif
#ifdef EINPROGRESS
	{EINPROGRESS, "inprogress"},
#endif
#ifdef EINTR
	{EINTR, "intr"},
#endif
#ifdef EINVAL
	{EINVAL, "inval"},
#endif
#ifdef EIO
	{EIO, "io"},
#endif
#ifdef EISDIR
	{EISDIR, "isdir"},
#endif
#ifdef ELOOP
	{ELOOP, "loop"},
#endif
#ifdef EMFILE
	{EMFILE, "mfile"},
#endif
#ifdef EMLINK
	{EMLINK, "mlink"},
#endif
#ifdef EMSGSIZE
	{EMSGSIZE, "msgsize"},
#endif
#ifdef ENAMETOOLONG
	{ENAMETOOLONG, "nametoolong"},
#endif
#ifdef ENFILE
	{ENFILE, "nfile"},
#endif
#ifdef ENODEV
	{ENODEV, "nodev"},
#endif
#ifdef ENOENT
	{ENOENT, "noent"},
#endif
#ifdef ENOEXEC
	{ENOEXEC, "noexec"},
#endif
#ifdef ENOLCK
	{ENOLCK, "nolck"},
#endif
#ifdef ENOMEM
	{ENOMEM, "nomem"},
#endif
#ifdef ENOSPC
	{ENOSPC, "nospc"},
#endif
#ifdef ENOSYS
	{ENOSYS, "nosys"},
#endif
#ifdef ENOTDIR
	{ENOTDIR, "notdir"},
#endif
#ifdef ENOTEMPTY
	{ENOTEMPTY, "notempty"},
#endif
#ifdef ENOTSUP
	{ENOTSUP, "notsup"},
#endif
#ifdef ENOTTY
	{ENOTTY, "notty"},
#endif
#ifdef ENXIO
	{ENXIO, "nxio"},
#endif
#ifdef EPERM
	{EPERM, "perm"},
#endif
#ifdef EPIPE
	{EPIPE, "pipe"},
#endif
#ifdef ERANGE
	{ERANGE, "range"},
#endif
#ifdef EROFS
	{EROFS, "rofs"},
#endif
#ifdef ESPIPE
	{ESPIPE, "spipe"},
#endif
#ifdef ESRCH
	{ESRCH, "srch"},
#endif
#ifdef E2BIG
	{E2BIG, "toobig"},
#endif
#ifdef EXDEV
	{EXDEV, "xdev"},
#endif
};

/*
 * prim GenericOS_errorName : int -> string
 */
void *
prim_GenericOS_errorName(ml_int_t errnum)
{
	unsigned int i;
	const char *name = "unknown";

	for (i = 0; i < arraysize(sys_errors); i++) {
		if (sys_errors[i].errnum == errnum) {
			name = sys_errors[i].name;
			break;
		}
	}
	return string_alloc_with(name, strlen(name));
}

/*
 * prim ya_GenericOS_syserror : string -> int
 */
ml_int_t
prim_GenericOS_syserror(void *errorname)
{
	unsigned int i;
	int errnum = -1;

	ASSERT(OBJ_TYPE(errorname) == OBJTYPE_UNBOXED_VECTOR);

	for (i = 0; i < arraysize(sys_errors); i++) {
		if (strcmp(errorname, sys_errors[i].name) == 0) {
			errnum = sys_errors[i].errnum;
			break;
		}
	}
	return errnum;
}

/*
 * prim GenericOS_exit : int -> () : has_effect
 */
ml_int_t
prim_GenericOS_exit(ml_int_t status)
{
	/* FIXME: finalization is needed? */
	if (interactive_mode)
		return interact_prim_exit(status);
	else
		exit(status);
}

/*
 * prim GenericOS_sleep : int -> () : has_effect
 */
ml_int_t
prim_GenericOS_sleep(ml_uint_t sec)
{
	sleep(sec);
	return 0;
}

static void
puts_posix(int fd, const char *buf, size_t len)
{
	ssize_t n;

	while (len > 0) {
		n = write(fd, buf, len);
		if (n < 0) {
			if (errno == EINTR)
				continue;
			/* give up. */
			return;
		}
		buf += n;
		len -= n;
	}
}

/*
 * prim print : string -> () : has_effect
 */
ml_int_t
prim_print(void *str)
{
	ASSERT(OBJ_TYPE(str) == OBJTYPE_UNBOXED_VECTOR);
	if (interactive_mode)
		interact_prim_print(str);
	else
		puts_posix(1, str, string_size(str));
	return 0;
}

/*
 * prim printerr : string -> () : has_effect
 */
/* for debug */
int debug_printerrcount = 0;
ml_int_t
prim_printerr(void *str)
{
	ASSERT(OBJ_TYPE(str) == OBJTYPE_UNBOXED_VECTOR);

	debug_printerrcount++;

	if (interactive_mode)
		interact_prim_printerr(str);
	else
		puts_posix(2, str, string_size(str));

	return 0;
}

/*
 * prim ya_GenericOS_open : (string, string) -> int : has_effect
 */
ml_int_t
prim_GenericOS_open(void *filename, void *fmode)
{
	const char *str;
	int flags, subflags;

	ASSERT(OBJ_TYPE(filename) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(OBJ_TYPE(fmode) == OBJTYPE_UNBOXED_VECTOR);

	str = fmode;
	switch (*(str++)) {
	case 'r':
		flags = O_RDONLY, subflags = 0;
		break;
	case 'w':
		flags = O_WRONLY, subflags = O_TRUNC | O_CREAT;
		break;
	case 'a':
		flags = O_WRONLY, subflags = O_APPEND | O_CREAT;
		break;
	default:
		errno = EINVAL;
		return -1;
	}

	if (*str == 'b') {
#ifdef O_BINARY
		subflags |= O_BINARY;
#endif
		str++;
	}

	if (*str == '+') {
		flags = O_RDWR;
		str++;
	}
#ifdef O_BINARY
	if (*str == 'b')
		subflags |= O_BINARY;
#endif

	return open(filename, flags | subflags, 0777);
}

/*
 * prim ya_GenericOS_read : (int, byteArray, word, word) -> int : has_effect
 */
ml_int_t
prim_GenericOS_read(ml_int_t fd, void *buf, ml_uint_t offset, ml_uint_t len)
{
	ASSERT(OBJ_TYPE(buf) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(offset + len <= OBJ_SIZE(buf));

	if (interactive_mode && fd == 0)
		return interact_prim_read(fd, buf, offset, len);
	else
		return read(fd, buf + offset, len);
}

/*
 * prim ya_GenericOS_write : (int, byteArray, word, word) -> int : has_effect
 */
ml_int_t
prim_GenericOS_write(ml_int_t fd, void *buf, ml_uint_t offset, ml_uint_t len)
{
	ASSERT(OBJ_TYPE(buf) == OBJTYPE_UNBOXED_ARRAY
	       || OBJ_TYPE(buf) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(offset + len <= OBJ_SIZE(buf));

	if (interactive_mode && (fd == 1 || fd == 2))
		return interact_prim_write(fd, buf, offset, len);
	else
		return write(fd, buf + offset, len);
}

/*
 * prim ya_GenericOS_lseek : (int, int, int) -> int : has_effect
 */
ml_int_t
prim_GenericOS_lseek(ml_int_t fd, ml_int_t offset, ml_int_t whence)
{
	return lseek(fd, offset, whence);
}

/*
 * prim ya_GenericOS_lseekSet : (int, int) -> int : has_effect
ml_int_t
prim_GenericOS_lseekSet(ml_int_t fd, ml_int_t offset)
{
	return lseek(fd, offset, SEEK_SET);
}
 */

/*
 * prim ya_GenericOS_lseekCur : (int, int) -> int : has_effect
ml_int_t
prim_GenericOS_lseekCur(ml_int_t fd, ml_int_t offset)
{
	return lseek(fd, offset, SEEK_CUR);
}
 */


#define ML_S_IFIFO  0x1000
#define ML_S_IFCHR  0x2000
#define ML_S_IFDIR  0x4000
#define ML_S_IFBLK  0x6000
#define ML_S_IFREG  0x8000
#define ML_S_IFLNK  0xa000
#define ML_S_IFSOCK 0xc000
#define ML_S_ISUID  0x0800
#define ML_S_ISGID  0x0400
#define ML_S_ISVTX  0x0200
#define ML_S_IRUSR  0x0100
#define ML_S_IWUSR  0x0080
#define ML_S_IXUSR  0x0040

static void
set_stat(struct stat *st, ml_uint_t *ret)
{
	ASSERT(OBJ_TYPE(ret) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(OBJ_SIZE(ret) >= sizeof(ml_uint_t) * 6);

	ret[0] = st->st_dev;
	ret[1] = st->st_ino;
	ret[3] = st->st_atime;
	ret[4] = st->st_mtime;
	ret[5] = st->st_size;

#if S_IFIFO == ML_S_IFIFO \
	&& S_IFCHR == ML_S_IFCHR \
	&& S_IFDIR == ML_S_IFDIR \
	&& S_IFBLK == ML_S_IFBLK \
	&& S_IFREG == ML_S_IFREG \
	&& S_IFLNK == ML_S_IFLNK \
	&& S_IFSOCK == ML_S_IFSOCK \
	&& S_ISUID == ML_S_ISUID \
	&& S_ISGID == ML_S_ISGID \
	&& S_ISVTX == ML_S_ISVTX \
	&& S_IRUSR == ML_S_IRUSR \
	&& S_IWUSR == ML_S_IWUSR \
	&& S_IXUSR == ML_S_IXUSR
	ret[2] = st->st_mode;
#else
	{
		ml_uint_t mode = 0;
		mode |= (st->st_mode & S_IFIFO) ? ML_S_IFIFO : 0;
		mode |= (st->st_mode & S_IFCHR) ? ML_S_IFCHR : 0;
		mode |= (st->st_mode & S_IFDIR) ? ML_S_IFDIR : 0;
		mode |= (st->st_mode & S_IFBLK) ? ML_S_IFBLK : 0;
		mode |= (st->st_mode & S_IFREG) ? ML_S_IFREG : 0;
		mode |= (st->st_mode & S_IFLNK) ? ML_S_IFLNK : 0;
		mode |= (st->st_mode & S_IFSOCK) ? ML_S_IFSOCK : 0;
		mode |= (st->st_mode & S_ISUID) ? ML_S_ISUID : 0;
		mode |= (st->st_mode & S_ISGID) ? ML_S_ISGID : 0;
		mode |= (st->st_mode & S_ISVTX) ? ML_S_ISVTX : 0;
		mode |= (st->st_mode & S_IRUSR) ? ML_S_IRUSR : 0;
		mode |= (st->st_mode & S_IWUSR) ? ML_S_IWUSR : 0;
		mode |= (st->st_mode & S_IXUSR) ? ML_S_IXUSR : 0;
		ret[2] = mode;
	}
#endif
}

/*
 * prim ya_GenericOS_fstat : (int, word array) -> int : has_effect
 */
ml_int_t
prim_GenericOS_fstat(ml_int_t fd, void *ret)
{
	int err;
	struct stat st;

	err = fstat(fd, &st);
	if (err == 0)
		set_stat(&st, ret);
	return err;
}

/*
 * prim ya_GenericOS_stat : (string, word array) -> int : has_effect
 */
ml_int_t
prim_GenericOS_stat(void *filename, void *ret)
{
	int err;
	struct stat st;

	err = stat(filename, &st);
	if (err == 0)
		set_stat(&st, ret);
	return err;
}

/*
 * prim ya_GenericOS_utime : (string, word, word) -> int : has_effect
 */
ml_int_t
prim_GenericOS_utime(void *filename, ml_uint_t atime, ml_uint_t mtime)
{
	struct timeval times[2];

	/* FIXME: untested */
	ASSERT(OBJ_TYPE(filename) == OBJTYPE_UNBOXED_VECTOR);
	times[0].tv_sec = atime;
	times[0].tv_usec = 0;
	times[1].tv_sec = mtime;
	times[1].tv_usec = 0;
	return utimes(filename, times);
}

/*
 * prim ya_GenericOS_remove : string -> int : has_effect
 */
ml_int_t
prim_GenericOS_remove(void *filename)
{
	/* FIXME: untested */
	ASSERT(OBJ_TYPE(filename) == OBJTYPE_UNBOXED_VECTOR);
	return remove(filename);
}

/*
 * prim ya_GenericOS_rename : (string, string) -> int : has_effect
ml_int_t
prim_GenericOS_rename(void *filename, void *newfilename)
{
	/ * FIXME: untested * /
	ASSERT(OBJ_TYPE(filename) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(OBJ_TYPE(newfilename) == OBJTYPE_UNBOXED_VECTOR);
	return rename(filename, newfilename);
}
*/

/*
 * prim ya_GenericOS_readlink : string -> string : has_effect
 */
void *
prim_GenericOS_readlink(void *filename)
{
	char buf[128], *p;
	ssize_t n, len;
	void *obj;

	ASSERT(OBJ_TYPE(filename) == OBJTYPE_UNBOXED_VECTOR);

	n = readlink(filename, buf, sizeof(buf));
	if (n < 0)
		return NULL;
	if ((size_t)n < sizeof(buf))
		return string_alloc_with(buf, n);

	p = NULL;
	for (len = sizeof(buf); n >= len; len *= 2) {
		p = xrealloc(p, len);
		n = readlink(filename, buf, len);
	}

	if (n < 0) {
		free(p);
		return NULL;
	}
	obj = string_alloc_with(buf, n);
	free(p);
	return obj;
}

/*
 * prim ya_GenericOS_tmpnam : unit -> string : has_effect
 */
void *
prim_GenericOS_tmpnam(ml_int_t unit ATTR_UNUSED)
{
	char *str;

	/* FIXME: untested */
	str = tmpnam(NULL);
	if (str == NULL)
		return NULL;
	return string_alloc_with(str, strlen(str));
}

/*
 * prim ya_GenericOS_chdir : string -> int : has_effect
 */
ml_int_t
prim_GenericOS_chdir(void *dirname)
{
	ASSERT(OBJ_TYPE(dirname) == OBJTYPE_UNBOXED_VECTOR);
	if (interactive_mode)
		return interact_prim_chdir(dirname);
	else
		return chdir(dirname);
}

/*
 * prim ya_GenericOS_mkdir : string -> int : has_effect
 */
ml_int_t
prim_GenericOS_mkdir(void *dirname)
{
	ASSERT(OBJ_TYPE(dirname) == OBJTYPE_UNBOXED_VECTOR);
	return mkdir(dirname, 0777);
}

/*
 * prim ya_GenericOS_rmdir : string -> int : has_effect
 */
ml_int_t
prim_GenericOS_rmdir(void *dirname)
{
	ASSERT(OBJ_TYPE(dirname) == OBJTYPE_UNBOXED_VECTOR);
	return rmdir(dirname);
}

/*
 * prim ya_GenericOS_getcwd : unit -> string : has_effect
 */
void *
prim_GenericOS_getcwd(ml_int_t unit ATTR_UNUSED)
{
	char *pwd;
	void *obj;

	pwd = getcwd(NULL, 0);
	obj = string_alloc_with(pwd, strlen(pwd));
	free(pwd);
	return obj;
}

/*
 * prim ya_GenericOS_opendir : string -> unit ptr : has_effect
 */
void *
prim_GenericOS_opendir(void *dirname)
{
	/* FIXME: untested */
	ASSERT(OBJ_TYPE(dirname) == OBJTYPE_UNBOXED_VECTOR);
	return opendir(dirname);
}

/*
 * prim ya_GenericOS_readdir : unit ptr -> string : has_effect
 */
void *
prim_GenericOS_readdir(void *dirhandle)
{
	struct dirent *ent;

	/* FIXME: untested */
	ent = readdir(dirhandle);
	if (ent == NULL)
		return NULL;
	return string_alloc_with(ent->d_name, strlen(ent->d_name));
}

/*
 * prim ya_GenericOS_rewinddir : unit ptr -> unit : has_effect
 */
ml_int_t
prim_GenericOS_rewinddir(void *dirhandle)
{
	/* FIXME: untested */
	rewinddir(dirhandle);
	return 0;
}

/*
 * prim ya_GenericOS_closedir : unit ptr -> int : has_effect
 */
ml_int_t
prim_GenericOS_closedir(void *dirhandle)
{
	/* FIXME: untested */
	return closedir(dirhandle);
}

/*
 * prim ya_GenericOS_select : (int array, int array, int array, int, int) -> int : has_effect
 */
ml_int_t
prim_GenericOS_select(void *infdary, void *outfdary, void *prifdary,
		      ml_int_t timeout_sec, ml_int_t timeout_usec)
{
	fd_set infds, outfds, prifds;
	struct timeval timeout;
	unsigned int i;
	int nfds, err;

	/* FIXME: untested */
	ASSERT(OBJ_TYPE(infdary) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(OBJ_TYPE(outfdary) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(OBJ_TYPE(prifdary) == OBJTYPE_UNBOXED_ARRAY);

	FD_ZERO(&infds);
	FD_ZERO(&outfds);
	FD_ZERO(&prifds);

	nfds = 0;

#define SET_FDS(fdary, fds) \
	for (i = 0; i < OBJ_SIZE(fdary) / sizeof(ml_int_t); i++) { \
		int fd__ = ((ml_int_t*)(fdary))[i]; \
		FD_SET(fd__, fds); \
		if (nfds < fd__) nfds = fd__; \
	}

	SET_FDS(infdary, &infds);
	SET_FDS(outfdary, &outfds);
	SET_FDS(prifdary, &prifds);
	nfds++;

#undef SET_FDS

	if (timeout_sec < 0 || timeout_usec < 0) {
		err = select(nfds, &infds, &outfds, &prifds, NULL);
	} else {
		timeout.tv_sec = timeout_sec;
		timeout.tv_usec = timeout_usec;
		err = select(nfds, &infds, &outfds, &prifds, &timeout);
	}

	if (err < 0)
		return err;

#define GET_FDS(fds, fdary) \
	for (i = 0; i < OBJ_SIZE(fds) / sizeof(ml_int_t); i++) { \
		if (!FD_ISSET(((ml_int_t*)(fdary))[i], fds)) \
			((ml_int_t*)(fdary))[i] = -1; \
	}

	GET_FDS(&infds, infdary);
	GET_FDS(&outfds, outfdary);
	GET_FDS(&prifds, prifdary);

#undef GET_FDS

	return err;
}

/*
 * prim ya_GenericOS_system : string -> int : has_effect
 */
ml_int_t
prim_GenericOS_system(void *command)
{
	ASSERT(OBJ_TYPE(command) == OBJTYPE_UNBOXED_VECTOR);
	return system(command);
}

/*
 * prim ya_GenericOS_getenv : string -> string : has_effect
 */
void *
prim_GenericOS_getenv(void *varname)
{
	char *str;
	ASSERT(OBJ_TYPE(varname) == OBJTYPE_UNBOXED_VECTOR);
	str = getenv(varname);
	if (str == NULL)
		return NULL;
	return string_alloc_with(str, strlen(str));
}

/*
 * prim Platform_isBigEndian : () -> bool
 */
ml_uint_t
prim_Platform_isBigEndian(ml_int_t unit ATTR_UNUSED)
{
#ifdef WORDS_BIGENDIAN
	return 1;
#else
	return 0;
#endif /* WORDS_BIGENDIAN */
}

/*
 * prim Platform_getPlatform : () -> string
 */
void *
prim_Platform_getPlatform(ml_int_t unit ATTR_UNUSED)
{
#ifdef SMLSHARP_PLATFORM
	return string_alloc_with(SMLSHARP_PLATFORM, strlen(SMLSHARP_PLATFORM));
#else
	return string_alloc_with("", 0); /* dummy */
#endif /* SMLSHARP_PLATFORM */
}

/*
 * prim CopyMemory : ['a . ('a array, word, 'a array, word, word, word) -> ()]
 */
ml_int_t
prim_CopyMemory(void *dst, ml_uint_t doff, void *src, ml_uint_t soff,
		ml_uint_t len, ml_uint_t tag)
{
	char *p;
	ml_uint_t i;

	/* FIXME: untested */
	ASSERT((tag == TAG_UNBOXED && OBJ_TYPE(dst) == OBJTYPE_UNBOXED_ARRAY)
	       || (tag == TAG_BOXED && OBJ_TYPE(dst) == OBJTYPE_BOXED_ARRAY));
	ASSERT((tag == TAG_UNBOXED && OBJ_TYPE(src) == OBJTYPE_UNBOXED_ARRAY)
	       || (tag == TAG_BOXED && OBJ_TYPE(src) == OBJTYPE_BOXED_ARRAY));
	ASSERT(doff + len <= OBJ_SIZE(dst));
	ASSERT(soff + len <= OBJ_SIZE(src));

	memmove((char*)dst + doff, (char*)src + soff, len);
	if (tag != TAG_UNBOXED) {
		p = (char*)dst + doff;
		for (i = 0; i < len; i += sizeof(void*))
			WRITE_BARRIER(dst, (void**)(p + i));
	}
	return 0;
}

int
prim_UnmanagedMemory_subInt(void *p)
{
	return *(int*)p;
}

double
prim_UnmanagedMemory_subReal(void *p)
{
	return *(double*)p;
}

unsigned int
prim_UnmanagedMemory_subWord(void *p)
{
	return *(unsigned int*)p;
}

unsigned char
prim_UnmanagedMemory_subByte(void *p)
{
	return *(unsigned char*)p;
}



void *
sml_str_new(const char *str)
{
	return string_alloc_with(str, strlen(str));
}

void *
prim_xmalloc(int size)
{
	return xmalloc(size);
}

int
prim_cconst_int(const char *name)
{
	if (strcmp(name, "RTLD_LAZY") == 0)
		return RTLD_LAZY;
	if (strcmp(name, "RTLD_LOCAL") == 0)
		return RTLD_LOCAL;
	if (strcmp(name, "SEEK_SET") == 0)
		return SEEK_SET;
	if (strcmp(name, "SEEK_CUR") == 0)
		return SEEK_CUR;
	return 0;
}


status_t
init_primitives(env_t *env)
{
	status_t err;
	err = env_define(env, "__EMPTY__", empty_object);
	err = env_define(env, "__NULL__", NULL);
	err = env_define(env, "__NOWHERE__", NULL);
	env_commit(env);
	return 0;
}
