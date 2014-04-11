/*
 * objspace.c - common heap management features.
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: value.c,v 1.5 2008/02/05 08:54:35 katsu Exp $
 */

#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/mman.h>
#ifdef MULTITHREAD
#include <pthread.h>
#endif /* MULTITHREAD */
#include "smlsharp.h"
#include "object.h"
#include "objspace.h"
#include "splay.h"
#include "heap.h"

#ifdef MULTITHREAD
void sml_mutex_lock(pthread_mutex_t *m);

static void
mutex_lock(pthread_mutex_t *m)
{
	if (pthread_mutex_lock(m) != 0)
		sml_sysfatal("pthread_mutex_lock failed");
}

static void
mutex_unlock(pthread_mutex_t *m)
{
	if (pthread_mutex_unlock(m) != 0)
		sml_sysfatal("pthread_mutex_unlock failed");
}
#else
#define sml_mutex_lock(m) ((void)0)
#define mutex_lock(m)     ((void)0)
#define mutex_unlock(m)   ((void)0)
#endif /* MULTITHREAD */

#ifdef MULTITHREAD
/* lock for global variables, callbacks, and the trampoline heap */
pthread_mutex_t global_stuffs_lock = PTHREAD_MUTEX_INITIALIZER;
#endif /* MULTITHREAD */

/* tree node allocator for persistent trees. */
static sml_obstack_t *persistent_node_obstack = NULL;
static void *persistent_node_alloc(size_t size);

/* global variable slots */
static int voidp_cmp(void *, void *);
static sml_tree_t global_barrier =
	SML_TREE_INITIALIZER(voidp_cmp, persistent_node_alloc, NULL);

/* global callback closures */
static int callback_cmp(void *, void *);
static sml_tree_t callback_closures =
	SML_TREE_INITIALIZER(callback_cmp, persistent_node_alloc, NULL);

struct callback_item {
	void *ptrs[3];  /* {trampoline, env, codeaddr} */
	struct callback_item *next;
};
#define cb_trampoline ptrs[0]
#define cb_env ptrs[1]
#define cb_codeaddr ptrs[2]

/* trampoline heap */
static struct {
	char *base;
	char *end;
} trampoline_heap;

/* For each trampoline, 72 bytes buffer and 16 byte alignemnt is enough for
 * any platform.  80 is the minimum multiple of 16 greater than 72. */
#define TRAMPOLINE_SIZE  80

/* malloc heap */

#ifdef MULTITHREAD
pthread_mutex_t malloc_heap_lock = PTHREAD_MUTEX_INITIALIZER;
#endif /* MULTITHREAD */

static sml_tree_t malloc_heap =
	SML_TREE_INITIALIZER(voidp_cmp, xmalloc, free);
static size_t malloc_count;

struct malloc_obj_header {
	struct malloc_obj_header *next;  /* next object in the stack */
	unsigned int flags;
};

#define MALLOC_FLAG_REMEMBER  0x1
#define MALLOC_FLAG_TRACED    0x2

/* top of mark stack.
 * mark stack is used not only for collection but also remembered set for
 * the next minor collection.
 */
static struct malloc_obj_header *malloc_stack_top = NULL;

#define MALLOC_PADDING \
	ALIGNSIZE(sizeof(struct malloc_obj_header) + OBJ_HEADER_SIZE, MAXALIGN)
#define MALLOC_HEAD(objptr) \
	((struct malloc_obj_header*)((char*)(objptr) - MALLOC_PADDING))
#define MALLOC_BODY(headptr) \
	((void*)((char*)(headptr) + MALLOC_PADDING))
#define MALLOC_LIMIT  (1024 * 1024 * 4)

/* finalizer */

#ifdef MULTITHREAD
pthread_mutex_t finalizer_lock = PTHREAD_MUTEX_INITIALIZER;
#endif /* MULTITHREAD */

struct finalizer {
	struct finalizer *next;   /* for linked list */
	void *obj;
	void (*finalizer)(void *);
	int active;  /* true = requested to run the finalizer. */
};

static int finalizer_cmp(void *, void *);
static sml_tree_t finalizer_set =
	SML_TREE_INITIALIZER(finalizer_cmp, xmalloc, free);
static struct finalizer *active_finalizers;

static void *
persistent_node_alloc(size_t size)
{
	return sml_obstack_alloc(&persistent_node_obstack, size);
}

/* for debug */
static void
dump_malloc(void *item, void *data ATTR_UNUSED)
{
	sml_notice("%p (flags=%08x, size=%lu)", item,
		   MALLOC_HEAD(item)->flags, (unsigned long)OBJ_SIZE(item));
}

/* for debug */
static void
dump_finalizer(void *item, void *data ATTR_UNUSED)
{
	struct finalizer *final = item;
	sml_notice("active=%d, obj=%p, fn=%p",
		   final->active, final->obj, final->finalizer);
}

/* for debug */
static void
dump_callback(void *item, void *data ATTR_UNUSED)
{
	struct callback_item *cls = item;
	while (cls) {
		sml_notice("trampoline=%p, codeaddr=%p, env=%p",
			   cls->cb_trampoline, cls->cb_codeaddr, cls->cb_env);
		cls = cls->next;
	}
}

/* for debug */
static void
dump_barrier(void *item, void *data ATTR_UNUSED)
{
	sml_notice("%p -> %p", item, *(void**)item);
}

/* for debug */
void
sml_objspace_dump()
{
	struct malloc_obj_header *p;
	sml_notice("malloc :");
	sml_tree_each(&malloc_heap, dump_malloc, NULL);
	sml_notice("finalizers :");
	sml_tree_each(&finalizer_set, dump_finalizer, NULL);
	sml_notice("callbacks :");
	sml_tree_each(&callback_closures, dump_callback, NULL);
	sml_notice("barriered :");
	sml_tree_each(&global_barrier, dump_barrier, NULL);
	sml_notice("mark stack :");
	for (p = malloc_stack_top; p; p = p->next)
		dump_malloc(MALLOC_BODY(p), NULL);
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
	/* currently nothing to do */
}

void
sml_objspace_free(void)
{
	ASSERT(sml_num_threads() == 0);

	/* free all global stuffs */
	callback_closures.root = NULL;
	global_barrier.root = NULL;

#ifndef FAIR_COMPARISON
//	sml_control_start();
	/* To run finalizers forcely, invoke GC with empty root set. */
//	while (finalizer_set.root != NULL)
//		sml_heap_gc();

	/* free all malloc'ed objects */
//	sml_malloc_sweep(MAJOR);

//	sml_control_finish();
#endif /* FAIR_COMPARISON */

	sml_obstack_free(&persistent_node_obstack, NULL);
}

/* malloc heap */

void *
sml_obj_malloc(size_t objsize)
{
	/* objsize = payload_size + bitmap_size */
	struct malloc_obj_header *head;
	void *obj;
	size_t alloc_size;

	sml_mutex_lock(&malloc_heap_lock);

	if (malloc_count > MALLOC_LIMIT) {
		mutex_unlock(&malloc_heap_lock);
		sml_heap_gc();
		sml_mutex_lock(&malloc_heap_lock);
	}

	alloc_size = MALLOC_PADDING + objsize;
	head = xmalloc(alloc_size);
	obj = MALLOC_BODY(head);
	sml_tree_insert(&malloc_heap, obj);
	malloc_count += alloc_size;

	/* if the new object is an immutable object such as record, ML
	 * object pointer may be stored without write barrier during
	 * initialization of the new object. */
	head->next = malloc_stack_top;
	malloc_stack_top = head;
	head->flags = MALLOC_FLAG_REMEMBER;

	mutex_unlock(&malloc_heap_lock);

	OBJ_HEADER(obj) = 0;
	return obj;
}

void
sml_trace_ptr(void *obj)
{
	/* assume that malloc heap is exclusively locked */

	if (sml_tree_find(&malloc_heap, obj)) {
		struct malloc_obj_header *head = MALLOC_HEAD(obj);
		ASSERT(head->flags != 0 || head->next == NULL);
		if (head->flags == 0) {
			head->next = malloc_stack_top;
			malloc_stack_top = head;
		}
		head->flags |= MALLOC_FLAG_TRACED;
	}
}

static void
malloc_barrier(void *obj)
{
	struct malloc_obj_header *head = MALLOC_HEAD(obj);

	/* assume that malloc heap is exclusively locked */

	ASSERT(head->flags == MALLOC_FLAG_REMEMBER
	       || (head->flags == 0 && head->next == NULL));
	if (head->flags == 0) {
		head->flags |= MALLOC_FLAG_REMEMBER;
		head->next = malloc_stack_top;
		malloc_stack_top = head;
	}
}

int
sml_malloc_pop_and_mark(void (*trace)(void **), enum sml_gc_mode mode)
{
	struct malloc_obj_header *head;
	int found = 0;

	/* assume that malloc heap is exclusively locked */

	if (mode == MINOR) {
		/* check only remembered set */
		while (malloc_stack_top) {
			head = malloc_stack_top;
			malloc_stack_top = malloc_stack_top->next;
			if (head->flags & MALLOC_FLAG_REMEMBER) {
				sml_obj_enum_ptr(MALLOC_BODY(head), trace);
				found = 1;
			}
			head->next = NULL;
			head->flags = 0;
		}
	} else {
		/* check only traced objects */
		while (malloc_stack_top) {
			head = malloc_stack_top;
			malloc_stack_top = malloc_stack_top->next;
			head->next = NULL;
			if (head->flags & MALLOC_FLAG_TRACED) {
				sml_obj_enum_ptr(MALLOC_BODY(head), trace);
				found = 1;
			} else {
				head->flags = 0;
			}
		}
	}

	return found;
}

static int
malloc_heap_sweep(void *item)
{
	void **obj = item;
	struct malloc_obj_header *head = MALLOC_HEAD(obj);

	ASSERT(head->next == NULL);

	if (head->flags == 0) {   /* unmarked */
		free(head);
		return 1;
	} else {
		head->flags = 0;  /* clear mark */
		return 0;
	}
}

void
sml_malloc_sweep(enum sml_gc_mode mode)
{
	/* assume that malloc heap is exclusively locked */

	ASSERT(malloc_stack_top == NULL);

	if (mode == MINOR)
		return;

	sml_tree_reject(&malloc_heap, malloc_heap_sweep);
	malloc_count = 0;
}

/* root set management */

static void
each_barrier(void *item, void *data)
{
	void (**trace)(void **) = data;
	void **addr = item;
	(*trace)(addr);
}

void
sml_objspace_gc_initiate(void (*trace)(void **), enum sml_gc_mode mode)
{
	/* monopolize everything during garbage collection */
	mutex_lock(&global_stuffs_lock);
	mutex_lock(&finalizer_lock);
	mutex_lock(&malloc_heap_lock);

	if (mode != MINOR) {
		/* global_barrier includes every addresses in
		 * callback_closures where holds an ML object. */
		sml_tree_each(&global_barrier, each_barrier, &trace);
	}
}

void
sml_objspace_gc_done()
{
	mutex_unlock(&malloc_heap_lock);
	mutex_unlock(&finalizer_lock);
	mutex_unlock(&global_stuffs_lock);
}

/* global barrier */

void
sml_global_barrier(void **writeaddr, void *obj)
{
	sml_mutex_lock(&malloc_heap_lock);

	/* check whether obj is in malloc heap. */
	if (sml_tree_find(&malloc_heap, obj)) {
		malloc_barrier(obj);
		mutex_unlock(&malloc_heap_lock);
	} else {
		mutex_unlock(&malloc_heap_lock);
		/* There is a reference to an ML object from outside.
		 * remember the writeaddr as a root set. */
		sml_mutex_lock(&global_stuffs_lock);
		sml_tree_insert(&global_barrier, writeaddr);
		mutex_unlock(&global_stuffs_lock);
	}
}

/* finalizer */

static int
finalizer_cmp(void *x, void *y)
{
	struct finalizer *final1 = x;
	struct finalizer *final2 = y;
	return voidp_cmp(final1->obj, final2->obj);
}

void
sml_set_finalizer(void *obj, void (*finalizer)(void *))
{
	struct finalizer *final, key;

	sml_mutex_lock(&finalizer_lock);

	key.obj = obj;

	if (finalizer == NULL) {
		sml_tree_delete(&finalizer_set, &key);
		mutex_unlock(&finalizer_lock);
		return;
	}

	final = sml_tree_find(&finalizer_set, &key);
	if (final == NULL) {
		ASSERT(sml_tree_find(&malloc_heap, obj));
		final = xmalloc(sizeof(struct finalizer));
		final->active = 0;
		final->obj = obj;
		sml_tree_insert(&finalizer_set, final);
	}

	/* obj is a malloc'ed object. No need to call write barrier. */
	ASSERT(final->active == 0);
	final->finalizer = finalizer;

	mutex_unlock(&finalizer_lock);
}

static void
each_check_finalizer(void *item, void *data)
{
	void (**p_trace_rec)(void **) = data;
	void (*trace_rec)(void **) = *p_trace_rec;
	struct finalizer *final = item;

	/* assume that malloc heap and finalizer is exclusively locked */

	if (final->finalizer == NULL)
		return;

	if (MALLOC_HEAD(final->obj)->flags & MALLOC_FLAG_TRACED) {
		DBG(("%p: survived", final->obj));
		return;
	}

	/* Save all descendants of the finalizable object.
	 * If the object itself is forwarded during this process,
	 * there is a cyclic dependency. If so, we discard its
	 * finalizer in order to prevent inconsistency. */
	for(;;) {
		sml_obj_enum_ptr(final->obj, trace_rec);
		if (malloc_stack_top == NULL)
			break;
		sml_malloc_pop_and_mark(trace_rec, MAJOR);
	}

	if (MALLOC_HEAD(final->obj)->flags & MALLOC_FLAG_TRACED) {
		sml_warn(0, "%p : circular finalizer detected."
			 " The finalizer is discarded to prevent"
			 " inconsistency.", final->obj);
		final->finalizer = NULL;
	}
}

static int
each_activate_finalizer(void *item)
{
	struct finalizer *final = item;

	/* assume that malloc heap and finalizer is exclusively locked */

	if (final->finalizer == NULL)
		return 1;

	if (!(MALLOC_HEAD(final->obj)->flags & MALLOC_FLAG_TRACED)) {
		DBG(("%p: activated", final->obj));
		final->active = 1;
		MALLOC_HEAD(final->obj)->flags |= MALLOC_FLAG_TRACED;
	} else {
		final->active = 0;
	}
	return 0;
}

void
sml_check_finalizer(void (*trace_rec)(void **), enum sml_gc_mode mode)
{
	/* assume that malloc heap and finalizer is exclusively locked */

	if (mode == MINOR)
		return;

	sml_tree_each(&finalizer_set, each_check_finalizer, &trace_rec);
	sml_tree_reject(&finalizer_set, each_activate_finalizer);
}

static int
each_run_finalizer(void *item)
{
	struct finalizer *final = item;

	/* assume that finalizer is exclusively locked */

	if (final->active) {
		final->next = active_finalizers;
		active_finalizers = final;
		return 1;
	}
	return 0;
}

void *
sml_run_finalizer(void *reserved_obj)
{
	struct finalizer *final, *next;
	void **slot = NULL;

	/* During execution of finalizers, garbage collection may occur
	 * and eventually the new object allocated by the caller of
	 * sml_run_finalizer may be lost. To protect the new object from
	 * garbage collection, we put the new object to root set.
	 */
	if (reserved_obj) {
		slot = sml_tmp_root();
		*slot = reserved_obj;
		OBJ_HEADER(reserved_obj) = OBJ_DUMMY_HEADER;
	}

	sml_mutex_lock(&finalizer_lock);

	/* If there is at least one active finalizer, do nothing. */
	if (active_finalizers != NULL) goto finished;
	sml_tree_reject(&finalizer_set, each_run_finalizer);

	DBG(("run finalizer"));

	for (final = active_finalizers; final; final = next) {
		next = final->next;
		if (final->finalizer) {
			DBG(("start finalizer for %p", final->obj));
			mutex_unlock(&finalizer_lock);
			final->finalizer(final->obj);
			sml_mutex_lock(&finalizer_lock);
		}
		free(final);
	}

	DBG(("finished"));

	active_finalizers = NULL;
 finished:
	mutex_unlock(&finalizer_lock);
	if (slot) {
		reserved_obj = *slot;
		*slot = NULL;
	}
	return reserved_obj;
}

/**** callback closures ****/

static int
callback_cmp(void *x, void *y)
{
	struct callback_item *item1 = x, *item2 = y;
	return voidp_cmp(item1->cb_codeaddr, item2->cb_codeaddr);
}

SML_PRIMITIVE void **
sml_find_callback(void *codeaddr, void *env)
{
	struct callback_item key, *item, *prev;

	sml_mutex_lock(&global_stuffs_lock);

	key.cb_codeaddr = codeaddr;
	prev = sml_tree_find(&callback_closures, &key);
	if (prev != NULL) {
		for (item = prev; item; item = item->next) {
			if (sml_obj_equal(env, item->cb_env)) {
				mutex_unlock(&global_stuffs_lock);
				return item->ptrs;
			}
		}
	}

	/* This is safe since sizeof(struct callback_item) is equal to
	 * sizeof(struct sml_tree_node). */
	item = persistent_node_alloc(sizeof(struct callback_item));

	item->cb_trampoline = NULL;
	item->cb_env = env;
	item->cb_codeaddr = codeaddr;
	item->next = prev;
 	sml_tree_insert(&callback_closures, item);

	/* remember callback closure as a part of root set. */
	if (item->cb_env)
		sml_tree_insert(&global_barrier, &item->cb_env);

	mutex_unlock(&global_stuffs_lock);

	return item->ptrs;
}

SML_PRIMITIVE void *
sml_alloc_code()
{
	void *p;
	size_t pagesize;

	sml_mutex_lock(&global_stuffs_lock);

	if (trampoline_heap.end - trampoline_heap.base < TRAMPOLINE_SIZE) {
		pagesize = getpagesize();
		p = mmap(NULL, pagesize,
			 PROT_READ | PROT_WRITE | PROT_EXEC,
			 MAP_ANON | MAP_PRIVATE,
			 -1, 0);
		if (p == MAP_FAILED)
			sml_sysfatal("mmap");
		trampoline_heap.base = p;
		trampoline_heap.end = (char*)p + pagesize;
	}

	p = trampoline_heap.base;
	trampoline_heap.base += TRAMPOLINE_SIZE;

	mutex_unlock(&global_stuffs_lock);

	return p;
}
