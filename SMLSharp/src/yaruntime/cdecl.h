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

#ifdef HAVE_INTTYPES_H
#include <inttypes.h>
#else

typedef unsigned long long uint64_t;
typedef signed long long int64_t;
typedef unsigned int uint32_t;
typedef signed int int32_t;
typedef unsigned short uint16_t;
typedef signed int int16_t;
typedef unsigned long uintptr_t;
typedef signed long intptr_t;

typedef unsigned long uintmax_t;
typedef signed long intmax_t;
#define PRIuMAX "lu"
#define PRIdMAX "ld"
#define PRIoMAX "lo"
#define PRIxMAX "lx"

#endif

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

#endif /* SMLSHARP__CDECL_H__ */
