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
 * register an root set enumerator of current thread.
 */
typedef void sml_rootset_fn(sml_trace_cls *, enum sml_gc_mode, void *data);
void sml_add_rootset(sml_rootset_fn *enumfn, void *data);

/*
 * unregister an root set enumerator of current thread.
 */
void sml_remove_rootset(sml_rootset_fn *, void *data);

/*
 * enumerate pointer slots in root set.
 */
void sml_rootset_enum_ptr(sml_trace_cls *, enum sml_gc_mode);

/*
 * allocate an ML object by malloc.
 * malloc'ed objects are managed by mark-and-sweep collector.
 * objsize: allocation size except object header in bytes.
 */
void *sml_obj_malloc(size_t objsize);

/*
 * trace pointer which is outside of heap.
 * if ptr is a malloc'ed object, mark it and trace its children.
 * ptr: pointer to be traced.
 * trace: object trace function.
 *
 * This function will be called from garbage collector when collectors meets
 * an ML pointer at outside of heap.
 * If ptr is NULL, garbage collector may skip calling this function.
 */
void *sml_trace_ptr(void *ptr, enum sml_gc_mode);

/*
 * sweep malloc'ed objects.
 *
 * This function will be called from garbage collector at collection phase.
 */
void sml_malloc_sweep(enum sml_gc_mode);

/*
 * enumerate pointer slots in malloc'ed objects.
 */
void sml_malloc_enum_ptr(sml_trace_cls *trace);

/*
 * add writeaddr to global barrier.
 * writeaddr : address of pointer variable holding address of an ML object.
 * objaddr : address of object including writeaddr.
 *
 * This function will be called from implementation of HEAP_WRITE_BARRIER.
 */
void *sml_global_barrier(void **writeaddr, void *objaddr,
			 enum sml_gc_mode trace_mode);

/*
 * register a finalizer of current thread for an object.
 * obj : finalizable object.
 * finalize_fn : finalizer function. This function is invoked when the object
 *               is to be freed.
 * data : extra data passed to finalize_fn.
 *
 * Return value is a pointer to the finalizable object.
 * Note that obj and return value is not always equal due to garbage
 * collection invoked during finalizer registration.
 */
typedef void sml_finalizer_fn(void *obj, void *data);
void *sml_add_finalizer(void *obj, sml_finalizer_fn *finalize_fn, void *data);

/*
 * Check whether each object with finalizer survived garbage collection and
 * reserve execution of finalizer.
 * save : keep given object and its descendants alive.
 * survived : return true if given object is in heap and survives.
 *
 * This function will be called from garbage collector after survival phase
 * and before collection phase.
 */
void sml_check_finalizer(enum sml_gc_mode mode, int (*survived)(void *),
			 sml_trace_cls *save);

/*
 * Execute finalizers which are reserved by sml_check_finalizer.
 *
 * This function will be called from garbage collector after collection phase,
 * i.e., heap goes back to stable state.
 */
void sml_run_finalizer(void);

#endif /* SMLSHARP__OBJSPACE_H__ */
