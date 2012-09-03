/*
 * objspace.c - common heap management features.
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: value.c,v 1.5 2008/02/05 08:54:35 katsu Exp $
 */

#include <stdlib.h>
#include <stdint.h>
#include "smlsharp.h"
#include "object.h"
#include "heap.h"
#include "objspace.h"

/* rootset array */
struct rootset {
	struct sml_heap_thread *thread;
	sml_rootset_fn *enumfn;
	void *data;
};
static sml_obstack_t *rootset_obstack = NULL;

/* barriered slot */
static sml_obstack_t *barrier_obstack = NULL;
static sml_tree_t global_barrier;

/* malloc heap */
static sml_tree_t malloc_heap;
static size_t malloc_count;

struct malloc_obj_header {
	struct malloc_obj_header *barrier; /* list of barriered malloc object */
};
static struct malloc_obj_header barrier_list_last;
static struct malloc_obj_header *malloc_barrier_list = &barrier_list_last;

#define MALLOC_PADDING \
	ALIGNSIZE(sizeof(struct malloc_obj_header) + OBJ_HEADER_SIZE, MAXALIGN)
#define MALLOC_HEAD(objptr) \
	((struct malloc_obj_header*)((char*)(objptr) - MALLOC_PADDING))
#define MALLOC_BODY(headptr) \
	((void*)((char*)(headptr) + MALLOC_PADDING))
#define MALLOC_LIMIT  (1024 * 1024 * 4)

#define UNMARKED      ((void*)0)
#define MINOR_MARKED  ((void*)1)
#define MAJOR_MARKED  ((void*)2)

/* finalizer array */
struct finalizer {
	int active;  /* true = requested to run the finalizer. */
	void *obj;
	sml_finalizer_fn *finalize_fn;
	void *data;
};
static sml_obstack_t *finalizer_obstack = NULL;
static int finalizer_is_running = 0;

/* callback closures */
static sml_tree_t callback_closures;

static void *
barrier_node_alloc(size_t size)
{
	return sml_obstack_alloc(&barrier_obstack, size);
}

/* for debug */
static void
dump_barrier_node(void *key, void **value ATTR_UNUSED, void *data ATTR_UNUSED)
{
	sml_debug("%p, ", key);
}

/* for debug */
void
sml_objspace_dump()
{
	sml_debug("rootset :\n");
	if (rootset_obstack) {
		struct rootset *start, *end, *i;
		start = sml_obstack_base(rootset_obstack);
		end = sml_obstack_next_free(rootset_obstack);
		for (i = start; i < end; i++)
			sml_debug("enumfn=%p, data=%p\n", i->enumfn, i->data);
	}

	sml_debug("finalizers :\n");
	if (finalizer_obstack) {
		struct finalizer *start, *end, *i;
		start = sml_obstack_base(finalizer_obstack);
		end = sml_obstack_next_free(finalizer_obstack);
		for (i = start; i < end; i++) {
			sml_debug("active=%d, obj=%p, fn=%p, data=%p\n",
				  i->active, i->obj, i->finalize_fn, i->data);
		}
	}

	sml_debug("barriered :\n");
	sml_tree_traverse(global_barrier.root, dump_barrier_node, NULL);
	sml_debug("\n");
}

static int
voidp_cmp(void *x, void *y)
{
	uintptr_t m = (uintptr_t)x, n = (uintptr_t)y;
	if (m < n) return -1;
	else if (m > n) return 1;
	else return 0;
}

void
sml_objspace_init(void)
{
	global_barrier.root = NULL;
	global_barrier.cmp = voidp_cmp;
	global_barrier.alloc = barrier_node_alloc;
	global_barrier.free = NULL;

	malloc_heap.root = NULL;
	malloc_heap.cmp = voidp_cmp;
	malloc_heap.alloc = xmalloc;
	malloc_heap.free = free;

	callback_closures.root = NULL;
	callback_closures.cmp = voidp_cmp;
	callback_closures.alloc = xmalloc;
	callback_closures.free = free;
}

void
sml_objspace_free(void)
{
	/* remove all rootset. */
	if (rootset_obstack) {
		sml_obstack_shrink(&rootset_obstack,
				   sml_obstack_base(rootset_obstack));
	}

	/* remove global barrier. */
	global_barrier.root = NULL;
	sml_obstack_free(&barrier_obstack, NULL);

	/* To run finalizers forcely, invoke GC with empty root set. */
	if (finalizer_obstack) {
		while (sml_obstack_object_size(finalizer_obstack) > 0)
			sml_heap_gc();
	}

	sml_malloc_sweep(MAJOR);  /* free all malloc'ed objects */
	sml_tree_delete_all(&malloc_heap);
	sml_obstack_free(&finalizer_obstack, NULL);
	sml_obstack_free(&rootset_obstack, NULL);
}

/* root set management */

void
sml_add_rootset(sml_rootset_fn *enumfn, void *data)
{
	struct rootset *rootset;

	HEAP_LOCK();
	rootset = sml_obstack_extend(&rootset_obstack, sizeof(struct rootset));
	rootset->enumfn = enumfn;
	rootset->data = data;
	rootset->thread = SML_THREAD_ENV->heap;
	HEAP_UNLOCK();
}

void
sml_remove_rootset(sml_rootset_fn *enumfn, void *data)
{
	struct sml_heap_thread *th = SML_THREAD_ENV->heap;
	struct rootset *start, *end;
	struct rootset *i, *free;

	HEAP_LOCK();

	start = sml_obstack_base(rootset_obstack);
	end = sml_obstack_next_free(rootset_obstack);
	for (free = start, i = start; i < end; i++) {
		if (i->thread == th && i->enumfn == enumfn && i->data == data)
			continue;
		*(free++) = *i;
	}
	sml_obstack_shrink(&rootset_obstack, free);

	HEAP_UNLOCK();
}

static void
visit_barrier_node(void *key, void **value ATTR_UNUSED, void *data)
{
	sml_trace_cls *trace = data;
	(*trace)((void**)key, trace);
}

static void
visit_callback_node(void *key ATTR_UNUSED, void **value, void *data)
{
	sml_trace_cls *trace = data;
	(*trace)(value, trace);
}

void
sml_rootset_enum_ptr(sml_trace_cls *trace, enum sml_gc_mode mode)
{
	struct rootset *start, *end, *i;
	struct malloc_obj_header *head, *next;

	if (mode == MINOR) {
		ASSERT(malloc_barrier_list != NULL);
		head = malloc_barrier_list;
		if (head != &barrier_list_last) {
			do {
				next = head->barrier;
				ASSERT(next != NULL);
				sml_obj_enum_ptr(MALLOC_BODY(head), trace);
				head->barrier = NULL;
				head = next;
			} while (head != &barrier_list_last);
			malloc_barrier_list = head;
		}
	} else {
		sml_tree_traverse(global_barrier.root, visit_barrier_node,
				  (void*)trace);
		sml_tree_traverse(callback_closures.root, visit_callback_node,
				  (void*)trace);
	}

	if (rootset_obstack != NULL) {
		start = sml_obstack_base(rootset_obstack);
		end = sml_obstack_next_free(rootset_obstack);
		for (i = start; i < end; i++)
			i->enumfn(trace, mode, i->data);
	}
}

/* malloc heap */

void *
sml_obj_malloc(size_t objsize)
{
	/* objsize = payload_size + bitmap_size */
	struct malloc_obj_header *head;
	void *obj, **node;
	size_t alloc_size;

	if (malloc_count > MALLOC_LIMIT)
		sml_heap_gc();

	HEAP_LOCK();

	alloc_size = MALLOC_PADDING + objsize;
	head = xmalloc(alloc_size);
	head->barrier = NULL;
	obj = MALLOC_BODY(head);
	node = sml_splay_insert(&malloc_heap, obj);
	*node = UNMARKED;
	malloc_count += alloc_size;

	HEAP_UNLOCK();

	OBJ_HEADER(obj) = 0;
	return obj;
}

void *
sml_trace_ptr(void *obj, enum sml_gc_mode mode)
{
	/* assume HEAP_LOCK'ed */
	void **node;

	node = sml_splay_find(&malloc_heap, obj);
	if (node != NULL) {
		if (mode == MINOR) {
			if (*node == UNMARKED) {
				*node = MINOR_MARKED;
				return obj;
			}
		} else {
			if (*node != MAJOR_MARKED) {
				*node = MAJOR_MARKED;
				return obj;
			}
		}
	}
	return NULL;
}

static int
malloc_heap_sweep(void *obj, void **mark)
{
	/* assume HEAP_LOCK'ed */
	if (*mark != MAJOR_MARKED) {
		free(MALLOC_HEAD(obj));
		return 1;
	} else {
		*mark = UNMARKED;   /* clear mark */
		MALLOC_HEAD(obj)->barrier = NULL;
		return 0;
	}
}

void
sml_malloc_sweep(enum sml_gc_mode mode)
{
	/* assume HEAP_LOCK'ed */

	if (mode == MINOR) {
#ifdef DEBUG
		ASSERT(malloc_barrier_list == &barrier_list_last);
#endif /* DEBUG */
		return;
	}

	sml_splay_reject(&malloc_heap, malloc_heap_sweep);
	malloc_count = 0;
	malloc_barrier_list = &barrier_list_last;
}

/* global barrier */

void *
sml_global_barrier(void **writeaddr, void *obj, enum sml_gc_mode trace_mode)
{
	void **node, *ret;

	HEAP_LOCK();

	/* check whether obj is in malloc heap. */
	node = sml_splay_find(&malloc_heap, obj);
	if (node != NULL) {
		if (trace_mode == MINOR && *node != UNMARKED
		    && MALLOC_HEAD(obj)->barrier == NULL) {
			ASSERT(malloc_barrier_list != NULL);
			MALLOC_HEAD(obj)->barrier = malloc_barrier_list;
			malloc_barrier_list = MALLOC_HEAD(obj);
		}
		ret = NULL;
	}
	/* check whether finalizer update. */
	else if (obj == &finalizer_obstack) {
		ret = *writeaddr;
	} else {
		/* remember the writeaddr as a root pointer which is outside
		 * of the heap. */
		sml_splay_insert(&global_barrier, writeaddr);
		ret = *writeaddr;
	}

	HEAP_UNLOCK();
	return ret;
}

/* finalizer */

void *
sml_add_finalizer(void *obj, sml_finalizer_fn *fn, void *data)
{
	struct finalizer *finalizer;
	/* ASSERT(IS_IN_HEAP_SPACE(sml_heap_from_space, obj)); */

	HEAP_LOCK();

	finalizer = sml_obstack_extend(&finalizer_obstack,
				       sizeof(struct finalizer));
	finalizer->active = 0;
	finalizer->obj = obj;
	finalizer->finalize_fn = fn;
	finalizer->data = data;
	sml_write_barrier(&finalizer->obj, &finalizer_obstack);

	HEAP_UNLOCK();
	return obj;
}

void
sml_check_finalizer(enum sml_gc_mode mode, int (*survived)(void *),
		    sml_trace_cls *save)
{
	/* assume HEAP_LOCK'ed */
	struct finalizer *start, *end, *i;

	if (mode == MINOR) {
#ifdef DEBUG
		if (finalizer_obstack) {
			start = sml_obstack_base(finalizer_obstack);
			end = sml_obstack_next_free(finalizer_obstack);
			for (i = start; i < end; i++)
				ASSERT(survived(i->obj));
		}
#endif /* DEBUG */
		return;
	}

	if (finalizer_obstack == NULL)
		return;

	DBG(("check finalization"));

	start = sml_obstack_base(finalizer_obstack);
	end = sml_obstack_next_free(finalizer_obstack);

	for (i = start; i < end; i++) {
		/* forward the finalizable object if the finalizer is
		 * already in active. */
		if (i->active) {
			DBG(("%p: finalizer is active", i->obj));
			(*save)(&i->obj, save);
			continue;
		}

		/* keep inactive the finalizer if the finalizable object
		 * survived. */
		if (survived(i->obj)) {
			DBG(("%p: survived", i->obj));
			continue;
		}

		/* Forward all descendants of the finalizable object.
		 * If the object itself is forwarded during this process,
		 * there is a cyclic dependency. If the object is in cyclic
		 * dependency, we discard its finalizer in order to prevent
		 * inconsistency. */
		sml_obj_enum_ptr(i->obj, save);
		if (survived(i->obj)) {
			sml_warn(0, "%p : cyclic finalizer. discarded.",
				 i->obj);
			i->finalize_fn = NULL;
			continue;
		}
	}

	DBG(("finalizer activation"));

	for (i = start; i < end; i++) {
		if (i->active)
			continue;
		/* activate finalizer if the object is not survived.
		 * At this timing, every object with finalizer always
		 * survives here whether the finalizer is active or not. */
		i->active = !survived(i->obj);
		(*save)(&i->obj, save);
	}

	DBG(("check finalizer end"));
}

void
sml_run_finalizer()
{
	struct finalizer *start, *end, *i, *free;

	if (finalizer_obstack == NULL)
		return;

	/* If GC is invoked from a finalizer function, do nothing. */
	if (finalizer_is_running)
		return;

	DBG(("run finalizer"));

	finalizer_is_running = 1;
	start = sml_obstack_base(finalizer_obstack);
	end = sml_obstack_next_free(finalizer_obstack);

	for (free = start, i = start; i < end; i++) {
		if (!i->active) {
			*(free++) = *i;
			continue;
		}
		if (i->finalize_fn == NULL)
			continue;

		DBG(("start finalizer for %p", i->obj));
		i->finalize_fn(i->obj, i->data);
	}
	sml_obstack_shrink(&finalizer_obstack, free);

	finalizer_is_running = 0;

	DBG(("finalizer finished. %d remains.", free - start));
}

SML_PRIMITIVE void *
sml_alloc_callback(unsigned int objsize, void *codeaddr, void *envobj)
{
	void **p, **entry, *obj, **slots;

	p = sml_splay_find(&callback_closures, codeaddr);
	if (p == NULL) {
		p = sml_splay_insert(&callback_closures, codeaddr);
		*p = NULL;
	} else {
		for (entry = *p; entry; entry = entry[2]) {
			if (sml_obj_equal(envobj, entry[1]))
				return entry[0];
		}
	}

	slots = sml_push_tmp_rootset(1);
	slots[0] = envobj;
	entry = sml_obj_alloc(OBJTYPE_BOXED_VECTOR, sizeof(void*) * 3);
	entry[0] = NULL;
	entry[1] = slots[0];
	entry[2] = *p;
	*p = entry;
	obj = sml_obj_malloc(objsize);
	entry = *p;
	entry[0] = obj;

	sml_pop_tmp_rootset(slots);
	return obj;
}
