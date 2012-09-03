/*
 * frame.c
 * @copyright (c) 2007-2010, Tohoku University.
 * @author UENO Katsuhiro
 */

#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <setjmp.h>
#ifdef MULTITHREAD
#include <pthread.h>
#endif /* MULTITHREAD */
#include "smlsharp.h"
#include "object.h"
#include "frame.h"
#include "objspace.h"
#include "heap.h"
#include "control.h"

struct sml_control {
	void *frame_stack_top;
	void *frame_stack_bottom;
	void *current_handler;
	void *heap;
	enum {RUNNING, SUSPENDED, STOPPED_BY_STW} state;
	jmp_buf *exn_jmpbuf;          /* longjmp if uncaught exception error */
	sml_obstack_t *tmp_root;      /* temporary root slots of GC. */
	struct sml_control *prev, *next;  /* for double-linked list */
#ifdef DEBUG
	const char *giant_lock_at;    /* request GIANT_LOCK here. */
#endif /* DEBUG */
};

static struct sml_control *control_blocks;

#ifdef MULTITHREAD
static pthread_key_t control_key;
#else
static struct sml_control *global_control;
#endif /* MULTITHREAD */

static struct sml_control *
get_current_control()
{
#ifdef MULTITHREAD
	return pthread_getspecific(control_key);
#else
	return global_control;
#endif /* MULTITHREAD */
}

static void
set_current_control(struct sml_control *control)
{
#ifdef MULTITHREAD
	pthread_setspecific(control_key, control);
#else
	global_control = control;
#endif /* MULTITHREAD */
}

/* the giant lock */
#ifdef MULTITHREAD

static pthread_mutex_t giant_lock_mutex;
static volatile unsigned int stop_the_world_flag;
volatile unsigned int sml_check_gc_flag;
static pthread_cond_t control_state_changed_cond;

#ifdef DEBUG
int
sml_giant_locked()
{
	return get_current_control()->giant_lock_at != NULL;
}

int
sml_is_no_thread()
{
	return control_blocks == NULL;
}
#endif /* DEBUG */

void
#ifdef DEBUG
sml_giant_lock(void *frame_pointer, const char *lock_at)
#else
sml_giant_lock(void *frame_pointer)
#endif /* DEBUG */
{
	struct sml_control *control;
	int err ATTR_UNUSED;

	ASSERT(get_current_control() != NULL);
#ifdef DEBUG
	ASSERT(lock_at);
	get_current_control()->giant_lock_at = lock_at;
#endif /* DEBUG */

	err = pthread_mutex_lock(&giant_lock_mutex);
	ASSERT(err == 0);
	if (!stop_the_world_flag)
		return;

	DBG(("STOP THE WORLD RECEIVED: %p", pthread_self()));
	if (frame_pointer)
		sml_save_frame_pointer(frame_pointer);
	control = get_current_control();
	sml_heap_thread_stw_hook(control->heap);
	control->state = STOPPED_BY_STW;
	pthread_cond_broadcast(&control_state_changed_cond);
	do {
		pthread_cond_wait(&control_state_changed_cond, &giant_lock_mutex);
	} while (stop_the_world_flag);
	control->state = RUNNING;
}

void
sml_giant_unlock()
{
	int err ATTR_UNUSED;
	err = pthread_mutex_unlock(&giant_lock_mutex);
#ifdef DEBUG
	get_current_control()->giant_lock_at = NULL;
#endif /* DEBUG */
	ASSERT(err == 0);
}

static int
is_the_world_stopped()
{
	struct sml_control *control;

	ASSERT(GIANT_LOCKED());

	for (control = control_blocks; control; control = control->prev) {
		if (control->state == RUNNING)
			return 0;
	}
	return 1;
}

void
sml_stop_the_world()
{
	struct sml_control *control, *c;

	ASSERT(GIANT_LOCKED());
	ASSERT(get_current_control() != NULL);

	stop_the_world_flag = 1;
	sml_check_gc_flag = 1;
	DBG(("STOP THE WORLD: %p", pthread_self()));
	control = get_current_control();
	sml_heap_thread_stw_hook(control->heap);
	control->state = STOPPED_BY_STW;
	while (!is_the_world_stopped()) {
		pthread_cond_wait(&control_state_changed_cond, &giant_lock_mutex);
	}

	for (c = control_blocks; c; c = c->prev) {
		if (c->state == SUSPENDED)
			sml_heap_thread_stw_hook(c->heap);
	}

	control->state = RUNNING;
	DBG(("STOP THE WORLD COMPLETE: %p", pthread_self()));
}

void
sml_run_the_world()
{
	ASSERT(GIANT_LOCKED());

	stop_the_world_flag = 0;
	sml_check_gc_flag = 0;
	pthread_cond_broadcast(&control_state_changed_cond);
	DBG(("RUN THE WORLD : %p", pthread_self()));
}

#endif /* MULTITHREAD */

#ifdef MULTITHREAD
/* GIANT_LOCK without stop-the-world */
#define GIANT_LOCK_LIGHT() do { \
	int err ATTR_UNUSED; \
	err = pthread_mutex_lock(&giant_lock_mutex); \
	ASSERT(err == 0); \
} while (0)
#define GIANT_UNLOCK_LIGHT() do { \
	int err ATTR_UNUSED; \
	err = pthread_cond_broadcast(&control_state_changed_cond); \
	ASSERT(err == 0); \
	err = pthread_mutex_unlock(&giant_lock_mutex); \
	ASSERT(err == 0); \
} while (0)
#else
#define GIANT_LOCK_LIGHT()    ((void)0)
#define GIANT_UNLOCK_LIGHT()  ((void)0)
#endif /* MULTITHREAD */

#ifdef MULTITHREAD
SML_PRIMITIVE void
sml_check_gc(void *frame_pointer)
{
	GIANT_LOCK(frame_pointer);
	GIANT_UNLOCK();
}
#endif /* MULTITHREAD */

static void
attach_control(struct sml_control *control)
{
	/* do not use GIANT_LOCK in order to prevent stop-the-world */
	GIANT_LOCK_LIGHT();

	control->prev = control_blocks;
	control->next = NULL;
	if (control->prev)
		control->prev->next = control;
	control_blocks = control;

	GIANT_UNLOCK_LIGHT();
}

static void
detach_control(struct sml_control *control)
{
	/* do not use GIANT_LOCK in order to prevent stop-the-world */
	GIANT_LOCK_LIGHT();

	if (control->prev)
		control->prev->next = control->next;
	if (control->next)
		control->next->prev = control->prev;
	else
		control_blocks = control->prev;

	GIANT_UNLOCK_LIGHT();
}

static void control_finalize(void *control_ptr);

void
sml_control_init()
{
#ifdef MULTITHREAD
	int ret;
#ifdef DEBUG
	pthread_mutexattr_t attr;
	pthread_mutexattr_init(&attr);
	pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ERRORCHECK);
#endif /* DEBUG */
	ret = pthread_key_create(&control_key, control_finalize);
	if (ret != 0)
		sml_sysfatal("pthread_key_create failed");

#ifdef DEBUG
	if (pthread_mutex_init(&giant_lock_mutex, &attr) != 0)
		sml_sysfatal("pthread_mutex_init failed");
	pthread_mutexattr_destroy(&attr);
#else
	if (pthread_mutex_init(&giant_lock_mutex, NULL) != 0)
		sml_sysfatal("pthread_mutex_init failed");
#endif /* DEBUG */
	if (pthread_cond_init(&control_state_changed_cond, NULL) != 0)
		sml_sysfatal("pthread_cond_init failed");
#endif /* MULTITHREAD */
}

void
sml_control_free()
{
#ifdef MULTITHREAD
	/* FIXME: wait until all SML threads are finished. */

	pthread_cond_destroy(&control_state_changed_cond);
	pthread_mutex_destroy(&giant_lock_mutex);
	pthread_key_delete(control_key);
#endif /* MULTITHREAD */
}

SML_PRIMITIVE void
sml_control_start(void *frame_pointer)
{
	struct sml_control *control = get_current_control();

	if (control == NULL) {
		control = xmalloc(sizeof(struct sml_control));
		control->frame_stack_top = frame_pointer;
		control->frame_stack_bottom = frame_pointer;
		control->current_handler = NULL;
		control->state = RUNNING;
		control->heap = NULL;
		control->exn_jmpbuf = NULL;
		control->tmp_root = NULL;
#ifdef DEBUG
		control->giant_lock_at = NULL;
#endif /* DEBUG */
		control->heap = sml_heap_thread_init();
		set_current_control(control);
		attach_control(control);
		DBG(("START NEW THREAD : %p %u", pthread_self(),
		     sml_num_threads()));
	} else {
		FRAME_HEADER(frame_pointer) |= FRAME_FLAG_SKIP;
		FRAME_EXTRA(frame_pointer) =
			(uintptr_t)control->frame_stack_top;
		control->frame_stack_top = frame_pointer;
		control->state = RUNNING;
	}

}

static void
control_finalize(void *control_ptr)
{
	struct sml_control *control = control_ptr;

	if (control == NULL)
		return;

	detach_control(control);
	sml_heap_thread_free(control->heap);
	sml_obstack_free(&control->tmp_root, NULL);
	free(control);
	set_current_control(NULL);
}

SML_PRIMITIVE void
sml_control_finish(void *frame_pointer)
{
	struct sml_control *control = get_current_control();

	if (control->frame_stack_bottom == frame_pointer) {
		DBG(("FINISH THREAD : %p %u", pthread_self(),
		     sml_num_threads()));
		control_finalize(control);
	} else {
		ASSERT(FRAME_HEADER(frame_pointer) & FRAME_FLAG_SKIP);
		control->frame_stack_top = (void*)FRAME_EXTRA(frame_pointer);
	}
}

/*
 * prepares new "num_slots" pointer slots which are part of root set of garbage
 * collection, and returns the address of array of the new pointer slots.
 * These pointer slots are available until sml_pop_tmp_rootset() is called.
 * Returned address is only available in the same thread.
 */
void **
sml_push_tmp_rootset(size_t num_slots)
{
	struct sml_control *control = get_current_control();
	void **ret;
	unsigned int i;

	ret = sml_obstack_alloc(&control->tmp_root, sizeof(void*) * num_slots);
	for (i = 0; i < num_slots; i++)
		ret[i] = NULL;
	return ret;
}

/*
 * releases last pointer slots allocated by sml_push_tmp_rootset()
 * in the same thread.
 */
void
sml_pop_tmp_rootset(void **slots)
{
	struct sml_control *control = get_current_control();
	sml_obstack_free(&control->tmp_root, slots);
}

SML_PRIMITIVE void
sml_save_frame_pointer(void *p)
{
	get_current_control()->frame_stack_top = p;
}

void *
sml_load_frame_pointer()
{
	return get_current_control()->frame_stack_top;
}

void *
sml_current_thread_heap()
{
	return get_current_control()->heap;
}

SML_PRIMITIVE void
sml_push_handler(void *handler)
{
	/* The detail of structure of handler is platform-dependent except
	 * that runtime may use *(void**)handler for handler chain. */
	struct sml_control *control = get_current_control();

	*((void**)handler) = control->current_handler;

	/* assume that this assignment is atomic so that asynchronous signal
	 * may raise an exception. */
	control->current_handler = handler;

	/*DBG(("ip=%p from %p", ((void**)handler)[1],
	  __builtin_return_address(0)));*/
}

SML_PRIMITIVE void *
sml_pop_handler(void *exn)
{
	struct sml_control *control = get_current_control();
	void *handler = control->current_handler;
	void *prev;
	jmp_buf *buf;

	if (handler == NULL) {
		/* uncaught exception */
		buf = control->exn_jmpbuf;
		control_finalize(control);
		if (buf) {
			longjmp(*buf, 1);
		} else {
			sml_error(0, "uncaught exception: %s",
				  sml_exn_name(exn));
			abort();
		}
	}

	prev = *((void**)handler);

	/* assume that this assignment is atomic so that asynchronous signal
	 * may raise an exception. */
	control->current_handler = prev;

	/*DBG(("ip=%p from %p", ((void**)handler)[1],
	  __builtin_return_address (0)));*/

	return handler;
}

static void
frame_enum_ptr(void *frame_info, void (*trace)(void **))
{
	void **boxed;
	unsigned int *sizes, *bitmaps, num_generics, num_boxed;
	unsigned int i, j, num_slots;
	ptrdiff_t offset;
	char *generic;

	num_boxed = FRAME_NUM_BOXED(frame_info);
	num_generics = FRAME_NUM_GENERIC(frame_info);
	boxed = FRAME_BOXED_PART(frame_info);

	for (i = 0; i < num_boxed; i++) {
		if (*boxed)
			trace(boxed);
		boxed++;
	}

	offset = (char*)boxed - (char*)frame_info;
	offset = ALIGNSIZE(offset, sizeof(unsigned int));
	sizes = (unsigned int *)(frame_info + offset);
	bitmaps = sizes + num_generics;
	generic = frame_info;

	for (i = 0; i < num_generics; i++) {
		num_slots = sizes[i];
		if (BITMAP_BIT(bitmaps, i) == TAG_UNBOXED) {
			generic -= num_slots * SIZEOF_GENERIC;
		} else {
			for (j = 0; j < num_slots; j++) {
				generic -= SIZEOF_GENERIC;
				trace((void**)generic);
			}
		}
	}
}

static void
stack_enum_ptr(void (*trace)(void **), enum sml_gc_mode mode,
	       void *frame_stack_top, void *frame_stack_bottom)
{
	void *fp = frame_stack_top;
	uintptr_t header;
	intptr_t offset;

	for (;;) {
		header = FRAME_HEADER(fp);
#ifdef DEBUG
		if (mode != TRY_MAJOR)
#endif /* DEBUG */
			FRAME_HEADER(fp) = header | FRAME_FLAG_VISITED;

		offset = FRAME_INFO_OFFSET(header);
		if (offset != 0)
			frame_enum_ptr((char*)fp + offset, trace);

		/* When MINOR tracing, we need to trace not only unvisited
		 * frames but also the first frame of visited frames since
		 * the first frame may be modified by ML code from the
		 * previous frame tracing.
		 */
		if (mode == MINOR && (header & FRAME_FLAG_VISITED)) {
			DBG(("%p: visited frame.", fp));
			break;
		}

		if (fp == frame_stack_bottom)
			break;

		if (header & FRAME_FLAG_SKIP)
			fp = (void*)FRAME_EXTRA(fp);
		else
			fp = FRAME_NEXT(fp);
	}

	DBG(("frame end"));
}

int
sml_protect(void (*func)(void *), void *data)
{
	struct sml_control *control = get_current_control();
	jmp_buf *prev, buf;
	int ret, need_finish = 0;
	void *dummy_frame[3];

	if (control == NULL) {
		FRAME_HEADER(&dummy_frame[1]) = 0;
		sml_control_start(&dummy_frame[1]);
		control = get_current_control();
		need_finish = 1;
	}

	prev = control->exn_jmpbuf;
	control->exn_jmpbuf = &buf;
	ret = setjmp(buf);
	if (ret == 0)
		func(data);
	control->exn_jmpbuf = prev;

	if (need_finish)
		sml_control_finish(&dummy_frame[1]);

	return ret;
}

struct enum_ptr_cls {
	void (*trace)(void **);
	enum sml_gc_mode mode;
};

static void
tmp_root_enum_ptr(void *start, void *end, void *data)
{
	const struct enum_ptr_cls *cls = data;
	void (*trace)(void **) = cls->trace;
	void **i;
	for (i = start; i < (void**)end; i++)
		trace(i);
}

void
sml_control_enum_ptr(void (*trace)(void **), enum sml_gc_mode mode)
{
	struct sml_control *control;
	struct enum_ptr_cls arg = {trace, mode};

	ASSERT(GIANT_LOCKED());

	for (control = control_blocks; control; control = control->prev) {
		stack_enum_ptr(trace, mode, control->frame_stack_top,
			       control->frame_stack_bottom);
		sml_obstack_enum_chunk(control->tmp_root,
				       tmp_root_enum_ptr, &arg);
	}
}

/* for debug */
unsigned int
sml_num_threads()
{
	struct sml_control *control;
	unsigned int count = 0;

	/* do not use GIANT_LOCK in order to prevent stop-the-world */
	GIANT_LOCK_LIGHT();
	for (control = control_blocks; control; control = control->prev)
		count++;
	GIANT_UNLOCK_LIGHT();

	return count;
}

SML_PRIMITIVE
void sml_state_suspend()
{
	int err ATTR_UNUSED;

	/* no need to check STW since this thread is to be suspended. */
	GIANT_LOCK_LIGHT();
	get_current_control()->state = SUSPENDED;
	GIANT_UNLOCK_LIGHT();
}

SML_PRIMITIVE
void sml_state_running()
{
	GIANT_LOCK(NULL);
	get_current_control()->state = RUNNING;
	GIANT_UNLOCK();
}

/* for debug */
void
sml_control_dump()
{
	struct sml_control *control;

	for (control = control_blocks; control; control = control->prev) {
		sml_notice("%p: stack=(%p, %p), heap=%p, state=%d"
#ifdef DEBUG
			   " lock_at=%s"
#endif /* DEBUG */
			   , control,
			   control->frame_stack_top,
			   control->frame_stack_bottom,
			   control->heap,
			   control->state
#ifdef DEBUG
			   , control->giant_lock_at
			   ? control->giant_lock_at : "(none)"
#endif /* DEBUG */
			   );
	}
}
