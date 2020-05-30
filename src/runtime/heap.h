/*
 * heap.h
 * @copyright (c) 2015, Tohoku University.
 * @author UENO Katsuhiro
 */
#ifndef SMLSHARP__HEAP_H__
#define SMLSHARP__HEAP_H__

struct sml_alloc;

/*
 * Initialize the SML# heap.
 * min_size : hint of minimum and initial heap size in bytes.
 * max_size : hint of maximum heap size in bytes.
 */
void sml_heap_init(size_t min_size, size_t max_size);

/*
 * Finalize the SML# heap.
 */
void sml_heap_destroy(void);

/*
 * Initialize thread-local allocator agent of the current worker thread.
 */
struct sml_heap_worker_init {
	struct sml_alloc *alloc;
	void *memory;
};
struct sml_heap_worker_init sml_heap_worker_init(size_t);
void sml_heap_worker_register(struct sml_alloc *, enum sml_sync_phase);
void sml_heap_worker_kill(struct sml_alloc *);

/*
 * Action taken when a worker thread received the SYNC2 signal.
 * It adds the worker context to the root set and takes the allocation pointer
 * snapshot.
 */
void sml_heap_worker_sync2(struct sml_worker *, struct sml_alloc *);

/*
 * Action taken when a user thread received the SYNC2 signal.
 * It enumerates pointers in the stack frames including the user context
 * and adds them to the root set.
 */
void sml_heap_user_sync2(struct sml_user *, struct sml_alloc *);

/*
 * Action taken when the global context received the SYNC2 signal.
 * It enumerates pointers in the global variables and adds them to the root set.
 */
void sml_heap_global_sync2(struct sml_alloc *);

/*
 * Action taken when the worker thread received the MARK signal.
 * It traces all the objects reachable from the root set.
 */
void sml_heap_worker_mark(struct sml_alloc *);

/*
 * Action taken when all the worker thread have finished the mark action.
 * It checks whether all the remembered sets are empty and therefore the
 * tracing has finished (non-zero) or not (zero).
 */
int sml_heap_mark_finish(void);

/*
 * Action taken when the worker thread received the ASYNC signal.
 * It copies the collect bitmap to the allocation bitmap for each segment
 * belonging to the worker and reclaims the segments according to its
 * utilization.
 */
void sml_heap_worker_async(struct sml_alloc *info);

/*
 * Action taken before ASYNC signal is sent to the worker threads.
 */
void sml_heap_global_before_async(void);

/*
 * Action taken when the global context received the ASYNC signal.
 * It performs the same thing as sml_heap_worker_async for each segment
 * in the global segment pool.
 */
void sml_heap_global_async(void);

/*
 * Allocate an SML# object with objsize-byte payload.
 */
SML_PRIMITIVE void *sml_alloc(unsigned int objsize);

/*
 * Similar to sml_alloc except that it never cause garbage collection.
 * if no free block is found for objsize, it returns NULL.
 */
void *sml_alloc_important(struct sml_alloc *, unsigned int, enum sml_sync_phase);

/*
 * Memory update with write barrier.
 * obj : the object to be altered
 * writeaddr : the address in obj to be overwritten with new_value
 * new_value : the value to be stored in writeaddr
 */
SML_PRIMITIVE void sml_write(void *obj, void **writeaddr, void *new_value);

/*
 * Check whether or not the given object survives.
 * slot : pointer to pointer to the object to be checked
 * This function works only after sml_heap_mark_finish returns non-zero and
 * before sml_heap_*_async is called.
 * This returns non-zero if the given object is marked as alive.
 */
int sml_heap_check_alive(void **slot);

#endif /* SMLSHARP__HEAP_H__ */
