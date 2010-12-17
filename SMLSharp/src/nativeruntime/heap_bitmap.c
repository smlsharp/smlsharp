/*
 * heap_bitmap.c
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 */

#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>

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

#define EARLYMARK
/*#define GLOBAL_MARKSTACK*/
/*#define ARENA_MARKSTACK*/
/*#define SURVIVAL_CHECK*/
/*#define GCSTAT*/
/*#define GCTIME*/
/*#define MEMSET_NT*/
#define SWEEP_ARENA
/*#define NULL_IS_NOT_ZERO*/
/*#define MINOR_GC*/

#ifdef GCSTAT
#define GCTIME
#endif /* GCSTAT */
#ifdef MINOR_GC
#define SWEEP_ARENA
#undef GLOBAL_MARKSTACK
#undef ARENA_MARKSTACK
#endif /* MINOR_GC */

#if defined GCSTAT || defined GCTIME
#include <stdarg.h>
#include <stdio.h>
#include "timer.h"
#endif /* GCSTAT || GCTIME */

/* bit pointer */
struct heap_bitptr {
	unsigned int *ptr;
	unsigned int mask;
};
typedef struct heap_bitptr heap_bitptr_t;

#define HEAP_BITPTR_WORDBITS  ((unsigned int)(sizeof(unsigned int) * CHAR_BIT))

#define HEAP_BITPTR_INIT(b,p,n) \
	((b).ptr = (p) + (n) / HEAP_BITPTR_WORDBITS, \
	 (b).mask = 1 << ((n) % HEAP_BITPTR_WORDBITS))
#define HEAP_BITPTR_TEST(b)  (*(b).ptr & (b).mask)
#define HEAP_BITPTR_SET(b)   (*(b).ptr |= (b).mask)
#define HEAP_BITPTR_CLEAR(b) (*(b).ptr &= ~(b).mask)
#define HEAP_BITPTR_WORD(b)  (*(b).ptr)
#define HEAP_BITPTR_WORDINDEX(b,p)  ((b).ptr - (p))
#define HEAP_BITPTR_EQUAL(b1,b2) \
	((b1).ptr == (b2).ptr && (b1).mask == (b2).mask)

/* HEAP_BITPTR_NEXT: find 0 bit in current word after and including
 * pointed bit. */
#define HEAP_BITPTR_NEXT(b) do {			 \
	unsigned int tmp__ = *(b).ptr | ((b).mask - 1U); \
	(b).mask = (tmp__ + 1U) & ~tmp__;		 \
} while (0)
#define HEAP_BITPTR_NEXT_FAILED(b)  ((b).mask == 0)

static heap_bitptr_t
bitptr_linear_search(unsigned int *start, const unsigned int *limit)
{
	heap_bitptr_t b = {start, 0};
	while (b.ptr < limit) {
		b.mask = (*b.ptr + 1) & ~*b.ptr;
		if (b.mask) break;
		b.ptr++;
	}
	return b;
}

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define HEAP_BITPTR_INC(b) do {						\
	unsigned int tmp__;						\
	__asm__ ("xorl\t%0, %0\n\t"					\
		 "roll\t%1\n\t"						\
		 "rcll\t%0"						\
		 : "=&r" (tmp__), "+r" ((b).mask));			\
	(b).ptr += tmp__;\
} while (0)
#else
#define HEAP_BITPTR_INC(b) \
	(((b).mask <<= 1) ? (void)0 : (void)((b).mask = 1, (b).ptr++))
#endif /* !NOASM */

/* HEAP_BITPTR_INDEX: bit index of 'b' counting from first bit of 'base'. */
#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define HEAP_BITPTR_INDEX(b,p) ({				\
	unsigned int tmp__;					\
	__asm__ ("bsfl %1, %0" : "=r" (tmp__) : "r" ((b).mask)); \
	((b).ptr - (p)) * HEAP_BITPTR_WORDBITS + tmp__;		 \
})
#else
#define HEAP_BITPTR_INDEX(b,p) \
	(((b).ptr - (p) + 1U) * HEAP_BITPTR_WORDBITS - bsr((b).mask))
#endif /* NOASM */

/* sml_heap_bsr(x) : searches first 1 bit from MSB and returns the bit index.
 * Assume that x is not zero. */
#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define sml_heap_bsr(x) ({ \
	unsigned int tmp__;						\
	ASSERT((x) > 0);						\
	__asm__ ("bsrl\t%1, %0" : "=r" (tmp__) : "r" ((unsigned int)(x))); \
	tmp__;								\
})
#elif defined(SIZEOF_INT) && (SIZEOF_INT == 4 || SIZEOF_INT == 8)
static inline unsigned int
sml_heap_bsr(unsigned int m)
{
	unsigned int x, n = -1;
	ASSERT(m > 0);
#if SIZEOF_INT == 8
	x = m >> 32; if (x != 0) n += 32, m = x;
#endif /* SIZEOF_INT == 8 */
	x = m >> 16; if (x != 0) n += 16, m = x;
	x = m >> 8; if (x != 0) n += 8, m = x;
	x = m >> 4; if (x != 0) n += 4, m = x;
	x = m >> 2; if (x != 0) n += 2, m = x;
	return n + m;
}
#else
static inline unsigned int
sml_heap_bsr(unsigned int m)
{
	unsigned int x, n = -1, c = sizeof(unsigned int) / 2;
	ASSERT(m > 0);
	do {
		x = m >> c; if (x != 0) n += c, m = x;
		c >>= 1;
	} while (c > 1);
	return n + m;
}
#endif /* NOASM */

#define HEAP_CEIL_LOG2(x) \
	(sml_heap_bsr((x) - 1) + 1)

/* heap bins */
/*
 * Since heap_bins are frequently accessed, they should be small so that
 * they can stay in cache as long as possible. And, in order for fast
 * offset computation, sizeof(struct heap_bin) should be power of 2.
 */
struct heap_bin {
	heap_bitptr_t freebit;
	char *free;
	unsigned int slotsize_bytes;
	struct heap_arena *arena, *filled;  /* zipped arena list */
	unsigned int minor_count;
	unsigned int dummy;
};

#define HEAP_SLOTSIZE_MIN_LOG2  3U   /* 2^3 = 8 */
#define HEAP_SLOTSIZE_MIN       (1U << HEAP_SLOTSIZE_MIN_LOG2)
#define HEAP_SLOTSIZE_MAX_LOG2  12U  /* 2^4 = 16 */
#define HEAP_SLOTSIZE_MAX       (1U << HEAP_SLOTSIZE_MAX_LOG2)

static struct heap_bin heap_bins[HEAP_SLOTSIZE_MAX_LOG2 + 1];

#define BIN_TO_SLOTSIZE_LOG2(bin) \
	(ASSERT(HEAP_SLOTSIZE_MIN_LOG2 <= (unsigned)((bin) - heap_bins) \
		&& (unsigned)((bin) - heap_bins) <= HEAP_SLOTSIZE_MAX_LOG2), \
	 (unsigned)((bin) - heap_bins))

static const unsigned int dummy_bitmap = ~0U;
static const heap_bitptr_t dummy_bitptr = { (unsigned int *)&dummy_bitmap, 1 };

/* heap arena */
/*
 * Heap arena layout:
 *
 * 00000 +--------------------------+
 *       | struct heap_arena        |
 *       +--------------------------+ ARENA_BITMAP_BASE0 (aligned in MAXALIGN)
 *       | bitmap(0)                | ^
 *       :                          : | about N bits + sentinel
 *       |                          | V
 *       +--------------------------+ ARENA_BITMAP_BASE1
 *       | bitmap(1)                | ^
 *       :                          : | about N/32 bits + sentinel
 *       |                          | V
 *       +--------------------------+ ARENA_BITMAP_BASE2
 *       :                          :
 *       +--------------------------+ ARENA_BITMAP_BASEn
 *       | bitmap(n)                | about N/32^n bits + sentinel
 *       |                          |
 *       +--------------------------+ ARENA_STACK_BASE
 *       | stack area               | ^
 *       |                          | | N pointers
 *       |                          | v
 *       +--------------------------+ ARENA_SLOT_BASE (aligned in MAXALIGN)
 *       | obj slot area            | ^
 *       |                          | | N slots
 *       |                          | v
 *       +--------------------------+
 *       :                          :
 * 80000 +--------------------------+
 *
 * N-th bit of bitmap(0) indicates whether N-th slot is used (1) or not (0).
 * N-th bit of bitmap(n) indicates whether N-th word of bitmap(n-1) is
 * filled (1) or not (0).
 */

#define WORDBITS HEAP_BITPTR_WORDBITS

#define CEIL_(x,y)         ((((x) + (y) - 1) / (y)) * (y))
#define BITS_TO_WORDS_(n)  (((n) + WORDBITS - 1) / WORDBITS)
#define WORDS_TO_BYTES_(n) ((n) * sizeof(unsigned int))

#define APPLY_(f,a)    f a
#define REPEAT_0(f,z)  z
#define REPEAT_1(f,z)  APPLY_(f, REPEAT_0(f,z))
#define REPEAT_2(f,z)  APPLY_(f, REPEAT_1(f,z))
#define REPEAT_3(f,z)  APPLY_(f, REPEAT_2(f,z))
#define REPEAT_4(f,z)  APPLY_(f, REPEAT_3(f,z))
#define REPEAT_(i,f,z) REPEAT__(i,f,z)
#define REPEAT__(i,f,z) REPEAT_##i(f,z)

#define INC_0    1
#define INC_1    2
#define INC_2    3
#define INC_3    4
#define INC_4    5
#define INC__(n) INC_##n
#define INC_(n)  INC__(n)

#define LIST_1(f,n)   f(0,n)
#define LIST_2(f,n)   LIST_1(f,n), f(1,n)
#define LIST_3(f,n)   LIST_2(f,n), f(2,n)
#define LIST_4(f,n)   LIST_3(f,n), f(3,n)
#define LIST_5(f,n)   LIST_4(f,n), f(4,n)
#define LIST_(i,f,n)  LIST_##i(f,n)
#define ARRAY_(i,f,n) {LIST_(i,f,n)}
#define DUMMY_(x,y)   y

#define SEL1_(a,b,c)  a
#define SEL2_(a,b,c)  b
#define SEL3_(a,b,c)  c

#ifndef ARENA_SIZE
#define ARENA_SIZE  524288  /* 512k */
#endif /* ARENA_SIZE */
#ifndef ARENA_RANK
#define ARENA_RANK  3
#endif /* ARENA_RANK */

struct heap_arena {
#ifdef SWEEP_ARENA
	unsigned int live_count;
#endif /* SWEEP_ARENA */
	void **stack;
	char *slot_base;
	const struct arena_layout *layout;
	unsigned int slotsize_log2;
	struct heap_arena *next;
};

static struct {
	struct heap_arena *freelist;
	void *begin, *end;
} alloc_arena;

#define IS_IN_HEAP(p) \
	((char*)alloc_arena.begin <= (char*)(p) \
		 && (char*)(p) < (char*)alloc_arena.end)

#ifdef ARENA_MARKSTACK
#define STACK_SENTINEL  sizeof(void*)
#else
#define STACK_SENTINEL  0
#endif /* ARENA_MARKSTACK */

#define ARENA_INITIAL_OFFSET CEIL_(sizeof(struct heap_arena), MAXALIGN)

#define ARENA_BITMAP0_OFFSET   ARENA_INITIAL_OFFSET
#define ARENA_BITMAP_BOTTOM(n)					\
	(/* offset */ ARENA_BITMAP0_OFFSET,			\
	 /* bits */   n,					\
	 /* words */  BITS_TO_WORDS_((n) + 1))
#define ARENA_BITMAP_ITERATE(offset,bits,words)			\
	(/* offset */ (offset) + WORDS_TO_BYTES_(words),	\
	 /* bits */   BITS_TO_WORDS_(bits),			\
	 /* words */  BITS_TO_WORDS_((words) + 1))

#define ARENA_BITMAP_(i,n) \
	REPEAT_(i, ARENA_BITMAP_ITERATE, ARENA_BITMAP_BOTTOM(n))

#define ARENA_BITMAP_OFFSET_(i,n) (APPLY_(SEL1_,ARENA_BITMAP_(i,n)))
#define ARENA_BITMAP_BITS_(i,n)   (APPLY_(SEL2_,ARENA_BITMAP_(i,n)))
#define ARENA_BITMAP_WORDS_(i,n)  (APPLY_(SEL3_,ARENA_BITMAP_(i,n)))
#define ARENA_BITMAP_SIZE_(i,n)   WORDS_TO_BYTES(ARENA_BITMAP_WORDS_(i,n))
#define ARENA_BITMAP_LIMIT_(i,n)  ARENA_BITMAP_OFFSET_(INC_(i), n)
#define ARENA_BITMAP_SENTINEL_BITS_(i,n) \
	(ARENA_BITMAP_WORDS_(i,n) * WORDBITS - ARENA_BITMAP_BITS_(i,n))

#define ARENA_STACK_OFFSET_(n) \
	CEIL_(ARENA_BITMAP_OFFSET_(ARENA_RANK, n), sizeof(void*))
#define ARENA_STACK_SIZE_(n) \
	((n) * sizeof(void*))
#define ARENA_STACK_LIMIT_(n) \
	(ARENA_STACK_OFFSET_(n) + ARENA_STACK_SIZE_(n))
#define ARENA_SLOT_OFFSET_(n,s) \
	CEIL_(ARENA_STACK_LIMIT_(n) + OBJ_HEADER_SIZE, MAXALIGN)
#define ARENA_TOTAL_SIZE_(numslots,slotsize) \
	(ARENA_SLOT_OFFSET_(numslots,slotsize) + (numslots) * (slotsize))

#define ARENA_NUM_SLOTS_ESTIMATE(slotsize)		\
	((size_t)(((double)ARENA_SIZE			\
		   - (double)ARENA_INITIAL_OFFSET	\
		   - (double)ARENA_RANK / CHAR_BIT	\
		   - STACK_SENTINEL)			\
		  / ((double)(slotsize)			\
		     + (1.f				\
			+ 1.f / WORDBITS		\
			+ 1.f / WORDBITS / WORDBITS)	\
		     / CHAR_BIT				\
		     + sizeof(void*))))

#define ARENA_OVERFLOW_BYTES(slotsize) \
	((signed)(ARENA_TOTAL_SIZE_(ARENA_NUM_SLOTS_ESTIMATE(slotsize),	\
				    slotsize) - ARENA_SIZE))
#define ARENA_OVERFLOW_SLOTS(slotsize) \
	((ARENA_OVERFLOW_BYTES(slotsize) + (slotsize) - 1) / (signed)(slotsize))
#define ARENA_NUM_SLOTS(slotsize) \
	(ARENA_NUM_SLOTS_ESTIMATE(slotsize) - ARENA_OVERFLOW_SLOTS(slotsize))

#define ARENA_BITMAP_OFFSET(level, slotsize) \
	ARENA_BITMAP_OFFSET_(level, ARENA_NUM_SLOTS(slotsize))
#define ARENA_BITMAP_LIMIT(level, slotsize) \
	ARENA_BITMAP_LIMIT_(level, ARENA_NUM_SLOTS(slotsize))
#define ARENA_BITMAP_SIZE(slotsize) \
	/* aligning in MAXALIGN makes memset faster. \
	 * It is safe since stack area is bigger than MAXALIGN and \
	 * memset never reach both object header and content. */ \
	CEIL_(ARENA_BITMAP_OFFSET(ARENA_RANK, slotsize) - ARENA_BITMAP0_OFFSET,\
	      MAXALIGN)
#define ARENA_BITMAP_SENTINEL_BITS(level, slotsize) \
	ARENA_BITMAP_SENTINEL_BITS_(level, ARENA_NUM_SLOTS(slotsize))
#define ARENA_BITMAP_SENTINEL(level, slotsize) \
	(~0U << (WORDBITS - ARENA_BITMAP_SENTINEL_BITS(level, slotsize)))
#define ARENA_STACK_OFFSET(slotsize) \
	ARENA_STACK_OFFSET_(ARENA_NUM_SLOTS(slotsize))
#define ARENA_STACK_SIZE(slotsize) \
	ARENA_STACK_SIZE_(ARENA_NUM_SLOTS(slotsize))
#define ARENA_STACK_LIMIT(slotsize) \
	ARENA_STACK_LIMIT_(ARENA_NUM_SLOTS(slotsize))
#define ARENA_SLOT_OFFSET(slotsize) \
	ARENA_SLOT_OFFSET_(ARENA_NUM_SLOTS(slotsize), slotsize)

#ifdef MINOR_GC
#ifndef MINOR_THRESHOLD_RATIO
#define MINOR_THRESHOLD_RATIO  0.5
#endif /* MINOR_THRESHOLD_RATIO */
#ifndef MINOR_COUNT
#define MINOR_COUNT  3
#endif /* MINOR_COUNT */
#define ARENA_LAYOUT(slotsize) \
	{/*slotsize*/      slotsize, \
	 /*bitmap_offset*/ ARRAY_(ARENA_RANK, ARENA_BITMAP_OFFSET, slotsize), \
	 /*bitmap_limit*/  ARRAY_(ARENA_RANK, ARENA_BITMAP_LIMIT, slotsize), \
	 /*sentinel*/      ARRAY_(ARENA_RANK, ARENA_BITMAP_SENTINEL, slotsize),\
	 /*bitmap_size*/   ARENA_BITMAP_SIZE(slotsize), \
	 /*stack_offset*/  ARENA_STACK_OFFSET(slotsize), \
	 /*stack_limit*/   ARENA_STACK_LIMIT(slotsize),	\
	 /*slot_offset*/   ARENA_SLOT_OFFSET(slotsize),	\
	 /*num_slots*/     ARENA_NUM_SLOTS(slotsize),	\
	 /*minor_threshold*/ (size_t)(ARENA_NUM_SLOTS(slotsize) \
				      * MINOR_THRESHOLD_RATIO)}

#define ARENA_LAYOUT_DUMMY \
	{/*slotsize*/      0, \
	 /*bitmap_offset*/ ARRAY_(ARENA_RANK, DUMMY_, ARENA_BITMAP0_OFFSET), \
	 /*bitmap_limit*/  ARRAY_(ARENA_RANK, DUMMY_, ARENA_SIZE), \
	 /*sentinel*/      ARRAY_(ARENA_RANK, DUMMY_, 0), \
	 /*bitmap_size*/   ARENA_SIZE - ARENA_BITMAP0_OFFSET, \
	 /*stack_offset*/  ARENA_SIZE, \
	 /*stack_limit*/   ARENA_SIZE, \
	 /*slot_offset*/   ARENA_SIZE, \
	 /*num_slots*/     ARENA_SIZE, \
	 /*minor_threshold*/ 0}
#else
#define ARENA_LAYOUT(slotsize) \
	{/*slotsize*/      slotsize,\
	 /*bitmap_offset*/ ARRAY_(ARENA_RANK, ARENA_BITMAP_OFFSET, slotsize), \
	 /*bitmap_limit*/  ARRAY_(ARENA_RANK, ARENA_BITMAP_LIMIT, slotsize), \
	 /*sentinel*/      ARRAY_(ARENA_RANK, ARENA_BITMAP_SENTINEL, slotsize),\
	 /*bitmap_size*/   ARENA_BITMAP_SIZE(slotsize), \
	 /*stack_offset*/  ARENA_STACK_OFFSET(slotsize), \
	 /*stack_limit*/   ARENA_STACK_LIMIT(slotsize), \
	 /*slot_offset*/   ARENA_SLOT_OFFSET(slotsize), \
	 /*num_slots*/     ARENA_NUM_SLOTS(slotsize)}

#define ARENA_LAYOUT_DUMMY \
	{/*slotsize*/      0, \
	 /*bitmap_offset*/ ARRAY_(ARENA_RANK, DUMMY_, ARENA_BITMAP0_OFFSET), \
	 /*bitmap_limit*/  ARRAY_(ARENA_RANK, DUMMY_, ARENA_SIZE), \
	 /*sentinel*/      ARRAY_(ARENA_RANK, DUMMY_, 0), \
	 /*bitmap_size*/   ARENA_SIZE - ARENA_BITMAP0_OFFSET, \
	 /*stack_offset*/  ARENA_SIZE, \
	 /*stack_limit*/   ARENA_SIZE, \
	 /*slot_offset*/   ARENA_SIZE, \
	 /*num_slots*/     0}
#endif /* MINOR_GC */

const struct arena_layout {
	size_t slotsize;
	size_t bitmap_offset[ARENA_RANK];
	size_t bitmap_limit[ARENA_RANK];
	unsigned int bitmap_sentinel[ARENA_RANK];
	size_t bitmap_size;
	size_t stack_offset;
	size_t stack_limit;
	size_t slot_offset;
	size_t num_slots;
#ifdef MINOR_GC
	size_t minor_threshold;
#endif /* MINOR_GC */
} arena_layout[HEAP_SLOTSIZE_MAX_LOG2 + 1] = {
	ARENA_LAYOUT_DUMMY,     /* 2^0 = 1 */
	ARENA_LAYOUT_DUMMY,     /* 2^1 = 2 */
	ARENA_LAYOUT_DUMMY,     /* 2^2 = 4 */
	ARENA_LAYOUT(1 << 3),   /* 2^3 = 8 == HEAP_SLOTSIZE_MIN  */
	ARENA_LAYOUT(1 << 4),   /* 2^4 = 16 */
	ARENA_LAYOUT(1 << 5),   /* 2^5 = 32 */
	ARENA_LAYOUT(1 << 6),   /* 2^6 = 64 */
	ARENA_LAYOUT(1 << 7),   /* 2^7 = 128 */
	ARENA_LAYOUT(1 << 8),   /* 2^8 = 256 */
	ARENA_LAYOUT(1 << 9),   /* 2^9 = 512 */
	ARENA_LAYOUT(1 << 10),  /* 2^10 = 1024 */
	ARENA_LAYOUT(1 << 11),  /* 2^11 = 2048 */
	ARENA_LAYOUT(1 << 12),  /* 2^12 = 4096 == HEAP_SLOTSIZE_MIN */
};

#ifdef DEBUG
void
sml_heap_dump_layout()
{
	unsigned int i, j;
	const struct arena_layout *l;
	unsigned long total;

	for (i = HEAP_SLOTSIZE_MIN_LOG2; i <= HEAP_SLOTSIZE_MAX_LOG2; i++) {
		l = &arena_layout[i];
		total = l->slot_offset + l->num_slots * l->slotsize;
		sml_notice("---");
		sml_notice("slotsize: %lu", (unsigned long)l->slotsize);
		sml_notice("bitmap0 offset: %lu",
			   (unsigned long)ARENA_BITMAP0_OFFSET);
		for (j = 0; j < ARENA_RANK; j++) {
			sml_notice("bitmap%u limit: %lu",
			       j, (unsigned long)l->bitmap_limit[j]);
			sml_notice("bitmap%u sentinel: %08x",
			       j, l->bitmap_sentinel[j]);
		}
		sml_notice("bitmap size: %lu",
		       (unsigned long)l->bitmap_size);
		sml_notice("stack offset: %lu", (unsigned long)l->stack_offset);
		sml_notice("stack limit: %lu", (unsigned long)l->stack_limit);
		sml_notice("slot offset: %lu", (unsigned long)l->slot_offset);
		sml_notice("num slots: %lu", (unsigned long)l->num_slots);
		sml_notice("total size: %lu", total);
	}
}
#endif /* DEBUG */

#define ADD_OFFSET(p,n)  ((void*)((char*)(p) + (n)))

#define BITMAP0_BASE(arena) \
	((unsigned int*)ADD_OFFSET(arena, ARENA_BITMAP0_OFFSET))
#define BITMAP_BASE(arena, level) \
	((unsigned int*) \
	 ADD_OFFSET(arena, (arena)->layout->bitmap_offset[level]))
#define BITMAP_LIMIT_3(arena, layout, level)				\
	((unsigned int*)ADD_OFFSET(arena, (layout)->bitmap_limit[level]))
#define BITMAP_LIMIT(arena, level) \
	BITMAP_LIMIT_3(arena, (arena)->layout, level)
#define BITMAP_SENTINEL(arena, level) \
	((arena)->layout->bitmap_sentinel[level])
#define SLOT_BASE(arena)  ((arena)->slot_base)
#define SLOT_SIZE(arena)  (1U << (arena)->slotsize_log2)

#define OBJ_TO_ARENA(objaddr) \
	(ASSERT(IS_IN_HEAP(objaddr)), \
	 ((struct heap_arena*)((uintptr_t)(objaddr) & ~(ARENA_SIZE - 1U))))
#define OBJ_TO_INDEX(arena, objaddr) \
	(ASSERT(OBJ_TO_ARENA(objaddr) == (arena)), \
	 ASSERT((char*)(objaddr) >= (arena)->slot_base), \
	 ASSERT((char*)(objaddr) < (arena)->slot_base \
				 + ((arena)->layout->num_slots \
				    << (arena)->slotsize_log2)), \
	 ((size_t)((char*)(objaddr) - (arena)->slot_base) \
	  >> (arena)->slotsize_log2))

struct heap_arena *obj_to_arena(void *obj) {return OBJ_TO_ARENA(obj);}
size_t obj_to_index(void *obj) {
	struct heap_arena *arena = OBJ_TO_ARENA(obj);
	return OBJ_TO_INDEX(arena, obj);
}
unsigned int obj_to_bit(void *obj) {
	struct heap_arena *arena = OBJ_TO_ARENA(obj);
	size_t index = OBJ_TO_INDEX(arena, obj);
	heap_bitptr_t b;
	HEAP_BITPTR_INIT(b, BITMAP0_BASE(arena), index);
	return HEAP_BITPTR_TEST(b);
}
void **obj_to_stack(void *obj) {
	struct heap_arena *arena = OBJ_TO_ARENA(obj);
	size_t index = OBJ_TO_INDEX(arena, obj);
	return arena->stack + index;
}


#if defined GCSTAT || defined GCTIME
static struct {
	FILE *file;
	size_t probe_threshold;
	unsigned int verbose;
	unsigned int initial_num_arenas;
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
	struct {
		unsigned int trigger;
		struct {
			unsigned int fast[HEAP_SLOTSIZE_MAX_LOG2 + 1];
			unsigned int find[HEAP_SLOTSIZE_MAX_LOG2 + 1];
			unsigned int next[HEAP_SLOTSIZE_MAX_LOG2 + 1];
			unsigned int new[HEAP_SLOTSIZE_MAX_LOG2 + 1];
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
	for (i = HEAP_SLOTSIZE_MIN_LOG2; i <= HEAP_SLOTSIZE_MAX_LOG2; i++) {
		if (gcstat.last.alloc_count.fast[i] != 0
		    || gcstat.last.alloc_count.find[i] != 0
		    || gcstat.last.alloc_count.next[i] != 0
		    || gcstat.last.alloc_count.new[i] != 0)
			stat_notice(" %u: {fast: %u, find: %u, next: %u,"
				    " new: %u}",
				    1U << i,
				    gcstat.last.alloc_count.fast[i],
				    gcstat.last.alloc_count.find[i],
				    gcstat.last.alloc_count.next[i],
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



/* arena allocation */

#ifdef MEMSET_NT
#define memset(dst,fill,size) do {					\
	if ((fill) == 0) {						\
		void *p__ = (dst);					\
		size_t s__ = (size);					\
		ASSERT((uintptr_t)p__ % 16 == 0);			\
		ASSERT(s__ % 16 == 0);					\
		__asm__ volatile ("xorps\t%%xmm0, %%xmm0\n"		\
				  "1:\n\t"				\
				  "movntdq\t%%xmm0, (%0)\n\t"		\
				  "addl\t$16, %0\n\t"			\
				  "cmpl\t%0, %1\n\t"			\
				  "jne\t1b"				\
				  : "+r" (p__)				\
				  : "r" ((char*)p__ + s__)		\
				  : "xmm0", "memory");			\
	} else memset(dst,fill,size);					\
} while (0)
#endif /* MEMSET_NT */

/* for debug or GCSTAT */
static size_t
arena_filled(struct heap_arena *arena, size_t filled_index, size_t *ret_bytes)
{
	unsigned int i;
	heap_bitptr_t b;
	char *p = SLOT_BASE(arena);
	size_t filled = 0, count = 0;
	const size_t slotsize = SLOT_SIZE(arena);

	HEAP_BITPTR_INIT(b, BITMAP0_BASE(arena), 0);
	for (i = 0; i < arena->layout->num_slots; i++) {
		if (i < filled_index || HEAP_BITPTR_TEST(b)) {
			ASSERT(OBJ_TOTAL_SIZE(p) <= slotsize);
			count++;
			filled += OBJ_TOTAL_SIZE(p);
		}
		HEAP_BITPTR_INC(b);
		p += slotsize;
	}

	if (ret_bytes)
		*ret_bytes = filled;
	return count;
}

#ifdef DEBUG
static void
scribble_arena(struct heap_arena *arena, size_t filled_index)
{
	unsigned int i;
	heap_bitptr_t b;
	char *p = SLOT_BASE(arena);

	HEAP_BITPTR_INIT(b, BITMAP0_BASE(arena), 0);
	for (i = 0; i < arena->layout->num_slots; i++) {
		size_t objsize = ((i < filled_index || HEAP_BITPTR_TEST(b))
				  ? OBJ_TOTAL_SIZE(p) : 0);
		memset(p - OBJ_HEADER_SIZE + objsize, 0x55,
		       SLOT_SIZE(arena) - objsize);
		HEAP_BITPTR_INC(b);
		p += SLOT_SIZE(arena);
	}
}

static void
scribble_bins()
{
	unsigned int i;
	struct heap_bin *bin;
	struct heap_arena *arena;

	for (i = HEAP_SLOTSIZE_MIN_LOG2; i <= HEAP_SLOTSIZE_MAX_LOG2; i++) {
		bin = &heap_bins[i];
#ifdef MINOR_GC
		for (arena = bin->filled; arena; arena = arena->next)
			scribble_arena(arena, 0);
#endif /* MINOR_GC */
		if (bin->arena == NULL)
			continue;
		scribble_arena(bin->arena, HEAP_BITPTR_INDEX
			       (bin->freebit, BITMAP0_BASE(bin->arena)));
		for (arena = bin->arena->next; arena; arena = arena->next)
			scribble_arena(arena, 0);
	}
}

static size_t
check_arena_consistent(struct heap_arena *arena, size_t filled_index)
{
	heap_bitptr_t b;
	unsigned int i, *p;
	size_t index, count, filled;
	const struct arena_layout *layout;

	ASSERT(HEAP_SLOTSIZE_MIN_LOG2 <= arena->slotsize_log2
	       && arena->slotsize_log2 <= HEAP_SLOTSIZE_MAX_LOG2);

	/* check alignment */
	ASSERT((uintptr_t)arena & ~(ARENA_SIZE - 1U));

	/* check layout */
	layout = &arena_layout[arena->slotsize_log2];
	ASSERT(arena->layout == layout);
	ASSERT(arena->stack == ADD_OFFSET(arena, layout->stack_offset));
	ASSERT(arena->slot_base == ADD_OFFSET(arena, layout->slot_offset));

#if defined ARENA_MARKSTACK
	/* check stack bottom sentinel. */
	ASSERT(*arena->stack == NULL);
#elif !defined GLOBAL_MARKSTACK
	/* stack area must be filled with NULL. */
	for (i = 0; i < layout->num_slots; i++)
		ASSERT(arena->stack[i] == NULL);
#endif /* ARENA_MARKSTACK */

	/* check sentinel bits */
	index = layout->num_slots;
	HEAP_BITPTR_INIT(b, BITMAP0_BASE(arena), index);
	ASSERT(HEAP_BITPTR_TEST(b));
	HEAP_BITPTR_NEXT(b);
	ASSERT(HEAP_BITPTR_NEXT_FAILED(b));

	for (i = 1; i < ARENA_RANK; i++) {
		index = index / HEAP_BITPTR_WORDBITS + 1;
		HEAP_BITPTR_INIT(b, BITMAP_BASE(arena, i), index);
		ASSERT(HEAP_BITPTR_TEST(b));
		HEAP_BITPTR_NEXT(b);
		ASSERT(HEAP_BITPTR_NEXT_FAILED(b));
	}

	/* check bitmap tree */
	for (i = 0; i < ARENA_RANK - 1; i++) {
		for (p = BITMAP_BASE(arena,i); p < BITMAP_LIMIT(arena,i); p++) {
			HEAP_BITPTR_INIT(b, BITMAP_BASE(arena, i + 1),
					 p - BITMAP_BASE(arena, i));
			ASSERT((*p == ~0U) == (HEAP_BITPTR_TEST(b) != 0));
		}
	}

	/* check all objecst are valid. */
	count = arena_filled(arena, filled_index, &filled);
	ASSERT(count <= layout->num_slots);
	ASSERT(filled <= (layout->num_slots << arena->slotsize_log2));

#if defined MINOR_GC
	/* check live_count */
	ASSERT(count == arena->live_count);
#elif defined SWEEP_ARENA
	/* check live_count flag */
	ASSERT((count == 0) == (arena->live_count == 0));
#endif /* MINOR_GC || SWEEP_ARENA */

	return count;
}

static void
check_bin_consistent()
{
	unsigned int i;
	struct heap_arena *arena;
	struct heap_bin *bin;
	size_t index, count;

	for (i = HEAP_SLOTSIZE_MIN_LOG2; i <= HEAP_SLOTSIZE_MAX_LOG2; i++) {
		bin = &heap_bins[i];

		/* arenas may be empty only if freebit is equal to dummy. */
		if (HEAP_BITPTR_EQUAL(bin->freebit, dummy_bitptr)) {
			ASSERT(bin->arena == NULL);
			ASSERT(bin->free == NULL);
			continue;
		}

		/* each bin must have at least one current arena. */
		ASSERT(bin->arena != NULL);

		/* free pointer boundary check */
		ASSERT(SLOT_BASE(bin->arena) <= bin->free
		       && bin->free < (SLOT_BASE(bin->arena)
				       + (arena_layout[i].num_slots << i)));
		ASSERT(BITMAP0_BASE(bin->arena) <= bin->freebit.ptr
		       && bin->freebit.ptr < BITMAP_LIMIT(bin->arena, 0));

		/* correspondence between free and freebit */
		index = HEAP_BITPTR_INDEX(bin->freebit,
					  BITMAP0_BASE(bin->arena));
		ASSERT(index == OBJ_TO_INDEX(bin->arena, bin->free));

		/* check all arenas */
		for (arena = bin->filled; arena; arena = arena->next) {
			ASSERT(arena->slotsize_log2 == i);
#ifdef MINOR_GC
			count = check_arena_consistent(arena, 0);
#else
			count = check_arena_consistent(arena, ARENA_SIZE);
			ASSERT(count == arena_layout[i].num_slots);
#endif /* MINOR_GC */
		}
		for (arena = bin->arena; arena; arena = arena->next) {
			ASSERT(arena->slotsize_log2 == i);
			check_arena_consistent(arena, 0);
		}

#ifdef MINOR_GC
		ASSERT(bin->minor_count <= MINOR_COUNT);
#endif /* MINOR_GC */
	}
}
#endif /* DEBUG */

static void
rewind_arena_list(struct heap_bin *bin)
{
	struct heap_arena *arenas = bin->arena;
	struct heap_arena *arena, *next;

	arena = bin->filled;
	while (arena) {
		next = arena->next;
		arena->next = arenas;
		arenas = arena;
		arena = next;
	}
	bin->arena = arenas;
	bin->filled = NULL;
}

/* for debug */
static struct heap_arena *
reverse_arena_list(struct heap_arena *arena)
{
	struct heap_arena *next, *prev = NULL;
	while (arena) {
		next = arena->next;
		arena->next = prev;
		prev = arena;
		arena = next;
	}
	return prev;
}

#ifdef GCSTAT
static void
print_arena_occupancy(struct heap_arena *arena, size_t filled_index,
		      struct heap_arena *current)
{
	size_t count, filled;
	count = arena_filled(arena, filled_index, &filled);
	stat_notice("  - {filled: %lu, count: %lu, used: %lu}%s",
		    (unsigned long)filled,
		    (unsigned long)count,
		    (unsigned long)count << arena->slotsize_log2,
		    arena == current ? " #" : "");
}

static void
print_arenas_occupancy(struct heap_arena *arena, size_t filled_index,
		       struct heap_arena *current)
{
	while (arena) {
		print_arena_occupancy(arena, filled_index, current);
		arena = arena->next;
	}
}

static void
print_heap_occupancy()
{
	unsigned int i;
	size_t index;
	struct heap_bin *bin;

	if (gcstat.verbose < GCSTAT_VERBOSE_HEAP)
		return;

	stat_notice("heap:");
	for (i = HEAP_SLOTSIZE_MIN_LOG2; i <= HEAP_SLOTSIZE_MAX_LOG2; i++) {
		bin = &heap_bins[i];
		if (bin->filled == NULL && bin->arena == NULL)
			continue;

		stat_notice(" %u:", bin->slotsize_bytes);
		bin->filled = reverse_arena_list(bin->filled);
#ifdef MINOR_GC
		print_arenas_occupancy(bin->filled, 0, NULL);
#else
		print_arenas_occupancy(bin->filled, ARENA_SIZE, NULL);
#endif /* MINOR_GC */
		bin->filled = reverse_arena_list(bin->filled);

		if (bin->arena == NULL)
			continue;
		index = HEAP_BITPTR_INDEX(bin->freebit,
					  BITMAP0_BASE(bin->arena));
		print_arena_occupancy(bin->arena, index, bin->arena);
		print_arenas_occupancy(bin->arena->next, 0, NULL);
	}
}
#endif /* GCSTAT */

/* for debug */
static void
dump_arena_list(struct heap_arena *arena, struct heap_arena *cur)
{
	size_t filled, count;

	while (arena) {
		count = arena_filled(arena, 0, &filled);
		sml_debug("  arena %p:%s\n",
			  arena, arena == cur ? " CURRENT" : "");
		sml_debug("    slotsize = %u, "
			  "slots = %lu, used = %lu, filled = %lu\n",
			  SLOT_SIZE(arena),
			  (unsigned long)arena->layout->num_slots,
			  (unsigned long)count, (unsigned long)filled);
		arena = arena->next;
	}
}

/* for debug */
void
sml_heap_dump()
{
	unsigned int i;
	struct heap_bin *bin;

	for (i = HEAP_SLOTSIZE_MIN_LOG2; i <= HEAP_SLOTSIZE_MAX_LOG2; i++) {
		bin = &heap_bins[i];

		if (HEAP_BITPTR_EQUAL(bin->freebit, dummy_bitptr)) {
			sml_debug("bin %u (2^%u=%u): dummy bitptr\n",
				  i, i, bin->slotsize_bytes);
		}
		else if (bin->arena) {
			sml_debug("bin %u (2^%u=%u): free=%p, bit %u\n",
				  i, i, bin->slotsize_bytes, bin->free,
				  HEAP_BITPTR_INDEX(bin->freebit,
						    BITMAP0_BASE(bin->arena)));
		} else {
			sml_debug("bin %u (2^%u=%u): free=%p, bitptr %p:%08u\n",
				  i, i, bin->slotsize_bytes, bin->free,
				  bin->freebit.ptr, bin->freebit.mask);
		}
		sml_debug(" arenas:\n");
		bin->filled = reverse_arena_list(bin->filled);
		dump_arena_list(bin->filled, NULL);
		bin->filled = reverse_arena_list(bin->filled);
		dump_arena_list(bin->arena, bin->arena);
	}

	sml_debug("freelist:\n");
	dump_arena_list(alloc_arena.freelist, NULL);
}

static void
clear_bin(struct heap_bin *bin)
{
	if (bin->arena) {
		bin->free = SLOT_BASE(bin->arena);
		HEAP_BITPTR_INIT(bin->freebit, BITMAP0_BASE(bin->arena), 0);
	} else {
		bin->free = NULL;
		bin->freebit = dummy_bitptr;
	}
}

static void
clear_bitmap(struct heap_arena *arena)
{
	unsigned int i;

#ifdef DEBUG
	for (i = arena->layout->bitmap_limit[ARENA_RANK - 1];
	     i < ARENA_BITMAP0_OFFSET + arena->layout->bitmap_size;
	     i++)
		ASSERT(*(unsigned char*)ADD_OFFSET(arena, i) == 0);
#endif /* DEBUG */

	memset(BITMAP0_BASE(arena), 0, arena->layout->bitmap_size);
#ifdef GCSTAT
	gcstat.last.clear_bytes += arena->layout->bitmap_size;
#endif /* GCSTAT */

	for (i = 0; i < ARENA_RANK; i++)
		BITMAP_LIMIT(arena, i)[-1] = BITMAP_SENTINEL(arena, i);
#ifdef SWEEP_ARENA
	arena->live_count = 0;
#endif /* SWEEP_ARENA */
}

static void
clear_all_bitmaps()
{
	unsigned int i;
	struct heap_arena *arena;
	struct heap_bin *bin;

	for (i = HEAP_SLOTSIZE_MIN_LOG2; i <= HEAP_SLOTSIZE_MAX_LOG2; i++) {
		bin = &heap_bins[i];
		rewind_arena_list(bin);
		for (arena = bin->arena; arena; arena = arena->next)
			clear_bitmap(arena);
	}
}

static void
init_arena(struct heap_arena *arena, unsigned int slotsize_log2)
{
	const struct arena_layout *layout;
	unsigned int i;
	void *old_limit, *new_limit;

	ASSERT(HEAP_SLOTSIZE_MIN_LOG2 <= slotsize_log2
	       && slotsize_log2 <= HEAP_SLOTSIZE_MAX_LOG2);

	/* if arena is already initialized, do nothing. */
	if (arena->slotsize_log2 == slotsize_log2) {
		ASSERT(check_arena_consistent(arena, 0) == 0);
		return;
	}

	layout = &arena_layout[slotsize_log2];

	/*
	 * bitmap and stack area are cleared except bitmap sentinels.
	 * Under this assumption, we initialize bitmap and stack area
	 * with accessing least memory.
	 */
#if defined NULL_IS_NOT_ZERO
	old_limit = BITMAP_LIMIT(arena, ARENA_RANK - 1);
	new_limit = BITMAP_LIMIT_L(arena, layout, ARENA_RANK - 1);
#elif defined GLOBAL_MARKSTACK || defined ARENA_MARKSTACK
	old_limit = ADD_OFFSET(BITMAP0_BASE(arena), arena->layout->bitmap_size);
	new_limit = ADD_OFFSET(BITMAP0_BASE(arena), layout->bitmap_size);
#else
	old_limit = ADD_OFFSET(arena, arena->layout->stack_limit);
	new_limit = ADD_OFFSET(arena, layout->stack_limit);
#endif /* NULL_IS_NOT_ZERO */
	if ((char*)new_limit > (char*)old_limit)
		memset(old_limit, 0, (char*)new_limit - (char*)old_limit);

	for (i = 0; i < ARENA_RANK; i++) {
		/* clear old sentinel */
		BITMAP_LIMIT(arena, i)[-1] = 0;
		/* set new sentinel */
		BITMAP_LIMIT_3(arena,layout,i)[-1] = layout->bitmap_sentinel[i];
	}

	arena->slotsize_log2 = slotsize_log2;
	arena->layout = layout;
	arena->stack = ADD_OFFSET(arena, layout->stack_offset);
	arena->slot_base = ADD_OFFSET(arena, layout->slot_offset);
	arena->next = NULL;

#ifdef ARENA_MARKSTACK
	*arena->stack = NULL;
#else
#ifdef NULL_IS_NOT_ZERO
	for (i = 0; i < layout->num_slots; i++)
		arena->stack[i] = NULL;
#endif /* NULL_IS_NOT_ZERO */
#endif /* ARENA_MARKSTACK */

	ASSERT(check_arena_consistent(arena, 0) == 0);
}

static void
init_alloc_arena(size_t size)
{
	size_t pagesize, allocsize, freesize_pre, freesize_post;
	void *p;
	unsigned int i;
	struct heap_arena *arena;

#ifdef MINGW32
	pagesize = 64 * 1024;
#else
	pagesize = getpagesize();
#endif /* MINGW32 */
	if (ARENA_SIZE % pagesize != 0)
		sml_fatal(0, "ARENA_SIZE is not aligned in page size.");

	allocsize = ALIGNSIZE(size, ARENA_SIZE);

	if (allocsize / ARENA_SIZE == 0)
		allocsize = ARENA_SIZE;

#ifdef MINGW32
	p = VirtualAlloc(NULL, ARENA_SIZE + allocsize, MEM_RESERVE,
			 PAGE_NOACCESS);
	if (p == NULL) {
		sml_fatal(0, "VirtualAlloc: error %lu",
			  (unsigned long)GetLastError());
	}

	freesize_post = (uintptr_t)p & (ARENA_SIZE - 1);
	if (freesize_post == 0) {
		VirtualFree(p + allocsize, ARENA_SIZE, MEM_RELEASE);
	} else {
		freesize_pre = ARENA_SIZE - freesize_post;
		VirtualFree(p, freesize_pre, MEM_RELEASE);
		p = (char*)p + freesize_pre;
		VirtualFree(p + allocsize, freesize_post, MEM_RELEASE);
	}
	VirtualAlloc(p, allocsize, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
#else
	/* mmap clears mapping with 0. */
#ifdef DEBUG
	p = mmap((void*)0x2000000, ARENA_SIZE + allocsize, PROT_NONE,
		 MAP_ANON | MAP_PRIVATE, -1, 0);
#else
	p = mmap(NULL, ARENA_SIZE + allocsize, PROT_NONE,
		 MAP_ANON | MAP_PRIVATE, -1, 0);
#endif /* DEBUG */
	if (p == (void*)-1)
		sml_sysfatal("mmap");

	freesize_post = (uintptr_t)p & (ARENA_SIZE - 1);
	if (freesize_post == 0) {
		munmap(p + allocsize, ARENA_SIZE);
	} else {
		freesize_pre = ARENA_SIZE - freesize_post;
		munmap(p, freesize_pre);
		p = (char*)p + freesize_pre;
		munmap(p + allocsize, freesize_post);
	}
	mprotect(p, allocsize, PROT_READ | PROT_WRITE);
#endif /* MINGW32 */

	alloc_arena.begin = p;
	alloc_arena.end = (char*)p + allocsize;
	arena = (struct heap_arena *)alloc_arena.end;
	alloc_arena.freelist = NULL;

	for (i = 0; i < allocsize / ARENA_SIZE; i++) {
		arena = (struct heap_arena *)((char*)arena - ARENA_SIZE);
		arena->next = alloc_arena.freelist;
		arena->layout = &arena_layout[0];
		alloc_arena.freelist = arena;
	}

#ifdef GCSTAT
	gcstat.initial_num_arenas = i;
#endif /* GCSTAT */
}

static struct heap_arena *
new_arena()
{
	struct heap_arena *arena;

	if (alloc_arena.freelist == NULL)
		return NULL;

	arena = alloc_arena.freelist;
	alloc_arena.freelist = arena->next;
	arena->next = NULL;
	return arena;
}

static void
free_arena(struct heap_arena *arena)
{
#ifdef MINGW32
	VirtualFree(arena, ARENA_SIZE, MEM_RELEASE);
#else
	munmap(arena, ARENA_SIZE);
#endif /* MINGW32 */
}

void
sml_heap_init(size_t size)
{
	unsigned int i;

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
		gcstat.probe_threshold = ARENA_SIZE * 4;
	}
#endif /* GCSTAT */

#ifdef GCTIME
	sml_timer_now(gcstat.exec_begin);
#endif /* GCTIME */

	init_alloc_arena(size);

	for (i = HEAP_SLOTSIZE_MIN_LOG2; i <= HEAP_SLOTSIZE_MAX_LOG2; i++) {
		heap_bins[i].arena = NULL; /* new_arena(); */
		heap_bins[i].filled = NULL;
		heap_bins[i].slotsize_bytes = 1U << i;
		if (heap_bins[i].arena)
			init_arena(heap_bins[i].arena, i);
		clear_bin(&heap_bins[i]);
#ifdef MINOR_GC
		heap_bins[i].minor_count = MINOR_COUNT;
#endif /* MINOR_GC */
	}

#ifdef GCSTAT
	stat_notice("---");
	stat_notice("event: init");
	stat_notice("time: 0.0");
	stat_notice("initial_num_arenas: %u", gcstat.initial_num_arenas);
	stat_notice("heap_size: %u", ARENA_SIZE * gcstat.initial_num_arenas);
	stat_notice("config:");
	for (i = HEAP_SLOTSIZE_MIN_LOG2; i <= HEAP_SLOTSIZE_MAX_LOG2; i++)
		stat_notice(" %u: {size: %lu, num_slots: %lu, "
			    "bitmap_size: %lu}",
			    1U << i, (unsigned long)ARENA_SIZE,
			    (unsigned long)arena_layout[i].num_slots,
			    (unsigned long)arena_layout[i].bitmap_size);
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
	unsigned int i;
	struct heap_arena *arena, *next;
#if defined GCTIME && defined MINOR_GC
	sml_time_t t;
#endif /* GCTIME && MINOR_GC */

	for (i = HEAP_SLOTSIZE_MIN_LOG2; i <= HEAP_SLOTSIZE_MAX_LOG2; i++) {
		rewind_arena_list(&heap_bins[i]);
		arena = heap_bins[i].arena;
		while (arena) {
			next = arena->next;
			free_arena(arena);
			arena = next;
		}
	}

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

void
sml_heap_thread_init()
{
}

void
sml_heap_thread_free()
{
}

static int
is_marked(void *obj)
{
	struct heap_arena *arena;
	size_t index;
	heap_bitptr_t b;

	if (!IS_IN_HEAP(obj))
		return 0;

	arena = OBJ_TO_ARENA(obj);
	index = OBJ_TO_INDEX(arena, obj);
	HEAP_BITPTR_INIT(b, BITMAP0_BASE(arena), index);
	return HEAP_BITPTR_TEST(b);
}

#if defined GLOBAL_MARKSTACK
static void *stack[4096];
static void **stack_top = stack;
#elif defined ARENA_MARKSTACK
#else
static unsigned int stack_last;
static void *stack_top = &stack_last;

void stacklist(){
	void *obj = stack_top;
	while (obj != &stack_last) {
		sml_notice("%p", obj);
		obj = *obj_to_stack(obj);
	}
}
#endif /* GLOBAL_MARKSTACK || ARENA_MARKSTACK */

#ifdef GCSTAT
#define GCSTAT_PUSH_COUNT()  (gcstat.last.push_count++)
#else
#define GCSTAT_PUSH_COUNT()
#endif /* GCSTAT */

#if defined MINOR_GC
#define GCSTAT_MARK_COUNT(arena)  ((arena)->live_count++)
#elif defined SWEEP_ARENA
#define GCSTAT_MARK_COUNT(arena)  ((arena)->live_count = 1)
#else
#define GCSTAT_MARK_COUNT(arena)
#endif /* MINOR_GC || SWEEP_ARENA */

#define OBJ_HAS_NO_POINTER(obj) \
	(!(OBJ_TYPE(obj) & OBJTYPE_BOXED) \
	|| (OBJ_TYPE(obj) == OBJTYPE_RECORD \
	    && OBJ_BITMAP(obj)[0] == 0 \
	    && OBJ_NUM_BITMAPS(obj) == 1))

#define MARKBIT(b, index, arena) do {					\
	unsigned int index__ = (index);					\
	ASSERT(HEAP_BITPTR_INDEX((b), BITMAP0_BASE(arena)) == index__);	\
	GCSTAT_MARK_COUNT(arena);					\
	HEAP_BITPTR_SET(b);						\
	if (~HEAP_BITPTR_WORD(b) == 0U) {				\
		unsigned int i__;					\
		for(i__ = 1; i__ < ARENA_RANK; i__++) {			\
			heap_bitptr_t b__;				\
			index__ /= HEAP_BITPTR_WORDBITS;		\
			HEAP_BITPTR_INIT(b__, BITMAP_BASE(arena, i__),	\
					 index__);			\
			HEAP_BITPTR_SET(b__);				\
			if (~HEAP_BITPTR_WORD(b__) != 0U)		\
				break;					\
		}							\
	}								\
} while (0)

struct trace_cls {
	sml_trace_cls fn;
	enum sml_gc_mode mode;
};

#if defined GLOBAL_MARKSTACK
#define STACK_TOP()  (*stack_top)
#define STACK_PUSH(obj, arena, index) do { \
	ASSERT(obj != NULL); \
	GCSTAT_PUSH_COUNT(); \
	*(++stack_top) = (obj); \
} while (0)
#define STACK_POP(topobj)  (stack_top--)
#elif defined ARENA_MARKSTACK
#define STACK_PUSH(obj, arena, index) do { \
	ASSERT(obj != NULL); \
	GCSTAT_PUSH_COUNT(); \
	*(++(arena)->stack) = (obj); \
} while (0)
#else
#define STACK_TOP() (stack_top == &stack_last ? NULL : stack_top)
#define STACK_PUSH(obj, arena, index) do { \
	GCSTAT_PUSH_COUNT(); \
	ASSERT(OBJ_TO_ARENA(obj) == arena); \
	ASSERT(OBJ_TO_INDEX(OBJ_TO_ARENA(obj), obj) == index); \
	ASSERT((arena)->stack[index] == NULL); \
	(arena)->stack[index] = stack_top, stack_top = (obj); \
} while (0)
#define STACK_POP(topobj) do { \
	struct heap_arena *arena__ = OBJ_TO_ARENA(topobj); \
	unsigned int index__ = OBJ_TO_INDEX(arena__, topobj); \
	stack_top = arena__->stack[index__], arena__->stack[index__] = NULL; \
} while (0)
#endif /* GLOBAL_MARKSTACK */

#ifdef MINOR_GC
#if defined GLOBAL_MARKSTACK
static void
flush_stack()
{
	stack_top = stack;
}
#elif defined ARENA_MARKSTACK
static void
flush_stack()
{
	unsigned int i;
	struct heap_arena *arena;

	for (i = HEAP_SLOTSIZE_MIN_LOG2; i <= HEAP_SLOTSIZE_MAX_LOG2; i++) {
		ASSERT(heap_bins[i].filled == NULL);
		for (arena = heap_bins[i].arena; arena; arena = arena->next) {
			arena->stack =
				ADD_OFFSET(arena, arena->layout->stack_offset);
		}
	}
}
#else
static void
flush_stack()
{
	void *obj;
	while ((obj = STACK_TOP()))
		STACK_POP(obj);
}
#endif /* GLOBAL_MARKSTACK || ARENA_MARKSTACK */
#endif /* MINOR_GC */

#ifdef MINOR_GC
void
sml_heap_barrier(void **writeaddr, void *objaddr)
{
	struct heap_arena *arena;
	size_t index;
	heap_bitptr_t b;
	void *obj;

	DBG(("objaddr=%p, writeaddr=%p (%p)", objaddr, writeaddr, *writeaddr));
#ifdef GCSTAT
	gcstat.last.barrier_count.called++;
#endif /* GCSTAT */

	if (!IS_IN_HEAP(writeaddr)) {
		obj = *writeaddr;
		if (!IS_IN_HEAP(obj)) {
			sml_global_barrier(writeaddr, objaddr, MAJOR);
			return;
		}
		arena = OBJ_TO_ARENA(obj);
		index = OBJ_TO_INDEX(arena, obj);
		HEAP_BITPTR_INIT(b, BITMAP0_BASE(arena), index);
		if (HEAP_BITPTR_TEST(b)) {
			sml_global_barrier(writeaddr, objaddr, MAJOR);
			return;
		}
		if (!sml_global_barrier(writeaddr, objaddr, MINOR))
			return;

		/* obj is referenced from outside of heap.
		 * it must be either marked or barriered. */
#ifdef GCSTAT
		gcstat.last.barrier_count.barriered++;
#endif /* GCSTAT */
		DBG(("BARRIER: %p", obj));
		MARKBIT(b, index, arena);
		STACK_PUSH(obj, arena, index);
	} else {
		/* objaddr is destructively updated.
		 * if it is marked, it must be barriered. */
		arena = OBJ_TO_ARENA(objaddr);
		index = OBJ_TO_INDEX(arena, objaddr);
		HEAP_BITPTR_INIT(b, BITMAP0_BASE(arena), index);
		if (!HEAP_BITPTR_TEST(b) || arena->stack[index] != NULL)
			return;
#ifdef GCSTAT
		gcstat.last.barrier_count.barriered++;
#endif /* GCSTAT */
		DBG(("BARRIER: %p", objaddr));
		STACK_PUSH(objaddr, arena, index);
	}
}
#else /* MINOR_GC */
void
sml_heap_barrier(void **writeaddr, void *objaddr)
{
	if (!IS_IN_HEAP(writeaddr))
		sml_global_barrier(writeaddr, objaddr, MAJOR);
}
#endif /* MINOR_GC */

static void
push(void **slot, void *data)
{
	struct trace_cls *cls = (struct trace_cls *)data;
	void *obj = *slot;
	struct heap_arena *arena;
	size_t index;
	heap_bitptr_t b;

	if (!IS_IN_HEAP(obj)) {
		DBG(("%p at %p outside", obj, slot));
		if (obj == NULL)
			return;
		obj = sml_trace_ptr(obj, cls->mode);
		if (obj != NULL)
			sml_obj_enum_ptr(obj, &cls->fn);
		return;
	}

#ifdef GCSTAT
	gcstat.last.trace_count++;
#endif /* GCSTAT */
	arena = OBJ_TO_ARENA(obj);
	index = OBJ_TO_INDEX(arena, obj);
	HEAP_BITPTR_INIT(b, BITMAP0_BASE(arena), index);
	if (HEAP_BITPTR_TEST(b)) {
		DBG(("already marked: %p", obj));
		return;
	}
	MARKBIT(b, index, arena);
	DBG(("MARK: %p", obj));

#ifdef EARLYMARK
	if (OBJ_HAS_NO_POINTER(obj)) {
		DBG(("EARLYMARK: %p", obj));
		return;
	}
#endif /* EARLYMARK */

	STACK_PUSH(obj, arena, index);
	DBG(("PUSH: %p", obj));
}

#ifdef ARENA_MARKSTACK
static void
pop()
{
	unsigned int i, found;
	struct heap_arena *arena;
	void *obj;

	do {
		found = 0;
		for (i = HEAP_SLOTSIZE_MIN_LOG2; i <= HEAP_SLOTSIZE_MAX_LOG2;
		     i++) {
			for (arena = heap_bins[i].filled; arena;
			     arena = arena->next) {
				while ((obj = *arena->stack)) {
					arena->stack--;
					DBG(("POP: %p", obj));
					sml_obj_enum_ptr(obj, push);
					found = 1;
				}
			}
			for (arena = heap_bins[i].arena; arena;
			     arena = arena->next) {
				while ((obj = *arena->stack)) {
					arena->stack--;
					DBG(("POP: %p", obj));
					sml_obj_enum_ptr(obj, push);
					found = 1;
				}
			}
		}
	} while (found);
}

static void
mark_and_pop(void **slot)
{
	push(slot);
	pop();
}

#else /* ARENA_MARKSTACK */

#ifdef MINOR_GC
static void
pop(struct trace_cls *trace_cls)
{
	void *obj;

	while ((obj = STACK_TOP())) {
		DBG(("POP: %p", obj));
		STACK_POP(obj);
		sml_obj_enum_ptr(obj, &trace_cls->fn);
	}
}
#endif /* MINOR_GC */

static void
mark(void **slot, void *data)
{
	struct trace_cls *cls = data;
	struct trace_cls push_cls;
	void *obj = *slot;
	struct heap_arena *arena;
	size_t index;
	heap_bitptr_t b;

#ifndef GLOBAL_MARKSTACK
	ASSERT(STACK_TOP() == NULL);
#endif /* !GLOBAL_MARKSTACK */

	if (!IS_IN_HEAP(obj)) {
		DBG(("%p at %p outside", obj, slot));
		if (obj == NULL)
			return;
		obj = sml_trace_ptr(obj, cls->mode);
		if (obj != NULL)
			sml_obj_enum_ptr(obj, &cls->fn);
		return;
	}

#ifdef GCSTAT
	gcstat.last.trace_count++;
#endif /* GCSTAT */
	arena = OBJ_TO_ARENA(obj);
	index = OBJ_TO_INDEX(arena, obj);
	HEAP_BITPTR_INIT(b, BITMAP0_BASE(arena), index);
	if (HEAP_BITPTR_TEST(b)) {
		DBG(("already marked: %p", obj));
		return;
	}
	MARKBIT(b, index, arena);
	DBG(("MARK: %p", obj));

#ifdef EARLYMARK
	if (OBJ_HAS_NO_POINTER(obj)) {
		DBG(("EARLYMARK: %p", obj));
		return;
	}
#endif /* EARLYMARK */

	push_cls.fn = push;
	push_cls.mode = cls->mode;

	for (;;) {
		sml_obj_enum_ptr(obj, &push_cls.fn);
		obj = STACK_TOP();
		if (obj == NULL) {
			DBG(("MARK END"));
			break;
		}
		STACK_POP(obj);
		DBG(("POP: %p", obj));
	}
}
#endif /* ARENA_MARKSTACK */

static void
sweep_arena()
{
	unsigned int i;
	struct heap_bin *bin;
#ifdef SWEEP_ARENA
	struct heap_arena *arena, **arena_p, **free_p = &alloc_arena.freelist;
#endif /* SWEEP_ARENA */

	for (i = HEAP_SLOTSIZE_MIN_LOG2; i <= HEAP_SLOTSIZE_MAX_LOG2; i++) {
		bin = &heap_bins[i];
#ifdef SWEEP_ARENA
		ASSERT(bin->filled == NULL);

		/* Keep the order of arenas in the list.
		 * This means that allocator always tries to find free
		 * slot from long-life arena. This storategy is good to
		 * gather long-life object in same arena as many as
		 * possible. */
		arena_p = &bin->arena;
		while ((arena = *arena_p)) {
			if (arena->live_count > 0) {
				arena_p = &arena->next;
			} else {
				*arena_p = arena->next;
				/* Arenas in freelist are sorted by slotsize.
				 * Smaller slotsize arena has larger bitmap.
				 * By recycling smaller slotsize arena at
				 * first, we can avoid memset of arena
				 * initialization as many as possible.
				 */
				*free_p = arena;
				free_p = &arena->next;
			}
		}
#endif /* SWEEP_ARENA */
		clear_bin(bin);
#ifdef MINOR_GC
		bin->minor_count = MINOR_COUNT;
#endif /* MINOR_GC */
	}
#ifdef SWEEP_ARENA
	*free_p = NULL;
#endif /* SWEEP_ARENA */
}

#ifdef MINOR_GC
static void
rewind_arena_minor()
{
	unsigned int i, j;
	struct heap_bin *bin;
	struct heap_arena *arena, **arena_p;

	for (i = HEAP_SLOTSIZE_MIN_LOG2; i <= HEAP_SLOTSIZE_MAX_LOG2; i++) {
		bin = &heap_bins[i];

		/* move not-so-filled arenas from bin->filled to bin->arena. */
		arena_p = &bin->filled;
		for (j = 0; *arena_p && j < MINOR_COUNT - bin->minor_count;
		     j++) {
			arena = *arena_p;
			if (arena->live_count == 0) {
				*arena_p = arena->next;
				arena->next = alloc_arena.freelist;
				alloc_arena.freelist = arena;
			}
			else if (arena->live_count
				 < arena->layout->minor_threshold) {
				*arena_p = arena->next;
				arena->next = bin->arena;
				bin->arena = arena;
			} else {
				arena_p = &arena->next;
			}
		}

		/* skip filled arenas */
		while (bin->arena && (bin->arena->live_count
				      == bin->arena->layout->num_slots)) {
			arena = bin->arena;
			bin->arena = bin->arena->next;
			arena->next = bin->filled;
			bin->filled = arena;
		}

		clear_bin(bin);
		bin->minor_count = MINOR_COUNT;
	}
}
#endif /* MINOR_GC */

#if defined DEBUG && defined SURVIVAL_CHECK
static struct {
	sml_tree_t set;
} survival_check;

struct survive_cls {
	sml_trace_cls fn;
	void *parent;
	sml_obstack_t *stack;
};

static int
voidp_cmp(void *x, void *y)
{
	uintptr_t m = (uintptr_t)x, n = (uintptr_t)y;
	if (m < n) return -1;
	else if (m > n) return 1;
	else return 0;
}

static void
survive_trace(void **slot, void *data)
{
	struct survive_cls *cls = data;
	if (*slot == NULL) return;
	if (sml_splay_find(&survival_check.set, *slot) != NULL) return;
	*(sml_splay_insert(&survival_check.set, *slot)) = cls->parent;
	*((void**)sml_obstack_extend(&cls->stack, sizeof(void*))) = *slot;
}

static void
init_check_survival()
{
	struct survive_cls cls;
	void **p;

	survival_check.set.root = NULL;
	survival_check.set.cmp = voidp_cmp;
	survival_check.set.alloc = xmalloc;
	survival_check.set.free = free;
	cls.fn = survive_trace;
	cls.parent = NULL;
	cls.stack = NULL;
	sml_rootset_enum_ptr(&cls.fn, TRY_MAJOR);

	while (cls.stack && sml_obstack_object_size(cls.stack) > 0) {
		p = (void**)sml_obstack_next_free(cls.stack) - 1;
		cls.parent = *p;
		sml_obstack_shrink(&cls.stack, p);
		sml_obj_enum_ptr(cls.parent, &cls.fn);
	}
	sml_obstack_free(&cls.stack, NULL);
}

static unsigned int
check_alive(struct heap_arena *arena)
{
	unsigned int i, bittest, livetest, count = 0;
	heap_bitptr_t b;
	char *p;

	HEAP_BITPTR_INIT(b, BITMAP0_BASE(arena), 0);
	p = SLOT_BASE(arena);
	for (i = 0; i < arena->layout->num_slots; i++) {
		bittest = (HEAP_BITPTR_TEST(b) != 0);
		livetest = (sml_splay_find(&survival_check.set, p) != NULL);
		ASSERT(bittest >= livetest);
		if (bittest > livetest) {
			DBG(("%p is not alive but marked", p));
			count++;
		}
		HEAP_BITPTR_INC(b);
		p += SLOT_SIZE(arena);
	}
	return count;
}

static void
check_survival()
{
	unsigned int i, count = 0;
	struct heap_arena *arena;

	for (i = HEAP_SLOTSIZE_MIN_LOG2; i <= HEAP_SLOTSIZE_MAX_LOG2; i++) {
		for (arena = heap_bins[i].filled; arena; arena = arena->next)
			count += check_alive(arena);
		for (arena = heap_bins[i].arena; arena; arena = arena->next)
			count += check_alive(arena);
	}
	if (count > 0)
		sml_warn(0, "%u objects are not alive but marked.", count);

	sml_tree_delete_all(&survival_check.set);
}

/* for debugger */
void
survival_ancestors(void *obj)
{
	void **v;
	while (obj) {
		sml_notice("%p", obj);
		v = sml_splay_find(&survival_check.set, obj);
		if (v == NULL) {
			sml_notice("*** abort ***");
			return;
		}
		obj = *v;
	}
}
#endif /* DEBUG && SURVIVAL_CHECK */

static void
do_gc(enum sml_gc_mode mode)
{
	struct trace_cls trace_cls;
#ifdef GCSTAT
	sml_time_t cleartime, t;
	sml_timer_t b_cleared;
#endif /* GCSTAT */
#ifdef GCTIME
	sml_timer_t b_start, b_end;
	sml_time_t gctime;
	struct gcstat_gc *gcstat_gc = &gcstat.gc;
#ifdef MINOR_GC
	if (mode == MINOR)
		gcstat_gc = &gcstat.minor_gc;
#endif /* MINOR_GC */
#endif /* GCTIME */

	HEAP_LOCK();

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
#ifdef MINOR_GC
	}
#endif /* MINOR_GC */

#ifdef GCSTAT
	sml_timer_now(b_cleared);
#endif /* GCSTAT */

#ifdef ARENA_MARKSTACK
	trace_cls.fn = push;
	trace_cls.mode = mode;
	sml_rootset_enum_ptr(&trace_cls.fn, mode);
	pop();
#else
#ifdef MINOR_GC
	if (mode == MINOR) {
		trace_cls.fn = push;
		trace_cls.mode = mode;
		pop(&trace_cls);
	}
#endif /* MINOR_GC */
	trace_cls.fn = mark;
	trace_cls.mode = mode;
	sml_rootset_enum_ptr(&trace_cls.fn, mode);
#endif /* ARENA_MARKSTACK */

	/* check finalization */
#ifdef ARENA_MARKSTACK
	trace_cls.fn = mark_and_pop;
	sml_check_finalizer(mode, is_marked, &trace_cls.fn);
#else
	trace_cls.fn = mark;
	sml_check_finalizer(mode, is_marked, &trace_cls.fn);
#endif /* ARENA_MARKSTACK */

#ifdef MINOR_GC
	if (mode == MINOR)
		rewind_arena_minor();
	else
#endif /* MINOR_GC */
		sweep_arena();

	/* sweep malloc heap */
	sml_malloc_sweep(mode);

#ifdef GCTIME
	sml_timer_now(b_end);
#endif /* GCTIME */

	DBG(("gc finished."));

#ifdef DEBUG
	check_bin_consistent();
	scribble_bins();
#endif /* DEBUG */
#if defined DEBUG && defined SURVIVAL_CHECK
	check_survival();
#endif /* DEBUG && SURVIVAL_CHECK */

	HEAP_UNLOCK();

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

#ifdef MINOR_GC
	if (mode != MINOR)
#endif
	/* start finalizers */
	sml_run_finalizer();
}

void
sml_heap_gc()
{
	do_gc(MAJOR);
}

#ifdef DEBUG
static int
check_newobj(void *obj)
{
	struct heap_bin *bin;
	struct heap_arena *arena;
	size_t index;
	heap_bitptr_t b, b2;
	unsigned int i;

	arena = OBJ_TO_ARENA(obj);
	bin = &heap_bins[arena->slotsize_log2];

	/* new object must belong to current arena. */
	ASSERT(bin->arena == arena);

	/* bit pointer boundary check */
	ASSERT(BITMAP0_BASE(arena) <= bin->freebit.ptr
	       && bin->freebit.ptr < BITMAP_LIMIT(arena, 0));

	/* check index */
	index = OBJ_TO_INDEX(arena, obj);
	ASSERT(SLOT_BASE(arena) + (index << arena->slotsize_log2)
	       == (char*)obj);

	/* object address boundary check */
	ASSERT(index < arena->layout->num_slots);

	/* bitmap check */
	HEAP_BITPTR_INIT(b, BITMAP0_BASE(arena), index);
	ASSERT(!HEAP_BITPTR_TEST(b));

	/* bitmap tree check */
	for (i = 1; i < ARENA_RANK; i++) {
		index /= HEAP_BITPTR_WORDBITS;
		HEAP_BITPTR_INIT(b2, BITMAP_BASE(arena, i), index);
		ASSERT((HEAP_BITPTR_WORD(b) == ~0U) ==
		       (HEAP_BITPTR_TEST(b2) != 0));
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
	((unsigned int*)&gcstat.last)[offset]++;
}
#define GCSTAT_ALLOC_COUNT(counter, offset, size)			\
	gcstat_alloc_count((unsigned int*)&gcstat.last.alloc_count.counter \
			    - (unsigned int*)&gcstat.last + (offset), size)
#define GCSTAT_TRIGGER(slogsize_log2) \
	(gcstat.last.trigger = (slotsize_log2))
#define GCSTAT_COUNT_MOVE(counter1, counter2) \
	(gcstat.last.alloc_count.counter1--, \
	 gcstat.last.alloc_count.counter2++)
#else
#define GCSTAT_ALLOC_COUNT(counter, offset, size)
#define GCSTAT_TRIGGER(slogsize_log2)
#define GCSTAT_COUNT_MOVE(counter1, counter2)
#endif /* GCSTAT */

static void *
find_bitmap(struct heap_bin *bin)
{
	unsigned int i, index, *base, *limit, *p;
	struct heap_arena *arena;
	heap_bitptr_t b = bin->freebit;
	void *obj;

	ASSERT(bin->arena != NULL);
	arena = bin->arena;

	HEAP_BITPTR_NEXT(b);
	base = BITMAP0_BASE(arena);

	if (HEAP_BITPTR_NEXT_FAILED(b)) {
		for (i = 1;; i++) {
			if (i >= ARENA_RANK) {
				p = &HEAP_BITPTR_WORD(b) + 1;
				limit = BITMAP_LIMIT(arena, ARENA_RANK - 1);
				b = bitptr_linear_search(p, limit);
				if (HEAP_BITPTR_NEXT_FAILED(b))
					return NULL;
				i = ARENA_RANK - 1;
				break;
			}
			index = HEAP_BITPTR_WORDINDEX(b, base) + 1;
			base = BITMAP_BASE(arena, i);
			HEAP_BITPTR_INIT(b, base, index);
			HEAP_BITPTR_NEXT(b);
			if (!HEAP_BITPTR_NEXT_FAILED(b))
				break;
		}
		do {
			index = HEAP_BITPTR_INDEX(b, base);
			base = BITMAP_BASE(arena, --i);
			HEAP_BITPTR_INIT(b, base + index, 0);
			HEAP_BITPTR_NEXT(b);
			ASSERT(!HEAP_BITPTR_NEXT_FAILED(b));
		} while (i > 0);
	}

	index = HEAP_BITPTR_INDEX(b, base);
	obj = SLOT_BASE(arena) + (index << arena->slotsize_log2);
	ASSERT(OBJ_TO_ARENA(obj) == arena);

	GCSTAT_ALLOC_COUNT(find, arena->slotsize_log2, bin->slotsize_bytes);
	HEAP_BITPTR_INC(b);
	bin->freebit = b;
	bin->free = (char*)obj + bin->slotsize_bytes;

	return obj;
}

static void *
find_arena(struct heap_bin *bin)
{
	struct heap_arena *arena;
	void *obj;

	/* find free slot from following arenas. */
	if (bin->arena) {
		arena = bin->arena;
		for (;;) {
			/* skip current arena. */
			bin->arena = arena->next;
			arena->next = bin->filled;
			bin->filled = arena;
#ifdef MINOR_GC
			if (--bin->minor_count == 0) {
				clear_bin(bin);
				return NULL;
			}
#endif /* MINOR_GC */
			arena = bin->arena;
			if (arena == NULL)
				break;
			clear_bin(bin);
			obj = find_bitmap(bin);
			if (obj) {
				GCSTAT_COUNT_MOVE(find[arena->slotsize_log2],
						  next[arena->slotsize_log2]);
				return obj;
			}
		}
	}

	/* try to allocate new arena */
	bin->arena = new_arena();
	if (bin->arena) {
		init_arena(bin->arena, BIN_TO_SLOTSIZE_LOG2(bin));
		clear_bin(bin);
		ASSERT(!HEAP_BITPTR_TEST(bin->freebit));
		GCSTAT_ALLOC_COUNT(new, BIN_TO_SLOTSIZE_LOG2(bin),
				   bin->slotsize_bytes);
		obj = bin->free;
		HEAP_BITPTR_INC(bin->freebit);
		bin->free += bin->slotsize_bytes;
		return obj;
	}

#ifdef DEBUG
	clear_bin(bin);
#endif /* DEBUG */
	return NULL;
}

SML_PRIMITIVE void *
sml_alloc(unsigned int objsize, void *frame_pointer)
{
	size_t alloc_size;
	unsigned int slotsize_log2;
	struct heap_bin *bin;
	void *obj;

#ifdef GCSTAT
	gcstat.total_alloc_count++;
#endif /* GCSTAT */

	/* ensure that alloc_size is at least HEAP_SLOTSIZE_MIN. */
	alloc_size = ALIGNSIZE(OBJ_HEADER_SIZE + objsize, HEAP_SLOTSIZE_MIN);

	if (alloc_size > HEAP_SLOTSIZE_MAX) {
		GCSTAT_ALLOC_COUNT(malloc, 0, alloc_size);
		sml_save_frame_pointer(frame_pointer);
		return sml_obj_malloc(alloc_size);
	}

	slotsize_log2 = HEAP_CEIL_LOG2(alloc_size);
	ASSERT(HEAP_SLOTSIZE_MIN_LOG2 <= slotsize_log2
	       && slotsize_log2 <= HEAP_SLOTSIZE_MAX_LOG2);

	bin = &heap_bins[slotsize_log2];

	HEAP_LOCK();

	if (!HEAP_BITPTR_TEST(bin->freebit)) {
		GCSTAT_ALLOC_COUNT(fast, slotsize_log2, alloc_size);
		HEAP_BITPTR_INC(bin->freebit);
		obj = bin->free;
		bin->free += bin->slotsize_bytes;
		goto alloced;
	}

	if (bin->arena) {
		obj = find_bitmap(bin);
		if (obj) goto alloced;
	}
	obj = find_arena(bin);
	if (obj) goto alloced;
	sml_save_frame_pointer(frame_pointer);

#ifdef MINOR_GC
	GCSTAT_TRIGGER(slotsize_log2);
	do_gc(MINOR);
	if (bin->arena) {
		obj = find_bitmap(bin);
		if (obj) goto alloced;
	}
	obj = find_arena(bin);
	if (obj) goto alloced;
#endif /* MINOR_GC */

	GCSTAT_TRIGGER(slotsize_log2);
	do_gc(MAJOR);

	if (bin->arena) {
		obj = find_bitmap(bin);
		if (obj) goto alloced;
	}
	obj = find_arena(bin);
	if (obj) goto alloced;

#ifdef GCSTAT
	stat_notice("---");
	stat_notice("event: error");
	stat_notice("heap exceeded: intented to allocate %u bytes.",
		    bin->slotsize_bytes);
	if (gcstat.file)
		fclose(gcstat.file);
#endif /* GCSTAT */
	sml_fatal(0, "heap exceeded: intended to allocate %u bytes.",
		  bin->slotsize_bytes);

 alloced:
	HEAP_UNLOCK();
	ASSERT(check_newobj(obj));
	OBJ_HEADER(obj) = 0;
	return obj;
}
