/**
 * smlsharp.h - SML# runtime implemenatation
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 */
#ifndef SMLSHARP__SMLSHARP_H__
#define SMLSHARP__SMLSHARP_H__

#include <stddef.h>

/* FILELINE : "<filename>:<lineno>(<function>)" for debug */
#if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
#define __func__ __func__
#elif defined __GNUC__ && __GNUC__ >= 2
#define __func__ __extension__ __FUNCTION__
#else
#define __func__ "(unknown)"
#endif
#define FILELINE__(x,y) x":"#y
#define FILELINE_(x,y) FILELINE__(x,y)
#define FILELINE FILELINE_(__FILE__, __LINE__)

#if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
#define restrict restrict
#elif defined __GNUC__ && __GNUC__ >= 3
#define restrict __restrict__
#else
#define restrict
#endif

#if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
#define inline inline
#elif defined __GNUC__ && __GNUC__ >= 2
#define inline __inline__
#else
#define inline
#endif

#if defined __GNUC__ && __GNUC__ >= 2
#define NOINLINE __attribute__((noinline))
#else
#define NOINLINE
#endif

/* GNU C extensions */

#ifndef GCC_VERSION
#ifdef __GNUC__
#define GCC_VERSION (__GNUC__ * 1000 + __GNUC_MINOR__)
#endif
#endif /* GCC_VERSION */

#if defined(__GNUC__) && GCC_VERSION >= 2096
#define ATTR_MALLOC __attribute__((malloc))
#else
#define ATTR_MALLOC
#endif

#if defined(__GNUC__) && GCC_VERSION >= 3000
#define ATTR_PURE __attribute__((pure))
#else
#define ATTR_PURE
#endif

#if defined(__GNUC__) && GCC_VERSION >= 3003
#define ATTR_NONNULL(n) __attribute__((nonnull(n)))
#else
#define ATTR_NONNULL(n)
#endif

#if defined(__GNUC__)
#define ATTR_PRINTF(m,n) __attribute__((format(printf,m,n))) ATTR_NONNULL(m)
#endif

#if defined(__GNUC__)
#define ATTR_NORETURN __attribute__((noreturn))
#endif

#if defined(__GNUC__)
#define ATTR_UNUSED __attribute__((unused))
#endif

#if defined(__GNUC__)
/* Boland fastcall; %eax, %edx, %ecx */
#define SML_PRIMITIVE __attribute__((regparm(3)))
#else
/* Microsoft fastcall; %ecx, %edx */
/* #define SML_PRIMITIVE __attribute__((fastcall)) */
#define SML_PRIMITIVE
#endif

/* the number of elements of an array. */
#define arraysize(a)   (sizeof(a) / sizeof(a[0]))

/* ALIGNSIZE(x,y) : round up x to the multiple of y. */
#define ALIGNSIZE(x,y)  (((x) + (y) - 1) - ((x) + (y) - 1) % (y))

/* the most conservative memory alignment.
 * It should be differed for each architecture. */
#ifndef MAXALIGN
union sml__alignment__ {
	char c; short s; int i; long n;
	float f; double d; long double x; void *p;
};
#define MAXALIGN    (sizeof(union sml__alignment__))
#endif

/*
 * print fatal error message and abort the program.
 * err : error status describing why this error happened.
 *       (0: no error status, positive: system errno, negative: runtime error)
 * format, ... : standard output format (same as printf)
 */
void sml_fatal(int err, const char *format, ...)
     ATTR_PRINTF(2, 3) ATTR_NORETURN;

/*
 * print error message.
 */
void sml_error(int err, const char *format, ...) ATTR_PRINTF(2, 3);

/*
 * print warning message.
 */
void sml_warn(int err, const char *format, ...) ATTR_PRINTF(2, 3);

/*
 * print fatal error message with system error status and abort the program.
 */
void sml_sysfatal(const char *format, ...) ATTR_PRINTF(1, 2) ATTR_NORETURN;

/*
 * print error message with system error status.
 */
void sml_syserror(const char *format, ...) ATTR_PRINTF(1, 2);

/*
 * print warning message with system error status.
 */
void sml_syswarn(const char *format, ...) ATTR_PRINTF(1, 2);

/*
 * print notice message.
 */
void sml_notice(const char *format, ...) ATTR_PRINTF(1, 2);

/*
 * print debug message.
 */
void sml_debug(const char *format, ...) ATTR_PRINTF(1, 2);

/*
 * DBG((format, ...));
 * print debug message.
 *
 * ASSERT(cond);
 * abort the program if cond is not satisfied.
 *
 * FATAL((err, format, ...));
 * print fatal error message with position and abort the program.
 *
 * DBG and ASSERT are enabled only if the program is compiled in debug mode.
 */
#if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
#define DEBUG__(fmt, ...) \
	sml_debug("%s:%d:%s: "fmt"\n", __FILE__,__LINE__,__func__,__VA_ARGS__)
#define DEBUG_(args) DEBUG__ args
#define FATAL__(err, fmt, ...) \
	sml_fatal(err, "%s:%d:%s: "fmt, __FILE__,__LINE__,__func__,__VA_ARGS__)
#define FATAL(args) FATAL__ args
#elif defined __GNUC__
#define DEBUG__(fmt, args...) \
	sml_debug("%s:%d:%s: "fmt"\n", __FILE__,__LINE__,__func__,##args)
#define DEBUG_(args) DEBUG__ args
#define FATAL__(err, fmt, args...) \
	sml_fatal(err, "%s:%d:%s: "fmt, __FILE__,__LINE__,__func__,##args)
#define FATAL(args) FATAL__ args
#else
#define DEBUG_(args) \
	((void)sml_debug("%s:%d: ", __FILE__,__LINE__), \
	 (void)sml_debug args, \
	 (void)sml_debug("\n"))
#define FATAL(args) (sml_fatal args)
#endif

#ifdef DEBUG
#define DBG(args) DEBUG_(args)
#else
#define DBG(args)
#endif /* DEBUG */

#if defined DEBUG || defined ENABLE_ASSERT
#define ASSERT(expr) \
	((expr) ? (void)0 : (void)FATAL((0, "assertion failed: %s", #expr)))
#else
#define ASSERT(expr) ((void)0)
#endif /* ENABLE_ASSERT */

/*
 * for internal use.
 */
enum sml_msg_level {
	MSG_FATAL,
	MSG_ERROR,
	MSG_WARN,
	MSG_NOTICE,
	MSG_DEBUG
};
void sml_set_verbose(enum sml_msg_level level);
#if 0
void sml_msg_set_hook(FILE *(*start_hook)(enum sml_msg_level level),
		      void (*end_hook)(FILE *f, enum sml_msg_level level));
#endif

/*
 * safe malloc and realloc.
 */
void *xmalloc(size_t size) ATTR_MALLOC;
void *xrealloc(void *p, size_t size) ATTR_MALLOC;

#if 0
void xfree(void *);
#define free xfree
#ifdef DEBUG
void *sml_xmem_debug(void *p, const char *prefix, const char *pos);
#define xmalloc(x) xmem_debug(xmalloc(x), "xmalloc", FILELINE)
#define xrealloc(x) xmem_debug(xrealloc(x), "xrealloc", FILELINE)
#define free(x) xmem_debug(x, "free", FILELINE)
#endif
#endif

/*
 * naive obstack implementation.
 * Note that this implementation doesn't take care of object alignemnt.
 */
typedef struct sml_obstack sml_obstack_t;
void sml_obstack_blank(sml_obstack_t **obstack, size_t size);
void *sml_obstack_finish(sml_obstack_t *obstack);
void *sml_obstack_base(sml_obstack_t *obstack);
void *sml_obstack_next_free(sml_obstack_t *obstack);
size_t sml_obstack_object_size(sml_obstack_t *obstack);
void *sml_obstack_alloc(sml_obstack_t **obstack, size_t size);
void sml_obstack_free(sml_obstack_t **obstack, void *ptr);

void sml_obstack_align(sml_obstack_t **obstack, size_t size);

/* use obstack growing object as extensible array */
void *sml_obstack_extend(sml_obstack_t **obstack, size_t size);
void sml_obstack_shrink(sml_obstack_t **obstack, void *p);

/* enumerate chunks in obstack */
void sml_obstack_enum_chunk(sml_obstack_t *obstack,
			    void (*f)(void *start, void *end, void *data),
			    void *data);
int sml_obstack_is_empty(sml_obstack_t *obstack);

/*
 * giant lock of SML# runtime
 */
#ifdef MULTITHREAD
void sml_giant_lock(void);
void sml_giant_unlock(void);
#define GIANT_LOCK()     sml_giant_lock()
#define GIANT_UNLOCK()   sml_giant_unlock()
#else /* MULTITHREAD */
#define GIANT_LOCK()     ((void)0)
#define GIANT_UNLOCK()   ((void)0)
#endif /* MULTITHREAD */

volatile unsigned int sml_check_gc_flag;
SML_PRIMITIVE void sml_check_gc(void *frame_pointer);

/*
 * Event objects for thread synchronization
 */
typedef struct sml_event sml_event_t;
sml_event_t *sml_event_new(int no_reset, int init);
void sml_event_free(sml_event_t *event);
void sml_event_wait(sml_event_t *event);
void sml_event_signal(sml_event_t *event);
void sml_event_reset(sml_event_t *event);

typedef struct sml_counter sml_counter_t;
sml_counter_t *sml_counter_new(void);
void sml_counter_free(sml_counter_t *c);
void sml_counter_inc(struct sml_counter *c);
void sml_counter_wait(struct sml_counter *c, int min);

/*
 * SML# heap object management
 */
struct sml_intinf;
typedef struct sml_intinf sml_intinf_t;

int sml_obj_equal(void *obj1, void *obj2);
void *sml_obj_dup(void *obj);
void sml_obj_enum_ptr(void *obj, void (*callback)(void **));
void *sml_obj_alloc(unsigned int objtype, size_t payload_size);
void *sml_record_alloc(size_t payload_size);
char *sml_str_alloc(size_t len);
char *sml_str_new(const char *str);
char *sml_str_new2(const char *str, size_t len);
sml_intinf_t *sml_intinf_new(void);

SML_PRIMITIVE void *sml_alloc(unsigned int objsize, void *frame_pointer);
SML_PRIMITIVE void *sml_alloc_callback(unsigned int objsize, void *codeaddr,
				       void *envaddr);
SML_PRIMITIVE void *sml_obj_empty(void);
SML_PRIMITIVE void sml_write(void *objaddr, void **writeaddr, void *new_value);

void sml_heap_gc(void);

/* temporally root slots for C code */
void **sml_push_tmp_rootset(size_t num_slots);
void sml_pop_tmp_rootset(void **slots);

/*
 * execution context
 */
void *sml_load_frame_pointer(void);
SML_PRIMITIVE void sml_save_frame_pointer(void *p);
void *sml_current_thread_heap(void);
int sml_is_in_sync1(void);

/* called when SML code is started. */
SML_PRIMITIVE void sml_control_start(void *frame_pointer);
/* called when SML code is successfully finished. */
SML_PRIMITIVE void sml_control_finish(void *frame_pointer);

SML_PRIMITIVE void sml_check_gc(void *frame_pointer);
SML_PRIMITIVE void sml_control_suspend(void);
SML_PRIMITIVE void sml_control_resume(void);

/*
 * exception support
 */
SML_PRIMITIVE void sml_push_handler(void *);
SML_PRIMITIVE void *sml_pop_handler(void *exn);
int sml_protect(void (*func)(void *), void *data);

struct sml_exntag;
extern const struct sml_exntag sml_exntag_Bind;
extern const struct sml_exntag sml_exntag_Match;
extern const struct sml_exntag sml_exntag_Subscript;
extern const struct sml_exntag sml_exntag_Size;
extern const struct sml_exntag sml_exntag_Overflow;
extern const struct sml_exntag sml_exntag_Div;
extern const struct sml_exntag sml_exntag_Domain;
extern const struct sml_exntag sml_exntag_Fail;
extern const struct sml_exntag sml_exntag_MatchCompBug;

const void *SML4Bind;
const void *SML5Match;
const void *SML9Subscript;
const void *SML4Size;
const void *SML8Overflow;
const void *SML3Div;
const void *SML6Domain;
const void *SML4Fail;
const void *SMLN2OS6SysErrE;
const void *SMLN8SMLSharp12MatchCompBugE;

const char *sml_exn_name(void *exnobj);
void sml_matchcomp_bug(void) ATTR_NORETURN;

/*
 * Initialize and finalize SML# runtime
 */
void sml_init(int argc, char **argv);
void sml_finish(void);

#endif /* SMLSHARP__SMLSHARP_H__ */
