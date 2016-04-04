/*
 * finalize.c - finalizer
 * @copyright (c) 2010-2015, Tohoku University.
 * @author UENO Katsuhiro
 */

#include "smlsharp.h"
#include "splay.h"
#include "heap.h"

/* We provide a simple finalizer mechanism only for objects that does not
 * include any reference to ML objects and other C objects to be finalized.
 * We do not check any dependency (including circularity) of finalizers.
 */

struct finalizer {
	void *obj;			/* object to be finalized */
	void (*finalizer)(void *obj);	/* the finalizer function for obj */
};

#ifndef WITHOUT_MULTITHREAD
static pthread_mutex_t finalizer_lock = PTHREAD_MUTEX_INITIALIZER;
#endif /* !WITHOUT_MULTITHREAD */
static sml_tree_t *finalizer_set;

static int
voidp_cmp(const void *x, const void *y)
{
	uintptr_t m = (uintptr_t)x, n = (uintptr_t)y;
	if (m < n) return -1;
	else if (m > n) return 1;
	else return 0;
}

static int
finalizer_cmp(const void *x, const void *y)
{
	const struct finalizer *final1 = x, *final2 = y;
	return voidp_cmp(final1->obj, final2->obj);
}

void
sml_finalize_init()
{
	finalizer_set = sml_tree_new(finalizer_cmp, sizeof(struct finalizer));
}

static void
each_destroy(void *item, void *data ATTR_UNUSED)
{
	struct finalizer *final = item;
	if (final->finalizer)
		final->finalizer(final->obj);
}

void
sml_finalize_destroy()
{
	sml_tree_each(finalizer_set, each_destroy, NULL);
	sml_tree_destroy(finalizer_set);
}

void
sml_set_finalizer(void *obj, void (*finalizer)(void *))
{
	struct finalizer *item, key;

	mutex_lock(&finalizer_lock);

	key.obj = obj;
	item = sml_tree_find(finalizer_set, &key);
	if (item == NULL)
		item = sml_tree_insert(finalizer_set, &key);
	item->finalizer = finalizer;

	mutex_unlock(&finalizer_lock);
}

static int
each_run(void *item)
{
	struct finalizer *final = item;
	if (sml_heap_check_alive(&final->obj))
		return 0;
	if (final->finalizer)
		final->finalizer(final->obj);
	return 1;
}

void
sml_run_finalizer()
{
	mutex_lock(&finalizer_lock);
	sml_tree_reject(finalizer_set, each_run);
	sml_tree_rebuild(finalizer_set);   /* for copying GC */
	mutex_unlock(&finalizer_lock);
}
