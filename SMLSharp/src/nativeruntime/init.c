/**
 * init.c
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 */

#include <stdlib.h>
#include "smlsharp.h"
#include "objspace.h"
#include "control.h"
#include "heap.h"

#if 0
#define DEFAULT_HEAPSIZE (4096000 * 4 * 2)  /* same as C++ runtime */
#else
#define DEFAULT_HEAPSIZE (1024 * 1024 * 8 * 2)
#endif

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

void
sml_init(int argc ATTR_UNUSED, char **argv ATTR_UNUSED)
{
	char *s;
	size_t heapsize_min, heapsize_max;

	heapsize_min = DEFAULT_HEAPSIZE;
	heapsize_max = DEFAULT_HEAPSIZE;

	s = getenv("SMLSHARP_HEAPSIZE");
	if (s)
		parse_heapsize(s, &heapsize_min, &heapsize_max);

	s = getenv("SMLSHARP_VERBOSE");
	if (s)
		sml_set_verbose(strtol(s, NULL, 10));

	sml_control_init();
	sml_heap_init(heapsize_min, heapsize_max);
	sml_objspace_init();
}

void
sml_finish()
{
	sml_objspace_free();
	sml_heap_free();
	sml_control_free();
}
