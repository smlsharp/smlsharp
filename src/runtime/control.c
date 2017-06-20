/*
 * control.c
 * @copyright (c) 2007-2014, Tohoku University.
 * @author UENO Katsuhiro
 */

#include "smlsharp.h"
#include <stdlib.h>
#include "heap.h"

#ifndef WITHOUT_MULTITHREAD
struct control {
	_Atomic(unsigned int) state;
	_Atomic(unsigned int) canceled;
	struct control *next;  /* double-linked list */
};
#endif /* !WITHOUT_MULTITHREAD */

#define PHASE_MASK       0x0fU
#define INACTIVE_FLAG    0x10U
#define PHASE(state)     ((state) & PHASE_MASK)
#define ACTIVE(phase)    (phase)
#define INACTIVE(phase)  ((phase) | INACTIVE_FLAG)
#define IS_ACTIVE(state) (!((state) & INACTIVE_FLAG))

#ifdef WITHOUT_MULTITHREAD
#undef IS_ACTIVE
#define IS_ACTIVE(x) 1
#endif /* WITHOUT_MULTITHREAD */

struct sml_mutator {
#ifndef WITHOUT_MASSIVETHREADS
	struct control control;
#endif /* !WITHOUT_MASSIVETHREADS */
	struct frame_stack_range {
		/* If bottom is empty, this is a dummy range; this must be
		 * skipped during stack frame scan.  A dummy range is used
		 * to run a sequence of top-level code fragments efficiently.
		 * See sml_run_toplevels. */
		void *bottom, *top;
		struct frame_stack_range *next;
	} *frame_stack;
	void *exn_object;
};

struct sml_worker {
	struct control control;
	union sml_alloc *thread_local_heap;
	struct sml_mutator *mutator;
#ifndef WITHOUT_MASSIVETHREADS
	/* newly created mutators (but not yet in global mutators list) */
	_Atomic(struct control *) new_mutators;
#endif /* WITHOUT_MASSIVETHREADS */
};

#ifndef WITHOUT_MULTITHREAD
static _Atomic(struct control *) workers;
static enum sml_sync_phase new_worker_phase = ASYNC;
static sml_spinlock_t worker_creation_lock = SPIN_LOCK_INIT;
#endif /* !WITHOUT_MULTITHREAD */

#ifndef WITHOUT_MASSIVETHREADS
static struct control *mutators; /* owned by collector only */
#endif /* !WITHOUT_MASSIVETHREADS */

_Atomic(unsigned int) sml_check_flag;

#ifndef WITHOUT_CONCURRENCY
static pthread_mutex_t sync_wait_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t sync_wait_cond = PTHREAD_COND_INITIALIZER;
static _Atomic(unsigned int) sync_counter;
#endif /* !WITHOUT_CONCURRENCY */

#ifndef WITHOUT_MULTITHREAD
static void cancel(void *p)
{
	/* Thread cancellation is performed in C code since SML# code
	 * never cancel any thread.  We assume that thread is always
	 * canceled synchronously due to, for example, pthread_cancel or
	 * pthread_exit.  POSIX thread provides capability of asynchronous
	 * cancellation, which would break mutator--collector handshaking,
	 * but no clever programmer use it ;p).
	 */
	store_release(&((struct control *)p)->canceled, 1);
}
#endif /* WITHOUT_MULTITHREAD */

worker_tlv_alloc(struct sml_worker *, current_worker, cancel);

#ifndef WITHOUT_MASSIVETHREADS
user_tlv_alloc(struct sml_mutator *, current_mutator, cancel);
#endif /* !WITHOUT_MASSIVETHREADS */

#if !defined WITHOUT_MULTITHREAD && defined WITHOUT_CONCURRENCY
static pthread_mutex_t stop_the_world_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t stop_the_world_cond = PTHREAD_COND_INITIALIZER;
static _Atomic(unsigned int) stop_the_world_flag;
#endif /* !defined WITHOUT_MULTITHREAD && defined WITHOUT_CONCURRENCY */

#if !defined WITHOUT_MULTITHREAD && defined WITHOUT_CONCURRENCY
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
#endif /* !defined WITHOUT_MULTITHREAD && defined WITHOUT_CONCURRENCY */

#if !defined WITHOUT_MULTITHREAD && defined WITHOUT_CONCURRENCY
void
sml_run_the_world()
{
	mutex_lock(&stop_the_world_lock);
	store_relaxed(&stop_the_world_flag, 0);
	cond_broadcast(&stop_the_world_cond);
	mutex_unlock(&stop_the_world_lock);
}
#endif /* !defined WITHOUT_MULTITHREAD && defined WITHOUT_CONCURRENCY */

#ifndef WITHOUT_MULTITHREAD
static void
control_insert(_Atomic(struct control *) *list, struct control *item)
{
	struct control *old = load_relaxed(list);
	do {
		item->next = old;
	} while (!cmpswap_release(list, &old, item));
}
#endif /* !WITHOUT_MULTITHREAD */

#ifndef WITHOUT_MULTITHREAD
static void
control_init(struct control *control, unsigned int state)
{
	atomic_init(&control->state, state);
	atomic_init(&control->canceled, 0);
}
#endif /* !WITHOUT_MULTITHREAD */

#ifdef WITHOUT_MULTITHREAD
static void
control_destroy(struct control *control ATTR_UNUSED)
{
}
#endif /* WITHOUT_MULTITHREAD */

#ifndef WITHOUT_MULTITHREAD
static void
activate(struct control *control)
{
	unsigned int old;

	/* all updates by other threads must happen before here */
	old = fetch_and(acquire, &control->state, ~INACTIVE_FLAG);
	while (IS_ACTIVE(old)) {
		sched_yield();
		old = fetch_and(acquire, &control->state, ~INACTIVE_FLAG);
	}
	assert(IS_ACTIVE(load_relaxed(&control->state)));
}
#endif /* !WITHOUT_MULTITHREAD */

#ifndef WITHOUT_MASSIVETHREADS
static void
activate_myth(struct control *control)
{
	unsigned int old;

	/* all updates by other threads must happen before here */
	old = fetch_and(acquire, &control->state, ~INACTIVE_FLAG);
	while (IS_ACTIVE(old)) {
		myth_yield();
		old = fetch_and(acquire, &control->state, ~INACTIVE_FLAG);
	}
	assert(IS_ACTIVE(load_relaxed(&control->state)));
}
#endif /* !WITHOUT_MULTITHREAD */

#ifndef WITHOUT_MASSIVETHREADS
static void
mutator_register(struct sml_mutator *mutator, struct sml_worker *worker)
{
	control_init(&mutator->control, ACTIVE(ASYNC));
	control_insert(&worker->new_mutators, &mutator->control);
	user_tlv_set(current_mutator, mutator);
}
#endif /* WITHOUT_MASSIVETHREADS */

#ifndef WITHOUT_MULTITHREAD
static void
worker_register(struct sml_worker *worker)
{
	control_init(&worker->control, ACTIVE(ASYNC));
	spin_lock(&worker_creation_lock);
	atomic_init(&worker->control.state, ACTIVE(new_worker_phase));
	control_insert(&workers, &worker->control);
	spin_unlock(&worker_creation_lock);
	worker_tlv_set(current_worker, worker);
}
#endif /* WITHOUT_MULTITHREAD */

static struct sml_mutator *
mutator_new()
{
	struct sml_mutator *mutator;
	mutator = xmalloc(sizeof(struct sml_mutator));
	mutator->frame_stack = NULL;
	mutator->exn_object = NULL;
	return mutator;
}

static struct sml_worker *
worker_new()
{
	struct sml_worker *worker;
	worker = xmalloc(sizeof(struct sml_worker));
	worker->thread_local_heap = sml_heap_worker_init();
	worker->mutator = NULL;
#ifndef WITHOUT_MASSIVETHREADS
	atomic_init(&worker->new_mutators, NULL);
#endif /* WITHOUT_MASSIVETHREADS */
	return worker;
}

static void
mutator_destroy(struct sml_mutator *mutator)
{
	free(mutator);
}

static void
worker_destroy(struct sml_worker *worker)
{
	sml_heap_worker_destroy(worker->thread_local_heap);
#ifdef WITHOUT_MASSIVETHREADS
	mutator_destroy(worker->mutator);
#endif /* WITHOUT_MASSIVETHREADS */
	free(worker);
}

#ifndef WITHOUT_CONCURRENCY
static void
decr_sync_counter_relaxed()
{
	if (fetch_sub(relaxed, &sync_counter, 1) - 1 == 0) {
		mutex_lock(&sync_wait_lock);
		cond_signal(&sync_wait_cond);
		mutex_unlock(&sync_wait_lock);
	}
}
#endif /* !WITHOUT_CONCURRENCY */

#ifndef WITHOUT_CONCURRENCY
static void
decr_sync_counter_release()
{
	if (fetch_sub(release, &sync_counter, 1) - 1 == 0) {
		mutex_lock(&sync_wait_lock);
		cond_signal(&sync_wait_cond);
		mutex_unlock(&sync_wait_lock);
	}
}
#endif /* !WITHOUT_CONCURRENCY */

#if !defined WITHOUT_CONCURRENCY && defined WITHOUT_MASSIVETHREADS
static void
mutator_sync2(struct sml_mutator *mutator)
{
	sml_heap_mutator_sync2(mutator);
}
#endif /* !defined WITHOUT_CONCURRENCY && defined WITHOUT_MASSIVETHREADS */

#ifndef WITHOUT_MASSIVETHREADS
static void
mutator_sync2(struct sml_mutator *mutator)
{
	sml_heap_mutator_sync2(mutator);
	/* all updates by this thread must happen before here */
	decr_sync_counter_release();
}
#endif /* !WITHOUT_MASSIVETHREADS */

#ifndef WITHOUT_CONCURRENCY
static void
mutator_sync2_with(struct sml_mutator *mutator, void *frame_pointer)
{
	void *old_frame_top = mutator->frame_stack->top;
	if (!old_frame_top)
		mutator->frame_stack->top = frame_pointer;
	mutator_sync2(mutator);
	mutator->frame_stack->top = old_frame_top;
}
#endif /* WITHOUT_CONCURRENCY */

#ifndef WITHOUT_CONCURRENCY
static void
worker_sync1(struct sml_worker *worker ATTR_UNUSED)
{
	decr_sync_counter_relaxed();
}
#endif /* WITHOUT_CONCURRENCY */

#ifndef WITHOUT_CONCURRENCY
static void
worker_sync2(struct sml_worker *worker)
{
	sml_heap_worker_sync2(worker->thread_local_heap);
	/* all updates by this thread must happen before here */
	decr_sync_counter_release();
}
#endif /* WITHOUT_CONCURRENCY */

#ifdef WITHOUT_MASSIVETHREADS
static void
mutator_leave(struct sml_mutator *mutator ATTR_UNUSED)
{
}
#endif /* WITHOUT_MASSIVETHREADS */

#ifndef WITHOUT_MASSIVETHREADS
static void
mutator_leave(struct sml_mutator *mutator)
{
	unsigned int old;
	assert(IS_ACTIVE(load_relaxed(&mutator->control.state)));
	/* SYNC2 -> ASYNC */
	old = swap(release, &mutator->control.state, INACTIVE(ASYNC));
	if (old == ACTIVE(PRESYNC2))
		mutator_sync2(mutator);
}
#endif /* WITHOUT_MASSIVETHREADS */

#ifdef WITHOUT_MULTITHRED
static void
worker_leave(struct sml_worker *worker ATTR_UNUSED)
{
}
#endif /* WITHOUT_MULTITHRED */

#if !defined WITHOUT_MULTITHREAD && defined WITHOUT_CONCURRENCY
static void
worker_leave(struct sml_worker *worker)
{
	assert(load_relaxed(&worker->control.state) == ACTIVE(ASYNC));
	/* all updates by this thread must happen before here */
	store_release(&worker->control.state, INACTIVE(ASYNC));
	if (load_relaxed(&stop_the_world_flag)) {
		mutex_lock(&worker->control.inactive_wait_lock);
		cond_signal(&worker->control.inactive_wait_cond);
		mutex_unlock(&worker->control.inactive_wait_lock);
	}
}
#endif /* !defined WITHOUT_MULTITHREAD && defined WITHOUT_CONCURRENCY */

#ifndef WITHOUT_CONCURRENCY
static void
worker_leave(struct sml_worker *worker)
{
	unsigned int old;
	assert(IS_ACTIVE(load_relaxed(&worker->control.state)));
	/* all updates by this thread must happen before here */
	/* PRESYNC1 -> SYNC1 or PRESYNC2 -> SYNC2 */
	old = fetch_or(release, &worker->control.state, INACTIVE_FLAG | 1);
	if (old == ACTIVE(PRESYNC1)) {
		worker_sync1(worker);
	} else if (old == ACTIVE(PRESYNC2)) {
#ifdef WITHOUT_MASSIVETHREADS
		mutator_sync2(worker->mutator);
#endif /* WITHOUT_MASSIVETHREADS */
		worker_sync2(worker);
	}
#ifndef WITHOUT_MASSIVETHREADS
	worker->mutator = NULL;
#endif /* !WITHOUT_MASSIVETHREADS */
}
#endif /* WITHOUT_CONCURRENCY */

SML_PRIMITIVE void
sml_leave()
{
	struct sml_worker *worker = worker_tlv_get(current_worker);
	assert(worker->mutator->frame_stack->top == NULL);
	worker->mutator->frame_stack->top = CALLER_FRAME_END_ADDRESS();
	mutator_leave(worker->mutator);
	worker_leave(worker);
}

void *
sml_leave_internal(void *frame_pointer)
{
	struct sml_worker *worker = worker_tlv_get(current_worker);
	void *old_frame_top = worker->mutator->frame_stack->top;
	if (!old_frame_top)
		worker->mutator->frame_stack->top = frame_pointer;
	mutator_leave(worker->mutator);
	worker_leave(worker);
	return old_frame_top;
}

#ifdef WITHOUT_MASSIVETHREADS
static void
mutator_enter(struct sml_mutator *mutator ATTR_UNUSED)
{
}
#endif /* WITHOUT_MASSIVETHREADS */

#ifndef WITHOUT_MASSIVETHREADS
static void
mutator_enter(struct sml_mutator *mutator)
{
	activate_myth(&mutator->control);

	if (load_relaxed(&mutator->control.state) == ACTIVE(PRESYNC2)) {
		store_relaxed(&mutator->control.state, ACTIVE(ASYNC));
		mutator_sync2(mutator);
	}
}
#endif /* !WITHOUT_MASSIVETHREADS */

#ifdef WITHOUT_MULTITHREAD
static struct sml_worker *
worker_enter(struct sml_worker *worker, struct sml_mutator *mutator ATTR_UNUSED)
{
	return worker;
}
#endif /* WITHOUT_MULTITHREAD */

#if !defined WITHOUT_MULTITHREAD && defined WITHOUT_CONCURRENCY
static struct sml_worker *
worker_enter(struct sml_worker *worker, struct sml_mutator *mutator ATTR_UNUSED)
{
	struct control *control = &worker->control;
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

	return worker;
}
#endif /* !defined WITHOUT_MULTITHREAD && defined WITHOUT_CONCURRENCY */

#if !defined WITHOUT_CONCURRENCY && defined WITHOUT_MASSIVETHREADS
static struct sml_worker *
worker_enter(struct sml_worker *worker, struct sml_mutator *mutator ATTR_UNUSED)
{
	activate(&worker->control);
	return worker;
}
#endif /* !defined WITHOUT_CONCURRENCY && defined WITHOUT_MASSIVETHREADS */

#ifndef WITHOUT_MASSIVETHREADS
static struct sml_worker *
worker_enter(struct sml_worker *worker, struct sml_mutator *mutator)
{
	if (worker) {
		activate(&worker->control);
	} else {
		worker = worker_new();
		worker_register(worker);
	}
	worker->mutator = mutator;
	return worker;
}
#endif /* !WITHOUT_MASSIVETHREADS */

SML_PRIMITIVE void
sml_enter()
{
	struct sml_mutator *mutator = NULL;
	struct sml_worker *worker;
#ifndef WITHOUT_MASSIVETHREADS
	mutator = user_tlv_get(current_mutator);
#endif /* WITHOUT_MASSIVETHREADS */
	mutator_enter(mutator);
	worker = worker_tlv_get(current_worker);
	worker = worker_enter(worker, mutator);
	assert(worker->mutator->frame_stack->top == CALLER_FRAME_END_ADDRESS());
	worker->mutator->frame_stack->top = NULL;
}

void
sml_enter_internal(void *old_frame_top)
{
	struct sml_mutator *mutator = NULL;
	struct sml_worker *worker;
#ifndef WITHOUT_MASSIVETHREADS
	mutator = user_tlv_get(current_mutator);
#endif /* WITHOUT_MASSIVETHREADS */
	mutator_enter(mutator);
	worker = worker_tlv_get(current_worker);
	worker = worker_enter(worker, mutator);
	worker->mutator->frame_stack->top = old_frame_top;
}

#ifdef WITHOUT_MASSIVETHREADS
static void
mutator_sync2_check(struct sml_mutator *mutator, void *frame_pointer)
{
	mutator_sync2_with(mutator, frame_pointer);
}
#endif /* WITHOUT_MASSIVETHREADS */

#ifndef WITHOUT_MASSIVETHREADS
static void
mutator_sync2_check(struct sml_mutator *mutator, void *frame_pointer)
{
	unsigned int state = load_relaxed(&mutator->control.state);
	if (state == ACTIVE(PRESYNC2)) {
		store_relaxed(&mutator->control.state, ACTIVE(ASYNC));
		mutator_sync2_with(mutator, frame_pointer);
	}
}
#endif /* WITHOUT_MASSIVETHREADS */

#ifndef WITHOUT_CONCURRENCY
void
sml_check_internal(void *frame_pointer)
{
	struct sml_worker *worker = worker_tlv_get(current_worker);
	unsigned int state = load_relaxed(&worker->control.state);

	assert(IS_ACTIVE(state));

	switch(state) {
	case ACTIVE(PRESYNC1):
		store_relaxed(&worker->control.state, ACTIVE(SYNC1));
		worker_sync1(worker);
		break;
	case ACTIVE(PRESYNC2):
		store_relaxed(&worker->control.state, ACTIVE(SYNC2));
		mutator_sync2_check(worker->mutator, frame_pointer);
		worker_sync2(worker);
		break;
	}
}
#endif /* !WITHOUT_CONCURRENCY */

SML_PRIMITIVE void
sml_check()
{
	assert(worker_tlv_get(current_worker)->mutator->frame_stack->top
	       == NULL);
	sml_check_internal(CALLER_FRAME_END_ADDRESS());
}

#ifdef WITHOUT_MULTITHREAD
enum sml_sync_phase
sml_current_phase()
{
	return ASYNC;
}
#endif /* WITHOUT_MULTITHREAD */

#ifndef WITHOUT_MULTITHREAD
enum sml_sync_phase
sml_current_phase()
{
	struct sml_worker *worker = worker_tlv_get(current_worker);
	/* Thanks to memory coherency, control.state always indicates
	 * the current status of this mutator regardless of the fact that
	 * both the mutator and collector updates it.
	 * If worker->control.state is SYNC1, then the thread is in SYNC1
	 * at this instant.
	 */
	return PHASE(load_relaxed(&worker->control.state));
}
#endif /* !WITHOUT_MULTITHREAD */

SML_PRIMITIVE void
sml_save()
{
	struct sml_worker *worker = worker_tlv_get(current_worker);
	struct sml_mutator *mutator = worker->mutator;
	assert(IS_ACTIVE(load_relaxed(&worker->control.state)));
	assert(mutator->frame_stack->top == NULL);
	mutator->frame_stack->top = CALLER_FRAME_END_ADDRESS();
}

SML_PRIMITIVE void
sml_unsave()
{
	struct sml_worker *worker = worker_tlv_get(current_worker);
	struct sml_mutator *mutator = worker->mutator;
	assert(IS_ACTIVE(load_relaxed(&worker->control.state)));
	assert(mutator->frame_stack->top == CALLER_FRAME_END_ADDRESS());
	mutator->frame_stack->top = NULL;
}

void *
sml_save_exn_internal(void *obj)
{
	struct sml_worker *worker = worker_tlv_get(current_worker);
	struct sml_mutator *mutator = worker->mutator;
	void *old = mutator->exn_object;
	mutator->exn_object = obj;
	return old;
}

/* for debug */
#ifndef NDEBUG
int
sml_saved()
{
	struct sml_worker *worker = worker_tlv_get(current_worker);
	struct sml_mutator *mutator = worker->mutator;
#ifndef WITHOUT_MASSIVETHREADS
	mutator = user_tlv_get(current_mutator);
#endif /* WITHOUT_MASSIVETHREADS */
	return mutator->frame_stack->top != NULL;
}
#endif /* NDEBUG */

void
sml_control_init()
{
	worker_tlv_init(current_worker);
#ifndef WITHOUT_MASSIVETHREADS
	user_tlv_init(current_mutator);
#endif /* !WITHOUT_MASSIVETHREADS */
}

SML_PRIMITIVE void
sml_start(void **arg)
{
	struct frame_stack_range *range = (void*)arg;
	struct sml_mutator *mutator = NULL;
	struct sml_worker *worker;
	range->bottom = CALLER_FRAME_END_ADDRESS();
	range->top = NULL;

#ifndef WITHOUT_MASSIVETHREADS
	mutator = user_tlv_get(current_mutator);
	if (mutator) {
		mutator_enter(mutator);
		worker = worker_tlv_get(current_worker);
		worker = worker_enter(worker, mutator);
	} else {
		mutator = mutator_new();
		worker = worker_tlv_get(current_worker);
		worker = worker_enter(worker, mutator);
		mutator_register(mutator, worker);
	}
#else /* !WITHOUT_MASSIVETHREADS */
	worker = worker_tlv_get(current_worker);
	if (worker) {
		worker = worker_enter(worker, mutator);
	} else {
		worker = worker_new();
		worker->mutator = mutator_new();
		worker_register(worker);
	}
#endif /* !WITHOUT_MASSIVETHREADS */

	range->next = worker->mutator->frame_stack;
	worker->mutator->frame_stack = range;
}

SML_PRIMITIVE void
sml_end()
{
	struct sml_worker *worker = worker_tlv_get(current_worker);
	struct sml_mutator *mutator = worker->mutator;

	assert(IS_ACTIVE(load_relaxed(&worker->control.state)));
	assert(mutator->frame_stack->bottom == CALLER_FRAME_END_ADDRESS());

	mutator->frame_stack = mutator->frame_stack->next;
	mutator_leave(worker->mutator);
	worker_leave(worker);
}

#ifndef WITHOUT_MASSIVETHREADS
static struct control **
mutators_gc(struct control **p)
{
	struct control *control;

	while ((control = *p)) {
		if (load_acquire(&control->canceled)) {
			*p = control->next;
			mutator_destroy((struct sml_mutator *)control);
		} else {
			p = &control->next;
		}
	}
	return p;
}
#endif /* WITHOUT_MASSIVETHREADS */

#ifndef WITHOUT_MASSIVETHREADS
static void
gather_mutators(struct sml_worker *worker)
{
	struct control **new_mutators;

	new_mutators = mutators_gc(&mutators);

	for (; worker; worker = (struct sml_worker *)worker->control.next) {
		*new_mutators = swap(acquire, &worker->new_mutators, NULL);
		new_mutators = mutators_gc(new_mutators);
	}
}
#endif /* !WITHOUT_MASSIVETHREADS */

#ifndef WITHOUT_MULTITHREAD
static void
control_gc()
{
	struct control *first_worker, **p;
	struct control **new_mutators;
	struct sml_worker *w;

#ifndef WITHOUT_MASSIVETHREADS
	new_mutators = mutators_gc(&mutators);
#endif /* !WITHOUT_MASSIVETHREADS */

	first_worker = load_acquire(&workers);
	if (!first_worker)
		return;

	/* destroy canceled workers except for the first one */
	p = &first_worker->next;
	while ((w = (struct sml_worker *)*p)) {
		if (load_acquire(&w->control.canceled)) {
#ifndef WITHOUT_MASSIVETHREADS
			*new_mutators = load_acquire(&w->new_mutators);
			new_mutators = mutators_gc(new_mutators);
#endif /* !WITHOUT_MASSIVETHREADS */
			*p = w->control.next;
			worker_destroy(w);
		} else {
#ifndef WITHOUT_MASSIVETHREADS
			*new_mutators = swap(acquire, &w->new_mutators, NULL);
			new_mutators = mutators_gc(new_mutators);
#endif /* !WITHOUT_MASSIVETHREADS */
			p = &w->control.next;
		}
	}

	/* if the first one is canceled, destroy it if we can occupy it */
	if (load_acquire(&first_worker->canceled)
	    && cmpswap_acquire(&workers, &first_worker, first_worker->next)) {
		w = (struct sml_worker *)first_worker;
#ifndef WITHOUT_MASSIVETHREADS
		*new_mutators = load_acquire(&w->new_mutators);
		new_mutators = mutators_gc(new_mutators);
#endif /* !WITHOUT_MASSIVETHREADS */
		worker_destroy(w);
	}
}
#endif /* !WITHOUT_MULTITHREAD */

#ifdef WITHOUT_MULTITHREAD
void
sml_detach()
{
	struct sml_worker *worker = worker_tlv_get_or_init(current_worker);
	if (worker) {
		if (mutator->frame_stack != NULL)
			sml_fatal(0, "sml_detach: ML code is running");
		mutator_destroy(worker->mutator);
		worker_destroy(worker);
	}
	worker_tlv_set(current_worker, NULL);
}
#endif /* WITHOUT_MULTITHREAD */

#ifndef WITHOUT_MULTITHREAD
void
sml_detach()
{
	struct sml_worker *worker = worker_tlv_get_or_init(current_worker);
	struct sml_mutator *mutator = worker->mutator;

#ifndef WITHOUT_MASSIVETHREADS
	mutator = user_tlv_get_or_init(current_mutator);
	user_tlv_set(current_mutator, NULL);
	if (mutator)
		cancel(mutator);
#endif /* WITHOUT_MASSIVETHREADS */

	if (mutator && mutator->frame_stack != NULL)
		sml_fatal(0, "sml_detach: ML code is running");

	cancel(worker);
	worker_tlv_set(current_worker, NULL);
}
#endif /* !WITHOUT_MULTITHREAD */

#ifndef WITHOUT_CONCURRENCY
static void
change_phase(struct control *list,
	     enum sml_sync_phase old, enum sml_sync_phase new)
{
	struct control *control;
	unsigned int state ATTR_UNUSED;

	for (control = list; control; control = control->next) {
		state = fetch_xor(relaxed, &control->state, old ^ new);
		assert(PHASE(state) == old);
	}
}
#endif /* !WITHOUT_CONCURRENCY */

#ifndef WITHOUT_CONCURRENCY
static void
sync1(struct control *workers)
{
	struct control *control;
	unsigned int old, new, count = 0;

	store_relaxed(&sml_check_flag, 1);

	for (control = workers; control; control = control->next) {
		old = INACTIVE(PRESYNC1);
		new = INACTIVE(SYNC1);
		if (cmpswap_relaxed(&control->state, &old, new))
			worker_sync1((struct sml_worker *)control);
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
#endif /* !WITHOUT_CONCURRENCY */

#ifndef WITHOUT_CONCURRENCY
static void
sync2(struct control *workers)
{
	struct control *control;
	unsigned int old, new, count = 0;

	sml_heap_collector_sync2();

	store_relaxed(&sml_check_flag, 1);

#ifndef WITHOUT_MASSIVETHREADS
	for (control = mutators; control; control = control->next) {
		old = INACTIVE(PRESYNC2);
		new = ACTIVE(ASYNC);
		/* all updates so far must happen before here */
		if (cmpswap_acquire(&control->state, &old, new)) {
			mutator_sync2((struct sml_mutator *)control);
			/* all updates by this thread must happen before here */
			store_release(&control->state, INACTIVE(ASYNC));
		}
		count++;
	}
#endif /* !WITHOUT_MASSIVETHREADS */

	for (control = workers; control; control = control->next) {
		old = INACTIVE(PRESYNC2);
		new = ACTIVE(SYNC2);
		/* all updates so far must happen before here */
		if (cmpswap_acquire(&control->state, &old, new)) {
			struct sml_worker *w = (struct sml_worker *)control;
#ifdef WITHOUT_MASSIVETHREADS
			mutator_sync2(w->mutator);
#endif /* WITHOUT_MASSIVETHREADS */
			worker_sync2(w);
			/* all updates by this thread must happen before here */
			store_release(&control->state, INACTIVE(SYNC2));
		}
		count++;
	}

	/* all updates so far must happen before here */
	if (fetch_add(acquire, &sync_counter, count) + count != 0) {
		mutex_lock(&sync_wait_lock);
		while (!(load_acquire(&sync_counter) == 0))
			cond_wait(&sync_wait_cond, &sync_wait_lock);
		mutex_unlock(&sync_wait_lock);
	}

	store_relaxed(&sml_check_flag, 0);
}
#endif /* WITHOUT_CONCURRENCY */

#ifdef WITHOUT_MULTITHREAD
void
sml_gc()
{
	struct sml_worker *worker = worker_tlv_get(current_worker);

	sml_heap_worker_sync2(worker->thread_local_heap);
	sml_heap_collector_sync2();
	sml_heap_mutator_sync2(worker->mutator);
	sml_heap_collector_mark();
	sml_run_finalizer();
	sml_heap_collector_async();
}
#endif /* WITHOUT_MULTITHREAD */

#if !defined WITHOUT_MULTITHREAD && defined WITHOUT_CONCURRENCY
void
sml_gc()
{
	/* stop-the-world garbage collection */
	struct control *control;

	mutex_lock(&thread_creation_lock);
	ASSERT(load_relaxed(&stop_the_world_flag));

	store_relaxed(&sml_check_flag, 1);

	for (control = workers; control; control = control->next)
		activate(control);

	store_relaxed(&sml_check_flag, 0);

	for (control = workers; control; control = control->next) {
		struct sml_worker *worker = (struct sml_worker *)control;
		sml_heap_worker_sync2(worker->thread_local_heap);
	}
	sml_heap_collector_sync2();
	for (control = workers; control; control = control->next) {
		struct sml_worker *worker = (struct sml_worker *)control;
		sml_heap_mutator_sync2(worker->mutator);
	}
	sml_heap_collector_mark();
	sml_run_finalizer();
	sml_heap_collector_async();

	control_gc(&workers, worker_destroy);

	for (control = workers; control; control = control->next) {
		mutex_lock(&control->inactive_wait_lock);
		store_release(&control->state, INACTIVE(ASYNC));
		cond_signal(&control->inactive_wait_cond);
		mutex_unlock(&control->inactive_wait_lock);
	}

	mutex_unlock(&control_blocks_lock);
}
#endif /* !defined WITHOUT_MULTITHREAD && defined WITHOUT_CONCURRENCY */

#ifndef WITHOUT_CONCURRENCY
void
sml_gc()
{
	struct control *current_workers;
	control_gc();

	assert(load_relaxed(&sync_counter) == 0);

	/* SYNC1: turn on snooping and snapshot barriers */

	/* all new worker threads must be in SYNC1. */
	spin_lock(&worker_creation_lock);
	new_worker_phase = SYNC1;
	current_workers = load_relaxed(&workers);
	spin_unlock(&worker_creation_lock);

	change_phase(current_workers, ASYNC, PRESYNC1);

	sync1(current_workers);

	/* SYNC2: rootset & allocation pointer snapshot */

	/* all new worker threads must be in SYNC2. */
	spin_lock(&worker_creation_lock);
	new_worker_phase = SYNC2;
	current_workers = load_relaxed(&workers);
	spin_unlock(&worker_creation_lock);

#ifndef WITHOUT_MASSIVETHREADS
	/* mutators must precede workers */
	gather_mutators((struct sml_worker *)current_workers);
	change_phase(mutators, ASYNC, PRESYNC2);
#endif /* !WITHOUT_MASSIVETHREADS */
	change_phase(current_workers, SYNC1, PRESYNC2);

	sync2(current_workers);

	/* MARK: turn off snooping barrier */

	/* all new worker threads must be in MARK. */
	spin_lock(&worker_creation_lock);
	new_worker_phase = MARK;
	current_workers = load_relaxed(&workers);
	spin_unlock(&worker_creation_lock);

	change_phase(current_workers, SYNC2, MARK);

	sml_heap_collector_mark();

	/* ASYNC: turn off snapshot barrier */
	spin_lock(&worker_creation_lock);
	new_worker_phase = ASYNC;
	current_workers = load_relaxed(&workers);
	spin_unlock(&worker_creation_lock);

	change_phase(current_workers, MARK, ASYNC);

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
sml_stack_enum_ptr(struct sml_mutator *mutator,
		   void (*trace)(void **, void *), void *data)
{
	const struct frame_stack_range *range;
	void *fp, *next;

	if (mutator->exn_object)
		trace(&mutator->exn_object, data);

	for (range = mutator->frame_stack; range; range = range->next) {
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

#ifdef WITHOUT_MULTITHREAD
void
sml_exit(int status)
{
	sml_finish();
	exit(status);
}
#endif /* WITHOUT_MULTITHREAD */

#ifndef WITHOUT_MULTITHREAD
void
sml_exit(int status)
{
	struct control *control;

	control = (struct control *)worker_tlv_get_or_init(current_worker);
	if (control)
		cancel(control);

#ifndef WITHOUT_MASSIVETHREADS
	control = (struct control *)user_tlv_get_or_init(current_mutator);
	if (control)
		cancel(control);
#endif /* WITHOUT_MASSIVETHREADS */

	sml_heap_stop();

	/* disallow thread creation and termination */
	spin_lock(&worker_creation_lock);

	control = load_relaxed(&workers);
#ifndef WITHOUT_MASSIVETHREADS
	control = mutators;
#endif /* WITHOUT_MASSIVETHREADS */

	/* If there is no thread other than this thread, release all
	 * resources allocated by the runtime.  Otherwise, terminate the
	 * process immediately without any cleanup. */
	if (control == NULL)
		sml_finish();

	exit(status);
}

#endif /* !WITHOUT_MULTITHREAD */
