/*
 * heap_cheney.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: heap.h,v 1.11 2008/12/10 03:23:23 katsu Exp $
 */
#ifndef SMLSHARP__HEAP_CHENEY_H__
#define SMLSHARP__HEAP_CHENEY_H__

/*#define GCSTAT*/

#define HEAP_LOCK_IMPL   ((void)0)
#define HEAP_UNLOCK_IMPL ((void)0)

/*
 * Heap Space Layout:
 *
 *   INITIAL_OFFSET
 *    <-->
 *   +----+--------------------------------+
 *   |    |                                |
 *   +----+--------------------------------+
 *   ^    ^           ^                     ^
 *   base |          free                   limit
 *        |
 *        start address of free.
 */
struct heap_space {
	char *free;
	char *limit;
	char *base;
};
extern struct heap_space sml_heap_from_space;

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
#define HEAP_ROUND_SIZE_IMPL(sz) \
	ALIGNSIZE(sz, ALIGNSIZE(HEAP_ALLOC_SIZE_MIN, 8))
#else
#define HEAP_ROUND_SIZE_IMPL(sz) \
	ALIGNSIZE(sz, ALIGNSIZE(HEAP_ALLOC_SIZE_MIN, MAXALIGN))
#endif /* FAIR_COMPARISON */

#ifdef GCSTAT
void sml_heap_alloced(size_t size);
#else
#define sml_heap_alloced(size) ((void)0)
#endif /* GCSTAT */

#ifdef FAIR_COMPARISON
#define HEAP_OBJ_MALLOC(size,ret) \
	if ((size) > 4096) { ret = sml_obj_malloc(size); } else
#else
#define HEAP_OBJ_MALLOC(sie,ret)
#endif /* FAIR_COMPARISON */

#define HEAP_FAST_ALLOC_IMPL(obj__, inc, IFFAIL) do {			\
	HEAP_LOCK();							\
	HEAP_OBJ_MALLOC(inc, obj__) {					\
	obj__ = (void*)sml_heap_from_space.free;			\
	(size_t)(sml_heap_from_space.limit - (char*)obj__) < (inc)	\
		? (void)(obj__ = ((void)HEAP_UNLOCK(), IFFAIL))		\
		: (void)(sml_heap_alloced(inc),				\
			 sml_heap_from_space.free += (inc),		\
			 (void)HEAP_UNLOCK());				\
	}								\
} while (0)

void sml_heap_barrier(void **writeaddr, void *objaddr);

#define HEAP_WRITE_BARRIER_IMPL(writeaddr, objaddr) \
	sml_heap_barrier(writeaddr, objaddr)

#endif /* SMLSHARP__HEAP_CHENEY_H */
