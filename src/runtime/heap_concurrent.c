/*
 * heap_bitmap.c
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 * @author Yudai Asai
 * @version $Id: $
 */
#ifndef MULTITHREAD
#error "concurrent GC requires multithread support"
#endif /* MULTITHREAD */

#include <stdio.h>

#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>
#include <pthread.h>
#ifdef DEBUG
#include <stdio.h>
#include "splay.h"
#endif /* DEBUG */

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

#ifndef __APPLE__
#define STATIC_THREAD_STORAGE
#endif /* __APPLE__ */

#include "smlsharp.h"
#include "object.h"
#include "objspace.h"
#include "spinlock.h"
#include "heap.h"

/* #include "sys/time.h" */
/* #include "time.h" */
/* struct timespec th = {0, 200000000}; */
#ifdef GCTIME
#include "timer.h"
static struct {
	sml_time_t total_time;
	sml_time_t total_wait_segment;
	sml_time_t total_initiation;
	sml_time_t total_mark;
	sml_time_t total_clear_bitmap;
	sml_time_t total_reclaim;
	sml_time_t total_clear_stack;
	sml_time_t total_remember;
	unsigned int gc_count;
	unsigned int write_barrier_count;
	unsigned int wait_segment_count;
	double max_wait_segment;
} gcstat = {TIMEINIT, TIMEINIT, TIMEINIT, TIMEINIT, TIMEINIT, TIMEINIT,
	    TIMEINIT, TIMEINIT};
sml_time_t gcstat_total_collector_sync1;
sml_time_t gcstat_total_collector_sync2;
extern double gcstat_max_mutators_pause;
#define stat_notice sml_notice
#endif /* GCTIME */

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

static bitptr_t
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
#define SEGMENT_SIZE_LOG2  15   /* 32k */
#endif /* SEGMENT_SIZE_LOG2 */
#define SEGMENT_SIZE (1U << SEGMENT_SIZE_LOG2)
#ifndef SEG_RANK
#define SEG_RANK  3
#endif /* SEG_RANK */

#define BLOCKSIZE_MIN_LOG2  3U   /* 2^3 = 8 */
#define BLOCKSIZE_MIN       (1U << BLOCKSIZE_MIN_LOG2)
#define BLOCKSIZE_MAX_LOG2  12U  /* 2^4 = 16 */
#define BLOCKSIZE_MAX       (1U << BLOCKSIZE_MAX_LOG2)

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
};

struct segment {
	struct segment *next;
	unsigned int live_count;
	struct stack_slot {
		void *trace_next;     /* for collector's trace stack */
		void *barrier_next;   /* for mutators' write barrier */
		/* "barrier_next" field is shared between mutators and
		 * collector. Its access contention is resolved by atomic
		 * compare-and-swap operation. */
	} *stack;
	char *block_base;
	char *free;
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
 *       |                          | | N * 2 pointers
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
#define WORDBITS BITPTR_WORDBITS

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
		//layout->bitmap_size = CEIL(filled - bitmap_start, MAXALIGN);
		layout->bitmap_size = filled - bitmap_start;
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

#ifdef DEBUG
static unsigned int
seglist_length(struct segment *seg)
{
	unsigned int len = 0;
	for (; seg; seg = seg->next) len++;
	return len;
}
#endif /* DEBUG */

/* sub heaps */
/* The size of struct subheap shoulde be power of 2 for good performance. */
struct subheap {
	/*
	 * Each segment in "partial" has at least one free block.
	 * "filled" is the list of segments with no free block.
	 * "partial_last" points to the last segment of the "partial" list.
	 * If "partial" is empty, "partial_last" is indefinite.
	 *
	 * "filled" and "partial" form a zipped list of segments.
	 */
	struct segment *partial, *partial_last;
	struct segment *filled;
	struct segment *collect;
	unsigned int num_partial;
	spinlock_t lock, dummy1__, dummy2__;
};

#define INITIAL_STARVATION_COUNT  2

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
	/* alloc_ptr[0] is not used. We use there as a pointer member. */
	struct {
		union alloc_ptr_set *next;
		struct segment *seg;
		struct alloc_ptr_set_sync {
			pthread_mutex_t mutex;
			pthread_cond_t cond;
		} *sync;
		unsigned int request_blocksize_log2;
		unsigned int segment_reservation;
	} head;
};

static const unsigned int dummy_bitmap = ~0U;
static const bitptr_t dummy_bitptr = { (unsigned int *)&dummy_bitmap, 1 };

/* list of freed alloc_ptr_set.
 * This variable is shared between mutators and collector. Its access
 * contention is resolved by atomic swap operation. */
static struct {
	union alloc_ptr_set *freelist;
	spinlock_t lock;
} alloc_ptr_set_pool;

#ifdef STATIC_THREAD_STORAGE
static __thread union alloc_ptr_set *local_alloc_ptr_set;
#define ALLOC_PTR_SET() local_alloc_ptr_set
#else
#define ALLOC_PTR_SET() ((union alloc_ptr_set *)sml_current_thread_heap())
#endif

static struct subheap global_subheaps[BLOCKSIZE_MAX_LOG2 + 1];

/* list of stalled threads which waits for finishing current collection.
 * This variable is shared between mutators and collector. Its access
 * contention is resolved by atomic swap operation. */
union alloc_ptr_set *stalled_threads;

#ifdef DEBUG
/* for debugger */
void
dump_subheaps()
{
	unsigned int i, count = 0;
	struct subheap *subheap;
	struct segment *seg;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		subheap = &global_subheaps[i];
		if (subheap->filled == NULL
		    && subheap->partial == NULL)
			continue;
		sml_notice("subheap %d", i);
		sml_notice("  filled:");
		for (seg = subheap->filled; seg; seg = seg->next, count++)
			sml_notice("    %p (%p)", seg, seg->free);
		sml_notice("  partial:");
		for (seg = subheap->partial; seg; seg = seg->next, count++)
			sml_notice("    %p (%p)", seg, seg->free);
	}
	sml_notice("%d segments", count);
}
#endif /* DEBUG */

static struct {
	spinlock_t lock;
	struct segment *freelist;

	/* the length of freelist */
	unsigned int num_free;
	/* the number of free segments which is kept for allowance */
	unsigned int num_headroom;
	/* counter of the case that mutator trims the headroom */
	unsigned int peak_count;
} segment_pool;

static struct {
	unsigned int count;
	unsigned int gc_threshold;
	unsigned int count_prev;
	unsigned int optimal_headroom;
	unsigned int count_dif;
} segment_usage;

static unsigned int num_segments_reserved;
//static pthread_t pthread_watch;

static struct {
	void *begin, *end;
	unsigned int min_num_segments, max_num_segments, extend_step;
	unsigned int num_committed;
	unsigned int *bitmap;
	pthread_mutex_t bitmap_lock;
} heap_space;

static const unsigned int nil__;
#define NIL ((void*)(&nil__))

static struct {
	void *top;
	void *visited;
} trace_stack = { NIL, NIL };

static struct {
	/* "head" field is shared between mutators and collector.
	 * Its access contension is resolved by atomic compare-and-swap
	 * operation. */
	void *head;
	void *visited;
} barrier_list = { NIL, NIL };

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
	  (((uintptr_t)(ptr)->freebit.ptr) & ~(SEGMENT_SIZE - 1U))))

#define OBJ_TO_SEGMENT(objaddr) \
	(ASSERT(IS_IN_HEAP(objaddr)), \
	 ((struct segment*)((uintptr_t)(objaddr) & ~(SEGMENT_SIZE - 1U))))

#define OBJ_TO_INDEX(seg, objaddr)					\
	(ASSERT(OBJ_TO_SEGMENT(objaddr) == (seg)),			\
	 ASSERT((char*)(objaddr) >= (seg)->block_base),			\
	 ASSERT((char*)(objaddr)					\
		< (seg)->block_base + ((seg)->layout->num_blocks	\
				       << (seg)->blocksize_log2)),	\
	 ((size_t)((char*)(objaddr) - (seg)->block_base)		\
	  >> (seg)->blocksize_log2))

#define OBJ_HAS_NO_POINTER(obj)			\
	(!(OBJ_TYPE(obj) & OBJTYPE_BOXED)	\
	 || (OBJ_TYPE(obj) == OBJTYPE_RECORD	\
	     && OBJ_BITMAP(obj)[0] == 0		\
	     && OBJ_NUM_BITMAPS(obj) == 1))

#ifdef DEBUG
/* for debugger */
int
obj_bit(void *obj)
{
	struct segment *seg;
	unsigned int index;
	bitptr_t b;
	seg = OBJ_TO_SEGMENT(obj);
	index = OBJ_TO_INDEX(seg, obj);
	BITPTR_INIT(b, BITMAP0_BASE(seg), index);
	return BITPTR_TEST(b) != 0;
}
#endif /* DEBUG */

#ifdef DEBUG
/* for debugger */
struct stack_slot *
obj_stack(void *obj)
{
	struct segment *seg;
	unsigned int index;
	seg = OBJ_TO_SEGMENT(obj);
	index = OBJ_TO_INDEX(seg, obj);
	return &seg->stack[index];
}
#endif /* DEBUG */

static void
clear_alloc_ptr(struct alloc_ptr *ptr)
{
	ptr->free = NULL;
	ptr->freebit = dummy_bitptr;
}

static void
set_alloc_ptr(struct alloc_ptr *ptr, struct segment *seg)
{
	ptr->free = BLOCK_BASE(seg);
	BITPTR_INIT(ptr->freebit, BITMAP0_BASE(seg), 0);
}

static void
clear_bitmap(struct segment *seg)
{
	unsigned int i;

	memset(BITMAP0_BASE(seg), 0, seg->layout->bitmap_size);

	for (i = 0; i < SEG_RANK; i++)
		BITMAP_LIMIT(seg, i)[-1] = BITMAP_SENTINEL(seg, i);
	seg->live_count = 0;
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
		/* ASSERT(check_segment_consistent(seg, 0) == 0); */
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
	seg->free = seg->block_base;
	seg->next = NULL;

#ifdef DEBUG
	/* scribble allocation blocks */
	memset(ADD_OFFSET(seg, seg->layout->block_offset - 4),
	       0x55, SEGMENT_SIZE - (seg->layout->block_offset - 4));
#endif /* DEBUG */

#ifdef NULL_IS_NOT_ZERO
	for (i = 0; i < layout->num_blocks; i++)
		seg->stack[i] = NULL;
#endif /* NULL_IS_NOT_ZERO */

	/* ASSERT(check_segment_consistent(seg, 0) == 0); */
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
		ASSERT(objsize <= (size_t)(1 << seg->blocksize_log2));
		memset(p - OBJ_HEADER_SIZE + objsize, 0x55,
		       BLOCK_SIZE(seg) - objsize);
		BITPTR_INC(b);
		p += BLOCK_SIZE(seg);
	}
}
#endif /* DEBUG */

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

static struct segment **
extend_heap(unsigned int count, struct segment **freelist)
{
	unsigned int i;
	struct segment *seg;
	bitptr_t b;

	BITPTR_INIT(b, heap_space.bitmap, 0);
	seg = heap_space.begin;
	for (i = 0; count > 0 && i < heap_space.max_num_segments; i++) {
		if (!BITPTR_TEST(b)) {
			CommitPage(seg, SEGMENT_SIZE);
			seg->layout = &segment_layout[0];
			*freelist = seg;
			freelist = &seg->next;
			BITPTR_SET(b);
			count--;
			heap_space.num_committed++;
		}
		BITPTR_INC(b);
		seg = (struct segment *)((char*)seg + SEGMENT_SIZE);
	}

	*freelist = NULL;
	return freelist;
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

	freesize_post = (uintptr_t)p & (SEGMENT_SIZE - 1);
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
	heap_space.extend_step = min_num_segments > 0 ? min_num_segments : 1;
	heap_space.num_committed = 0;

	bitmap_bits = ALIGNSIZE(max_num_segments, BITPTR_WORDBITS);
	heap_space.bitmap = xmalloc(bitmap_bits / CHAR_BIT);
	memset(heap_space.bitmap, 0, bitmap_bits / CHAR_BIT);

	pthread_mutex_init(&heap_space.bitmap_lock, NULL);
	SPIN_INIT(&segment_pool.lock);

	segment_pool.freelist = NULL;
	extend_heap(min_num_segments, &segment_pool.freelist);
	segment_pool.num_free = min_num_segments;
	segment_pool.num_headroom = min_num_segments / 2;
	segment_pool.peak_count = 0;
	ASSERT(seglist_length(segment_pool.freelist) == segment_pool.num_free);
	ASSERT(segment_pool.num_headroom - segment_pool.peak_count
	       <= segment_pool.num_free);

	segment_usage.count = 0;
	segment_usage.gc_threshold = min_num_segments / 2;
	segment_usage.optimal_headroom = min_num_segments / 2;
}

static void
init_subheaps()
{
	unsigned int i;
	struct subheap *subheap;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		subheap = &global_subheaps[i];
		subheap->partial = NULL;
		subheap->filled = NULL;
		subheap->num_partial = 0;
		SPIN_INIT(&subheap->lock);
	}

	ATOMIC_SWAP(&stalled_threads, NULL);
}

static struct segment *
new_segment()
{
	struct segment *seg;

	SPIN_LOCK(&segment_pool.lock);
	seg = segment_pool.freelist;
	if (seg) {
		segment_pool.freelist = seg->next;
		segment_pool.num_free--;
		if (segment_pool.num_free < segment_pool.num_headroom)
			segment_pool.peak_count++;
	}
	ASSERT(seglist_length(segment_pool.freelist) == segment_pool.num_free);
	ASSERT(segment_pool.num_headroom - segment_pool.peak_count
	       <= segment_pool.num_free);
	SPIN_UNLOCK(&segment_pool.lock);

	if (seg != NULL)
		seg->next = NULL;
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
init_alloc_ptr_set(union alloc_ptr_set *ptr_set)
{
	unsigned int i;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		ptr_set->alloc_ptr[i].blocksize_bytes = 1U << i;
		clear_alloc_ptr(&ptr_set->alloc_ptr[i]);
	}
	ptr_set->head.next = NULL;
	ptr_set->head.seg = NULL;
	ptr_set->head.sync = xmalloc(sizeof(struct alloc_ptr_set_sync));
	ptr_set->head.segment_reservation = 0;
	pthread_mutex_init(&ptr_set->head.sync->mutex, NULL);
	pthread_cond_init(&ptr_set->head.sync->cond, NULL);
}

static void
destroy_alloc_ptr_set(union alloc_ptr_set *ptr_set)
{
	pthread_mutex_destroy(&ptr_set->head.sync->mutex);
	pthread_cond_destroy(&ptr_set->head.sync->cond);
	free(ptr_set->head.sync);
	free(ptr_set);
}

void
sml_heap_set_reservation(unsigned int n)
{
	unsigned int old = ALLOC_PTR_SET()->head.segment_reservation;
	ALLOC_PTR_SET()->head.segment_reservation = n;
	num_segments_reserved += n - old;
//pthread_watch = pthread_self();
}

static union alloc_ptr_set *debug_global_alloc_ptr;

static union alloc_ptr_set *
new_alloc_ptr_set()
{
	union alloc_ptr_set *ptr_set;

	SPIN_LOCK(&alloc_ptr_set_pool.lock);
	ptr_set = alloc_ptr_set_pool.freelist;
	if (ptr_set)
		alloc_ptr_set_pool.freelist = ptr_set->head.next;
	SPIN_UNLOCK(&alloc_ptr_set_pool.lock);

	if (ptr_set == NULL) {
		ptr_set = xmalloc(sizeof(union alloc_ptr_set));
		init_alloc_ptr_set(ptr_set);
	}

	debug_global_alloc_ptr = ptr_set;
	return ptr_set;
}

static void
free_alloc_ptr_set(union alloc_ptr_set *ptr_set)
{
	SPIN_LOCK(&alloc_ptr_set_pool.lock);
	ptr_set->head.next = alloc_ptr_set_pool.freelist;
	alloc_ptr_set_pool.freelist = ptr_set;
	SPIN_UNLOCK(&alloc_ptr_set_pool.lock);
	num_segments_reserved -= ptr_set->head.segment_reservation;
}

static struct segment *
collect_free_ptr_list(struct segment *tail)
{
	union alloc_ptr_set *ptr_set, *next;
	struct alloc_ptr *ptr;
	struct segment *seg;
	unsigned int i;

	SPIN_LOCK(&alloc_ptr_set_pool.lock);
	ptr_set = alloc_ptr_set_pool.freelist;
	alloc_ptr_set_pool.freelist = NULL;
	SPIN_UNLOCK(&alloc_ptr_set_pool.lock);

	while (ptr_set) {
		for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
			ptr = &ptr_set->alloc_ptr[i];
			if (ptr->free) {
				seg = ALLOC_PTR_TO_SEGMENT(ptr);
				seg->next = tail;
				tail = seg;
			}
		}
		next = ptr_set->head.next;
		destroy_alloc_ptr_set(ptr_set);
		ptr_set = next;
	}

	return tail;
}

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
		//sml_time_accum(t, gcstat.total_collector_exec);
#endif /* GCTIME */
	}
}

static void
start_collector()
{
	int ret;

	collector.event = sml_event_new(0, 0);
	collector.stop = 0;

	ret = pthread_create(&collector.thread, NULL, collector_main, NULL);
	if (ret != 0)
		sml_sysfatal("sml_start_collector");
}

static void
stop_collector()
{
	collector.stop = 1;
	/* nanosleep(&tc, NULL); */
	sml_event_signal(collector.event);
	pthread_join(collector.thread, NULL);
	sml_event_free(collector.event);
}

static void
signal_collector()
{
	/* nanosleep(&tc, NULL); */
	sml_event_signal(collector.event);
}

void
sml_heap_init(size_t min_size, size_t max_size)
{
	init_segment_layout();
	init_heap_space(min_size, max_size);
	init_subheaps();
	SPIN_INIT(&alloc_ptr_set_pool.lock);
	start_collector();
}

void
sml_heap_free()
{
	stop_collector();

	collect_free_ptr_list(NULL);
	ReleasePage(heap_space.begin,
		    (char*)heap_space.end - (char*)heap_space.begin);
	SPIN_FREE(&alloc_ptr_set_pool.lock);

#ifdef GCTIME
	stat_notice("---");
	stat_notice("# reported by heap_concurrent.c");
	stat_notice("mutators:");
	stat_notice("  total wait_segment : "TIMEFMT" #sec, %u times, "
		    "avg %.6f sec",
		    TIMEARG(gcstat.total_wait_segment),
		    gcstat.wait_segment_count,
		    TIMEFLOAT(gcstat.total_wait_segment)
		    / gcstat.wait_segment_count);
	stat_notice("  max wait_segment   : %.6f #sec",
		    gcstat.max_wait_segment);
	stat_notice("  write barrier      : %u #times",
		    gcstat.write_barrier_count);
	stat_notice("collector:");
	stat_notice("  count              : %u #times", gcstat.gc_count);
	stat_notice("  total time         : "TIMEFMT" #sec, avg %.6f sec",
		    TIMEARG(gcstat.total_time),
		    TIMEFLOAT(gcstat.total_time) / gcstat.gc_count);
	stat_notice("  initiation:");
	stat_notice("    total sync1      : "TIMEFMT" #sec, avg %.6f sec",
		    TIMEARG(gcstat_total_collector_sync1),
		    TIMEFLOAT(gcstat_total_collector_sync1) / gcstat.gc_count);
	stat_notice("    total sync2      : "TIMEFMT" #sec, avg %.6f sec",
		    TIMEARG(gcstat_total_collector_sync2),
		    TIMEFLOAT(gcstat_total_collector_sync2) / gcstat.gc_count);
	stat_notice("    total initiation : "TIMEFMT" #sec, avg %.6f sec",
		    TIMEARG(gcstat.total_initiation),
		    TIMEFLOAT(gcstat.total_initiation) / gcstat.gc_count);
	stat_notice("  total remember     : "TIMEFMT" #sec, avg %.6f sec",
		    TIMEARG(gcstat.total_remember),
		    TIMEFLOAT(gcstat.total_remember) / gcstat.gc_count);
	stat_notice("  total mark         : "TIMEFMT" #sec, avg %.6f sec",
		    TIMEARG(gcstat.total_mark),
		    TIMEFLOAT(gcstat.total_mark) / gcstat.gc_count);
	stat_notice("  total bitmap clear : "TIMEFMT" #sec, avg %.6f sec",
		    TIMEARG(gcstat.total_clear_bitmap),
		    TIMEFLOAT(gcstat.total_clear_bitmap) / gcstat.gc_count);
	stat_notice("  total reclaim      : "TIMEFMT" #sec, avg %.6f sec",
		    TIMEARG(gcstat.total_reclaim),
		    TIMEFLOAT(gcstat.total_reclaim) / gcstat.gc_count);
	stat_notice("  total stack clear  : "TIMEFMT" #sec, avg %.6f sec",
		    TIMEARG(gcstat.total_clear_stack),
		    TIMEFLOAT(gcstat.total_clear_stack) / gcstat.gc_count);
	stat_notice("heap usage:");
	stat_notice("  last # of segments : %u",
		    heap_space.num_committed);
	stat_notice("  last num_headroom : %u",
		    segment_pool.num_headroom);
#endif /* GCTIME */
}

void *
sml_heap_thread_init()
{
#ifdef STATIC_THREAD_STORAGE
	local_alloc_ptr_set = new_alloc_ptr_set();
	return local_alloc_ptr_set;
#else
	return new_alloc_ptr_set();
#endif /* STATIC_THREAD_STORAGE */
}

void
sml_heap_thread_free(void *data ATTR_UNUSED)
{
	union alloc_ptr_set *ptr_set = (union alloc_ptr_set *)data;
	free_alloc_ptr_set(ptr_set);
}

void
sml_heap_thread_gc_hook(void *data)
{
	union alloc_ptr_set *ptr_set = data;
	struct alloc_ptr *ptr;
	struct segment *seg;
	unsigned int i;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		ptr = &ptr_set->alloc_ptr[i];
		if (ptr->free) {
			seg = ALLOC_PTR_TO_SEGMENT(ptr);
			seg->free = ptr->free;
		}
	}
}

static void
push(void **slot)
{
	void *obj = *slot;
	struct segment *seg;
	unsigned int index;
	bitptr_t b;

	if (!IS_IN_HEAP(obj)) {
		if (obj != NULL)
			sml_trace_ptr(obj);
		return;
	}

	seg = OBJ_TO_SEGMENT(obj);
	index = OBJ_TO_INDEX(seg, obj);

	if (seg->stack[index].trace_next)
		return;  /* already traced */

	if ((char*)obj >= seg->free) {
		BITPTR_INIT(b, BITMAP0_BASE(seg), index);
		if (!BITPTR_TEST(b))
			return;   /* new object */
	}

	ASSERT(OBJ_HEADER(obj) != 0x55555555);

	seg->stack[index].trace_next = trace_stack.top;
	trace_stack.top = obj;
}

static void
mark(void *obj)
{
	struct segment *seg;
	unsigned int index;
	bitptr_t b;

	seg = OBJ_TO_SEGMENT(obj);
	index = OBJ_TO_INDEX(seg, obj);
	BITPTR_INIT(b, BITMAP0_BASE(seg), index);

	if ((char*)obj >= seg->free || BITPTR_TEST(b))
		return;

	seg->live_count++;
	BITPTR_SET(b);
	if (~BITPTR_WORD(b) == 0U) {
		unsigned int i;
		for(i = 1; i < SEG_RANK; i++) {
			bitptr_t b;
			index /= BITPTR_WORDBITS;
			BITPTR_INIT(b, BITMAP_BASE(seg, i), index);
			BITPTR_SET(b);
			if (~BITPTR_WORD(b) != 0U)
				break;
		}
	}
}

static void
remember(void **ptr)
{
	void *obj = *ptr;
	struct segment *seg;
	struct stack_slot *slot;
	void *head, *next, *new_head;
#if 0
#ifdef GCTIME
	sml_timer_t t1, t2;
	sml_time_t t;
	sml_timer_now(t1);
#endif /* GCTIME */
#endif

	if (!IS_IN_HEAP(obj))
		goto end;

	seg = OBJ_TO_SEGMENT(obj);
	slot = &seg->stack[OBJ_TO_INDEX(seg, obj)];

	/* NOTE: Although it seems a good strategy that it checks whether
	 * "obj" is a new object (i.e. allocated after root-set enumeration)
	 * or not here to reduce the size of barriered pointer set
	 * (barrier_list), it is impossible actually.
	 * To determine whether obj is new, "free" field of every segment
	 * must be set collectly, but the "free" field of segments in the
	 * collect set are managed only by collector in an asynchronous way.
	 * Hence, mutators should put any obj to barrier_list anyway, and
	 * deciding how to deal with it is delegated to the collector. */

	head = barrier_list.head;
	next = ATOMIC_CMPSWAP(&slot->barrier_next, NULL, head);
	if (next != NULL)
		goto end;  /* already barriered */

#ifdef GCTIME
	gcstat.write_barrier_count++;
#endif

	for (;;) {
		new_head = ATOMIC_CMPSWAP(&barrier_list.head, head, obj);
		if (head == new_head)
			break;
		head = new_head;
		ATOMIC_SWAP(&slot->barrier_next, head);
	}
end:
#if 0
#ifdef GCTIME
	sml_timer_now(t2);
	sml_timer_dif(t1, t2, t);
	sml_time_accum(t, gcstat.total_remember);
#endif /* GCTIME */
#endif
	return;
}

static void
clear_stack()
{
	struct segment *seg;
	struct stack_slot *slot;
	void *obj, *next;

	/* clear trace_next */
	ASSERT(trace_stack.top == NIL);
	obj = trace_stack.visited;
	while (obj != NIL) {
		seg = OBJ_TO_SEGMENT(obj);
		slot = &seg->stack[OBJ_TO_INDEX(seg, obj)];
		next = slot->trace_next;
		slot->trace_next = NULL;
		obj = next;
	}
	trace_stack.visited = NIL;

	/* clear barrier_next of objects in barrier_list.visited. */
	obj = barrier_list.visited;
	while (obj != NIL) {
		seg = OBJ_TO_SEGMENT(obj);
		slot = &seg->stack[OBJ_TO_INDEX(seg, obj)];
		obj = ATOMIC_SWAP(&slot->barrier_next, NULL);
	}
	barrier_list.visited = NIL;

	/* clear barrier_next of objects in barrier_list.head.
	 * Note that mutators may add some objects to barrier_list.head
	 * even if collector does not need them. */
	obj = ATOMIC_SWAP(&barrier_list.head, NIL);
	while (obj != NIL) {
		seg = OBJ_TO_SEGMENT(obj);
		slot = &seg->stack[OBJ_TO_INDEX(seg, obj)];
		obj = ATOMIC_SWAP(&slot->barrier_next, NULL);
	}
}

SML_PRIMITIVE void
sml_write(void *objaddr, void **writeaddr, void *new_value)
{
	enum sml_sync_phase phase = sml_current_phase();

	/* snapshot barrier */
	if (phase != ASYNC && IS_IN_HEAP(*writeaddr))
		remember(writeaddr);
	/* snooping barrier */
	if ((phase == SYNC1 || phase == SYNC2) && IS_IN_HEAP(new_value))
		remember(&new_value);

	*writeaddr = new_value;

	if (!IS_IN_HEAP(writeaddr)) {
		/* sml_global_barrier may extend global root-set.
		 * This extension is performed even during collector's live
		 * object tracing.
		 * To ensure new_value is live in any cases, new_value must
		 * be preserved if write barrier is turned on.
		 */
		sml_save_fp(CALLER_FRAME_END_ADDRESS());
		sml_global_barrier(writeaddr, objaddr);
	}
}

static void *
gather_filled()
{
	struct subheap *subheap;
	unsigned int i;
	struct segment *filled, *seg;
	struct segment *head, **last = &head;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		subheap = &global_subheaps[i];
		SPIN_LOCK(&subheap->lock);
		filled = subheap->filled;
		subheap->filled = NULL;
		SPIN_UNLOCK(&subheap->lock);
		*last = filled;
		for (seg = filled; seg; seg = seg->next)
			last = &seg->next;
	}

	/* Every segment in alloc_ptr_set_pool has been allocated to some
	 * thread, so it may have some live objects with bit 0.
	 * This means that conceptually they should be regarded as segments
	 * in "filled" list.
	 *
	 * Moving segments in alloc_ptr_set_pool to the collect set after
	 * root-set enumeration is a bad idea because they may have some
	 * new objects (i.e. objects allocated after root-set enumeration),
	 * which must not be reclaimed by this collection cycle.
	 */
	*last = collect_free_ptr_list(NULL);

	return head;
}

int
sml_heap_gc_hook(void *data)
{
	struct segment **ret = data;
	*ret = gather_filled();
	return 1;
}

static struct segment *
gather_collect(struct segment *tail)
{
	struct subheap *subheap;
	unsigned int i;
	struct segment *collect, *seg;
	struct segment *head, **last = &head;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		subheap = &global_subheaps[i];
		SPIN_LOCK(&subheap->lock);
		collect = subheap->collect;
		subheap->collect = NULL;
		SPIN_UNLOCK(&subheap->lock);
		*last = collect;
		for (seg = collect; seg; seg = seg->next)
			last = &seg->next;
	}
	*last = tail;

	return head;
}

static void
clear_bitmaps(struct segment *collect_set)
{
	struct segment *seg;

	for (seg = collect_set; seg; seg = seg->next) {
		seg->free = (char*)seg + SEGMENT_SIZE;
		clear_bitmap(seg);
	}
}

static void
mark_loop()
{
	struct segment *seg;
	struct stack_slot *slot;
	void *obj, *head;

	do {
		/* consume trace stack */
		while (trace_stack.top != NIL) {
			obj = trace_stack.top;
			seg = OBJ_TO_SEGMENT(obj);
			slot = &seg->stack[OBJ_TO_INDEX(seg, obj)];
			trace_stack.top = slot->trace_next;
			slot->trace_next = trace_stack.visited;
			trace_stack.visited = obj;
			mark(obj);
			sml_obj_enum_ptr(obj, push);
		}

		/* scan barrier list */
		head = ATOMIC_SWAP(&barrier_list.head, NIL);
		while (head != NIL) {
			obj = head;
			seg = OBJ_TO_SEGMENT(obj);
			slot = &seg->stack[OBJ_TO_INDEX(seg, obj)];
			head = ATOMIC_SWAP(&slot->barrier_next,
					   barrier_list.visited);
			barrier_list.visited = obj;
			/* barrier_list may contain some new objects, which
			 * should not be traced.
			 * Call push() to filter out them. */
			if (slot->trace_next == NULL)
				push(&obj);
		}

		sml_malloc_pop_and_mark(push, MAJOR);

		/* If there is no pointer which is needed to be traced in
		 * the barrier_list, the mark loop is finished. */
	} while (trace_stack.top != NIL);
}

#ifdef DEBUG
/* for debugger */
void
dump_segment_sizes(unsigned int *count_collect)
{
	unsigned int i, count;
	struct segment *seg;
	struct subheap *subheap;

	printf("\n");
	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		subheap = &global_subheaps[i];
		SPIN_LOCK(&subheap->lock);
	}
	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		count = 0;
		subheap = &global_subheaps[i];
		for (seg = subheap->partial; seg; seg = seg->next)
			count++;
		printf("%u:\t%u partial\t", i, count);
		count = 0;
		for (seg = subheap->filled; seg; seg = seg->next)
			count++;
		printf("%u filled\t", count);
		count = 0;
		printf("%u collect\t", count_collect[i]);
		if (debug_global_alloc_ptr->alloc_ptr[i].free != NULL)
			count++;
		printf("%u mutator\n", count);
	}
	SPIN_LOCK(&segment_pool.lock);
	for (seg = segment_pool.freelist; seg; seg = seg->next)
		count++;
	printf("%u free\n", count);
	SPIN_UNLOCK(&segment_pool.lock);
	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		subheap = &global_subheaps[i];
		SPIN_UNLOCK(&subheap->lock);
	}
}
#endif /* DEBUG */

static void
reclaim_segments(struct segment *collect_set)
{
	unsigned int i;
	unsigned int count[BLOCKSIZE_MAX_LOG2 + 1];
	struct subheap *subheap;
	struct segment *seg, *next;
	struct segment *free, **free_last = &free;
	unsigned int num_free = 0;
	struct {
		struct segment *filled, **filled_last;
		struct segment *partial, *partial_last;
		unsigned int num_filled, num_partial;
//unsigned int usage_blocks, usage_lives;
	} seglists[BLOCKSIZE_MAX_LOG2 + 1], *seglist;

	unsigned int num_partial = 0;
	unsigned int num_consumed;

	union alloc_ptr_set *wait_list, *ptrs, *ptrs_next;
	unsigned int num_skipped;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		count[i] = 0;
		seglists[i].filled_last = &seglists[i].filled;
		seglists[i].partial_last = NULL;
		seglists[i].partial = NULL;
		seglists[i].num_filled = 0;
		seglists[i].num_partial = 0;
//seglists[i].usage_blocks = 0;
//seglists[i].usage_lives = 0;
	}

	/* assort segments in collect set */
	for (seg = collect_set; seg; seg = next) {
		count[seg->blocksize_log2]++;
		seglist = &seglists[seg->blocksize_log2];
#ifdef DEBUG
		scribble_segment(seg, 0);
#endif /* DEBUG */
		seg->free = seg->block_base;
		next = seg->next;
		if (seg->live_count == seg->layout->num_blocks) {
			/* keep the order of segments in filled list */
			*seglist->filled_last = seg;
			seglist->filled_last = &seg->next;
			seglist->num_filled++;
		} else if (seg->live_count > 0) {
			seg->next = seglist->partial;
			if (seglist->partial == NULL)
				seglist->partial_last = seg;
			seglist->partial = seg;
			seglist->num_partial++;
			num_partial++;
//seglist->usage_blocks += seg->layout->num_blocks;
//seglist->usage_lives += seg->live_count;
		} else {
			*free_last = seg;
			free_last = &seg->next;
			num_free++;
		}
	}
	*free_last = NULL;

	/* allocate segments to stalled threads. */
	wait_list = ATOMIC_SWAP(&stalled_threads, NULL);
	num_skipped = 0;

	for (ptrs = wait_list; ptrs; ptrs = ptrs_next) {
		/* lock is needed to ensure memory access ordering */
		pthread_mutex_lock(&ptrs->head.sync->mutex);
		/* keep pointer to the next item before resuming the thread. */
		ptrs_next = ptrs->head.next;
		ASSERT(ptrs->head.seg == NULL);
		seglist = &seglists[ptrs->head.request_blocksize_log2];
		if (seglist->num_partial + num_free + segment_pool.num_free
		    + ptrs->head.segment_reservation <= num_segments_reserved) {
			ATOMIC_APPEND(&stalled_threads, &ptrs->head.next, ptrs);
			num_skipped++;
			goto skip;
		}
/*
fprintf(stderr, "%d (%d %d/%d %5.3f%%) segments are left for %d\n",
	seglist->num_partial + num_free + segment_pool.num_free,
	seglist->num_partial,
	seglist->usage_lives, seglist->usage_blocks,
	(double)seglist->usage_lives / (double)seglist->usage_blocks * 100.0,
	ptrs->head.request_blocksize_log2);
*/
		if (seglist->partial) {
			ptrs->head.seg = seglist->partial;
			seglist->partial = seglist->partial->next;
			seglist->num_partial--;
			num_partial--;
		} else if (free) {
			seg = free;
			free = free->next;
			num_free--;
			ptrs->head.seg = seg;
			init_segment(seg, ptrs->head.request_blocksize_log2);
		} else if ((seg = new_segment()) != NULL) {
			ptrs->head.seg = seg;
			init_segment(seg, ptrs->head.request_blocksize_log2);
		} else {
			free_last = extend_heap(heap_space.extend_step, &free);
			if (free == NULL) {
				/* dump_segment_sizes(count); */
				sml_fatal(0, "heap exceeded (2^%u)",
					  ptrs->head.request_blocksize_log2);
			}
			seg = free;
			free = free->next;
			num_free--;
			ptrs->head.seg = seg;
			init_segment(seg, ptrs->head.request_blocksize_log2);
		}
		pthread_cond_signal(&ptrs->head.sync->cond);
	skip:
		pthread_mutex_unlock(&ptrs->head.sync->mutex);
	}

	if (sml_num_threads() == num_skipped)
		sml_fatal(0, "failed to schedule segments. all threads are stalled.");

	/* shrink the heap if there are excess segments. */
	if (heap_space.num_committed > heap_space.min_num_segments && free) {
		seg = free;
		free = free->next;
		num_free--;
		free_segment(seg);
	}

	/* reclaim segments */
	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {

		subheap = &global_subheaps[i];
		seglist = &seglists[i];
		if (seglist->filled == NULL && seglist->partial == NULL)
			continue;
		SPIN_LOCK(&subheap->lock);
		*seglist->filled_last = subheap->filled;
		subheap->filled = seglist->filled;
		if (subheap->partial)
			subheap->partial_last->next = seglist->partial;
		else
			subheap->partial = seglist->partial;
		if (seglist->partial)
			subheap->partial_last = seglist->partial_last;
		subheap->num_partial += seglist->num_partial;
		SPIN_UNLOCK(&subheap->lock);
	}


	num_consumed = ATOMIC_COUNTER_SWAP(&segment_usage.count, 0);
	num_consumed -= segment_usage.count_prev;
	segment_usage.gc_threshold = heap_space.num_committed;

	SPIN_LOCK(&segment_pool.lock);
	if (free) {
		*free_last = segment_pool.freelist;
		segment_pool.freelist = free;
		segment_pool.num_free += num_free;
	}

	//fprintf(stderr, "num_consumed=%u, num_free=%u, peak_count=%u, num_headroom=%u, optimal=%u\n", num_consumed, segment_pool.num_free, segment_pool.peak_count, segment_pool.num_headroom, segment_usage.optimal_headroom);

	/* compute optimal headroom */
	if (segment_pool.peak_count >= segment_usage.optimal_headroom / 2) {
		unsigned int n = segment_pool.peak_count * 2;
		unsigned int m = heap_space.num_committed;
		n = m < n ? m : n;
		segment_usage.optimal_headroom = n;
	}
	else if (segment_usage.optimal_headroom <= segment_pool.num_free) {
		unsigned int n = segment_pool.peak_count * 4;
		unsigned int m = heap_space.num_committed / 2;
		n = m > n ? m : n;
		if (segment_usage.optimal_headroom > n)
			segment_usage.optimal_headroom--;
	}
	if (wait_list)
		segment_usage.optimal_headroom = heap_space.num_committed / 2;

	if (segment_usage.optimal_headroom <= segment_pool.num_free)
		segment_pool.num_headroom = segment_usage.optimal_headroom;
	else
		segment_pool.num_headroom = segment_pool.num_free;

	segment_pool.peak_count = 0;

	segment_usage.gc_threshold -= segment_usage.optimal_headroom;
	if (segment_usage.gc_threshold > num_consumed)
		segment_usage.gc_threshold -= num_consumed;
	else 
		segment_usage.gc_threshold = 0;

	if (wait_list)
		segment_usage.gc_threshold = 0;
	//fprintf(stderr, "-> num_free=%u, num_headroom=%u, gc_threshold=%u, optimal=%u\n", segment_pool.num_free, segment_pool.num_headroom, segment_usage.gc_threshold, segment_usage.optimal_headroom);


	ASSERT(seglist_length(segment_pool.freelist) == segment_pool.num_free);
	ASSERT(segment_pool.num_headroom - segment_pool.peak_count
	       <= segment_pool.num_free);
	SPIN_UNLOCK(&segment_pool.lock);

	segment_usage.count_prev = 0;
	segment_usage.count_dif = 0;

	//if (segment_usage.gc_threshold == 0)
	//sml_signal_collector();
}

#ifdef DEBUG
/* for debugger */
void
dump_barrier_list()
{
	struct segment *seg;
	unsigned int index;
	void *obj;

	obj = barrier_list.head;
	printf("dump_barrier_list start\n");
	for (;;) {
		printf("barrier: %p\n", obj);
		if (obj == NULL || obj == NIL) break;
		seg = OBJ_TO_SEGMENT(obj);
		index = OBJ_TO_INDEX(seg, obj);
		obj = seg->stack[index].barrier_next;
	}
	printf("dump_barrier_list end\n");
	obj = barrier_list.head;
}
#endif /* DEBUG */

#ifdef DEBUG
/* for debugger */
void
dump_num_segments()
{
	unsigned int i;
	struct segment *seg;
	struct subheap *subheap;
	unsigned int filled = 0, partial = 0, mutator = 0, free = 0, n;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		subheap = &global_subheaps[i];
		for (n = 0, seg = subheap->filled; seg; seg = seg->next) n++;
		filled += n;
		for (n = 0, seg = subheap->partial; seg; seg = seg->next) n++;
		partial += n;
	}
	for (seg = segment_pool.freelist; seg; seg = seg->next)
		free++;

	for (i = BLOCKSIZE_MIN_LOG2; i <= BLOCKSIZE_MAX_LOG2; i++) {
		if (debug_global_alloc_ptr->alloc_ptr[i].free != NULL)
			mutator++;
	}
	if (debug_global_alloc_ptr->head.seg)
		mutator++;

	printf("filled=%u partial=%u mutator=%u free=%u total=%u\n",
	       filled, partial, mutator, free,
	       filled + partial + mutator + free);
}
#endif /* DEBUG */

#ifdef DEBUG
/* for debugger */
int
is_in(struct segment *seg, struct segment *set)
{
       int i;
       struct segment *s;
       for (s = set, i = 0; s; s = s -> next, i++) {
               if (s == seg)
                       return i;
       }
       return -1;
}
#endif /* DEBUG */

#if defined DEBUG && defined USE_LIVECHECK
static struct {
	sml_obstack_t *nodes, *prev_nodes;
	sml_tree_t set, prev_set;
	struct livecheck_item {
		void *obj, **slot;
		struct livecheck_item *parent, *next;
		struct livecheck_parents {
			struct livecheck_parents *next;
			struct livecheck_item *parent;
		} *other_parents;
		int is_collect;
		int markbit;
		void *trace_next;
		void *barrier_next;
		int is_new;
	} *top, *parent;
	struct segment *collect_set;
} livecheck;

static void *
livecheck_alloc(size_t n)
{
	return sml_obstack_alloc(&livecheck.nodes, n);
}

static int
livecheck_cmp(void *x, void *y)
{
	uintptr_t m = (uintptr_t)*(void**)x, n = (uintptr_t)*(void**)y;
	if (m < n) return -1;
	else if (m > n) return 1;
	else return 0;
}

static void
livecheck_init(struct segment *collect_set)
{
	sml_obstack_free(&livecheck.prev_nodes, NULL);
	livecheck.prev_nodes = livecheck.nodes;
	livecheck.prev_set = livecheck.set;
	livecheck.nodes = NULL;
	livecheck.set.root = NULL;
	livecheck.set.cmp = livecheck_cmp;
	livecheck.set.alloc = livecheck_alloc;
	livecheck.set.free = NULL;
	livecheck.top = NULL;
	livecheck.parent = NULL;
	livecheck.collect_set = collect_set;
}

static void
livecheck_push(void **slot)
{
	void *obj = *slot;
	struct livecheck_item *item;
	struct livecheck_parents *parents;

	if (obj == NULL) return;
	ASSERT(obj != (void*)0x55555555);
	item = sml_tree_find(&livecheck.set, &obj);
	if (item) {
		if (!livecheck.parent) return;
		parents = livecheck_alloc(sizeof(struct livecheck_parents));
		parents->parent = livecheck.parent;
		parents->next = item->other_parents;
		item->other_parents = parents;
		return;
	}
	item = livecheck_alloc(sizeof(struct livecheck_item));
	item->next = livecheck.top;
	item->obj = obj;
	item->slot = slot;
	item->parent = livecheck.parent;
	item->other_parents = NULL;
	if (IS_IN_HEAP(obj)) {
		item->is_collect = is_in(OBJ_TO_SEGMENT(obj),
					 livecheck.collect_set);
		item->markbit = obj_bit(obj);
		item->trace_next = obj_stack(item->obj)->trace_next;
		item->barrier_next = obj_stack(item->obj)->barrier_next;
		item->is_new = (!obj_bit(obj)
			        && (char*)obj >= OBJ_TO_SEGMENT(obj)->free);
	}
	sml_tree_insert(&livecheck.set, item);
	livecheck.top = item;
}

static void
livecheck_trace()
{
	while (livecheck.top) {
		livecheck.parent = livecheck.top;
		livecheck.top = livecheck.top->next;
		sml_obj_enum_ptr(livecheck.parent->obj, livecheck_push);
	}
}

static void
livecheck_dump_item(struct livecheck_item *item, const char *header)
{
	fprintf(stderr, "%s%p @%p ", header, item->obj, item->slot);
	if (!IS_IN_HEAP(item->obj)) {
		fprintf(stderr, "(not in heap)\n");
		return;
	}
	fprintf(stderr, "(collect=%d,bit=%d,trace=%p,barrier=%p,new=%d)\n",
		item->is_collect, item->markbit, item->trace_next,
		item->barrier_next, item->is_new);
}

static void
livecheck_dump(void *obj, int new)
{
	struct livecheck_item *item, *i;
	struct livecheck_parents *p;
	sml_tree_t *set = new ? &livecheck.set : &livecheck.prev_set;

	item = sml_tree_find(set, &obj);
	if (item == NULL) {
		fprintf(stderr, "not found\n");
		return;
	}
	livecheck_dump_item(item, "object: ");
	for (i = item->parent; i; i = i->parent)
		livecheck_dump_item(i, "parent: ");
	fprintf(stderr, "root\n");
	for (p = item->other_parents; p; p = p->next)
		livecheck_dump_item(p->parent, "other parent: ");
}

static void
livecheck_check()
{
	struct segment *seg;
	void *obj;
	unsigned int i;
	bitptr_t b;

	for (seg = livecheck.collect_set; seg; seg = seg->next) {
		obj = seg->block_base;
		BITPTR_INIT(b, BITMAP0_BASE(seg), 0);
		for (i = 0; i < seg->layout->num_blocks; i++) {
			if (!BITPTR_TEST(b)
			    && sml_tree_find(&livecheck.set, &obj) != NULL) {
				livecheck_dump(obj, 1);
				sml_fatal(0, "[BUG] found unmarked object");
			}
			obj = (char*)obj + BLOCK_SIZE(seg);
			BITPTR_INC(b);
		}
	}
}

void sml_stw_begin(void);
void sml_stw_end(void);
void sml_stw_enum_ptr(void(*)(void**));
#endif /* DEBUG && USE_LIVE_CHECK */

static int
check_start_gc()
{
	unsigned int count, count_dif;

	count = ATOMIC_COUNTER_READ(&segment_usage.count);
	count_dif = count - segment_usage.count_prev;
	if (segment_usage.count_dif < count_dif)
		segment_usage.count_dif = count_dif;
	segment_usage.count_prev = count;

	if (count + segment_usage.count_dif > segment_usage.gc_threshold
	    || segment_pool.peak_count > 0
	    || segment_usage.optimal_headroom > segment_pool.num_headroom
	    || ATOMIC_LOAD(&stalled_threads)) {
		segment_usage.count_dif = 0;
		return 1;
	}

	return 0;
}

static void
do_gc()
{
	struct segment *collect_set;
#ifdef GCTIME
	sml_timer_t t1, t2, t3, t4, t5, t6;
	sml_time_t t;
#endif /* GCTIME */

	if (!check_start_gc())
		return;

	//fprintf(stderr, "start gc\n");

#ifdef GCTIME
	gcstat.gc_count++;
	sml_timer_now(t1);
#endif /* GCTIME */

	sml_gc_initiate(remember, MAJOR, &collect_set);
	collect_set = gather_collect(collect_set);

#ifdef GCTIME
	sml_timer_now(t2);
#endif /* GCTIME */

	clear_bitmaps(collect_set);

#ifdef GCTIME
	sml_timer_now(t3);
#endif /* GCTIME */

	mark_loop();
	sml_malloc_sweep(MAJOR);

	/* turn off all write barriers */
	sml_check_gc_flag = ASYNC;

	sml_gc_done();

#ifdef GCTIME
	sml_timer_now(t4);
#endif /* GCTIME */

#if defined DEBUG && defined USE_LIVECHECK
	sml_stw_begin();
	livecheck_init(collect_set);
	sml_stw_enum_ptr(livecheck_push);
	livecheck_trace();
	livecheck_check();
	sml_stw_end();
#endif /* DEBUG && USE_LIVECHECK */

	reclaim_segments(collect_set);

#ifdef GCTIME
	sml_timer_now(t5);
#endif /* GCTIME */

	clear_stack();

#ifdef GCTIME
	sml_timer_now(t6);
#endif /* GCTIME */

	//fprintf(stderr, "end gc\n");

#ifdef GCTIME
	sml_timer_dif(t1, t2, t);
	sml_time_accum(t, gcstat.total_initiation);
	sml_timer_dif(t2, t3, t);
	sml_time_accum(t, gcstat.total_clear_bitmap);
	sml_timer_dif(t3, t4, t);
	sml_time_accum(t, gcstat.total_mark);
	sml_timer_dif(t4, t5, t);
	sml_time_accum(t, gcstat.total_reclaim);
	sml_timer_dif(t5, t6, t);
	sml_time_accum(t, gcstat.total_clear_stack);
	sml_timer_dif(t1, t6, t);
	sml_time_accum(t, gcstat.total_time);
//sml_notice("gc "TIMEFMT" sec", t);
#endif /* GCTIME */
}

void
sml_heap_gc()
{
	do_gc();
}

static NOINLINE void *
find_bitmap(struct alloc_ptr *ptr)
{
	unsigned int i, index, *base, *limit, *p;
	struct segment *seg;
	bitptr_t b = ptr->freebit;
	void *obj;

	if (ptr->free == NULL)
		return NULL;

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
	obj = BLOCK_BASE(seg) + (index << seg->blocksize_log2);
	ASSERT(OBJ_TO_SEGMENT(obj) == seg);

	BITPTR_INC(b);
	ptr->freebit = b;
	ptr->free = (char*)obj + ptr->blocksize_bytes;

	return obj;
}

static NOINLINE void *
find_segment(struct alloc_ptr *ptr)
{
	unsigned int reservation = ALLOC_PTR_SET()->head.segment_reservation;
	unsigned int blocksize_log2 = ALLOC_PTR_TO_BLOCKSIZE_LOG2(ptr);
	struct segment *seg;
	struct subheap *subheap = &global_subheaps[blocksize_log2];
	void *obj;

	ASSERT(BLOCKSIZE_MIN_LOG2 <= blocksize_log2
	       && blocksize_log2 <= BLOCKSIZE_MAX_LOG2);

	//fprintf(stderr, "%p tries to obtain %d seg; num_partial=%d num_free=%d reservation=%d : %d\n",
	//	pthread_self(), blocksize_log2, subheap->num_partial, segment_pool.num_free, reservation, num_segments_reserved);

	seg = ptr->free ? ALLOC_PTR_TO_SEGMENT(ptr) : NULL;

	SPIN_LOCK(&subheap->lock);
	if (seg) {
		if (sml_current_phase() == SYNC1) {
			seg->next = subheap->collect;
			subheap->collect = seg;
		} else {
			seg->next = subheap->filled;
			subheap->filled = seg;
		}
	}
	if (subheap->num_partial + segment_pool.num_free + reservation
	    <= num_segments_reserved) {
		SPIN_UNLOCK(&subheap->lock);
		goto fail;
	}
	seg = subheap->partial;
	if (seg) {
		subheap->partial = seg->next;
		subheap->num_partial--;
	}
	SPIN_UNLOCK(&subheap->lock);

	if (seg) {
		ATOMIC_COUNTER_INC(&segment_usage.count);
		signal_collector();
		ASSERT(blocksize_log2 == seg->blocksize_log2);
		/* seg have at least one free block. */
		set_alloc_ptr(ptr, seg);
		obj = find_bitmap(ptr);
		ASSERT(obj != NULL);
		return obj;
	}

	seg = new_segment();
	if (seg) {
		ATOMIC_COUNTER_INC(&segment_usage.count);
		signal_collector();
		init_segment(seg, blocksize_log2);
		set_alloc_ptr(ptr, seg);
		ASSERT(!BITPTR_TEST(ptr->freebit));
		BITPTR_INC(ptr->freebit);
		obj = ptr->free;
		ptr->free += ptr->blocksize_bytes;
		return obj;
	}
 fail:
	clear_alloc_ptr(ptr);
	return NULL;
}

void sml_control_suspend_internal(void);
void sml_check_gc_internal(void);

static NOINLINE void *
wait_segment(struct alloc_ptr *ptr)
{
	/* assume frame pointer is already saved */

	union alloc_ptr_set *ptr_set = ALLOC_PTR_SET();
	unsigned int blocksize_log2 = ptr - &ptr_set->alloc_ptr[0];
	struct segment *seg;
	void *obj;
#ifdef GCTIME
	sml_timer_t t1, t2;
	sml_time_t t;
	double dt;
#endif /* GCTIME */

	ASSERT(BLOCKSIZE_MIN_LOG2 <= blocksize_log2
	       && blocksize_log2 <= BLOCKSIZE_MAX_LOG2);

#ifdef GCTIME
	sml_timer_now(t1);
#endif /* GCTIME */

	ptr_set->head.seg = NULL;
	ptr_set->head.request_blocksize_log2 = blocksize_log2;
	ATOMIC_APPEND(&stalled_threads, &ptr_set->head.next, ptr_set);

	/* printf("wait block=%u\n", blocksize_log2); */
	sml_control_suspend_internal();  /* frame pointer is already saved */
	signal_collector();

//if (pthread_self() == pthread_watch)
//fprintf(stderr, "%p waits for %d\n", pthread_self(), blocksize_log2);
//fprintf(stderr, "wait!! %d\n", blocksize_log2);

	pthread_mutex_lock(&ptr_set->head.sync->mutex);
	while (ptr_set->head.seg == NULL)
		pthread_cond_wait(&ptr_set->head.sync->cond,
				  &ptr_set->head.sync->mutex);
	pthread_mutex_unlock(&ptr_set->head.sync->mutex);

//fprintf(stderr, "%p resumes\n", pthread_self());

	sml_control_resume();

#ifdef GCTIME
	sml_timer_now(t2);
	sml_timer_dif(t1, t2, t);
	sml_time_accum(t, gcstat.total_wait_segment);
	gcstat.wait_segment_count++;
	dt = TIMEFLOAT(t);
	if (dt > gcstat.max_wait_segment) gcstat.max_wait_segment = dt;
	if (dt > gcstat_max_mutators_pause) gcstat_max_mutators_pause = dt;
#endif /* GCTIME */

	seg = ptr_set->head.seg;
	ptr_set->head.seg = NULL;
	ASSERT(seg);
	set_alloc_ptr(ptr, seg);
	obj = find_bitmap(ptr);
	ASSERT(obj != NULL);
	return obj;
}

SML_PRIMITIVE void *
sml_alloc(unsigned int objsize)
{
	size_t alloc_size;
	unsigned int blocksize_log2;
	struct alloc_ptr *ptr;
	void *obj;

	/* ensure that alloc_size is at least BLOCKSIZE_MIN. */
	alloc_size = ALIGNSIZE(OBJ_HEADER_SIZE + objsize, BLOCKSIZE_MIN);

	if (alloc_size > BLOCKSIZE_MAX) {
		sml_save_fp(CALLER_FRAME_END_ADDRESS());
		return sml_obj_malloc(alloc_size);
	}

	blocksize_log2 = CEIL_LOG2(alloc_size);
	ASSERT(BLOCKSIZE_MIN_LOG2 <= blocksize_log2
	       && blocksize_log2 <= BLOCKSIZE_MAX_LOG2);

	ptr = &ALLOC_PTR_SET()->alloc_ptr[blocksize_log2];

	if (!BITPTR_TEST(ptr->freebit)) {
		BITPTR_INC(ptr->freebit);
		obj = ptr->free;
		ptr->free += ptr->blocksize_bytes;
		goto alloced;
	}

	obj = find_bitmap(ptr);
	if (obj) goto alloced;

	sml_save_fp(CALLER_FRAME_END_ADDRESS());
	sml_check_gc_internal();

	obj = find_segment(ptr);
	if (obj) goto alloced;

	obj = wait_segment(ptr);
	ASSERT(obj != NULL);

 alloced:
	ASSERT(OBJ_HEADER(obj) == 0x55555555);
	OBJ_HEADER(obj) = 0;
	return obj;
}
