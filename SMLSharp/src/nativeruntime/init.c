/**
 * init.c
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 */

#include <stdlib.h>
#include "smlsharp.h"
#include "objspace.h"
#include "thread.h"
#include "heap.h"

#if 0
#define DEFAULT_HEAPSIZE (4096000 * 4 * 2)  /* same as C++ runtime */
#else
#define DEFAULT_HEAPSIZE (1024 * 1024 * 8 * 2)
#endif

void
sml_init(int argc ATTR_UNUSED, char **argv ATTR_UNUSED)
{
	char *s;
	size_t heapsize = DEFAULT_HEAPSIZE;

	s = getenv("SMLSHARP_HEAPSIZE");
	if (s) {
		long n = strtol(s, NULL, 10);
		if (n > 0)
			heapsize = n;
	}

	s = getenv("SMLSHARP_VERBOSE");
	if (s)
		sml_set_verbose(strtol(s, NULL, 10));

	sml_heap_init(heapsize);
	sml_objspace_init();
	sml_thread_env_init();
}

void
sml_finish()
{
	sml_objspace_free();
	sml_thread_env_free();
	sml_heap_free();
}
