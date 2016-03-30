/*
 * dump.c
 * @copyright (c) 2015, Tohoku University.
 * @author UENO Katsuhiro
 */

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "smlsharp.h"
#include "object.h"
#include "splay.h"

#define EXTEND_STEP  (sizeof(void*) * 1024)

#define IS_POINTER_FLAG        0x1
#define POINT_TO_MUTABLE_FLAG  0x2
#define OBJECT_BEGIN_FLAG      0x4

struct forward {
	void *orig_ptr;
	uintptr_t copy_index;   /* in words */
	unsigned char flags;    /* POINT_TO_MUTABLE or not */
};

#define DUMMY_FORWARD \
	((struct forward){.orig_ptr = NULL, .copy_index = 0, .flags = 0})

/*
 * buf contains the dump memory image as an array of words (pointers).
 * Each word in buf is either an immediate value or a pointer represented
 * by an offset in words from the beginning of buf.
 * N-th byte of is_ptr indicates whether N-th word of buf is either
 * a value (is_ptr[N] == 0) or a pointer (is_ptr[N] != 0).
 */
struct to_space {
	char *buf;              /* dump image */
	size_t buf_filled;      /* in bytes */
	size_t buf_size;        /* in bytes */
	unsigned char *flags;   /* flags of the corresponding word in buf */
	char *buf_old;		/* preserved previous buf */
};

#define TO_SPACE_INIT \
	((struct to_space) \
	 {.buf = NULL, .buf_filled = 0, .buf_size = 0, \
	  .flags = NULL, .buf_old = NULL})

struct dump {
	struct to_space immutables;
	struct to_space mutables;
	sml_tree_t *forward;
};

static int
forward_cmp(const void *x, const void *y)
{
	const struct forward *x2 = x, *y2 = y;
	uintptr_t m = (uintptr_t)x2->orig_ptr, n = (uintptr_t)y2->orig_ptr;
	if (m < n) return -1;
	else if (m > n) return 1;
	else return 0;
}

static size_t
size_in_words(const struct to_space *s)
{
	return CEILING(s->buf_filled, sizeof(void*)) / sizeof(void*);
}

static const struct forward *
get_forward(struct dump *dump, void *obj)
{
	struct forward key;
	key.orig_ptr = obj;
	return sml_tree_find(dump->forward, &key);
}

static const struct forward *
put_forward(struct dump *dump, void *orig_ptr, uintptr_t copy_index,
	    unsigned char flags)
{
	struct forward key;
	key.orig_ptr = orig_ptr;
	key.copy_index = copy_index;
	key.flags = flags;
	return sml_tree_insert(dump->forward, &key);
}

static struct dump *
init()
{
	struct dump *d;
	d = xmalloc(sizeof(struct dump));
	d->immutables = TO_SPACE_INIT;
	d->mutables = TO_SPACE_INIT;
	d->forward = sml_tree_new(forward_cmp, sizeof(struct forward));
	return d;
}

static void
finish_space(struct to_space *s)
{
	if (s->buf_old && s->buf_old != s->buf) {
		free(s->buf_old);
		s->buf_old = NULL;
	}
}

static void
destroy(struct dump *d)
{
	finish_space(&d->immutables);
	finish_space(&d->mutables);
	sml_tree_destroy(d->forward);
}

#define FIRST_OFFSET CEILING(OBJ_HEADER_SIZE, MAXALIGN)

static void *
allocate(struct to_space *s, size_t obj_total_size)
{
	size_t padded = CEILING(s->buf_filled + OBJ_HEADER_SIZE, MAXALIGN);
	size_t new_filled = padded - OBJ_HEADER_SIZE + obj_total_size;
	size_t new_size;

	if (new_filled > s->buf_size) {
		new_size = CEILING(new_filled, EXTEND_STEP);
		if (s->buf_old) {
			s->buf = xrealloc(s->buf, new_size);
		} else {
			/* preserve old pointer during sml_obj_enum_ptr */
			s->buf_old = s->buf;
			s->buf = xmalloc(new_size);
			memcpy(s->buf, s->buf_old, s->buf_size);
		}
		memset(s->buf + s->buf_size, 0, new_size - s->buf_size);
		s->flags = xrealloc(s->flags, new_size / sizeof(void*));
		memset(s->flags + s->buf_size / sizeof(void*), 0,
		       (new_size - s->buf_size) / sizeof(void*));
		s->buf_size = new_size;
	}

	s->buf_filled = new_filled;

	return s->buf + padded;
}

static const struct forward *
copy(struct dump *d, void *obj)
{
	void *dst;
	size_t objsize;
	unsigned char flags;
	struct to_space *s;

	objsize = OBJ_TOTAL_SIZE(obj);
	if (OBJTYPE_IS_ARRAY(OBJ_HEADER(obj)))
		flags = POINT_TO_MUTABLE_FLAG, s = &d->mutables;
	else
		flags = 0, s = &d->immutables;
	dst = allocate(s, objsize);
	memcpy(&OBJ_HEADER(dst), &OBJ_HEADER(obj), objsize);
	OBJ_HEADER(dst) |= OBJ_FLAG_SKIP;
	return put_forward(d, obj, (void**)dst - (void**)s->buf, flags);
}

struct trace_arg {
	struct dump *d;
	struct to_space *s;
};

static void
trace(void **slot, void *arg)
{
	struct trace_arg *t = arg;
	struct dump *d = t->d;
	struct to_space *s = t->s;
	void *obj = *slot;
	void **begin;
	const struct forward *fwd;

	if (*slot == NULL)
		return;

	fwd = get_forward(d, obj);
	if (!fwd)
		fwd = copy(d, obj);

	begin = (void**)(s->buf_old ? s->buf_old : s->buf);
	s->flags[slot - begin] |= fwd->flags | IS_POINTER_FLAG;
	*slot = (void*)fwd->copy_index;
}

static size_t
forward_space(struct dump *d, struct to_space *s, size_t start)
{
	struct trace_arg arg = {d, s};
	size_t cur = start;
	void *obj;

	while (cur < s->buf_filled) {
		obj = s->buf + cur;
		s->flags[cur / sizeof(void*)] |= OBJECT_BEGIN_FLAG;
		sml_obj_enum_ptr(obj, trace, &arg);
		cur += CEILING(OBJ_TOTAL_SIZE(obj), MAXALIGN);
		if (s->buf_old) {
			free(s->buf_old);
			s->buf_old = NULL;
		}
	}
	return cur;
}

static void
forward_all(struct dump *d)
{
	size_t cur_imm = FIRST_OFFSET, cur_mut = FIRST_OFFSET;
	size_t new_imm, new_mut;

	for (;;) {
		new_imm = forward_space(d, &d->immutables, cur_imm);
		new_mut = forward_space(d, &d->mutables, cur_mut);
		if (new_imm == cur_imm && new_mut == cur_mut)
			break;
		cur_imm = new_imm;
		cur_mut = new_mut;
	}
}

void
sml_dump_heap(void *obj,
	      void ***immutables_dump_ret,
	      unsigned char **immutables_flags_ret,
	      unsigned int *immutables_words_ret,
	      void ***mutables_dump_ret,
	      unsigned char **mutables_flags_ret,
	      unsigned int *mutables_words_ret,
	      unsigned int *first_index_ret,
	      unsigned char *first_flags_ret)
{
	struct dump *d;
	const struct forward *fwd;

	d = init();
	fwd = obj ? copy(d, obj) : &DUMMY_FORWARD;
	forward_all(d);

	*immutables_dump_ret = (void**)d->immutables.buf;
	*immutables_flags_ret = d->immutables.flags;
	*immutables_words_ret = size_in_words(&d->immutables);
	*mutables_dump_ret = (void**)d->mutables.buf;
	*mutables_flags_ret = d->mutables.flags;
	*mutables_words_ret = size_in_words(&d->mutables);
	*first_index_ret = fwd->copy_index;
	*first_flags_ret = fwd->flags;

	destroy(d);
}
