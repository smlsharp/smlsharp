/*
 * heap.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: heap.h,v 1.11 2008/12/10 03:23:23 katsu Exp $
 */
#ifndef SMLSHARP__HEAP_H__
#define SMLSHARP__HEAP_H__

#include "cdecl.h"
#include "value.h"

/*
 * prepend "heap_" or "HEAP_" to all names to prevent name conflict.
 * obj_alloc, and record_alloc are exception; they are frequently used.
 */

/*
 * initialize the global heap.
 */
void heap_init(void);

/*
 * finalize the global heap.
 */
void heap_free(void);

/*
 * register an root set enumerator.
 *
 * enumfn: (ptr -> unit) * data -> unit
 * data: extra data passed to enum
 */
typedef void heap_rootset_fn(void (*)(void **), void *);
void heap_add_rootset(heap_rootset_fn *enumfn, void *data);

/*
 * unregister an root set enumerator.
 */
void heap_remove_rootset(void (*enumfn)(void (*)(void **), void *), void *data);

/*
 * Heap Space Layout: (INTERNAL)
 *
 *   |<-------------- size --------------->|
 *   |                                     |
 *   | INITIAL_OFFSET                      |
 *   |<-->|                                |
 *
 *   +----+--------------------------------+
 *   |    |                                |
 *   +----+--------------------------------+
 *   ^    ^           ^                     ^
 *   base |          free                   limit
 *        |
 *        start address of free.
 *
 * This decralation is just for internal use by HEAP_ALLOC macro.
 * DO NOT USE THIS DIRECTLY FROM OUTSIDE.
 */
struct heap_space {
	void *free;
	void *limit;
	void *base;
	size_t size;
};
extern struct heap_space heap_from_space;

/*
 * Allocation: (INTERNAL)
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

/*
 * size_t HEAP_ROUND_SIZE(size_t size);
 *
 * size : header size + payload size + bitmap size
 * return : increment for HEAP_ALLOC.
 */
/* For each object, its size must be enough to hold one forwarded pointer. */
#define ALLOC_SIZE_MIN       (OBJ_HEADER_SIZE + sizeof(void*)) /* (INTERNAL) */
#define HEAP_ROUND_SIZE(sz)  ALIGN(sz, ALIGN(ALLOC_SIZE_MIN, MAXALIGN))

/*
 * allocate an arbitrary heap object.
 *
 * obj : variable for storing new object pointer. (void *)
 * inc : increment (size_t)
 * IFFAIL : execute this expression if the allocation was failed due to
 *          lack of free space.
 *          IFFAIL must reutrn the new object pointer. (void *)
 *
 * IFFAIL is needed to be abstracted here so that the evaluation loop
 * can save stack pointer from machine register to global variable before
 * invoking GC.
 */
#define HEAP_ALLOC(obj__, inc, IFFAIL) do {				\
	obj__ = heap_from_space.free;					\
	(size_t)((char*)heap_from_space.limit - (char*)obj__) < (inc)	\
	? (void)(obj__ = IFFAIL)					\
	: (void)(heap_from_space.free = (char*)heap_from_space.free + (inc)); \
} while (0)

/*
 * invoke garbage collection and retry to allocate the heap object.
 * This function is provided for implementing IFFAIL of HEAP_ALLOC macro.
 *
 * inc : increment (same as HEAP_ALLOC)
 */
void *heap_invoke_gc_and_alloc(size_t inc);

/*
 * add an pointer to the set of intergenerational pointers.
 * base : pointer to the beginning of the heap object which contains
 *        the updated field. (void *)
 * ptr  : pointer to the updated field. (void **)
 */
#define WRITE_BARRIER(base, ptr)  ((void)0)

/*
 * allocate an heap object without bitmap.
 */
void *obj_alloc(unsigned int objtype, size_t payload_size);

/*
 * allocate an heap object with bitmaps.
 */
void *record_alloc(size_t payload_size);

/*
 * register a finalizer.
 */
#define HEAP_HAVE_FINALIZER 1
typedef void heap_finalizer_fn(void *obj, void *data);
void heap_add_finalizer(void *obj, heap_finalizer_fn *finalize_fn, void *data);

#endif /* SMLSHARP__HEAP_H */
