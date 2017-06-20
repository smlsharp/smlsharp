/*
 * livecheck.c - naive object tracer for GC debug
 * @copyright (c) 2015, Tohoku University.
 * @author UENO Katsuhiro
 */

#include "smlsharp.h"
#include "object.h"
#include "splay.h"
#include <stdlib.h>

struct sml_livecheck;
struct sml_livecheck *sml_livecheck(struct sml_mutator *);
void sml_livecheck_destroy(struct sml_livecheck *);
void *sml_livecheck_at(struct sml_livecheck *, void *);
void *sml_livecheck_parent(struct sml_livecheck *, void *);
void sml_livecheck_print_parents(struct sml_livecheck *s, void *obj);
void sml_livecheck_each(struct sml_livecheck *, void(*)(void *,void *), void *);


struct sml_livecheck_obj {
	void *obj;
	void **at;
	struct sml_livecheck_obj *next, *parent;
};

struct sml_livecheck {
	struct sml_livecheck_obj *top, *parent;
	sml_tree_t *tree;
};

static int
voidp_cmp(const void *x, const void *y)
{
	uintptr_t m = (uintptr_t)x, n = (uintptr_t)y;
	if (m < n) return -1;
	else if (m > n) return 1;
	else return 0;
}

static int
livecheck_obj_cmp(const void *x, const void *y)
{
	const struct sml_livecheck_obj *s1 = x, *s2 = y;
	return voidp_cmp(s1->obj, s2->obj);
}

static struct sml_livecheck *
livecheck_new()
{
	struct sml_livecheck *s;
	s = xmalloc(sizeof(struct sml_livecheck));
	s->tree = sml_tree_new(livecheck_obj_cmp,
			       sizeof(struct sml_livecheck_obj));
	s->top = NULL;
	s->parent = NULL;
	return s;
}

void
sml_livecheck_destroy(struct sml_livecheck *s)
{
	sml_tree_destroy(s->tree);
	free(s);
}

static void
livecheck_mark(void **slot, void *data)
{
	void *obj = *slot;
	struct sml_livecheck *s = data;
	struct sml_livecheck_obj key = {.obj = obj}, *i;

	if (obj == NULL) return;
	if (sml_tree_find(s->tree, &key) != NULL) return;
	i = sml_tree_insert(s->tree, &key);
	i->at = slot;
	i->parent = s->parent;
	i->next = s->top;
	s->top = i;
}

static struct sml_livecheck_obj global_root;

static void
livecheck_trace(struct sml_mutator *mutator, struct sml_livecheck *s)
{
	s->parent = &global_root;
	sml_enum_global(livecheck_mark, s);
	sml_callback_enum_ptr(livecheck_mark, s);
	if (mutator) {
		s->parent = NULL;
		sml_stack_enum_ptr(mutator, livecheck_mark, s);
	}
	while (s->top) {
		s->parent = s->top;
		s->top = s->top->next;
		if (!(OBJ_HEADER(s->parent->obj) & OBJ_FLAG_SKIP))
			sml_obj_enum_ptr(s->parent->obj, livecheck_mark, s);
	}
}

struct sml_livecheck *
sml_livecheck(struct sml_mutator *mutator)
{
	struct sml_livecheck *s;
	s = livecheck_new();
	livecheck_trace(mutator, s);
	return s;
}

static struct sml_livecheck_obj *
livecheck_find(struct sml_livecheck *s, void *obj)
{
	struct sml_livecheck_obj key = {.obj = obj};
	return sml_tree_find(s->tree, &key);
}

void *
sml_livecheck_at(struct sml_livecheck *s, void *obj)
{
	struct sml_livecheck_obj *i;
	i = livecheck_find(s, obj);
	return i ? i->at : NULL;
}

void *
sml_livecheck_parent(struct sml_livecheck *s, void *obj)
{
	struct sml_livecheck_obj *i;
	i = livecheck_find(s, obj);
	return i ? i->parent->obj : NULL;
}

void
sml_livecheck_print_parents(struct sml_livecheck *s, void *obj)
{
	struct sml_livecheck_obj *i;
	i = livecheck_find(s, obj);
	sml_debug("--BEGIN--\n");
	while (i) {
		sml_debug("%p\n", i->obj);
		i = i->parent;
	}
	sml_debug("---END---\n");
}

struct cls {
	void(*f)(void *,void *);
	void *arg;
};

static void
each(void *item, void *data)
{
	struct cls *cls = data;
	struct sml_livecheck_obj *s = item;
	cls->f(s->obj, cls->arg);
}

void
sml_livecheck_each(struct sml_livecheck *s, void(*f)(void *,void *), void *arg)
{
	struct cls cls = {f, arg};
	sml_tree_each(s->tree, each, &cls);
}
