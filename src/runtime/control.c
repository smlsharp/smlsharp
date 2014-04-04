/*
 * control.c
 * @copyright (c) 2007-2014, Tohoku University.
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
#include "objspace.h"
#include "heap.h"
#include "splay.h"

#ifdef MULTITHREAD
#define MUTEX_LOCK(m) do { \
	int err ATTR_UNUSED = pthread_mutex_lock(m); \
	ASSERT(err == 0); \
} while (0)
#define MUTEX_UNLOCK(m) do { \
	int err ATTR_UNUSED = pthread_mutex_unlock(m); \
	ASSERT(err == 0); \
} while (0)
#define COND_WAIT_WHILE(exp, c, m) do {	\
	while (exp) { \
		int err ATTR_UNUSED = pthread_cond_wait(c, m);	\
		ASSERT(err == 0); \
	} \
} while (0)
#define COND_BROADCAST(c) do { \
	int err ATTR_UNUSED = pthread_cond_broadcast(c); \
	ASSERT(err == 0); \
} while (0)
#define COND_SIGNAL(c) do { \
	int err ATTR_UNUSED = pthread_cond_signal(c); \
	ASSERT(err == 0); \
} while (0)
#else
#define MUTEX_LOCK(m)   ((void)0)
#define MUTEX_UNLOCK(m) ((void)0)
#define COND_WAIT_WHILE(e,c,m)  ((void)0)
#define COND_BROADCAST(c)  ((void)0)
#define COND_SIGNAL(c)     ((void)0)
#endif /* MULTITHREAD */

static sml_obstack_t *stack_map_node_obstack = NULL;

static void *
stack_map_node_alloc(size_t size)
{
	return sml_obstack_alloc(&stack_map_node_obstack, size);
}

struct stack_map_entry {
	void *codeaddr;
	short *layout;
};

#define FRAME_BEGIN_OFFSET(layout) ((layout)[0])
#define NUM_ROOTS(layout) (((unsigned short *)(layout))[1])
#define ROOTS(layout) (&(layout)[2])
#define LAYOUT_SIZE(layout) (2 + NUM_ROOTS(layout))

static int
entry_cmp(void *x, void *y)
{
	struct stack_map_entry *e1 = x, *e2 = y;
	uintptr_t m = (uintptr_t)e1->codeaddr, n = (uintptr_t)e2->codeaddr;
	if (m < n) return -1;
	else if (m > n) return 1;
	else return 0;
}

static sml_tree_t stack_map =
	SML_TREE_INITIALIZER(entry_cmp, stack_map_node_alloc, NULL);

static short *
lookup_stack_layout(void *retaddr)
{
	struct stack_map_entry key = {retaddr, NULL};
	struct stack_map_entry *e = sml_tree_find(&stack_map, &key);
	return (e == NULL) ? NULL : e->layout;
}

void
sml_register_stackmap(void *src, void *code_begin)
{
	char *base = code_begin;
	uintptr_t points_offset;
	intptr_t *points;
	short *cur, *end;
	unsigned short num_points, i;
	struct stack_map_entry *entry;

	points_offset = (uintptr_t)((void**)src)[0];
	cur = (short*)&((void**)src)[1];
	points = (intptr_t*)((char*)src + points_offset);
	end = (short*)points;

	while (cur < end) {
		num_points = *(cur++);
		if (num_points == 0)
			continue;
		for (i = 0; i < num_points; i++) {
			entry = stack_map_node_alloc(sizeof(*entry));
			entry->codeaddr = base + *(points++);
			//sml_notice("%p\n", base + *(points++));
			entry->layout = cur;
			sml_tree_insert(&stack_map, entry);
		}
		cur += LAYOUT_SIZE(cur);
	}
}

static void
init_stack_map()
{
	extern void *_SMLstackmap;
	void **src;
	for (src = &_SMLstackmap; *src; src += 2)
		sml_register_stackmap(src[0], src[1]);
}

struct sml_control {
	void *heap;
	enum { PAUSE, RUN } state;
#ifdef MULTITHREAD
	pthread_mutex_t state_lock;
	pthread_cond_t state_cond;
#ifdef CONCURRENT
	enum sml_sync_phase phase;
#endif /* CONCURRENT */
#endif /* MULTITHREAD */
	void *tmp_root[2];         /* temporary root slot. */
	void *exn;
	void *frame_stack_top_override;
	void *frame_stack_top;
	void *frame_stack_bottom;
	struct sml_control *prev, *next;  /* for double-linked list */
};

static struct sml_control *control_blocks;
#ifdef CONCURRENT
static unsigned int num_control_blocks;
#endif /* CONCURRENT */

#ifdef MULTITHREAD
static pthread_mutex_t control_blocks_lock = PTHREAD_MUTEX_INITIALIZER;
#ifndef CONCURRENT
static volatile unsigned int stop_the_world_flag;
static pthread_mutex_t stop_the_world_flag_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t stop_the_world_flag_cond = PTHREAD_COND_INITIALIZER;
#endif /* CONCURRENT */
#endif /* MULTITHREAD */

volatile unsigned int sml_check_gc_flag;

static void
attach_control(struct sml_control *control)
{
	MUTEX_LOCK(&control_blocks_lock);

	control->prev = control_blocks;
	control->next = NULL;
	if (control->prev)
		control->prev->next = control;
	control_blocks = control;
#ifdef CONCURRENT
	num_control_blocks++;
#endif /* CONCURRENT */

	MUTEX_UNLOCK(&control_blocks_lock);
}

static void
detach_control(struct sml_control *control)
{
	MUTEX_LOCK(&control_blocks_lock);

	if (control->prev)
		control->prev->next = control->next;
	if (control->next)
		control->next->prev = control->prev;
	else
		control_blocks = control->prev;
#ifdef CONCURRENT
	num_control_blocks--;
#endif /* CONCURRENT */

	MUTEX_UNLOCK(&control_blocks_lock);
}

/* for debug */
unsigned int
sml_num_threads()
{
	struct sml_control *control;
	unsigned int n = 0;

	MUTEX_LOCK(&control_blocks_lock);
	for (control = control_blocks; control; control = control->next)
		n++;
	MUTEX_UNLOCK(&control_blocks_lock);

	return n;
}

#ifndef MULTITHREAD
static struct sml_control *global_control;
#define CONTROL() global_control
#define SET_CONTROL(c) ((void)(global_control = (c)))
#else
/* we use pthread_key not only for local storage but for thread finalization */
static pthread_key_t current_control_key;
#ifndef THREAD_LOCAL_STORAGE
#define CONTROL() \
	((struct sml_control *)pthread_getspecific(current_control_key))
#define SET_CONTROL(c) do { \
	if (pthread_setspecific(current_control_key, c) != 0) \
		sml_sysfatal("pthread_setspecific failed"); \
} while (0)
#else
static __thread struct sml_control *current_control;
#define CONTROL() current_control
#define SET_CONTROL(c) do { \
	current_control = (c); \
	if (pthread_setspecific(current_control_key, current_control) != 0) \
		sml_sysfatal("pthread_setspecific failed"); \
} while (0)
#endif /* THREAD_LOCAL_STORAGE */
#endif /* MULTITHREAD */

void sml_check_gc_internal(void);

static void
control_suspend(struct sml_control *control)
{
#ifdef CONCURRENT
	/* Before changing state to PAUSE, mutator must respond to collector's
	 * request. */
	sml_check_gc_internal();
#endif /* CONCURRENT */

	MUTEX_LOCK(&control->state_lock);
	ASSERT(control->state == RUN);
	control->state = PAUSE;
	COND_SIGNAL(&control->state_cond);
	DBG(("SUSPEND %p", control));
	MUTEX_UNLOCK(&control->state_lock);
}

static void
control_resume(struct sml_control *control)
{
#if defined MULTITHREAD && !defined CONCURRENT
	/* wait until stop-the-world phase is over */
	MUTEX_LOCK(&stop_the_world_flag_lock);
	COND_WAIT_WHILE(stop_the_world_flag,
			&stop_the_world_flag_cond,
			&stop_the_world_flag_lock);
	MUTEX_UNLOCK(&stop_the_world_flag_lock);
#endif /* MULTITHREAD && !CONCURRENT */

	MUTEX_LOCK(&control->state_lock);
	COND_WAIT_WHILE(control->state != PAUSE,
			&control->state_cond, &control->state_lock);
	control->state = RUN;
	DBG(("RESUME %p", control));
	MUTEX_UNLOCK(&control->state_lock);
}

SML_PRIMITIVE void
sml_control_suspend()
{
	struct sml_control *control = CONTROL();
	control->frame_stack_top = CALLER_FRAME_END_ADDRESS();
	control_suspend(control);
}

SML_PRIMITIVE void
sml_control_suspend_internal()
{
	control_suspend(CONTROL());
}

SML_PRIMITIVE void
sml_control_resume()
{
	control_resume(CONTROL());
}

#ifdef MULTITHREAD
void
sml_mutex_lock(pthread_mutex_t *m)
{
	struct sml_control *control = CONTROL();
	control_suspend(control);
	MUTEX_LOCK(m);
	control_resume(control);
}
#endif /* MULTITHREAD */

SML_PRIMITIVE void
sml_control_start()
{
	struct sml_control *control = CONTROL();
	void **frame_end = CALLER_FRAME_END_ADDRESS();
	short *layout;

	if (control != NULL) {
		control_resume(control);
		layout = lookup_stack_layout(FRAME_CODE_ADDRESS(frame_end));
		ASSERT(layout != NULL);
		ASSERT(NUM_ROOTS(layout) > 0);
		frame_end[ROOTS(layout)[0]] = control->frame_stack_top;
		control->frame_stack_top = frame_end;
		return;
	}

	control = xmalloc(sizeof(struct sml_control));
	control->state = RUN;
#ifdef MULTITHREAD
	if (pthread_mutex_init(&control->state_lock, NULL) != 0)
		sml_sysfatal("pthread_mutex_init failed");
	if (pthread_cond_init(&control->state_cond, NULL) != 0)
		sml_sysfatal("pthread_cond_init failed");
#ifdef CONCURRENT
	control->phase = ASYNC;
#endif /* CONCURRENT */
#endif /* MULTITHREAD */
	control->frame_stack_top_override = NULL;
	control->frame_stack_top = frame_end;
	control->frame_stack_bottom = frame_end;
	control->tmp_root[0] = NULL;
	control->tmp_root[1] = NULL;
	control->heap = sml_heap_thread_init();
	control->exn = sml_exn_init();
	SET_CONTROL(control);
	attach_control(control);

	DBG(("START THREAD %p", control));
}

static void
control_finalize(void *control_ptr)
{
	struct sml_control *control = control_ptr;

	if (control == NULL)
		return;

	detach_control(control);
#ifdef MULTITHREAD
	pthread_mutex_destroy(&control->state_lock);
	pthread_cond_destroy(&control->state_cond);
#endif /* MULTITHREAD */
	sml_heap_thread_free(control->heap);
	sml_exn_free(control->exn);
	free(control);
	SET_CONTROL(NULL);

	DBG(("FINISH THREAD %p", control));
}

SML_PRIMITIVE void
sml_control_finish()
{
	struct sml_control *control = CONTROL();
	void **frame_end = CALLER_FRAME_END_ADDRESS();
	short *layout;

	if (control->frame_stack_bottom == frame_end) {
		DBG(("CONTROL_FINISH %p", control));
		control_suspend(control);
		control_finalize(control);
	} else {
		layout = lookup_stack_layout(FRAME_CODE_ADDRESS(frame_end));
		ASSERT(layout != NULL);
		ASSERT(NUM_ROOTS(layout) > 0);
		control->frame_stack_top = frame_end[ROOTS(layout)[0]];
		control_suspend(control);
	}
}

void *
sml_current_thread_heap()
{
	return CONTROL()->heap;
}

void *
sml_current_thread_exn()
{
	return CONTROL()->exn;
}

void
sml_save_fp(void *frame_pointer)
{
	CONTROL()->frame_stack_top = frame_pointer;
}

SML_PRIMITIVE void
sml_push_fp()
{
	struct sml_control *control = CONTROL();
	if (control->frame_stack_top_override != NULL)
		FATAL((0, "sml_push_fp overfull"));
	control->frame_stack_top_override = CALLER_FRAME_END_ADDRESS();
}

SML_PRIMITIVE void
sml_pop_fp()
{
	struct sml_control *control = CONTROL();
	ASSERT(control->frame_stack_top_override != NULL);
	control->frame_stack_top_override = NULL;
	control->tmp_root[0] = NULL;
	control->tmp_root[1] = NULL;
}

/* for debug */
int
sml_alloc_available()
{
	return CONTROL()->frame_stack_top_override != NULL;
}

void **
sml_tmp_root()
{
	struct sml_control *control = CONTROL();

	if (control->tmp_root[0] == NULL)
		return &control->tmp_root[0];
	if (control->tmp_root[1] == NULL)
		return &control->tmp_root[1];

	FATAL((0, "sml_tmp_root overfull"));
}

#ifdef CONCURRENT
enum sml_sync_phase
sml_current_phase()
{
	struct sml_control *control = CONTROL();

	if (control->phase == SYNC2 || control->phase == MARK)
		if (sml_check_gc_flag != control->phase)
			control->phase = sml_check_gc_flag;
	return control->phase;
}
#endif /* CONCURRENT */

static void **
frame_enum_ptr(void **frame_end, void (*trace)(void**))
{
	void *codeaddr = FRAME_CODE_ADDRESS(frame_end);
	void **frame_begin, *header;
	short *layout = lookup_stack_layout(codeaddr);
	unsigned short num_roots, i;

	ASSERT(layout != NULL);

	frame_begin = frame_end + FRAME_BEGIN_OFFSET(layout);
	num_roots = NUM_ROOTS(layout);

	if (num_roots == 0)
		return NEXT_FRAME(frame_begin);

	header = frame_end[ROOTS(layout)[0]];

	for (i = 1; i < num_roots; i++)
		trace(frame_end + ROOTS(layout)[i]);

	return header ? header : NEXT_FRAME(frame_begin);
}

static void
stack_enum_ptr(struct sml_control *control, void (*trace)(void **))
{
	void **frame_end;

	frame_end = (control->frame_stack_top_override != NULL)
		? control->frame_stack_top_override
		: control->frame_stack_top;

	while (frame_end != control->frame_stack_bottom)
		frame_end = frame_enum_ptr(frame_end, trace);
}

static void
control_enum_ptr(struct sml_control *control, void (*trace)(void **),
		 enum sml_gc_mode mode)
{
	stack_enum_ptr(control, trace);
	sml_exn_enum_ptr(control->exn, trace);
	if (control->tmp_root[0])
		trace(&control->tmp_root[0]);
	if (control->tmp_root[1])
		trace(&control->tmp_root[1]);
}

#if !defined MULTITHREAD

/* single thread */
SML_PRIMITIVE void
sml_check_gc()
{
	/* do nothing */
}

/* single thread */
int
sml_gc_initiate(void (*trace)(void **), enum sml_gc_mode mode,
                void *data ATTR_UNUSED)
{
	control_enum_ptr(CONTROL(), trace, mode);
	sml_objspace_gc_initiate(trace, mode);
	return 1;
}

/* single thread */
void
sml_gc_done()
{
	sml_objspace_gc_done();
}

#elif defined MULTITHREAD && !defined CONCURRENT

/* stop the world */
SML_PRIMITIVE void
sml_check_gc()
{
	struct sml_control *control;

	MUTEX_LOCK(&stop_the_world_flag_lock);
	if (stop_the_world_flag) {
		MUTEX_UNLOCK(&stop_the_world_flag_lock);
		control = CONTROL();
		control->frame_stack_top = CALLER_FRAME_END_ADDRESS();
		control_suspend(control);
		control_resume(control);
	} else {
		MUTEX_UNLOCK(&stop_the_world_flag_lock);
	}
}

/* stop the world */
int
sml_gc_initiate(void (*trace)(void **), enum sml_gc_mode mode,
                void *data ATTR_UNUSED)
{
	struct sml_control *self = CONTROL();
	struct sml_control *control;

	MUTEX_LOCK(&stop_the_world_flag_lock);

	if (stop_the_world_flag) {
		/* another thread already have control to stop-the-world */
		MUTEX_UNLOCK(&stop_the_world_flag_lock);
		control_suspend(self);
		control_resume(self);
		return 0;
	}

	DBG(("STOP THE WORLD by %p", self));
	stop_the_world_flag = 1;
	sml_check_gc_flag = 1;

	COND_BROADCAST(&stop_the_world_flag_cond);
	MUTEX_UNLOCK(&stop_the_world_flag_lock);

	/* prohibit thread creation and termination during GC */
	MUTEX_LOCK(&control_blocks_lock);

	/* obtain execution lock of all mutator threads and enumerate
	 * pointers in their root sets */
	for (control = control_blocks; control; control = control->prev) {
		MUTEX_LOCK(&control->state_lock);
		if (control == self) {
			ASSERT(control->state == RUN);
		} else {
			COND_WAIT_WHILE(control->state != PAUSE,
					&control->state_cond,
					&control->state_lock);
			control->state = RUN;
		}
		MUTEX_UNLOCK(&control->state_lock);
		DBG(("CAPTURED %p", control));
		sml_heap_thread_gc_hook(control->heap);
	}

	DBG(("DO GC"));

	sml_objspace_gc_initiate(trace, mode);

	for (control = control_blocks; control; control = control->prev)
		control_enum_ptr(control, trace, mode);

	return 1;
}

/* stop the world */
void
sml_gc_done()
{
	struct sml_control *self = CONTROL();
	struct sml_control *control;

	sml_objspace_gc_done();

	DBG(("DONE GC"));

	/* release execution locks of all mutator threads */
	for (control = control_blocks; control; control = control->prev) {
		MUTEX_LOCK(&control->state_lock);
		ASSERT(control->state == RUN);
		if (control == self)
			control->state = PAUSE;
		COND_SIGNAL(&control->state_cond);
		DBG(("RELEASED %p", control));
		MUTEX_UNLOCK(&control->state_lock);
	}

	/* permit thread creation and termination */
	MUTEX_UNLOCK(&control_blocks_lock);

	/* completed. clear signal flags */
	MUTEX_LOCK(&stop_the_world_flag_lock);
	stop_the_world_flag = 0;
	sml_check_gc_flag = 0;
	COND_BROADCAST(&stop_the_world_flag_cond);
	DBG(("RUN THE WORLD by %p", self));
	MUTEX_UNLOCK(&stop_the_world_flag_lock);
}

#elif defined MULTITHREAD && defined CONCURRENT

static sml_counter_t *sync_response_counter;

static void (* volatile gc_trace_fn)(void **);

static void
do_control_enum_ptr(struct sml_control *control)
{
	sml_heap_thread_gc_hook(control->heap);
	control_enum_ptr(control, gc_trace_fn, MAJOR);
}

/* concurrent garbage collection */
static void
check_gc(struct sml_control *control)
{
	MUTEX_LOCK(&control->state_lock);
	ASSERT(control->state == RUN);

	if (control->phase == sml_check_gc_flag) {
		MUTEX_UNLOCK(&control->state_lock);
		return;
	}

	control->phase = sml_check_gc_flag;

	COND_SIGNAL(&control->state_cond);
	MUTEX_UNLOCK(&control->state_lock);

	if (control->phase == SYNC2) {
		// enumerate root set
		// take a snapshot of pointers
		do_control_enum_ptr(control);
	}

	if (control->phase == SYNC1 || control->phase == SYNC2)
		sml_counter_inc(sync_response_counter);
}

/* concurrent garbage collection */
void
sml_check_gc_internal()
{
	check_gc(CONTROL());
}

/* concurrent garbage collection */
SML_PRIMITIVE void
sml_check_gc()
{
	struct sml_control *control = CONTROL();
	control->frame_stack_top = CALLER_FRAME_END_ADDRESS();
	check_gc(CONTROL());
}

static void
handshake(enum sml_sync_phase phase)
{
	struct sml_control *control;
	sml_check_gc_flag = phase;

	for (control = control_blocks; control; control = control->prev) {
		MUTEX_LOCK(&control->state_lock);
		if (control->state == PAUSE) {
			control->state = RUN;
			MUTEX_UNLOCK(&control->state_lock);
			check_gc(control);
			MUTEX_LOCK(&control->state_lock);
			control->state = PAUSE;
			COND_SIGNAL(&control->state_cond);
			MUTEX_UNLOCK(&control->state_lock);
		} else {
			MUTEX_UNLOCK(&control->state_lock);
		}
	}

	sml_counter_wait(sync_response_counter, num_control_blocks);
}

/* concurrent garbage collection */
int
// start trace
sml_gc_initiate(void (*trace)(void **), enum sml_gc_mode mode, void *data)
{
	/* prohibit thread creation and termination during GC initiation. */
	MUTEX_LOCK(&control_blocks_lock);

	/* phase SYNC1: turn on all the write barriers */
	handshake(SYNC1);
	sml_heap_gc_hook(data);

	/* phase SYNC2: enumerate root sets */
	gc_trace_fn = trace;
	handshake(SYNC2);

	/* phase MARK */
	//handshake(MARK);
	sml_check_gc_flag = MARK;

	/* permit thread creation and termination */
	MUTEX_UNLOCK(&control_blocks_lock);

	sml_objspace_gc_initiate(trace, mode);

	return 1;
}

/* concurrent garbage collection */
void
// trace end
sml_gc_done()
{
	sml_objspace_gc_done();

	/* go back to phase ASYNC */
	//MUTEX_LOCK(&control_blocks_lock);
	//handshake(ASYNC);
	//MUTEX_UNLOCK(&control_blocks_lock);
	sml_check_gc_flag = ASYNC;
}

#endif /* MULTITHREAD */

void
sml_control_init()
{
#ifdef MULTITHREAD
	int ret ATTR_UNUSED;

	ret = pthread_key_create(&current_control_key, control_finalize);
	if (ret != 0)
		sml_sysfatal("pthread_key_create failed");
#ifdef CONCURRENT
	sync_response_counter = sml_counter_new();
#endif /* CONCURRENT */
#endif /* MULTITHREAD */

	init_stack_map();
}

void
sml_control_free()
{
#ifdef MULTITHREAD
	/* TODO: wait all SML threads are terminated here? */
	pthread_key_delete(current_control_key);
#ifdef CONCURRENT
	/* TODO: free sync_response_counter */
#endif /* CONCURRENT */
#endif /* MULTITHREAD */
}
