/*
 * heap.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: heap.h,v 1.11 2008/12/10 03:23:23 katsu Exp $
 */
#ifndef SMLSHARP__HEAP_H__
#define SMLSHARP__HEAP_H__

/*
 * In order to prevent name conflict, the name of all global symbols
 * defined in heap mangenement implementation must be started with
 * "sml_heap_", and so do macros with "HEAP_".
 */

/*
 * heap.h declares public interface of heap management module.
 * Each implementation of heap module should be splitted to heap_impl.h.
 */
#ifdef HEAP_IMPL_H
#include HEAP_IMPL_H
#endif

/*
 * thread-local environment for heap management.
 */
struct sml_heap_thread;

/*
 * initialize the global heap.
 * size : hint of initial heap size in bytes.
 *        Implementation should allocate "size" bytes in total for initial
 *        heap.
 */
void sml_heap_init(size_t size);

/*
 * finalize the global heap.
 */
void sml_heap_free(void);

/*
 * setup thread-local heap of current thread.
 */
void sml_heap_thread_init(void);

/*
 * finalize the thread-local heap of current thread.
 */
void sml_heap_thread_free(void);

/*
 * obtain/release global lock.
 */
#define HEAP_LOCK()    HEAP_LOCK_IMPL
#define HEAP_UNLOCK()  HEAP_UNLOCK_IMPL

/*
 * If heap management module provides sml_alloc directly, define
 * HEAP_OWN_SML_ALLOC.
 */
#ifdef HEAP_OWN_SML_ALLOC
SML_PRIMITIVE void *sml_alloc(unsigned int objsize, void *frame_pointer);
#else

/*
 * size_t HEAP_ROUND_SIZE(size_t size);
 *
 * size : header size + payload size + bitmap size
 * return : increment for HEAP_FAST_ALLOC.
 */
#define HEAP_ROUND_SIZE(sz)  HEAP_ROUND_SIZE_IMPL(sz)

/*
 * allocate an arbitrary heap object of current thread.
 *
 * obj : variable for storing new object pointer. (void *)
 * inc : increment produced by HEAP_ROUND_SIZE (size_t)
 * IFFAIL : execute this expression if the fast allocation was failed.
 *          IFFAIL must reutrn the new object pointer. (void *)
 *
 * IFFAIL is needed to be abstracted so that caller may have a chance
 * to save stack frame pointer before invoking garbage collector.
 */
#define HEAP_FAST_ALLOC(obj, inc, IFFAIL) \
        HEAP_FAST_ALLOC_IMPL(obj, inc, IFFAIL)

/*
 * alternative allocation function for the case when HEAP_FAST_ALLOC failed.
 *
 * This function may invoke garbage collection and retry to allocate
 * the heap object. Usually this function is used for implementing IFFAIL
 * of HEAP_FAST_ALLOC macro.
 *
 * inc : increment (same as HEAP_FAST_ALLOC)
 */
void *sml_heap_slow_alloc(size_t inc);

#endif /* HEAP_OWN_SML_ALLOC */

/*
 * Forcely start garbage collection.
 */
void sml_heap_gc(void);

/*
 * invoked just after storing a pointer value to memory.
 * writeaddr (void**) : updated address.
 * objaddr (void*) : address of object containing writeaddr.
 *
 * This macro will be executed for objects at both inside and outside
 * of heap. If "writeaddr" and/or "objaddr" is not in any heap, heap
 * management module must call sml_global_barrier with the address
 * so that runtime remembers the address in order to keep track of
 * object references from outside of heap.
 */
#define HEAP_WRITE_BARRIER(writeaddr, objaddr) \
	HEAP_WRITE_BARRIER_IMPL(writeaddr, objaddr)

/*
 * If heap management module requires notification from finalizer modules,
 * define the following macros.
 */
#ifdef HEAP_NOTIFY_ADD_FINALIZER
void sml_heap_notify_add_finalizer(void *obj);
#endif /* HEAP_NOTIFY_ADD_FINALIZER */

#endif /* SMLSHARP__HEAP_H__ */
