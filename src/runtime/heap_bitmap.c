/*
 * heap_bitmap.c
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 * @author Yudai Asai
 * @version $Id: $
 */

#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>
#ifdef MULTITHREAD
#include <pthread.h>
#endif /* MULTITHREAD */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

#if !defined(HAVE_CONFIG_H) || defined(HAVE_SYS_MMAN_H)
#include <sys/mman.h>
#endif /* HAVE_SYS_MMAN_H */
#ifdef MINGW32
#include <windows.h>
#undef OBJ_BITMAP
#endif /* MINGW32 */

#include "smlsharp.h"
#include "object.h"
#include "objspace.h"
#include "heap.h"

/*#define SURVIVAL_CHECK*/
/*#define GCSTAT*/
/*#define GCTIME*/
/*#define NULL_IS_NOT_ZERO*/
/*#define MINOR_GC*/
/*#define CONFIGURABLE_MINOR_COUNT*/
/*#define DEBUG_USE_MMAP */

#ifdef MULTITHREAD
/* ToDo: generational collection with multithread support is not confirmed. */
#undef MINOR_GC
#endif /* MULTITHREAD */

#ifdef GCSTAT
#define GCTIME
#endif /* GCSTAT */

#if defined GCSTAT || defined GCTIME
#include <stdarg.h>
#include <stdio.h>
#include "timer.h"
#endif /* GCSTAT || GCTIME */

/* bit pointer */
struct bitptr {
	unsigned int *ptr;
	unsigned int mask;
};
typedef struct bitptr bitptr_t;

#define BITPTR_WORDBITS  ((unsigned int)(sizeof(unsigned int) * CHAR_BIT))

#define BITPTR_INIT(b,p,n) \
	((b).ptr = (p) + (n) / BITPTR_WORDBITS, \
	 (b).mask = 1 << ((n) % BITPTR_WORDBITS))
#define BITPTR_TEST(b)  (*(b).ptr & (b).mask)
#define BITPTR_SET(b)   (*(b).ptr |= (b).mask)
#define BITPTR_CLEAR(b) (*(b).ptr &= ~(b).mask)
#define BITPTR_WORD(b)  (*(b).ptr)
#define BITPTR_WORDINDEX(b,p)  ((b).ptr - (p))
#define BITPTR_EQUAL(b1,b2) \
	((b1).ptr == (b2).ptr && (b1).mask == (b2).mask)

/* BITPTR_NEXT: find 0 bit in current word after and including
 * pointed bit. */
#define BITPTR_NEXT(b) do {				 \
	unsigned int tmp__ = *(b).ptr | ((b).mask - 1U); \
	(b).mask = (tmp__ + 1U) & ~tmp__;		 \
} while (0)
#define BITPTR_NEXT_FAILED(b)  ((b).mask == 0)

#define BITPTR_NEXT2(b,dst) do {				 \
	unsigned int tmp__ = *(b).ptr | ((b).mask - 1U); \
	dst = (tmp__ + 1U) & ~tmp__;		 \
} while (0)

static NOINLINE bitptr_t
bitptr_linear_search(unsigned int *start, const unsigned int *limit)
{
	bitptr_t b = {start, 0};
	while (b.ptr < limit) {
		b.mask = (*b.ptr + 1) & ~*b.ptr;
		if (b.mask) break;
		b.ptr++;
	}
	return b;
}

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define BITPTR_INC(b) do {						\
	unsigned int tmp__;						\
	__asm__ ("xorl\t%0, %0\n\t"					\
		 "roll\t%1\n\t"						\
		 "rcll\t%0"						\
		 : "=&r" (tmp__), "+r" ((b).mask));			\
	(b).ptr += tmp__;						\
} while (0)
#else
#define BITPTR_INC(b) \
	(((b).mask <<= 1) ? (void)0 : (void)((b).mask = 1, (b).ptr++))
#endif /* !NOASM */

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define bsr(x) ({							\
	unsigned int tmp__;						\
	ASSERT((x) > 0);						\
	__asm__ ("bsrl\t%1, %0" : "=r" (tmp__) : "r" ((unsigned int)(x))); \
	tmp__;								\
})
#define bsf(x) ({							\
	unsigned int tmp__;						\
	ASSERT((x) > 0);						\
	__asm__ ("bsfl\t%1, %0" : "=r" (tmp__) : "r" ((unsigned int)(x))); \
	tmp__;								\
})
#elif defined(SIZEOF_INT) && (SIZEOF_INT == 4)
static inline unsigned int
bsr(unsigned int m)
{
	unsigned int x, n = 0;
	ASSERT(m > 0);
	x = m >> 16; if (x != 0) n += 16, m = x;
	x = m >> 8; if (x != 0) n += 8, m = x;
	x = m >> 4; if (x != 0) n += 4, m = x;
	x = m >> 2; if (x != 0) n += 2, m = x;
	return n + (m >> 1);
}
static inline unsigned int
bsf(unsigned int m)
{
	unsigned int x, n = 31;
	ASSERT(m > 0);
	x = m << 16; if (x != 0) n -= 16, m = x;
	x = m << 8; if (x != 0) n -= 8, m = x;
	x = m << 4; if (x != 0) n -= 4, m = x;
	x = m << 2; if (x != 0) n -= 2, m = x;
	x = m << 1; if (x != 0) n -= 1;
	return n;
}
#else
static inline unsigned int
bsr(unsigned int m)
{
	unsigned int x, n = 0, c = BITPTR_WORDBITS / 2;
	ASSERT(m > 0);
	do {
		x = m >> c; if (x != 0) n += c, m = x;
		c >>= 1;
	} while (c > 1);
	return n + (m >> 1);
}
static inline unsigned int
bsf(unsigned int m)
{
	unsigned int x, n = 31, c = BITPTR_WORDBITS / 2;
	ASSERT(m > 0);
	do {
		x = m << c; if (x != 0) n -= c, m = x;
		c >>= 1;
	} while (c > 0);
	return n;
}
#endif /* NOASM */

/* BITPTR_INDEX: bit index of 'b' counting from first bit of 'base'. */
#define BITPTR_INDEX(b,p) \
	(((b).ptr - (p)) * BITPTR_WORDBITS + bsf((b).mask))

#define CEIL_LOG2(x) \
	(bsr((x) - 1) + 1)

/* segments */

#ifndef SEGMENT_SIZE_LOG2
#define SEGMENT_SIZE_LOG2  17   /* 128k */
#endif /* SEGMENT_SIZE_LOG2 */
#define SEGMENT_SIZE (1U << SEGMENT_SIZE_LOG2)
#ifndef SEG_RANK
#define SEG_RANK  3
#endif /* SEG_RANK */

#define BLOCKSIZE_MIN_LOG2  3U   /* 2^3 = 8 */
#define BLOCKSIZE_MIN       (1U << BLOCKSIZE_MIN_LOG2)
#define BLOCKSIZE_MAX_LOG2  12U  /* 2^4 = 16 */
#define BLOCKSIZE_MAX       (1U << BLOCKSIZE_MAX_LOG2)

#ifdef MINOR_GC
#ifndef DEFAULT_MINOR_THRESHOLD_RATIO
#define DEFAULT_MINOR_THRESHOLD_RATIO  0.5
#endif /* MINOR_THRESHOLD_RATIO */
static double minor_threshold_ratio = DEFAULT_MINOR_THRESHOLD_RATIO;
#ifdef CONFIGURABLE_MINOR_COUNT
#define MINOR_COUNT minor_count
static unsigned int minor_count = 0;
#else
#ifndef MINOR_COUNT
#define MINOR_COUNT  0  /* must be a positive number. 0 means infinity */
#endif /* MINOR_COUNT */
#endif /* CONFIGURABLE_MINOR_COUNT */
#endif /* MINOR_GC */

struct segment_layout {
	size_t blocksize;
	size_t bitmap_offset[SEG_RANK];
	size_t bitmap_limit[SEG_RANK];
	unsigned int bitmap_sentinel[SEG_RANK];
	size_t bitmap_size;
	size_t stack_offset;
	size_t stack_limit;
	size_t block_offset;
	size_t num_blocks;
#ifdef MINOR_GC
	size_t minor_threshold;
#endif /* MINOR_GC */
};

struct segment {
	struct segment *next;
	unsigned int live_count;
	struct stack_slot { void *next_obj; } *stack;
	char *block_base;
	const struct segment_layout *layout;
	unsigned int blocksize_log2;
};

/*
 * segment layout:
 *
 * 00000 +--------------------------+
 *       | struct segment           |
 *       +--------------------------+ SEG_BITMAP_BASE0 (aligned in MAXALIGN)
 *       | bitmap(0)                | ^
 *       :                          : | about N bits + sentinel
 *       |                          | V
 *       +--------------------------+ SEG_BITMAP_BASE1
 *       | bitmap(1)                | ^
 *       :                          : | about N/32 bits + sentinel
 *       |                          | V
 *       +--------------------------+ SEG_BITMAP_BASE2
 *       :                          :
 *       +--------------------------+ SEG_BITMAP_BASEn
 *       | bitmap(n)                | about N/32^n bits + sentinel
 *       |                          |
 *       +--------------------------+ SEG_STACK_BASE
 *       | stack area               | ^
 *       |                          | | N pointers
 *       |                          | v
 *       +--------------------------+ SEG_BLOCK_BASE (aligned in MAXALIGN)
 *       | obj block area           | ^
 *       |                          | | N blocks
 *       |                          | v
 *       +--------------------------+
 *       :                          :
 * 80000 +--------------------------+
 *
 * N-th bit of bitmap(0) indicates whether N-th block is used (1) or not (0).
 * N-th bit of bitmap(n) indicates whether N-th word of bitmap(n-1) is
 * filled (1) or not (0).
 */

#define CEIL(x,y)         ((((x) + (y) - 1) / (y)) * (y))
#define BITS_TO_WORDS(n)  (((n) + BITPTR_WORDBITS - 1) / BITPTR_WORDBITS)
#define WORDS_TO_BITS(n)  ((n) * BITPTR_WORDBITS)
#define WORDS_TO_BYTES(n) ((n) * sizeof(unsigned int))

#define SEG_INITIAL_OFFSET CEIL(sizeof(struct segment), MAXALIGN)
#define SEG_BITMAP0_OFFSET SEG_INITIAL_OFFSET

static struct segment_layout segment_layout[BLOCKSIZE_MAX_LOG2 + 1];

#ifdef DEBUG
static void
dump_layout()
{
	unsigned int i, j;
	const struct segment_layout *l;
	unsigned long total;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		l = &segment_layout[i];
		total = l->block_offset + l->num_blocks * l->blocksize;
		sml_notice("---");
		sml_notice("blocksize: %lu", (unsigned long)l->blocksize);
		sml_notice("bitmap0 offset: %lu",
			   (unsigned long)SEG_BITMAP0_OFFSET);
		for (j = 0; j < SEG_RANK; j++) {
			sml_notice("bitmap%u limit: %lu",
				   j, (unsigned long)l->bitmap_limit[j]);
			sml_notice("bitmap%u sentinel: %08x",
			       j, l->bitmap_sentinel[j]);
		}
		sml_notice("bitmap size: %lu", (unsigned long)l->bitmap_size);
		sml_notice("stack offset: %lu", (unsigned long)l->stack_offset);
		sml_notice("stack limit: %lu", (unsigned long)l->stack_limit);
		sml_notice("block offset: %lu", (unsigned long)l->block_offset);
		sml_notice("num blocks: %lu", (unsigned long)l->num_blocks);
		sml_notice("total size: %lu", total);
	}
}
#endif /* DEBUG */

static void
calc_layout(unsigned int blocksize_log2)
{
	struct segment_layout *layout;
	unsigned int num_blocks, i;
	double estimate_bits;

	layout = &segment_layout[blocksize_log2];
	layout->blocksize = 1 << blocksize_log2;

	estimate_bits = 1.0;
	for (i = 0; i < SEG_RANK; i++)
		estimate_bits = 1.0 + estimate_bits / (double)BITPTR_WORDBITS;

	num_blocks = (double)(SEGMENT_SIZE - SEG_INITIAL_OFFSET)
		/ (layout->blocksize + estimate_bits / CHAR_BIT
		   + sizeof(struct stack_slot));

	for (;;) {
		unsigned int filled, bitmap_start, num_bits, stack_size, i;
		unsigned int bitmap_words, sentinel_bits;
		filled = SEG_BITMAP0_OFFSET;
		bitmap_start = filled;
		num_bits = num_blocks;
		sentinel_bits = 1;
		for (i = 0; i < SEG_RANK; i++) {
			layout->bitmap_offset[i] = filled;
			bitmap_words = BITS_TO_WORDS(num_bits + sentinel_bits);
			sentinel_bits = WORDS_TO_BITS(bitmap_words) - num_bits;
			layout->bitmap_sentinel[i] =
				~0U << (BITPTR_WORDBITS - sentinel_bits);
			filled += WORDS_TO_BYTES(bitmap_words);
			layout->bitmap_limit[i] = filled;
			num_bits = BITS_TO_WORDS(num_bits);
			sentinel_bits = 1 + sentinel_bits / BITPTR_WORDBITS;
		}
		/* aligning bitmap_size in MAXALIGN makes memset faster.
		 * It is safe since stack area is bigger than MAXALIGN
		 * and memset never reach both object header and
		 * content. */
		layout->bitmap_size = CEIL(filled - bitmap_start, MAXALIGN);
		filled = CEIL(filled, sizeof(struct stack_slot));
		layout->stack_offset = filled;
		stack_size = num_blocks * sizeof(struct stack_slot);
		layout->stack_limit = filled + stack_size;
		filled += stack_size;
		filled = CEIL(filled + OBJ_HEADER_SIZE, MAXALIGN);
		layout->block_offset = filled;
		filled += num_blocks * layout->blocksize;

		ASSERT(bitmap_start + layout->bitmap_size
		       < layout->block_offset - OBJ_HEADER_SIZE);

		if (filled <= SEGMENT_SIZE)
			break;
		num_blocks--;
	}
	layout->num_blocks = num_blocks;

#ifdef MINOR_GC
	layout->minor_threshold =
		(double)layout->num_blocks * minor_threshold_ratio;
#endif /* MINOR_GC */
}

static void
init_segment_layout()
{
	unsigned int i;

	/* segment_layout[0] is used for fresh segments. */
	segment_layout[0].blocksize = 0;
	for (i = 0; i < SEG_RANK; i++) {
		segment_layout[0].bitmap_offset[i] = SEG_BITMAP0_OFFSET;
		segment_layout[0].bitmap_limit[i] = SEGMENT_SIZE;
		segment_layout[0].bitmap_sentinel[i] = 0;
	}
	segment_layout[0].bitmap_size = SEGMENT_SIZE - SEG_BITMAP0_OFFSET;
	segment_layout[0].stack_offset = SEGMENT_SIZE;
	segment_layout[0].stack_limit = SEGMENT_SIZE;
	segment_layout[0].block_offset = SEGMENT_SIZE;
	segment_layout[0].num_blocks = 0;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++)
		calc_layout(i);
#ifdef DEBUG
	dump_layout();
#endif /* DEBUG */
}

#define ADD_OFFSET(p,n)  ((void*)((char*)(p) + (n)))

#define BITMAP0_BASE(seg) \
	((unsigned int*)ADD_OFFSET(seg, SEG_BITMAP0_OFFSET))
#define BITMAP_BASE(seg, level) \
	((unsigned int*) \
	 ADD_OFFSET(seg, (seg)->layout->bitmap_offset[level]))
#define BITMAP_LIMIT_3(seg, layout, level) \
	((unsigned int*)ADD_OFFSET(seg, (layout)->bitmap_limit[level]))
#define BITMAP_LIMIT(seg, level) \
	BITMAP_LIMIT_3(seg, (seg)->layout, level)
#define BITMAP_SENTINEL(seg, level) \
	((seg)->layout->bitmap_sentinel[level])
#define BLOCK_BASE(seg)  ((seg)->block_base)
#define BLOCK_SIZE(seg)  (1U << (seg)->blocksize_log2)

/* sub heaps */
struct subheap {
	struct segment *seglist;      /* list of segments */
	struct segment **unreserved;  /* head of unreserved segs on seglist */
#ifdef MINOR_GC
	unsigned int minor_count;
	struct segment **minor_space; /* head of minor space on seglist */
#endif /* MINOR_GC */
};

/* allocation pointers */
/*
 * Since allocation pointers are frequently accessed,
 * they should be small so that they can stay in cache as long as possible.
 * And, in order for fast offset computation, sizeof(struct alloc_ptr)
 * should be power of 2.
 */
struct alloc_ptr {
	bitptr_t freebit;
	char *free;
	unsigned int blocksize_bytes;
};

union alloc_ptr_set {
	struct alloc_ptr alloc_ptr[BLOCKSIZE_MAX_LOG2 + 1];
#ifdef MULTITHREAD
	/* alloc_ptr[0] is not used. We use there as a pointer member. */
	union alloc_ptr_set *next;
#endif /* MULTITHREAD */
};

static const unsigned int dummy_bitmap = ~0U;
static const bitptr_t dummy_bitptr = { (unsigned int *)&dummy_bitmap, 1 };

#ifdef MULTITHREAD
static union alloc_ptr_set *global_free_ptr_list;
#ifdef THREAD_LOCAL_STORAGE
static __thread union alloc_ptr_set *current_alloc_ptr_set;
#define ALLOC_PTR_SET() current_alloc_ptr_set
#else
#define ALLOC_PTR_SET() ((union alloc_ptr_set *)sml_current_thread_heap())
#endif /* THREAD_LOCAL_STORAGE */
#else
static union alloc_ptr_set global_alloc_ptr_set;
#define ALLOC_PTR_SET() (&global_alloc_ptr_set)
#endif /* MULTITHREAD */

struct subheap global_subheaps[BLOCKSIZE_MAX_LOG2 + 1];

static struct {
	struct segment *freelist;
	void *begin, *end;
	unsigned int min_num_segments, max_num_segments, num_committed;
	unsigned int extend_step;
	unsigned int *bitmap;
} heap_space;

#define IS_IN_HEAP(p) \
	((char*)heap_space.begin <= (char*)(p) \
		 && (char*)(p) < (char*)heap_space.end)

#define ALLOC_PTR_TO_BLOCKSIZE_LOG2(ptr)				\
	(ASSERT								\
	 (BLOCKSIZE_MIN_LOG2 <=						\
	  (unsigned)((ptr) - &ALLOC_PTR_SET()->alloc_ptr[0])		\
	  && (unsigned)((ptr) - &ALLOC_PTR_SET()->alloc_ptr[0])		\
	  <= BLOCKSIZE_MAX_LOG2),					\
	 (unsigned)((ptr) - &ALLOC_PTR_SET()->alloc_ptr[0]))

/* bit pointer is suitable for computing segment address.
 * bit pointer always points to the address in the middle of segments. */
#define ALLOC_PTR_TO_SEGMENT(ptr)					\
	(ASSERT(IS_IN_HEAP((ptr)->freebit.ptr)),			\
	 ((struct segment*)                                             \
	  ((uintptr_t)((ptr)->freebit.ptr) & ~((uintptr_t)SEGMENT_SIZE - 1U))))

#define OBJ_TO_SEGMENT(objaddr) \
	(ASSERT(IS_IN_HEAP(objaddr)), \
	 (struct segment*) \
	 ((uintptr_t)(objaddr) & ~((uintptr_t)SEGMENT_SIZE - 1U)))

#define OBJ_TO_INDEX(seg, objaddr)					\
	(ASSERT(OBJ_TO_SEGMENT(objaddr) == (seg)),			\
	 ASSERT((char*)(objaddr) >= (seg)->block_base),			\
	 ASSERT((char*)(objaddr)					\
		< (seg)->block_base + ((seg)->layout->num_blocks	\
				       << (seg)->blocksize_log2)),	\
	 ((size_t)((char*)(objaddr) - (seg)->block_base)		\
	  >> (seg)->blocksize_log2))

/* for debug */
struct segment *obj_to_segment(void *obj) {return OBJ_TO_SEGMENT(obj);}
size_t obj_to_index(void *obj) {
	struct segment *seg = OBJ_TO_SEGMENT(obj);
	return OBJ_TO_INDEX(seg, obj);
}
unsigned int obj_to_bit(void *obj) {
	struct segment *seg = OBJ_TO_SEGMENT(obj);
	size_t index = OBJ_TO_INDEX(seg, obj);
	bitptr_t b;
	BITPTR_INIT(b, BITMAP0_BASE(seg), index);
	return BITPTR_TEST(b);
}
struct stack_slot *obj_to_stack(void *obj) {
	struct segment *seg = OBJ_TO_SEGMENT(obj);
	size_t index = OBJ_TO_INDEX(seg, obj);
	return seg->stack + index;
}

#ifdef MULTITHREAD
static pthread_mutex_t free_ptr_list_lock = PTHREAD_MUTEX_INITIALIZER;
#define PUSH_FREE_PTR_LIST(ptr) do { \
	pthread_mutex_lock(&free_ptr_list_lock); \
	ptr->next = global_free_ptr_list; \
	global_free_ptr_list = ptr; \
	pthread_mutex_unlock(&free_ptr_list_lock); \
} while (0)
#define POP_FREE_PTR_LIST(ptr) do { \
	pthread_mutex_lock(&free_ptr_list_lock); \
	ptr = global_free_ptr_list; \
	if (ptr) global_free_ptr_list = ptr->next; \
	pthread_mutex_unlock(&free_ptr_list_lock); \
} while (0)
#define CLEAR_FREE_PTR_LIST(ptr) do { \
	pthread_mutex_lock(&free_ptr_list_lock); \
	ptr = global_free_ptr_list; \
	global_free_ptr_list = NULL; \
	pthread_mutex_unlock(&free_ptr_list_lock); \
} while (0)
#endif /* MULTITHREAD */

#ifdef MULTITHREAD
#if 0 && defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
/* this seems buggy... */
#define FREELIST_NEXT(freelist, seg) do { \
	struct segment *new__ ATTR_UNUSED; \
	__asm__ volatile ("movl %0, %1\n" \
			  "1:\n\t" \
			  "testl %1, %1\n\t" \
			  "je 1f\n\t" \
			  "movl (%1), %2\n\t" \
			  "lock; cmpxchgl %2, %0\n\t" \
			  "jne 1b\n" \
			  "1:" \
			  : "+m" (freelist), "=&a" (seg), "=&r" (new__) \
			  :: "memory"); \
} while (0)
#define UNRESERVED_NEXT(unreserved, seg) do { \
	__asm__ volatile ("movl %0, %%eax\n" \
			  "1:\n\t" \
			  "movl (%%eax), %1\n\t" \
			  "testl %1, %1\n\t" \
			  "je 1f\n\t" \
			  "lock; cmpxchgl %1, %0\n\t" \
			  "jne 1b\n" \
			  "1:" \
			  : "+m" (unreserved), "=&r" (seg) \
			  :: "eax", "memory"); \
} while (0)
#define UNRESERVED_APPEND(unreserved, seg) do { \
	struct segment *next__ ATTR_UNUSED; \
	__asm__ volatile ("1:\n\t" \
			  "movl %0, %%eax\n\t" \
			  "movl (%%eax), %1\n\t" \
			  "testl %1, %1\n\t" \
			  "je 2f\n\t" \
			  "lock; cmpxchgl %1, %0\n\t" \
			  "jmp 1b\n" \
			  "2:\n\t" \
			  "movl %%eax, %1\n\t" \
			  "xorl %%eax, %%eax\n\t" \
			  "lock; cmpxchgl %2, (%1)\n\t" \
			  "jne 1b\n\t" \
			  "movl %1, %%eax\n\t" \
			  "lock; cmpxchgl %2, %0" \
			  : "+m" (unreserved), "=&r" (next__) \
			  : "r" (seg) : "eax", "memory"); \
} while (0)
#else
static pthread_mutex_t heap_space_lock = PTHREAD_MUTEX_INITIALIZER;
#define FREELIST_NEXT(freelist, seg) do { \
	pthread_mutex_lock(&heap_space_lock); \
	seg = freelist;	\
	if (seg) freelist = seg->next; \
	pthread_mutex_unlock(&heap_space_lock); \
} while (0)
#define UNRESERVED_NEXT(unreserved, seg) do { \
	pthread_mutex_lock(&heap_space_lock); \
	seg = *unreserved; \
	if (seg) unreserved = &seg->next; \
	pthread_mutex_unlock(&heap_space_lock); \
} while (0)
#define UNRESERVED_APPEND(unreserved, seg) do { \
	pthread_mutex_lock(&heap_space_lock); \
	*unreserved = seg; \
	unreserved = &seg->next; \
	pthread_mutex_unlock(&heap_space_lock); \
} while (0)
#endif /* !NOASM */
#else /* MULTITHREAD */
#define UNRESERVED_NEXT(unreserved, seg) do { \
	seg = *unreserved; \
	if (seg) unreserved = &seg->next; \
} while (0)
#define FREELIST_NEXT(freelist, seg) do { \
	seg = freelist;	\
	if (seg) freelist = seg->next; \
} while (0)
#define UNRESERVED_APPEND(unreserved, seg) do { \
	*unreserved = seg; \
	unreserved = &seg->next; \
} while (0)
#endif /* MULTITHREAD */

#if defined GCSTAT || defined GCTIME
static struct {
	FILE *file;
	size_t probe_threshold;
	unsigned int verbose;
	unsigned int initial_num_segments;
	sml_timer_t exec_begin, exec_end;
	sml_time_t exec_time;
	struct gcstat_gc {
		unsigned int count;
		sml_time_t total_time;
		sml_time_t clear_time;
		unsigned long total_clear_bytes;
		unsigned long total_trace_count;
		unsigned long total_push_count;
	} gc;
#ifdef MINOR_GC
	struct gcstat_gc minor_gc;
#endif /* MINOR_GC */
	unsigned long total_alloc_count;
	double max_wait_time;
	double last_probe_time;
	double probe_interval;
	struct {
		unsigned int trigger;
		struct {
			unsigned int fast[BLOCKSIZE_MAX_LOG2 + 1];
			unsigned int next[BLOCKSIZE_MAX_LOG2 + 1];
			unsigned int find[BLOCKSIZE_MAX_LOG2 + 1];
			unsigned int new[BLOCKSIZE_MAX_LOG2 + 1];
			unsigned int malloc;
		} alloc_count;
#ifdef MINOR_GC
		struct {
			unsigned int called;
			unsigned int barriered;
		} barrier_count;
#endif /* MINOR_GC */
		unsigned int trace_count;
		unsigned int push_count;
		size_t alloc_bytes;
		size_t clear_bytes;
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

#if defined GCSTAT
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
	unsigned int i;

	if (gcstat.verbose < GCSTAT_VERBOSE_COUNT)
		return;

	stat_notice("count:");
	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		if (gcstat.last.alloc_count.fast[i] != 0
		    || gcstat.last.alloc_count.next[i] != 0
		    || gcstat.last.alloc_count.find[i] != 0
		    || gcstat.last.alloc_count.new[i] != 0)
			stat_notice(" %u: {fast: %u, next: %u, find: %u,"
				    " new: %u}",
				    1U << i,
				    gcstat.last.alloc_count.fast[i],
				    gcstat.last.alloc_count.next[i],
				    gcstat.last.alloc_count.find[i],
				    gcstat.last.alloc_count.new[i]);
	}
	if (gcstat.last.alloc_count.malloc > 0)
		stat_notice(" other: {malloc: %u}",
			    gcstat.last.alloc_count.malloc);
#ifdef MINOR_GC
	if (gcstat.last.barrier_count.called > 0
	    || gcstat.last.barrier_count.barriered > 0) {
		stat_notice(" barrier: {called: %u, barriered: %u}",
			    gcstat.last.barrier_count.called,
			    gcstat.last.barrier_count.barriered);
	}
#endif /* MINOR_GC */
}
#endif /* GCSTAT */
#endif /* GCSTAT || GCTIME */


/* for debug or GCSTAT */
static size_t
segment_filled(struct segment *seg, size_t filled_index, size_t *ret_bytes)
{
	unsigned int i;
	bitptr_t b;
	char *p = BLOCK_BASE(seg);
	size_t filled = 0, count = 0;
	const size_t blocksize = BLOCK_SIZE(seg);

	BITPTR_INIT(b, BITMAP0_BASE(seg), 0);
	for (i = 0; i < seg->layout->num_blocks; i++) {
		if (i < filled_index || BITPTR_TEST(b)) {
			ASSERT(OBJ_TOTAL_SIZE(p) <= blocksize);
			count++;
			filled += OBJ_TOTAL_SIZE(p);
		}
		BITPTR_INC(b);
		p += blocksize;
	}

	if (ret_bytes)
		*ret_bytes = filled;
	return count;
}

#ifdef DEBUG
static void
scribble_segment(struct segment *seg, size_t filled_index)
{
	unsigned int i;
	bitptr_t b;
	char *p = BLOCK_BASE(seg);

	BITPTR_INIT(b, BITMAP0_BASE(seg), 0);
	for (i = 0; i < seg->layout->num_blocks; i++) {
		size_t objsize = ((i < filled_index || BITPTR_TEST(b))
				  ? OBJ_TOTAL_SIZE(p) : 0);
		memset(p - OBJ_HEADER_SIZE + objsize, 0x55,
		       BLOCK_SIZE(seg) - objsize);
		BITPTR_INC(b);
		p += BLOCK_SIZE(seg);
	}
}

static void
scribble_subheaps()
{
	unsigned int i;
	struct segment *seg;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		for (seg = global_subheaps[i].seglist; seg; seg = seg->next)
			/* assume that bitmaps exactly indicate
			 * the liveness of blocks. */
			scribble_segment(seg, 0);
	}
}

static size_t
check_segment_consistent(struct segment *seg, size_t filled_index)
{
	bitptr_t b;
	unsigned int i, *p;
	size_t index, count, filled;
	const struct segment_layout *layout;

	ASSERT(BLOCKSIZE_MIN_LOG2 <= seg->blocksize_log2
	       && seg->blocksize_log2 <= BLOCKSIZE_MAX_LOG2);

	/* check alignment */
	ASSERT((uintptr_t)seg & ~((uintptr_t)SEGMENT_SIZE - 1U));

	/* check layout */
	layout = &segment_layout[seg->blocksize_log2];
	ASSERT(seg->layout == layout);
	ASSERT(seg->stack == ADD_OFFSET(seg, layout->stack_offset));
	ASSERT(seg->block_base == ADD_OFFSET(seg, layout->block_offset));

	/* stack area must be filled with NULL. */
	for (i = 0; i < layout->num_blocks; i++)
		ASSERT(seg->stack[i].next_obj == NULL);

	/* check sentinel bits */
	index = layout->num_blocks;
	BITPTR_INIT(b, BITMAP0_BASE(seg), index);
	ASSERT(BITPTR_TEST(b));
	BITPTR_NEXT(b);
	ASSERT(BITPTR_NEXT_FAILED(b));

	for (i = 1; i < SEG_RANK; i++) {
		index = index / BITPTR_WORDBITS + 1;
		BITPTR_INIT(b, BITMAP_BASE(seg, i), index);
		ASSERT(BITPTR_TEST(b));
		BITPTR_NEXT(b);
		ASSERT(BITPTR_NEXT_FAILED(b));
	}

	/* check bitmap tree */
	for (i = 0; i < SEG_RANK - 1; i++) {
		for (p = BITMAP_BASE(seg,i); p < BITMAP_LIMIT(seg,i); p++) {
			BITPTR_INIT(b, BITMAP_BASE(seg, i + 1),
				    p - BITMAP_BASE(seg, i));
			ASSERT((*p == ~0U) == (BITPTR_TEST(b) != 0));
		}
	}

	/* check all objecst are valid. */
	count = segment_filled(seg, filled_index, &filled);
	ASSERT(count <= layout->num_blocks);
	ASSERT(filled <= (layout->num_blocks << seg->blocksize_log2));

	/* check live_count */
	ASSERT(count == seg->live_count);

	return count;
}

static void
check_ptr_consistent(struct alloc_ptr *ptr)
{
	size_t index;
	unsigned int i;
	struct segment *seg, *s;

	/* if freebit is equal to dummy, ptr points no segment. */
	ASSERT((!ptr->free && BITPTR_EQUAL(ptr->freebit, dummy_bitptr))
	       || (ptr->free && !BITPTR_EQUAL(ptr->freebit, dummy_bitptr)));
	if (ptr->free == NULL)
		return;
	seg = ALLOC_PTR_TO_SEGMENT(ptr);
	i = seg->blocksize_log2;

	/* block size must be equal between ptr and segment. */
	ASSERT(ptr->blocksize_bytes == 1 << i);

	/* segment is in seglist of the subheap. */
	for (s = global_subheaps[i].seglist; s; s = s->next)
		if (s == seg)
			break;
	ASSERT(s == seg);

	/* free pointer boundary check */
	ASSERT(BLOCK_BASE(seg) <= ptr->free
	       && ptr->free < (BLOCK_BASE(seg) +
			       (seg->layout->num_blocks << i)));
	ASSERT(BITMAP0_BASE(seg) <= ptr->freebit.ptr
	       && ptr->freebit.ptr < BITMAP_LIMIT(seg, 0));

	/* correspondence between free and freebit */
	index = BITPTR_INDEX(ptr->freebit, BITMAP0_BASE(seg));
	ASSERT(index == OBJ_TO_INDEX(seg, ptr->free));
}

static void
check_subheap_consistent(struct subheap *subheap, unsigned int blocksize_log2)
{
	struct segment *seg, *s, **p;
	size_t count;
	int num_segments, unreserved_start;
#ifdef MINOR_GC
	int minor_start;
#endif /* MINOR_GC */

	/* check subheap->unreserved consistent */
	num_segments = 0;
	unreserved_start = -1;
	for (p = &subheap->seglist; *p; p = &(*p)->next) {
		if (p == subheap->unreserved) {
			ASSERT(unreserved_start == -1);
			unreserved_start = num_segments;
		}
		num_segments++;
	}
	if (subheap->unreserved == p)
		unreserved_start = num_segments;
	ASSERT(unreserved_start >= 0);

#ifdef MINOR_GC
	/* check subheap->minor_space consistent */
	num_segments = 0;
	minor_start = -1;
	for (p = &subheap->seglist; *p; p = &(*p)->next) {
		if (p == subheap->minor_space) {
			ASSERT(minor_start == -1);
			minor_start = num_segments;
		}
		num_segments++;
	}
	if (subheap->minor_space == p)
		minor_start = num_segments;
	ASSERT(minor_start >= 0 && minor_start <= unreserved_start);
#if defined CONFIGURABLE_MINOR_COUNT || MINOR_COUNT > 0
	ASSERT(subheap->minor_count <= MINOR_COUNT);
#endif /* MINOR_COUNT */
#endif /* MINOR_GC */

	/* check each segment consistent */
	for (seg = subheap->seglist; seg; seg = seg->next) {
		ASSERT(seg->blocksize_log2 == blocksize_log2);
		/* assume that bitmaps exactly indicate
		 * the liveness of blocks. */
		count = check_segment_consistent(seg, 0);
		/*count = check_segment_consistent(seg, SEGMENT_SIZE);*/
		/*ASSERT(!reserved || count == seg->layout->num_blocks);*/

		/* seg is not in the free list. */
		for (s = heap_space.freelist; s; s = s->next)
			ASSERT(s != seg);
	}
}

static void
check_heap_consistent()
{
	unsigned int i;
	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		check_subheap_consistent(&global_subheaps[i], i);
		check_ptr_consistent(&ALLOC_PTR_SET()->alloc_ptr[i]);
	}
}
#endif /* DEBUG */

#ifdef GCSTAT
struct occupancy_accum {
	unsigned int total_objects;
	unsigned int total_object_bytes;
	unsigned int total_blocks;
	unsigned int total_block_bytes;
};

static void
print_segment_occupancy(struct segment *seg, size_t filled_index,
			struct subheap *subheap, struct occupancy_accum *a)
{
	size_t count, filled;

	count = segment_filled(seg, filled_index, &filled);
	stat_notice("  - {bytes: %lu, blocks: %lu}%s",
		    (unsigned long)filled,
		    (unsigned long)count,
		    (&seg->next == subheap->unreserved) ? " # ^^^"
#ifdef MINOR_GC
		    : (seg == *subheap->minor_space) ? " # ---"
#endif /* MINOR_GC */
		    : "");
	a->total_objects += count;
	a->total_object_bytes += filled;
	a->total_blocks += seg->layout->num_blocks;
	a->total_block_bytes += count << seg->blocksize_log2;
}

static void
print_subheap_occupancy(struct subheap *subheap, unsigned int blocksize_log2,
			struct occupancy_accum *a)
{
	struct segment *seg;
#ifdef MINOR_GC
	size_t filled = SEGMENT_SIZE;
#else
	size_t filled = 0;
#endif /* MINOR_GC */

	filled = SEGMENT_SIZE;
	for (seg = subheap->seglist; seg; seg = seg->next) {
#ifdef MINOR_GC
		if (seg == *subheap->minor_space)
			filled = SEGMENT_SIZE;
#endif /* MINOR_GC */
		if (seg == *subheap->unreserved)
			filled = 0;
		else if (&seg->next == subheap->unreserved) {
			struct alloc_ptr *ptr;
			ptr = &ALLOC_PTR_SET()->alloc_ptr[blocksize_log2];
			filled = BITPTR_INDEX(ptr->freebit, BITMAP0_BASE(seg));
		}
		print_segment_occupancy(seg, filled, subheap, a);
	}
}

static void
print_heap_occupancy()
{
	unsigned int i;
	struct subheap *subheap;
	struct occupancy_accum a = {0, 0, 0, 0};

	if (gcstat.verbose < GCSTAT_VERBOSE_HEAP)
		return;

	stat_notice("heap:");
	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		subheap = &global_subheaps[i];

		if (subheap->seglist) {
			stat_notice(" %u:", 1U << i);
			print_subheap_occupancy(subheap, i, &a);
		}
	}

	stat_notice("  # using %u / %u blocks, %u / %u / %u bytes, occ %.2f %%",
		    a.total_objects, a.total_blocks,
		    a.total_object_bytes, a.total_block_bytes,
		    heap_space.num_committed * SEGMENT_SIZE,
		    (double)a.total_object_bytes
		    / ((double)heap_space.num_committed * SEGMENT_SIZE)
		    * 100.0);
}
#endif /* GCSTAT */

/* for debug */
static void
dump_segment_list(struct segment *seg, struct segment *cur)
{
	size_t filled, count;

	while (seg) {
		count = segment_filled(seg, 0, &filled);
		sml_debug("  segment %p:%s\n",
			  seg, seg == cur ? " UNRESERVED" : "");
		sml_debug("    blocksize = %u, "
			  "%lu blocks, %lu blocks used, %lu bytes filled\n",
			  BLOCK_SIZE(seg),
			  (unsigned long)seg->layout->num_blocks,
			  (unsigned long)count, (unsigned long)filled);
		seg = seg->next;
	}
}

/* for debug */
void
sml_heap_dump()
{
	unsigned int i;
	struct subheap *subheap;
	struct alloc_ptr *ptr;
	struct segment *seg;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		subheap = &global_subheaps[i];
		ptr = &ALLOC_PTR_SET()->alloc_ptr[i];

		if (BITPTR_EQUAL(ptr->freebit, dummy_bitptr)) {
			sml_debug("ptr[%u] (%u): dummy bitptr\n",
				  i, ptr->blocksize_bytes);
		} else {
			seg = ALLOC_PTR_TO_SEGMENT(ptr);
			sml_debug("ptr[%u] (%u): free=%p, bit %u\n",
				  i, ptr->blocksize_bytes, ptr->free,
				  BITPTR_INDEX(ptr->freebit,
					       BITMAP0_BASE(seg)));
		}
		sml_debug(" segments:\n");
		dump_segment_list(subheap->seglist, *subheap->unreserved);
	}

	sml_debug("freelist:\n");
	dump_segment_list(heap_space.freelist, NULL);
}

static void
set_alloc_ptr(struct alloc_ptr *ptr, struct segment *seg)
{
	if (seg) {
		ptr->free = BLOCK_BASE(seg);
		BITPTR_INIT(ptr->freebit, BITMAP0_BASE(seg), 0);
	} else {
		ptr->free = NULL;
		ptr->freebit = dummy_bitptr;
	}
}

static void
clear_bitmap(struct segment *seg)
{
	unsigned int i;

#ifdef DEBUG
	for (i = seg->layout->bitmap_limit[SEG_RANK - 1];
	     i < SEG_BITMAP0_OFFSET + seg->layout->bitmap_size;
	     i++)
		ASSERT(*(unsigned char*)ADD_OFFSET(seg, i) == 0);
#endif /* DEBUG */

	memset(BITMAP0_BASE(seg), 0, seg->layout->bitmap_size);
#ifdef GCSTAT
	gcstat.last.clear_bytes += seg->layout->bitmap_size;
#endif /* GCSTAT */

	for (i = 0; i < SEG_RANK; i++)
		BITMAP_LIMIT(seg, i)[-1] = BITMAP_SENTINEL(seg, i);
	seg->live_count = 0;
}

static void
clear_all_bitmaps()
{
	unsigned int i;
	struct segment *seg;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		for (seg = global_subheaps[i].seglist; seg; seg = seg->next)
			clear_bitmap(seg);
	}
}

static void
init_segment(struct segment *seg, unsigned int blocksize_log2)
{
	const struct segment_layout *layout;
	unsigned int i;
	void *old_limit, *new_limit;

	ASSERT(BLOCKSIZE_MIN_LOG2 <= blocksize_log2
	       && blocksize_log2 <= BLOCKSIZE_MAX_LOG2);

	/* if seg is already initialized, do nothing. */
	if (seg->blocksize_log2 == blocksize_log2) {
		ASSERT(check_segment_consistent(seg, 0) == 0);
		return;
	}

	layout = &segment_layout[blocksize_log2];

	/*
	 * bitmap and stack area are cleared except bitmap sentinels.
	 * Under this assumption, we initialize bitmap and stack area
	 * with accessing least memory.
	 */
#if defined NULL_IS_NOT_ZERO
	old_limit = BITMAP_LIMIT(seg, SEG_RANK - 1);
	new_limit = BITMAP_LIMIT_L(seg, layout, SEG_RANK - 1);
#else
	old_limit = ADD_OFFSET(seg, seg->layout->stack_limit);
	new_limit = ADD_OFFSET(seg, layout->stack_limit);
#endif /* NULL_IS_NOT_ZERO */
	if ((char*)new_limit > (char*)old_limit)
		memset(old_limit, 0, (char*)new_limit - (char*)old_limit);

	/* clear old sentinel */
	for (i = 0; i < SEG_RANK; i++)
		BITMAP_LIMIT(seg, i)[-1] = 0;
	/* set new sentinel */
	for (i = 0; i < SEG_RANK; i++)
		BITMAP_LIMIT_3(seg,layout,i)[-1] = layout->bitmap_sentinel[i];

	seg->blocksize_log2 = blocksize_log2;
	seg->layout = layout;
	seg->stack = ADD_OFFSET(seg, layout->stack_offset);
	seg->block_base = ADD_OFFSET(seg, layout->block_offset);
	seg->next = NULL;

#ifdef NULL_IS_NOT_ZERO
	for (i = 0; i < layout->num_blocks; i++)
		seg->stack[i] = NULL;
#endif /* NULL_IS_NOT_ZERO */

	ASSERT(check_segment_consistent(seg, 0) == 0);
}

#ifdef MINGW32
#define GetPageSize()  (64 * 1024)
#define ReservePageError  NULL
#define ReservePage(addr, size)	\
	VirtualAlloc(addr, size, MEM_RESERVE, PAGE_NOACCESS)
#define ReleasePage(addr, size) \
	VirtualFree(addr, size, MEM_RELEASE)
#define CommitPage(addr, size) \
	VirtualAlloc(addr, size, MEM_COMMIT, PAGE_EXECUTE_READWRITE)
#define UncommitPage(addr, size) \
	VirtualFree(addr, size, MEM_DECOMMIT)
#else
#define GetPageSize()  getpagesize()
#define ReservePageError  ((void*)-1)
#define ReservePage(addr, size) \
	mmap(addr, size, PROT_NONE, MAP_ANON | MAP_PRIVATE, -1, 0)
#define ReleasePage(addr, size) \
	munmap(addr, size)
#define CommitPage(addr, size) \
	mprotect(addr, size, PROT_READ | PROT_WRITE)
#define UncommitPage(addr, size) \
	mmap(addr, size, PROT_NONE, MAP_ANON | MAP_PRIVATE | MAP_FIXED, -1, 0)
#endif /* MINGW32 */

#if defined(DEBUG) && defined(DEBUG_USE_MMAP)
#define HEAP_BEGIN_ADDR  (void*)0x2000000
#else
#define HEAP_BEGIN_ADDR  NULL
#endif /* DEBUG && DEBUG_USE_MMAP */

static void
extend_heap(unsigned int count)
{
	unsigned int i;
	struct segment *first, *seg, **seg_p;
	bitptr_t b;

	BITPTR_INIT(b, heap_space.bitmap, 0);
	seg = heap_space.begin;
	count = heap_space.min_num_segments;
	seg_p = &first;
	for (i = 0; count > 0 && i < heap_space.max_num_segments; i++) {
		if (!BITPTR_TEST(b)) {
			CommitPage(seg, SEGMENT_SIZE);
			seg->layout = &segment_layout[0];
			*seg_p = seg;
			seg_p = &seg->next;
			BITPTR_SET(b);
			count--;
			heap_space.num_committed++;
			DBG(("extend: %p (%d) %d", seg, i,
			     heap_space.num_committed));
		}
		BITPTR_INC(b);
		seg = (struct segment *)((char*)seg + SEGMENT_SIZE);
	}
	*seg_p = heap_space.freelist;
	heap_space.freelist = first;
}

static void
init_heap_space(size_t min_size, size_t max_size)
{
	size_t pagesize, alloc_size, reserve_size, freesize_pre, freesize_post;
	unsigned int min_num_segments, max_num_segments, bitmap_bits;
	void *p;

	pagesize = GetPageSize();

	if (SEGMENT_SIZE % pagesize != 0)
		sml_fatal(0, "SEGMENT_SIZE is not aligned in page size.");

	alloc_size = ALIGNSIZE(min_size, SEGMENT_SIZE);
	reserve_size = ALIGNSIZE(max_size, SEGMENT_SIZE);

	if (alloc_size < SEGMENT_SIZE)
		alloc_size = SEGMENT_SIZE;
	if (reserve_size < alloc_size)
		reserve_size = alloc_size;

	min_num_segments = alloc_size / SEGMENT_SIZE;
	max_num_segments = reserve_size / SEGMENT_SIZE;

	p = ReservePage(HEAP_BEGIN_ADDR, SEGMENT_SIZE + reserve_size);
	if (p == ReservePageError)
		sml_fatal(0, "failed to alloc virtual memory.");

	freesize_post = (uintptr_t)p & ((uintptr_t)SEGMENT_SIZE - 1);
	if (freesize_post == 0) {
		ReleasePage(p + reserve_size, SEGMENT_SIZE);
	} else {
		freesize_pre = SEGMENT_SIZE - freesize_post;
		ReleasePage(p, freesize_pre);
		p = (char*)p + freesize_pre;
		ReleasePage(p + reserve_size, freesize_post);
	}

	heap_space.begin = p;
	heap_space.end = (char*)p + reserve_size;
	heap_space.min_num_segments = min_num_segments;
	heap_space.max_num_segments = max_num_segments;
	heap_space.num_committed = 0;
	heap_space.extend_step = min_num_segments > 0 ? min_num_segments : 1;

	bitmap_bits = ALIGNSIZE(max_num_segments, BITPTR_WORDBITS);
	heap_space.bitmap = xmalloc(bitmap_bits / CHAR_BIT);
	memset(heap_space.bitmap, 0, bitmap_bits / CHAR_BIT);

	extend_heap(min_num_segments);

#ifdef GCSTAT
	gcstat.initial_num_segments = min_num_segments;
#endif /* GCSTAT */
}

static void
init_subheaps()
{
	unsigned int i;
	struct subheap *subheap;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		subheap = &global_subheaps[i];
		subheap->seglist = NULL;
		subheap->unreserved = &subheap->seglist;
#ifdef MINOR_GC
#if defined CONFIGURABLE_MINOR_COUNT || MINOR_COUNT > 0
		subheap->minor_count = MINOR_COUNT;
#endif /* MINOR_COUNT */
		subheap->minor_space = &subheap->seglist;
#endif /* MINOR_GC */
	}
}

static struct segment *
new_segment()
{
	struct segment *seg;

	FREELIST_NEXT(heap_space.freelist, seg);
	if (seg == NULL)
		return NULL;
	seg->next = NULL;
#ifdef DEBUG
	memset(ADD_OFFSET(seg, seg->layout->block_offset),
	       0x55, SEGMENT_SIZE - seg->layout->block_offset);
#endif /* DEBUG */
	return seg;
}

static void
free_segment(struct segment *seg)
{
	bitptr_t b;
	unsigned int index;

	index = ((char*)seg - (char*)heap_space.begin) / SEGMENT_SIZE;
	BITPTR_INIT(b, heap_space.bitmap, index);
	ASSERT(BITPTR_TEST(b));
	BITPTR_CLEAR(b);
	UncommitPage(seg, SEGMENT_SIZE);
	heap_space.num_committed--;
	DBG(("free_segment: %p (%d) %d\n", seg, index,
	     heap_space.num_committed));
}

static void
shrink_heap(unsigned int count)
{
	struct segment *seg;

	while (heap_space.num_committed > heap_space.min_num_segments
	       && count > 0) {
		seg = heap_space.freelist;
		if (seg == NULL)
			break;
		heap_space.freelist = seg->next;
		free_segment(seg);
		heap_space.num_committed--;
		count--;
	}
}

static void
init_alloc_ptr_set(union alloc_ptr_set *ptr_set)
{
	unsigned int i;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		ptr_set->alloc_ptr[i].blocksize_bytes = 1U << i;
		set_alloc_ptr(&ptr_set->alloc_ptr[i], NULL);
	}
#ifdef MULTITHREAD
	ptr_set->next = NULL;
#endif /* MULTITHREAD */
}

#ifdef MULTITHREAD
static union alloc_ptr_set *
new_alloc_ptr_set()
{
	union alloc_ptr_set *ptr_set;

	POP_FREE_PTR_LIST(ptr_set);
	if (ptr_set != NULL) {
		ptr_set->next = NULL;
		return ptr_set;
	}

	ptr_set = xmalloc(sizeof(union alloc_ptr_set));
	init_alloc_ptr_set(ptr_set);
	return ptr_set;
}

static void
free_alloc_ptr_set(union alloc_ptr_set *ptr_set)
{
	// ToDo:: LOCK
	ASSERT(ptr_set != NULL);
	PUSH_FREE_PTR_LIST(ptr_set);
}

static void
destroy_free_ptr_list()
{
	union alloc_ptr_set *freelist, *ptr_set;

	CLEAR_FREE_PTR_LIST(freelist);

	while (freelist) {
		ptr_set = freelist->next;
		free(freelist);
		freelist = ptr_set;
	}
}
#endif /* MULTITHREAD */

void
sml_heap_init(size_t min_size, size_t max_size)
{
#if defined GCSTAT || defined MINOR_GC
	const char *env;
#endif /* GCSTAT || MINOR_GC */
#ifdef GCSTAT
	unsigned int i;
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
		if (env[0] != '\0' && env[strlen(env)-1] == 's') {
			gcstat.probe_interval = strtod(env, NULL);
		} else {
			gcstat.probe_threshold = strtol(env, NULL, 10);
		}
		if (gcstat.probe_threshold == 0)
			gcstat.probe_threshold = min_size;
	} else {
		gcstat.probe_threshold = SEGMENT_SIZE * 4;
	}
#endif /* GCSTAT */
#ifdef MINOR_GC
	env = getenv("SMLSHARP_GC_FILLRATIO");
	if (env)
		minor_threshold_ratio = strtod(env, NULL);
#endif /* MINOR_GC */
#if defined MINOR_GC && defined CONFIGURABLE_MINOR_COUNT
	env = getenv("SMLSHARP_GC_MINORCOUNT");
	if (env) {
		if (env[0] != '\0' && env[strlen(env)-1] == '%') {
			minor_count = strtod(env, NULL) / 100.0
				* min_size / SEGMENT_SIZE;
		} else {
			minor_count = strtol(env, NULL, 10);
		}
	}
	stat_notice("minor_count : %u", minor_count);
#endif /* MINOR_GC && CONFIGURABLE_MINOR_COUNT */

#ifdef GCTIME
	sml_timer_now(gcstat.exec_begin);
#endif /* GCTIME */

	init_segment_layout();
	init_heap_space(min_size, max_size);
	init_subheaps();
#ifndef MULTITHREAD
	init_alloc_ptr_set(ALLOC_PTR_SET());
#endif /* MULTITHREAD */

#ifdef GCSTAT
	stat_notice("---");
	stat_notice("event: init");
	stat_notice("time: 0.0");
	stat_notice("initial_num_segments: %u", gcstat.initial_num_segments);
	stat_notice("heap_size: %u",
		    SEGMENT_SIZE * gcstat.initial_num_segments);
	stat_notice("config:");
	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++)
		stat_notice(" %u: {size: %lu, num_blocks: %lu, "
			    "bitmap_size: %lu}",
			    1U << i, (unsigned long)SEGMENT_SIZE,
			    (unsigned long)segment_layout[i].num_blocks,
			    (unsigned long)segment_layout[i].bitmap_size);
	stat_notice("counters:");
	stat_notice(" heap: [fast, find, next, new]");
	stat_notice(" other: [malloc]");
#ifdef MINOR_GC
	stat_notice(" barrier: [called, barriered]");
#endif /* MINOR_GC */
	print_heap_occupancy();
#endif /* GCSTAT */
}

void
sml_heap_free()
{
#if defined GCTIME && defined MINOR_GC
	sml_time_t t;
#endif /* GCTIME && MINOR_GC */

#ifdef MULTITHREAD
	destroy_free_ptr_list();
#endif /* MULTITHREAD */

	ReleasePage(heap_space.begin,
		    (char*)heap_space.end - (char*)heap_space.begin);

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
#ifndef MINOR_GC
	stat_notice("gc count       : %u #times", gcstat.gc.count);
	stat_notice("gc time        : "TIMEFMT" #sec (%4.2f%%), avg: %.6f sec",
		    TIMEARG(gcstat.gc.total_time),
		    TIMEFLOAT(gcstat.gc.total_time)
		    / TIMEFLOAT(gcstat.exec_time) * 100.0f,
		    TIMEFLOAT(gcstat.gc.total_time)
		    / (double)gcstat.gc.count);
	stat_notice("max wait time  : %.6f #sec", gcstat.max_wait_time);
#else
	t = gcstat.gc.total_time;
	sml_time_accum(gcstat.minor_gc.total_time, t);
	stat_notice("gc count       : %u #times",
		    gcstat.gc.count + gcstat.minor_gc.count);
	stat_notice("gc time        : "TIMEFMT" #sec (%4.2f%%), avg: %.6f sec",
		    TIMEARG(t),
		    TIMEFLOAT(t) / TIMEFLOAT(gcstat.exec_time) * 100.0f,
		    TIMEFLOAT(t)
		    / (double)(gcstat.gc.count + gcstat.minor_gc.count));
	stat_notice("max wait time  : %.6f #sec", gcstat.max_wait_time);
	stat_notice("major count    : %u #times", gcstat.gc.count);
	stat_notice("major time     : "TIMEFMT" #sec (%4.2f%%), avg: %.6f sec",
		    TIMEARG(gcstat.gc.total_time),
		    TIMEFLOAT(gcstat.gc.total_time)
		    / TIMEFLOAT(gcstat.exec_time) * 100.0f,
		    TIMEFLOAT(gcstat.gc.total_time)
		    / (double)gcstat.gc.count);
	stat_notice("minor count    : %u #times", gcstat.minor_gc.count);
	stat_notice("minor time     : "TIMEFMT" #sec (%4.2f%%), avg: %.6f sec",
		    TIMEARG(gcstat.minor_gc.total_time),
		    TIMEFLOAT(gcstat.minor_gc.total_time)
		    / TIMEFLOAT(gcstat.exec_time) * 100.0f,
		    TIMEFLOAT(gcstat.minor_gc.total_time)
		    / (double)gcstat.minor_gc.count);
#endif /* MINOR_GC */
#ifdef GCSTAT
	stat_notice("clear time     : "TIMEFMT" #sec (%4.2f%%), avg: %.6f sec",
		    TIMEARG(gcstat.gc.clear_time),
		    TIMEFLOAT(gcstat.gc.clear_time)
		    / TIMEFLOAT(gcstat.gc.total_time) * 100.0f,
		    TIMEFLOAT(gcstat.gc.clear_time)
		    / (double)gcstat.gc.count);
	stat_notice("total clear bytes :%10lu #bytes, avg:%8.2f bytes",
		    gcstat.gc.total_clear_bytes,
		    (double)gcstat.gc.total_clear_bytes
		    / (double)gcstat.gc.count);
	stat_notice("total push count  :%10lu #times, avg:%8.2f times",
		    gcstat.gc.total_push_count,
		    (double)gcstat.gc.total_push_count
		    / (double)gcstat.gc.count);
	stat_notice("total trace count :%10lu #times, avg:%8.2f times",
		    gcstat.gc.total_trace_count,
		    (double)gcstat.gc.total_trace_count
		    / (double)gcstat.gc.count);
#ifdef MINOR_GC
	stat_notice("minor push count  :%10lu #times, avg:%8.2f times",
		    gcstat.minor_gc.total_push_count,
		    (double)gcstat.minor_gc.total_push_count
		    / (double)gcstat.minor_gc.count);
	stat_notice("minor trace count :%10lu #times, avg:%8.2f times",
		    gcstat.minor_gc.total_trace_count,
		    (double)gcstat.minor_gc.total_trace_count
		    / (double)gcstat.minor_gc.count);
#endif /* MINOR_GC */
	stat_notice("total alloc count :%10lu #times",
		    gcstat.total_alloc_count);
	if (gcstat.file)
		fclose(gcstat.file);
#endif /* GCSTAT */
#endif /* GCSTAT || GCTIME */
}

void *
sml_heap_thread_init()
{
#ifdef MULTITHREAD
	union alloc_ptr_set *ptr_set = new_alloc_ptr_set();
#ifdef THREAD_LOCAL_STORAGE
	current_alloc_ptr_set = ptr_set;
#endif /* THREAD_LOCAL_STORAGE */
	return ptr_set;
#else
	return NULL;
#endif /* MULTITHREAD */
}

void
sml_heap_thread_free(void *data ATTR_UNUSED)
{
#ifdef MULTITHREAD
	union alloc_ptr_set *ptr_set = (union alloc_ptr_set *)data;
	free_alloc_ptr_set(ptr_set);
#endif /* MULTITHREAD */
}

#ifdef MULTITHREAD
void
sml_heap_thread_gc_hook(void *data)
{
	unsigned int i;
	union alloc_ptr_set *ptr_set = data;
	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++)
		set_alloc_ptr(&ptr_set->alloc_ptr[i], NULL);
}
#endif /* MULTITHREAD */

static unsigned int stack_last;
static void *stack_top = &stack_last;

void stacklist(){
	void *obj = stack_top;
	while (obj != &stack_last) {
		sml_notice("%p", obj);
		obj = obj_to_stack(obj)->next_obj;
	}
}

#ifdef GCSTAT
#define GCSTAT_PUSH_COUNT()  (gcstat.last.push_count++)
#else
#define GCSTAT_PUSH_COUNT()
#endif /* GCSTAT */

#define OBJ_HAS_NO_POINTER(obj)			\
	(!(OBJ_TYPE(obj) & OBJTYPE_BOXED)	\
	 || (OBJ_TYPE(obj) == OBJTYPE_RECORD	\
	     && OBJ_BITMAP(obj)[0] == 0		\
	     && OBJ_NUM_BITMAPS(obj) == 1))

#if SEG_RANK == 3
#define MARKBIT(b, index, seg) do {					\
	ASSERT(BITPTR_INDEX((b), BITMAP0_BASE(seg)) == index);		\
	(seg)->live_count++;						\
	BITPTR_SET(b);							\
	if (~BITPTR_WORD(b) == 0U) {					\
		unsigned int index__ = (index) / BITPTR_WORDBITS;	\
		BITPTR_INIT(b, BITMAP_BASE(seg, 1), index__);		\
		BITPTR_SET(b);						\
		if (~BITPTR_WORD(b) == 0U) {				\
			index__ /= BITPTR_WORDBITS;			\
			BITPTR_INIT(b, BITMAP_BASE(seg, 2), index__);	\
			BITPTR_SET(b);					\
		}							\
	}								\
} while(0)
#else
#define MARKBIT(b, index, seg) do {					\
	unsigned int index__ = (index);					\
	ASSERT(BITPTR_INDEX((b), BITMAP0_BASE(seg)) == index__);	\
	(seg)->live_count++;						\
	BITPTR_SET(b);							\
	if (~BITPTR_WORD(b) == 0U) {					\
		unsigned int i__;					\
		for(i__ = 1; i__ < SEG_RANK; i__++) {			\
			bitptr_t b__;					\
			index__ /= BITPTR_WORDBITS;			\
			BITPTR_INIT(b__, BITMAP_BASE(seg, i__),		\
				    index__);				\
			BITPTR_SET(b__);				\
			if (~BITPTR_WORD(b__) != 0U)			\
				break;					\
		}							\
	}								\
} while (0)
#endif /* SEG_RANK == 3 */

#define STACK_IS_EMPTY() (stack_top == &stack_last)

#define STACK_TOP() (stack_top == &stack_last ? NULL : stack_top)
#define STACK_PUSH(obj, seg, index) do {				\
	GCSTAT_PUSH_COUNT();						\
	ASSERT(OBJ_TO_SEGMENT(obj) == seg);				\
	ASSERT(OBJ_TO_INDEX(OBJ_TO_SEGMENT(obj), obj) == index);	\
	ASSERT((seg)->stack[index].next_obj == NULL);			\
	(seg)->stack[index].next_obj = stack_top, stack_top = (obj);	\
} while (0)
#define STACK_POP(topobj) do {						\
	struct segment *seg__ = OBJ_TO_SEGMENT(topobj);			\
	unsigned int index__ = OBJ_TO_INDEX(seg__, topobj);		\
	stack_top = seg__->stack[index__].next_obj;			\
	seg__->stack[index__].next_obj = NULL;				\
} while (0)

#ifdef MINOR_GC
static void
flush_stack()
{
	void *obj;
	while ((obj = STACK_TOP()))
		STACK_POP(obj);
}
#endif /* MINOR_GC */

#ifdef MINOR_GC
SML_PRIMITIVE void
sml_write(void *objaddr, void **writeaddr, void *new_value)
{
	struct segment *seg;
	size_t index;
	bitptr_t b;
	void *obj;

	*writeaddr = new_value;

	DBG(("objaddr=%p, writeaddr=%p (%p)", objaddr, writeaddr, *writeaddr));
#ifdef GCSTAT
	gcstat.last.barrier_count.called++;
#endif /* GCSTAT */

	if (!IS_IN_HEAP(writeaddr)) {
		sml_global_barrier(writeaddr, objaddr);

		if (!IS_IN_HEAP(new_value))
			return;
		GIANT_LOCK();

		seg = OBJ_TO_SEGMENT(new_value);
		index = OBJ_TO_INDEX(seg, new_value);
		BITPTR_INIT(b, BITMAP0_BASE(seg), index);
		if (BITPTR_TEST(b)) {
			GIANT_UNLOCK();
			return;
		}

		/* obj is young and is referenced from outside of heap.
		 * it must be either marked or barriered. */
#ifdef GCSTAT
		gcstat.last.barrier_count.barriered++;
#endif /* GCSTAT */
		DBG(("BARRIER: %p", new_value));
		MARKBIT(b, index, seg);
		STACK_PUSH(new_value, seg, index);
		GIANT_UNLOCK();
	} else {
		GIANT_LOCK();
		/* objaddr is destructively updated.
		 * if it is marked, it must be barriered. */
		seg = OBJ_TO_SEGMENT(objaddr);
		index = OBJ_TO_INDEX(seg, objaddr);
		BITPTR_INIT(b, BITMAP0_BASE(seg), index);
		if (!BITPTR_TEST(b) || seg->stack[index].next_obj != NULL) {
			GIANT_UNLOCK();
			return;
		}

#ifdef GCSTAT
		gcstat.last.barrier_count.barriered++;
#endif /* GCSTAT */
		DBG(("BARRIER: %p", objaddr));
		STACK_PUSH(objaddr, seg, index);
		GIANT_UNLOCK();
	}
}
#else /* MINOR_GC */
SML_PRIMITIVE void
sml_write(void *objaddr, void **writeaddr, void *new_value)
{
	*writeaddr = new_value;
	if (!IS_IN_HEAP(writeaddr))
		sml_global_barrier(writeaddr, objaddr);
}
#endif /* MINOR_GC */

static void
push(void **block)
{
	void *obj = *block;
	struct segment *seg;
	size_t index;
	bitptr_t b;

	if (!IS_IN_HEAP(obj)) {
		DBG(("%p at %p outside", obj, block));
		if (obj != NULL)
			sml_trace_ptr(obj);
		return;
	}

#ifdef GCSTAT
	gcstat.last.trace_count++;
#endif /* GCSTAT */
	seg = OBJ_TO_SEGMENT(obj);
	index = OBJ_TO_INDEX(seg, obj);
	BITPTR_INIT(b, BITMAP0_BASE(seg), index);
	if (BITPTR_TEST(b)) {
		DBG(("already marked: %p", obj));
		return;
	}
	MARKBIT(b, index, seg);
	DBG(("MARK: %p", obj));

	if (OBJ_HAS_NO_POINTER(obj)) {
		DBG(("EARLYMARK: %p", obj));
		return;
	}

	STACK_PUSH(obj, seg, index);
	DBG(("PUSH: %p", obj));
}

#ifdef MINOR_GC
static void
pop()
{
	void *obj;

	while ((obj = STACK_TOP())) {
		DBG(("POP: %p", obj));
		STACK_POP(obj);
		sml_obj_enum_ptr(obj, push);
	}
}
#endif /* MINOR_GC */

static void
mark(void **block)
{
	void *obj = *block;
	struct segment *seg;
	size_t index;
	bitptr_t b;

	ASSERT(STACK_TOP() == NULL);

	if (!IS_IN_HEAP(obj)) {
		DBG(("%p at %p outside", obj, block));
		if (obj != NULL)
			sml_trace_ptr(obj);
		return;
	}

#ifdef GCSTAT
	gcstat.last.trace_count++;
#endif /* GCSTAT */
	seg = OBJ_TO_SEGMENT(obj);
	index = OBJ_TO_INDEX(seg, obj);
	BITPTR_INIT(b, BITMAP0_BASE(seg), index);
	if (BITPTR_TEST(b)) {
		DBG(("already marked: %p", obj));
		return;
	}
	MARKBIT(b, index, seg);
	DBG(("MARK: %p", obj));

	if (OBJ_HAS_NO_POINTER(obj)) {
		DBG(("EARLYMARK: %p", obj));
		return;
	}

	for (;;) {
		sml_obj_enum_ptr(obj, push);
		if (STACK_IS_EMPTY()) {
			DBG(("MARK END"));
			break;
		}
		obj = stack_top;
		STACK_POP(obj);
		DBG(("POP: %p", obj));
	}
}

static void
sweep()
{
	unsigned int i;
	struct subheap *subheap;
	struct segment *seg;
	struct segment **filled_tail;
	struct segment *unfilled, **unfilled_tail;
	struct segment *free, **free_tail;

	/*
	 * The order of segments in a sub-heap and the free list may be
	 * significant for performace.
	 *
	 * Segments in the list should be ordered in allocation time order.
	 * By keeping this order, mutator always tries to find a free block
	 * at first from long-alived segments, which have long-life objects.
	 * This storategy is good to gather long-life objects in one segment
	 * as many as possible.
	 *
	 * Segments in the free list should be sorted by previous block size.
	 * Smaller block size segment has larger bitmap, and any bitmap in
	 * the free list are already cleared by collector.
	 * By recycling smaller block size segment at first, we can avoid
	 * memset of segment initialization as many as possible.
	 */
	free = NULL, free_tail = &free;
	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		subheap = &global_subheaps[i];

		filled_tail = &subheap->seglist;
		unfilled = NULL, unfilled_tail = &unfilled;
		for (seg = subheap->seglist; seg; seg = seg->next) {
			if (seg->live_count == seg->layout->num_blocks) {
				*filled_tail = seg;
				filled_tail = &seg->next;
			} else if (seg->live_count > 0) {
				*unfilled_tail = seg;
				unfilled_tail = &seg->next;
			} else {
				*free_tail = seg;
				free_tail = &seg->next;
			}
		}

		*filled_tail = unfilled;
		*unfilled_tail = NULL;
		subheap->unreserved = filled_tail;
#ifdef MINOR_GC
#if defined CONFIGURABLE_MINOR_COUNT || MINOR_COUNT > 0
		subheap->minor_count = MINOR_COUNT;
#endif /* MINOR_COUNT */
		subheap->minor_space = subheap->unreserved;
#endif /* MINOR_GC */

#ifndef MULTITHREAD
		set_alloc_ptr(&ALLOC_PTR_SET()->alloc_ptr[i], NULL);
#endif /* MULTITHREAD */
	}
	*free_tail = heap_space.freelist;
	heap_space.freelist = free;
}

#ifdef MINOR_GC
static void
sweep_minor()
{
	unsigned int i;
	struct subheap *subheap;
	struct segment *seg;
	struct segment **filled_tail;
	struct segment *unfilled, **unfilled_tail;
	struct segment *free, **free_tail;

	free = NULL, free_tail = &free;
	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		subheap = &global_subheaps[i];

		/* initial filled_tail is different from sweep() */
		filled_tail = subheap->minor_space;
		unfilled = NULL, unfilled_tail = &unfilled;
		for (seg = *subheap->minor_space; seg; seg = seg->next) {
			/* filled condition is different from sweep() */
			if (seg->live_count >= seg->layout->minor_threshold) {
				*filled_tail = seg;
				filled_tail = &seg->next;
			} else if (seg->live_count > 0) {
				*unfilled_tail = seg;
				unfilled_tail = &seg->next;
			} else {
				*free_tail = seg;
				free_tail = &seg->next;
			}
		}

		*filled_tail = unfilled;
		*unfilled_tail = NULL;
		subheap->unreserved = filled_tail;
#if defined CONFIGURABLE_MINOR_COUNT || MINOR_COUNT > 0
		subheap->minor_count = MINOR_COUNT;
#endif /* MINOR_COUNT */
		subheap->minor_space = subheap->unreserved;

#ifndef MULTITHREAD
		set_alloc_ptr(&ALLOC_PTR_SET()->alloc_ptr[i], NULL);
#endif /* MULTITHREAD */
	}
	*free_tail = heap_space.freelist;
	heap_space.freelist = free;
}
#endif /* MINOR_GC */

#if defined DEBUG && defined SURVIVAL_CHECK
#include "splay.h"
static struct {
	sml_obstack_t *nodes;
	sml_obstack_t *stack;
	sml_tree_t set;
	void *parent;
} survival_check;

static void *
survive_alloc(size_t n)
{
	return sml_obstack_alloc(&survival_check.nodes, n);
}

static int
survive_cmp(void *x, void *y)
{
	uintptr_t m = (uintptr_t)((void**)x)[0], n = (uintptr_t)((void**)y)[0];
	if (m < n) return -1;
	else if (m > n) return 1;
	else return 0;
}

static void
survive_trace(void **block)
{
	void *key;
	void **p;
	if (*block == NULL) return;
	key = *block;
	if (sml_tree_find(&survival_check.set, &key) != NULL) return;
	p = survive_alloc(sizeof(void *) * 3);
	p[0] = *block, p[1] = survival_check.parent, p[2] = block;
	sml_tree_insert(&survival_check.set, p);
	p = sml_obstack_extend(&survival_check.stack, sizeof(void*));
	*p = *block;
}

static void
init_check_survival()
{
	void **p;

	survival_check.nodes = NULL;
	survival_check.stack = NULL;
	survival_check.set.root = NULL;
	survival_check.set.cmp = survive_cmp;
	survival_check.set.alloc = survive_alloc;
	survival_check.set.free = NULL;
	survival_check.parent = NULL;
	sml_rootset_enum_ptr(survive_trace, TRY_MAJOR);

	while (survival_check.stack
	       && sml_obstack_object_size(survival_check.stack) > 0) {
		p = (void**)sml_obstack_next_free(survival_check.stack) - 1;
		survival_check.parent = *p;
		sml_obstack_shrink(&survival_check.stack, p);
		sml_obj_enum_ptr(survival_check.parent, survive_trace);
	}
	sml_obstack_free(&survival_check.stack, NULL);
}

static unsigned int
check_alive(struct segment *seg)
{
	unsigned int i, bittest, livetest, count = 0;
	bitptr_t b;
	char *p;
	void *key;

	BITPTR_INIT(b, BITMAP0_BASE(seg), 0);
	p = BLOCK_BASE(seg);
	for (i = 0; i < seg->layout->num_blocks; i++) {
		bittest = (BITPTR_TEST(b) != 0);
		key = p;
		livetest = (sml_tree_find(&survival_check.set, &key) != NULL);
		ASSERT(bittest >= livetest); /* live but not marked! */
		if (bittest > livetest) {
			DBG(("%p is not alive but marked", p));
			count++;
		}
		BITPTR_INC(b);
		p += BLOCK_SIZE(seg);
	}
	return count;
}

static void
check_survival()
{
	unsigned int i, count = 0;
	struct segment *seg;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		for (seg = global_subheaps[i].seglist; seg; seg = seg->next)
			count += check_alive(seg);
	}
	if (count > 0)
		sml_warn(0, "%u objects are not alive but marked.", count);

	sml_obstack_free(&survival_check.nodes, NULL);
	sml_obstack_free(&survival_check.stack, NULL);
}

/* for debugger */
void
survival_ancestors(void *obj)
{
	void **v;
	while (obj) {
		v = sml_tree_find(&survival_check.set, &obj);
		if (v == NULL) {
			sml_notice("*** abort ***");
			return;
		}
		sml_notice("%p (= *%p)", v[0], v[2]);
		obj = v[1];
	}
}
#endif /* DEBUG && SURVIVAL_CHECK */

static void
do_gc(enum sml_gc_mode mode)
{
#ifdef GCSTAT
	sml_time_t cleartime, t;
	sml_timer_t b_cleared;
#endif /* GCSTAT */
#ifdef GCTIME
	sml_timer_t b_start, b_end;
	sml_timer_t wait_start, wait_end;
	sml_time_t gctime, waittime;
	double waittime_f;
	struct gcstat_gc *gcstat_gc = &gcstat.gc;
#ifdef MINOR_GC
	if (mode == MINOR)
		gcstat_gc = &gcstat.minor_gc;
#endif /* MINOR_GC */
#endif /* GCTIME */

#ifdef GCTIME
	sml_timer_now(wait_start);
#endif /* GCTIME */

#ifdef GCSTAT
	if (gcstat.verbose >= GCSTAT_VERBOSE_COUNT) {
		stat_notice("---");
		stat_notice("event: start gc");
#ifdef MINOR_GC
		stat_notice("gc_type: %s", mode == MINOR ? "MINOR" : "MAJOR");
#endif /* MINOR_GC */
		if (gcstat.last.trigger)
			stat_notice("trigger: %u", 1U << gcstat.last.trigger);
		print_alloc_count();
		print_heap_occupancy();
	}
	clear_last_counts();
#endif /* GCSTAT */

#if defined DEBUG && defined SURVIVAL_CHECK
	init_check_survival();
#endif /* DEBUG && SURVIVAL_CHECK */

	DBG(("start gc"));

#ifdef GCTIME
	gcstat_gc->count++;
	sml_timer_now(b_start);
#endif /* GCTIME */

#ifdef MINOR_GC
	if (mode != MINOR) {
		flush_stack();
#endif /* MINOR_GC */
		clear_all_bitmaps();
#ifdef MULTITHREAD
		destroy_free_ptr_list();
#endif /* MULTITHREAD */
#ifdef MINOR_GC
	}
#endif /* MINOR_GC */

#ifdef GCSTAT
	sml_timer_now(b_cleared);
#endif /* GCSTAT */

#ifdef MINOR_GC
	if (mode == MINOR)
		pop();
#endif /* MINOR_GC */

	if (!sml_gc_initiate(mark, mode, NULL))
		return;
	sml_malloc_pop_and_mark(mark, mode);

#ifndef FAIR_COMPARISON
	/* check finalization */
	sml_check_finalizer(mark, mode);
#endif /* FAIR_COMPARISON */

#ifdef MINOR_GC
	if (mode == MINOR)
		sweep_minor();
	else {
#endif /* MINOR_GC */
		sweep();
		shrink_heap(1);
#ifdef MINOR_GC
	}
#endif /* MINOR_GC */

	/* sweep malloc heap */
	sml_malloc_sweep(mode);

#ifdef GCTIME
	sml_timer_now(b_end);
#endif /* GCTIME */

	DBG(("gc finished."));

#ifdef DEBUG
	check_heap_consistent();
#if defined SURVIVAL_CHECK
	check_survival();
#endif /* SURVIVAL_CHECK */
	scribble_subheaps();
#endif /* DEBUG */

#ifdef GCTIME
	sml_timer_dif(b_start, b_end, gctime);
	sml_time_accum(gctime, gcstat_gc->total_time);
#endif /* GCTIME */
#ifdef GCSTAT
#ifdef MINOR_GC
	if (mode != MINOR) {
#endif /* MINOR_GC */
		sml_timer_dif(b_start, b_cleared, cleartime);
		sml_time_accum(cleartime, gcstat_gc->clear_time);
		gcstat_gc->total_clear_bytes += gcstat.last.clear_bytes;
#ifdef MINOR_GC
	}
#endif /* MINOR_GC */
	gcstat_gc->total_push_count += gcstat.last.push_count;
	gcstat_gc->total_trace_count += gcstat.last.trace_count;
	if (gcstat.verbose >= GCSTAT_VERBOSE_GC) {
		sml_timer_dif(gcstat.exec_begin, b_start, t);
		stat_notice("time: "TIMEFMT, TIMEARG(t));
		stat_notice("---");
		stat_notice("event: end gc");
#ifdef MINOR_GC
		stat_notice("gc_type: %s", mode == MINOR ? "MINOR" : "MAJOR");
#endif /* MINOR_GC */
		sml_timer_dif(gcstat.exec_begin, b_end, t);
		stat_notice("time: "TIMEFMT, TIMEARG(t));
		gcstat.last_probe_time = TIMEFLOAT(t);
		stat_notice("duration: "TIMEFMT, TIMEARG(gctime));
#ifdef MINOR_GC
		if (mode != MINOR) {
#endif /* MINOR_GC */
			stat_notice("clear_time: "TIMEFMT, TIMEARG(cleartime));
			stat_notice("clear_bytes: %lu",
				    gcstat.last.clear_bytes);
#ifdef MINOR_GC
		}
#endif /* MINOR_GC */
		stat_notice("push: %u", gcstat.last.push_count);
		stat_notice("trace: %u", gcstat.last.trace_count);
		print_heap_occupancy();
	}
#endif /* GCSTAT */

#ifdef GCTIME
	sml_timer_now(wait_end);
	sml_timer_dif(wait_start, wait_end, waittime);
	waittime_f = TIMEFLOAT(waittime);
	if (gcstat.max_wait_time < waittime_f)
		gcstat.max_wait_time = waittime_f;
#endif /* GCTIME */

	sml_gc_done();
}

void
sml_heap_gc()
{
	do_gc(MAJOR);
#ifndef FAIR_COMPARISON
	sml_run_finalizer(NULL);
#endif /* FAIR_COMPARISON */
}

#ifdef DEBUG
static int
check_newobj(void *obj)
{
	struct alloc_ptr *ptr;
	struct segment *seg;
	size_t index;
	bitptr_t b, b2;
	unsigned int i;

	seg = OBJ_TO_SEGMENT(obj);
	ptr = &ALLOC_PTR_SET()->alloc_ptr[seg->blocksize_log2];

	/* new object must belong to current segment. */
	ASSERT(ALLOC_PTR_TO_SEGMENT(ptr) == seg);

	/* bit pointer boundary check */
	ASSERT(BITMAP0_BASE(seg) <= ptr->freebit.ptr
	       && ptr->freebit.ptr < BITMAP_LIMIT(seg, 0));

	/* check index */
	index = OBJ_TO_INDEX(seg, obj);
	ASSERT(BLOCK_BASE(seg) + (index << seg->blocksize_log2)
	       == (char*)obj);

	/* object address boundary check */
	ASSERT(index < seg->layout->num_blocks);

	/* bitmap check */
	BITPTR_INIT(b, BITMAP0_BASE(seg), index);
	ASSERT(!BITPTR_TEST(b));

	/* bitmap tree check */
	for (i = 1; i < SEG_RANK; i++) {
		index /= BITPTR_WORDBITS;
		BITPTR_INIT(b2, BITMAP_BASE(seg, i), index);
		ASSERT((BITPTR_WORD(b) == ~0U) ==
		       (BITPTR_TEST(b2) != 0));
		b2 = b;
	}

	return 1;
}
#endif /* DEBUG */

#ifdef GCSTAT
static void
gcstat_alloc_count(size_t offset, size_t size)
{
	sml_timer_t b;
	sml_time_t t;

	gcstat.last.alloc_bytes += size;
	((unsigned int*)&gcstat.last)[offset]++;

	if (gcstat.verbose < GCSTAT_VERBOSE_PROBE)
		return;

	sml_timer_now(b);
	sml_timer_dif(gcstat.exec_begin, b, t);

	if (gcstat.probe_interval > 0) {
		double f = TIMEFLOAT(t);
		if (gcstat.last_probe_time + gcstat.probe_interval > f)
			return;
		gcstat.last_probe_time = f;
	} else {
		if (gcstat.last.alloc_bytes < gcstat.probe_threshold)
			return;
	}

	stat_notice("---");
	stat_notice("event: probe");
	stat_notice("time: "TIMEFMT, TIMEARG(t));
	print_alloc_count();
	print_heap_occupancy();
	clear_last_counts();
}
#define GCSTAT_ALLOC_COUNT(counter, offset, size) \
	gcstat_alloc_count((unsigned int*)&gcstat.last.alloc_count.counter \
			   - (unsigned int*)&gcstat.last + (offset), size)
#define GCSTAT_TRIGGER(slogsize_log2) \
	(gcstat.last.trigger = (blocksize_log2))
#define GCSTAT_COUNT_MOVE(counter1, counter2) \
	(gcstat.last.alloc_count.counter1--, \
	 gcstat.last.alloc_count.counter2++)
#else
#define GCSTAT_ALLOC_COUNT(counter, offset, size)
#define GCSTAT_TRIGGER(slogsize_log2)
#define GCSTAT_COUNT_MOVE(counter1, counter2)
#endif /* GCSTAT */

static NOINLINE void *
find_bitmap(struct alloc_ptr *ptr)
{
	unsigned int index;
	struct segment *seg;
	bitptr_t b = ptr->freebit;
	void *obj;

#if SEG_RANK == 3
	unsigned int *base0, *base1, *base2, *limit, *p;

	ASSERT(ptr->freebit.ptr != &dummy_bitmap);
	seg = ALLOC_PTR_TO_SEGMENT(ptr);

	base0 = BITMAP_BASE(seg, 0);
	BITPTR_NEXT(b);
	if (BITPTR_NEXT_FAILED(b)) {
		index = BITPTR_WORDINDEX(b, base0) + 1;
		base1 = BITMAP_BASE(seg, 1);
		BITPTR_INIT(b, base1, index);
		BITPTR_NEXT(b);
		if (BITPTR_NEXT_FAILED(b)) {
			index = BITPTR_WORDINDEX(b, base1) + 1;
			base2 = BITMAP_BASE(seg, 2);
			BITPTR_INIT(b, base2, index);
			BITPTR_NEXT(b);
			if (BITPTR_NEXT_FAILED(b)) {
				p = &BITPTR_WORD(b) + 1;
				limit = BITMAP_LIMIT(seg, SEG_RANK - 1);
				b = bitptr_linear_search(p, limit);
				if (BITPTR_NEXT_FAILED(b))
					return NULL;
			}
			index = BITPTR_INDEX(b, base2);
			BITPTR_INIT(b, base1 + index, 0);
			BITPTR_NEXT(b);
			ASSERT(!BITPTR_NEXT_FAILED(b));
		}
		index = BITPTR_INDEX(b, base1);
		BITPTR_INIT(b, base0 + index, 0);
		BITPTR_NEXT(b);
		ASSERT(!BITPTR_NEXT_FAILED(b));
	}
	index = BITPTR_INDEX(b, base0);
#else
	unsigned int i, *base, *limit, *p;

	ASSERT(ptr->freebit.ptr != &dummy_bitmap);
	seg = ALLOC_PTR_TO_SEGMENT(ptr);

	BITPTR_NEXT(b);
	base = BITMAP0_BASE(seg);

	if (BITPTR_NEXT_FAILED(b)) {
		for (i = 1;; i++) {
			if (i >= SEG_RANK) {
				p = &BITPTR_WORD(b) + 1;
				limit = BITMAP_LIMIT(seg, SEG_RANK - 1);
				b = bitptr_linear_search(p, limit);
				if (BITPTR_NEXT_FAILED(b))
					return NULL;
				i = SEG_RANK - 1;
				break;
			}
			index = BITPTR_WORDINDEX(b, base) + 1;
			base = BITMAP_BASE(seg, i);
			BITPTR_INIT(b, base, index);
			BITPTR_NEXT(b);
			if (!BITPTR_NEXT_FAILED(b))
				break;
		}
		do {
			index = BITPTR_INDEX(b, base);
			base = BITMAP_BASE(seg, --i);
			BITPTR_INIT(b, base + index, 0);
			BITPTR_NEXT(b);
			ASSERT(!BITPTR_NEXT_FAILED(b));
		} while (i > 0);
	}

	index = BITPTR_INDEX(b, base);
#endif /* SEG_RANK == 3 */

	obj = BLOCK_BASE(seg) + (index << seg->blocksize_log2);
	ASSERT(OBJ_TO_SEGMENT(obj) == seg);

	GCSTAT_ALLOC_COUNT(find, seg->blocksize_log2, ptr->blocksize_bytes);
	BITPTR_INC(b);
	ptr->freebit = b;
	ptr->free = (char*)obj + ptr->blocksize_bytes;

	return obj;
}

static NOINLINE void *
find_segment(struct alloc_ptr *ptr)
{
	unsigned int blocksize_log2 = ALLOC_PTR_TO_BLOCKSIZE_LOG2(ptr);
	struct segment *seg;
	struct subheap *subheap = &global_subheaps[blocksize_log2];
	void *obj;

	ASSERT(BLOCKSIZE_MIN_LOG2 <= blocksize_log2
	       && blocksize_log2 <= BLOCKSIZE_MAX_LOG2);

#ifdef MINOR_GC
#if defined CONFIGURABLE_MINOR_COUNT
	if (minor_count > 0 && subheap->minor_count-- == 0)
		return NULL;
#elif MINOR_COUNT > 0
	if (subheap->minor_count-- == 0)
		return NULL;
#endif /* MINOR_COUNT > 0 */
#endif /* MINOR_GC */

	UNRESERVED_NEXT(subheap->unreserved, seg);
	if (seg) {
		/* seg have at least one free block. */
		set_alloc_ptr(ptr, seg);
		obj = find_bitmap(ptr);
		ASSERT(obj != NULL);
		GCSTAT_COUNT_MOVE(find[blocksize_log2], next[blocksize_log2]);
		return obj;
	}

	seg = new_segment();
	if (seg) {
		init_segment(seg, blocksize_log2);
		UNRESERVED_APPEND(subheap->unreserved, seg);
		set_alloc_ptr(ptr, seg);

		ASSERT(!BITPTR_TEST(ptr->freebit));
		GCSTAT_ALLOC_COUNT(new, blocksize_log2, ptr->blocksize_bytes);
		BITPTR_INC(ptr->freebit);
		obj = ptr->free;
		ptr->free += ptr->blocksize_bytes;
		return obj;
	}

	return NULL;
}

static NOINLINE void *
fast_find_bitmap(struct alloc_ptr *ptr, unsigned int newmask)
{
	unsigned int index;
	struct segment *seg = ALLOC_PTR_TO_SEGMENT(ptr);
	char *obj;
	ptr->freebit.mask = newmask;
	index = BITPTR_INDEX(ptr->freebit, BITMAP0_BASE(seg));
	obj = BLOCK_BASE(seg) + (index << seg->blocksize_log2);
	BITPTR_INC(ptr->freebit);
	ptr->free = obj + ptr->blocksize_bytes;

	ASSERT(check_newobj(obj));
	OBJ_HEADER(obj) = 0;
	return obj;
}

SML_PRIMITIVE void *
sml_alloc(unsigned int objsize)
{
	size_t alloc_size;
	unsigned int blocksize_log2;
	struct alloc_ptr *ptr;
	void *obj;

#ifdef GCSTAT
	gcstat.total_alloc_count++;
#endif /* GCSTAT */

	/* ensure that alloc_size is at least BLOCKSIZE_MIN. */
	alloc_size = ALIGNSIZE(OBJ_HEADER_SIZE + objsize, BLOCKSIZE_MIN);

	if (alloc_size > BLOCKSIZE_MAX) {
		GCSTAT_ALLOC_COUNT(malloc, 0, alloc_size);
		sml_save_fp(CALLER_FRAME_END_ADDRESS());
		return sml_obj_malloc(alloc_size);
	}

	blocksize_log2 = CEIL_LOG2(alloc_size);
	ASSERT(BLOCKSIZE_MIN_LOG2 <= blocksize_log2
	       && blocksize_log2 <= BLOCKSIZE_MAX_LOG2);

	ptr = &ALLOC_PTR_SET()->alloc_ptr[blocksize_log2];

	if (!BITPTR_TEST(ptr->freebit)) {
		GCSTAT_ALLOC_COUNT(fast, blocksize_log2, alloc_size);
		BITPTR_INC(ptr->freebit);
		obj = ptr->free;
		ptr->free += ptr->blocksize_bytes;
		goto alloced;
	}

	sml_save_fp(CALLER_FRAME_END_ADDRESS());

	if (ptr->free != NULL) {
		unsigned int newmask;
		BITPTR_NEXT2(ptr->freebit, newmask);
		if (newmask != 0) {
			GCSTAT_ALLOC_COUNT(next, blocksize_log2, alloc_size);
			return fast_find_bitmap(ptr, newmask);
		}
	}

	if (ptr->free != NULL) {
		obj = find_bitmap(ptr);
		if (obj) goto alloced;
	}
	obj = find_segment(ptr);
	if (obj) goto alloced;

#ifdef MINOR_GC
	GCSTAT_TRIGGER(blocksize_log2);
	do_gc(MINOR);
	obj = find_segment(ptr);
	if (obj) goto alloced_unlock;
#endif /* MINOR_GC */

	GCSTAT_TRIGGER(blocksize_log2);
	do_gc(MAJOR);
	obj = find_segment(ptr);
	if (obj) goto alloced_major;

#ifndef FAIR_COMPARISON
	extend_heap(heap_space.extend_step);
#endif /* FAIR_COMPARISON */
	obj = find_segment(ptr);
	if (obj) goto alloced_major;

#ifdef GCSTAT
	stat_notice("---");
	stat_notice("event: error");
	stat_notice("heap exceeded: intented to allocate %u bytes.",
		    ptr->blocksize_bytes);
	if (gcstat.file)
		fclose(gcstat.file);
#endif /* GCSTAT */
	sml_fatal(0, "heap exceeded: intended to allocate %u bytes.",
		  ptr->blocksize_bytes);

 alloced_major:
	ASSERT(check_newobj(obj));
#ifndef FAIR_COMPARISON
	/* NOTE: sml_run_finalizer may cause garbage collection. */
	obj = sml_run_finalizer(obj);
#endif /* FAIR_COMPARISON */
	goto finished;
#if defined MULTITHREAD || defined MINOR_GC
 alloced_unlock:
#endif /* MULTITHREAD || MINOR_GC */
 alloced:
	ASSERT(check_newobj(obj));
 finished:
#ifndef FAIR_COMPARISON
	OBJ_HEADER(obj) = 0;
#endif /* FAIR_COMPARISON */
	return obj;
}
