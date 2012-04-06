/*
 * heap_malloc.c - use malloc heap as a main heap. (for test use)
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 */

#include "smlsharp.h"
#include "objspace.h"
#include "heap.h"

void
sml_heap_init(size_t size ATTR_UNUSED, size_t max_size ATTR_UNUSED)
{
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
sml_heap_thread_stw_hook(void *data ATTR_UNUSED)
{
}
#endif /* MULTITHREAD */

static void
trace(void **slot)
{
	sml_trace_ptr(*slot);
}

void
sml_heap_gc()
{
	GIANT_LOCK(NULL);
	STOP_THE_WORLD();
	sml_rootset_enum_ptr(trace, MAJOR);
	sml_malloc_pop_and_mark(trace, MAJOR);
	sml_check_finalizer(trace, MAJOR);
	sml_malloc_sweep(MAJOR);
	RUN_THE_WORLD();
	GIANT_UNLOCK();
	sml_run_finalizer(NULL);
}

SML_PRIMITIVE void *
sml_alloc(unsigned int objsize, void *frame_pointer)
{
	sml_save_frame_pointer(frame_pointer);
	return sml_obj_malloc(objsize);
}

SML_PRIMITIVE void
sml_write(void *objaddr, void **writeaddr, void *new_value)
{
	*writeaddr = new_value;
	sml_global_barrier(writeaddr, objaddr);
}
