/*
 * heap_cheney.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: heap.c,v 1.10 2008/12/10 03:23:23 katsu Exp $
 */

#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include "smlsharp.h"
#include "object.h"
#include "objspace.h"
#include "heap.h"

/*#define GCTIME*/

#ifdef GCSTAT
#define GCTIME
#endif /* GCSTAT */

#if defined GCSTAT || defined GCTIME
#include <stdarg.h>
#include <stdio.h>
#include "timer.h"
#endif /* GCSTAT || GCTIME */

#if defined GCSTAT || defined GCTIME
static struct {
	FILE *file;
	size_t probe_threshold;
	unsigned int verbose;
	unsigned int count;
	sml_timer_t exec_begin, exec_end;
	sml_time_t exec_time;
	struct gcstat_gc {
		unsigned int count;
		sml_time_t total_time;
		unsigned long total_copy_bytes;
		unsigned long total_copy_count;
		unsigned long total_forward_count;
	} gc;
	struct {
		unsigned int trigger;
		unsigned int alloc_count;
		unsigned int forward_count;
		unsigned int copy_count;
		size_t alloc_bytes;
		size_t copy_bytes;
	} last;
} gcstat;

#define clear_last_counts() \
	(memset(&gcstat.last, 0, sizeof(gcstat.last)))

#define GCSTAT_VERBOSE_GC      10
#define GCSTAT_VERBOSE_COUNT   20
#define GCSTAT_VERBOSE_HEAP    30
#define GCSTAT_VERBOSE_PROBE   40
#define GCSTAT_VERBOSE_MAX    100

static void (*stat_notice)(const char *format, ...) ATTR_PRINTF(1, 2) =
	sml_notice;

#ifdef GCSTAT
static void
gcstat_print(const char *fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	vfprintf(gcstat.file, fmt, args);
	fputs("\n", gcstat.file);
	va_end(args);
}

static void
print_alloc_count()
{
	if (gcstat.verbose < GCSTAT_VERBOSE_COUNT)
		return;

	stat_notice("count:");
	if (gcstat.last.alloc_count != 0
	    || gcstat.last.alloc_bytes != 0)
		stat_notice(" from: {alloc: %u}", gcstat.last.alloc_count);
}
#endif /* GCSTAT */
#endif /* GCSTAT || GCTIME */

#ifdef GCSTAT
#define GCSTAT_FORWARD_COUNT()  (gcstat.last.forward_count++)
#define GCSTAT_COPY_COUNT(size) \
	(gcstat.last.copy_count++, gcstat.last.copy_bytes += (size))
#define GCSTAT_TRIGGER(size)  (gcstat.last.trigger = (size))
#else
#define GCSTAT_FORWARD_COUNT()
#define GCSTAT_COPY_COUNT(size)
#define GCSTAT_TRIGGER(size)
#endif /* GCSTAT */

#define INITIAL_OFFSET  ALIGNSIZE(OBJ_HEADER_SIZE, MAXALIGN)

#define GC_FORWARDED_FLAG     OBJ_GC1_MASK
#define OBJ_FORWARDED         OBJ_GC1
#define OBJ_FORWARD_PTR(obj)  (*(void**)(obj))

#define IS_IN_HEAP_SPACE(heap_space, ptr) \
	((heap_space).base <= (char*)(ptr) \
	 && (char*)(ptr) < (heap_space).limit)

struct heap_space sml_heap_from_space = {0, 0, 0};
static struct heap_space sml_heap_to_space = {0, 0, 0};

/* thread-local information */
struct sml_heap_thread {
	int dummy;
};

static void
heap_space_alloc(struct heap_space *heap, size_t size)
{
	size_t pagesize = getpagesize();
	size_t allocsize;
	void *page;

	allocsize = ALIGNSIZE(size, pagesize);
#ifdef DEBUG
	{
	static void *base = (void*)0x2000000;
	page = mmap(base, allocsize, PROT_READ | PROT_WRITE,
		    MAP_ANON | MAP_PRIVATE, -1, 0);
	base = (char*)base + 0x2000000;
	}
	if (page == (void*)-1)
		sml_sysfatal("mmap");
#elif 0
	page = mmap(NULL, allocsize, PROT_READ | PROT_WRITE,
		    MAP_ANON | MAP_PRIVATE, -1, 0);
	if (page == (void*)-1)
		sml_sysfatal("mmap");
#else
	page = xmalloc(allocsize);
#endif

	heap->base = page;
	heap->limit = page + allocsize;
}

#ifdef DEBUG
static void
heap_space_protect(struct heap_space *heap)
{
	mprotect(heap->base, heap->limit - heap->base, 0);
}

static void
heap_space_unprotect(struct heap_space *heap)
{
	mprotect(heap->base, heap->limit - heap->base, PROT_READ | PROT_WRITE);
}
#else
#define heap_space_protect(heap)  ((void)0)
#define heap_space_unprotect(heap)  ((void)0)
#endif /* DEBUG */

static void
heap_space_swap()
{
	struct heap_space tmp_space;

	tmp_space = sml_heap_from_space;
	sml_heap_from_space = sml_heap_to_space;
	sml_heap_to_space = tmp_space;
}

static void
heap_space_free(struct heap_space *heap)
{
	munmap(heap->base, heap->limit - heap->base);
}

static void
heap_space_clear(struct heap_space *heap)
{
	heap->free = heap->base + INITIAL_OFFSET;
	ASSERT(heap->free < heap->limit);
#ifdef DEBUG
	memset(heap->base, 0x77, heap->limit - heap->base);
#endif
}

static void
heap_space_init(struct heap_space *heap, size_t size)
{
	if (size < INITIAL_OFFSET)
		size = INITIAL_OFFSET;
	heap_space_alloc(heap, size);
	heap_space_clear(heap);
}

#define HEAP_START(h)  ((h).base + INITIAL_OFFSET)
#define HEAP_USED(h)   ((size_t)((h).free - (h).base))
#define HEAP_REST(h)   ((size_t)((h).limit - (h).free))
#define HEAP_TOTAL(h)  ((size_t)((h).limit - HEAP_START(h)))

#ifdef GCSTAT
static size_t
heap_filled(struct heap_space *heap, size_t *ret_bytes)
{
	char *p = HEAP_START(*heap);
	size_t filled = 0, count = 0;

	while (p < heap->free) {
		count++;
		filled += OBJ_TOTAL_SIZE(p);
		p += HEAP_ROUND_SIZE(OBJ_TOTAL_SIZE(p));
	}

	if (ret_bytes)
		*ret_bytes = filled;
	return count;
}

static void
print_heap_occupancy()
{
	size_t count, filled;

	if (gcstat.verbose < GCSTAT_VERBOSE_HEAP)
		return;

	stat_notice("heap:");
	count = heap_filled(&sml_heap_from_space, &filled);
	stat_notice(" from:");
	stat_notice("  - {filled: %lu, count: %lu, used: %lu}",
		    (unsigned long)filled, (unsigned long)count,
		    (unsigned long)HEAP_USED(sml_heap_from_space));
	count = heap_filled(&sml_heap_to_space, &filled);
	stat_notice(" to:");
	stat_notice("  - {filled: %lu, count: %lu, used: %lu}",
		    (unsigned long)filled, (unsigned long)count,
		    (unsigned long)HEAP_USED(sml_heap_to_space));
}
#endif /* GCSTAT */

/* for debug */
void
sml_heap_dump()
{
	char *cur;
	unsigned int size, allocsize;

	sml_debug("from space : %p - %p\n",
		  HEAP_START(sml_heap_from_space),
		  sml_heap_from_space.limit);

	cur = HEAP_START(sml_heap_from_space);

	while (cur < sml_heap_from_space.free) {
		size = OBJ_TOTAL_SIZE(cur);
		allocsize = HEAP_ROUND_SIZE(size);
		sml_debug("%p : type=%08x, size=%u, total=%u, alloc=%u\n",
			  cur, OBJ_TYPE(cur), OBJ_SIZE(cur), size, allocsize);
		cur += allocsize;
	}
}

void
sml_heap_init(size_t size)
{
	size_t space_size;

#ifdef GCSTAT
	const char *env;
	env = getenv("SMLSHARP_GCSTAT_FILE");
	if (env) {
		gcstat.file = fopen(env, "w");
		if (gcstat.file == NULL) {
			perror("sml_heap_init");
			abort();
		}
		stat_notice = gcstat_print;
	}
	env = getenv("SMLSHARP_GCSTAT_VERBOSE");
	if (env)
		gcstat.verbose = strtol(env, NULL, 10);
	else
		gcstat.verbose = GCSTAT_VERBOSE_MAX;
	env = getenv("SMLSHARP_GCSTAT_PROBE");
	if (env) {
		gcstat.probe_threshold = strtol(env, NULL, 10);
		if (gcstat.probe_threshold == 0)
			gcstat.probe_threshold = size;
	} else {
		gcstat.probe_threshold = 2 * 1024 * 1024;
	}
#endif /* GCSTAT */

#ifdef GCTIME
	sml_timer_now(gcstat.exec_begin);
#endif /* GCTIME */

	space_size = size / 2;
	heap_space_init(&sml_heap_from_space, space_size);
	heap_space_init(&sml_heap_to_space, space_size);

#ifdef GCSTAT
	stat_notice("---");
	stat_notice("event: init");
	stat_notice("time: 0.0");
	stat_notice("heap_size: %lu", (unsigned long)size);
	stat_notice("config:");
	stat_notice(" from: {size: %lu}",
		    (unsigned long)HEAP_TOTAL(sml_heap_from_space));
	stat_notice(" to: {size: %lu}",
		    (unsigned long)HEAP_TOTAL(sml_heap_to_space));
	stat_notice("counters:");
	stat_notice(" heap: [alloc]");
	print_heap_occupancy();
#endif /* GCSTAT */
}

void
sml_heap_free()
{
	heap_space_free(&sml_heap_from_space);
	heap_space_free(&sml_heap_to_space);

#ifdef GCTIME
	sml_timer_now(gcstat.exec_end);
	sml_timer_dif(gcstat.exec_begin, gcstat.exec_end, gcstat.exec_time);
#endif /* GCTIME */
#if defined GCSTAT || defined GCTIME
#ifdef GCSTAT
	stat_notice("---");
	stat_notice("event: finish");
	stat_notice("time: "TIMEFMT, TIMEARG(gcstat.exec_time));
	print_alloc_count();
#endif /* GCSTAT */
	stat_notice("exec time      : "TIMEFMT" #sec",
		    TIMEARG(gcstat.exec_time));
	stat_notice("gc count       : %u #times", gcstat.gc.count);
	stat_notice("gc time        : "TIMEFMT" #sec (%4.2f%%), avg: %.6f sec",
		    TIMEARG(gcstat.gc.total_time),
		    TIMEFLOAT(gcstat.gc.total_time)
		    / TIMEFLOAT(gcstat.exec_time) * 100.0f,
		    TIMEFLOAT(gcstat.gc.total_time)
		    / (double)gcstat.gc.count);
#ifdef GCSTAT
	stat_notice("total copy bytes    :%10lu #bytes, avg:%8.2f bytes",
		    gcstat.gc.total_copy_bytes,
		    (double)gcstat.gc.total_copy_bytes
		    / (double)gcstat.gc.count);
	stat_notice("total forward count :%10lu #times, avg:%8.2f times",
		    gcstat.gc.total_forward_count,
		    (double)gcstat.gc.total_forward_count
		    / (double)gcstat.gc.count);
	if (gcstat.file)
		fclose(gcstat.file);
#endif /* GCSTAT */
#endif /* GCSTAT || GCTIME */
}

void
sml_heap_thread_init()
{
	struct sml_heap_thread *th = xmalloc(sizeof(struct sml_heap_thread));
	th->dummy = 0;
	SML_THREAD_ENV->heap = th;
}

void
sml_heap_thread_free()
{
	struct sml_thread_env *env = SML_THREAD_ENV;
	free(env->heap);
	env->heap = NULL;
}

void
sml_heap_barrier(void **writeaddr, void *objaddr)
{
	if (IS_IN_HEAP_SPACE(sml_heap_from_space, writeaddr))
		return;

	ASSERT(!IS_IN_HEAP_SPACE(sml_heap_to_space, writeaddr));
	ASSERT(!IS_IN_HEAP_SPACE(sml_heap_to_space, *writeaddr));

	/* remember the writeaddr as a root pointer which is outside
	 * of the heap. */
	sml_global_barrier(writeaddr, objaddr, MAJOR);
}

static int
obj_forwarded(void *obj)
{
	return IS_IN_HEAP_SPACE(sml_heap_from_space, obj)
		&& OBJ_FORWARDED(obj);
}

static void forward(void **slot, void *data);
static const sml_trace_cls forward_fn = forward;
#define forward_cls ((sml_trace_cls*)&forward_fn)

static void
forward(void **slot, void *data ATTR_UNUSED)
{
	void *obj = *slot;
	size_t obj_size, alloc_size;
	void *newobj;

	if (!IS_IN_HEAP_SPACE(sml_heap_from_space, obj)) {
		DBG(("%p at %p outside", obj, slot));
		ASSERT(!IS_IN_HEAP_SPACE(sml_heap_to_space, obj));
		if (obj != NULL) {
			obj = sml_trace_ptr(obj, MAJOR);
			if (obj != NULL)
				sml_obj_enum_ptr(obj, forward_cls);
		}
		return;
	}

	if (OBJ_FORWARDED(obj)) {
		*slot = OBJ_FORWARD_PTR(obj);
		GCSTAT_FORWARD_COUNT();
		DBG(("%p at %p forward -> %p", obj, slot, *slot));
		return;
	}

	obj_size = OBJ_TOTAL_SIZE(obj);
	alloc_size = HEAP_ROUND_SIZE(obj_size);

	ASSERT(HEAP_REST(sml_heap_to_space) >= alloc_size);

	newobj = sml_heap_to_space.free;
	sml_heap_to_space.free += alloc_size;
	memcpy(&OBJ_HEADER(newobj), &OBJ_HEADER(obj), obj_size);
	GCSTAT_COPY_COUNT(obj_size);

	DBG(("%p at %p copy -> %p (%lu/%lu)",
	     obj, slot, newobj,
	     (unsigned long)obj_size, (unsigned long)alloc_size));

	OBJ_HEADER(obj) |= GC_FORWARDED_FLAG;
	OBJ_FORWARD_PTR(obj) = newobj;
	*slot = newobj;
}

#define forward_children(obj)  sml_obj_enum_ptr(obj, forward_cls)

static void
forward_region(void *start)
{
	char *cur = start;

	DBG(("%p - %p", start, sml_heap_to_space.free));

	while (cur < sml_heap_to_space.free) {
		forward_children(cur);
		cur += HEAP_ROUND_SIZE(OBJ_TOTAL_SIZE(cur));
	}
}

static void
forward_deep(void **slot, void *data ATTR_UNUSED)
{
	void *cur = sml_heap_to_space.free;
	forward(slot, NULL);
	forward_region(cur);
}

static const sml_trace_cls forward_deep_fn = forward_deep;
#define forward_deep_cls ((sml_trace_cls*)&forward_deep_fn)

void
sml_heap_gc(void)
{
#ifdef GCTIME
	sml_timer_t b_start, b_end;
	sml_time_t gctime;
#endif /* GCTIME */
#ifdef GCSTAT
	sml_time_t t;
#endif /* GCSTAT */

	HEAP_LOCK();

#ifdef GCSTAT
	if (gcstat.verbose >= GCSTAT_VERBOSE_COUNT) {
		stat_notice("---");
		stat_notice("event: start gc");
		stat_notice("trigger: %u", gcstat.last.trigger);
		print_alloc_count();
		print_heap_occupancy();
	}
	clear_last_counts();
#endif /* GCSTAT */

#ifdef GCTIME
	gcstat.gc.count++;
	sml_timer_now(b_start);
#endif /* GCTIME */

	heap_space_unprotect(&sml_heap_to_space);

	DBG(("start gc (%lu/%lu used) %p -> %p",
	     (unsigned long)HEAP_USED(sml_heap_from_space),
	     (unsigned long)HEAP_TOTAL(sml_heap_from_space),
	     sml_heap_from_space.base, sml_heap_to_space.base));

	sml_rootset_enum_ptr(forward_cls, MAJOR);

	DBG(("copying root completed"));

	/* forward objects which are reachable from live objects. */
	forward_region(HEAP_START(sml_heap_to_space));

	/* check finalization */
	sml_check_finalizer(MAJOR, obj_forwarded, forward_deep_cls);

	/* clear from-space, and swap two spaces. */
	heap_space_clear(&sml_heap_from_space);
	heap_space_swap();
	heap_space_protect(&sml_heap_to_space);

	/* sweep malloc heap */
	sml_malloc_sweep(MAJOR);

	DBG(("gc finished. remain %lu bytes",
	     (unsigned long)HEAP_USED(sml_heap_from_space)));

#ifdef GCTIME
	sml_timer_now(b_end);
#endif /* GCTIME */
	HEAP_UNLOCK();

#ifdef GCTIME
	sml_timer_dif(b_start, b_end, gctime);
	sml_time_accum(gctime, gcstat.gc.total_time);
#endif /* GCTIME */
#ifdef GCSTAT
	gcstat.gc.total_copy_bytes += gcstat.last.copy_bytes;
	gcstat.gc.total_copy_count += gcstat.last.copy_count;
	gcstat.gc.total_forward_count += gcstat.last.forward_count;
	if (gcstat.verbose >= GCSTAT_VERBOSE_GC) {
		sml_timer_dif(gcstat.exec_begin, b_start, t);
		stat_notice("time: "TIMEFMT, TIMEARG(t));
		stat_notice("---");
		stat_notice("event: end gc");
		sml_timer_dif(gcstat.exec_begin, b_end, t);
		stat_notice("time: "TIMEFMT, TIMEARG(t));
		stat_notice("duration: "TIMEFMT, TIMEARG(gctime));
		stat_notice("copy: %u", gcstat.last.copy_count);
		stat_notice("forward: %u", gcstat.last.forward_count);
		stat_notice("copy_bytes: %lu",
			    (unsigned long)gcstat.last.copy_bytes);
		print_heap_occupancy();
	}
#endif /* GCSTAT */

	/* start finalizers */
	sml_run_finalizer();
}

#ifdef GCSTAT
void
sml_heap_alloced(size_t size)
{
	sml_timer_t b;
	sml_time_t t;
	
	gcstat.last.alloc_bytes += size;
	if (gcstat.last.alloc_bytes > gcstat.probe_threshold
	    && gcstat.verbose >= GCSTAT_VERBOSE_PROBE) {
		sml_timer_now(b);
		sml_timer_dif(gcstat.exec_begin, b, t);
		stat_notice("---");
		stat_notice("event: probe");
		stat_notice("time: "TIMEFMT, TIMEARG(t));
		print_alloc_count();
		print_heap_occupancy();
		clear_last_counts();
	}
	gcstat.last.alloc_count++;
}
#endif /* GCSTAT */

void *
sml_heap_slow_alloc(size_t obj_size)
{
	void *obj;

	GCSTAT_TRIGGER(obj_size);
	sml_heap_gc();

	HEAP_FAST_ALLOC(obj, obj_size, NULL);

	if (obj == NULL) {
#ifdef GCSTAT
		stat_notice("---");
		stat_notice("event: error");
		stat_notice("heap exceeded: intented to allocate %lu bytes.",
			  (unsigned long)obj_size);
		if (gcstat.file)
			fclose(gcstat.file);
#endif /* GCSTAT */
		sml_fatal(0, "heap exceeded: intended to allocate %lu bytes.",
			  (unsigned long)obj_size);
	}
	return obj;
}
