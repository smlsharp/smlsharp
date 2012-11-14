/*
 * heap_reppy.c
 * @copyright (c) 2010, Tohoku University.
 * @author OTOMO Toshiaki
 * @author UENO Katsuhiro
 *
 * An implementation of generational copying GC described in
 * J. H. Reppy.
 * A high-performance garbage collector for Standard ML.
 * Technical report, AT&T Bell Laboratories Technical Memo, 1994.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#if 0
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */
#if defined(HAVE_CONFIG_H) && defined(HAVE_SYS_MMAN_H)
#include <sys/mman.h>
#endif /* HAVE_SYS_MMAN_H */
#endif
#include <sys/mman.h>
#include "smlsharp.h"
#include "object.h"
#include "objspace.h"
#include "heap.h"

/*#define GCTIME*/

#ifdef GCSTAT
#define GCTIME
#endif /* GCSTAT */

#ifndef NUM_GENERATIONS
#define NUM_GENERATIONS 5
#endif /* NUM_GENERATIONS */

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
		unsigned long total_promote_count;
	} gc;
	struct gcstat_gc minor_gc[NUM_GENERATIONS];
	struct {
		unsigned int trigger;
		unsigned int alloc_count;
		struct {
			unsigned int called;
			unsigned int barriered;
			unsigned int already_barriered;
		} barrier_count;
		unsigned int forward_count;
		unsigned int copy_count;
		unsigned int promote_count;
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
	if (gcstat.last.barrier_count.called > 0
	    || gcstat.last.barrier_count.barriered > 0) {
		stat_notice(" barrier: {called: %u, barriered: %u, already: %u}",
			    gcstat.last.barrier_count.called,
			    gcstat.last.barrier_count.barriered,
			    gcstat.last.barrier_count.already_barriered
			);
	}
}
#endif /* GCSTAT */
#endif /* GCSTAT || GCTIME */

#ifdef GCSTAT
#define GCSTAT_PROMOTE_COUNT()  (gcstat.last.promote_count++)
#define GCSTAT_FORWARD_COUNT()  (gcstat.last.forward_count++)
#define GCSTAT_COPY_COUNT(size) \
	(gcstat.last.copy_count++, gcstat.last.copy_bytes += (size))
#define GCSTAT_TRIGGER(size)  (gcstat.last.trigger = (size))
#else
#define GCSTAT_PROMOTE_COUNT()
#define GCSTAT_FORWARD_COUNT()
#define GCSTAT_COPY_COUNT(size)
#define GCSTAT_TRIGGER(size)
#endif /* GCSTAT */

struct heap_all_space {
	char *base;
	char *end;
	size_t all_size;
	size_t each_size;
};
extern struct heap_all_space sml_heap_space;

/*
 * Heap Space Layout:
 *
 *   INITIAL_OFFSET
 *    <-->
 *   +----+------+--------------------------+------------+------+
 *   |    |      |                          |            |      |
 *   +----+------+--------------------------+------------+------+
 *   ^    ^      ^     ^                    ^            ^      ^
 *   base |      |    free                limit         top   end
 *        |   water_mark(start address of free.)
 *        start address of free(init).
 */

#define DEFAULT_REMEMBERSIZE (4 * 1024)
struct heap_space {
	char *free;
	char *limit;
	char *water_mark;
	void ***top;
	char *base;
	char *end;
};
extern struct heap_space sml_heap_from_space[NUM_GENERATIONS];

/*
 * Allocation:
 *
 * heap_space.free always points to the free space for the next object.
 * inc must be aligned in MAXALIGN, i.e., rounded by HEAP_ROUND_SIZE.
 *
 * h : size of object header
 * size : total object size intended to be allocated.
 * inc = HEAP_ROUND_SIZE(size)
 *
 *         |<---------------- inc ----------------->|
 *         |                                        |
 *         |     |<----------------- inc ---------------->|
 *         |     |                                  |     |
 *         |<------------ size ------------>|       |     |
 *         |     |                          |       |     |
 *         |<-h->|                          |       |<-h->|
 *         |     |                          |       |     |
 *         |  MAXALIGN                      |       |  MAXALIGN
 *   HEAP        v                                        v
 *    -----+-----+--------------------------+-------+-----+----------
 *         |head1|           obj1           |       |     |
 *    -----+-----+--------------------------+-------+-----+----------
 *               ^                                        ^
 *              prev                                     new
 *              free                                     free
 */

/* For each object, its size must be enough to hold one forwarded pointer. */
#define HEAP_ALLOC_SIZE_MIN      (OBJ_HEADER_SIZE + sizeof(void*))
#ifdef FAIR_COMPARISON
#define HEAP_ROUND_SIZE(sz) \
	ALIGNSIZE(sz, ALIGNSIZE(HEAP_ALLOC_SIZE_MIN, 8))
#else
#define HEAP_ROUND_SIZE(sz) \
	ALIGNSIZE(sz, ALIGNSIZE(HEAP_ALLOC_SIZE_MIN, MAXALIGN))
#endif /* FAIR_COMPARISON */

#define INITIAL_OFFSET  ALIGNSIZE(OBJ_HEADER_SIZE, MAXALIGN)

#define REMEMBER_FLAG OBJ_GC2_MASK
#define OBJ_REMEMBERED OBJ_GC2

#define GC_FORWARDED_FLAG     OBJ_GC1_MASK
#define OBJ_FORWARDED         OBJ_GC1
#define OBJ_FORWARD_PTR(obj)  (*(void**)(obj))

#define IS_IN_SML_HEAP_SPACE(ptr) \
	(sml_heap_space.base <= (char*)(ptr) \
	 && (char*)(ptr) < sml_heap_space.end)
#define IS_IN_HEAP_SPACE(heap_space, ptr) \
	((heap_space).base <= (char*)(ptr) \
	 && (char*)(ptr) < (heap_space).limit)
#define HOW_OLD(ptr) \
	((size_t)((char*)(ptr) - sml_heap_space.base) \
	 / sml_heap_space.each_size)

#ifdef DEBUG
int how_old(void *ptr)
{
	return HOW_OLD(ptr);
}
#endif /* DEBUG */

#ifdef DEBUG
static void
heap_space_protect(struct heap_space *heap)
{
	mprotect(heap->base, heap->end - heap->base, 0);
}

static void
heap_space_unprotect(struct heap_space *heap)
{
	mprotect(heap->base, heap->end - heap->base, PROT_READ | PROT_WRITE);
}
#else
#define heap_space_protect(heap)  ((void)0)
#define heap_space_unprotect(heap)  ((void)0)
#endif /* DEBUG */

int search_rememberset(struct heap_space *heap,void**write)
{
	void ***p;
	for(p=heap->top + 1;(char*)p<heap->end;p++)
		if(*p == write) return 1;
	return 0;
}

#define REMEMBERSET_PUSH(h,p) do{		   \
		if((char*)((h).top) > (h).limit) { \
			*((h).top) = (p); \
			(h).top = (h).top - 1;\
		} else sml_fatal(0,"rememberset is over");	\
	}while(0)

struct heap_all_space sml_heap_space = {0,0,0,0};
struct heap_space sml_heap_from_space[NUM_GENERATIONS];
static struct heap_space sml_heap_to_space[NUM_GENERATIONS];
static size_t gc_level = 0;

/* thread-local information */
struct sml_heap_thread {
	int dummy;
};

#define HEAP_START(h)  ((h).base + INITIAL_OFFSET)
#define HEAP_USED(h)   ((size_t)((h).free - (h).base))
#define HEAP_REST(h)   ((size_t)((h).limit - (h).free))
#define HEAP_TOTAL(h)  ((size_t)((h).limit - HEAP_START((h))))
#define HEAP_OLDER_OBJ(h) ((size_t)((h).water_mark - (h).base))

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
	unsigned int i;

	if (gcstat.verbose < GCSTAT_VERBOSE_HEAP)
		return;

	stat_notice("heap:");
	for(i=0;i<NUM_GENERATIONS;i++) {
		count = heap_filled(sml_heap_from_space + i, &filled);
		stat_notice(" %u from:",i);
		stat_notice("  - {filled: %lu, count: %lu, used: %lu}",
			    (unsigned long)filled, (unsigned long)count,
			    (unsigned long)HEAP_USED(sml_heap_from_space[i]));
		count = heap_filled(sml_heap_to_space + i, &filled);
		stat_notice(" %u to:",i);
		stat_notice("  - {filled: %lu, count: %lu, used: %lu}",
			    (unsigned long)filled, (unsigned long)count,
			    (unsigned long)HEAP_USED(sml_heap_to_space[i]));
	}
}
#endif /* GCSTAT */

static void
heap_space_alloc(size_t size)
{
	size_t pagesize = getpagesize();
	size_t allocsize;
	void *page;
	
	allocsize = (size / NUM_GENERATIONS) / 2;
	allocsize = ALIGNSIZE(allocsize,pagesize);
	allocsize = allocsize * 2 * NUM_GENERATIONS;
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

	sml_heap_space.base = page;
	sml_heap_space.end = (char*)page + allocsize;
	sml_heap_space.all_size = allocsize;
	sml_heap_space.each_size = 
		sml_heap_space.all_size / NUM_GENERATIONS;
}

static void
heap_space_clear(struct heap_space *heap)
{
	heap->free = heap->base + INITIAL_OFFSET;
	heap->top = (void***)(heap->end - sizeof(void **));	
	heap->water_mark = heap->free; 
	
	ASSERT(heap->free < heap->limit);
	ASSERT(heap->limit <= (char*)heap->top);
#ifdef DEBUG
	memset(heap->base, 0x55, heap->end - heap->base);
#endif
}

static void
heap_space_init(struct heap_space *heap, size_t size, char *base, size_t rememberset_size)
{
	heap->base = base;
	heap->end = (char*)heap->base + size;
	heap->limit = (char*)heap->end - rememberset_size;
	heap_space_clear(heap);
}

void
sml_heap_init(size_t size, size_t maxsize ATTR_UNUSED)
{
	int i;
	char *next_heap;
	size_t each_heap_size;
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

	char*s;
	long n;
	size_t rememberset_size = DEFAULT_REMEMBERSIZE;
	s = getenv("SMLSHARP_REMEMBERSIZE");
	if (s) {
		n = strtol(s, NULL, 10);
		if (n > 0)
			rememberset_size = n;
	}
	rememberset_size = ALIGNSIZE(rememberset_size,sizeof(void**));

	if(size < ((INITIAL_OFFSET + rememberset_size) * NUM_GENERATIONS * 2))
		space_size = INITIAL_OFFSET * NUM_GENERATIONS * 2;
	else space_size = size;

	heap_space_alloc(space_size);	
	each_heap_size = sml_heap_space.each_size / 2;
	next_heap = sml_heap_space.base;
	for(i=0;i<NUM_GENERATIONS;i++) {
		heap_space_init(&sml_heap_from_space[i],
				each_heap_size,next_heap,rememberset_size);
		next_heap += each_heap_size;

		heap_space_unprotect(&sml_heap_from_space[i]);

		heap_space_init(&sml_heap_to_space[i],
				each_heap_size,next_heap,rememberset_size);
		next_heap += each_heap_size;
		
		heap_space_protect(&sml_heap_to_space[i]);
	}
	sml_heap_from_space[NUM_GENERATIONS-1].limit = 
		sml_heap_from_space[NUM_GENERATIONS-1].end - sizeof(void**);
	sml_heap_to_space[NUM_GENERATIONS-1].limit = 
		sml_heap_to_space[NUM_GENERATIONS-1].end - sizeof(void**);
	
#ifdef GCSTAT
	stat_notice("---");
	stat_notice("event: init");
	stat_notice("time: 0.0");
	stat_notice("heap_size: %lu", (unsigned long)space_size);
	stat_notice("config:");
	for(i=0; i<NUM_GENERATIONS; i++) {
		stat_notice(" %u from: {size: %lu}",i,
			    (unsigned long)HEAP_TOTAL(sml_heap_from_space[i]));
		stat_notice(" %u to: {size: %lu}",i,
			    (unsigned long)HEAP_TOTAL(sml_heap_to_space[i]));
	}
	stat_notice("counters:");
	stat_notice(" heap: [alloc]");
	print_heap_occupancy();
#endif /* GCSTAT */
}

static void
heap_space_swap(int i)
{
	struct heap_space tmp_space;

	tmp_space = sml_heap_from_space[i];
	sml_heap_from_space[i] = sml_heap_to_space[i];
	sml_heap_to_space[i] = tmp_space;
}

static void
heap_space_free()
{
#ifdef DEBUG
	munmap(sml_heap_space.base, sml_heap_space.end - sml_heap_space.base);
#else
	free(sml_heap_space.base);
#endif
}

/* for debug */
#if 0
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
#endif
void
sml_heap_free()
{
	heap_space_free();

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
	unsigned int i;
	for(i=0;i<NUM_GENERATIONS;i++) {
		sml_time_accum(gcstat.minor_gc[i].total_time,
			       gcstat.gc.total_time);
		gcstat.gc.count += gcstat.minor_gc[i].count;
	}
	stat_notice("exec time      : "TIMEFMT" #sec",
		    TIMEARG(gcstat.exec_time));
	stat_notice("gc count       : %u #times", gcstat.gc.count);
	stat_notice("gc time        : "TIMEFMT" #sec (%4.2f%%), avg: %.6f sec",
		    TIMEARG(gcstat.gc.total_time),
		    TIMEFLOAT(gcstat.gc.total_time)
		    / TIMEFLOAT(gcstat.exec_time) * 100.0f,
		    TIMEFLOAT(gcstat.gc.total_time)
		    / (double)gcstat.gc.count);
	for(i=0;i<NUM_GENERATIONS;i++) {
		stat_notice("%u count       : %u #times",i, gcstat.minor_gc[i].count);
		stat_notice("%u time        : "TIMEFMT" #sec (%4.2f%%), avg: %.6f sec",i,
			    TIMEARG(gcstat.minor_gc[i].total_time),
			    TIMEFLOAT(gcstat.minor_gc[i].total_time)
			    / TIMEFLOAT(gcstat.exec_time) * 100.0f,
			    TIMEFLOAT(gcstat.minor_gc[i].total_time)
			    / (double)gcstat.minor_gc[i].count);
	}
#ifdef GCSTAT
	stat_notice("total copy bytes    :%10lu #bytes, avg:%8.2f bytes",
		    gcstat.gc.total_copy_bytes,
		    (double)gcstat.gc.total_copy_bytes
		    / (double)gcstat.gc.count);
	stat_notice("total forward count :%10lu #times, avg:%8.2f times",
		    gcstat.gc.total_forward_count,
		    (double)gcstat.gc.total_forward_count
		    / (double)gcstat.gc.count);
	stat_notice("total promote count :%10lu #times, avg:%8.2f times",
		    gcstat.gc.total_promote_count,
		    (double)gcstat.gc.total_promote_count
		    / (double)gcstat.gc.count);
	if (gcstat.file)
		fclose(gcstat.file);
#endif /* GCSTAT */
#endif /* GCSTAT || GCTIME */
}

void *
sml_heap_thread_init()
{
	struct sml_heap_thread *th = xmalloc(sizeof(struct sml_heap_thread));
	th->dummy = 0;
	return th;
}

void
sml_heap_thread_free(void *p ATTR_UNUSED)
{
	free(p);
}

SML_PRIMITIVE void
sml_write(void *objaddr, void **writeaddr, void *new_value)
{
	unsigned int slot_age, obj_age;
#ifdef GCSTAT
	gcstat.last.barrier_count.called++;
#endif /* GCSTAT */

	*writeaddr = new_value;

	if(IS_IN_SML_HEAP_SPACE(writeaddr)) {
		if (IS_IN_SML_HEAP_SPACE(*writeaddr)) {
			slot_age = HOW_OLD(writeaddr);
			obj_age = HOW_OLD(*writeaddr);
			ASSERT(IS_IN_HEAP_SPACE(sml_heap_from_space[slot_age],writeaddr));
			ASSERT(IS_IN_HEAP_SPACE(sml_heap_from_space[obj_age],*writeaddr));
			if(slot_age > obj_age) {
				if(search_rememberset(sml_heap_from_space + obj_age,writeaddr) == 0) {
#ifdef GCSTAT
					gcstat.last.barrier_count.barriered++;
#endif /* GCSTAT */
					REMEMBERSET_PUSH(sml_heap_from_space[obj_age],writeaddr);	
					ASSERT(search_rememberset(sml_heap_from_space + obj_age,writeaddr));
				}
#ifdef GCSTAT
				else gcstat.last.barrier_count.already_barriered++;
#endif /* GCSTAT */
			}
		}
	} else
		sml_global_barrier(writeaddr, objaddr);
}

#if 0
static int
obj_forwarded(void *obj)
{
	return IS_IN_SML_HEAP_SPACE(obj)
		&& OBJ_FORWARDED(obj);
}
#endif /* 0 */

static void
forward(void **slot)
{
	void *obj = *slot;
	size_t obj_size, alloc_size;
	unsigned int obj_age;
	void *newobj;

	if (!IS_IN_SML_HEAP_SPACE(obj)) {
		DBG(("%p at %p outside", obj, slot));
		if (obj != NULL)
		    sml_trace_ptr(obj);
		return;
	}

	obj_age = HOW_OLD(obj);
	if(obj_age > gc_level) return;

	if (OBJ_FORWARDED(obj)) {
		*slot = OBJ_FORWARD_PTR(obj);
		GCSTAT_FORWARD_COUNT();
		DBG(("%p at %p forward -> %p", obj, slot, *slot));
		return;
	}
	
	obj_size = OBJ_TOTAL_SIZE(obj);
	alloc_size = HEAP_ROUND_SIZE(obj_size);
	ASSERT(IS_IN_HEAP_SPACE(sml_heap_from_space[obj_age],obj));
	
	ASSERT(sml_heap_to_space[obj_age].free >=
	       (sml_heap_to_space[obj_age].base + INITIAL_OFFSET));
			
	if(((char*)obj < sml_heap_from_space[obj_age].water_mark) &&
	   (obj_age < (NUM_GENERATIONS - 1))){
		if((obj_age+1) > gc_level) {
			ASSERT(HEAP_REST(sml_heap_from_space[obj_age+1]) 
			       >= alloc_size);
			newobj = sml_heap_from_space[obj_age+1].free;
			sml_heap_from_space[obj_age+1].free += alloc_size;
			GCSTAT_PROMOTE_COUNT();
		} else {
			newobj = sml_heap_to_space[obj_age+1].free;
			if((size_t)(sml_heap_to_space[obj_age+1].limit 
				    - (char*)newobj) < alloc_size) {
				ASSERT(HEAP_REST(sml_heap_to_space[obj_age]) 
				       >= alloc_size);
				newobj = sml_heap_to_space[obj_age].free;
				sml_heap_to_space[obj_age].free += alloc_size;
			} else {
				sml_heap_to_space[obj_age+1].free += alloc_size;
				GCSTAT_PROMOTE_COUNT();
			}
		}
	} else {
		if(HEAP_REST(sml_heap_to_space[obj_age]) < alloc_size)
			sml_fatal(0,"heap is over");
		newobj = sml_heap_to_space[obj_age].free;
		sml_heap_to_space[obj_age].free += alloc_size;
	}
	
	memcpy(&OBJ_HEADER(newobj), &OBJ_HEADER(obj), obj_size);
	/*size_t count;
	char tmp;
	for(count=0;count<=obj_size;count++) {
		tmp = *((char*)&OBJ_HEADER(obj)+count);
		*((char*)&OBJ_HEADER(newobj)+count)= tmp;
		}*/
	
	GCSTAT_COPY_COUNT(obj_size);

	DBG(("%p at %p copy -> %p (%lu/%lu)",
	     obj, slot, newobj,
	     (unsigned long)obj_size, (unsigned long)alloc_size));

	OBJ_HEADER(obj) |= GC_FORWARDED_FLAG;
	OBJ_FORWARD_PTR(obj) = newobj;
	*slot = newobj;
}

#define forward_children(obj)  sml_obj_enum_ptr(obj, forward)

#if 0
/* toDo */
static void
forward_region(void *start,unsigned int age)
{
	char *cur = start;

	DBG(("%p - %p", start, sml_heap_to_space[age].free));

	while ((char*)cur < sml_heap_to_space[age].free) {
		forward_children(cur);
		cur += HEAP_ROUND_SIZE(OBJ_TOTAL_SIZE(cur));
	}
}

/* toDo */
static void
forward_deep(void **slot, void *data ATTR_UNUSED)
{
	int i;
	for(i=gc_level;i>=0;i--){
		void *cur = sml_heap_to_space[i].free;
		forward(slot);
		forward_region(cur,i);
	}
}

static const sml_trace_cls forward_deep_fn = forward_deep;
#define forward_deep_cls ((sml_trace_cls*)&forward_deep_fn)
#endif /* 0 */

static void
forward2(void **slot)
{
	unsigned int slot_age,obj_age;
	forward(slot);
	
	slot_age = HOW_OLD(slot);
	obj_age = HOW_OLD(*slot);
	
	if(slot_age > obj_age)       
		REMEMBERSET_PUSH(sml_heap_to_space[obj_age],slot);
}

#define forward_children2(obj)  sml_obj_enum_ptr(obj, forward2)

static void nop(void **x ATTR_UNUSED)
{
	/* no operation */
}

static void
do_gc(enum sml_gc_mode mode)
{
	int i;
	void ***trace;
	unsigned int slot_age,obj_age;
	char *scan_start[NUM_GENERATIONS];
#ifdef GCTIME
	sml_timer_t b_start, b_end;
	sml_time_t gctime;
#endif /* GCTIME */
#ifdef GCSTAT
	sml_time_t t;
#endif /* GCSTAT */

	STOP_THE_WORLD();

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
	sml_timer_now(b_start);
#endif /* GCTIME */
/*
	DBG(("start gc (%lu/%lu used) %p -> %p",
	     (unsigned long)HEAP_USED(sml_heap_from_space),
	     (unsigned long)HEAP_TOTAL(sml_heap_from_space),
	     sml_heap_from_space.base, sml_heap_to_space.base));
*/

	if(mode == MINOR) {
		heap_space_unprotect(&sml_heap_to_space[0]);
		gc_level = 0;
		while((gc_level < (NUM_GENERATIONS-1)) && 
		      (HEAP_REST(sml_heap_from_space[gc_level+1]) <=
		       HEAP_OLDER_OBJ(sml_heap_from_space[gc_level]))) {
			heap_space_unprotect(sml_heap_to_space + gc_level + 1);
			gc_level++;
		}

		if(gc_level < NUM_GENERATIONS-1)
			scan_start[gc_level+1] = sml_heap_from_space[gc_level+1].free;
	} else {
		gc_level = NUM_GENERATIONS-1;
#ifdef DEBUG
		for(i=0;i<NUM_GENERATIONS;i++)
			heap_space_unprotect(sml_heap_to_space + i);
#endif /* DEBUG */
	}

#ifdef GCTIME
	gcstat.minor_gc[gc_level].count++;
	sml_timer_now(b_start);
#endif /* GCTIME */

	/* scan remembered-set */
	for(i=(gc_level<=NUM_GENERATIONS-2)?gc_level:NUM_GENERATIONS-2;i>=0;i--){
		trace = (void***)sml_heap_from_space[i].end - 1;
		while((char*)trace > (char*)sml_heap_from_space[i].top) {
			slot_age = HOW_OLD(*trace);
			if((slot_age > gc_level) && (HOW_OLD(**trace) == i)){
				forward(*trace);
				obj_age = HOW_OLD(**trace);
				if(i != obj_age) {
					ASSERT(obj_age == i+1);
					if(obj_age <= gc_level)
						REMEMBERSET_PUSH(
							sml_heap_to_space[obj_age],
							*trace);
					else {
						if((obj_age < NUM_GENERATIONS -1) &&
						   (search_rememberset(sml_heap_from_space + obj_age,*trace) == 0)) {
							REMEMBERSET_PUSH(sml_heap_from_space[obj_age],*trace);
							ASSERT(search_rememberset(sml_heap_from_space + obj_age,*trace));
						}
					}
				} else 
					REMEMBERSET_PUSH(sml_heap_to_space[i],*trace);
			}			
			trace--;
		}
	}

	/* All pointer slots must be updated even if this is minor GC */
	sml_rootset_enum_ptr(forward, MAJOR);
	if (gc_level < NUM_GENERATIONS - 1) {
		/* ignore remembered malloc objects but visit all pointers
		 * in all malloc objects. */
		sml_malloc_pop_and_mark(nop, MINOR);
		sml_malloc_enum_ptr(forward);
	}

	DBG(("copying root completed"));
	char *cur;
	
	/* forward objects which are reachable from live objects. */
	unsigned int finish = 1;
	
	for(i=0;i<=gc_level;i++)
		scan_start[i] = HEAP_START(sml_heap_to_space[i]);
	
	do{
		finish = 1;
		/* 
		   promoteしたことによってgcの対象となっていないfrom領域に移動するobjがある．
		   それらをscanする．
		*/
		if(gc_level < NUM_GENERATIONS -1) {
			if(scan_start[gc_level+1] != sml_heap_from_space[gc_level+1].free) {
				cur = scan_start[gc_level+1];
				while ((char*)cur < sml_heap_from_space[gc_level+1].free) {
					forward_children2(cur);
					cur += HEAP_ROUND_SIZE(OBJ_TOTAL_SIZE(cur));
				}
				finish = 0;
				scan_start[gc_level+1] = sml_heap_from_space[gc_level+1].free;
			}
		}
		for(i=gc_level;i>=0;i--){
			if(scan_start[i] != sml_heap_to_space[i].free) {
				cur = scan_start[i];
				while ((char*)cur < sml_heap_to_space[i].free) {
					forward_children2(cur);
					cur += HEAP_ROUND_SIZE(OBJ_TOTAL_SIZE(cur));
				}				
				finish = 0;
				scan_start[i] = sml_heap_to_space[i].free;
			}
		}		
		finish &= !sml_malloc_pop_and_mark(forward, gc_level < NUM_GENERATIONS - 1 ? MINOR : MAJOR);
	}while(finish == 0);

#ifndef FAIR_COMPARISON
	/* check finalization */ //toDo
	//sml_check_finalizer(MAJOR, obj_forwarded, forward_deep_cls);
#endif /* FAIR_COMPARISON */
	
	/* clear from-space, and swap two spaces. */
	for(i=0;i<=gc_level;i++) {
		heap_space_clear(&sml_heap_from_space[i]);
		heap_space_swap(i);
		heap_space_protect(sml_heap_to_space + i);
	}

#ifdef DEBUG
	if(gc_level < (NUM_GENERATIONS - 1)) {
		heap_space_protect(sml_heap_to_space + gc_level + 1);
	}
#endif /* DEBUG */
	for(i=0;i<=(gc_level+1);i++)
		sml_heap_from_space[i].water_mark = sml_heap_from_space[i].free;
	
	/* sweep malloc heap */
	if(gc_level == (NUM_GENERATIONS - 1))
		sml_malloc_sweep(MAJOR);

	DBG(("gc finished. remain %lu bytes",
	     (unsigned long)HEAP_USED(sml_heap_from_space[0])));

#ifdef GCTIME
	sml_timer_now(b_end);
#endif /* GCTIME */
	RUN_THE_WORLD();

#ifdef GCTIME
	sml_timer_dif(b_start, b_end, gctime);
	sml_time_accum(gctime, gcstat.minor_gc[gc_level].total_time);
#endif /* GCTIME */
#ifdef GCSTAT
	gcstat.gc.total_copy_bytes += gcstat.last.copy_bytes;
	gcstat.gc.total_copy_count += gcstat.last.copy_count;
	gcstat.gc.total_forward_count += gcstat.last.forward_count;
	gcstat.gc.total_promote_count += gcstat.last.promote_count;
	if (gcstat.verbose >= GCSTAT_VERBOSE_GC) {
		sml_timer_dif(gcstat.exec_begin, b_start, t);
		stat_notice("time: "TIMEFMT, TIMEARG(t));
		stat_notice("---");
		stat_notice("event: end gc");
		stat_notice("gc_level: %u",gc_level);
		sml_timer_dif(gcstat.exec_begin, b_end, t);
		stat_notice("time: "TIMEFMT, TIMEARG(t));
		stat_notice("duration: "TIMEFMT, TIMEARG(gctime));
		stat_notice("copy: %u", gcstat.last.copy_count);
		stat_notice("forward: %u", gcstat.last.forward_count);
		stat_notice("copy_bytes: %lu",
			    (unsigned long)gcstat.last.copy_bytes);
		stat_notice("promote: %u", gcstat.last.forward_count);
		print_heap_occupancy();
	}
#endif /* GCSTAT */

#ifndef FAIR_COMPARISON
	/* start finalizers */
	//sml_run_finalizer();
#endif /* FAIR_COMPARISON */
}


void
sml_heap_gc(void)
{
	do_gc(MAJOR);
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

#if 0
void 
heap_print(int flag)
{
	size_t i;
	
	if(flag == 0) 
		fprintf(stderr,"\n initial \n");
	else if(flag == 0) fprintf(stderr,"\n before gc\n");
	else fprintf(stderr,"\n after gc\n");
	
	fprintf(stderr,"\n*****************************\n");
	fprintf(stderr,"sml_heap_space base=%p, end=%p, all_size=%u, each_heap_size=%u\n",
		sml_heap_space.base,sml_heap_space.end,
		sml_heap_space.all_size,sml_heap_space.each_size);
	for(i=0;i<NUM_GENERATIONS;i++) {
		fprintf(stderr,"sml_heap_from_space[%u] base=%p, end=%p\n\tfree=%p, limit=%p, water_mark=%p, top=%p\n",
			i,sml_heap_from_space[i].base,sml_heap_from_space[i].end,
			sml_heap_from_space[i].free,sml_heap_from_space[i].limit,
			sml_heap_from_space[i].water_mark,sml_heap_from_space[i].top);
		fprintf(stderr,"sml_heap_to_space[%u] base=%p, end=%p\n\tfree=%p, limit=%p, water_mark=%p, top=%p\n",
			i,sml_heap_to_space[i].base,sml_heap_to_space[i].end,
			sml_heap_to_space[i].free,sml_heap_to_space[i].limit,
			sml_heap_to_space[i].water_mark,sml_heap_to_space[i].top);
	}
	fprintf(stderr,"\n*****************************\n");
}
#endif

static NOINLINE void *
slow_alloc(size_t obj_size)
{
	void *obj;

	GCSTAT_TRIGGER(obj_size);

	do_gc(MINOR);

	if (HEAP_REST(sml_heap_from_space[0]) >= obj_size) {
		obj = sml_heap_from_space[0].free;
		sml_heap_from_space[0].free += obj_size;
#ifdef GC_STAT
		sml_heap_alloced(obj_size);
#endif /* GC_STAT */
	} else {
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

	GIANT_UNLOCK();
	return obj;
}

SML_PRIMITIVE void *
sml_alloc(unsigned int objsize, void *frame_pointer)
{
	/* objsize = payload_size + bitmap_size */
	void *obj;
	size_t inc = HEAP_ROUND_SIZE(OBJ_HEADER_SIZE + objsize);

#ifdef FAIR_COMPARISON
	if (inc > 4096) {
		sml_save_frame_pointer(frame_pointer);
		return sml_obj_malloc(inc);
	}
#endif /* FAIR_COMPARISON */

	GIANT_LOCK(frame_pointer);

	obj = sml_heap_from_space[0].free;
	if ((size_t)(sml_heap_from_space[0].limit - (char*)obj) >= inc) {
		sml_heap_from_space[0].free += inc;
#ifdef GC_STAT
		sml_heap_alloced(inc);
#endif /* GC_STAT */
		GIANT_UNLOCK();
	} else {
		sml_save_frame_pointer(frame_pointer);
		obj = slow_alloc(inc);
	}

#ifndef FAIR_COMPARISON
	OBJ_HEADER(obj) = 0;
#endif /* FAIR_COMPARISON */
	return obj;
}
