/*
 * heap_boehm.c - use BDW GC (for test use)
 * @copyright (c) 2015, Tohoku University.
 * @author UENO Katsuhiro
 */

#include <gc.h>
#include "smlsharp.h"
#include "object.h"
#include "objspace.h"
#include "heap.h"

void
sml_heap_init(size_t min_size ATTR_UNUSED, size_t max_size)
{
	GC_INIT();
	GC_set_max_heap_size(max_size);
}

void
sml_heap_free()
{
}

void *
sml_heap_thread_init()
{
	return NULL;
}

void
sml_heap_thread_free(void *heap ATTR_UNUSED)
{
}

#ifdef MULTITHREAD
void
sml_heap_thread_gc_hook(void *data ATTR_UNUSED)
{
}
#endif /* MULTITHREAD */

void
sml_heap_gc()
{
	/* sml_run_finalizer(); */
}

SML_PRIMITIVE void *
sml_alloc(unsigned int objsize)
{
	unsigned int headersize = ALIGNSIZE(OBJ_HEADER_SIZE, sizeof(void*));
	char *m, *p;
	m = GC_MALLOC(objsize + headersize);
	p = m + headersize;
#ifndef FAIR_COMPARISON
	OBJ_HEADER(p) = 0;
#endif /* FAIR_COMPARISON */
	return p;
}

SML_PRIMITIVE void
sml_write(void *obj, void **writeaddr, void *new_value)
{
	*writeaddr = new_value;
	sml_global_barrier(writeaddr, obj);
}
