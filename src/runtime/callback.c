/*
 * callback.c - callback closure support
 * @copyright (c) 2010-2015, Tohoku University.
 * @author UENO Katsuhiro
 */

#include "smlsharp.h"
#include <unistd.h>
#include <sys/mman.h>
#include "splay.h"

#ifndef WITHOUT_MULTITHREAD
static pthread_mutex_t callbacks_lock = PTHREAD_MUTEX_INITIALIZER;
#endif /* !WITHOUT_MULTITHREAD */

/* A callback consists of an SML# code address, an closure environment
 * object, and a trampoline code.  Two callbacks are identical if they
 * have same SML# code address and recursively-equivalent closure
 * environment.
 */
struct callback_item {
	void *ptrs[3];  /* {trampoline, env, codeaddr} */
	int count;      /* the number of entries for the same codeaddr */
	struct callback_item *next;  /* list of callbacks of same codeaddr */
};
#define cb_trampoline ptrs[0]
#define cb_env ptrs[1]
#define cb_codeaddr ptrs[2]

static sml_tree_t *callback_closures;

static struct {
	char *base, *end;
} trampoline_heap;

/* For each trampoline, 72 bytes buffer and 16 byte alignemnt is enough for
 * any platform.  80 is the minimum multiple of 16 greater than 72. */
#define TRAMPOLINE_SIZE  80

static int
voidp_cmp(const void *x, const void *y)
{
	uintptr_t m = (uintptr_t)x, n = (uintptr_t)y;
	if (m < n) return -1;
	else if (m > n) return 1;
	else return 0;
}

static int
callback_cmp(const void *x, const void *y)
{
	const struct callback_item *item1 = x, *item2 = y;
	int ret = voidp_cmp(item1->cb_codeaddr, item2->cb_codeaddr);
	return (ret != 0) ? ret : item1->count - item2->count;
	/* NOTE: Comparing item->count by subtraction is safe since
	 * item->count is a signed integer but always positive. */
}

void
sml_callback_init()
{
	callback_closures =
		sml_tree_new(callback_cmp, sizeof(struct callback_item));
}

void
sml_callback_destroy()
{
	sml_tree_destroy(callback_closures);
	/* FIXME: we cannot release memory allocated for trampoline heap
	 * since we do not keep the address ranges of its all fragments. */
}

struct trace_fn {
	void (*fn)(void **, void *);
	void *data;
};

static void
trace_each(void *item, void *data)
{
	struct trace_fn *cls = data;
	struct callback_item *cb;
	for (cb = item; cb; cb = cb->next)
		cls->fn(&cb->cb_env, cls->data);
}

void
sml_callback_enum_ptr(void (*trace)(void **, void *), void *data)
{
	struct trace_fn cls = {trace, data};
	mutex_lock(&callbacks_lock);
	sml_tree_each(callback_closures, trace_each, &cls);
	mutex_unlock(&callbacks_lock);
}

SML_PRIMITIVE void **
sml_find_callback(void *codeaddr, void *env)
{
	struct callback_item key, *item, *found;

	mutex_lock(&callbacks_lock);

	key.cb_codeaddr = codeaddr;
	key.count = 0;
	found = sml_tree_find(callback_closures, &key);
	if (found != NULL) {
		for (;;) {
			if (sml_obj_equal(env, found->cb_env)) {
				mutex_unlock(&callbacks_lock);
				return found->ptrs;
			}
			key.count++;
			if (found->next == NULL)
				break;
			found = found->next;
		}
		item = sml_tree_insert(callback_closures, &key);
		found->next = item;
	} else {
		item = sml_tree_insert(callback_closures, &key);
	}
	item->cb_codeaddr = codeaddr;
	item->cb_trampoline = NULL;
	item->cb_env = env;
	item->next = NULL;

	mutex_unlock(&callbacks_lock);
	return item->ptrs;
}

SML_PRIMITIVE void *
sml_alloc_code()
{
	void *p;
	size_t pagesize;

	mutex_lock(&callbacks_lock);

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

	mutex_unlock(&callbacks_lock);
	return p;
}
