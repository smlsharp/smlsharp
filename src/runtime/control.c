/*
 * control.c
 * @copyright (c) 2007-2014, Tohoku University.
 * @author UENO Katsuhiro
 */

#include "smlsharp.h"
#include <stdlib.h>
#include "heap.h"

struct sml_control {
#ifndef WITHOUT_MULTITHREAD
	_Atomic(unsigned int) state;
	pthread_mutex_t inactive_wait_lock;
	pthread_cond_t inactive_wait_cond;
#endif /* !WITHOUT_MULTITHREAD */
	struct frame_stack_range {
		/* If bottom is empty, this is a dummy range; this must be
		 * skipped during stack frame scan.  A dummy range is used
		 * to run a sequence of top-level code fragments efficiently.
		 * See sml_run_toplevels. */
		void *bottom, *top;
		struct frame_stack_range *next;
	} *frame_stack;
	void *thread_local_heap;
	void *exn_object;
	struct sml_control *prev, *next;  /* double-linked list */
};
#define PHASE_MASK       0x0fU
#define INACTIVE_FLAG    0x10U
#define PHASE(state)     ((state) & PHASE_MASK)
#define ACTIVE(phase)    (phase)
#define INACTIVE(phase)  ((phase) | INACTIVE_FLAG)
#define IS_ACTIVE(state) (!((state) & INACTIVE_FLAG))

#ifndef WITHOUT_MULTITHREAD
static struct sml_control *control_blocks;
static enum sml_sync_phase new_thread_phase = ASYNC;
static pthread_mutex_t control_blocks_lock = PTHREAD_MUTEX_INITIALIZER;
#endif /* !WITHOUT_MULTITHREAD */

_Atomic(unsigned int) sml_check_flag;

#if !defined WITHOUT_MULTITHREAD && !defined WITHOUT_CONCURRENCY
static pthread_mutex_t sync_wait_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t sync_wait_cond = PTHREAD_COND_INITIALIZER;
static _Atomic(unsigned int) sync_counter;
#endif /* !WITHOUT_MULTITHREAD && !WITHOUT_CONCURRENCY */

#ifndef WITHOUT_MULTITHREAD
static void thread_cancelled(struct sml_control *control);
#endif /* !WITHOUT_MULTITHREAD */
tlv_alloc(struct sml_control *, current_control, thread_cancelled);

#if !defined WITHOUT_MULTITHREAD && defined WITHOUT_CONCURRENCY
static pthread_mutex_t stop_the_world_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t stop_the_world_cond = PTHREAD_COND_INITIALIZER;
static _Atomic(unsigned int) stop_the_world_flag;
int
sml_stop_the_world()
{
	mutex_lock(&stop_the_world_lock);
	if (load_relaxed(&stop_the_world_flag)) {
		/* do nothing if another thread stops the world */
		while (load_relaxed(&stop_the_world_flag))
			cond_wait(&stop_the_world_cond, &stop_the_world_lock);
		mutex_unlock(&stop_the_world_lock);
		return 0;
	}
	store_relaxed(&stop_the_world_flag, 1);
	mutex_unlock(&stop_the_world_lock);
	return 1;
}
void
sml_run_the_world()
{
	mutex_lock(&stop_the_world_lock);
	store_relaxed(&stop_the_world_flag, 0);
	cond_broadcast(&stop_the_world_cond);
	mutex_unlock(&stop_the_world_lock);
}
#endif /* !defined WITHOUT_MULTITHREAD && defined WITHOUT_CONCURRENCY */

#if defined WITHOUT_MULTITHREAD
static void
control_register(struct sml_control *control ATTR_UNUSED)
{
}

#else /* !WITHOUT_MULTITHREAD */
static void
control_register(struct sml_control *control)
{
	mutex_lock(&control_blocks_lock);

	atomic_init(&control->state, ACTIVE(new_thread_phase));

	control->prev = control_blocks;
	control->next = NULL;
	if (control->prev)
		control->prev->next = control;
	control_blocks = control;

	mutex_unlock(&control_blocks_lock);
}

#endif /* !WITHOUT_MULTITHREAD */

#if defined WITHOUT_MULTITHREAD
static void
control_unregister(struct sml_control *control ATTR_UNUSED)
{
}

#else /* !WITHOUT_MULTITHREAD */
static void
control_unregister(struct sml_control *control)
{
	mutex_lock(&control_blocks_lock);

	if (control->prev)
		control->prev->next = control->next;
	if (control->next)
		control->next->prev = control->prev;
	else
		control_blocks = control->prev;

	mutex_unlock(&control_blocks_lock);
}

#endif /* !WITHOUT_MULTITHREAD */

#if !defined WITHOUT_MULTITHREAD && !defined WITHOUT_CONCURRENCY
static void
sync1_action()
{
	if (fetch_sub(relaxed, &sync_counter, 1) - 1 == 0) {
		mutex_lock(&sync_wait_lock);
		cond_signal(&sync_wait_cond);
		mutex_unlock(&sync_wait_lock);
	}
}

#endif /* !WITHOUT_MULTITHREAD && !WITHOUT_CONCURRENCY */

#if !defined WITHOUT_MULTITHREAD && !defined WITHOUT_CONCURRENCY
static void
sync2_action(struct sml_control *control)
{
	if (control->thread_local_heap)
		sml_heap_mutator_sync2(control, control->thread_local_heap);

	/* all updates performed by this mutator happen before time that
	 * collector checks sync_counter. */
	if (fetch_sub(release, &sync_counter, 1) - 1 == 0) {
		mutex_lock(&sync_wait_lock);
		cond_signal(&sync_wait_cond);
		mutex_unlock(&sync_wait_lock);
	}
}

#endif /* !WITHOUT_MULTITHREAD && !WITHOUT_CONCURRENCY */

#if defined WITHOUT_MULTITHREAD
static void
control_leave(struct sml_control *control ATTR_UNUSED)
{
}

#elif defined WITHOUT_CONCURRENCY
static void
control_leave(struct sml_control *control)
{
	assert(load_relaxed(&control->state) == ACTIVE(ASYNC));
	/* unlock; all updates so far must be released */
	store_release(&control->state, INACTIVE(ASYNC));
	if (load_relaxed(&stop_the_world_flag)) {
		mutex_lock(&control->inactive_wait_lock);
		cond_signal(&control->inactive_wait_cond);
		mutex_unlock(&control->inactive_wait_lock);
	}
}

#else /* !WITHOUT_MULTITHREAD && !WITHOUT_CONCURRENCY */
static void
control_leave(struct sml_control *control)
{
	unsigned int old;

	assert(IS_ACTIVE(load_relaxed(&control->state)));
	/* progress even phase to odd phase */
	/* unlock; all updates so far must be released */
	old = fetch_or(release, &control->state, INACTIVE_FLAG | 1);

	if (old == ACTIVE(PRESYNC1))
		sync1_action();
	else if (old == ACTIVE(PRESYNC2))
		sync2_action(control);
}

#endif /* !WITHOUT_MULTITHREAD && !WITHOUT_CONCURRENCY */

#ifndef WITHOUT_MULTITHREAD
static void
cleanup_mutex_unlock(void *m)
{
	mutex_unlock(m);
}

#endif /* !WITHOUT_MULTITHREAD */

#ifndef WITHOUT_MULTITHREAD
static void
activate(struct sml_control *control)
{
	unsigned int old;

	/* lock; all updates so far must be acquired */
	old = fetch_and(acquire, &control->state, ~INACTIVE_FLAG);
	if (IS_ACTIVE(old)) {
		mutex_lock(&control->inactive_wait_lock);
		pthread_cleanup_push(cleanup_mutex_unlock,
				     &control->inactive_wait_lock);
		while ((old = fetch_and(acquire, &control->state,
					~INACTIVE_FLAG),
			IS_ACTIVE(old)))
			cond_wait(&control->inactive_wait_cond,
				  &control->inactive_wait_lock);
		pthread_cleanup_pop(1);
	}

	assert(IS_ACTIVE(load_relaxed(&control->state)));
}

#endif /* !WITHOUT_MULTITHREAD */

#if defined WITHOUT_MULTITHREAD
static void
control_enter(struct sml_control *control ATTR_UNUSED)
{
}

#elif defined WITHOUT_CONCURRENCY
static void
control_enter(struct sml_control *control)
{
	unsigned int old;

	/* lock; all updates so far must be acquired */
	old = INACTIVE(ASYNC);
	if (cmpswap_weak_acquire(&control->state, &old, ACTIVE(ASYNC)))
		return;

	mutex_lock(&control->inactive_wait_lock);
	pthread_cleanup_push(cleanup_mutex_unlock,
			     &control->inactive_wait_lock);
	old = INACTIVE(ASYNC);
	while (!cmpswap_weak_acquire(&control->state, &old, ACTIVE(ASYNC))) {
		cond_wait(&control->inactive_wait_cond,
			  &control->inactive_wait_lock);
		old = INACTIVE(ASYNC);
	}
	pthread_cleanup_pop(1);
}

#else /* !WITHOUT_MULTITHREAD && !WITHOUT_CONCURRENCY */
static void
control_enter(struct sml_control *control)
{
	activate(control);
}

#endif /* !WITHOUT_MULTITHREAD && !WITHOUT_CONCURRENCY */

SML_PRIMITIVE void
sml_leave()
{
	struct sml_control *control = tlv_get(current_control);
	assert(control->frame_stack->top == NULL);
	control->frame_stack->top = CALLER_FRAME_END_ADDRESS();
	control_leave(control);
}

SML_PRIMITIVE void
sml_enter()
{
	struct sml_control *control = tlv_get(current_control);
	control_enter(control);
	assert(control->frame_stack->top == CALLER_FRAME_END_ADDRESS());
	control->frame_stack->top = NULL;
}

void *
sml_leave_internal(void *frame_pointer)
{
	struct sml_control *control = tlv_get(current_control);
	void *old_frame_top;

	old_frame_top = control->frame_stack->top;
	if (!old_frame_top)
		control->frame_stack->top = frame_pointer;
	control_leave(control);
	return old_frame_top;
}

void
sml_enter_internal(void *old_frame_top)
{
	struct sml_control *control = tlv_get(current_control);
	control_enter(control);
	control->frame_stack->top = old_frame_top;
}

#if defined WITHOUT_MULTITHREAD
void
sml_check_internal(void *frame_pointer ATTR_UNUSED)
{
}

#elif defined WITHOUT_CONCURRENCY
void
sml_check_internal(void *frame_pointer)
{
	struct sml_control *control = tlv_get(current_control);
	void *old_frame_top;

	assert(load_relaxed(&control->state) == ACTIVE(ASYNC));
	if (load_relaxed(&stop_the_world_flag)) {
		old_frame_top = control->frame_stack->top;
		if (!old_frame_top)
			control->frame_stack->top = frame_pointer;
		store_release(&control->state, INACTIVE(SYNC1));
		mutex_lock(&control->inactive_wait_lock);
		cond_signal(&control->inactive_wait_cond);
		mutex_unlock(&control->inactive_wait_lock);
		control_enter(control);
		control->frame_stack->top = old_frame_top;
	}
}

#else /* !WITHOUT_MULTITHREAD && !WITHOUT_CONCURRENCY */
void
sml_check_internal(void *frame_pointer)
{
	struct sml_control *control = tlv_get(current_control);
	unsigned int state = load_relaxed(&control->state);
	void *old_frame_top;

	assert(IS_ACTIVE(state));

	if (state == ACTIVE(PRESYNC1)) {
		store_relaxed(&control->state, ACTIVE(SYNC1));
		sync1_action();
	} else if (state == ACTIVE(PRESYNC2)) {
		store_relaxed(&control->state, ACTIVE(SYNC2));
		old_frame_top = control->frame_stack->top;
		if (!old_frame_top)
			control->frame_stack->top = frame_pointer;
		sync2_action(control);
		control->frame_stack->top = old_frame_top;
	}
}

#endif /* !WITHOUT_MULTITHREAD && !WITHOUT_CONCURRENCY */

SML_PRIMITIVE void
sml_check()
{
	assert(tlv_get(current_control)->frame_stack->top == NULL);
	sml_check_internal(CALLER_FRAME_END_ADDRESS());
}

#ifndef WITHOUT_MULTITHREAD
enum sml_sync_phase
sml_current_phase()
{
	struct sml_control *control = tlv_get(current_control);
	/* Thanks to memory coherency, control->state always indicates
	 * the current status of this mutator regardless of the fact that
	 * both the mutator and collector updates it.
	 * If control->state is SYNC1, then the thread is in SYNC1.
	 */
	return PHASE(load_relaxed(&control->state));
}

#endif /* !WITHOUT_MULTITHREAD */

SML_PRIMITIVE void
sml_save()
{
	struct sml_control *control = tlv_get(current_control);
#ifndef WITHOUT_MULTITHREAD
	assert(IS_ACTIVE(load_relaxed(&control->state)));
#endif /* !WITHOUT_MULTITHREAD */
	assert(control->frame_stack->top == NULL);
	control->frame_stack->top = CALLER_FRAME_END_ADDRESS();
}

SML_PRIMITIVE void
sml_unsave()
{
	struct sml_control *control = tlv_get(current_control);
#ifndef WITHOUT_MULTITHREAD
	assert(IS_ACTIVE(load_relaxed(&control->state)));
#endif /* !WITHOUT_MULTITHREAD */
	assert(control->frame_stack->top == CALLER_FRAME_END_ADDRESS());
	control->frame_stack->top = NULL;
}

void *
sml_save_exn_internal(void *obj)
{
	struct sml_control *control = tlv_get(current_control);
	void *old = control->exn_object;
	control->exn_object = obj;
	return old;
}

/* for debug */
int
sml_saved()
{
	struct sml_control *control = tlv_get(current_control);
	return control->frame_stack->top != NULL;
}

static struct sml_control *
control_start(struct frame_stack_range *range)
{
	struct sml_control *control;

	assert(tlv_get_or_init(current_control) == NULL);

	control = xmalloc(sizeof(struct sml_control));
#ifndef WITHOUT_MULTITHREAD
	atomic_init(&control->state, ACTIVE(ASYNC));
	mutex_init(&control->inactive_wait_lock);
	cond_init(&control->inactive_wait_cond);
#endif /* !WITHOUT_MULTITHREAD */
	control->frame_stack = range;
	range->next = NULL;
	control->thread_local_heap = NULL;
	control->exn_object = NULL;
	tlv_set(current_control, control);
	control_register(control);

	/* thread local heap is allocated after the control is set up. */
	control->thread_local_heap = sml_heap_mutator_init();

	return control;
}

static void
control_destroy(struct sml_control *control)
{
	assert(tlv_get(current_control) == control);

#ifndef WITHOUT_MULTITHREAD
	/* To release the thread local heap exclusively, it must be
	 * occupied by the current thread. */
	assert(IS_ACTIVE(load_relaxed(&control->state)));
#endif /* !WITHOUT_MULTITHREAD */

	if (control->thread_local_heap) {
		sml_heap_mutator_destroy(control->thread_local_heap);
		control->thread_local_heap = NULL;
	}

	/* Pointers in the stack is safely ignored since the thread has
	 * been terminated. */
	control->frame_stack = NULL;

	control_leave(control);

	control_unregister(control);
	tlv_set(current_control, NULL);

	mutex_destroy(&control->inactive_wait_lock);
	cond_destroy(&control->inactive_wait_cond);
	free(control);
}

SML_PRIMITIVE void
sml_start(void **arg)
{
	struct frame_stack_range *range = (void*)arg;
	struct sml_control *control = tlv_get_or_init(current_control);

	range->bottom = CALLER_FRAME_END_ADDRESS();
	range->top = NULL;

	if (control == NULL) {
		control_start(range);
	} else {
		control_enter(control);
		range->next = control->frame_stack;
		control->frame_stack = range;
	}
}

SML_PRIMITIVE void
sml_end()
{
	struct sml_control *control = tlv_get(current_control);

#ifndef WITHOUT_MULTITHREAD
	assert(IS_ACTIVE(load_relaxed(&control->state)));
#endif /* !WITHOUT_MULTITHREAD */
	assert(control->frame_stack->bottom == CALLER_FRAME_END_ADDRESS());

	control->frame_stack = control->frame_stack->next;

	if (control->frame_stack) {
		control_leave(control);
	} else {
		control_destroy(control);
	}
}

#ifndef WITHOUT_MULTITHREAD
static void
thread_cancelled(struct sml_control *control)
{
	/* This function is called with a non-NULL control if an SML# thread
	 * is cancelled abnormally, for example, due to pthread_cancel or
	 * pthread_exit.  Since SML# code never cancel any thread, a thread
	 * may be cancelled only in C code (pthread provides asynchronous
	 * cancellation, but no clever programmer use it ;p).  Therefore,
	 * the current thread does not occupy its sml_control at the
	 * beginning of this function.
	 * Note that tlv_get(current_control) is NULL due to thread exit.
	 */
	if (!control)
		return;

	/* recover tlv_get(control) temporarily for thread local heap
	 * deallocation */
	tlv_set(current_control, control);

	/* occupy the control to deallocate the thread local heap safely */
	control_enter(control);

	/* control_destroy resets tlv_get(control) to NULL.
	 * This avoids iteration of destructor calls. */
	control_destroy(control);
}

#endif /* !WITHOUT_MULTITHREAD */

void
sml_run_toplevels(void (**topfuncs)(void))
{
	struct frame_stack_range dummy_range = {.top = NULL, .bottom = NULL};
	struct sml_control *control = tlv_get_or_init(current_control);

	if (control != NULL) {
		for (; *topfuncs; topfuncs++)
			(*topfuncs)();
		return;
	}

	/* Set up a control block with a dummy stack range.
	 * This avoids frequent allocation and deallocation of thread local
	 * heap due to sml_start and sml_end called at the beginning and end
	 * of each top-level fragment. */
	control = control_start(&dummy_range);
	control_leave(control);

	for (; *topfuncs; topfuncs++)
		(*topfuncs)();

	/* NOTE: if an uncaught exception occurs, the following code will
	 * not be executed. */
	control_enter(control);
	assert(control->frame_stack == &dummy_range);
	control_destroy(control);
}

#if !defined WITHOUT_MULTITHREAD && !defined WITHOUT_CONCURRENCY
static void
enforce_phase(enum sml_sync_phase old, enum sml_sync_phase new)
{
	struct sml_control *control;
	unsigned int state ATTR_UNUSED;

	for (control = control_blocks; control; control = control->prev) {
		state = fetch_xor(relaxed, &control->state, old ^ new);
		assert(PHASE(state) == old);
	}
}

#endif /* !WITHOUT_MULTITHREAD */

#if !defined WITHOUT_MULTITHREAD && !defined WITHOUT_CONCURRENCY
static void
sync1()
{
	struct sml_control *control;
	unsigned int old, new, count = 0;

	store_relaxed(&sml_check_flag, 1);

	for (control = control_blocks; control; control = control->prev) {
		old = INACTIVE(PRESYNC1);
		new = INACTIVE(SYNC1);
		if (cmpswap_relaxed(&control->state, &old, new))
			sync1_action();
		count++;
	}

	if (fetch_add(relaxed, &sync_counter, count) + count != 0) {
		mutex_lock(&sync_wait_lock);
		while (!(load_relaxed(&sync_counter) == 0))
			cond_wait(&sync_wait_cond, &sync_wait_lock);
		mutex_unlock(&sync_wait_lock);
	}

	store_relaxed(&sml_check_flag, 0);

	sml_heap_collector_sync1();
}

#endif /* !WITHOUT_MULTITHREAD && !WITHOUT_CONCURRENCY */

#if !defined WITHOUT_MULTITHREAD && !defined WITHOUT_CONCURRENCY
static void
sync2()
{
	struct sml_control *control;
	unsigned int old, new, count = 0;

	store_relaxed(&sml_check_flag, 1);

	for (control = control_blocks; control; control = control->prev) {
		old = INACTIVE(PRESYNC2);
		new = ACTIVE(SYNC2);
		/* lock; all updates must be acquired */
		if (cmpswap_acquire(&control->state, &old, new)) {
			sync2_action(control);
			/* unlock; all updates must be released */
			store_release(&control->state, INACTIVE(SYNC2));
			mutex_lock(&control->inactive_wait_lock);
			cond_signal(&control->inactive_wait_cond);
			mutex_unlock(&control->inactive_wait_lock);
		}
		count++;
	}

	/* all updates performed by all mutators happen before here */
	if (fetch_add(acquire, &sync_counter, count) + count != 0) {
		/* if there is a mutator for which the collector must wait,
		 * do sml_heap_collector_sync2() before the mutator will
		 * respond for time efficiency. */
		sml_heap_collector_sync2();

		mutex_lock(&sync_wait_lock);
		while (!(load_acquire(&sync_counter) == 0))
			cond_wait(&sync_wait_cond, &sync_wait_lock);
		mutex_unlock(&sync_wait_lock);

		store_relaxed(&sml_check_flag, 0);
	} else {
		/* clear sml_check_flag as soon as possible for performance */
		store_relaxed(&sml_check_flag, 0);
		sml_heap_collector_sync2();
	}
}

#endif /* !WITHOUT_MULTITHREAD && !WITHOUT_CONCURRENCY */

#if defined WITHOUT_MULTITHREAD
void
sml_gc()
{
	void sml_heap_mutator_sync2_enum(struct sml_control *);
	struct sml_control *control = tlv_get(current_control);

	sml_heap_mutator_sync2(control, control->thread_local_heap);
	sml_heap_collector_sync2();
	sml_heap_mutator_sync2_enum(control);
	sml_heap_collector_mark();
	sml_run_finalizer();
	sml_heap_collector_async();
}

#elif defined WITHOUT_CONCURRENCY
void
sml_gc()
{
	void sml_heap_mutator_sync2_enum(struct sml_control *);
	struct sml_control *control;

	mutex_lock(&control_blocks_lock);

	store_relaxed(&sml_check_flag, 1);

	for (control = control_blocks; control; control = control->prev)
		activate(control);

	store_relaxed(&sml_check_flag, 0);

	for (control = control_blocks; control; control = control->prev) {
		if (control->thread_local_heap)
			sml_heap_mutator_sync2(control,
					       control->thread_local_heap);
	}
	sml_heap_collector_sync2();
	for (control = control_blocks; control; control = control->prev) {
		if (control->thread_local_heap)
			sml_heap_mutator_sync2_enum(control);
	}
	sml_heap_collector_mark();
	sml_run_finalizer();
	sml_heap_collector_async();

	for (control = control_blocks; control; control = control->prev) {
		mutex_lock(&control->inactive_wait_lock);
		store_release(&control->state, INACTIVE(ASYNC));
		cond_signal(&control->inactive_wait_cond);
		mutex_unlock(&control->inactive_wait_lock);
	}

	mutex_unlock(&control_blocks_lock);
}

#else /* !WITHOUT_MULTITHREAD && !WITHOUT_CONCURRENCY */
void
sml_gc()
{
	/* disable thread creation and termination */
	mutex_lock(&control_blocks_lock);

	assert(load_relaxed(&sync_counter) == 0);

	/* SYNC1: turn on snooping and snapshot barriers */
	enforce_phase(ASYNC, PRESYNC1);
	sync1();

	/* SYNC2: enumerate pointers in root set */
	enforce_phase(SYNC1, PRESYNC2);
	sync2();

	/* MARK: turn off snooping barrier */
	enforce_phase(SYNC2, MARK);
	new_thread_phase = MARK;

	/* enable thread creation and termination */
	mutex_unlock(&control_blocks_lock);

	sml_heap_collector_mark();

	/* ASYNC: turn off snapshot barrier */
	mutex_lock(&control_blocks_lock);
	enforce_phase(MARK, ASYNC);
	new_thread_phase = ASYNC;
	mutex_unlock(&control_blocks_lock);

	sml_run_finalizer();
	sml_heap_collector_async();
}

#endif /* !WITHOUT_MULTITHREAD && !WITHOUT_CONCURRENCY */

static void *
frame_enum_ptr(void *frame_end, void (*trace)(void **, void *), void *data)
{
	void *codeaddr = FRAME_CODE_ADDRESS(frame_end);
	void *frame_begin, **slot;
	const struct sml_frame_layout *layout = sml_lookup_frametable(codeaddr);
	uint16_t num_roots, i;

	/* assume that the stack grows downwards. */
	frame_begin = (void**)frame_end + layout->frame_size;
	num_roots = layout->num_roots;

	for (i = 0; i < num_roots; i++) {
		slot = (void**)frame_end + layout->root_offsets[i];
		if (*slot)
			trace(slot, data);
	}

	return NEXT_FRAME(frame_begin);
}

void
sml_stack_enum_ptr(struct sml_control *control,
		   void (*trace)(void **, void *), void *data)
{
	const struct frame_stack_range *range;
	void *fp, *next;

	if (control->exn_object)
		trace(&control->exn_object, data);

	for (range = control->frame_stack; range; range = range->next) {
		/* skip dummy ranges */
		if (range->bottom == NULL)
			continue;
		assert(range->top != NULL);
		fp = range->top;
		for (;;) {
			next = frame_enum_ptr(fp, trace, data);
			if (fp == range->bottom)
				break;
			fp = next;
		}
	}
}

#if defined WITHOUT_MULTITHREAD
void
sml_exit(int status)
{
	sml_finish();
	exit(status);
}

#else /* !WITHOUT_MULTITHREAD */
void
sml_exit(int status)
{
	struct sml_control *control;
	unsigned int num_threads = 0;

	sml_heap_stop();

	/* disallow thread creation and termination */
	mutex_lock(&control_blocks_lock);

	for (control = control_blocks; control; control = control->prev)
		num_threads++;

	/* If there is no thread other than this thread, release all
	 * resources allocated by the runtime.  Otherwise, terminate the
	 * process immediately without any cleanup. */
	if (num_threads == 0
	    || (num_threads == 1
		&& control_blocks == tlv_get(current_control)))
		sml_finish();

	exit(status);
}

#endif /* !WITHOUT_MULTITHREAD */
