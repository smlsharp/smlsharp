/*
 * heap_concurrent.c
 * @copyright (c) 2015, Tohoku University.
 * @author UENO Katsuhiro
 */

#include "smlsharp.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <sys/mman.h>
#include <unistd.h>
#ifdef HAVE_CONFIG_H
#ifdef MINGW32
# include <windows.h>
#endif /* MINGW32 */
#endif /* HAVE_CONFIG_H */
#include "object.h"
#include "heap.h"
/* #include "dbglog.h" */

#ifdef GCHIST
#include "dbglog.h"
#include "timer.h"
#endif

#ifdef GCTIME
#include "timer.h"
#endif

/******** segments ********/

#define SEGMENT_SIZE_LOG2  15   /* 32k */
#define SEGMENT_SIZE (1U << SEGMENT_SIZE_LOG2)
#define SEG_RANK  2

#define BLOCKSIZE_MIN_LOG2  3U   /* 2^3 = 8 */
#define BLOCKSIZE_MIN       (1U << BLOCKSIZE_MIN_LOG2)
#define BLOCKSIZE_MAX_LOG2  12U  /* 2^4 = 16 */
#define BLOCKSIZE_MAX       (1U << BLOCKSIZE_MAX_LOG2)

#define NUM_SUBHEAPS (BLOCKSIZE_MAX_LOG2 - BLOCKSIZE_MIN_LOG2 + 1)

/*
 * segment layout:
 *
 * 0000 +------------------------+ 0
 *      | struct segment         |
 *      +------------------------+ BITMAP0_OFFSET (aligned in sml_bmword_t)
 *      | bitmap[0]              | ^
 *      :                        : | N bits + sentinel bits
 *      |                        | V
 *      +------------------------+ bitmap_offset[1]
 *      | bitmap[1]              | ^
 *      :                        : | ceil(N/32) bits + sentinel bits
 *      |                        | V
 *      +------------------------+ bitmap_offset[2]
 *      | collect_bitmap         | ^
 *      :                        : | N bits + sentinel bits
 *      |                        | v
 *      +------------------------+ zerofill_limit
 *      | padding (if needed)    |
 *      +------------------------+ stack_offset (aligned in void*)
 *      | stack area             | ^
 *      |                        | | N pointers
 *      |                        | v
 *      +------------------------+ stack_limit
 *      | padding (if needed)    |
 *      +------------------------+ block_offset (aligned in MAXALIGN
 *      | obj block area         | ^                        - OBJ_HEADER_SIZE)
 *      |                        | | N blocks
 *      |                        | v
 *      +------------------------+ block_limit
 *      : padding                :
 * 8000 +------------------------+
 *
 * N-th bit of bitmap[0] indicates whether N-th block is used (1) or not (0).
 * N-th bit of bitmap[n] indicates whether N-th word of bitmap[n-1] is
 * filled (1) or not (0).
 */
struct segment_layout {
	unsigned int blocksize_log2;
	unsigned int blocksize_bytes;
	unsigned int bitmap_offset[SEG_RANK + 1];
	sml_bmword_t bitmap_sentinel[SEG_RANK];
	unsigned int bitmap_length;
	unsigned int bitmap0_length;
	unsigned int zerofill_limit;
	unsigned int stack_offset;
	unsigned int block_offset;
	unsigned int num_blocks;
	unsigned int block_limit;
};

struct stack_slot {
	void *next;
};

struct segment {
	struct segment *next;
	const struct segment_layout *layout;
	/* トレースの範囲を定めるポインタ．このメンバは複数のスレッドから
	 * 参照されるが，_Atomicでなくてもよい．なぜなら：
	 * (1) GCフェーズが変わると，全てのスレッドが前のフェーズで行った
	 *     メモリ操作は，全てのスレッドからhappened-beforeになる．
	 *     MARKフェーズ中はこのメンバを書き換えないから，SYNC2までで
	 *     行ったこのメンバへの操作は，_Atomicでなくとも全てのスレッドから
	 *     可視である．
	 * (2) SYNC1, SYNC2のとき，ライトバリアのために他のスレッドから
	 *     このメンバが参照される．前回のGCの生き残りならばこのメンバは
	 *     参照されない．今回のGCサイクル中でアロケートされたオブジェクト
	 *     の場合，このメンバの更新はオブジェクトのアロケーションより
	 *     先行する（set_alloc_ptr参照）から，このメンバの更新は
	 *     オブジェクトのアロケーションよりもhappened-beforeである．
	 *     従ってASYNCでアロケートされ共有されたならば，このメンバの
	 *     最新の値が他のスレッドからも見えるはずである．SYNC1からSYNC2
	 *     までの間に共有された場合，他のスレッドから可視になるためには
	 *     その前に破壊的更新が行われているはずであるから，自分のライト
	 *     バリアによって共有オブジェクトのビットが立てられているはず
	 *     である．従って他のスレッドはこのメンバを見ない．*/
	void *allocptr_snapshot;
	unsigned int free_count;
};

static struct segment_layout segment_layout[NUM_SUBHEAPS];

#define BITMAP0_OFFSET \
	CEILING(sizeof(struct segment), sizeof(sml_bmword_t))

#define ADD_BYTES(p,n) \
	((void*)((char*)(p) + (n)))
#define DIF_BYTES(p1,p2) \
	((uintptr_t)((char*)(p1)) - (uintptr_t)((char*)(p2)))

#define BITMAP_BASE(seg, level) \
	((sml_bmword_t*)ADD_BYTES(seg, (seg)->layout->bitmap_offset[level]))
#define BITMAP_LIMIT(seg, level) \
	((sml_bmword_t*)ADD_BYTES(seg, (seg)->layout->bitmap_offset[(level)+1]))
#define BITMAP0_BASE(seg) \
	((sml_bmword_t*)ADD_BYTES(seg, BITMAP0_OFFSET))
#define COLLECT_BITMAP_BASE(seg) \
	((_Atomic(sml_bmword_t)*) \
	 ADD_BYTES(seg, (seg)->layout->bitmap_offset[SEG_RANK]))
#define STACK_BASE(seg) \
	((struct stack_slot *)ADD_BYTES((seg), (seg)->layout->stack_offset))
#define BLOCK_BASE(seg) \
	((char*)ADD_BYTES(seg, (seg)->layout->block_offset))
#define BLOCK_LIMIT(seg) \
	((char*)ADD_BYTES(seg, (seg)->layout->block_limit))

static inline void
compute_segment_layout(unsigned int subheap_index, struct segment_layout *l)
{
	unsigned int i, n, blocksize_log2, blocksize,
		bmoffset[SEG_RANK+1], bmlen[SEG_RANK], bmbits[SEG_RANK],
		bmlimit, stackoffset, stacklimit,
		blockalign, blockoffset, blocklimit;
	blocksize_log2 = subheap_index + BLOCKSIZE_MIN_LOG2;
	blocksize = 1 << blocksize_log2;
	/* 1 + 1/32 + 1/32/32 + ... = 32/31 */
	n = (SEGMENT_SIZE - BITMAP0_OFFSET)
		/ (blocksize + sizeof(struct stack_slot)
		   + BITPTR_WORDBITS / (BITPTR_WORDBITS - 1) / 8
		   + 1.0f / 8.0f
		   );
	for (;; n--) {
		bmoffset[0] = BITMAP0_OFFSET;
		bmlen[0] = n;
		bmbits[0] = CEILING(bmlen[0] + 1, BITPTR_WORDBITS);
		bmlimit = bmoffset[0] + bmbits[0] / 8;
		for (i = 1; i < SEG_RANK; i++) {
			bmoffset[i] = bmlimit;
			bmlen[i] = bmbits[i - 1] / BITPTR_WORDBITS;
			bmbits[i] = CEILING(bmlen[i] + 1, BITPTR_WORDBITS);
			bmlimit += bmbits[i] / 8;
		}
		bmoffset[SEG_RANK] = bmlimit;
		bmlimit += bmbits[0] / 8;
		stackoffset = CEILING(bmlimit, alignof(struct stack_slot));
		stacklimit = stackoffset + sizeof(struct stack_slot) * n;
		blockalign = MAXALIGN < blocksize ? MAXALIGN : blocksize;
		blockoffset = CEILING(stacklimit + OBJ_HEADER_SIZE, blockalign);
		blocklimit = blockoffset + blocksize * n;
		if (blocklimit <= SEGMENT_SIZE)
			break;
	}
	l->blocksize_log2 = blocksize_log2;
	l->blocksize_bytes = blocksize;
	for (i = 0; i < SEG_RANK; i++) {
		l->bitmap_offset[i] = bmoffset[i];
		l->bitmap_sentinel[i] =
			-1 << (BITPTR_WORDBITS - (bmbits[i] - bmlen[i]));
	}
	l->bitmap_offset[SEG_RANK] = bmoffset[SEG_RANK];
	l->bitmap_length = bmoffset[SEG_RANK] - bmoffset[0];
	l->bitmap0_length = bmbits[0] / 8;
	l->stack_offset = stackoffset;
	l->zerofill_limit = bmlimit;
	l->block_offset = blockoffset;
	l->num_blocks = n;
	l->block_limit = blocklimit;

	DEBUG(sml_debug("- blocksize_log2: %u\n"
			"  blocksize_bytes: %u\n"
			"  num_blocks: %u\n"
			"  bitmap_offset: [%u, %u, %u]\n"
			"  bitmap_sentinel: [0x%08x, 0x%08x]\n"
			"  stack_offset: %u\n"
			"  bitmap_length: %u\n"
			"  bitmap0_length: %u\n"
			"  zerofill_limit: %u\n"
			"  block_offset: %u\n"
			"  block_limit: %u\n",
			l->blocksize_log2, l->blocksize_bytes, l->num_blocks,
			l->bitmap_offset[0], l->bitmap_offset[1],
			l->bitmap_offset[2],
			l->bitmap_sentinel[0], l->bitmap_sentinel[1],
			l->bitmap_length,
			l->bitmap0_length,
			l->stack_offset, l->zerofill_limit,
			l->block_offset, l->block_limit));
}

static void
init_segment_layout()
{
	unsigned int i;
	for (i = 0; i < NUM_SUBHEAPS; i++)
		compute_segment_layout(i, &segment_layout[i]);
}

/* assume that segment address is a multiple of SEGMENT_SIZE */
static inline struct segment *
segment_addr(const void *p)
{
	return (void*)((uintptr_t)p & ~((uintptr_t)(SEGMENT_SIZE - 1)));
}

static inline unsigned int
object_index(struct segment *seg, void *obj)
{
	assert(segment_addr(obj) == seg || obj == ADD_BYTES(seg, SEGMENT_SIZE));
	assert((char*)obj >= BLOCK_BASE(seg));
	assert((char*)obj <= (char*)seg + SEGMENT_SIZE);
	return DIF_BYTES(obj, BLOCK_BASE(seg)) >> seg->layout->blocksize_log2;
}

static ATTR_UNUSED void
scribble_segment(struct segment *seg, void *from)
{
	char *block = BLOCK_BASE(seg);
	sml_bitptr_t b = BITPTR(BITMAP0_BASE(seg), 0);
	unsigned int i;

	for (i = 0; i < seg->layout->num_blocks; i++) {
		if (!BITPTR_TEST(b) && (char*)from <= block)
			memset(block - OBJ_HEADER_SIZE, 0x55,
			       seg->layout->blocksize_bytes);
		BITPTR_INC(b);
		block += seg->layout->blocksize_bytes;
	}
}

/* for debug */
static ATTR_UNUSED int
check_filled(const void *buf, unsigned char c, size_t n)
{
	const unsigned char *p;
	for (p = buf; n > 0; p++, n--) {
		if (*p != c)
			return 0;
	}
	return 1;
}

static void
init_segment(struct segment *seg, unsigned int subheap_index)
{
	const struct segment_layout *new_layout;
	unsigned int blocksize_log2, i;
	char *old_limit, *new_limit;

	blocksize_log2 = subheap_index + BLOCKSIZE_MIN_LOG2;
	assert(BLOCKSIZE_MIN_LOG2 <= blocksize_log2
	       && blocksize_log2 <= BLOCKSIZE_MAX_LOG2);
	new_layout = &segment_layout[subheap_index];

	/* if seg is already initialized for new_layout, do nothing. */
	if (seg->layout == new_layout)
		return;

	if (seg->layout) {
		/* assumption: seg is initialized for some block size with its
		 * bitmap and stack area (including padding between them) being
		 * filled with zero except for bitmap sentinels.
		 * (We also assume that NULL is equal to zero)
		 */

		/* clear old sentinels */
		for (i = 0; i < SEG_RANK; i++)
			BITMAP_LIMIT(seg, i)[-1] = 0;

		/* clear the bitmap and stack area for the new block size by
		 * filling the difference between old and new zerofill_limit
		 * with zero.
		 */
		old_limit = ADD_BYTES(seg, seg->layout->zerofill_limit);
		new_limit = ADD_BYTES(seg, new_layout->zerofill_limit);
		if (new_limit > old_limit)
			memset(old_limit, 0, new_limit - old_limit);
	}

	assert(check_filled(BITMAP0_BASE(seg), 0,
			    new_layout->zerofill_limit - BITMAP0_OFFSET));

	seg->layout = new_layout;
	seg->allocptr_snapshot = BLOCK_BASE(seg);
	seg->free_count = new_layout->num_blocks;

	/* set new sentinels */
	for (i = 0; i < SEG_RANK; i++)
		BITMAP_LIMIT(seg, i)[-1] = new_layout->bitmap_sentinel[i];

	DEBUG(scribble_segment(seg, BLOCK_BASE(seg)));
}

static void
clear_collect_bitmap(struct segment *seg)
{
	memset(COLLECT_BITMAP_BASE(seg), 0, seg->layout->bitmap0_length);
}

static sml_bmword_t
copy_collect_bitmap(struct segment *seg)
{
	/* copy collect_bitmap to bitmap[0] with adding sentinel */
	memcpy(BITMAP0_BASE(seg), COLLECT_BITMAP_BASE(seg),
	       seg->layout->bitmap0_length);
	BITMAP_LIMIT(seg, 0)[-1] |= seg->layout->bitmap_sentinel[0];

	/* construct bitmap[1] or upper */
	sml_bmword_t *lower = BITMAP0_BASE(seg);
	sml_bmword_t *upper = BITMAP_LIMIT(seg, 0);
	sml_bmword_t orb = 0, andb = -1;
	unsigned int i;
	for (i = 1; i < SEG_RANK; i++) {
		sml_bmword_t *limit = upper;
		sml_bmword_t bit = 1;
		sml_bmword_t word = 0;
		assert(upper == BITMAP_BASE(seg, i));
		assert(limit == BITMAP_LIMIT(seg, i - 1));
		while (lower < limit) {
			orb |= *lower, andb &= *lower;
			if (*lower == -1U)
				word |= bit;
			lower++;
			bit <<= 1;
			if (bit == 0) {
				*(upper++) = word;
				word = 0;
				bit = 1;
			}
		}
		*(upper++) = word | seg->layout->bitmap_sentinel[i];
	}

	/* -1 : filled, 0 : empty, 1 : partial */
	return andb == orb ? andb : 1;
}

struct stat_segment {
	unsigned int num_marked;
	unsigned int num_unmarked;
	unsigned int num_marked_before_allocptr;
	unsigned int num_unmarked_before_allocptr;
};

static struct stat_segment
stat_segment(const struct segment *seg, void *allocptr)
{
	sml_bitptr_t b = BITPTR(BITMAP0_BASE(seg), 0);
	char *block = BLOCK_BASE(seg);
	struct stat_segment stat = {0, 0, 0, 0};
	unsigned int i;

	for (i = 0; i < seg->layout->num_blocks; i++) {
		if (BITPTR_TEST(b)) {
			stat.num_marked++;
			if (block < (char*)allocptr)
				stat.num_marked_before_allocptr++;
		} else {
			stat.num_unmarked++;
			if (block < (char*)allocptr)
				stat.num_unmarked_before_allocptr++;
		}
		BITPTR_INC(b);
		block += seg->layout->blocksize_bytes;
	}
	return stat;
}

static void
stat_segment_add(struct stat_segment *s1, struct stat_segment s2)
{
	s1->num_marked += s2.num_marked;
	s1->num_unmarked += s2.num_unmarked;
	s1->num_marked_before_allocptr += s2.num_marked_before_allocptr;
	s1->num_unmarked_before_allocptr += s2.num_unmarked_before_allocptr;
}

struct segment_list {
	struct segment *head;
	struct segment **last;
};

#define LIST_INIT(list) \
	(void)((list)->head = NULL, (list)->last = &(list)->head)
#define LIST_APPEND(list, item) \
	(void)(*(list)->last = (item), (list)->last = &(item)->next)
#define LIST_FINISH(list, item) \
	(*(list)->last = (item), (list)->head)
#define LIST_INIT_WITH(list, items) do { \
	(list)->head = (items); \
	(list)->last = &(list)->head; \
	while (*(list)->last) \
		(list)->last = &(*(list)->last)->next; \
} while (0)
#define LIST_CONCAT(list1, list2) do { \
	if ((list2)->head) { \
		*(list1)->last = (list2)->head; \
		(list1)->last = (list2)->last; \
	} \
} while (0)

static void
segment_push_list(_Atomic(struct segment *) *stack, struct segment_list *list)
{
	struct segment *old;
	if (!list->head)
		return;
	old = load_acquire(stack);
	do {
		*list->last = old;
	} while (!cmpswap_weak_acq_rel(stack, &old, list->head));
}

static void
segment_push(_Atomic(struct segment *) *stack, struct segment *item)
{
	struct segment *old;
	old = load_acquire(stack);
	do {
		item->next = old;
	} while (!cmpswap_weak_acq_rel(stack, &old, item));
}

static struct segment *
segment_pop(_Atomic(struct segment *) *stack)
{
	struct segment *old;
	old = load_acquire(stack);
	do {
		if (!old)
			break;
	} while (!cmpswap_acq_rel(stack, &old, old->next));
	return old;
}

/******** malloc segments ********/

struct malloc_segment {
	struct malloc_segment *next;
	struct stack_slot stack;
	sml_bmword_t bit; /* indicates whether allocated before SYNC2 */
	_Atomic(sml_bmword_t) collect_bit;
};

#define MALLOC_OBJECT_OFFSET \
	CEILING(sizeof(struct malloc_segment) + OBJ_HEADER_SIZE, MAXALIGN)
#define OBJ_TO_MALLOC_SEGMENT(obj) \
	((struct malloc_segment *)ADD_BYTES(obj, -MALLOC_OBJECT_OFFSET))
#define MALLOC_SEGMENT_TO_OBJ(mseg) \
	ADD_BYTES(mseg, MALLOC_OBJECT_OFFSET)
#define MALLOC_SEGMENT_SIZE(mseg) \
	(MALLOC_OBJECT_OFFSET \
	 + OBJ_TOTAL_SIZE(MALLOC_SEGMENT_TO_OBJ(mseg)) \
	 - OBJ_HEADER_SIZE)

static struct malloc_segment *
malloc_segment(unsigned int alloc_size)
{
	struct malloc_segment *mseg;

	mseg = xmalloc(MALLOC_OBJECT_OFFSET + alloc_size);
	DEBUG(memset(mseg, 0x55, MALLOC_OBJECT_OFFSET + alloc_size));
	mseg->stack.next = NULL;
	mseg->bit = (sml_current_phase() <= PRESYNC2);
	mseg->collect_bit = 0;
	return mseg;
}

static void
free_malloc_segment(struct malloc_segment *mseg)
{
	DEBUG(memset(mseg, 0x55, MALLOC_SEGMENT_SIZE(mseg)));
	free(mseg);
}

struct malloc_segment_list {
	struct malloc_segment *head;
	struct malloc_segment **last;
};

/******** memory ********/

struct memory {
	void *begin;
	size_t count;
	_Atomic(size_t) alloced;
	size_t pagesize;
};

static void
init_memory(struct memory *memory, size_t max_size)
{
	memory->pagesize = GetPageSize();
	if (SEGMENT_SIZE % memory->pagesize != 0)
		sml_fatal(0, "SEGMENT_SIZE is not aligned in page size.");

	size_t bytes = CEILING(max_size, SEGMENT_SIZE);
	void *p = AllocPage((void*)0x400000000, bytes + SEGMENT_SIZE);
	if (p == AllocPageError)
		sml_sysfatal("failed to allocate memory");
	size_t gap = (uintptr_t)p & (SEGMENT_SIZE - 1);
	if (gap == 0) {
		ReleasePage(ADD_BYTES(p, bytes), SEGMENT_SIZE);
	} else {
		ReleasePage(p, SEGMENT_SIZE - gap);
		p = ADD_BYTES(p, SEGMENT_SIZE - gap);
		ReleasePage(ADD_BYTES(p, bytes), gap);
	}

	memory->begin = p;
	memory->count = bytes / SEGMENT_SIZE;
}

static struct segment *
allocate_segment(struct memory *memory, size_t limit)
{
	size_t n = load_relaxed(&memory->alloced);
	do {
		if (n >= (limit < memory->count ? limit : memory->count))
			return NULL;
	} while (!cmpswap_weak_relaxed(&memory->alloced, &n, n + 1));

	return ADD_BYTES(memory->begin, n * SEGMENT_SIZE);
}

/******** segment pool ********/

struct subpool {
	struct segment *filled;
	_Atomic(struct segment *) partial;
	_Atomic(struct segment *) partial_marked;
};

struct segment_pool {
	struct subpool subpool[NUM_SUBHEAPS];
	struct malloc_segment *malloc_subpool;
	_Atomic(struct segment *) freelist;
	struct memory memory;
	unsigned int min_num_segments;
	unsigned int max_num_segments;
} segment_pool;

static void
init_segment_pool(size_t min_size, size_t max_size)
{
	unsigned int i;

	init_memory(&segment_pool.memory, max_size);

	min_size = CEILING(min_size, SEGMENT_SIZE);
	max_size = CEILING(max_size, SEGMENT_SIZE);

	segment_pool.min_num_segments = min_size / SEGMENT_SIZE;
	segment_pool.max_num_segments = segment_pool.memory.count;

	atomic_init(&segment_pool.freelist, NULL);
	for (i = 0; i < NUM_SUBHEAPS; i++) {
		segment_pool.subpool[i].filled = NULL;
		atomic_init(&segment_pool.subpool[i].partial, NULL);
		atomic_init(&segment_pool.subpool[i].partial_marked, NULL);
	}
}

static struct segment *
get_segment_from_pool(struct segment_pool *pool, unsigned int subheap_index,
		      enum sml_sync_phase phase)
{
	struct subpool *subpool;
	struct segment *seg;

	assert(subheap_index <= NUM_SUBHEAPS);
	subpool = &pool->subpool[subheap_index];

	/* このスレッドのフェーズがASYNCのとき，このスレッドが占有する
	 * セグメントのcollect_bitmapはクリア済みなので，segment poolから
	 * 取得するセグメントのcollect bitmapもまたクリア済みで
	 * なければならない．ASYNCのとき，collect bitmapがクリア済みの
	 * セグメントはpartialに，そうでないセグメントはpartial_markedにある．
	 * まずpartialからセグメントの取得を試みる．partialが空なら
	 * partial_markedからセグメントを取得し，collect bitmapを
	 * クリアする．
	 * このスレッドのフェーズがASYNCでないとき，全てのセグメントの
	 * コレクトビットマップは使用中である．従ってpartialとpartial_marked
	 * のどちらからセグメントを取っても全体として整合する．partial_marked
	 * が使用されているのは，ASYNCを除けばMARKかPREASYNCのときのみなので，
	 * この2つの場合のみpartial_markedを見ればよい．*/
	seg = segment_pop(&subpool->partial);
	if (seg) {
//DBG("get_segment_from_pool %u partial seg=%p", subheap_index, seg);
		return seg;
}
	if (phase == MARK || phase == ASYNC || phase == PREASYNC) {
		seg = segment_pop(&subpool->partial_marked);
		if (seg) {
			if (sml_current_phase() == ASYNC) {
				copy_collect_bitmap(seg);
				clear_collect_bitmap(seg);
			}
//DBG("get_segment_from_pool %u partial_marked seg=%p", subheap_index, seg);
			return seg;
		}
	}

	/* サブプールからセグメントを取るのに失敗した場合（サブプールに
	 * セグメントが無いか，partialからpartial_markedへの移動中に両方とも
	 * 空になる一瞬を突いたとき），freelistからのセグメント取得を
	 * 試みる．*/
	seg = segment_pop(&pool->freelist);
	if (seg) {
//DBG("get_segment_from_pool %u freelist seg=%p", subheap_index, seg);
		init_segment(seg, subheap_index);
		return seg;
	}

	/* freelistにもセグメントが無いとき，新しくセグメントを割り当てて
	 * ヒープを拡張する．*/
	seg = allocate_segment(&pool->memory, pool->memory.count);
	if (seg) {
//DBG("get_segment_from_pool %u allocate seg=%p", subheap_index, seg);
		init_segment(seg, subheap_index);
		return seg;
	}

	return NULL;
}

/******** allocation pointer ********/

struct alloc_ptr {
	sml_bitptr_t b;
	void *p;
	unsigned int blocksize_bytes;
};

/* use b.ptr instead of free because p may point outside */
#define ALLOC_PTR_TO_SEGMENT(alloc_ptr) \
	segment_addr((alloc_ptr)->b.ptr)

static const unsigned int dummy_bitmap = ~0U;
static const sml_bitptr_t dummy_bitptr = { (unsigned int *)&dummy_bitmap, 1 };

static void
clear_alloc_ptr(struct alloc_ptr *ptr)
{
	ptr->b = dummy_bitptr;
	ptr->p = NULL;
}

static void
init_alloc_ptr(struct alloc_ptr *ptr, unsigned int blocksize_log2)
{
	ptr->blocksize_bytes = 1U << blocksize_log2;
	clear_alloc_ptr(ptr);
}

static void
set_alloc_ptr(struct alloc_ptr *ptr, struct segment *seg,
	      enum sml_sync_phase phase)
{
	ptr->b = BITPTR(BITMAP0_BASE(seg), 0);
	ptr->p = BLOCK_BASE(seg);
	assert(ptr->blocksize_bytes == seg->layout->blocksize_bytes);
	DEBUG(seg->next = (void*)-1);
	assert(seg->allocptr_snapshot == BLOCK_BASE(seg));
	if (ASYNC <= phase && phase <= PRESYNC2) {
		/* まだsync2アクション（アロケーションポインタのスナップ
		 * ショットを取る）を行っていない．スナップショットが取られる
		 * のはこのセグメントの中か，あるいはこれよりも後のセグメント
		 * である．このセグメントにこれからアロケートされるオブジェク
		 * トのうち，ルートセットから到達できるオブジェクトはGCの対象
		 * である．visitが正しく働くように，allocptr_snapshotを
		 * セグメント末尾に設定する．*/
		seg->allocptr_snapshot = BLOCK_LIMIT(seg);
//DBG("set_alloc_ptr %p", seg->allocptr_snapshot);
	}
}

static struct segment *
release_alloc_ptr(struct alloc_ptr *ptr, enum sml_sync_phase phase)
{
	//enum sml_sync_phase phase = sml_current_phase();
	struct segment *seg = ALLOC_PTR_TO_SEGMENT(ptr);

	assert(ptr->p != NULL);
	assert(seg->next == (void*)-1);
	if (ASYNC <= phase && phase <= PRESYNC2) {
		/* まだsync2アクション（アロケーションポインタのスナップ
		 * ショットを取る）を行っていない．スナップショットが取られる
		 * のはこのセグメントよりも後のセグメントであるから，
		 * allocptr_snapshotをセグメント末尾に設定する．*/
		seg->allocptr_snapshot = BLOCK_LIMIT(seg);
//DBG("release_alloc_ptr %p", seg->allocptr_snapshot);
	}
	clear_alloc_ptr(ptr);
	return seg;
}

static void
save_alloc_ptr(struct alloc_ptr *ptr)
{
	struct segment *seg;
	if (ptr->p) {
		seg = ALLOC_PTR_TO_SEGMENT(ptr);
		seg->allocptr_snapshot = ptr->p;
//DBG("save_alloc_ptr %p", ptr->p);
	}
}

/******** subheap ********/

struct subheap {
	struct segment *filled;
	struct segment *partial;
};

struct subheap_count {
	int threshold;
	unsigned int extension_room;
	double threshold_ratio;
	double allocspeed_ratio;
#if 0
	unsigned int num_unmarked_before_allocptr;
#endif
};

struct heap {
	struct alloc_ptr ptr[NUM_SUBHEAPS];
	struct subheap subheap[NUM_SUBHEAPS];
	struct subheap_count count[NUM_SUBHEAPS];
	struct malloc_segment *malloc_subheap;
};

struct subheap_count subheap_count_init[NUM_SUBHEAPS];

static void
init_subheap_count_init()
{
	unsigned int i, num_blocks_total = 0;

	for (i = 0; i < NUM_SUBHEAPS; i++)
		num_blocks_total += segment_layout[i].num_blocks;

	for (i = 0; i < NUM_SUBHEAPS; i++) {
		struct subheap_count *count = &subheap_count_init[i];
		count->allocspeed_ratio =
			(double)segment_layout[i].num_blocks / num_blocks_total;
		count->extension_room =
			segment_pool.min_num_segments * count->allocspeed_ratio;
		if (count->extension_room <= 0)
			count->extension_room = 1;
		count->threshold_ratio = 0.5;
		count->threshold = (count->extension_room + 1) / 2;
#if 0
		count->num_unmarked_before_allocptr = 0;
#endif
	}
}

static void
init_heap(struct heap *heap)
{
	unsigned int i;

	for (i = 0; i < NUM_SUBHEAPS; i++) {
		init_alloc_ptr(&heap->ptr[i], i + BLOCKSIZE_MIN_LOG2);
		heap->subheap[i].filled = NULL;
		heap->subheap[i].partial = NULL;
		heap->count[i] = subheap_count_init[i];
	}
	heap->malloc_subheap = NULL;
}

static void
take_allocptr_snapshot(struct heap *heap)
{
	unsigned int i;
	for (i = 0; i < NUM_SUBHEAPS; i++)
		save_alloc_ptr(&heap->ptr[i]);
}

struct stat_subheap {
	unsigned int num_filled;
	unsigned int num_current;
	unsigned int num_partial;
	struct stat_segment total;
};

static struct stat_subheap
stat_subheap(const struct subheap *subheap, const struct alloc_ptr *ptr)
{
	struct segment *seg;
	struct stat_subheap st = {0, 0, 0, {0, 0, 0, 0}};

	for (seg = subheap->filled; seg; seg = seg->next) {
		st.num_filled++;
		stat_segment_add(&st.total,
				 stat_segment(seg, BLOCK_LIMIT(seg)));
	}
	if (ptr && ptr->p) {
		st.num_current++;
		seg = ALLOC_PTR_TO_SEGMENT(ptr);
		stat_segment_add(&st.total, stat_segment(seg, ptr->p));
	}
	for (seg = subheap->partial; seg; seg = seg->next) {
		st.num_partial++;
		stat_segment_add(&st.total,
				 stat_segment(seg, BLOCK_BASE(seg)));
	}
	return st;
}

static void
print_heap_summary(const struct heap *heap)
{
	unsigned int i, num_malloc = 0, num_malloc_bytes = 0;
	unsigned int num_segments = 0;
	unsigned int num_total_blocks = 0, num_filled_blocks = 0;
	struct stat_subheap st;
	const struct subheap_count *count;
	struct malloc_segment *mseg;

//	sml_notice("heap usage summary:");
	for (i = 0; i < NUM_SUBHEAPS; i++) {
		count = &heap->count[i];
		st = stat_subheap(&heap->subheap[i], &heap->ptr[i]);
		sml_notice("subheap %2u: %4u|%1u|%4u(%4u|%4d|%4.2f) segs, "
			   "%7u/%7u blks filled %4.2f",
			   i + BLOCKSIZE_MIN_LOG2,
			   st.num_filled, st.num_current, st.num_partial,
			   count->extension_room, count->threshold,
			   count->threshold_ratio,
			   st.total.num_marked
			   + st.total.num_unmarked_before_allocptr,
			   st.total.num_marked + st.total.num_unmarked,
			   count->allocspeed_ratio);
		num_segments += st.num_filled + st.num_current + st.num_partial;
		num_filled_blocks += st.total.num_marked
			+ st.total.num_unmarked_before_allocptr;
		num_total_blocks += st.total.num_marked + st.total.num_unmarked;
	}
	sml_notice("%d segments (%5.2f MB); block utilization : %u / %u (%6.2f%%)",
		   num_segments,
		   (double)num_segments * SEGMENT_SIZE / 1024 / 1024,
		   num_filled_blocks, num_total_blocks,
		   (double)num_filled_blocks / num_total_blocks * 100.0);
	for (mseg = heap->malloc_subheap; mseg; mseg = mseg->next) {
		num_malloc++;
		num_malloc_bytes += MALLOC_SEGMENT_SIZE(mseg);
	}
	sml_notice("subheap malloc: %5u segments, %8u bytes in total",
		   num_malloc, num_malloc_bytes);
}

/******** allocator ********/

struct sml_alloc {
	struct heap heap;
	void *root_set;
	_Atomic(void *) remembered_set;
};

worker_tlv_alloc(struct sml_alloc *, current_allocator, (void));

static void
init_allocator(struct sml_alloc *alloc)
{
	init_heap(&alloc->heap);
	alloc->root_set = NULL;
	atomic_init(&alloc->remembered_set, NULL);
}

static NOINLINE void *find_bitmap(struct alloc_ptr *ptr);

struct sml_heap_worker_init
sml_heap_worker_init(size_t extra_allocsize)
{
	struct sml_alloc *alloc;
	void *memory;
	size_t offset, allocsize;
	unsigned int blocksize_log2, subheap_index;
	struct segment *seg;

	/* メモリの使用効率を高めるため，ワーカーコンテキストとユーザー
	 * コンテキストも同じメモリ領域にアロケートする．extra_allocsizeは
	 * それらのサイズの合計である．2つのコンテキストに続いてアロケータを
	 * アロケートする．*/
	offset = CEILING(extra_allocsize, alignof(struct sml_alloc));
	allocsize = OBJ_HEADER_SIZE + offset + sizeof(struct sml_alloc);
	blocksize_log2 = CEIL_LOG2(allocsize);
	assert(BLOCKSIZE_MIN_LOG2 <= blocksize_log2
	       && blocksize_log2 <= BLOCKSIZE_MAX_LOG2);
	subheap_index = blocksize_log2 - BLOCKSIZE_MIN_LOG2;

	/* セグメントの確保をDUMMY_PHASEで行う．これによってフェーズ依存の
	 * 処理を避ける．partial_markedを見に行かなくなる分だけ，プールされた
	 * セグメントの再利用をしなくなる．*/
	seg = get_segment_from_pool(&segment_pool, subheap_index, DUMMY_PHASE);
	if (seg) {
		struct alloc_ptr ptr;
		init_alloc_ptr(&ptr, blocksize_log2);
		/* セグメントのセットもDUMMY_PHASEで行う．これによりフェーズの
		 * 進行上正しいallocptr_snapshotがセットされなくなる．しかし
		 * まだスレッドローカルなオブジェクトしかアロケートしていない
		 * ため，他のスレッドは誰もこのallocptr_snapshotを見ないので
		 * 安全である．この不整合はユーザーによるアロケーションが始まる
		 * 前に，sml_heap_worker_registerで是正する */
		set_alloc_ptr(&ptr, seg, DUMMY_PHASE);
		/* 新しいセグメントを取得したので，find_bitmapは必ず成功する */
		memory = find_bitmap(&ptr);
		assert(memory != NULL);
		OBJ_HEADER(memory) = allocsize;
		alloc = ADD_BYTES(memory, offset);
		init_allocator(alloc);
		alloc->heap.ptr[subheap_index] = ptr;
		return ((struct sml_heap_worker_init)
			{.alloc = alloc, .memory = memory});
	}

	return ((struct sml_heap_worker_init){.alloc = NULL, .memory = NULL});
}

void
sml_heap_worker_register(struct sml_alloc *alloc, enum sml_sync_phase phase)
{
	struct alloc_ptr *ptr;
	struct segment *seg;
	unsigned int i;

	for (i = 0; i < NUM_SUBHEAPS; i++) {
		ptr = &alloc->heap.ptr[i];
		/* sml_heap_worker_initおよびsml_try_allocでDUMMY_PHASEを使って
		 * アロケートしたために起こったallocptr_snapshotの不整合を
		 * 是正する．現在のフェーズがPRESYNC2より前なら，
		 * allocptr_snapshotはセグメント末尾を指していなければ
		 * ならない */
		if (ptr->p && ASYNC <= phase && phase <= PRESYNC2) {
			seg = ALLOC_PTR_TO_SEGMENT(ptr);
			seg->allocptr_snapshot = BLOCK_LIMIT(seg);
		}
	}

	worker_tlv_set(current_allocator, alloc);
}

void
sml_heap_worker_kill(struct sml_alloc *alloc)
{
	struct segment_list l1, l2;
	struct malloc_segment_list m;
	unsigned int i;
	struct segment_pool *pool = &segment_pool;

	for (i = 0; i < NUM_SUBHEAPS; i++) {
		struct subheap *subheap = &alloc->heap.subheap[i];
		struct alloc_ptr *ptr = &alloc->heap.ptr[i];
		struct subpool *subpool = &pool->subpool[i];
		LIST_INIT_WITH(&l1, subheap->filled);
		if (ptr->p) {
			struct segment *seg = ALLOC_PTR_TO_SEGMENT(ptr);
			LIST_APPEND(&l1, seg);
		}
		LIST_INIT_WITH(&l2, subheap->partial);
		LIST_CONCAT(&l1, &l2);
		subheap->filled = NULL;
		subheap->partial = NULL;
		clear_alloc_ptr(ptr);
//*l1.last = NULL;
//for (struct segment *seg = l1.head; seg; seg = seg->next)
//DBG("sml_heap_worker_kill segment=%p", seg);
		subpool->filled = LIST_FINISH(&l1, subpool->filled);
	}

	LIST_INIT_WITH(&m, alloc->heap.malloc_subheap);
	pool->malloc_subpool = LIST_FINISH(&m, pool->malloc_subpool);
}

/******** tracing ********/

static struct stack_slot *
object_stack_slot(void *obj)
{
	struct segment *seg;
	struct malloc_segment *mseg;

	if (obj == NULL)
		return NULL;
	if (OBJ_HEADER(obj) & OBJ_FLAG_SKIP)
		return NULL;
	if (OBJ_TOTAL_SIZE(obj) > BLOCKSIZE_MAX) {
		mseg = OBJ_TO_MALLOC_SEGMENT(obj);
		return &mseg->stack;
	} else {
		seg = segment_addr(obj);
		return &STACK_BASE(seg)[object_index(seg, obj)];
	}
}

static struct stack_slot *
visit(void *obj)
{
	struct malloc_segment *mseg;
	struct segment *seg;
	unsigned int index;
	sml_bitptr_t r;
	sml_bitptra_t b;

//if (obj && OBJ_HEADER(obj) == 0x55555555)
//abort();
	if (obj == NULL || (OBJ_HEADER(obj) & OBJ_FLAG_SKIP))
		return NULL;
	if (OBJ_TOTAL_SIZE(obj) > BLOCKSIZE_MAX) {
		mseg = OBJ_TO_MALLOC_SEGMENT(obj);
		if (!mseg->bit)
			return NULL;
		b = BITPTRA(&mseg->collect_bit, 0);
		if (BITPTRA_TEST_AND_SET(b))
			return NULL;
		return &mseg->stack;
	} else {
		seg = segment_addr(obj);
		index = object_index(seg, obj);
		r = BITPTR(BITMAP0_BASE(seg), index);
		if (!BITPTR_TEST(r)
		    && (char*)obj >= (char*)seg->allocptr_snapshot)
//{DBG("visit not gc target %p", obj);
			return NULL;
//}
		b = BITPTRA(COLLECT_BITMAP_BASE(seg), index);
		if (BITPTRA_TEST_AND_SET(b))
//{DBG("visit already visited %p", obj);
			return NULL;
//}
//DBG("visit %p 0x%016x", obj, *(void**)obj);
		return &STACK_BASE(seg)[index];
	}
}

static int
is_alive(void *obj)
{
	struct malloc_segment *mseg;
	struct segment *seg;
	unsigned int index;
	sml_bitptr_t r;
	sml_bitptra_t b;

	if (obj == NULL || (OBJ_HEADER(obj) & OBJ_FLAG_SKIP))
		return 1;
	if (OBJ_TOTAL_SIZE(obj) > BLOCKSIZE_MAX) {
		mseg = OBJ_TO_MALLOC_SEGMENT(obj);
		if (!mseg->bit)
			return 1;
		if (load_relaxed(&mseg->collect_bit) != 0)
			return 1;
		return 0;
	} else {
		seg = segment_addr(obj);
		index = object_index(seg, obj);
		r = BITPTR(BITMAP0_BASE(seg), index);
		if ((char*)obj >= (char*)seg->allocptr_snapshot
		    && !BITPTR_TEST(r)) {
//DBG("is_alive 1 %p", obj);
			return 1;
}
		b = BITPTRA(COLLECT_BITMAP_BASE(seg), index);
		if (BITPTRA_TEST(b)) {
//DBG("is_alive 2 %p", obj);
			return 1;
}
//DBG("is_alive not %p", obj);
		return 0;
	}
}

static void
push(void **stack_top, void *obj)
{
	struct stack_slot *slot = visit(obj);
	if (slot) {
		assert(slot->next == NULL);
		slot->next = *stack_top;
		*stack_top = obj;
	}
}

static void
push_enum(void **objp, void *data)
{
	push(data, *objp);
}

static void
remember(struct sml_alloc *alloc, void *obj)
{
	struct stack_slot *slot = visit(obj);
	if (slot) {
		slot->next = load_relaxed(&alloc->remembered_set);
		store_relaxed(&alloc->remembered_set, obj);
	}
}

static void
trace(void *stack_top)
{
	void *obj;
	struct stack_slot *slot;

	while (stack_top) {
		obj = stack_top;
		slot = object_stack_slot(obj);
		stack_top = slot->next;
		DEBUG(slot->next = NULL);
		sml_obj_enum_ptr(obj, push_enum, &stack_top);
	}
}

#if 0
void stackdump(void *stack_top) {
  while (stack_top) {
    sml_notice("%p", stack_top);
    stack_top = object_stack_slot(stack_top)->next;
  }
}

int objtest(uintptr_t objaddr) {
  void *obj = (void*)objaddr;
  struct segment *seg = segment_addr(obj);
  unsigned int index = object_index(seg, obj);
  sml_bitptr_t b = BITPTR(BITMAP0_BASE(seg), index);
  sml_bitptr_t c = BITPTR((sml_bmword_t*)COLLECT_BITMAP_BASE(seg), index);
  sml_notice("object %p: segment=%p index=%u bit=%d cbit=%d", obj, seg, index, BITPTR_TEST(b), BITPTR_TEST(c));
  return BITPTR_TEST(b);
}
#endif

void
sml_heap_user_sync2(struct sml_user *user, struct sml_alloc *alloc)
{
	visit(user);
	sml_stack_enum_ptr(user, push_enum, &alloc->root_set);
}

void
sml_heap_worker_sync2(struct sml_worker *worker, struct sml_alloc *alloc)
{
	visit(worker);
	visit(alloc);
	take_allocptr_snapshot(&alloc->heap);
}

void
sml_heap_global_sync2(struct sml_alloc *alloc)
{
	sml_global_enum_ptr(push_enum, &alloc->root_set);
	sml_callback_enum_ptr(push_enum, &alloc->root_set);
}

void
sml_heap_worker_mark(struct sml_alloc *alloc)
{
	trace(alloc->root_set);
	alloc->root_set = NULL;
	trace(load_relaxed(&alloc->remembered_set));
	store_relaxed(&alloc->remembered_set, NULL);
}

int
sml_heap_check_alive(void **objptr)
{
	return is_alive(*objptr);
}

int
sml_heap_mark_finish()
{
	struct sml_alloc_cons c, c1, c2;

	/* 全てのアロケータについてリメンバードセットが空でない可能性がある
	 * ので，全てのアロケータのremembered setを確認する．
	 * 2回見ることで，全てのallocのremembered setが空である時があった
	 * ことがわかる */
	c1 = sml_get_allocators();
	for (c = c1; c.alloc; c = sml_next_allocator(c.next)) {
		if (load_relaxed(&c.alloc->remembered_set) != NULL)
			return 0;
	}
	for (c = c1; c.alloc; c = sml_next_allocator(c.next)) {
		if (load_relaxed(&c.alloc->remembered_set) != NULL)
			return 0;
	}

	/* 2回見ている間にアロケータ集合が変化していないことを確認する */
	c2 = sml_get_allocators();
	if (c1.alloc != c2.alloc)
		return 0;

	return 1;
}

/******** reclamation ********/

static struct malloc_segment *
reclaim_malloc_segments(struct malloc_segment *msegs)
{
	struct malloc_segment_list l;
	struct malloc_segment *mseg, *next;

	LIST_INIT(&l);
	for (mseg = msegs; mseg; mseg = next) {
		next = mseg->next;
		if (!mseg->bit || load_relaxed(&mseg->collect_bit)) {
			mseg->bit = 1;
			store_relaxed(&mseg->collect_bit, 0);
			LIST_APPEND(&l, mseg);
		} else {
			free_malloc_segment(mseg);
		}
	}
	return LIST_FINISH(&l, NULL);
}

static unsigned int
free_count(struct segment *seg, void *allocptr)
{
	const sml_bmword_t *p;
	const sml_bmword_t *limit = BITMAP_LIMIT(seg, 0);
	unsigned int sum = 0;

	if (!allocptr) {
		p = BITMAP0_BASE(seg);
	} else {
		/* allocptrが指定されている場合は，allocptrより後にある
		 * 0ビットのみを数える．ただし，ビットポインタが途中にある
		 * ビットマップワードに含まれる0ビットの数は正確に数えない．
		 * allocptrが次のビットマップワードの先頭にあるものと
		 * してカウントする．従ってこの関数が数えるフリーブロックの
		 * 数は実際よりも最大で31個少なくなる */
		unsigned int index = object_index(seg, allocptr);
		sml_bitptr_t b = BITPTR(BITMAP0_BASE(seg), index);
		p = b.ptr + 1;
	}

	for (; p < limit; p++)
		sum += __builtin_popcount(~*p);

	return sum;
}

struct stat_reclaim {
	/* GC後のpartialの長さ */
	unsigned int num_partial;
	/* GC後の全ブロック数 */
	unsigned int num_blocks;
	/* GC後のフリーなブロックの数 */
	unsigned int num_blocks_free;
	/* 前回のGCから今回のGCまでの間にアロケートされたブロック数 */
	unsigned int num_blocks_alloced;
	/* 今回のGCでの余剰ブロック数 */
	unsigned int num_blocks_room;
	/* num_blocks_freeに新規割り当て可能数を加えた余剰ブロック数 */
	unsigned int num_free_total;
};

static void
reclaim_subheap(struct heap *heap, unsigned int subheap_index,
		struct segment_list *free, struct stat_reclaim *stat)
{
	struct subheap *subheap = &heap->subheap[subheap_index];
	struct alloc_ptr *ptr = &heap->ptr[subheap_index];

	struct segment_list partial, filled;
	struct segment *seg;
	unsigned int num_filled = 0, num_partial = 0;
	unsigned int num_blocks_free = 0, num_blocks_alloced = 0;
	unsigned int num_blocks_room = 0;

	LIST_INIT(&partial);
	LIST_INIT(&filled);

	for (seg = subheap->partial; seg; seg = seg->next) {
		sml_bmword_t summary = copy_collect_bitmap(seg);
		if (summary == 0) {
			LIST_APPEND(free, seg);
		} else {
			clear_collect_bitmap(seg);
			seg->allocptr_snapshot = BLOCK_BASE(seg);
			DEBUG(scribble_segment(seg, BLOCK_BASE(seg)));
			LIST_APPEND(&partial, seg);
			num_partial++;
			seg->free_count = free_count(seg, NULL);
			num_blocks_free += seg->free_count;
			num_blocks_room += seg->free_count;
		}
	}

	if (ptr->p) {
		seg = ALLOC_PTR_TO_SEGMENT(ptr);
		copy_collect_bitmap(seg);
		clear_collect_bitmap(seg);
		DEBUG(scribble_segment(seg, ptr->p));
		seg->allocptr_snapshot = BLOCK_LIMIT(seg);
		seg->free_count = free_count(seg, ptr->p);
		num_blocks_free += seg->free_count;
		num_blocks_alloced += object_index(seg, ptr->p);//rough estimation
		num_filled++;
	}

	for (seg = subheap->filled; seg; seg = seg->next) {
		num_blocks_alloced += seg->free_count;
		sml_bmword_t summary = copy_collect_bitmap(seg);
		if (summary == 0) {
			LIST_APPEND(free, seg);
		} else if (summary == -1U
			   || ((char*)seg->allocptr_snapshot
			       < (char*)BLOCK_LIMIT(seg))) {
			clear_collect_bitmap(seg);
			seg->allocptr_snapshot = BLOCK_LIMIT(seg);
			seg->free_count = 0;
			LIST_APPEND(&filled, seg);
			num_filled++;
		} else {
			clear_collect_bitmap(seg);
			seg->allocptr_snapshot = BLOCK_BASE(seg);
			DEBUG(scribble_segment(seg, BLOCK_BASE(seg)));
			LIST_APPEND(&partial, seg);
			num_partial++;
			seg->free_count = free_count(seg, NULL);
			num_blocks_free += seg->free_count;
		}
	}

	subheap->partial = LIST_FINISH(&partial, NULL);
	subheap->filled = LIST_FINISH(&filled, NULL);


	stat->num_blocks =
		(num_filled + num_partial)
		* segment_layout[subheap_index].num_blocks;
	stat->num_blocks_free = num_blocks_free;
	stat->num_blocks_alloced = num_blocks_alloced;
	stat->num_partial = num_partial;
	stat->num_blocks_room = num_blocks_room;
}

static void
reclaim_heap(struct heap *heap)
{
	struct segment_list free;
	unsigned int i;
	struct stat_reclaim stat[NUM_SUBHEAPS];

//sml_notice("before reclamation");
//print_heap_summary(heap);


#if 0
	struct stat_subheap before[NUM_SUBHEAPS];
	for (i = 0; i < NUM_SUBHEAPS; i++)
		before[i] = stat_subheap(&heap->subheap[i], &heap->ptr[i]);
#endif



	LIST_INIT(&free);
	unsigned int num_alloc_total = 0, num_live_total = 0, num_free_total = 0;
	for (i = 0; i < NUM_SUBHEAPS; i++) {
		reclaim_subheap(heap, i, &free, &stat[i]);
		num_alloc_total += stat[i].num_blocks_alloced;
		num_live_total += stat[i].num_blocks - stat[i].num_blocks_free;
		stat[i].num_free_total = stat[i].num_blocks_free + heap->count[i].extension_room * segment_layout[i].num_blocks;
		num_free_total += stat[i].num_free_total;
	}
	segment_push_list(&segment_pool.freelist, &free);
	heap->malloc_subheap = reclaim_malloc_segments(heap->malloc_subheap);



#if 0
	struct stat_subheap after[NUM_SUBHEAPS];
	for (i = 0; i < NUM_SUBHEAPS; i++)
		after[i] = stat_subheap(&heap->subheap[i], &heap->ptr[i]);

	unsigned int num_alloc_total_s = 0;
	unsigned int num_alloc_s[NUM_SUBHEAPS];
	for (i = 0; i < NUM_SUBHEAPS; i++) {
		num_alloc_s[i] = before[i].total.num_unmarked_before_allocptr - heap->count[i].num_unmarked_before_allocptr;
		num_alloc_total_s += num_alloc_s[i];
	}
	sml_notice("total alloc = %u", num_alloc_total_s);

	unsigned int num_live_total_s = 0;
	for (i = 0; i < NUM_SUBHEAPS; i++)
		num_live_total_s += after[i].total.num_marked + after[i].total.num_unmarked_before_allocptr;
	sml_notice("total live = %u", num_live_total_s);
#endif






#if 0
	for (i = 0; i < NUM_SUBHEAPS; i++) {
		struct subheap_count *count = &heap->count[i];
		double allocspeed =
			(double)num_alloc_s[i] / num_alloc_total_s;
		double allocspeed_ratio =
			count->allocspeed_ratio +
			0.2 * (allocspeed - count->allocspeed_ratio);
//		count->allocspeed_ratio = allocspeed_ratio;
		unsigned int want_block =
			num_live_total_s * allocspeed_ratio;
		unsigned int num_blocks_free =
			after[i].total.num_unmarked
			- after[i].total.num_unmarked_before_allocptr;
		unsigned int shortage_block =
			want_block > num_blocks_free
			? want_block - num_blocks_free
			: 0;
		unsigned int shortage_segment =
			ceil(shortage_block / segment_layout[i].num_blocks);
//		count->limit =
//			after[i].num_partial + shortage_segment;
//		if (count->limit <= 0)
//			count->limit++;
//		double room =
//			before[i].total.num_unmarked
//			- before[i].total.num_unmarked_before_allocptr > 0
//			? 1.0 : 0.5;
//		count->threshold_ratio +=
//			0.2 * (room - count->threshold_ratio);
//		count->threshold =
//			ceil(count->limit * count->threshold_ratio);
//		if (count->threshold <= 0)
//			count->threshold++;
		count->num_unmarked_before_allocptr =
			after[i].total.num_unmarked_before_allocptr;

sml_notice("%2u : %7u alloc (%4.2f -> %4.2f) %7u want %7u free %4u add",
	   i + BLOCKSIZE_MIN_LOG2,
	   num_alloc_s[i], allocspeed, allocspeed_ratio,
	   want_block,
	   num_blocks_free,
	   shortage_segment
	   );
	}
#endif


	/* 残りブロックの総数を各サブヒープにアロケーションの速さ
	 * （の割合の重み付き平均）で比例配分する．ただし，残りブロック数は
	 * 少なくともライブオブジェクト数の2倍を用意する．
	 * アロケーションの速さは，前回GCからのサブヒープごとのアロケーション
	 * 回数を総アロケーション回数で割って算出する．*/
	unsigned int num_distrib =
		num_free_total > num_live_total
		? num_free_total : num_live_total;
	for (i = 0; i < NUM_SUBHEAPS; i++) {
		struct subheap_count *count = &heap->count[i];
		double allocspeed =
			(double)stat[i].num_blocks_alloced / num_alloc_total;
		double allocspeed_ratio =
			count->allocspeed_ratio +
			0.2 * (allocspeed - count->allocspeed_ratio);
		count->allocspeed_ratio = allocspeed_ratio;
		unsigned int want_block =
			num_distrib * allocspeed_ratio;
		unsigned int shortage_block =
			want_block > stat[i].num_blocks_free
			? want_block - stat[i].num_blocks_free
			: 0;
		unsigned int shortage_segment =
			ceil(shortage_block / segment_layout[i].num_blocks);
		count->extension_room =
			shortage_segment;
		if (count->extension_room <= 0)
			count->extension_room = 1;
		double room =
			stat[i].num_blocks_room > 0
			? 1.0 : 0.2;
		count->threshold_ratio +=
			0.2 * (room - count->threshold_ratio);
		unsigned int num_room =
			stat[i].num_partial + count->extension_room;
		count->threshold =
			ceil(num_room * count->threshold_ratio);
		if (count->threshold <= 0)
			count->threshold++;
#if 0
sml_notice("%2u : %7u alloc (%4.2f) %7u live %7u want %7u free %4u add %.1f",
	   i + BLOCKSIZE_MIN_LOG2,
	   stat[i].num_blocks_alloced,
	   allocspeed,
	   stat[i].num_blocks - stat[i].num_blocks_free,
	   want_block,
	   stat[i].num_free_total,
	   shortage_segment,
	   room
	   );
#endif
	}
#if 0
sml_notice("   : %7u alloc        %7u live              %7u free total",
	   num_alloc_total, num_live_total, num_free_total);
#endif

}

static void
reclaim_subpool(struct subpool *subpool, struct segment_list *free)
{
	struct segment_list partial, filled;
	struct segment *seg;
	sml_bmword_t summary;

	/* partial_markedから1つずつセグメントを取り出して，
	 * コレクトビットマップのクリアを行う．コレクトビットマップを
	 * クリアしたセグメントは，ブロックの使用状況に応じて
	 * partialかfreelistに戻される．*/
	while ((seg = segment_pop(&subpool->partial_marked))) {
		sml_bmword_t summary = copy_collect_bitmap(seg);
		if (summary == 0) {
			LIST_APPEND(free, seg);
		} else {
			clear_collect_bitmap(seg);
			seg->allocptr_snapshot = BLOCK_BASE(seg);
			DEBUG(scribble_segment(seg, BLOCK_BASE(seg)));
			segment_push(&subpool->partial, seg);
		}
	}

	LIST_INIT(&partial);
	LIST_INIT(&filled);
	for (seg = subpool->filled; seg; seg = seg->next) {
		summary = copy_collect_bitmap(seg);
		if (summary == 0) {
			LIST_APPEND(free, seg);
		} else if (summary == -1U) {
			clear_collect_bitmap(seg);
			seg->allocptr_snapshot = BLOCK_BASE(seg);
			LIST_APPEND(&filled, seg);
		} else {
			clear_collect_bitmap(seg);
			seg->allocptr_snapshot = BLOCK_BASE(seg);
			DEBUG(scribble_segment(seg, BLOCK_BASE(seg)));
			LIST_APPEND(&partial, seg);
		}
	}
	subpool->filled = LIST_FINISH(&filled, NULL);
	segment_push_list(&subpool->partial, &partial);
}

static void
reclaim_segment_pool(struct segment_pool *pool)
{
	unsigned int i;
	struct segment_list free;

	LIST_INIT(&free);
	for (i = 0; i < NUM_SUBHEAPS; i++)
		reclaim_subpool(&pool->subpool[i], &free);
	segment_push_list(&pool->freelist, &free);

	pool->malloc_subpool = reclaim_malloc_segments(pool->malloc_subpool);
}


void
sml_heap_global_before_async()
{
	unsigned int i;
	struct segment *segs;
	struct segment_pool *pool = &segment_pool;

	for (i = 0; i < NUM_SUBHEAPS; i++) {
		/* partialをpartial_markedに移し替える．移し替えの際，
		 * 一瞬だけ両方ともNULLになるときがある．この一瞬の間に
		 * サブプールからセグメントを取り出そうとするスレッドが
		 * 存在する可能性は（ごくわずかだが）ある．*/
		segs = swap(relaxed, &pool->subpool[i].partial, NULL);
		store_relaxed(&pool->subpool[i].partial_marked, segs);
	}
}

void
sml_heap_worker_async(struct sml_alloc *alloc)
{
	/* sml_heap_mark_finishでの判定後にもスナップショットライトバリアが
	 * 働く可能性があるので，remembered_setをNULLクリアする．*/
	store_relaxed(&alloc->remembered_set, NULL);


//static pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;

//mutex_lock(&m);
//sml_notice("allocator %p reclaim start", alloc);
//print_heap_summary(&alloc->heap);

	reclaim_heap(&alloc->heap);

//sml_notice("allocator %p reclaim end", alloc);
//print_heap_summary(&alloc->heap);
//mutex_unlock(&m);
}

void
sml_heap_global_async()
{
	reclaim_segment_pool(&segment_pool);
}

/******** mutation ********/

static void
barrier(void *old_value, void *new_value)
{
	enum sml_sync_phase phase = sml_current_phase();

	if (phase >= SYNC1) {
		struct sml_alloc *alloc = worker_tlv_get(current_allocator);
		if (phase <= SYNC2)
			remember(alloc, new_value);
		remember(alloc, old_value);
	}
}

SML_PRIMITIVE void
sml_write(void *obj ATTR_UNUSED, void **writeaddr, void *new_value)
{
//DBG("write %p %p", *writeaddr, new_value);
	barrier(*writeaddr, new_value);
	*writeaddr = new_value;
}

int
sml_cmpswap(void *obj, void *old_value, void *new_value)
{
	_Atomic(void *) *ref = (_Atomic(void *)*)obj;

	if (cmpswap_acq_rel(ref, &old_value, new_value)) {
		barrier(old_value, new_value);
		return 1;
	} else {
		return 0;
	}
}

static void *
try_find_segment(struct sml_alloc *alloc, unsigned int subheap_index,
		 enum sml_sync_phase phase)
{
	struct alloc_ptr *ptr = &alloc->heap.ptr[subheap_index];
	struct subheap *subheap = &alloc->heap.subheap[subheap_index];
	struct subheap_count *count = &alloc->heap.count[subheap_index];
	struct segment *seg;
	void *obj;

	if (ptr->p) {
		seg = release_alloc_ptr(ptr, phase);
		seg->next = subheap->filled;
		subheap->filled = seg;
		count->threshold--;
		if (count->threshold == 0)
{
			sml_gc(0);
//sml_notice("gc start by subheap %u", subheap_index+BLOCKSIZE_MIN_LOG2);
//print_heap_summary(&alloc->heap);
}
	}

	if (subheap->partial) {
		seg = subheap->partial;
		subheap->partial = subheap->partial->next;
	} else {
#if 0
		if (count->extension_room == 0)
			return NULL;
#endif
		seg = get_segment_from_pool(&segment_pool, subheap_index,
					    phase);
		if (!seg)
			return NULL;
//DBG("try_find_segment alloc=%p seg=%p", alloc, seg);
	count->extension_room--;
	}

	set_alloc_ptr(ptr, seg, phase);
	obj = find_bitmap(ptr);
	assert(obj != NULL);
	return obj;
}

static NOINLINE void *
find_segment(struct alloc_ptr *ptr, void *frame_pointer)
{
	unsigned int subheap_index;
	struct sml_alloc *alloc;
	void *obj;

	if (load_relaxed(&sml_check_flag))
		sml_check_internal(frame_pointer);

	/* calculate subheap_index from ptr instead of taking it as an
	 * argument.  This is an optimization that minimizes the number of
	 * instructions on the most frequently executed path in sml_alloc.
	 */
	alloc = worker_tlv_get(current_allocator);
	subheap_index = ptr - &alloc->heap.ptr[0];
	assert(subheap_index <= NUM_SUBHEAPS);

	obj = try_find_segment(alloc, subheap_index, sml_current_phase());
	if (obj)
		return obj;

//DBG("allocator %p waits for gc for %u", alloc, subheap_index);
//sml_notice("wait gc for %u", subheap_index);
//print_heap_summary(&alloc->heap);
#if defined GCTIME || defined GCHIST
	sml_timer_t t1, t2;
	sml_time_t t;
	sml_timer_now(t1);
#endif

	sml_wait_gc(frame_pointer);
	obj = try_find_segment(alloc, subheap_index, sml_current_phase());
	if (obj)
		goto wait_gc_finished;

	// ToDo
	sml_wait_gc(frame_pointer);
	obj = try_find_segment(alloc, subheap_index, sml_current_phase());
	if (obj)
		goto wait_gc_finished;

	print_heap_summary(&alloc->heap);
	sml_fatal(0, "exhaust subheap %u of allocator %p",
		  subheap_index, alloc);

wait_gc_finished:
#if defined GCTIME || defined GCHIST
	sml_timer_now(t2);
	sml_timer_dif(t1, t2, t);
#endif
#ifdef GCTIME
	static pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;
	mutex_lock(&m);
	sml_notice("# wait gc for: {subheap: %u, time: "TIMEFMT"}",
		   subheap_index, TIMEARG(t));
	mutex_unlock(&m);
#endif
#ifdef GCHIST
	DBG("  - wait gc for: {subheap: %u, time: "TIMEFMT"}",
	    subheap_index, TIMEARG(t));
#endif
	return obj;
}

static sml_bitptr_t
bitptr_linear_search(const sml_bmword_t *start, const sml_bmword_t *limit)
{
	sml_bitptr_t b = {start, 0};
	while (b.ptr < limit) {
		b.mask = 1;
		BITPTR_NEXT0(b);
		if (!BITPTR_NEXT_FAILED(b)) break;
		b.ptr++;
	}
	return b;
}

static NOINLINE void *
find_bitmap(struct alloc_ptr *ptr)
{
	unsigned int i, index, *base, *limit;
	const unsigned int *p;
	struct segment *seg;
	sml_bitptr_t b = ptr->b;
	void *obj;

	if (ptr->p == NULL)
		return NULL;

	seg = ALLOC_PTR_TO_SEGMENT(ptr);
	base = BITMAP0_BASE(seg);

	BITPTR_NEXT0(b);
	if (BITPTR_NEXT_FAILED(b)) {
		for (i = 1;; i++) {
			index = BITPTR_WORDINDEX(b, base) + 1;
			base = BITMAP_BASE(seg, i);
			b = BITPTR(base, index);
			BITPTR_NEXT0(b);
			if (!BITPTR_NEXT_FAILED(b))
				break;
			if (i >= SEG_RANK - 1) {
				p = &BITPTR_WORD(b) + 1;
				limit = BITMAP_LIMIT(seg, i);
				b = bitptr_linear_search(p, limit);
				if (BITPTR_NEXT_FAILED(b))
					return NULL;
				break;
			}
		}
		for (; i > 0; i--) {
			index = BITPTR_INDEX(b, base);
			base = BITMAP_BASE(seg, i - 1);
			b = BITPTR(base + index, 0);
			BITPTR_NEXT0(b);
			assert(!BITPTR_NEXT_FAILED(b));
		}
	}

	index = BITPTR_INDEX(b, base);
	assert(index < seg->layout->num_blocks);
	obj = BLOCK_BASE(seg) + (index << seg->layout->blocksize_log2);

	BITPTR_INC(b);
	ptr->b = b;
	ptr->p = ADD_BYTES(obj, ptr->blocksize_bytes);

	return obj;
}

static NOINLINE void *
malloc_object(size_t alloc_size)
{
	struct malloc_segment *mseg = malloc_segment(alloc_size);
	struct sml_alloc *alloc = worker_tlv_get(current_allocator);
	mseg->next = alloc->heap.malloc_subheap;
	alloc->heap.malloc_subheap = mseg;
	return MALLOC_SEGMENT_TO_OBJ(mseg);
}

SML_PRIMITIVE void *
sml_alloc(unsigned int objsize)
{
	size_t alloc_size;
	unsigned int blocksize_log2, subheap_index;
	struct alloc_ptr *ptr;
	void *obj;

	if (objsize > BLOCKSIZE_MAX - OBJ_HEADER_SIZE)
		return malloc_object(objsize);

	/* ensure that alloc_size is at least BLOCKSIZE_MIN. */
	alloc_size = CEILING(OBJ_HEADER_SIZE + objsize, BLOCKSIZE_MIN);
	blocksize_log2 = CEIL_LOG2(alloc_size);
	assert(BLOCKSIZE_MIN_LOG2 <= blocksize_log2
	       && blocksize_log2 <= BLOCKSIZE_MAX_LOG2);
	subheap_index = blocksize_log2 - BLOCKSIZE_MIN_LOG2;
	ptr = &(worker_tlv_get(current_allocator)->heap.ptr[subheap_index]);

	if (!BITPTR_TEST(ptr->b)) {
		BITPTR_INC(ptr->b);
		obj = ptr->p;
		ptr->p = ADD_BYTES(ptr->p, ptr->blocksize_bytes);
		assert(obj != NULL);
		goto alloced;
	}

	obj = find_bitmap(ptr);
	if (obj) goto alloced;

	obj = find_segment(ptr, CALLER_FRAME_END_ADDRESS());

alloced:
	assert(check_filled(OBJ_BEGIN(obj), 0x55, objsize));
	return obj;
}

void *
sml_alloc_important(struct sml_alloc *alloc, unsigned int objsize,
		    enum sml_sync_phase phase)
{
	size_t alloc_size;
	unsigned int blocksize_log2, subheap_index;
	struct alloc_ptr *ptr;
	void *obj;

	if (objsize > BLOCKSIZE_MAX - OBJ_HEADER_SIZE)
		return malloc_object(objsize);

	/* ensure that alloc_size is at least BLOCKSIZE_MIN. */
	alloc_size = CEILING(OBJ_HEADER_SIZE + objsize, BLOCKSIZE_MIN);
	blocksize_log2 = CEIL_LOG2(alloc_size);
	assert(BLOCKSIZE_MIN_LOG2 <= blocksize_log2
	       && blocksize_log2 <= BLOCKSIZE_MAX_LOG2);
	subheap_index = blocksize_log2 - BLOCKSIZE_MIN_LOG2;
 retry:
	ptr = &alloc->heap.ptr[subheap_index];

	if (!BITPTR_TEST(ptr->b)) {
		BITPTR_INC(ptr->b);
		obj = ptr->p;
		ptr->p = ADD_BYTES(ptr->p, ptr->blocksize_bytes);
		assert(obj != NULL);
		goto alloced;
	}

	obj = find_bitmap(ptr);
	if (obj) goto alloced;

	/* ここまではsml_allocと同じ．
	 * find_segmentの代わりにtry_find_segmentを用いることでGC待ちを
	 * 回避する */
	obj = try_find_segment(alloc, subheap_index, phase);
	if (obj) goto alloced;

	/* count->extension_roomにひっかかっただけなら，
	 * 無理やりextension_roomを上げてセグメントをアロケートする */
	struct subheap_count *count = &alloc->heap.count[subheap_index];
	if (count->extension_room == 0) {
		count->extension_room++;
		obj = try_find_segment(alloc, subheap_index, phase);
		if (obj) goto alloced;
	}

	/* それでもだめなら他のサイズのセグメントを転用する */
	if (subheap_index < NUM_SUBHEAPS - 1) {
		subheap_index++;
		goto retry;
	}

	/* それでもだめなら諦める */
	return NULL;
alloced:
	assert(check_filled(OBJ_BEGIN(obj), 0x55, objsize));
	return obj;
}

/******** initialization ********/

void
sml_heap_init(size_t min_size, size_t max_size)
{
	init_segment_layout();
	init_segment_pool(min_size, max_size);
	init_subheap_count_init();
}

void
sml_heap_destroy()
{
	/* ToDo */
#ifdef GCTIME
	sml_notice(" alloced: %u", load_relaxed(&segment_pool.memory.alloced));
#endif
}
