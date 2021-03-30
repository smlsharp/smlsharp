/**
 * init.c
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 */

#include <stdlib.h>
#include <string.h>
#include "smlsharp.h"
#include "heap.h"
#ifndef WITHOUT_MASSIVETHREADS
#include <myth/myth.h>
extern char **environ;
#endif /* WITHOUT_MASSIVETHREADS */

int sml_argc;
char **sml_argv;

#define DEFAULT_HEAPSIZE_MIN  (1 * 1024 * 1024UL)
#define DEFAULT_HEAPSIZE_MAX  (2 * 1024 * 1024 * 1024UL)

static size_t
parse_size(const char *src, char **next)
{
	char *p;
	long n;
	double f;
	size_t r;

	n = strtol(src, &p, 10);
	if (n < 0)
		p = (char*)src;
	f = (*p == '.') ? strtod(p, &p) : 0.0;
	switch (*p) {
	case 'G':
		p++;
		r = 1024 * 1024 * 1024;
		break;
	case 'M':
		p++;
		r = 1024 * 1024;
		break;
	case 'k':
		p++;
		r = 1024;
		break;
	default:
		r = 1;
	}

	if (next)
		*next = p;
	return r * n + r * f;
}

static void
parse_heapsize(const char *src, size_t *min_ret, size_t *max_ret)
{
	char *p;
	size_t min, max;

	min = parse_size(src, &p);
	if (p == src)
		min = *min_ret;
	if (*p == ':')
		max = parse_size(p + 1, &p);
	else
		max = min;
	if (max < min)
		max = min;
	if (*p == '\0' && p > src)
		*min_ret = min, *max_ret = max;
}

#ifndef WITHOUT_MASSIVETHREADS
static int
has_MYTH_env()
{
	char **p;
	for (p = environ; *p; p++) {
		if (strncmp(*p, "MYTH_", 5) == 0)
			return 1;
	}
	return 0;
}
#endif /* WITHOUT_MASSIVETHREADS */

void
sml_init(int argc, char **argv)
{
	char *s;
	size_t heapsize_min, heapsize_max;

	sml_argc = argc;
	sml_argv = argv;

	heapsize_min = DEFAULT_HEAPSIZE_MIN;
	heapsize_max = DEFAULT_HEAPSIZE_MAX;

	s = getenv("SMLSHARP_HEAPSIZE");
	if (s)
		parse_heapsize(s, &heapsize_min, &heapsize_max);

	if (heapsize_max < heapsize_min)
		heapsize_max = heapsize_min;

#ifndef WITHOUT_MASSIVETHREADS
	/* Massivethreads on multicore CPUs is disabled by default
	 * in order to avoid overheads incurred by unused workers.
	 * To enable massivethreads, set one of MYTH_* environment variable. */
	if (has_MYTH_env()) {
		myth_init();
	} else {
		myth_globalattr_t attr;
		myth_globalattr_init(&attr);
		myth_globalattr_set_bind_workers(&attr, 0);
		myth_globalattr_set_n_workers(&attr, 1);
		myth_init_ex(&attr);
		myth_globalattr_destroy(&attr);
	}
#endif /* WITHOUT_MASSIVETHREDS */

	sml_msg_init();
	sml_control_init();
	sml_heap_init(heapsize_min, heapsize_max);
	sml_callback_init();
	sml_finalize_init();
}

void
sml_finish()
{
	sml_finalize_destroy();
	sml_callback_destroy();
	sml_heap_destroy();

#ifndef WITHOUT_MASSIVETHREADS
	/* myth_fini(); */
#endif /* WITHOUT_MASSIVETHREDS */
}
