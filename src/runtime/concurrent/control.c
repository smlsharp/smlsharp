/*
 * frame.c
 * @copyright (c) 2007-2011, Tohoku University.
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
#include "spinlock.h"
#include "control.h"

/* #include "sys/time.h" */
/* #include "time.h" */
/* struct timespec tc = {0, 2000000}; */

#ifdef GCTIME
#include "timer.h"
static struct {
	sml_time_t total_collector_exec;
	sml_time_t total_mutators_exec;
	sml_time_t total_mutators_enum;
	sml_time_t total_mutators_suspend;
	sml_timer_t control_init_at;
	sml_timer_t total_mutators_suspend_tmp;
	double max_mutators_enum;
	unsigned int mutators_enum_count;
	unsigned int mutators_suspend_count;
} gcstat = {TIMEINIT, TIMEINIT, TIMEINIT, TIMEINIT, TIMEINIT, TIMEINIT};
sml_time_t gcstat_total_collector_sync1;
sml_time_t gcstat_total_collector_sync2;
double gcstat_max_mutators_pause;
#define stat_notice sml_notice
#endif /* GCTIME */

struct sml_control {
	void *frame_stack_top;
	void *frame_stack_bottom;
	void *current_handler;
	void *heap;
	jmp_buf *exn_jmpbuf;          /* longjmp if uncaught exception error */
	sml_obstack_t *tmp_root;      /* temporary root slots of GC. */
#ifdef MULTITHREAD
	enum sml_gc_phase { ASYNC, SYNC1, SYNC2 } phase;
	unsigned int write_barrier;
	enum { RUN, PAUSE } state;
	spinlock_t state_lock;
	sml_event_t *state_unlock_event;
#endif /* MULTITHREAD */
#ifdef GCTIME
	sml_timer_t start_at;
#endif /* GCTIME */
	struct sml_control *prev, *next;
};

static struct sml_control *control_blocks;
static unsigned int num_control_blocks;
#ifdef MULTITHREAD
static pthread_mutex_t control_blocks_lock;
#endif /* MULTITHREAD */

#ifdef MULTITHREAD
#ifdef THREAD_LOCAL_STORAGE
static __thread struct sml_control *current_control;
#else
static pthread_key_t control_key;
#endif /* THREAD_LOCAL_STORAGE */
#else
static struct sml_control *global_control;
#endif /* MULTITHREAD */

#ifdef MULTITHREAD
volatile unsigned int sml_check_gc_flag;
volatile int sml_write_barrier_flag;
static sml_counter_t *sync_response_counter;
static void (*gc_trace_fn)(void **);
#endif /* MULTITHREAD */

static struct sml_control *
get_current_control()
{
#ifdef MULTITHREAD
#ifdef THREAD_LOCAL_STORAGE
	return current_control;
#else
	return pthread_getspecific(control_key);
#endif /* THREAD_LOCAL_STORAGE */
#else
	return global_control;
#endif /* MULTITHREAD */
}

static void
set_current_control(struct sml_control *control)
{
#ifdef MULTITHREAD
#ifdef THREAD_LOCAL_STORAGE
	current_control = control;
#else
	pthread_setspecific(control_key, control);
#endif /* THREAD_LOCAL_STORAGE */
#else
	global_control = control;
#endif /* MULTITHREAD */
}

static void
control_enum_ptr(struct sml_control *control, void (*trace)(void **),
		 enum sml_gc_mode mode);

static void
do_control_enum_ptr(struct sml_control *control)
{
#ifdef GCTIME
	sml_timer_t t1, t2;
	sml_time_t t;
	double dt;
#endif /* GCTIME */

#ifdef GCTIME
	sml_timer_now(t1);
#endif /* GCTIME */
	sml_heap_thread_rootset_hook(control->heap);
	control_enum_ptr(control, gc_trace_fn, MAJOR);
#ifdef GCTIME
	sml_timer_now(t2);

	sml_timer_dif(t1, t2, t);
	sml_time_accum(t, gcstat.total_mutators_enum);
	gcstat.mutators_enum_count++;
	dt = TIMEFLOAT(t);
	if (dt > gcstat.max_mutators_enum)
		gcstat.max_mutators_enum = dt;
	if (dt > gcstat_max_mutators_pause)
		gcstat_max_mutators_pause = dt;
#endif /* GCTIME */
}



#if defined MULTITHREAD && defined DEBUG
#define GC_FLAG_STW  (0x1000U)
sml_counter_t *stw_count = NULL;
pthread_mutex_t stw_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t stw_cond = PTHREAD_COND_INITIALIZER;

void
sml_stw_begin()
{
	struct sml_control *control;
	pthread_mutex_lock(&control_blocks_lock);
	pthread_mutex_lock(&stw_mutex);
	ASSERT(stw_count == NULL);
	stw_count = sml_counter_new();
	pthread_mutex_unlock(&stw_mutex);
	ASSERT(sml_check_gc_flag == ASYNC);
	sml_check_gc_flag = GC_FLAG_STW;
	for (control = control_blocks; control; control = control->prev) {
		SPIN_LOCK(&control->state_lock);
		if (control->state == PAUSE)
			control->state = RUN, control->phase |= GC_FLAG_STW;
		SPIN_UNLOCK(&control->state_lock);
		sml_counter_inc(stw_count);
	}
	sml_counter_wait(stw_count, num_control_blocks);
}

void
sml_stw_end()
{
	struct sml_control *control;
	for (control = control_blocks; control; control = control->prev) {
		SPIN_LOCK(&control->state_lock);
		if (control->state == RUN && control->phase & GC_FLAG_STW) {
			control->state = PAUSE, control->phase &= ~GC_FLAG_STW;
			sml_event_signal(control->state_unlock_event);
		}
		SPIN_UNLOCK(&control->state_lock);
	}
	ASSERT(sml_check_gc_flag == GC_FLAG_STW);
	sml_check_gc_flag = ASYNC;
	pthread_mutex_lock(&stw_mutex);
	sml_counter_free(stw_count);
	stw_count = NULL;
	pthread_cond_broadcast(&stw_cond);
	pthread_mutex_unlock(&stw_mutex);
	pthread_mutex_unlock(&control_blocks_lock);
}

void
sml_stw_enum_ptr(void (*trace)(void**))
{
	struct sml_control *control;
	sml_objspace_enum_ptr(trace, MAJOR);
	for (control = control_blocks; control; control = control->prev)
		control_enum_ptr(control, trace, MAJOR);
}
#endif /* MULTITHREAD && DEBUG */

static void
check_gc(struct sml_control *control, unsigned int check_gc_flag)
{
	if (control->phase == ASYNC && check_gc_flag == SYNC1) {
		control->phase = SYNC1;
		control->write_barrier = 1;
		sml_counter_inc(sync_response_counter);
	}
	else if (control->phase == SYNC1 && check_gc_flag == SYNC2) {
		control->phase = ASYNC;
		do_control_enum_ptr(control);
		sml_counter_inc(sync_response_counter);
	}
#ifdef DEBUG
	if (check_gc_flag == GC_FLAG_STW) {
		pthread_mutex_lock(&stw_mutex);
		sml_counter_inc(stw_count);
		while (stw_count)
			pthread_cond_wait(&stw_cond, &stw_mutex);
		pthread_mutex_unlock(&stw_mutex);
	}
#endif /* DEBUG */
}

SML_PRIMITIVE void
sml_check_gc(void *frame_pointer)
{
	struct sml_control *control = get_current_control();
	control->frame_stack_top = frame_pointer;
	check_gc(control, sml_check_gc_flag);
}

static void
control_suspend(struct sml_control *control)
{
	unsigned int check_gc_flag;

	SPIN_LOCK(&control->state_lock);
	ASSERT(control->state == RUN);
	control->state = PAUSE;

	/* Before suspend, mutator must respond to collector's request.
	 * To avoid contention with the collector which is running on
	 * sml_gc_initiate, not only changing control->state but changing
	 * control->phase is also performed within SPIN_LOCK. */
	check_gc_flag = ACQUIRE_AND_LOAD_INT(&sml_check_gc_flag);

	if (control->phase == ASYNC && check_gc_flag == SYNC1) {
		control->phase = SYNC1;
		SPIN_UNLOCK(&control->state_lock);
		control->write_barrier = 1;
		sml_counter_inc(sync_response_counter);
	}
	else if (control->phase == SYNC1 && check_gc_flag == SYNC2) {
		control->phase = ASYNC;
		SPIN_UNLOCK(&control->state_lock);
		do_control_enum_ptr(control);
		sml_counter_inc(sync_response_counter);
	}
	else {
		SPIN_UNLOCK(&control->state_lock);
#ifdef DEBUG
		if (check_gc_flag == GC_FLAG_STW) {
			pthread_mutex_lock(&stw_mutex);
			sml_counter_inc(stw_count);
			while (stw_count)
				pthread_cond_wait(&stw_cond, &stw_mutex);
			pthread_mutex_unlock(&stw_mutex);
		}
#endif /* DEBUG */
	}

#ifdef GCTIME
	sml_timer_now(gcstat.total_mutators_suspend_tmp);
#endif /* GCTIME */
}

SML_PRIMITIVE void
sml_control_suspend()
{
	control_suspend(get_current_control());
}

static void
control_resume(struct sml_control *control)
{
#ifdef GCTIME
	sml_timer_t t1;
	sml_time_t t;
#endif /* GCTIME */

	SPIN_LOCK(&control->state_lock);
	while (control->state != PAUSE) {
		SPIN_UNLOCK(&control->state_lock);
		sml_event_wait(control->state_unlock_event);
		SPIN_LOCK(&control->state_lock);
	}

#ifdef GCTIME
	sml_timer_now(t1);
	sml_timer_dif(gcstat.total_mutators_suspend_tmp, t1, t);
	sml_time_accum(t, gcstat.total_mutators_suspend);
	gcstat.mutators_suspend_count++;
#endif /* GCTIME */

	control->state = RUN;
	SPIN_UNLOCK(&control->state_lock);
	
	check_gc(control, ACQUIRE_AND_LOAD_INT(&sml_check_gc_flag));
}

SML_PRIMITIVE void
sml_control_resume()
{
	control_resume(get_current_control());
}

int
sml_check_write_barrier()
{
	struct sml_control *control = get_current_control();

	if (control->write_barrier)
		control->write_barrier = sml_write_barrier_flag;
	return control->write_barrier;
}

void *
sml_gc_initiate(void (*trace)(void **), void *(*fix_collect_set)(void))
{
	struct sml_control *control;
	void *ret;
#ifdef GCTIME
	sml_timer_t t1, t2, t3;
	sml_time_t t;
#endif /* GCTIME */
	
	/* thread creation and termination are prohibited during
	 * collection initiation. */
	pthread_mutex_lock(&control_blocks_lock);

#ifdef GCTIME
	sml_timer_now(t1);
#endif /* GCTIME */

	ASSERT(sml_check_gc_flag == ASYNC);
	STORE_AND_RELEASE_INT(&sml_check_gc_flag, SYNC1);
	STORE_AND_RELEASE_INT(&sml_write_barrier_flag, 1);

	for (control = control_blocks; control; control = control->prev) {
		SPIN_LOCK(&control->state_lock);
		if (control->state == PAUSE && control->phase == ASYNC) {
			control->phase = SYNC1;
			control->write_barrier = 1;
			SPIN_UNLOCK(&control->state_lock);
			sml_counter_inc(sync_response_counter);
		} else {
			SPIN_UNLOCK(&control->state_lock);
		}
	}
	sml_counter_wait(sync_response_counter, num_control_blocks);

#ifdef GCTIME
	sml_timer_now(t2);
#endif /* GCTIME */

	ret = fix_collect_set();

	STORE_AND_RELEASE_INT(&sml_check_gc_flag, SYNC2);
	gc_trace_fn = trace;

	sml_objspace_enum_ptr(trace, MAJOR);

	for (control = control_blocks; control; control = control->prev) {
		SPIN_LOCK(&control->state_lock);
		if (control->state == PAUSE && control->phase == SYNC1) {
			control->state = RUN;
			SPIN_UNLOCK(&control->state_lock);

			control->phase = ASYNC;
			sml_heap_thread_rootset_hook(control->heap);
			control_enum_ptr(control, trace, MAJOR);
			sml_counter_inc(sync_response_counter);

			SPIN_LOCK(&control->state_lock);
			control->state = PAUSE;
			SPIN_UNLOCK(&control->state_lock);
			sml_event_signal(control->state_unlock_event);
		} else {
			ASSERT(control->state == RUN
			       || control->phase == ASYNC);
			SPIN_UNLOCK(&control->state_lock);
		}
	}
	sml_counter_wait(sync_response_counter, num_control_blocks);

	STORE_AND_RELEASE_INT(&sml_check_gc_flag, ASYNC);

#ifdef GCTIME
	sml_timer_now(t3);
#endif /* GCTIME */

	pthread_mutex_unlock(&control_blocks_lock);

#ifdef GCTIME
	sml_timer_dif(t1, t2, t);
	sml_time_accum(t, gcstat_total_collector_sync1);
	sml_timer_dif(t2, t3, t);
	sml_time_accum(t, gcstat_total_collector_sync2);
#endif /* GCTIME */

	return ret;
}

/* giant lock */
#ifdef MULTITHREAD
static pthread_mutex_t giant_lock;

void
sml_giant_lock()
{
	struct sml_control *control = get_current_control();
	int orig_state = control->state;
	int err ATTR_UNUSED;

	if (orig_state != PAUSE)
		control_suspend(control);

	err = pthread_mutex_lock(&giant_lock);
	ASSERT(err == 0);

	if (orig_state != PAUSE)
		control_resume(control);
}

void
sml_giant_unlock()
{
	int err__ ATTR_UNUSED;
	err__ = pthread_mutex_unlock(&giant_lock);
	ASSERT(err__ == 0);
}

#endif /* MULTITHREAD */

static void
attach_control(struct sml_control *new_control)
{
	/* thread creation are avoided during root set enumeration. */
	pthread_mutex_lock(&control_blocks_lock);

	new_control->next = NULL;
	new_control->prev = control_blocks;
	if (new_control->prev)
		new_control->prev->next = new_control;
	control_blocks = new_control;
	num_control_blocks++;

	pthread_mutex_unlock(&control_blocks_lock);
}

static void
detach_control(struct sml_control *control)
{
	/* thread termination are avoided during root set enumeration. */
	control_suspend(control);
	pthread_mutex_lock(&control_blocks_lock);
	ASSERT(control->state == PAUSE);

	if (control->prev)
		control->prev->next = control->next;
	if (control->next)
		control->next->prev = control->prev;
	else
		control_blocks = control->prev;
	num_control_blocks--;

	pthread_mutex_unlock(&control_blocks_lock);
}

static void control_finalize(void *control_ptr);

void
sml_control_init()
{
#ifdef MULTITHREAD
	int ret;
#ifndef THREAD_LOCAL_STORAGE
	ret = pthread_key_create(&control_key, control_finalize);
	if (ret != 0)
		sml_sysfatal("pthread_key_create failed");
#endif /* THREAD_LOCAL_STORAGE */

	pthread_mutex_init(&giant_lock, NULL);
	pthread_mutex_init(&control_blocks_lock, NULL);
	sync_response_counter = sml_counter_new();
#endif /* MULTITHREAD */

#ifdef GCTIME
	sml_timer_now(gcstat.control_init_at);
#endif /* GCTIME */
}

void
sml_control_free()
{
#ifdef GCTIME
	sml_timer_t now;
	sml_time_t t;
#endif /* GCTIME */

#ifdef MULTITHREAD
	/* FIXME: wait until all SML threads are finished. */
	pthread_mutex_destroy(&giant_lock);
	pthread_mutex_destroy(&control_blocks_lock);
	sml_counter_free(sync_response_counter);
#ifndef THREAD_LOCAL_STORAGE
	pthread_key_delete(control_key);
#endif /* THREAD_LOCAL_STORAGE */
#endif /* MULTITHREAD */

#ifdef GCTIME
	sml_timer_now(now);
	sml_timer_dif(gcstat.control_init_at, now, t);
	stat_notice("---");
	stat_notice("# reported by control.c");
	stat_notice("real exec time : "TIMEFMT" #sec, cpu %.3f %%",
		    TIMEARG(t),
		    (TIMEFLOAT(gcstat.total_mutators_exec)
		     + TIMEFLOAT(gcstat.total_collector_exec))
		    / TIMEFLOAT(t) * 100.0);
	stat_notice("collector:");
	stat_notice("  total exec time : "TIMEFMT" #sec",
		    TIMEARG(gcstat.total_collector_exec));
	stat_notice("mutators:");
	stat_notice("  total exec time : "TIMEFMT" #sec",
		    TIMEARG(gcstat.total_mutators_exec));
	stat_notice("  total enum      : "TIMEFMT" #sec, %u times, "
		    "avg %.6f sec",
		    TIMEARG(gcstat.total_mutators_enum),
		    gcstat.mutators_enum_count,
		    TIMEFLOAT(gcstat.total_mutators_enum)
		    / gcstat.mutators_enum_count);
	stat_notice("  max enum        : %.6f #sec", gcstat.max_mutators_enum);
	stat_notice("  max pause       : %.6f #sec", gcstat_max_mutators_pause);
	stat_notice("  total suspend   : "TIMEFMT" #sec, %u times, "
		    "avg %.6f sec",
		    TIMEARG(gcstat.total_mutators_suspend),
		    gcstat.mutators_suspend_count,
		    TIMEFLOAT(gcstat.total_mutators_suspend)
		    / gcstat.mutators_suspend_count);
#endif /* GCTIME */
}

SML_PRIMITIVE void
sml_control_start(void *frame_pointer)
{
	struct sml_control *control = get_current_control();
#ifdef MULTITHREAD
	int err ATTR_UNUSED;
#endif /* MULTITHREAD */

	if (control == NULL) {
		control = xmalloc(sizeof(struct sml_control));
		control->frame_stack_top = frame_pointer;
		control->frame_stack_bottom = frame_pointer;
		control->current_handler = NULL;
		control->heap = NULL;
		control->exn_jmpbuf = NULL;
		control->tmp_root = NULL;
#ifdef MULTITHREAD
		control->state = RUN;
		control->phase = ASYNC;
		SPIN_INIT(&control->state_lock);
		control->state_unlock_event = sml_event_new(0, 0);
#endif /* MULTITHREAD */
#ifdef GCTIME
		sml_timer_now(control->start_at);
#endif /* GCTIME */
		set_current_control(control);
		attach_control(control);

		/* allocation pointer must initialize AFTER attach_control()
		 * because sml_gc_initiate must send GC request to all
		 * threads that has an allocation pointer.
		 * If sml_heap_thread_init() is called BEFORE attach_control(),
		 * this control has an allocation pointer but is not in
		 * control_blocks due to mutex lock by control_blocks_lock.
		 *
		 * Since the initial state is RUN and the initial phase is
		 * ASYNC, sml_gc_initiate does not access to this control->heap
		 * before executing the following initialization by this
		 * thread, so sml_heap_thread_init() after attach_control() is
		 * correct. */
		control->heap = sml_heap_thread_init();

		//DBG(("START NEW THREAD : %p %u", pthread_self(),
		//sml_num_threads()));
	} else {
		control_resume(control);
		FRAME_HEADER(frame_pointer) |= FRAME_FLAG_SKIP;
		FRAME_EXTRA(frame_pointer) =
			(uintptr_t)control->frame_stack_top;
		control->frame_stack_top = frame_pointer;
	}
}

static void
control_finalize(void *control_ptr)
{
	struct sml_control *control = control_ptr;
#ifdef GCTIME
	sml_timer_t t1;
	sml_time_t t;
#endif /* GCTIME */

	if (control == NULL)
		return;

	/* NOTE: control_finalize may be called due to asynchronous
	 * termination, such as pthread_kill. Anyway, Since the thread
	 * is intended to be terminated, ML frame stack should be empty
	 * at this time. */
	control->frame_stack_top = control->frame_stack_bottom;

	detach_control(control);

	sml_event_free(control->state_unlock_event);
	sml_heap_thread_free(control->heap);
	sml_obstack_free(&control->tmp_root, NULL);
	free(control);
	set_current_control(NULL);

#ifdef GCTIME
	sml_timer_now(t1);
	sml_timer_dif(control->start_at, t1, t);
	sml_time_accum(t, gcstat.total_mutators_exec);
#endif /* GCTIME */
}

SML_PRIMITIVE void
sml_control_finish(void *frame_pointer)
{
	struct sml_control *control = get_current_control();

	control->frame_stack_top = frame_pointer;

	if (control->frame_stack_bottom == frame_pointer) {
		control_finalize(control);
	} else {
		ASSERT(FRAME_HEADER(frame_pointer) & FRAME_FLAG_SKIP);
		control->frame_stack_top = (void*)FRAME_EXTRA(frame_pointer);
		/* FIXME: callback function always suspends the thread. */
		control_suspend(control);
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

	/* ToDo: resume, suspend */

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

	/* ToDo: resume, suspend */
	sml_obstack_free(&control->tmp_root, slots);
}

SML_PRIMITIVE void
sml_save_frame_pointer(void *frame_pointer)
{
	get_current_control()->frame_stack_top = frame_pointer;
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

int
sml_is_in_sync1()
{
	return get_current_control()->phase == SYNC1;
}

SML_PRIMITIVE void
sml_push_handler(void *handler)
{
	/* The detail of handler structure is platform-dependent except
	 * that runtime may use *(void**)handler for handler chain. */
	struct sml_control *control = get_current_control();

	*((void**)handler) = control->current_handler;

	/* assume that this assignment is atomic so that asynchronous signal
	 * may raise an exception. */
	control->current_handler = handler;
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

static void
control_enum_ptr(struct sml_control *control, void (*trace)(void **),
		 enum sml_gc_mode mode)
{
	struct enum_ptr_cls arg = {trace, mode};

	stack_enum_ptr(trace, mode, control->frame_stack_top,
		       control->frame_stack_bottom);
	sml_obstack_enum_chunk(control->tmp_root,
			       tmp_root_enum_ptr, &arg);
}

unsigned int
sml_num_threads()
{
	unsigned int num_threads;
	pthread_mutex_lock(&control_blocks_lock);
	num_threads = num_control_blocks;
	pthread_mutex_unlock(&control_blocks_lock);
	return num_control_blocks;
}

#if 0

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

#endif



static struct {
	pthread_t thread;
	sml_event_t *event;
	int stop;
} collector;

static void *
collector_main(void *data ATTR_UNUSED)
{
#ifdef GCTIME
	sml_timer_t t1, t2;
	sml_time_t t;
#endif /* GCTIME */

	for (;;) {
		sml_event_wait(collector.event);
#ifdef GCTIME
		sml_timer_now(t1);
#endif /* GCTIME */
		if (collector.stop)
			return NULL;
		sml_heap_gc();
#ifdef GCTIME
		sml_timer_now(t2);
		sml_timer_dif(t1, t2, t);
		sml_time_accum(t, gcstat.total_collector_exec);
#endif /* GCTIME */
	}
}

void
sml_start_collector()
{
	int ret;

	collector.event = sml_event_new(0, 0);
	collector.stop = 0;

	ret = pthread_create(&collector.thread, NULL, collector_main, NULL);
	if (ret != 0)
		sml_sysfatal("sml_start_collector");
}

void
sml_stop_collector()
{
	collector.stop = 1;
	/* nanosleep(&tc, NULL); */
	sml_event_signal(collector.event);
	pthread_join(collector.thread, NULL);
	sml_event_free(collector.event);
}

void
sml_signal_collector()
{
	/* nanosleep(&tc, NULL); */
	sml_event_signal(collector.event);
}
