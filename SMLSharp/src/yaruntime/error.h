/**
 * error.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: error.h,v 1.5 2008/02/19 10:06:31 katsu Exp $
 */
#ifndef SMLSHARP__ERROR_H__
#define SMLSHARP__ERROR_H__

#include <stdio.h>
#include "cdecl.h"

/*
 * error status
 * 0 : success
 * negative : SML# specific runtime error (see below)
 * positive : system error (see errno.h)
 */
typedef int status_t;

/* positive error code is reserved for system errno. */
#define ERR_SUCCESS     0    /* success */
#define ERR_FAILED     -1    /* failed */
#define ERR_INVALID    -2    /* invalid file format */
#define ERR_TRUNCATED  -3    /* could not read requested size */
#define ERR_REDEFINED  -4    /* symbol redefined */
#define ERR_UNDEFINED  -5    /* symbol undefined */
#define ERR_ABORT      -6    /* execution aborted */

/*
 * print fatal error message and abort the program.
 * err : error status describing why this error happened.
 *       (0 if no error status)
 * format, ... : standard output format (same as printf)
 */
void fatal(status_t err, const char *format, ...)
     ATTR_PRINTF(2, 3) ATTR_NORETURN;

/*
 * print error message.
 */
void error(status_t err, const char *format, ...) ATTR_PRINTF(2, 3);

/*
 * print warning message.
 */
void warn(status_t err, const char *format, ...) ATTR_PRINTF(2, 3);

/*
 * print fatal error message with system error status and abort the program.
 */
void sysfatal(const char *format, ...) ATTR_PRINTF(1, 2) ATTR_NORETURN;

/*
 * print error message with system error status.
 */
void syserror(const char *format, ...) ATTR_PRINTF(1, 2);

/*
 * print warning message with system error status.
 */
void syswarn(const char *format, ...) ATTR_PRINTF(1, 2);

/*
 * print notice message.
 */
void notice(const char *format, ...) ATTR_PRINTF(1, 2);

/*
 * print debug message.
 */
void debug(const char *format, ...) ATTR_PRINTF(1, 2);

/*
 * DBG((format, ...));
 * print debug message.
 *
 * ASSERT(cond);
 * abort the program if cond is not satisfied.
 *
 * FATAL((err, format, ...));
 * print fatal error message with position and abort the program.
 *
 * DBG and ASSERT are enabled only if the program is compiled in debug mode.
 */

#if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
#define DEBUG__(fmt, ...) \
	debug("%s:%d:%s: "fmt"\n", __FILE__,__LINE__,__func__,__VA_ARGS__)
#define DEBUG_(args) DEBUG__ args
#define FATAL__(err, fmt, ...) \
	fatal(err, "%s:%d:%s: "fmt, __FILE__,__LINE__,__func__,__VA_ARGS__)
#define FATAL(args) FATAL__ args
#elif defined __GNUC__
#define DEBUG__(fmt, args...) \
	debug("%s:%d:%s: "fmt"\n", __FILE__,__LINE__,__func__,##args)
#define DEBUG_(args) DEBUG__ args
#define FATAL__(err, fmt, args...) \
	fatal(err, "%s:%d:%s: "fmt, __FILE__,__LINE__,__func__,##args)
#define FATAL(args) FATAL__ args
#else
#define DEBUG_(args) \
	((void)debug("%s:%d: ", __FILE__,__LINE__), \
	 (void)debug args, \
	 (void)debug("\n"))
#define FATAL(args) (fatal args)
#endif

#ifdef DEBUG
#define DBG(args) DEBUG_(args)
#else
#define DBG(args)
#endif /* DEBUG */

#if defined DEBUG || defined ENABLE_ASSERT
#define ASSERT(expr) \
	((expr) ? (void)0 : (void)FATAL((0, "assertion failed: %s", #expr)))
#else
#define ASSERT(expr)
#endif /* ENABLE_ASSERT */


/*
 * for internal use.
 */
enum msg_type {
	MSG_FATAL,
	MSG_ERROR,
	MSG_WARN,
	MSG_NOTICE,
	MSG_DEBUG
};

extern unsigned int verbose_level;
extern FILE *error_out;
extern void (*msg_start)(FILE *f, enum msg_type msg_type);
extern void (*msg_end)(FILE *f, enum msg_type msg_type);

#endif /* SMLSHARP__ERROR_H__ */
