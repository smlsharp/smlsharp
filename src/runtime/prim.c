/**
 * prim.c
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

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
#include <fenv.h>

#ifdef HAVE_CONFIG_H
#if !HAVE_DECL_FPCLASSIFY && !HAVE_DECL_ISINF
#include <float.h>
#endif /* HAVE_DECL_ISINF */
#endif /* HAVE_CONFIG_H */
#include <sys/times.h>
#include <sys/resource.h>
#include <utime.h>
#include <poll.h>
#include <dlfcn.h>

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

/* On some systems, fesetround and fegetround are provided as inline
 * functions, not as library functions.  The Basis Library requires
 * that they are library functions since it imports them to ML by the
 * _import feature.  */
int prim_fesetround(int x)
{
#if !defined(HAVE_FESETROUND) && !HAVE_DECL_FESETROUND
	/* ToDo: stub */
	sml_fatal(0, "fesetround is not implemented");
#else
	return fesetround(x);
#endif /* !HAVE_FESETROUND */
}

int prim_fegetround()
{
#if !defined(HAVE_FEGETROUND) && !HAVE_DECL_FEGETROUND
	/* ToDo: stub */
	sml_fatal(0, "fegetround is not implemented");
#else
	return fegetround();
#endif /* !HAVE_FEGETROUND */
}

int
sml_memcmp(const char *s1, int i1, const char *s2, int i2, int len)
{
	s1 += i1;
	s2 += i2;
	if (s1 == s2)
		return 0;
	while (len > 0) {
		unsigned char c1 = *s1;
		unsigned char c2 = *s2;
		if (c1 != c2)
			return (int)c1 - (int)c2;
		len--, s1++, s2++;
	}
	return 0;
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

	assert(OBJ_TYPE(n) == OBJTYPE_INTINF);
	buf = sml_intinf_fmt(n, 10);
	ret = sml_str_new(buf);
	free(buf);
	return ret;
}

unsigned int
prim_IntInf_toWord(sml_intinf_t *obj)
{
	assert(OBJ_TYPE(obj) == OBJTYPE_INTINF);

	if (sizeof(long int) > sizeof(int)) {
		/* if long int is larger than int, the low-order bits of
		 * mpz_get_si is the answer. */
		return (int)(unsigned int)(unsigned long int)
			(sml_intinf_get_si(obj));
	} else {
		/* otherwise, compute 2's complement of the absolute of
		 * the given value (mpz_get_ui) */
		unsigned long int n = sml_intinf_get_ui(obj);
		if (sml_intinf_sign(obj) < 0) n = -n;
		return n;
	}
}

uint64_t
prim_IntInf_toWord64(sml_intinf_t *obj)
{
	assert(OBJ_TYPE(obj) == OBJTYPE_INTINF);

	if (sizeof(long int) > sizeof(uint64_t)) {
		return (uint64_t)(unsigned long int)(sml_intinf_get_si(obj));
	} else if (sizeof(long int) == sizeof(uint64_t)) {
		unsigned long int n = (signed long int)sml_intinf_get_ui(obj);
		if (sml_intinf_sign(obj) < 0) n = -n;
		return n;
	} else {
		uint64_t *p, n;
		p = mpz_export(NULL, NULL, -1, sizeof(n), 0, 0, obj->value);
		if (p == NULL) return 0;
		n = *p;
		free(p);
		if (sml_intinf_sign(obj) < 0) n = -n;
		return n;
	}
}

double
prim_IntInf_toReal(sml_intinf_t *obj)
{
	assert(OBJ_TYPE(obj) == OBJTYPE_INTINF);
	return sml_intinf_get_d(obj);
}

sml_intinf_t *
prim_IntInf_fromInt(int x)
{
	sml_intinf_t *n = sml_intinf_new();
	sml_intinf_set_si(n, (long int)(unsigned long int)x);
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
prim_IntInf_fromInt64(int64_t x)
{
	sml_intinf_t *n = sml_intinf_new();

	if (sizeof(long int) >= sizeof(int64_t)) {
		sml_intinf_set_si(n, (long int)(uint64_t)x);
	} else {
		uint64_t u = x;
		if (x < 0) u = -u;
		mpz_import(n->value, 1, -1, sizeof(u), 0, 0, &u);
		if (x < 0) sml_intinf_neg(n, n);
	}
	return n;
}

sml_intinf_t *
prim_IntInf_fromWord64(uint64_t x)
{
	sml_intinf_t *n = sml_intinf_new();

	if (sizeof(long int) >= sizeof(int64_t))
		sml_intinf_set_ui(n, (long int)(uint64_t)x);
	else
		mpz_import(n->value, 1, -1, sizeof(x), 0, 0, &x);
	return n;
}

sml_intinf_t *
prim_IntInf_fromReal(double x)
{
	sml_intinf_t *n = sml_intinf_new();
	sml_intinf_set_d(n, x);
	return n;
}

sml_intinf_t *
prim_IntInf_abs(sml_intinf_t *x)
{
	sml_intinf_t xv, *z;
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);

	xv = *x; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_abs(z, &xv);
	return z;
}

sml_intinf_t *
prim_IntInf_add(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);
	assert(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_add(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_sub(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);
	assert(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_sub(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_neg(sml_intinf_t *x)
{
	sml_intinf_t xv, *z;
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);

	xv = *x; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_neg(z, &xv);
	return z;
}

sml_intinf_t *
prim_IntInf_mul(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);
	assert(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_mul(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_div(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);
	assert(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_div(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_mod(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);
	assert(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_mod(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_quot(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);
	assert(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_quot(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_rem(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);
	assert(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_rem(z, &xv, &yv);
	return z;
}

int
prim_IntInf_cmp(sml_intinf_t *x, sml_intinf_t *y)
{
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);
	assert(OBJ_TYPE(y) == OBJTYPE_INTINF);
	return sml_intinf_cmp(x, y);
}

sml_intinf_t *
prim_IntInf_orb(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);
	assert(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_ior(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_xorb(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);
	assert(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_xor(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_andb(sml_intinf_t *x, sml_intinf_t *y)
{
	sml_intinf_t xv, yv, *z;
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);
	assert(OBJ_TYPE(y) == OBJTYPE_INTINF);

	xv = *x, yv = *y; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_and(z, &xv, &yv);
	return z;
}

sml_intinf_t *
prim_IntInf_notb(sml_intinf_t *x)
{
	sml_intinf_t xv, *z;
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);

	xv = *x; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_com(z, &xv);
	return z;
}

sml_intinf_t *
prim_IntInf_pow(sml_intinf_t *x, int e)
{
	sml_intinf_t xv, *z;
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);
	assert(e >= 0);

	xv = *x; /* rescue from garbage collector */
	z = sml_intinf_new();
	sml_intinf_pow(z, &xv, e);
	return z;
}

int
prim_IntInf_log2(sml_intinf_t *x)
{
	sml_intinf_t xv;
	assert(OBJ_TYPE(x) == OBJTYPE_INTINF);

	xv = *x; /* rescue from garbage collector */
	return sml_intinf_log2(&xv);
}

int
prim_Time_gettimeofday(int *ret)
{
	struct timeval tv;
	int err;

	assert(OBJ_TYPE(ret) == OBJTYPE_UNBOXED_ARRAY);
	assert(OBJ_SIZE(ret) >= sizeof(int) * 2);

	err = gettimeofday(&tv, NULL);
	ret[0] = tv.tv_sec;
	ret[1] = tv.tv_usec;
	return err;
}

int
prim_Timer_getTimes(int *ret)
{
#if defined HAVE_GETRUSAGE
	struct rusage r;
	int err;

	err = getrusage(RUSAGE_SELF, &r);
	if (err == 0) {
		ret[0] = r.ru_stime.tv_sec;
		ret[1] = r.ru_stime.tv_usec;
		ret[2] = r.ru_utime.tv_sec;
		ret[3] = r.ru_utime.tv_usec;
		/* FIXME: do we put GC time still here? */
		ret[4] = 0;  /* GC seconds */
		ret[5] = 0;  /* GC microseconds */
	}
	return err;
#elif defined HAVE_TIMES
	struct tms tms;
	static long clocks_per_sec = 0;
	clock_t clk;

	assert(OBJ_TYPE(ret) == OBJTYPE_UNBOXED_ARRAY);
	assert(OBJ_SIZE(ret) >= sizeof(int) * 6);

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

	assert(OBJ_TYPE(ret) == OBJTYPE_UNBOXED_ARRAY);
	assert(OBJ_SIZE(ret) >= sizeof(int) * 6);

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
		   const struct tm *tm)
{
	return strftime(buf, maxsize, format, tm);
}

int
prim_Date_mkTime(const struct tm *time)
{
        struct tm tm;
	tm.tm_sec = time->tm_sec;
	tm.tm_min = time->tm_min;
	tm.tm_hour = time->tm_hour;
	tm.tm_mday = time->tm_mday;
	tm.tm_mon = time->tm_mon;
	tm.tm_year = time->tm_year;
	tm.tm_wday = time->tm_wday;
	tm.tm_yday = time->tm_yday;
	tm.tm_isdst = time->tm_isdst;
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

int
prim_StandardC_errno()
{
	return errno;
}

#define PRIM_CONST_FUNC(ty, const) \
	ty prim_const_##const() { return const; }
#define PRIM_CONST_FUNC_DUMMY(ty, const) \
	ty prim_const_##const() { return 0; }

#ifdef HAVE_DLOPEN
PRIM_CONST_FUNC(int, RTLD_LAZY)
PRIM_CONST_FUNC(int, RTLD_NOW)
PRIM_CONST_FUNC(int, RTLD_LOCAL)
PRIM_CONST_FUNC(int, RTLD_GLOBAL)
PRIM_CONST_FUNC(void *, RTLD_DEFAULT)
PRIM_CONST_FUNC(void *, RTLD_NEXT)
#else
PRIM_CONST_FUNC_DUMMY(int, RTLD_LAZY)
PRIM_CONST_FUNC_DUMMY(int, RTLD_NOW)
PRIM_CONST_FUNC_DUMMY(int, RTLD_LOCAL)
PRIM_CONST_FUNC_DUMMY(int, RTLD_GLOBAL)
PRIM_CONST_FUNC_DUMMY(void *, RTLD_DEFAULT)
PRIM_CONST_FUNC_DUMMY(void *, RTLD_NEXT)
#endif /* HAVE_DLOPEN */

PRIM_CONST_FUNC(int, SEEK_SET)
PRIM_CONST_FUNC(int, SEEK_CUR)
PRIM_CONST_FUNC(int, FE_TONEAREST)
PRIM_CONST_FUNC(int, FE_DOWNWARD)
PRIM_CONST_FUNC(int, FE_UPWARD)
PRIM_CONST_FUNC(int, FE_TOWARDZERO)

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

	assert(OBJ_TYPE(errorname) == OBJTYPE_UNBOXED_VECTOR);

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
	sml_exit(status);
}

int
prim_GenericOS_open(const char *filename, const char *fmode)
{
	const char *str;
	int flags, subflags;

	assert(OBJ_TYPE(filename) == OBJTYPE_UNBOXED_VECTOR);
	assert(OBJ_TYPE(fmode) == OBJTYPE_UNBOXED_VECTOR);

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

	return open(filename, flags | subflags, 0666);
}

int
prim_GenericOS_read(int fd, char *buf, unsigned int offset, unsigned int len)
{
	assert(OBJ_TYPE(buf) == OBJTYPE_UNBOXED_ARRAY
	       || OBJ_TYPE(buf) == OBJTYPE_UNBOXED_VECTOR);
	assert(offset + len <= OBJ_SIZE(buf));

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
	assert(OBJ_TYPE(buf) == OBJTYPE_UNBOXED_ARRAY
	       || OBJ_TYPE(buf) == OBJTYPE_UNBOXED_VECTOR);
	assert(offset + len <= OBJ_SIZE(buf));

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

PRIM_CONST_FUNC(unsigned int, S_IFMT)
PRIM_CONST_FUNC(unsigned int, S_IFIFO)
PRIM_CONST_FUNC(unsigned int, S_IFCHR)
PRIM_CONST_FUNC(unsigned int, S_IFDIR)
PRIM_CONST_FUNC(unsigned int, S_IFBLK)
PRIM_CONST_FUNC(unsigned int, S_IFREG)
PRIM_CONST_FUNC(unsigned int, S_IFLNK)
PRIM_CONST_FUNC(unsigned int, S_IFSOCK)
PRIM_CONST_FUNC(unsigned int, S_ISUID)
PRIM_CONST_FUNC(unsigned int, S_ISGID)
PRIM_CONST_FUNC(unsigned int, S_ISVTX)
PRIM_CONST_FUNC(unsigned int, S_IRUSR)
PRIM_CONST_FUNC(unsigned int, S_IWUSR)
PRIM_CONST_FUNC(unsigned int, S_IXUSR)

static void
set_stat(struct stat *st, unsigned int *ret)
{
	assert(OBJ_TYPE(ret) == OBJTYPE_UNBOXED_ARRAY);
	assert(OBJ_SIZE(ret) >= sizeof(unsigned int) * 6);

	ret[0] = st->st_dev;
	ret[1] = st->st_ino;
	ret[2] = st->st_mode;
	ret[3] = st->st_atime;
	ret[4] = st->st_mtime;
	ret[5] = st->st_size;
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
prim_GenericOS_lstat(const char *filename, unsigned int *ret)
{
	int err;
	struct stat st;

	err = lstat(filename, &st);
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
	assert(OBJ_TYPE(filename) == OBJTYPE_UNBOXED_VECTOR);
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

	assert(OBJ_TYPE(filename) == OBJTYPE_UNBOXED_VECTOR);

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
	assert(OBJ_TYPE(dirname) == OBJTYPE_UNBOXED_VECTOR);

#ifdef HAVE_INTERACTIVE_MODE
	if (interactive_mode)
		return interact_prim_chdir(dirname);
#endif

	return chdir(dirname);
}

int
prim_GenericOS_mkdir(const char *dirname, /*mode_t*/ int mode)
{
	assert(OBJ_TYPE(dirname) == OBJTYPE_UNBOXED_VECTOR);
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
	assert(OBJ_TYPE(dirname) == OBJTYPE_UNBOXED_VECTOR);
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

int
prim_GenericOS_system(const char *command)
{
	int ret;
	ret = system(command);
	return ret < 0 ? ret : WEXITSTATUS(ret);
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
	assert(OBJ_TYPE(fdary) == OBJTYPE_UNBOXED_ARRAY);
	assert(OBJ_TYPE(evary) == OBJTYPE_UNBOXED_ARRAY);
	assert(OBJ_SIZE(fdary) == OBJ_SIZE(evary));

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
	assert(OBJ_TYPE(fdary) == OBJTYPE_UNBOXED_ARRAY);
	assert(OBJ_TYPE(evary) == OBJTYPE_UNBOXED_ARRAY);
	assert(OBJ_SIZE(fdary) == OBJ_SIZE(evary));

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

STRING
prim_UnmanagedMemory_import(void *ptr, unsigned int len)
{
	void *obj;

	obj = sml_obj_alloc(OBJTYPE_UNBOXED_VECTOR, len);
	memcpy(obj, ptr, len);
	return obj;
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
	char *obj = sml_obj_alloc(OBJTYPE_UNBOXED_VECTOR, 1);
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
