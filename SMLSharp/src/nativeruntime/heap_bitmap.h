/*
 * heap_bitmap.h
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: heap.h,v 1.11 2008/12/10 03:23:23 katsu Exp $
 */
#ifndef SMLSHARP__HEAP_BITMAP_H__
#define SMLSHARP__HEAP_BITMAP_H__

/*#define GCSTAT*/

#define HEAP_OWN_SML_ALLOC

#define HEAP_LOCK_IMPL   ((void)0)
#define HEAP_UNLOCK_IMPL ((void)0)

void sml_heap_barrier(void **writeaddr, void *objaddr);

#define HEAP_WRITE_BARRIER_IMPL(writeaddr, objaddr) \
	sml_heap_barrier(writeaddr, objaddr)

#endif /* SMLSHARP__HEAP_BITMAP_H */
