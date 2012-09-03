/**
 * prim.c
 * @copyright (c) 2007-2010, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: prim.c,v 1.12 2008/12/11 10:22:51 katsu Exp $
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <errno.h>
#include <ctype.h>
#include <unistd.h>
#include <dirent.h>
#include <fcntl.h>
#include <time.h>
#include <stdint.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

#ifdef HAVE_CONFIG_H
#if !HAVE_DECL_FPCLASSIFY && !HAVE_DECL_ISINF
#include <float.h>
#endif /* HAVE_DECL_ISINF */
#endif /* HAVE_CONFIG_H */
#if !defined(HAVE_CONFIG_H) || defined(HAVE_SYS_TIMES_H)
#include <sys/times.h>
#endif /* HAVE_SYS_TIMES_H */
#if defined(HAVE_CONFIG_H) && !defined(HAVE_UTIMES) && defined(HAVE_UTIME_H)
#include <utime.h>
#endif /* HAVE_UTIME_H */
#if !defined(HAVE_CONFIG_H) || defined(HAVE_POLL_H)
#include <poll.h>
#endif /* HAVE_POLL_H */
#if !defined(HAVE_CONFIG_H) || defined(HAVE_DLFCN_H)
#include <dlfcn.h>
#endif /* HAVE_DLFCN_H */

#ifdef MINGW32
#include <windows.h>
#undef OBJ_BITMAP
#endif /* MINGW32 */

#if defined(HAVE_CONFIG_H) && defined(HAVE_IEEEFP_H)
#include <ieeefp.h>
#endif /* HAVE_IEEEFP_H */

#include "smlsharp.h"
#include "intinf.h"
#include "object.h"
#include "prim.h"

#ifdef HAVE_CONFIG_H
#ifndef HAVE_CEILF
float ceilf(float x)
{
	return ceil(x);
}
#endif /* HAVE_CEILF */

#ifndef HAVE_FLOORF
float floorf(float x)
{
	return floor(x);
}
#endif /* HAVE_FLOORF */

#ifndef HAVE_ROUNDF
float roundf(float x)
{
	return round(x);
}
#endif /* HAVE_ROUNDF */

#ifndef HAVE_LDEXPF
float ldexpf(float x, int n)
{
	return ldexp(x, n);
}
#endif /* HAVE_LDEXPF */

#ifndef HAVE_FREXPF
float frexpf(float x, int *n)
{
	return frexp(x, n);
}
#endif /* HAVE_FREXPF */

#ifndef HAVE_MODFF
float modff(float x, float *i)
{
	double n, y;
	y = modf(x, &n);
	*i = n;
	return y;
}
#endif /* HAVE_MODFF */

#if !HAVE_DECL_SIGNBIT
#define signbit__(t, x) \
	(((x) > 0.0##t) ? 0 : ((x) < 0.0##t) ? 1 : (1.0##t / x < 0.0##t))
#define signbit(x) \
	((sizeof(x) == sizeof(float)) ? signbit__(f, x) : \
	 (sizeof(x) == sizeof(double)) ? signbit__(, x) : signbit__(l, x))
#endif /* HAVE_DECL_SIGNBIT */

#ifndef HAVE_COPYSIGN
double copysign(double x, double y)
{
	return (signbit(x) == signbit(y)) ? x : -x;
}
#endif /* HAVE_COPYSIGN */

#ifndef HAVE_COPYSIGNF
float copysignf(float x, float y)
{
	return (signbit(x) == signbit(y)) ? x : -x;
}
#endif /* HAVE_COPYSIGNF */

#ifndef HAVE_NEXTAFTER
double nextafter(double x, double y)
{
	/* ToDo: stub */
	sml_fatal(0, "nextafter is not implemented");
}
#endif /* HAVE_NEXTAFTER */

#ifndef HAVE_NEXTAFTERF
float nextafter(float x, float y)
{
	/* ToDo: stub */
	sml_fatal(0, "nextafterf is not implemented");
}
#endif /* HAVE_NEXTAFTERF */

#ifndef HAVE_FESETROUND
int fesetround(int x)
{
	/* ToDo: stub */
	sml_fatal(0, "fesetround is not implemented");
}
#endif /* HAVE_FESETROUND */

#ifndef HAVE_FEGETROUND
int fegetround()
{
	/* ToDo: stub */
	sml_fatal(0, "fegetround is not implemented");
}
#endif /* HAVE_FEGETROUND */

#if HAVE_DECL_FPCLASSIFY
#define HAVE_FPCLASSIFY 1
#endif

#if !defined(HAVE_FPCLASS) && !defined(HAVE_FPCLASSIFY)

#if !HAVE_DECL_ISNORMAL
#define isnormal(x)   (1)   /* always normal */
#endif /* HAVE_DECL_ISNORMAL */

#if !HAVE_DECL_ISNAN
static int ne_(double x, double y) { return x == y; }
static int ne_f(float x, float y) { return x == y; }
static int ne_l(long double x, long double y) { return x == y; }
#define isnan(x) \
	((sizeof(x) == sizeof(float)) ? !ne_f(x, x) : \
	 (sizeof(x) == sizeof(double)) ? !ne_(x, x) : !ne_l(x, x))
#endif /* HAVE_DECL_ISNAN */

#if !HAVE_DECL_ISINF
#ifdef HAVE_FINITE
#define isinf(x)  (!finite(x) && !isnan(x))
#else
#define isinf__(p, x)  ((x) < -p##_MAX || (x) > p##_MAX)
#define isinf(x) \
	((sizeof(x) == sizeof(float)) ? isinf__(FLT, x) : \
	 (sizeof(x) == sizeof(double)) ? isinf_(DBL, x) : isinf_l(LDBL, x))
#endif /* HAVE_FINITE */
#endif /* HAVE_DECL_ISINF */

#define iszero(x) \
	((sizeof(x) == sizeof(float)) ? (x) == 0.0f : \
	 (sizeof(x) == sizeof(double)) ? (x) == 0.0 : (x) == 0.0l)

#endif /* HAVE_FPCLASSIFY */
#endif /* HAVE_CONFIG_H */

#if defined(MINGW32)
void *
dlopen(const char *libname, int mode ATTR_UNUSED)
{
	HMODULE handle = LoadLibrary(libname);
	return (void*)handle;
}

char *
dlerror()
{
	DWORD n;
	static char buf[128];

	n = FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM |
			  FORMAT_MESSAGE_IGNORE_INSERTS,
			  NULL, GetLastError(),
			  MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
			  buf, sizeof(buf) / sizeof(buf[0]), NULL);

	return buf;
}

void *
dlsym(void *handle, const char *symbol)
{
	FARPROC proc = GetProcAddress((HMODULE)handle, symbol);
	return (void*)proc;
}

int
dlclose(void *handle)
{
	BOOL ret = FreeLibrary((HMODULE)handle);
	return ret ? 0 : -1;
}

#elif defined(HAVE_CONFIG_H) && !defined(HAVE_DLOPEN)

void *
dlopen(const char *libname)
{
	return NULL;
}

const char *
dlerror()
{
	return "dynamic linking is not supported";
}

void *
dlsym(void *handle, const char *symbol)
{
	return NULL;
}

int
dlclose(void *handle)
{
	return 0;
}
#endif /* MINGW32 || HAVE_DLOPEN */

#if defined(MINGW32)
unsigned int
sleep(unsigned int seconds)
{
	DWORD sec = seconds;
	const DWORD max = ((DWORD)-1) / 1000;
	if (sec > max) {
		sleep(sec - max);
		sec = max;
	}
	Sleep(sec * 1000);
	return 0;
}
#elif defined(HAVE_CONFIG_H) && !defined(HAVE_SLEEP)
unsigned int
sleep(unsigned int seconds)
{
	return seconds;
}
#endif /* HAVE_SLEEP */

int
prim_String_size(const char *str)
{
	/* used for not only CharVector but CharArray */
	ASSERT(OBJ_TYPE(str) == OBJTYPE_UNBOXED_VECTOR
	       || OBJ_TYPE(str) == OBJTYPE_UNBOXED_ARRAY);
	return OBJ_STR_SIZE(str);
}

void
prim_String_update(char *str, int index, char ch)
{
	/* used for not only CharVector but CharArray */
	ASSERT(OBJ_TYPE(str) == OBJTYPE_UNBOXED_ARRAY
	       || OBJ_TYPE(str) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(index >= 0 && (size_t)index < OBJ_STR_SIZE(str));
	str[index] = ch;
}

char
prim_String_sub(const char *str, int n)
{
	/* used for not only CharVector but CharArray */
	ASSERT(OBJ_TYPE(str) == OBJTYPE_UNBOXED_ARRAY
	       || OBJ_TYPE(str) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(n >= 0 && (size_t)n < OBJ_STR_SIZE(str));
	return str[n];
}

STRING
prim_String_substring(const char *str, int beg, int len)
{
	ASSERT(OBJ_TYPE(str) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(beg >= 0 && len >= 0);
	ASSERT((size_t)(beg + len) <= OBJ_STR_SIZE(str));

	return sml_str_new2(&str[beg], len);
}

int
prim_String_cmp(const char *str1, const char *str2)
{
	int len1, len2, len, cmp;

	ASSERT(OBJ_TYPE(str1) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(OBJ_TYPE(str2) == OBJTYPE_UNBOXED_VECTOR);
	len1 = OBJ_STR_SIZE(str1);
	len2 = OBJ_STR_SIZE(str2);

	len = len1 < len2 ? len1 : len2;
	cmp = memcmp(str1, str2, len1);

	if (cmp == 0) {
		/* this is OK because both len1 and len2 are signed integer
		 * but never negative. */
		return len1 - len2;
	}
	return cmp;
}

STRING
prim_String_allocateMutableNoInit(unsigned int len)
{
	char *obj = sml_obj_alloc(OBJTYPE_UNBOXED_ARRAY, len + 1);
	obj[len] = '\0';
	return obj;
}

STRING
prim_String_allocateImmutableNoInit(unsigned int len)
{
	char *obj = sml_obj_alloc(OBJTYPE_UNBOXED_VECTOR, len + 1);
	obj[len] = '\0';
	return obj;
}

STRING
prim_String_allocateMutable(int len, char ch)
{
	void *obj;
	ASSERT(len >= 0);
	obj = prim_String_allocateMutableNoInit(len);
	memset(obj, ch, len);
	return obj;
}

STRING
prim_String_allocateImmutable(int len, char ch)
{
	void *obj;
	ASSERT(len >= 0);
	obj = prim_String_allocateImmutableNoInit(len);
	memset(obj, ch, len);
	return obj;
}

void
prim_String_copy(const char *src, int si, char *dst, int di, int len)
{
	/* used for not only CharVector but CharArray */
	ASSERT(OBJ_TYPE(src) == OBJTYPE_UNBOXED_ARRAY
	       || OBJ_TYPE(src) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(OBJ_TYPE(dst) == OBJTYPE_UNBOXED_ARRAY
	       || OBJ_TYPE(dst) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(len >= 0);
	ASSERT(si >= 0 && (size_t)(si + len) <= OBJ_STR_SIZE(src));
	ASSERT(di >= 0 && (size_t)(di + len) <= OBJ_STR_SIZE(dst));

	memcpy(dst + di, src + si, len);
}

static unsigned int
fmt(unsigned int value, unsigned int radix, char *buf, unsigned int index)
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

static STRING
fmt_int(int value, unsigned int radix)
{
	char buf[sizeof(unsigned int) * CHAR_BIT + sizeof("~")];
	unsigned int i = sizeof(buf);
	unsigned int n;

	/* assume that |INT_MIN| <= UINT_MAX */
	n = (value < 0) ? 0U - (unsigned int)value : (unsigned int)value;
	i = fmt(n, radix, buf, i);
	if (value < 0)
		buf[--i] = '~';

	return sml_str_new2(&buf[i], sizeof(buf) - i);
}

static STRING
fmt_word(unsigned int value, unsigned int radix)
{
	char buf[sizeof(unsigned int) * CHAR_BIT + sizeof("")];
	unsigned int i = sizeof(buf);

	i = fmt(value, radix, buf, i);
	return sml_str_new2(&buf[i], sizeof(buf) - i);
}

STRING
prim_Int_toString(int value)
{
	return fmt_int(value, 10);
}

STRING
prim_Word_toString(unsigned int value)
{
	return fmt_word(value, 16);
}

#define IEEEREAL_CLASS_SNAN     1   /* signaling NaN */
#define IEEEREAL_CLASS_QNAN     2   /* quiet NaN */
#define IEEEREAL_CLASS_INF      3   /* infinity */
#define IEEEREAL_CLASS_ZERO     4   /* zero */
#define IEEEREAL_CLASS_DENORM   5   /* denormal */
#define IEEEREAL_CLASS_NORM     6   /* normal */
#define IEEEREAL_CLASS_UNKNOWN  0

#if !defined(HAVE_CONFIG_H) || defined(HAVE_FPCLASSIFY)
#define FPCLASS(d) \
	switch (fpclassify(d)) { \
	case FP_INFINITE: \
		return signbit(d) ? -IEEEREAL_CLASS_INF \
				  : IEEEREAL_CLASS_INF; \
	case FP_NAN: \
		return signbit(d) ? -IEEEREAL_CLASS_QNAN \
				  : IEEEREAL_CLASS_QNAN; \
	case FP_NORMAL: \
		return signbit(d) ? -IEEEREAL_CLASS_NORM \
				  : IEEEREAL_CLASS_NORM; \
	case FP_SUBNORMAL: \
		return signbit(d) ? -IEEEREAL_CLASS_DENORM \
				  : IEEEREAL_CLASS_DENORM; \
	case FP_ZERO: \
		return signbit(d) ? -IEEEREAL_CLASS_ZERO \
				  : IEEEREAL_CLASS_ZERO; \
	default: \
		return IEEEREAL_CLASS_UNKNOWN; \
	}
#elif defined(HAVE_FPCLASS)
#define FPCLASS(d) \
	switch(fpclass(d)) { \
	case FP_SNAN: \
		return signbit(d) ? -IEEEREAL_CLASS_SNAN \
				  : IEEEREAL_CLASS_SNAN; \
	case FP_QNAN: \
		return signbit(d) ? -IEEEREAL_CLASS_QNAN \
				  : IEEEREAL_CLASS_QNAN; \
	case FP_NINF: \
		return -IEEEREAL_CLASS_INF; \
	case FP_PINF: \
		return IEEEREAL_CLASS_INF; \
	case FP_NDENORM: \
		return -IEEEREAL_CLASS_DENORM; \
	case FP_PDENORM: \
		return IEEEREAL_CLASS_DENORM; \
	case FP_NZERO: \
		return -IEEEREAL_CLASS_ZERO; \
	case FP_PZERO: \
		return IEEEREAL_CLASS_ZERO; \
	case FP_NNORM: \
		return -IEEEREAL_CLASS_NORM; \
	case FP_PNORM: \
		return IEEEREAL_CLASS_NORM; \
	default: \
		return IEEEREAL_CLASS_UNKNOWN; \
	}
#else
#define FPCLASS(d) \
	if (iszero(d)) \
		return signbit(d) ? -IEEEREAL_CLASS_ZERO \
				  : IEEEREAL_CLASS_ZERO; \
	else if (isinf(d)) \
		return signbit(d) ? -IEEEREAL_CLASS_INF \
				  : IEEEREAL_CLASS_INF; \
	else if (isnan(d)) \
		return signbit(d) ? -IEEEREAL_CLASS_QNAN \
				  : IEEEREAL_CLASS_QNAN; \
	else if (!isnormal(d)) \
		return signbit(d) ? -IEEEREAL_CLASS_DENORM \
				  : IEEEREAL_CLASS_DENORM; \
	else \
		return signbit(d) ? -IEEEREAL_CLASS_NORM \
				  : IEEEREAL_CLASS_NORM;
#endif /* HAVE_FPCLASSIFY */

int
prim_Real_class(double d)
{
	FPCLASS(d);
}

int
prim_Float_class(float f)
{
	FPCLASS(f);
}

STRING
prim_IntInf_toString(sml_intinf_t *n)
{
	char *buf, *ret;

	ASSERT(OBJ_TYPE(n) == OBJTYPE_INTINF);
	buf = sml_intinf_fmt(n, 10);
	ret = sml_str_new(buf);
	free(buf);
	return ret;
}

int
prim_IntInf_toInt(sml_intinf_t *obj)
{
	ASSERT(OBJ_TYPE(obj) == OBJTYPE_INTINF);
	return sml_intinf_get_si(obj);
}

unsigned int
prim_IntInf_toWord(sml_intinf_t *obj)
{
	unsigned long n;

	ASSERT(OBJ_TYPE(obj) == OBJTYPE_INTINF);

	/* mpz_get_ui(op) returns least significant bits of absolute value
	 * of "op" but this primitive requires to return least significant
	 * bits of 2's complement form of "op". So we take 2's complement
	 * of the return value of mpz_get_ui if "op" is negative.
	 */
	n = sml_intinf_get_ui(obj);
	if (sml_intinf_sign(obj) < 0)
		n = ~n + 1;

	return n;
}

sml_intinf_t *
prim_IntInf_fromInt(int x)
{
	sml_intinf_t *n = sml_intinf_new();
	sml_intinf_set_si(n, x);
	return n;
}

sml_intinf_t *
prim_IntInf_fromWord(unsigned int x)
{
	sml_intinf_t *n = sml_intinf_new();
	sml_intinf_set_ui(n, x);
	return n;
}

sml_intinf_t *
prim_IntInf_load(const char *src)
{
	sml_intinf_t *n = sml_intinf_new();
	sml_intinf_set_str(n, src, 10);
	return n;
}

sml_intinf_t *
prim_IntInf_abs(sml_intinf_t *x)
{
	sml_intinf_t xv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);

	xv = *x; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_abs(z, &xv);
	return z;
}

sml_intinf_t *
prim_IntInf_add(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_add(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_sub(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_sub(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_neg(sml_intinf_t *x)
{
	sml_intinf_t xv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);

	xv = *x; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_neg(z, &xv);
	return z;
}

sml_intinf_t *
prim_IntInf_mul(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_mul(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_div(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_div(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_mod(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_mod(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_quot(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_quot(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_rem(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_rem(z, &xv, &yv);
	return z;
}

int
prim_IntInf_cmp(sml_intinf_t *x, sml_intinf_t *y)
{
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);
	return sml_intinf_cmp(x, y);
}

sml_intinf_t *
prim_IntInf_orb(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_ior(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_xorb(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_xor(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_andb(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_and(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_notb(sml_intinf_t *x)
{
	sml_intinf_t xv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);

	xv = *x; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_com(z, &xv);
	return z;
}

sml_intinf_t *
prim_IntInf_pow(sml_intinf_t *x, int e)
{
	sml_intinf_t xv, *z;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);
	ASSERT(e >= 0);

	xv = *x; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_pow(z, &xv, e);
	return z;
}

int
prim_IntInf_log2(sml_intinf_t *x)
{
	sml_intinf_t xv;
	ASSERT(OBJ_TYPE(x) == OBJTYPE_INTINF);

	xv = *x; /* rescue from garbage collector */
	return sml_intinf_log2(&xv);
}

int
prim_Time_gettimeofday(int *ret)
{
	struct timeval tv;
	int err;

	ASSERT(OBJ_TYPE(ret) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(OBJ_SIZE(ret) >= sizeof(int) * 2);

	err = gettimeofday(&tv, NULL);
	ret[0] = tv.tv_sec;
	ret[1] = tv.tv_usec;
	return err;
}

int
prim_Timer_getTimes(int *ret)
{
#ifdef HAVE_TIMES
	struct tms tms;
	static long clocks_per_sec = 0;
	clock_t clk;

	ASSERT(OBJ_TYPE(ret) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(OBJ_SIZE(ret) >= sizeof(int) * 6);

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
#else
	struct timeval tv;
	int err;

	ASSERT(OBJ_TYPE(ret) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(OBJ_SIZE(ret) >= sizeof(int) * 6);

	err = gettimeofday(&tv, NULL);
	ret[0] = 0;  /* sys seconds */
	ret[1] = 0;  /* sys microseconds */
	ret[2] = tv.tv_sec;
	ret[3] = tv.tv_usec;
	/* FIXME: do we put GC time still here? */
	ret[4] = 0;  /* GC seconds */
	ret[5] = 0;  /* GC microseconds */
	return err;
#endif /* HAVE_TIMES */
}

unsigned int
prim_Date_strfTime(char *buf, unsigned int maxsize, const char *format,
		   int sec, int min, int hour, int mday, int month,
		   int year, int wday, int yday, int isdst)
{
	struct tm tm;
	tm.tm_sec = sec;
	tm.tm_min = min;
	tm.tm_hour = hour;
	tm.tm_mday = mday;
	tm.tm_mon = month;
	tm.tm_year = year;
	tm.tm_wday = wday;
	tm.tm_yday = yday;
	tm.tm_isdst = isdst;
	return strftime(buf, maxsize, format, &tm);
}

char *
prim_Date_ascTime(int sec, int min, int hour, int mday, int month, int year,
		  int wday, int yday, int isdst)
{
	struct tm tm;
	tm.tm_sec = sec;
	tm.tm_min = min;
	tm.tm_hour = hour;
	tm.tm_mday = mday;
	tm.tm_mon = month;
	tm.tm_year = year;
	tm.tm_wday = wday;
	tm.tm_yday = yday;
	tm.tm_isdst = isdst;
	return asctime(&tm);
}

int
prim_Date_mkTime(int sec, int min, int hour, int mday, int month, int year,
                 int wday, int yday, int isdst)
{
	struct tm tm;
	tm.tm_sec = sec;
	tm.tm_min = min;
	tm.tm_hour = hour;
	tm.tm_mday = mday;
	tm.tm_mon = month;
	tm.tm_year = year;
	tm.tm_wday = wday;
	tm.tm_yday = yday;
	tm.tm_isdst = isdst;
	return mktime(&tm);
}

int
prim_Date_localTime(int time, int *ret)
{
	time_t t = time;
	struct tm *tm = localtime(&t);
	if (tm == NULL)
		return -1;
	ret[0] = tm->tm_sec;
	ret[1] = tm->tm_min;
	ret[2] = tm->tm_hour;
	ret[3] = tm->tm_mday;
	ret[4] = tm->tm_mon;
	ret[5] = tm->tm_year;
	ret[6] = tm->tm_wday;
	ret[7] = tm->tm_yday;
	ret[8] = tm->tm_isdst;
	return 0;
}

int
prim_Date_gmTime(int time, int *ret)
{
	time_t t = time;
	struct tm *tm = gmtime(&t);
	if (tm == NULL)
		return -1;
	ret[0] = tm->tm_sec;
	ret[1] = tm->tm_min;
	ret[2] = tm->tm_hour;
	ret[3] = tm->tm_mday;
	ret[4] = tm->tm_mon;
	ret[5] = tm->tm_year;
	ret[6] = tm->tm_wday;
	ret[7] = tm->tm_yday;
	ret[8] = tm->tm_isdst;
	return 0;
}

double
prim_Pack_packReal64Little(unsigned char byte0, unsigned char byte1,
			   unsigned char byte2, unsigned char byte3,
			   unsigned char byte4, unsigned char byte5,
			   unsigned char byte6, unsigned char byte7)
{
	double result;

#ifdef WORDS_BIGENDIAN
	char src[8] = {byte7, byte6, byte5, byte4, byte3, byte2, byte1, byte0};
#else
	char src[8] = {byte0, byte1, byte2, byte3, byte4, byte5, byte6, byte7};
#endif /* WORDS_BIGENDIAN */

	memcpy(&result, src, sizeof(double) < 8 ? sizeof(double) : 8);
	return result;
}

double
prim_Pack_packReal64Big(unsigned char byte0, unsigned char byte1,
			unsigned char byte2, unsigned char byte3,
			unsigned char byte4, unsigned char byte5,
			unsigned char byte6, unsigned char byte7)
{
	double result;

#ifdef WORDS_BIGENDIAN
	char src[8] = {byte0, byte1, byte2, byte3, byte4, byte5, byte6, byte7};
#else
	char src[8] = {byte7, byte6, byte5, byte4, byte3, byte2, byte1, byte0};
#endif /* WORDS_BIGENDIAN */

	memcpy(&result, src, sizeof(double) < 8 ? sizeof(double) : 8);
	return result;
}

void
prim_Pack_unpackReal64Little(double d, unsigned char *buf)
{
#ifdef WORDS_BIGENDIAN
	size_t i, len = sizeof(double) < 8 ? sizeof(double) : 8;
	for (i = 0; i < len; i++)
		buf[i] = ((unsigned char *)&d)[len - i - 1];
#else
	memcpy(buf, &d, sizeof(double) < 8 ? sizeof(double) : 8);
#endif /* WORDS_BIGENDIAN */
}

void
prim_Pack_packReal32Little(unsigned char byte0, unsigned char byte1,
			   unsigned char byte2, unsigned char byte3,
			   float *ret)
{
#ifdef WORDS_BIGENDIAN
	char src[4] = {byte3, byte2, byte1, byte0};
#else
	char src[4] = {byte0, byte1, byte2, byte3};
#endif /* WORDS_BIGENDIAN */

	memcpy(ret, src, sizeof(float) < 4 ? sizeof(float) : 4);
}

void
prim_Pack_packReal32Big(unsigned char byte0, unsigned char byte1,
			unsigned char byte2, unsigned char byte3,
                        float *ret)
{
#ifdef WORDS_BIGENDIAN
	char src[4] = {byte0, byte1, byte2, byte3};
#else
	char src[4] = {byte3, byte2, byte1, byte0};
#endif /* WORDS_BIGENDIAN */

	memcpy(ret, src, sizeof(float) < 4 ? sizeof(float) : 4);
}

void
prim_Pack_unpackReal32Little(float d, unsigned char *buf)
{
#ifdef WORDS_BIGENDIAN
	size_t i, len = sizeof(float) < 4 ? sizeof(float) : 4;
	for (i = 0; i < len; i++)
		buf[i] = ((unsigned char *)&d)[len - i - 1];
#else
	memcpy(buf, &d, sizeof(float) < 4 ? sizeof(float) : 4);
#endif /* WORDS_BIGENDIAN */
}


/* HERE */


int
prim_StandardC_errno()
{
	return errno;
}

int
prim_cconst_int(const char *name)
{
#ifdef HAVE_DLOPEN
	if (strcmp(name, "RTLD_LAZY") == 0)
		return RTLD_LAZY;
	if (strcmp(name, "RTLD_NOW") == 0)
		return RTLD_NOW;
	if (strcmp(name, "RTLD_GLOBAL") == 0)
		return RTLD_GLOBAL;
	if (strcmp(name, "RTLD_LOCAL") == 0)
		return RTLD_LOCAL;
#endif /* HAVE_DLOPEN */
	if (strcmp(name, "SEEK_SET") == 0)
		return SEEK_SET;
	if (strcmp(name, "SEEK_CUR") == 0)
		return SEEK_CUR;
#ifdef FE_TONEAREST
	if (strcmp(name, "FE_TONEAREST") == 0)
		return FE_TONEAREST;
#endif /* FE_TONEAREST */
#ifdef FE_DOWNWARD
	if (strcmp(name, "FE_DOWNWARD") == 0)
		return FE_DOWNWARD;
#endif /* FE_DOWNWARD */
#ifdef FE_UPWARD
	if (strcmp(name, "FE_UPWARD") == 0)
		return FE_UPWARD;
#endif /* FE_UPWARD */
#ifdef FE_TOWARDZERO
	if (strcmp(name, "FE_TOWARDZERO") == 0)
		return FE_TOWARDZERO;
#endif /* FE_TOWARDZERO */
	return 0;
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

STRING
prim_GenericOS_errorName(int errnum)
{
	unsigned int i;
	const char *name = NULL;

	for (i = 0; i < arraysize(sys_errors); i++) {
		if (sys_errors[i].errnum == errnum) {
			name = sys_errors[i].name;
			break;
		}
	}

	if (name == NULL)
		return fmt_int(errnum, 10);
	else
		return sml_str_new(name);
}

int
prim_GenericOS_syserror(const char *errorname)
{
	unsigned int i;
	int errnum = -1;

	ASSERT(OBJ_TYPE(errorname) == OBJTYPE_UNBOXED_VECTOR);

	/* errorname[0] always exists due to existence of sentinel. */
	if (isdigit(errorname[0]))
		return atoi(errorname);

	for (i = 0; i < arraysize(sys_errors); i++) {
		if (strcmp(errorname, sys_errors[i].name) == 0) {
			errnum = sys_errors[i].errnum;
			break;
		}
	}
	return errnum;
}

void
prim_GenericOS_exit(int status)
{
	/* FIXME: finalization is needed? */
#ifdef HAVE_INTERACTIVE_MODE
	if (interactive_mode)
		return interact_prim_exit(status);
#endif /* HAVE_INTERACTIVE_MODE */

	exit(status);
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

void
prim_print(const char *str)
{
	ASSERT(OBJ_TYPE(str) == OBJTYPE_UNBOXED_VECTOR);
#ifdef HAVE_INTERACTIVE_MODE
	if (interactive_mode) {
		interact_prim_print(str);
		return;
	}
#endif /* HAVE_INTERACTIVE_MODE */

	puts_posix(1, str, OBJ_STR_SIZE(str));
}

#if 0
void
prim_printerr(const char *str)
{
	ASSERT(OBJ_TYPE(str) == OBJTYPE_UNBOXED_VECTOR);

#ifdef HAVE_INTERACTIVE_MODE
	if (interactive_mode) {
		interact_prim_printerr(str);
		return;
	}
#endif /* HAVE_INTERACTIVE_MODE */

	puts_posix(2, str, OBJ_STR_SIZE(str));
}
#endif

int
prim_GenericOS_open(const char *filename, const char *fmode)
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

int
prim_GenericOS_read(int fd, char *buf, unsigned int offset, unsigned int len)
{
	ASSERT(OBJ_TYPE(buf) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(offset + len <= OBJ_SIZE(buf));

#ifdef HAVE_INTERACTIVE_MODE
	if (interactive_mode && fd == 0)
		return interact_prim_read(fd, buf, offset, len);
#endif /* HAVE_INTERACTIVE_MODE */

	return read(fd, buf + offset, len);
}

int
prim_GenericOS_write(int fd, const char *buf,
		     unsigned int offset, unsigned int len)
{
	ASSERT(OBJ_TYPE(buf) == OBJTYPE_UNBOXED_ARRAY
	       || OBJ_TYPE(buf) == OBJTYPE_UNBOXED_VECTOR);
	ASSERT(offset + len <= OBJ_SIZE(buf));

#ifdef HAVE_INTERACTIVE_MODE
	if (interactive_mode && fd == 0)
		return interact_prim_write(fd, buf, offset, len);
#endif /* HAVE_INTERACTIVE_MODE */

	return write(fd, buf + offset, len);
}

int
prim_GenericOS_lseek(int fd, /*off_t*/ int offset, int whence)
{
	return lseek(fd, offset, whence);
}


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
#define ML_S_IFMT   0xf000

#ifndef S_IFLNK
#define S_IFLNK  0
#endif /* S_IFLNK */
#ifndef S_IFSOCK
#define S_IFSOCK  0
#endif /* S_IFSOCK */
#ifndef S_ISUID
#define S_ISUID  0
#endif /* S_ISUID */
#ifndef S_ISGID
#define S_ISGID  0
#endif /* S_ISGID */
#ifndef S_ISVTX
#define S_ISVTX  0
#endif /* S_ISVTX */

static void
set_stat(struct stat *st, unsigned int *ret)
{
	ASSERT(OBJ_TYPE(ret) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(OBJ_SIZE(ret) >= sizeof(unsigned int) * 6);

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
		unsigned int mode = 0;
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

int
prim_GenericOS_fstat(int fd, unsigned int *ret)
{
	int err;
	struct stat st;

	err = fstat(fd, &st);
	if (err == 0)
		set_stat(&st, ret);
	return err;
}

int
prim_GenericOS_stat(const char *filename, unsigned int *ret)
{
	int err;
	struct stat st;

	err = stat(filename, &st);
	if (err == 0)
		set_stat(&st, ret);
	return err;
}

int
prim_GenericOS_utime(const char *filename, unsigned int atime,
		     unsigned int mtime)
{
#if !defined(HAVE_CONFIG_H) || defined(HAVE_UTIMES)
	struct timeval times[2];

	/* FIXME: untested */
	ASSERT(OBJ_TYPE(filename) == OBJTYPE_UNBOXED_VECTOR);
	times[0].tv_sec = atime;
	times[0].tv_usec = 0;
	times[1].tv_sec = mtime;
	times[1].tv_usec = 0;
	return utimes(filename, times);
#elif defined(HAVE_CONFIG_H) && defined(HAVE_UTIME)
	struct utimbuf ut;
	ut.actime = atime;
	ut.modtime = mtime;
	return utime(filename, &ut);
#else
	errno = EIO;
	return -1;
#endif /* HAVE_UTIMES */
}

STRING
prim_GenericOS_readlink(const char *filename)
{
#if !defined(HAVE_CONFIG_H) || defined(HAVE_READLINK)
	char buf[128], *p;
	ssize_t n, len;
	void *obj;

	ASSERT(OBJ_TYPE(filename) == OBJTYPE_UNBOXED_VECTOR);

	n = readlink(filename, buf, sizeof(buf));
	if (n < 0)
		return NULL;
	if ((size_t)n < sizeof(buf))
		return sml_str_new2(buf, n);

	p = NULL;
	for (len = sizeof(buf); n >= len; len *= 2) {
		p = xrealloc(p, len);
		n = readlink(filename, buf, len);
	}

	if (n < 0) {
		free(p);
		return NULL;
	}
	obj = sml_str_new2(buf, n);
	free(p);
	return obj;
#else
	errno = EIO;
	return NULL;
#endif /* HAVE_READLINK */
}

int
prim_GenericOS_chdir(const char *dirname)
{
	ASSERT(OBJ_TYPE(dirname) == OBJTYPE_UNBOXED_VECTOR);

#ifdef HAVE_INTERACTIVE_MODE
	if (interactive_mode)
		return interact_prim_chdir(dirname);
#endif

	return chdir(dirname);
}

int
prim_GenericOS_mkdir(const char *dirname, /*mode_t*/ int mode)
{
	ASSERT(OBJ_TYPE(dirname) == OBJTYPE_UNBOXED_VECTOR);
#ifdef MINGW32
	return _mkdir(dirname);
#else
	return mkdir(dirname, mode);
#endif /* MINGW32 */
}

char *
prim_GenericOS_getcwd()
{
	size_t size = 256;
	char *pwd = xmalloc(size);

	while (getcwd(pwd, size) == NULL) {
		if (errno != ERANGE) {
			free(pwd);
			return NULL;
		}
		size += 256;
		pwd = xrealloc(pwd, size);
	}
	return pwd;
}

/*DIR**/ void *
prim_GenericOS_opendir(const char *dirname)
{
	ASSERT(OBJ_TYPE(dirname) == OBJTYPE_UNBOXED_VECTOR);
	return opendir(dirname);
}

char *
prim_GenericOS_readdir(/*DIR**/ void *dirhandle)
{
	struct dirent *ent;

	ent = readdir(dirhandle);
	if (ent == NULL)
		return NULL;
	return ent->d_name;
}

void
prim_GenericOS_rewinddir(/*DIR**/ void *dirhandle)
{
	return rewinddir(dirhandle);
}

/*DIR**/ int
prim_GenericOS_closedir(/*DIR**/ void *dirhandle)
{
	return closedir(dirhandle);
}

#define SML_POLLIN   1U
#define SML_POLLOUT  2U
#define SML_POLLPRI  4U

int
prim_GenericOS_poll(int *fdary, unsigned int *evary, int timeout_sec,
		    int timeout_usec)
{
#if (defined(HAVE_CONFIG_H) && defined(HAVE_SELECT)) || !defined(MINGW32) || !defined(HAVE_CONFIG_H)
	fd_set infds, outfds, prifds;
	struct timeval timeout;
	unsigned int i;
	int nfds, err;

	/* FIXME: untested */
	ASSERT(OBJ_TYPE(fdary) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(OBJ_TYPE(evary) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(OBJ_SIZE(fdary) == OBJ_SIZE(evary));

	FD_ZERO(&infds);
	FD_ZERO(&outfds);
	FD_ZERO(&prifds);
	nfds = 0;

	for (i = 0; i < OBJ_SIZE(fdary) / sizeof(int); i++) {
		int fd = ((int*)fdary)[i], setfd = 0;
		unsigned int ev = ((unsigned int*)evary)[i];
		if (ev & SML_POLLIN) {
			setfd = fd;
			FD_SET(fd, &infds);
		}
		if (ev & SML_POLLOUT) {
			setfd = fd;
			FD_SET(fd, &outfds);
		}
		if (ev & SML_POLLPRI) {
			setfd = fd;
			FD_SET(fd, &prifds);
		}
		nfds = (nfds > setfd) ? nfds : setfd;
	}
	nfds++;

	if (timeout_sec < 0 || timeout_usec < 0) {
		err = select(nfds, &infds, &outfds, &prifds, NULL);
	} else {
		timeout.tv_sec = timeout_sec;
		timeout.tv_usec = timeout_usec;
		err = select(nfds, &infds, &outfds, &prifds, &timeout);
	}

	if (err < 0)
		return err;

	for (i = 0; i < OBJ_SIZE(evary) / sizeof(unsigned int); i++) {
		unsigned int ev = 0;
		if (!FD_ISSET(((int*)fdary)[i], &infds))
			ev |= SML_POLLIN;
		if (!FD_ISSET(((int*)fdary)[i], &outfds))
			ev |= SML_POLLOUT;
		if (!FD_ISSET(((int*)fdary)[i], &prifds))
			ev |= SML_POLLPRI;
		((unsigned int*)evary)[i] = ev;
	}
	return err;

#elif defined(HAVE_POLL)
	struct pollfd *fds;
	nfds_t nfds, i;
	int err;

	/* FIXME: untested */
	ASSERT(OBJ_TYPE(fdary) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(OBJ_TYPE(evary) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(OBJ_SIZE(fdary) == OBJ_SIZE(evary));

	nfds = OBJ_SIZE(fdary) / sizeof(int);
	fds = xmalloc(nfds * sizeof(struct pollfd));

	for (i = 0; i < nfds; i++) {
		unsigned int ev = ((unsigned int*)evary)[i];
		fds[i].fd = ((int*)fdary)[i];
		fds[i].events = 0;
		if (ev & SML_POLLIN)
			fds[i].events |= POLLIN;
		if (ev & SML_POLLOUT)
			fds[i].events |= POLLOUT;
		if (ev & SML_POLLPRI)
			fds[i].events |= POLLPRI;
	}

	if (timeout_sec < 0 || timeout_usec < 0) {
		err = poll(fds, nfds, -1);
	} else {
		/* ToDo: overflow check is needed? */
		int timeout = timeout_sec * 1000 + timeout_usec / 1000;
		err = poll(fds, nfds, timeout);
	}

	if (err < 0)
		return err;

	for (i = 0; i < nfds; i++) {
		unsigned int ev = 0;
		if (fds[i].revents & POLLIN)
			ev |= SML_POLLIN;
		if (fds[i].revents & POLLOUT)
			ev |= SML_POLLOUT;
		if (fds[i].revents & POLLPRI)
			ev |= SML_POLLPRI;
		((unsigned int*)evary)[i] = ev;
	}
	return err;

#else
	errno = EIO;
	return -1;
#endif /* HAVE_SELECT | HAVE_POLL */
}

int
prim_Platform_isBigEndian()
{
#ifdef WORDS_BIGENDIAN
	return 1;
#else
	return 0;
#endif /* WORDS_BIGENDIAN */
}

STRING
prim_Platform_getPlatform()
{
#ifdef SMLSHARP_PLATFORM
	return sml_str_new(SMLSHARP_PLATFORM);
#else
	return sml_str_new("");  /* dummy */
#endif /* SMLSHARP_PLATFORM */
}

void
prim_CopyMemory(void *dst, unsigned int doff,
		const void *src, unsigned int soff,
		unsigned int len, unsigned int tag)
{
	void **writeaddr, **srcaddr;
	unsigned int i;

	ASSERT((tag == TAG_UNBOXED
		&& (OBJ_TYPE(dst) == OBJTYPE_UNBOXED_ARRAY
		    || OBJ_TYPE(dst) == OBJTYPE_UNBOXED_VECTOR))
	       || (tag == TAG_BOXED
		   && (OBJ_TYPE(dst) == OBJTYPE_BOXED_ARRAY
		       || OBJ_TYPE(dst) == OBJTYPE_BOXED_VECTOR)));
	ASSERT((tag == TAG_UNBOXED
		&& (OBJ_TYPE(src) == OBJTYPE_UNBOXED_ARRAY
		    || OBJ_TYPE(src) == OBJTYPE_UNBOXED_VECTOR))
	       || (tag == TAG_BOXED
		   && (OBJ_TYPE(src) == OBJTYPE_BOXED_ARRAY
		       || OBJ_TYPE(src) == OBJTYPE_BOXED_VECTOR)));
	ASSERT(doff + len <= OBJ_SIZE(dst));
	ASSERT(soff + len <= OBJ_SIZE(src));

	if (tag == TAG_UNBOXED) {
		memmove((char*)dst + doff, (char*)src + soff, len);
	} else if (src != dst || doff < soff) {
		writeaddr = (void**)((char*)dst + doff);
		srcaddr = (void**)((char*)src + soff);
		for (i = 0; i < len / sizeof(void*); i++)
			sml_write(dst, writeaddr++, *(srcaddr++));
	} else {
		writeaddr = (void**)((char*)dst + doff + len);
		srcaddr = (void**)((char*)src + soff + len);
		for (i = 0; i < len / sizeof(void*); i++)
			sml_write(dst, --writeaddr, *(--srcaddr));
	}
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
prim_UnmanagedMemory_subPtr(void *p)
{
	return *(void**)p;
}

STRING
prim_UnmanagedMemory_import(void *ptr, unsigned int len)
{
	return sml_str_new2(ptr, len);
}

void *
prim_UnmanagedMemory_export(const char *str, unsigned int offset,
			    unsigned int size)
{
	void *p;

	ASSERT(OBJ_TYPE(str) == OBJTYPE_UNBOXED_VECTOR
	       || OBJ_TYPE(str) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(offset < OBJ_STR_SIZE(str) && size < OBJ_STR_SIZE(str) - offset);

	p = xmalloc(size);
	memcpy(p, str + offset, size);
	return p;
}

int
prim_UnmanagedString_size(void *ptr)
{
	return strlen(ptr);
}

void
prim_UnmanagedMemory_updateByte(void *address, unsigned char value)
{
	*(unsigned char*)address = value;
}

void
prim_UnmanagedMemory_updateWord(void *address, unsigned int value)
{
	*(unsigned int *)address = value;
}

void
prim_UnmanagedMemory_updateInt(void *address, int value)
{
	*(int *)address = value;
}

void
prim_UnmanagedMemory_updateReal(void *address, double value)
{
	*(double *)address = value;
}

void
prim_UnmanagedMemory_updatePtr(void *address, void *value)
{
	*(void **)address = value;
}

int
prim_CommandLine_argc()
{
	extern int sml_argc;
	return sml_argc;
}

char **
prim_CommandLine_argv(int index)
{
	extern char **sml_argv;
	return sml_argv;
}

void *
prim_xmalloc(/*size_t*/ int size)
{
	return xmalloc(size);
}

STRING
prim_executable_path()
{
#ifdef MINGW32
	char path[256+1], *p;
	size_t len;
	void *obj;

	GetModuleFileName(NULL, path, sizeof(path));
	path[sizeof(path) - 1] = '\0';
	for (p = path, len = 0; *p; p++, len++) {
		if (*p == '\\')
			*p = '/';
	}

	obj = sml_obj_alloc(OBJTYPE_UNBOXED_VECTOR, len + 1);
	memcpy(obj, path, len + 1);
	return obj;
#else
	char *obj = sml_obj_alloc(OBJTYPE_UNBOXED_ARRAY, 1);
	obj[0] = '\0';
	return obj;
#endif /* MINGW32 */
}

STRING
prim_tmpName()
{
#ifdef MINGW32
	char path[MAX_PATH + 1], name[MAX_PATH + 1];
	char *buf;
	DWORD ret1;
	UINT ret2;

	ret1 = GetTempPath(sizeof(path), path);
	if (ret1 == 0)
		return sml_str_new("");
	ret2 = GetTempFileName(path, "tmp", 0, name);
	if (ret2 == 0)
		return sml_str_new("");

	return sml_str_new(name);
#elif defined(HAVE_MKSTEMP)
	char *buf = sml_str_new("/tmp/tmp.XXXXXX");
	int fd = mkstemp(buf);
	if (fd == -1) {
		return sml_str_new("");
	} else {
		close(fd);
		return buf;
	}
#else
	return sml_str_new(tmpnam(NULL));
#endif /* MINGW32 || HAVE_MKSTEMP */
}

typedef void primfn();
struct sml_prim_tabent {
       const char *name;
       primfn *func;
};

const struct sml_prim_tabent sml_runtime_primitives[] = {
	/* supported by compiler itself */
	{"sml_obj_dup", (primfn*)sml_obj_dup},
	{"prim_String_cmp", (primfn*)prim_String_cmp},
	{"prim_IntInf_cmp", (primfn*)prim_IntInf_cmp},
	{"prim_IntInf_load", (primfn*)prim_IntInf_load},
	{"prim_CopyMemory", (primfn*)prim_CopyMemory},
	{"sml_obj_equal", (primfn*)sml_obj_equal},

	{"prim_String_allocateMutable", (primfn*)prim_String_allocateMutable},
	{"prim_String_allocateImmutable", (primfn*)prim_String_allocateImmutable},
	{"prim_String_copy", (primfn*)prim_String_copy},
	{"prim_String_size", (primfn*)prim_String_size},
	{"prim_String_sub", (primfn*)prim_String_sub},
	{"prim_String_update", (primfn*)prim_String_update},
	{"prim_IntInf_abs", (primfn*)prim_IntInf_abs},
	{"prim_IntInf_add", (primfn*)prim_IntInf_add},
	{"prim_IntInf_div", (primfn*)prim_IntInf_div},
	{"prim_IntInf_mod", (primfn*)prim_IntInf_mod},
	{"prim_IntInf_mul", (primfn*)prim_IntInf_mul},
	{"prim_IntInf_neg", (primfn*)prim_IntInf_neg},
	{"prim_IntInf_sub", (primfn*)prim_IntInf_sub},
	{"prim_UnmanagedMemory_subInt", (primfn*)prim_UnmanagedMemory_subInt},
	{"prim_UnmanagedMemory_subReal", (primfn*)prim_UnmanagedMemory_subReal},
	{"prim_UnmanagedMemory_subWord", (primfn*)prim_UnmanagedMemory_subWord},
	{"prim_UnmanagedMemory_subByte", (primfn*)prim_UnmanagedMemory_subByte},

	/* for basis library implementation */
	{"prim_Int_toString", (primfn*)prim_Int_toString},
	{"prim_IntInf_toString", (primfn*)prim_IntInf_toString},
	{"prim_IntInf_toInt", (primfn*)prim_IntInf_toInt},
	{"prim_IntInf_toWord", (primfn*)prim_IntInf_toWord},
	{"prim_IntInf_fromInt", (primfn*)prim_IntInf_fromInt},
	{"prim_IntInf_fromWord", (primfn*)prim_IntInf_fromWord},
	{"prim_IntInf_quot", (primfn*)prim_IntInf_quot},
	{"prim_IntInf_rem", (primfn*)prim_IntInf_rem},
	{"prim_IntInf_pow", (primfn*)prim_IntInf_pow},
	{"prim_IntInf_log2", (primfn*)prim_IntInf_log2},
	{"prim_IntInf_orb", (primfn*)prim_IntInf_orb},
	{"prim_IntInf_xorb", (primfn*)prim_IntInf_xorb},
	{"prim_IntInf_andb", (primfn*)prim_IntInf_andb},
	{"prim_IntInf_notb", (primfn*)prim_IntInf_notb},
	{"prim_Word_toString", (primfn*)prim_Word_toString},
	{"prim_Real_class", (primfn*)prim_Real_class},
	{"prim_Float_class", (primfn*)prim_Float_class},
	{"prim_String_allocateImmutableNoInit", (primfn*)prim_String_allocateImmutableNoInit},
	{"prim_String_allocateMutableNoInit", (primfn*)prim_String_allocateMutableNoInit},
	{"prim_String_substring", (primfn*)prim_String_substring},
	{"prim_print", (primfn*)prim_print},
	{"prim_GenericOS_exit", (primfn*)prim_GenericOS_exit},
	{"prim_GenericOS_open", (primfn*)prim_GenericOS_open},
	{"prim_GenericOS_read", (primfn*)prim_GenericOS_read},
	{"prim_GenericOS_write", (primfn*)prim_GenericOS_write},
	{"prim_GenericOS_fstat", (primfn*)prim_GenericOS_fstat},
	{"prim_GenericOS_stat", (primfn*)prim_GenericOS_stat},
	{"prim_GenericOS_lseek", (primfn*)prim_GenericOS_lseek},
	{"prim_GenericOS_utime", (primfn*)prim_GenericOS_utime},
	{"prim_GenericOS_readlink", (primfn*)prim_GenericOS_readlink},
	{"prim_GenericOS_chdir", (primfn*)prim_GenericOS_chdir},
	{"prim_GenericOS_mkdir", (primfn*)prim_GenericOS_mkdir},
	{"prim_GenericOS_getcwd", (primfn*)prim_GenericOS_getcwd},
	{"prim_GenericOS_opendir", (primfn*)prim_GenericOS_opendir},
	{"prim_GenericOS_readdir", (primfn*)prim_GenericOS_readdir},
	{"prim_GenericOS_rewinddir", (primfn*)prim_GenericOS_rewinddir},
	{"prim_GenericOS_closedir", (primfn*)prim_GenericOS_closedir},
	{"prim_GenericOS_poll", (primfn*)prim_GenericOS_poll},
	{"prim_GenericOS_errorName", (primfn*)prim_GenericOS_errorName},
	{"prim_GenericOS_syserror", (primfn*)prim_GenericOS_syserror},
	{"prim_Time_gettimeofday", (primfn*)prim_Time_gettimeofday},
	{"prim_Timer_getTimes", (primfn*)prim_Timer_getTimes},
	{"prim_StandardC_errno", (primfn*)prim_StandardC_errno},
	{"prim_Platform_isBigEndian", (primfn*)prim_Platform_isBigEndian},
	{"prim_Platform_getPlatform", (primfn*)prim_Platform_getPlatform},
	{"prim_CommandLine_argc", (primfn*)prim_CommandLine_argc},
	{"prim_CommandLine_argv", (primfn*)prim_CommandLine_argv},
	{"prim_xmalloc", (primfn*)prim_xmalloc},
	{"prim_cconst_int", (primfn*)prim_cconst_int},
	{"sml_str_new", (primfn*)sml_str_new},

	/* Netlib dtoa */
	{"sml_dtoa", (primfn*)sml_dtoa},
	{"sml_freedtoa", (primfn*)sml_freedtoa},
	{"sml_strtod", (primfn*)sml_strtod},

	/* standard C library functions for basis library implementation */
	/* ANSI */
	{"ldexp", (primfn*)ldexp},
	{"sqrt", (primfn*)sqrt},
	{"sin", (primfn*)sin},
	{"cos", (primfn*)cos},
	{"tan", (primfn*)tan},
	{"asin", (primfn*)asin},
	{"acos", (primfn*)acos},
	{"atan", (primfn*)atan},
	{"atan2", (primfn*)atan2},
	{"exp", (primfn*)exp},
	{"pow", (primfn*)pow},
	{"log", (primfn*)log},
	{"log10", (primfn*)log10},
	{"sinh", (primfn*)sinh},
	{"cosh", (primfn*)cosh},
	{"tanh", (primfn*)tanh},
	{"floor", (primfn*)floor},
	{"ceil", (primfn*)ceil},
	{"round", (primfn*)round},
	{"modf", (primfn*)modf},
	{"frexp", (primfn*)frexp},
	{"strerror", (primfn*)strerror},
	{"getenv", (primfn*)getenv},
	{"free", (primfn*)free},
	{"system", (primfn*)system},
	{"remove", (primfn*)remove},
	{"rename", (primfn*)rename},

	/* C99 */
	{"copysign", (primfn*)copysign},
	{"copysignf", (primfn*)copysignf},
	{"ceilf", (primfn*)ceilf},
	{"floorf", (primfn*)floorf},
	{"roundf", (primfn*)roundf},
	{"ldexpf", (primfn*)ldexpf},
	{"frexpf", (primfn*)frexpf},
	{"modff", (primfn*)modff},
	{"fesetround", (primfn*)fesetround},
	{"fegetround", (primfn*)fegetround},

	/* POSIX */
	{"sleep", (primfn*)sleep},
	{"close", (primfn*)close},
	{"rmdir", (primfn*)rmdir},
	{"dlopen", (primfn*)dlopen},
	{"dlerror", (primfn*)dlerror},
	{"dlclose", (primfn*)dlclose},
	{"dlsym", (primfn*)dlsym},
};
