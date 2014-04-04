/*
 * objspace.h
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: value.c,v 1.5 2008/02/05 08:54:35 katsu Exp $
 */
#ifndef SMLSHARP__OBJSPACE_H__
#define SMLSHARP__OBJSPACE_H__

/*
 * rootset enumeration mode.
 * - MAJOR means enumerating all.
 * - MINOR means enumerating only new ones.
 */
enum sml_gc_mode {
	MINOR,
	MAJOR
#ifdef DEBUG
	,TRY_MAJOR  /* same as MAJOR but dry run */
#endif /* DEBUG */
};

/*
 * initialize object space management.
 */
void sml_objspace_init(void);

/*
 * finalize object space management.
 */
void sml_objspace_free(void);

/*
 * enumerate pointer slots in objspace.
 */
void sml_objspace_enum_ptr(void (*callback)(void **), enum sml_gc_mode);

/*
 * allocate an ML object by malloc.
 * malloc'ed objects are managed by mark-and-sweep collector.
 * objsize: allocation size except object header in bytes.
 */
void *sml_obj_malloc(size_t objsize);

/*
 * write barrier for global memory.
 * writeaddr : write address.
 * objaddr : address of object including writeaddr.
 *
 * Write barrier must call this function if writeadr is not in heap.
 */
void sml_global_barrier(void **writeaddr, void *objaddr);

/*
 * trace pointer which is outside of heap.
 * ptr: pointer to be traced.
 *
 * Garbage collector must call this function when it meets an ML object
 * pointer at outside of its heap.
 * If ptr is NULL, garbage collector is not needed to call this function.
 */
void sml_trace_ptr(void *ptr);

/*
 * pop and mark malloc'ed objects until mark stack of malloc heap becomes
 * empty.
 *
 * Garbage collector must call this function at tracing phase.
 * Before leaving tracing phase, make sure that the mark stack of malloc heap
 * is empty.
 * It returns true if there is some malloc'ed object poped.
 */
int sml_malloc_pop_and_mark(void (*trace)(void **), enum sml_gc_mode mode);

/*
 * sweep malloc'ed objects.
 *
 * Garbage collector must call this function at collection phase.
 */
void sml_malloc_sweep(enum sml_gc_mode);

/*
 * enumerate pointers in all malloc'ed objects.
 */
void sml_malloc_enum_ptr(void (*trace)(void **));

/*
 * register a finalizer function for an malloc'ed object.
 * obj : malloc'ed object which is related to the finalizer.
 * finalizer : finalizer function. This function is invoked when the object
 *             is to be freed.
 */
void sml_set_finalizer(void *obj, void (*finalizer)(void *obj));

/*
 * Check whether each finalizer-related object is traced at the last live
 * object tracing and activate finalizer functions if the object is not
 * traced.
 * trace_rec : trace given object and its descendants in the heap.
 *
 * Garbage collector must call this function between tracing phase and
 * collection phase.
 */
void sml_check_finalizer(void (*trace_rec)(void **), enum sml_gc_mode mode);

/*
 * Execute finalizers which are activated by sml_check_finalizer.
 * reserved_obj : an uninitialized object to be saved from garbage collection.
 *
 * Garbage collector must call this function after garbage collection is
 * finished.
 *
 * Note that sml_run_finalizer may run ML code, so object allocation and
 * garbage collection may occur. Hence after calling sml_check_finalizer,
 * heap may be full. If an allocation function calls this function, allocate
 * a new object before calling this function and pass the new object to this
 * function as reserved_obj. This function protects the new object from
 * garbage collection and ensures that the new object is live even after
 * finalizer execution.
 */
void *sml_run_finalizer(void *reserved_obj);

#endif /* SMLSHARP__OBJSPACE_H__ */
