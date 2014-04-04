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
 * initialize the global heap.
 * min_size : hint of minimum and initial heap size in bytes.
 * max_size : hint of maximum heap size in bytes.
 * Implementation should allocate "size" bytes in total for initial heap.
 */
void sml_heap_init(size_t min_size, size_t max_size);

/*
 * finalize the global heap.
 */
void sml_heap_free(void);

/*
 * setup thread-local heap of current thread.
 * It returns a pointer to thread-local heap structure.
 * NOTE: At the timing calling this function, thread management functions
 * such as sml_save_frame_pointer, sml_current_thread_heap, GIANT_LOCK,
 * and so on, is not available.
 */
void *sml_heap_thread_init(void);

/*
 * finalize the thread-local heap of current thread.
 */
void sml_heap_thread_free(void *thread_heap);

/*
 * this function is called when a mutator thread is to be suspended
 * due to stop-the-world.
 * Note that this function is called for every thread-local storage,
 * not for every mutator. If the mutator A is already suspended at STW
 * signal, another running thread may call this function with A's data.
 */
#ifdef MULTITHREAD
void sml_heap_thread_stw_hook(void *data);
#endif /* MULTITHREAD */


void sml_heap_thread_rootset_hook(void *data);


/*
 * Forcely start garbage collection.
 */
void sml_heap_gc(void);

/*
 * allocate an arbitrary heap object of current thread.
 */
SML_PRIMITIVE void *sml_alloc(unsigned int objsize, void *frame_pointer);

/*
 * update a pointer field of "obj" indicated by "writeaddr" with "new_value".
 * The heap implementation may perform additional tasks to keep track of
 * pointer updates.
 *
 * This function will be called with objects at both inside and outside
 * of heap. If "writeaddr" and/or "objaddr" is not in any heap, heap
 * implementation must call sml_global_barrier after update.
 */
SML_PRIMITIVE void sml_write(void *obj, void **writeaddr, void *new_value);

#endif /* SMLSHARP__HEAP_H__ */
