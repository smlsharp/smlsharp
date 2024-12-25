/**
 * smlsharp.h - SML# runtime implemenatation
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 */
#ifndef SMLSHARP__SMLSHARP_H__
#define SMLSHARP__SMLSHARP_H__

#if !defined __STDC_VERSION__ || __STDC_VERSION__ < 199901L
# error C99 is required
#endif
#if defined __GNUC__ && __GNUC__ < 4
#error GCC version 4.0 or later is required
#endif

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif
#include <stddef.h>
#include <assert.h>
#include <inttypes.h>
#include <pthread.h>
#include <sched.h>
#ifdef HAVE_STDATOMIC_H
# include <stdatomic.h>
#endif

#ifndef HAVE_STDATOMIC_H
# ifdef HAVE_GCC_ATOMIC
#  define _Atomic(ty) __typeof__(ty)
#  define memory_order_relaxed __ATOMIC_RELAXED
#  define memory_order_acquire __ATOMIC_ACQUIRE
#  define memory_order_release __ATOMIC_RELEASE
#  define memory_order_acq_rel __ATOMIC_ACQ_REL
#  define memory_order_seq_cst __ATOMIC_SEQ_CST
#  define ATOMIC_VAR_INIT(v) (v)
#  define atomic_init(p, val) (void)(*(p) = (val))
#  define atomic_load_explicit(p, order) \
	__atomic_load_n(p, order)
#  define atomic_store_explicit(p, val, order) \
	__atomic_store_n(p, val, order)
#  define atomic_compare_exchange_weak_explicit(p, expect, val, succ, fail) \
	__atomic_compare_exchange_n(p, expect, val, 1, succ, fail)
#  define atomic_compare_exchange_strong_explicit(p, expect, val, succ, fail) \
	__atomic_compare_exchange_n(p, expect, val, 0, succ, fail)
#  define atomic_exchange_explicit(p, val, order) \
	__atomic_exchange_n(p, val, order)
#  define atomic_fetch_add_explicit(p, arg, order) \
	__atomic_fetch_add(p, arg, order)
#  define atomic_fetch_sub_explicit(p, arg, order) \
	__atomic_fetch_sub(p, arg, order)
#  define atomic_fetch_or_explicit(p, arg, order) \
	__atomic_fetch_or(p, arg, order)
#  define atomic_fetch_and_explicit(p, arg, order) \
	__atomic_fetch_and(p, arg, order)
#  define atomic_fetch_xor_explicit(p, arg, order) \
	__atomic_fetch_xor(p, arg, order)
# else
#  error atomic builtins are required
# endif /* HAVE_GCC_ATOMIC */
#endif /* !HAVE_STDATOMIC_H */

/* short hands for frequently used synchronization primitives */
#define load_relaxed(p) \
	atomic_load_explicit(p, memory_order_relaxed)
#define load_acquire(p) \
	atomic_load_explicit(p, memory_order_acquire)
#define store_relaxed(p,v) \
	atomic_store_explicit(p, v, memory_order_relaxed)
#define store_release(p,v) \
	atomic_store_explicit(p, v, memory_order_release)
#define cmpswap_relaxed(p,e,v) \
	atomic_compare_exchange_strong_explicit \
	  (p, e, v, memory_order_relaxed, memory_order_relaxed)
#define cmpswap_acquire(p,e,v) \
	atomic_compare_exchange_strong_explicit \
	  (p, e, v, memory_order_acquire, memory_order_acquire)
#define cmpswap_release(p,e,v) \
	atomic_compare_exchange_strong_explicit \
	  (p, e, v, memory_order_release, memory_order_relaxed)
#define cmpswap_acq_rel(p,e,v) \
	atomic_compare_exchange_strong_explicit \
	  (p, e, v, memory_order_acq_rel, memory_order_acquire)
#define cmpswap_weak_relaxed(p,e,v) \
	atomic_compare_exchange_weak_explicit \
	  (p, e, v, memory_order_relaxed, memory_order_relaxed)
#define cmpswap_weak_acquire(p,e,v) \
	atomic_compare_exchange_weak_explicit \
	  (p, e, v, memory_order_acquire, memory_order_acquire)
#define cmpswap_weak_release(p,e,v) \
	atomic_compare_exchange_weak_explicit \
	  (p, e, v, memory_order_release, memory_order_relaxed)
#define cmpswap_weak_acq_rel(p,e,v) \
	atomic_compare_exchange_weak_explicit \
	  (p, e, v, memory_order_acq_rel, memory_order_acquire)
#define swap(order,p,v) \
	atomic_exchange_explicit(p, v, memory_order_##order)
#define fetch_add(order,p,v) \
	atomic_fetch_add_explicit(p, v, memory_order_##order)
#define fetch_sub(order,p,v) \
	atomic_fetch_sub_explicit(p, v, memory_order_##order)
#define fetch_or(order,p,v) \
	atomic_fetch_or_explicit(p, v, memory_order_##order)
#define fetch_and(order,p,v) \
	atomic_fetch_and_explicit(p, v, memory_order_##order)
#define fetch_xor(order,p,v) \
	atomic_fetch_xor_explicit(p, v, memory_order_##order)
#define ASSERT_ERROR_(e) \
	do { int no_error ATTR_UNUSED = e; assert(no_error == 0); } while (0)
#define mutex_init(m) ASSERT_ERROR_(pthread_mutex_init(m, NULL))
#define mutex_destroy(m) ASSERT_ERROR_(pthread_mutex_destroy(m))
#define mutex_lock(m) ASSERT_ERROR_(pthread_mutex_lock(m))
#define mutex_unlock(m) ASSERT_ERROR_(pthread_mutex_unlock(m))
#define cond_init(c) ASSERT_ERROR_(pthread_cond_init(c, NULL))
#define cond_destroy(c) ASSERT_ERROR_(pthread_cond_destroy(c))
#define cond_wait(c, m) ASSERT_ERROR_(pthread_cond_wait(c, m))
#define cond_broadcast(c) ASSERT_ERROR_(pthread_cond_broadcast(c))
#define cond_signal(c) ASSERT_ERROR_(pthread_cond_signal(c))

/*
 * support for thread local variables (tlv)
 */
#define single_tlv_alloc(ty, k, destructor)  static ty single_tlv__##k##__
#define single_tlv_init(k)  ((void)0)
#define single_tlv_get(k)  (single_tlv__##k##__)
#define single_tlv_set(k,v)  ((void)(single_tlv__##k##__ = (v)))

#define pth_tlv_alloc__(ty, k, destructor) \
	static pthread_key_t pth_tlv_key__##k##__; \
	static pthread_once_t pth_tlv_key__##k##__once__ = PTHREAD_ONCE_INIT; \
	static void pth_tlv_destruct__##k##__(void *p__) { destructor(p__); } \
	static void pth_tlv_init__##k##__once__() { \
		pthread_key_create(&pth_tlv_key__##k##__, \
				   pth_tlv_destruct__##k##__); \
	} \
	static inline void pth_tlv_init__##k##__() { \
		pthread_once(&pth_tlv_key__##k##__once__, \
			     pth_tlv_init__##k##__once__); \
	} \
	static inline void pth_tlv_set__##k##__(ty const arg__) { \
		pth_tlv_init__##k##__(); \
		pthread_setspecific(pth_tlv_key__##k##__, arg__); \
	}
#define pth_tlv_alloc(ty, k, destructor) \
	pth_tlv_alloc__(ty, k, destructor) \
	static inline ty pth_tlv_get__##k##__() { \
		return pthread_getspecific(pth_tlv_key__##k##__); \
	}
#define pth_tlv_init(k) (pth_tlv_init__##k##__())
#define pth_tlv_get(k) (pth_tlv_get__##k##__())
#define pth_tlv_set(k,v) (pth_tlv_set__##k##__(v))

/* Even if operating system provides thread local storage (TLS), we use
 * pthread_key in order to ensure that thread local variables are correctly
 * destructed even if the thread terminates abnormally.  To ensure this,
 * tlv_set operation updates both TLS and pthread_key.  This makes tlv_set
 * slower.  This overhead should be negligible since tlv_set is typically
 * used only at thread initialization.  In contrast, tlv_get only reads TLS;
 * so, it is pretty fast.  In Linux, tlv_get is often compiled to just one
 * CPU instruction. */
#define tls_tlv_alloc(ty, k, destructor) \
	pth_tlv_alloc__(ty, k, destructor) \
	static _Thread_local ty tls_tlv__##k##__; \
	static inline void tls_tlv_set__##k##__(ty const arg__) { \
		pth_tlv_set__##k##__(arg__); \
		tls_tlv__##k##__ = arg__; \
	}
#define tls_tlv_init(k) (pth_tlv_init__##k##__())
#define tls_tlv_get(k) (tls_tlv__##k##__)
#define tls_tlv_set(k,v) (tls_tlv_set__##k##__(v))

/* thread local variables for massivethreads.
 * The massivethreads library uses pthread for worker threads.
 * Therefore, we can use pthread_key_t for worker-local variables.
 * In addition, since user threads are non-preemptive, pthread
 * synchronization primitives may work safely (but less efficient) even in
 * a user thread. */
#define mth_tlv_alloc(ty, k, destructor) \
	static myth_key_t mth_tlv_key__##k##__; \
	static myth_once_t mth_tlv_key__##k##__once__; \
	static void mth_tlv_destruct__##k##__(void *p__) { destructor(p__); } \
	static void mth_tlv_init__##k##__once__() { \
		myth_key_create(&mth_tlv_key__##k##__, \
				mth_tlv_destruct__##k##__); \
	} \
	static inline void mth_tlv_init__##k##__() { \
		myth_once(&mth_tlv_key__##k##__once__, \
			  mth_tlv_init__##k##__once__); \
	} \
	static inline void mth_tlv_set__##k##__(ty const arg__) { \
		mth_tlv_init__##k##__(); \
		myth_setspecific(mth_tlv_key__##k##__, arg__); \
	} \
	static inline ty mth_tlv_get__##k##__() { \
		return myth_getspecific(mth_tlv_key__##k##__); \
	}
#define mth_tlv_init(k) (mth_tlv_init__##k##__())
#define mth_tlv_get(k) mth_tlv_get__##k##__()
#define mth_tlv_set(k,v) (mth_tlv_set__##k##__(v))

#ifdef HAVE_TLS
#define worker_tlv_alloc tls_tlv_alloc
#define worker_tlv_init tls_tlv_init
#define worker_tlv_get tls_tlv_get
#define worker_tlv_set tls_tlv_set
#else /* HAVE_TLS */
#define worker_tlv_alloc pth_tlv_alloc
#define worker_tlv_init pth_tlv_init
#define worker_tlv_get pth_tlv_get
#define worker_tlv_set pth_tlv_set
#endif /* HAVE_TLS */

#define user_tlv_alloc mth_tlv_alloc
#define user_tlv_init mth_tlv_init
#define user_tlv_get mth_tlv_get
#define user_tlv_set mth_tlv_set

#define worker_tlv_get_or_init(k) (worker_tlv_init(k), worker_tlv_get(k))
#define user_tlv_get_or_init(k) (user_tlv_init(k), user_tlv_get(k))


/* helpful attributes */

#ifdef __GNUC__
# define ALWAYS_INLINE __attribute__((always_inline))
# define NOINLINE __attribute__((noinline))
# define ATTR_MALLOC __attribute__((malloc))
# define ATTR_PURE __attribute__((pure))
# define ATTR_NONNULL(n) __attribute__((nonnull(n)))
# define ATTR_PRINTF(m,n) __attribute__((format(printf,m,n))) ATTR_NONNULL(m)
# define ATTR_NORETURN __attribute__((noreturn))
# define ATTR_UNUSED __attribute__((unused))
#else
# define ALWAYS_INLINE inline
# define NOINLINE
# define ATTR_MALLOC
# define ATTR_PURE
# define ATTR_NONNULL(n)
# define ATTR_PRINTF(m,n)
# define ATTR_NORETURN
# define ATTR_UNUSED
#endif /* __GNUC__ */

/*
 * The calling convention for SML# runtime primitives.
 * The SML# compiler emits call sequences compliant with this convention
 * for runtime primitive calls.
 */
#ifdef __GNUC__
/* first three arguments are passed by machine registers */
# ifdef HOST_CPU_i386
#  define SML_PRIMITIVE __attribute__((regparm(3),nothrow)) NOINLINE
# elif HOST_CPU_ARM
#  define SML_PRIMITIVE __attribute__((nothrow)) NOINLINE
# endif
#else
# error regparm(3) calling convention is not supported
#endif

/*
 * macros for calculating size
 */
/* the number of elements of an array. */
#define arraysize(a)    (sizeof(a) / sizeof(a[0]))
/* CEIL(x,y) : round x upwards to the nearest multiple of y. */
#define CEILING(x,y)  (((x) + (y) - 1) - ((x) + (y) - 1) % (y))

/*
 * the most conservative memory alignment.
 * It should be differed for each architecture.
 */
#ifndef MAXALIGN
# if defined HAVE_ALIGNOF && defined HAVE_MAX_ALIGN_T
#  define MAXALIGN alignof(max_align_t)
# elif defined HAVE_ALIGNOF
#  define MAXALIGN \
	alignof(union { long long n; double d; long double x; void *p; })
# else
#  define MAXALIGN \
	sizeof(union { long long n; double d; long double x; void *p; })
# endif
#endif

/*
 * print fatal error message and abort the program.
 * err : error status describing why this error happened.
 *       (0: no error status, positive: system errno, negative: runtime error)
 * format, ... : standard output format (same as printf)
 */
void sml_fatal(int err, const char *format, ...)
	ATTR_PRINTF(2, 3) ATTR_NORETURN;
/* print error message. */
void sml_error(int err, const char *format, ...) ATTR_PRINTF(2, 3);
/* print warning message. */
void sml_warn(int err, const char *format, ...) ATTR_PRINTF(2, 3);
/* print fatal error message with system error status and abort the program. */
void sml_sysfatal(const char *format, ...) ATTR_PRINTF(1, 2) ATTR_NORETURN;
/* print error message with system error status. */
void sml_syserror(const char *format, ...) ATTR_PRINTF(1, 2);
/* print warning message with system error status. */
void sml_syswarn(const char *format, ...) ATTR_PRINTF(1, 2);
/* print notice message if verbosity >= MSG_NOTICE */
void sml_notice(const char *format, ...) ATTR_PRINTF(1, 2);
/* print debug message if verbosity >= MSG_DEBUG */
void sml_debug(const char *format, ...) ATTR_PRINTF(1, 2);

void sml_msg_init(void);

/* pretty alternative to #ifndef NDEBUG ... #endif */
#ifndef NDEBUG
#define DEBUG(e) do { e; } while (0)
#else
#define DEBUG(e) do { } while (0)
#endif

/* for performance debug */
#define asm_rdtsc() ({ \
	uint32_t a__, d__; \
	__asm__ volatile ("rdtsc" : "=a" (a__), "=d" (d__)); \
	((uint64_t)d__ << 32) | a__; \
})

#ifdef HOST_CPU_i386
#define asm_pause() do { __asm__ volatile ("pause" ::: "memory"); } while(0)
#elif HOST_CPU_ARM
#define asm_pause() do { __asm__ volatile ("wfe" ::: "memory"); } while(0)
#endif

/*
 * malloc with error checking
 * If allocation failed, program exits immediately.
 */
void *sml_xmalloc(size_t size) ATTR_MALLOC;
void *sml_xrealloc(void *p, size_t size) ATTR_MALLOC;
#define xmalloc sml_xmalloc
#define xrealloc sml_xrealloc

/*
 * GC root set management including stack frame layouts
 */
struct sml_frame_layout {
	uint16_t num_safe_points;
	uint16_t frame_size;      /* in words */
	uint16_t num_roots;
	uint16_t root_offsets[];  /* in words */
};

void sml_gcroot(void *, void (*)(void), void *, void *);
struct sml_gcroot *sml_gcroot_load(void (* const *)(void *), unsigned int);
void sml_gcroot_unload(struct sml_gcroot *);
const struct sml_frame_layout *sml_lookup_frametable(void *retaddr);
void sml_global_enum_ptr(void (*trace)(void **, void *), void *data);

/* remove all thread-local data for SML# */
void sml_deatch(void);

/*
 * thread management
 */
void sml_control_init(void);

/* create an SML# execution context for current thread.
 * This is called when program or a callback starts.
 * Its argument is 3-pointer-size work area for SML# runtime. */
SML_PRIMITIVE void sml_start(void *);
/* destroy current SML# execution context.
 * This is called when program or a callback exits. */
SML_PRIMITIVE void sml_end(void);
/* leave current SML# excecution context temporarily.
 * This is called before calling a foreign function. */
SML_PRIMITIVE void sml_leave(void);
/* reenter current SML# excecution context.
 * This is called after returning from a foreign function. */
SML_PRIMITIVE void sml_enter(void);
/* save current frame pointer to SML# execution context for further root
 * set enumeration that would be carried out by a runtime primitive.
 * This is called before calling a primitive function that would allocate an
 * SML# object. */
SML_PRIMITIVE void sml_save(void);
/* clear the saved frame pointer by sml_save.
 * This is called after returning from an object-allocating runtime primitive
 * function. */
SML_PRIMITIVE void sml_unsave(void);
/* check collector's state and perform synchronization if needed. */
SML_PRIMITIVE void sml_check(unsigned int);
/* a flag indicating that mutators are requested to be synchronized.
 * If this is non-zero, mutators must call sml_check at their GC safe point
 * as soon as possible. */
extern _Atomic(unsigned int) sml_check_flag;
/* the main routine of garbage collection */
unsigned long sml_gc(int);
unsigned long sml_wait_gc(void *);

struct sml_user;
struct sml_worker;
struct sml_alloc;
void sml_stack_enum_ptr(struct sml_user *, void (*)(void **, void *), void *);

struct sml_alloc_cons {
	struct sml_alloc *alloc;
	struct sml_worker *next;
};
struct sml_alloc_cons sml_get_allocators(void);
struct sml_alloc_cons sml_next_allocator(struct sml_worker *);

typedef void (*sml_check_hook_fn)(void);
sml_check_hook_fn sml_set_check_hook(sml_check_hook_fn hook);
void sml_call_with_cleanup(void(*)(void), void(*)(void*,void*,void*), void*);

enum sml_sync_phase {
	PREASYNC = 0,           /* 000 = MARK ^ (MARK ^ PREASYNC) */
	ASYNC = 1,              /* 001 = PREASYNC | 001 */
	PRESYNC1 = 2,           /* 010 = ASYNC ^ (ASYNC ^ PRESYNC1) */
	SYNC1 = 3,              /* 011 = PRESYNC1 | 001 */
	PRESYNC2 = 4,           /* 100 = SYNC1 ^ (SYNC1 ^ PRESYNC2) */
	SYNC2 = 5,              /* 101 = PRESYNC2 | 001 */
	PREMARK = 6,            /* 110 = SYNC2 ^ (SYNC2 ^ PREMARK) */
	MARK = 7,               /* 111 = PREMARK | 001 */
	DUMMY_PHASE = 16        /* used for worker initialization */
};

void sml_check_internal(void *frame_pointer);
enum sml_sync_phase sml_current_phase(void);
int sml_saved(void); /* for debug */

SML_PRIMITIVE void sml_save_exn(void *);
SML_PRIMITIVE void *sml_unsave_exn(void *);

/*
 * stack frame address
 * FIXME: platform dependent
 */
#define CALLER_FRAME_END_ADDRESS() \
	((void**)__builtin_frame_address(0) + 2)
#define FRAME_CODE_ADDRESS(frame_end) \
	(*((void**)(frame_end) - 1))
#ifdef HOST_CPU_i386
#define NEXT_FRAME(frame_begin) \
	((void**)frame_begin + 1)
#elif HOST_CPU_ARM
#define NEXT_FRAME(frame_begin) ((void**)frame_begin)
#endif

/*
 * SML# heap object management
 */
/*void *sml_try_alloc(unsigned int objsize);*/
SML_PRIMITIVE void *sml_alloc(unsigned int objsize);
SML_PRIMITIVE void *sml_load_intinf(const char *hexsrc);
SML_PRIMITIVE void **sml_find_callback(void *codeaddr, void *env);
SML_PRIMITIVE void *sml_alloc_code(void);

SML_PRIMITIVE int sml_obj_equal(void *obj1, void *obj2);
SML_PRIMITIVE void sml_write(void *objaddr, void **writeaddr, void *new_value);
void sml_copyary(void **src, unsigned int si, void **dst, unsigned int di,
		 unsigned int len);

struct sml_intinf;
typedef struct sml_intinf sml_intinf_t;

void sml_obj_enum_ptr(void *obj, void (*callback)(void **, void *), void *);
void *sml_obj_alloc(unsigned int objtype, size_t payload_size);
NOINLINE char *sml_str_new(const char *str);
char *sml_str_new2(const char *str, unsigned int len);
sml_intinf_t *sml_intinf_new(void);
void *sml_intinf_hex(void *obj);

/*
 * exception support
 */
void sml_matchcomp_bug(void) ATTR_NORETURN;

SML_PRIMITIVE void sml_raise(void *exn) ATTR_NORETURN;
/*
_Unwind_Reason_Code
sml_personality(int version, _Unwind_Action actions, uint64_t exnclass,
		struct _Unwind_Exception *exception,
		struct _Unwind_Context *context);
*/

/*
 * callback support
 */
void sml_callback_init(void);
void sml_callback_destroy(void);
void sml_callback_enum_ptr(void (*trace)(void **, void *), void *data);
SML_PRIMITIVE void **sml_find_callback(void *codeaddr, void *env);
SML_PRIMITIVE void *sml_alloc_code(void);

/*
 * finalizer support
 */
void sml_finalize_init(void);
void sml_finalize_destroy(void);
void sml_set_finalizer(void *obj, void (*finalizer)(void *));
void sml_run_finalizer(void);

/*
 * Initialize and finalize SML# runtime
 */
void sml_init(int argc, char **argv);
void sml_finish(void);
ATTR_NORETURN void sml_exit(int status);

/*
 * bit pointer
 */
typedef uint32_t sml_bmword_t;
struct sml_bitptr { const sml_bmword_t *ptr; sml_bmword_t mask; };
struct sml_bitptrw { sml_bmword_t *wptr; sml_bmword_t mask; };
struct sml_bitptra { _Atomic(sml_bmword_t) *wptr; sml_bmword_t mask; };
typedef struct sml_bitptr sml_bitptr_t;
typedef struct sml_bitptrw sml_bitptrw_t;
typedef struct sml_bitptra sml_bitptra_t;
#define BITPTR_WORDBITS  32U
#define BITPTR(p,n) \
	((sml_bitptr_t){.ptr = (p) + (n) / 32U, .mask = 1 << ((n) % 32U)})
#define BITPTRW(p,n) \
	((sml_bitptrw_t){.wptr = (p) + (n) / 32U, .mask = 1 << ((n) % 32U)})
#define BITPTRA(p,n) \
	((sml_bitptra_t){.wptr = (p) + (n) / 32U, .mask = 1 << ((n) % 32U)})

static inline int BITPTRA_TEST_AND_SET(sml_bitptra_t b)
{
	sml_bmword_t old = load_relaxed(b.wptr);
	do {
		if (old & b.mask)
			return 1;
	} while (!cmpswap_relaxed(b.wptr, &old, old | b.mask));
	return 0;
}

#define BITPTRA_TEST(b)  (load_relaxed((b).wptr) & (b).mask)
#define BITPTRW_TEST(b)  (*((b).wptr) & (b).mask)
#define BITPTRW_SET(b)  (*((b).wptr) |= (b).mask)

#define BITPTR_TEST(b)  (*(b).ptr & (b).mask)
#define BITPTR_WORD(b)  (*(b).ptr)
#define BITPTR_EQUAL(b1,b2)  ((b1).ptr == (b2).ptr && (b1).mask == (b2).mask)
#define BITPTR_WORDINDEX(b,begin)  ((b).ptr - (begin))
#define BITPTR_NEXTWORD(b)  ((b).ptr++, (b).mask = 1U)

/* BITPTR_NEXT0: move to next 0 bit in the current word.
 * mask becomes zero if failed. */
#define BITPTR_NEXT0(b) do { \
	uint32_t tmp__ = *(b).ptr | ((b).mask - 1U); \
	(b).mask = (tmp__ + 1U) & ~tmp__; \
} while (0)
#define BITPTR_NEXT_FAILED(b)  ((b).mask == 0)

/* BITPTR_NEXT1: move to next 1 bit in the current word.
 * mask becomes zero if failed. */
#define BITPTR_NEXT1(b) do { \
	uint32_t tmp__ = *(b).ptr & -((b).mask << 1); \
	(b).mask = tmp__ & -tmp__; \
} while (0)

/* BITPTR_INC: move to the next bit */
#define BITPTR_INC(b) do { \
	(b).ptr += ((b).mask >> 31); \
	(b).mask = ((b).mask << 1) | ((b).mask >> 31); \
} while (0)

/* BITPTR_MASKINDEX: returns the bit index of the mask */
#define BITPTR_MASKINDEX(b) __builtin_ctz((b).mask)

/* BITPTR_INDEX: returns the bit offset of bitptr b from p */
#define BITPTR_INDEX(b,p) \
	(BITPTR_WORDINDEX(b,p) * BITPTR_WORDBITS + BITPTR_MASKINDEX(b))

/* CEIL_LOG2: ceiling the given integer x to the smallest 2^i larger than x.
 * x must not be 1. */
#define CEIL_LOG2(x)  (32 - __builtin_clz((uint32_t)(x) - 1))

/*
 * memory page allocation
 */
#ifdef MINGW32
/* include <windows.h> */
#define GetPageSize() ({ SYSTEM_INFO si; GetSystemInfo(&si); si.dwPageSize; })
#define AllocPageError NULL
#define AllocPage(addr, size) \
	VirtualAlloc(addr, size, MEM_COMMIT, PAGE_EXECUTE_READWRITE)
#define ReservePage(addr, size)	\
	VirtualAlloc(addr, size, MEM_RESERVE, PAGE_NOACCESS)
#define ReleasePage(addr, size) \
	VirtualFree(addr, size, MEM_RELEASE)
#define CommitPage(addr, size) \
	VirtualAlloc(addr, size, MEM_COMMIT, PAGE_EXECUTE_READWRITE)
#define UncommitPage(addr, size) \
	VirtualFree(addr, size, MEM_DECOMMIT)
#else
/* inclue <sys/mman.h> */
/* inclue <unistd.h> */
#define GetPageSize() sysconf(_SC_PAGESIZE)
#define AllocPageError MAP_FAILED
#define AllocPage(addr, size) \
	mmap(addr, size, PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0)
#define ReservePage(addr, size) \
	mmap(addr, size, PROT_NONE, MAP_ANON | MAP_PRIVATE, -1, 0)
#define ReleasePage(addr, size) \
	munmap(addr, size)
#define CommitPage(addr, size) \
	mprotect(addr, size, PROT_READ | PROT_WRITE)
#define UncommitPage(addr, size) \
	mmap(addr, size, PROT_NONE, MAP_ANON | MAP_PRIVATE | MAP_FIXED, -1, 0)
#endif /* MINGW32 */

#endif /* SMLSHARP__SMLSHARP_H__ */
