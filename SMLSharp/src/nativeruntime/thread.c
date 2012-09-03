/*
 * frame.c
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 */

#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "smlsharp.h"
#include "object.h"
#include "thread.h"
#include "heap.h"

static struct sml_thread_env *thread_env;

/* return environment of current thread. */
/* FIXME: multithread */
struct sml_thread_env *
sml_thread_env_get()
{
	return thread_env;
}

static void
tmp_root_enum_ptr(void *start, void *end, void *data)
{
	sml_trace_cls *trace = data;
	void **i;
	for (i = start; i < (void**)end; i++)
		(*trace)(i, trace);
}

static void
thread_env_enum_ptr(sml_trace_cls *trace, enum sml_gc_mode mode,
		    void *thread_env)
{
	struct sml_thread_env *env = thread_env;

	sml_frame_enum_ptr(trace, mode, env);
	sml_obstack_enum_chunk(env->tmp_root, tmp_root_enum_ptr, (void*)trace);
}

void
sml_thread_env_init()
{
	struct sml_thread_env *env;

	env = xmalloc(sizeof(struct sml_thread_env));
	env->saved_frame_pointer = NULL;
	env->heap = NULL;
	env->current_handler = NULL;
	env->tmp_root = NULL;
	thread_env = env;
	sml_heap_thread_init();
	sml_add_rootset(thread_env_enum_ptr, env);
}

void
sml_thread_env_free()
{
	struct sml_thread_env *env = thread_env;

	sml_heap_thread_free();
	free(env);
	thread_env = NULL;
}

/*
 * prepares new "num_slots" pointer slots which are part of root set of garbage
 * collection, and returns the address of array of the new pointer slots.
 * These pointer slots are available until sml_pop_tmp_rootset() is called.
 * Returned address is only available in the same thread.
 */
void **
sml_push_tmp_rootset(size_t num_slots)
{
	struct sml_thread_env *env = thread_env;
	void **ret;
	unsigned int i;

	ret = sml_obstack_alloc(&env->tmp_root, sizeof(void*) * num_slots);
	for (i = 0; i < num_slots; i++)
		ret[i] = NULL;
	return ret;
}

/*
 * releases last pointer slots allocated by sml_push_tmp_rootset()
 * in the same thread.
 */
void
sml_pop_tmp_rootset(void **slots)
{
	struct sml_thread_env *env = thread_env;
	sml_obstack_free(&env->tmp_root, slots);
}

SML_PRIMITIVE void
sml_save_frame_pointer(void *p)
{
	SML_THREAD_ENV->saved_frame_pointer = p;
}

SML_PRIMITIVE void *
sml_load_frame_pointer()
{
	return SML_THREAD_ENV->saved_frame_pointer;
}

/*
 * See also RTLFrame.sml.
 *
 * Frame pointer points the address of memory holding previous frame pointer.
 * The next (in the direction of stack growing) word of the previous frame
 * pointer holds relative address of frame information word of current frame
 * from the frame pointer.
 *
 * For example, on architecture whose the stack grows down (x86 etc.),
 * [ebp + 0] is previous frame pointer, and
 * [ebp - 4] is the relative address of frame info word.
 *
 * If the relative address of the frame info is 0, then the frame has no
 * info. If the previous frame pointer is NULL, the chain of frames is
 * terminated here.
 *
 *                                     :          :
 *            +--------+               | generics |
 *            |infoaddr|-------------->+----------+
 *  ebp ----->+--------+               | info     | current frame
 *            |  prev  |               | boxed    |
 *            +--|-----+               | ...      |
 *               |                     |          |
 *               |                     :          :
 *               |
 *               |                     :          :
 *               |   +--------+        | generics |
 *               |   |infoaddr|------->+----------+
 *               +-->+--------+        | info     | previous frame
 *                   |  prev  |        | boxed    |
 *                   +---|----+        | ....     |
 *                       |             |          |
 *                       |             :          :
 *                       :
 *                       |
 *                       v
 *                      NULL
 *
 * infoaddr:
 *  31                            2    1    0
 * +--------------------------------+----+----+
 * |             address            |next| gc |
 * +--------------------------------+----+----+
 * MSB                                      LSB
 *
 * if next is 0, address & 0xfffffffc is the offset of frame info of
 * this frame from frame pointer.
 * if next is 1, address & 0xfffffffc is the absolute address of previous
 * ML frame pointer. (this is used in callback function entry for gc to
 * skip C frames between ML frames.)
 * gc bit is reserved for gc. mutator must set it to 0.
 *
 * To make sure that we may use last 2 bits for the flags, frameAlign must
 * be at least multiple of 4.
 *
 * Structure of Frame:
 *
 * addr
 *   | :               :
 *   | +---------------+ [align in frameAlign] <------- offset origin
 *   | | pre-offset    |
 *   | +===============+ ================== beginning of frame
 *   | |               |
 *   | +---------------+ [align in frameAlign]
 *   | | slots of tN   | generic slot 0 of tN
 *   | |  :            |   :
 *   | +---------------+ [align in frameAlign]
 *   | :               :
 *   | +---------------+ [align in frameAlign]
 *   | | slots of t1   | generic slot 0 of t1
 *   | :               :   :
 *   | +---------------+ [align in frameAlign]
 *   | | slots of t0   | generic slot 0 of t0
 *   | |               | generic slot 1 of t0
 *   | :               :   :
 *   | +---------------+ [align in frameAlign]
 *   | | frame info    | info = (numBoxed, numBitmapBits)
 *   | +---------------+ [align in unsigned int]
 *   | |               |
 *   | +---------------+ [align in void*]
 *   | | boxed part    |
 *   | :               :
 *   | |               |
 *   | +---------------+ [align in void*]
 *   | |               |
 *   | +---------------+ [align in unsigned int]
 *   | | sizes         | number of slots of t0
 *   | |               | number of slots of t1
 *   | :               :   :
 *   | |               | number of slots of t(N-1)
 *   | +---------------+ [align in unsigned int]
 *   | | bitmaps       | bitmap of (t0-t31)
 *   | :               :   :
 *   | |               | bitmap of (t(N-32)-t(N-1))
 *   | +---------------+ [align in unsigned int]
 *   | | unboxed part  |
 *   | |               |
 *   | |               |
 *   | :               :
 *   | |               |
 *   | +===============+ ================== end of frame
 *   | | post-offset   |
 *   | +---------------+ [align in frameAlign]
 *   | :               :
 *   v
 *
 *  (info & 0xffff) is the number of bitmap bits.
 *  (info >> 16) is the number of pointers in boxed slots part.
 */

#ifdef STACK_GROWSUP
#define FRAME_HEADER(fp)  (*(uintptr_t*)((void**)(fp) + 1))
#else
#define FRAME_HEADER(fp)  (*(uintptr_t*)((void**)(fp) - 1))
#endif
#define FRAME_NEXT(fp)  (((void**)(fp))[0])

#define FRAME_FLAG_VISITED  0x1
#define FRAME_FLAG_SKIP     0x2
#define FRAME_OFFSET_MASK   (~(uintptr_t)0x3)
#define FRAME_INFO_OFFSET(header)  ((intptr_t)((header) & FRAME_OFFSET_MASK))
#define FRAME_SKIP_NEXT(header)    ((void*)((header) & FRAME_OFFSET_MASK))

#define FRAME_NUM_BOXED(info)   (((unsigned int*)(info))[0] >> 16)
#define FRAME_NUM_GENERIC(info) (((unsigned int*)(info))[0] & 0xffff)
#define FRAME_BOXED_PART(info) \
	((void*)((char*)(info) + ALIGNSIZE(sizeof(unsigned int), \
					   sizeof(void*))))

#ifndef SIZEOF_GENERIC
#define SIZEOF_GENERIC MAXALIGN
#endif

void
sml_frame_enum_ptr(sml_trace_cls *trace, enum sml_gc_mode mode,
		   void *thread_env_ptr)
{
	const struct sml_thread_env *thread_env = thread_env_ptr;
	void *fp = thread_env->saved_frame_pointer;
	unsigned int *sizes, *bitmaps, num_generics, num_boxed;
	unsigned int i, j, num_slots;
	ptrdiff_t offset;
	uintptr_t header;
	void **boxed;
	char *info, *generic;

	while (fp) {
		header = FRAME_HEADER(fp);

		if (header & FRAME_FLAG_SKIP) {
			DBG(("%p: skip", fp));
			fp = FRAME_SKIP_NEXT(header);
			continue;
		}

		offset = FRAME_INFO_OFFSET(header);
		info = (char*)fp + offset;
#ifdef DEBUG
		if (mode != TRY_MAJOR)
#endif /* DEBUG */
			FRAME_HEADER(fp) = header | FRAME_FLAG_VISITED;

		if (offset == 0) {
			DBG(("%p: no frame info", fp));
			fp = FRAME_NEXT(fp);
			continue;
		}

		num_boxed = FRAME_NUM_BOXED(info);
		num_generics = FRAME_NUM_GENERIC(info);
		boxed = FRAME_BOXED_PART(info);

		for (i = 0; i < num_boxed; i++) {
			if (*boxed)
				(*trace)(boxed, trace);
			boxed++;
		}

		offset = (char*)boxed - (char*)info;
		offset = ALIGNSIZE(offset, sizeof(unsigned int));
		sizes = (unsigned int *)(info + offset);
		bitmaps = sizes + num_generics;
		generic = info;

		for (i = 0; i < num_generics; i++) {
			num_slots = sizes[i];
			if (BITMAP_BIT(bitmaps, i) == TAG_UNBOXED) {
				generic -= num_slots * SIZEOF_GENERIC;
			} else {
				for (j = 0; j < num_slots; j++) {
					generic -= SIZEOF_GENERIC;
					(*trace)((void**)generic, trace);
				}
			}
		}

		fp = FRAME_NEXT(fp);

		/* When MINOR tracing, we need to trace not only unvisited
		 * frames but also first frame of visited frame since function
		 * code of the first visited frame may be ran and the frame
		 * may be modified before calling functions of the unvisited
		 * frames.
		 */
		if (mode == MINOR && (header & FRAME_FLAG_VISITED)) {
			DBG(("%p: visited frame.", fp));
			break;
		}
	}

	DBG(("frame end"));
}
