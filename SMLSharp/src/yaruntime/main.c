/**
 * main.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: main.c,v 1.8 2008/12/11 10:22:51 katsu Exp $
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "error.h"
#include "file.h"
#include "exe.h"
#include HEAP_H
#include "eval.h"
#include "foreign.h"
#include "runtime.h"
#include "interact.h"

static const char *program_name;

static void
msg_start_func(FILE *out, enum msg_type msg)
{
	const char *prefix;

	if (msg == MSG_DEBUG)
		return;

	switch (msg) {
	case MSG_FATAL:
		prefix = "FATAL: ";
		break;
	case MSG_WARN:
		prefix = "Warning: ";
		break;
	default:
		prefix = "";
	}
	fprintf(out, "%s: %s", program_name, prefix);
}

int main(int argc, char **argv)
{
	status_t err;
	int i, status;
	int interactive_mode = 0;
	file_t *file;
	runtime_t *rt;
	executable_t *exe;

	program_name = argv[0];
#ifdef DEBUG
	verbose_level = MSG_DEBUG;
	//error_out = stdout;
#endif
	msg_start = msg_start_func;

	heap_init();
	eval32_init();
	foreign_init();

	rt = runtime_new();

	if (argc > 1 && strcmp("-S", argv[1]) == 0) {
		interactive_mode = 1;
		argv++, argc--;
	}

	for (i = 1; i < argc; i++) {
		err = file_open(argv[i], &file);
		if (err)
			fatal(err, "%s", argv[i]);

		err = runtime_load(rt, file, &exe);
		if (err)
			fatal(err, "%s: could not load file", argv[i]);

		err = runtime_exec(rt, exe);
		if (err)
			fatal(err, "%s: execution failed", argv[i]);

		DBG(("%s: execution finished.", argv[i]));
	}

	if (interactive_mode)
		interact_start(rt, stdin, stdout, &status);
	else
		status = 0;

	runtime_free(rt);
	heap_free();
	return status;
}
