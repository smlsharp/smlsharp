/**
 * error.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: error.c,v 1.4 2008/01/23 08:20:07 katsu Exp $
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <errno.h>
#include <setjmp.h>
#include "error.h"

static
void default_msg_end(FILE *f, enum msg_type msg)
{
	if (msg != MSG_DEBUG)
		fputs("\n", f);
	fflush(f);
}

unsigned int verbose_level = MSG_WARN;
FILE *error_out = NULL;
void (*msg_start)(FILE *f, enum msg_type msg_type) = NULL;
void (*msg_end)(FILE *f, enum msg_type msg_type) = default_msg_end;

static const char *errornames[] = {
	"Success",                      /* ERR_SUCCESS */
	"Failed",                       /* ERR_FAILED */
	"Invalid data",                 /* ERR_INVALID */
	"File truncated",               /* ERR_TRUNCATED */
	"Symbol redefined",             /* ERR_REDEFINED */
	"Symbol undefined",             /* ERR_UNDEFINED */
	"Aborted",                      /* ERR_ABORT */
};

static void
print_syserror(enum msg_type msg_type, status_t err,
	       const char *format, va_list args)
{
	const char *errmsg;
	FILE *out = error_out ? error_out : stderr;

	if (verbose_level < msg_type)
		return;

	if (err > 0)
		errmsg = strerror(err);
	else if (err == ERR_FAILED)
		errmsg = NULL;
	else
		errmsg = errornames[-err];

	if (msg_start)
		msg_start(out, msg_type);
	vfprintf(out, format, args);
	if (errmsg != NULL)
		fprintf(out, ": %s", errmsg);
	if (msg_end)
		msg_end(out, msg_type);
}

static void
print_error(enum msg_type msg_type, status_t err,
	    const char *format, va_list args)
{
	FILE *out = error_out ? error_out : stderr;

	if (verbose_level < msg_type)
		return;

	if (err != 0) {
		print_syserror(msg_type, err, format, args);
		return;
	}
	if (msg_start)
		msg_start(out, msg_type);
	vfprintf(out, format, args);
	if (msg_end)
		msg_end(out, msg_type);
}

void
fatal(status_t err, const char *format, ...)
{
	va_list args;
	va_start(args, format);
	print_error(MSG_FATAL, err, format, args);
	va_end(args);
	abort();
}

void
error(status_t err, const char *format, ...)
{
	va_list args;
	va_start(args, format);
	print_error(MSG_ERROR, err, format, args);
	va_end(args);
}

void
warn(status_t err, const char *format, ...)
{
	va_list args;
	va_start(args, format);
	print_error(MSG_WARN, err, format, args);
	va_end(args);
}

void
notice(const char *format, ...)
{
	va_list args;
	va_start(args, format);
	print_error(MSG_NOTICE, 0, format, args);
	va_end(args);
}

void
sysfatal(const char *format, ...)
{
	va_list args;
	va_start(args, format);
	print_syserror(MSG_FATAL, errno, format, args);
	va_end(args);
	abort();
}

void
syserror(const char *format, ...)
{
	va_list args;
	va_start(args, format);
	print_syserror(MSG_ERROR, errno, format, args);
	va_end(args);
}

void
syswarn(const char *format, ...)
{
	va_list args;
	va_start(args, format);
	print_syserror(MSG_WARN, errno, format, args);
	va_end(args);
}

void
debug(const char *format, ...)
{
	va_list args;
	FILE *out = error_out ? error_out : stderr;

	if (verbose_level < MSG_DEBUG)
		return;

	va_start(args, format);
	if (msg_start)
		msg_start(out, MSG_DEBUG);
	vfprintf(out, format, args);
	if (msg_end)
		msg_end(out, MSG_DEBUG);
	va_end(args);
}
