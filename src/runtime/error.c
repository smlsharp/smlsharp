/**
 * error.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <errno.h>
#include "smlsharp.h"

#ifdef DEBUG
#define DEFAULT_VERBOSE_LEVEL  MSG_NOTICE
#else
#define DEFAULT_VERBOSE_LEVEL  MSG_WARN
#endif /* DEBUG */

static unsigned int verbose_level = DEFAULT_VERBOSE_LEVEL;
static FILE *(*msg_start)(enum sml_msg_level) = NULL;
static void (*msg_end)(FILE *, enum sml_msg_level) = NULL;

void sml_set_verbose(enum sml_msg_level level)
{
	verbose_level = level;
}

void sml_msg_set_hook(FILE *(*start_hook)(enum sml_msg_level),
		      void (*end_hook)(FILE *f, enum sml_msg_level))
{
	msg_start = start_hook;
	msg_end = end_hook;
}

#define MSG_START(t) (msg_start ? msg_start(t) : stderr)
#define MSG_END(f,t) (msg_end ? msg_end(f,t) : (void)0)

static void
print_syserror(enum sml_msg_level level, int err,
	       const char *format, va_list args)
{
	FILE *out;

	if (verbose_level < level)
		return;

	out = MSG_START(level);
	vfprintf(out, format, args);

	if (err > 0)
		fprintf(out, "%s\n", strerror(err));
	else if (err == 0)
		fprintf(out, ": Success\n");
	else
		fprintf(out, ": Failed (%d)\n", err);
	fflush(out);

	MSG_END(out, level);
}

static void
print_error(enum sml_msg_level level, int err,
	    const char *format, va_list args)
{
	FILE *out;

	if (verbose_level < level)
		return;

	if (err != 0) {
		print_syserror(level, err, format, args);
		return;
	}

	out = MSG_START(level);
	vfprintf(out, format, args);
	fputs("\n", out);
	fflush(out);
	MSG_END(out, level);
}

void
sml_fatal(int err, const char *format, ...)
{
	va_list args;
	va_start(args, format);
	print_error(MSG_FATAL, err, format, args);
	va_end(args);
	abort();
}

void
sml_error(int err, const char *format, ...)
{
	va_list args;
	va_start(args, format);
	print_error(MSG_ERROR, err, format, args);
	va_end(args);
}

void
sml_warn(int err, const char *format, ...)
{
	va_list args;
	va_start(args, format);
	print_error(MSG_WARN, err, format, args);
	va_end(args);
}

void
sml_notice(const char *format, ...)
{
	va_list args;
	va_start(args, format);
	print_error(MSG_NOTICE, 0, format, args);
	va_end(args);
}

void
sml_sysfatal(const char *format, ...)
{
	va_list args;
	va_start(args, format);
	print_syserror(MSG_FATAL, errno, format, args);
	va_end(args);
	abort();
}

void
sml_syserror(const char *format, ...)
{
	va_list args;
	va_start(args, format);
	print_syserror(MSG_ERROR, errno, format, args);
	va_end(args);
}

void
sml_syswarn(const char *format, ...)
{
	va_list args;
	va_start(args, format);
	print_syserror(MSG_WARN, errno, format, args);
	va_end(args);
}

void
sml_debug(const char *format, ...)
{
	va_list args;
	FILE *out;

	if (verbose_level < MSG_DEBUG)
		return;

	va_start(args, format);
	out = MSG_START(MSG_DEBUG);
	vfprintf(out, format, args);
	MSG_END(out, MSG_DEBUG);
	va_end(args);
}
