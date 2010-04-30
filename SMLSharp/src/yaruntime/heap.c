/*
 * heap.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: heap.c,v 1.10 2008/12/10 03:23:23 katsu Exp $
 */

#include <stdlib.h>
#include <string.h>
#include "error.h"
#include "memory.h"
#include "value.h"
#include "heap.h"

/* equal to default heap size of current runtime */
#define INITIAL_HEAP_SIZE (4096000 * 4 + MAXALIGN)
#define INITIAL_OFFSET    ALIGN(OBJ_HEADER_SIZE, MAXALIGN)

#define GC_FORWARDED_FLAG     OBJ_GC1_MASK
#define OBJ_FORWARDED         OBJ_GC1
#define OBJ_FORWARD_PTR(obj)  (*(void**)(obj))

struct heap_space heap_from_space = {0, 0, 0, 0};
static struct heap_space heap_to_space = {0, 0, 0, 0};

#define IS_IN_HEAP_SPACE(heap_space, ptr) \
	((char*)(heap_space).base <= (char*)(ptr) \
	 && (char*)(ptr) < (char*)(heap_space).limit)

struct rootset {
	heap_rootset_fn *enumfn;
	void *data;
};

static unsigned int num_rootset = 0;
static struct rootset *rootset = NULL;

struct finalizer {
	int active;  /* true = requested to run the finalizer. */
	void *obj;
	heap_finalizer_fn *finalize_fn;
	void *data;
};

static unsigned int num_finalizer = 0;
struct finalizer *finalizer = NULL;


static void
heap_space_clear(struct heap_space *heap)
{
	heap->free = (char*)heap->base + INITIAL_OFFSET;
	heap->limit = (char*)heap->base + heap->size;
	ASSERT(heap->free < heap->limit);
#ifdef DEBUG
	memset(heap->base, 0x55, (char*)heap->limit - (char*)heap->base);
#endif
}

static void
heap_space_init(struct heap_space *heap)
{
	heap->base = xmalloc(INITIAL_HEAP_SIZE);
	heap->size = INITIAL_HEAP_SIZE;
	heap_space_clear(heap);
}

static void
heap_space_free(struct heap_space *heap)
{
	free(heap->base);
}

/* for debug */
void
heap_dump(struct heap_space *heap)
{
	char *cur;
	void *obj;
	unsigned int size, allocsize;

	cur = heap->base + INITIAL_OFFSET;

	debug("%p - %p", heap->base, heap->limit);

	while (cur < (char*)heap->free) {
		obj = cur + OBJ_HEADER_SIZE;
		size = OBJ_TOTAL_SIZE(obj);
		allocsize = HEAP_ROUND_SIZE(size);
		debug("%p : type=%08x, size=%u, total=%u, alloc=%u",
		      obj, OBJ_TYPE(obj), OBJ_SIZE(obj), size, allocsize);
		cur += allocsize;
	}
}

void
heap_init()
{
	heap_space_init(&heap_from_space);
	heap_space_init(&heap_to_space);
}

static void do_gc(void);

void
heap_free()
{
	num_rootset = 0;
	array_free(rootset);

	/* To run finalizers forcely, invoke GC with empty root set. */
	while (num_finalizer > 0)
		do_gc();

	heap_space_free(&heap_from_space);
	heap_space_free(&heap_to_space);
	array_free(finalizer);
}

void
heap_add_rootset(heap_rootset_fn *enumfn, void *data)
{
	rootset = array_alloc(rootset,
			      sizeof(struct rootset) * (num_rootset + 1));
	rootset[num_rootset].enumfn = enumfn;
	rootset[num_rootset].data = data;
	num_rootset++;
}

void
heap_remove_rootset(heap_rootset_fn *enumfn, void *data)
{
	unsigned int i;

	for (i = 0; i < num_rootset; i++) {
		if (rootset[i].enumfn == enumfn && rootset[i].data == data)
			break;
	}
	if (i >= num_rootset)
		return;

	memmove(&rootset[i], &rootset[i + 1],
		sizeof(struct rootset) * (num_rootset - i - 1));
	num_rootset--;
	rootset = array_alloc(rootset, sizeof(struct rootset) * num_rootset);
}

void
heap_add_finalizer(void *obj, heap_finalizer_fn *fn, void *data)
{
	ASSERT(IS_IN_HEAP_SPACE(heap_from_space, obj));

	finalizer = array_alloc(finalizer,
				sizeof(struct finalizer) * (num_finalizer + 1));
	finalizer[num_finalizer].active = 0;
	finalizer[num_finalizer].obj = obj;
	finalizer[num_finalizer].finalize_fn = fn;
	finalizer[num_finalizer].data = data;
	num_finalizer++;
}

static void
forward(void **slot)
{
	void *obj = *slot;
	size_t obj_size, alloc_size;
	void *newobj;

#if 0
	if (obj == NULL) {
		DBG(("%p at %p", obj, slot));
		return;
	}
#endif

	/* FIXME: range check is needed? */
	if (!IS_IN_HEAP_SPACE(heap_from_space, obj)) {
		DBG(("%p at %p outside", obj, slot));
		ASSERT(!IS_IN_HEAP_SPACE(heap_to_space, obj));
		return;
	}

	if (OBJ_FORWARDED(obj)) {
		*slot = OBJ_FORWARD_PTR(obj);
		DBG(("%p at %p forward -> %p", obj, slot, *slot));
		return;
	}

	obj_size = OBJ_TOTAL_SIZE(obj);
	alloc_size = HEAP_ROUND_SIZE(obj_size);

	ASSERT((size_t)((char*)heap_to_space.limit
			- (char*)heap_to_space.free) >= alloc_size);

	newobj = heap_to_space.free;
	heap_to_space.free += alloc_size;
	memcpy(&OBJ_HEADER(newobj), &OBJ_HEADER(obj), obj_size);

	DBG(("%p at %p copy -> %p (%"PRIuMAX", %"PRIuMAX")",
	     obj, slot, newobj, (intmax_t)obj_size, (intmax_t)alloc_size));

	OBJ_HEADER(obj) |= GC_FORWARDED_FLAG;
	OBJ_FORWARD_PTR(obj) = newobj;
	*slot = newobj;
}

#define forward_children(obj)  obj_enum_pointers(obj, forward)

static void
forward_region(void *start)
{
	char *cur = start;

	DBG(("%p - %p", start, heap_to_space.free));

	while (cur < (char*)heap_to_space.free) {
		forward_children(cur);
		cur += HEAP_ROUND_SIZE(OBJ_TOTAL_SIZE(cur));
	}
}

static void
check_finalizer()
{
	void *cur;
	unsigned int i;

	DBG(("check finalization: %u", num_finalizer));

	for (i = 0; i < num_finalizer; i++) {
		/* forward if the finalizer is already in active. */
		if (finalizer[i].active) {
			DBG(("%p: active", finalizer[i].obj));
			cur = heap_to_space.free;
			forward(&finalizer[i].obj);
			forward_region(cur);
			continue;
		}

		ASSERT(IS_IN_HEAP_SPACE(heap_from_space, finalizer[i].obj));

		/* keep inactive if the finalizable object survived. */
		if (OBJ_FORWARDED(finalizer[i].obj)) {
			DBG(("%p: survived -> %p",
			     finalizer[i].obj,
			     OBJ_FORWARD_PTR(finalizer[i].obj)));
			continue;
		}

		/* Forward all descendants of the finalizable object.
		 * If myself is forwarded during this process, there is
		 * a cyclic dependency. If a finializable object is in
		 * cyclic dependency, we discard its finalizer in order
		 * to prevent inconsistency.
		 */
		cur = heap_to_space.free;
		forward_children(finalizer[i].obj);
		forward_region(cur);
		if (OBJ_FORWARDED(finalizer[i].obj)) {
			warn(0, "%p : cyclic finalizer. discarded.",
			     finalizer[i].obj);
			finalizer[i].finalize_fn = NULL;
		}
	}

	DBG(("activation: %u", num_finalizer));

	for (i = 0; i < num_finalizer; i++) {
		if (finalizer[i].active)
			continue;

		/* activate if the object is not survived. */
		finalizer[i].active = !OBJ_FORWARDED(finalizer[i].obj);
		forward(&finalizer[i].obj);
	}
}

static void
run_finalizer()
{
	static volatile int finalizer_is_running = 0;
	unsigned int i, j;

	/* If GC is invoked from a finalizer function, do nothing. */
	if (finalizer_is_running)
		return;

	finalizer_is_running = 1;

	for (i = 0, j = 0; i < num_finalizer; i++) {
		if (!finalizer[i].active) {
			finalizer[j++] = finalizer[i];
			continue;
		}
		if (finalizer[i].finalize_fn == NULL)
			continue;

		DBG(("start finalizer for %p", finalizer[i].obj));
		finalizer[i].finalize_fn(finalizer[i].obj, finalizer[i].data);
	}

	finalizer_is_running = 0;

	DBG(("finalizer finished. %d -> %d\n", i, j));
	num_finalizer = j;
	finalizer = array_alloc(finalizer, sizeof(struct finalizer) * j);
}

static void
do_gc(void)
{
	unsigned int i;
	struct heap_space tmp_space;

	DBG(("start gc %p-%p -> %p-%p",
	     heap_from_space.base, heap_from_space.limit,
	     heap_to_space.base, heap_to_space.limit));

	/* forward root objects */
	for (i = 0; i < num_rootset; i++)
		rootset[i].enumfn(forward, rootset[i].data);

	DBG(("copying root completed"));

	/* forward objects which are reachable from live objects. */
	forward_region(heap_to_space.base + INITIAL_OFFSET);

	/* check finalization */
	check_finalizer();

	/* clear from-space, and swap two spaces. */
	heap_space_clear(&heap_from_space);
	tmp_space = heap_from_space;
	heap_from_space = heap_to_space;
	heap_to_space = tmp_space;

	DBG(("gc finished. remain %d bytes",
	     heap_from_space.free - heap_from_space.base));

	/* start finalizers */
	run_finalizer();
}

void *
heap_invoke_gc_and_alloc(size_t obj_size)
{
	void *obj;

	do_gc();

	HEAP_ALLOC(obj, obj_size, NULL);

	if (obj == NULL) {
		fatal(0, "heap exceeded: intended to allocate %"PRIuMAX" bytes",
		      (intmax_t)obj_size);
	}
	return obj;
}

void *
obj_alloc(unsigned int objtype, size_t payload_size)
{
	void *obj;
	size_t alloc_size;

	alloc_size = HEAP_ROUND_SIZE(OBJ_HEADER_SIZE + payload_size);
	HEAP_ALLOC(obj, alloc_size, heap_invoke_gc_and_alloc(alloc_size));
	OBJ_HEADER(obj) = (ml_uint_t)objtype | (ml_uint_t)payload_size;

	ASSERT(OBJ_SIZE(obj) == payload_size);
	ASSERT(OBJ_TYPE(obj) == OBJTYPE_UNBOXED_VECTOR
	       || OBJ_TYPE(obj) == OBJTYPE_BOXED_VECTOR
	       || OBJ_TYPE(obj) == OBJTYPE_UNBOXED_ARRAY
	       || OBJ_TYPE(obj) == OBJTYPE_BOXED_ARRAY
	       || OBJ_TYPE(obj) == OBJTYPE_INTINF);
	ASSERT(OBJ_GC1(obj) == 0 && OBJ_GC2(obj) == 0);

	return obj;
}

void *
record_alloc(size_t payload_size)
{
	void *obj;
	size_t bitmap_size, obj_size, alloc_size;

	ASSERT(payload_size % sizeof(void*) == 0);

	bitmap_size = OBJ_BITMAPS_LEN(payload_size) * SIZEOF_BITMAP;
	obj_size = OBJ_HEADER_SIZE + payload_size + bitmap_size;
	alloc_size = HEAP_ROUND_SIZE(obj_size);
	HEAP_ALLOC(obj, alloc_size, heap_invoke_gc_and_alloc(alloc_size));
	OBJ_HEADER(obj) = OBJTYPE_RECORD | (ml_uint_t)obj_size;

	ASSERT(OBJ_SIZE(obj) == obj_size);
	ASSERT(OBJ_TYPE(obj) == OBJTYPE_RECORD);
	ASSERT(OBJ_GC1(obj) == 0 && OBJ_GC2(obj) == 0);

	return obj;
}
