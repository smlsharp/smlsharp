/*
 * vm.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: vm.c,v 1.6 2009/11/13 11:44:50 katsu Exp $
 */

#include <stddef.h>
#include <stdarg.h>
#include <string.h>
#include "error.h"
#include "memory.h"
#include "value.h"
#include "vm.h"
#include "eval.h"

#define FRAME_STACK_SIZE    (1024 * 1024 * 4)
#define HANDLER_STACK_SIZE  1024 * 4

vm_t *
vm_new(runtime_t *rt)
{
	vm_t *vm = xmalloc(sizeof(vm_t));

	vm->frame_stack_limit = xmalloc(FRAME_STACK_SIZE);
	vm->handler_stack_limit =
		xmalloc(HANDLER_STACK_SIZE * sizeof(vm_trap_t));

	vm->frame_stack_top = (char*)vm->frame_stack_limit + FRAME_STACK_SIZE;
	vm->sp = vm->frame_stack_top;
	vm->hsp = vm->handler_stack_limit + HANDLER_STACK_SIZE;
	vm->hr = NULL;
	vm->ip = NULL;
	vm->rt = rt;

#ifdef DEBUG
	/* fill stacks with dummy pattern */
	memset(vm->frame_stack_limit, 0xaa,
	       (char*)vm->sp - (char*)vm->frame_stack_limit);
	memset(vm->handler_stack_limit, 0xaa,
	       (char*)vm->hsp - (char*)vm->handler_stack_limit);
#endif /* DEBUG */

	heap_add_rootset(vm_enum_rootset, vm);

	return vm;
}

void
vm_free(vm_t *vm)
{
	heap_remove_rootset(vm_enum_rootset, vm);
	free(vm->frame_stack_limit);
	free(vm->handler_stack_limit);
}

void
vm_extend_handler_stack(vm_t *vm ATTR_UNUSED)
{
	/* FIXME */
	fatal(0, "handler stack exceeded");
}

void
vm_extend_frame_stack(vm_t *vm ATTR_UNUSED, size_t size ATTR_UNUSED)
{
	/* FIXME */
	fatal(0, "stack exceeded");
}


/*
    ----------------
     v0               stack frame header (Fig. 4.2)
     v1
    ----------------
     v2               number of slots of type t1 (= G1)
     :                  :
     v(N+2-1)         number of slots of type tN (= GN)
    ----------------
     v(N+2)
     :                bitmap part (Fig. 4.3)
     v(M+N+2-1)
    ----------------
     v(M+N+2)
     :                unboxed part: Each of words in this part is used
     :                              for storing arbitrary value. Garbage
     v(A+M+N+2-1)                   collector ignores this part.
    ----------------
     v(A+M+N+2)
     :                boxed part: Each of words in this part holds a heap
     :                            object pointer.
     v(B+A+M+N+2-1)
    ----------------
     v(B+A+M+N+2)
     :                t1 generic part: Whether this part holds a heap
     :                                 object pointer or not is described
     v(2*G1+B+A+M+N+2)                 is described by bitmap part.
    ----------------
     v(2*G1+B+A+M+N+2)
     :                            t2 generic part
     v(2*(G1+G2)+B+A+M+N+2-1)
    ----------------
     :
    ----------------
     v(2*(G1+..+G(N-1))+B+A+M+N+2)
     :                            tN generic part
     v(2*(G1+..+GN)+B+A+M+N+2-1)
    ----------------

    N : the number of generic types.
    M : the number of bitmaps.
    A : the number of words of unboxed part.
    B : the number of words of boxed part.
    G1..Gn : the number of slots of each generic part.
             Each slot has 2 word size.

    The size of the entire stack frame (= 2*(G1+...+GN)+B+A+M+N+2) must
    be multiple of 2.
    (2 = maximum alignment constraint / the size of word)
    The beginning of generic part (= B+A+N+M+2) also must be multiple
    of 2.

    M must be the minimum positive integer satisfying M >= N / 32.

  Fig. 4.2. The structure of stack frame header.

       MSB                                       LSB
       +---------------------+---------------------+
    v0 |   boxedPartOffset   |        flags        |
       +---------------------+---------------------+
        31                 16 15                  0
       +---------------------+---------------------+
    v1 |    boxedPartSize    |   numGenericTypes   |
       +---------------------+---------------------+
        31                 16 15                  0
*/

void
vm_enum_rootset(void (*f)(void **), void *vm_)
{
	vm_t *vm = vm_;
	char *sp = vm->sp;
	ml_uint_t header1, header2;
	unsigned int boxed_offset, boxed_slots, num_generics;
	ml_uint_t *generic_sizes, *bitmaps, bm;
	ml_uint_t num_slots;
	unsigned int i, j;

	DBG(("start %p -> %p", (void*)sp, vm->frame_stack_top));

	/* FIXME: need sanity check? */
	while (sp < (char*)vm->frame_stack_top) {
		header1 = ((ml_uint_t*)sp)[0];
		header2 = ((ml_uint_t*)sp)[1];
		ASSERT((header1 & 0xffff) == 0);
		boxed_offset = header1 >> 16;
		boxed_slots = header2 >> 16;
		num_generics = header2 & 0xffff;
		generic_sizes = &((ml_uint_t*)sp)[2];
		bitmaps = &((ml_uint_t*)sp)[2 + num_generics];

		DBG(("%p: "
		     "boxed_offset=%u, "
		     "boxed_slots=%u, "
		     "num_generics=%u",
		     (void*)sp, boxed_offset, boxed_slots, num_generics));

		sp += boxed_offset;
		for (i = 0; i < boxed_slots; i++) {
			f((void**)sp);
			sp += sizeof(void*);
		}

		for (i = 0; i < num_generics; i++) {
			num_slots = generic_sizes[i];
			bm = bitmaps[i / SIZEOF_BITMAP];
			bm >>= i % SIZEOF_BITMAP;

			DBG(("%p: num_slots=%u, tag=%d",
			     (void*)sp, num_slots, (int)(bm & 0x1)));

			if ((bm & 0x1) == TAG_UNBOXED) {
				sp += SIZEOF_GENERIC * num_slots;
			} else {
				for (j = 0; j < num_slots; j++) {
					f((void**)sp);
					sp += SIZEOF_GENERIC;
				}
			}
		}
	}
}


status_t
vm_run(vm_t *vm, void *entry, void *env)
{
	status_t err;
	void *save_ip, *save_sp, *save_hsp, *save_hr;
	const void *exitCode[1], *abortCode[1];

	exitCode[0] = eval32_optable->exit_entry;
	abortCode[0] = eval32_optable->abort_entry;

	/* FIXME: currently stacks are never extended. */
	LOAD_SYSREGS(vm, save_ip, save_sp, save_hr);
	save_hsp = vm->hsp;

	VM_PUSHTRAP(vm, &abortCode, vm->sp);
	vm->ip = entry;

	/* set return address to r1 */
	VM_LINKREG(vm) = &exitCode;
	VM_ENVREG(vm) = env ? env : empty_object;

	err = eval32(vm);

	if (!err)
		VM_POPTRAP(vm);

	ASSERT(vm->sp == save_sp);
	ASSERT(vm->hsp == save_hsp);
	ASSERT(vm->hr == save_hr);

	if (err == ERR_ABORT) {
		/* FIXME: there is unhandled exception */
		fatal(0, "unhandled exception");
	}

	return err;
}
