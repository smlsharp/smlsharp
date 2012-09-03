/**
 * cdecl.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: cdecl.h,v 1.3 2008/02/12 09:51:40 katsu Exp $
 */
#ifndef SMLSHARP__CDECL_H__
#define SMLSHARP__CDECL_H__

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <stddef.h>

#if 0
#if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
/* __func__ is a part of C99 specification */
#elif defined __GNUC__ && __GNUC__ >= 2
#define __func__ __extension__ __FUNCTION__
#else
#define __func__ "(unknown)"
#endif
#endif

#if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
#define RESTRICT restrict
#elif defined __GNUC__ && __GNUC__ >= 3
#define RESTRICT __restrict__
#else
#define RESTRICT
#endif

#if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
#define INLINE inline
#elif defined __GNUC__ && __GNUC__ >= 2
#define INLINE __inline__
#else
#define INLINE
#endif

/* GNU C extensions */

#ifndef GCC_VERSION
#ifdef __GNUC__
#define GCC_VERSION (__GNUC__ * 1000 + __GNUC_MINOR__)
#else
#define GCC_VERSION 0
#endif
#endif /* GCC_VERSION */

#if GCC_VERSION >= 2096
#define ATTR_MALLOC __attribute__((malloc))
#else
#define ATTR_MALLOC
#endif

#if GCC_VERSION >= 3000
#define ATTR_PURE __attribute__((pure))
#else
#define ATTR_PURE
#endif

#if GCC_VERSION >= 3003
#define ATTR_NONNULL(n) __attribute__((nonnull(n)))
#else
#define ATTR_NONNULL(n)
#endif

#ifdef __GNUC__
#define ATTR_PRINTF(m,n) __attribute__((format(printf,m,n))) ATTR_NONNULL(m)
#endif

#ifdef __GNUC__
#define ATTR_NORETURN __attribute__((noreturn))
#endif

#ifdef __GNUC__
#define ATTR_UNUSED __attribute__((unused))
#endif

#ifdef __GNUC__
/* Boland fastcall; %eax, %edx, %ecx */
#define PRIMITIVE __attribute__((regparm(3)))
#else
/* Microsoft fastcall; %ecx, %edx */
/* #define PRIMITIVE __attribute__((fastcall)) */
#define PRIMITIVE
#endif

/* the number of elements of an array. */
#define arraysize(a)   (sizeof(a) / sizeof(a[0]))

/* ALIGNSIZE(x,y) : round up x to the multiple of y. */
#define ALIGNSIZE(x,y)  (((x) + (y) - 1) - ((x) + (y) - 1) % (y))

/* the most conservative memory alignment.
 * It should be differed for each architecture. */
#ifndef MAXALIGN
union alignment__ {
	char c; short s; int i; long n;
	float f; double d; long double x; void *p;
};
#define MAXALIGN    (sizeof(union alignment__))
#endif

/* FILELINE : "<filename>:<lineno>" for debug */
#define FILELINE__(x,y)  x":"#y
#define FILELINE_(x,y) FILELINE__(x,y)
#define FILELINE FILELINE_(__FILE__, __LINE__)





#endif /* SMLSHARP__CDECL_H__ */
