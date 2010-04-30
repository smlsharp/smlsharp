/*
 * eval.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: eval.c,v 1.9 2010/01/19 11:31:46 katsu Exp $
 */

#include <stddef.h>
#include <string.h>
#include <ffi.h>
#include "error.h"
#include HEAP_H
#include "runtime.h"
#include "eval.h"
#include "foreign.h"

#define OPT_DIRECT_THREADED_CODE
//#define OPT_CALL_THREADED_CODE

/* absolute */

#if 0
#define ABS(ty,x) abs_##ty(x)
#define ABSO(ty,x) abso_##ty(x)
#endif

/* addition with overflow check */

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define addo_N(x,y) ({ \
	ml_int_t x__ = (x), y__ = (y); \
	asm ("addl    %1, %0\n\t" \
	     "into" \
	     : "+r" (y__) : "g" (x__));	\
	y__; })
#endif /* ASM */
#define ADDO(ty,x,y) addo_##ty(x,y)

/* subtraction with overflow check */

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define subo_N(x,y) ({ \
	ml_int_t x__ = (x), y__ = (y); \
	asm ("subl    %1, %0\n\t" \
	     "into" \
	     : "+r" (y__) : "g" (x__)); \
	y__; })
#endif /* ASM */
#define SUBO(ty,x,y) subo_##ty(x,y)

/* multiplication with overflow check */

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define mulo_N(x,y) ({ \
	ml_int_t x__ = (x), y__ = (y); \
	asm ("imull   %1, %0\n\t" \
	     "into" \
	     : "+r" (y__) : "g" (x__)); \
	y__; })
#endif /* ASM */
#define MULO(ty,x,y) mulo_##ty(x,y)

/* division */
/* NOTE for IA-32:
 * use %ecx register to determine the reason why the #DE exception
 * is raised. (division by zero or overflow)
 * if %ecx = 0, then the error is due to division by zero.
 */

#define DIVMOD__(name,ty,x,y,q,r) do { \
	div_t_##ty d__; \
	d__ = name##_##ty(x, y); \
	q = d__.quot; \
	r = d__.rem; \
} while (0)

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define DIVMOD_N(x,y,q,r) do { \
	ml_int_t x__ = (x), y__ = (y), tmp; \
	asm ("movl    %3, %%ecx\n\t" \
	     "cltd\n\t" \
	     "idivl   %%ecx\n\t" \
	     "xorl    %%ecx, %%ecx\n\t" \
	     "testl   %%eax, %%eax\n\t" \
	     "setns   %%cl\n\t" \
	     "movl    %%ecx, %4\n\t" \
	     "testl   %%edx, %%edx\n\t" \
	     "setz    %%cl\n\t" \
	     "orl     %4, %%ecx\n\t" \
	     "subl    $1, %%ecx\n\t" \
	     "addl    %%ecx, %%eax\n\t" \
	     "andl    %3, %%ecx\n\t" \
	     "addl    %%ecx, %%edx" \
	     : "=a" (q), "=d" (r) \
	     : "a" (x__), "m" (y__), "m" (tmp) \
	     : "ecx"); \
} while (0)
#else
#define DIVMOD_N(x,y,q,r) DIVMOD__(divmod,N,q,r)
#endif /* ASM */
#define DIVMOD_NL(x,y,q,r) DIVMOD__(divmod,NL,q,r)
#define DIVMOD_W(x,y,q,r)  (q = (x) / (y), r = (x) % (y))
#define DIVMOD_L(x,y,q,r)  (q = (x) / (y), r = (x) % (y))
#define DIVMOD(ty,x,y,q,r) DIVMOD_##ty(x,y,q,r)

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define DIVMODO_N DIVMOD_ml_int_t
#else
#define DIVMODO_N(x,y,q,r) DIVMOD__(divmodo,N,q,r)
#endif /* ASM */
#define DIVMODO_NL(x,y,q,r) DIVMOD__(divmodo,NL,q,r)
#define DIVMODO(ty,x,y,q,r) DIVMODO_##ty(x,y,q,r)

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define DIV_N(x,y) ({ \
	ml_int_t x__ = (x), y__ = (y); \
	asm ("cltd\n\t" \
	     "idivl   %%ecx\n\t" \
	     "xorl    %%ecx, %%ecx\n\t" \
	     "testl   %%eax, %%eax\n\t" \
	     "sets    %%cl\n\t" \
	     "testl   %%edx, %%edx\n\t" \
	     "setnz   %%dl\n\t" \
	     "andb    %%dl, %%cl\n\t" \
	     "subl    %%ecx, %%eax" \
	     : "+a" (x__) : "c" (y__) : "edx"); \
	x__; })
#else
#define DIV_N(x,y)  (divmod_N(x,y).quot)
#endif /* ASM */
#define DIV_NL(x,y) (divmod_NL(x,y).quot)
#define DIV_W(x,y)  ((ml_uint_t)(x) / (ml_uint_t)(y))
#define DIV_L(x,y)  ((ml_ulong_t)(x) / (ml_ulong_t)(y))
#define DIV_FS(x,y) ((float)(x) / (float)(y))
#define DIV_F(x,y)  ((double)(x) / (double)(y))
#define DIV_FL(x,y) ((long double)(x) / (long double)(y))
#define DIV(ty,x,y) DIV_##ty(x,y)

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define DIVO_N DIV_N
#else
#define DIVO_N(x,y) (divmodo_N(x,y).quot)
#endif /* ASM */
#define DIVO_NL(x,y) (divmodo_NL(x,y).quot)
#define DIVO(ty,x,y) DIVO_##ty(x,y)

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define MOD_N(x,y) ({ \
	ml_int_t x__ = (x), y__ = (y), z__ ; \
	asm ("movl    %2, %%ecx\n\t" \
	     "cltd\n\t" \
	     "idivl   %%ecx\n\t" \
	     "xorl    %%ecx, %%ecx\n\t" \
	     "testl   %%eax, %%eax\n\t" \
	     "setns   %%cl\n\t" \
	     "testl   %%edx, %%edx\n\t" \
	     "setz    %%al\n\t" \
	     "orb     %%al, %%cl\n\t" \
	     "subl    $1, %%ecx\n\t" \
	     "andl    %2, %%ecx\n\t" \
	     "addl    %%ecx, %%edx" \
	     : "=d" (z__), "+a" (x__) : "m" (y__) : "ecx"); \
	z__; })
#else
#define MOD_N(x,y) (divmod_N(x,y).rem)
#endif /* ASM */
#define MOD_NL(x,y) (divmod_NL(x,y).rem)
#define MOD_W(x,y) ((ml_uint_t)(x) % (ml_uint_t)(y))
#define MOD_L(x,y) ((ml_ulong_t)(x) % (ml_ulong_t)(y))
#define MOD(ty,x,y) MOD_##ty(x,y)

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define QUOTREM_N(x,y,q,r) \
	asm ("cltd\n\t" \
	     "idivl   %%ecx" : "=a" (q), "=d" (r) : "c" (y))
#else
#define QUOTREM_N(x,y,q,r) DIVMOD__(quotrem,N,x,y,q,r)
#endif /* ASM */
#define QUOTREM_W(x,y,q,r) DIVMOD__(quotrem,W,x,y,q,r)
#define QUOTREM(ty,x,y,q,r) QUOTREM_##ty(x,y,q,r)

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define QUOTREMO_N QUOTREM_N
#else
#define QUOTREMO_N(x,y,q,r) DIVMOD__(quotremo,N,x,y,q,r)
#endif /* ASM */
#define QUOTREMO_NL(x,y,q,r) DIVMOD__(quotremo,NL,x,y,q,r)
#define QUOTREMO(ty,x,y,q,r) QUOTREMO_##ty(x,y,q,r)

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define QUOT_N(x,y) ({ \
	ml_int_t x__ = (x), y__ = (y); \
	asm ("cltd\n\t" \
	     "idivl   %%ecx" : "+a" (x__) : "c" (y__) : "edx"); \
	x__; })
#else
#define QUOT_N(x,y) (quotrem_N(x,y).quot)
#endif /* ASM */
#define QUOT_NL(x,y) (quotrem_NL(x,y).quot)
#define QUOT(ty,x,y) QUOT_##ty(x,y)

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define QUOTO_N QUOT_N
#else
#define QUOTO_N(x,y) (quotremo_N(x,y).quot)
#endif /* ASM */
#define QUOTO_NL(x,y) (quotremo_N(x,y).quot)
#define QUOTO(ty,x,y) QUOTO_##ty(x,y)

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define REM_N(x,y) ({ \
	ml_int_t x__ = (x), y__ = (y), r__; \
	asm ("cltd\n\t" \
	     "idivl   %%ecx" : "=d" (r__) : "a" (x__), "c" (y__)); \
	r__; })
#else
#define REM_N(x,y) (quotrem_N(x,y).rem)
#endif /* ASM */
#define REM_NL(x,y) (quotrem_N(x,y).rem)
#define REM(ty,x,y) REM_##ty(x,y)

/* shift operations */

#ifdef SHIFT_COUNT_MASK
#define RSHIFT(ty,x,y) (((y) & ~SHIFT_COUNT_MASK) == 0 ? (x) >> (y) : 0)
#define LSHIFT(ty,x,y) (((y) & ~SHIFT_COUNT_MASK) == 0 ? (x) << (y) : 0)
#else
#define RSHIFT(ty,x,y) ((x) >> (y))
#define LSHIFT(ty,x,y) ((x) << (y))
#endif

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define RASHIFT_W(x,y) ({ \
	ml_uint_t x__ = (ml_uint_t)(x), y__ = (ml_uint_t)(y); \
	if ((y__ & ~SHIFT_COUNT_MASK) != 0) \
		x__ = ~(ml_uint_t)0; \
	else \
		asm ("sarl    %%cl, %0" : "+g" (x__) : "c" (y__)); \
	x__; })
#define RASHIFT_N(x,y) ((ml_int_t)RASHIFT_W(x,y))
#else
#define RASHIFT_N rashift_N
#define RASHIFT_W rashift_W
#endif /* ASM */
#define RASHIFT_NL rashift_NL
#define RASHIFT_L rashift_L
#define RASHIFT(ty,x,y) RASHIFT_##ty(x,y)

/* stack and register operations */

#define ENTER(x) do { \
	if ((size_t)((char*)sp - (char*)vm->frame_stack_limit) < (x)) { \
		SAVE_SYSREGS(vm, ip, sp, hr); \
		vm_extend_frame_stack(vm, x); \
		LOAD_SYSREGS(vm, ip, sp, hr); \
	} else {\
		sp -= (x);\
	}\
} while (0)

#ifdef DEBUG
#define LEAVE(x) (memset(sp, 0xaa, (x)), sp += (x))
#else
#define LEAVE(x) (sp += x)
#endif /* DEBUG */

#define REGNUM(i)  VM_REGADDR(vm, i)
#define VAR(i)     (&sp[i])

#define FETCH_PREP(patTy,semTy,prepTy,x)  (*(prepTy*)(x))
#define REG(x)     x
#define LABEL(x)   x

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)
#define ASM_REG_IP asm("%edi")
#define ASM_REG_SP asm("%esi")
#else
#define ASM_REG_IP
#define ASM_REG_SP
#endif /* ASM */

/* exception handling */

#define PUSHTRAP(addr) 	VM_PUSHTRAP(vm, (void*)addr, sp)
#define POPTRAP()       VM_POPTRAP(vm)
#define RAISE()         do{ VM_RAISE(vm, ip, sp); CONTINUE; }while(0)

/* memory management */

/* restore SP to runtime_t for garbage collection */
#define SAVE_SP  (vm->sp = sp)

#define ALLOC(obj__, sz) do { \
	size_t inc__ = HEAP_ROUND_SIZE(OBJ_HEADER_SIZE + sz); \
	HEAP_ALLOC(obj__, inc__, (SAVE_SP, heap_invoke_gc_and_alloc(inc__))); \
} while (0)
#define BARRIER(base,ptr) WRITE_BARRIER(base, ptr)

#define COPY(dst, src, sz) do { \
	if (sz == sizeof(uint32_t)) \
		*(uint32_t*)dst = *(uint32_t*)src; \
	else if (sz == sizeof(uint64_t)) \
		*(uint64_t*)dst = *(uint64_t*)src; \
	else \
		memmove(dst, src, sz); \
} while (0)

/* foreign function call */

#define SYSCALL(func) do { \
	SAVE_SYSREGS(vm, ip + OPSIZE, sp, hr); \
	((void(*)(vm_t*))(func))(vm); \
	LOAD_SYSREGS(vm, ip, sp, hr); \
	CONTINUE; \
} while (0)

#define FFCALL1(cif, func, dst, arg1) \
	(SAVE_SP, \
	 ffiarg[0] = arg1, \
	 ffi_call(cif, FFI_FN(func), (void*)(dst), ffiarg))

#define FFCALL2(cif, func, dst, arg1, arg2) \
	(SAVE_SP, \
	 ffiarg[0] = arg1, \
	 ffiarg[1] = arg2, \
	 ffi_call(cif, FFI_FN(func), (void*)(dst), ffiarg))

#define FFCALL3(cif, func, dst, arg1, arg2, arg3) \
	(SAVE_SP, \
	 ffiarg[0] = arg1, \
	 ffiarg[1] = arg2, \
	 ffiarg[2] = arg3, \
	 ffi_call(cif, FFI_FN(func), (void*)(dst), ffiarg))

#define FFCALL(cif, func, dst) \
	(SAVE_SP, \
	 ffi_call(cif, FFI_FN(func), (void*)(dst), vm->rt->ffiarg))

#define FFEXPORT(entry, env, cif) \
	(foreign_export(vm->rt, entry, env, cif))

/* for debug */

#ifdef DEBUG
int debug_op_print = 0;
#define DBG_OP_PRINT_BEG(insn) if (debug_op_print) { debug("%s ip=%p", #insn, (void*)ip)
#define DBG_OP_PRINT_END() debug("\n"); }
#define DBG_OP_PRINT_B(p,v) debug("%s%u",p,(unsigned int)v)
#define DBG_OP_PRINT_H(p,v) debug("%s%u",p,(unsigned int)v)
#define DBG_OP_PRINT_W(p,v) debug("%s%u",p,(unsigned int)v)
#define DBG_OP_PRINT_L(p,v) debug("%s%u",p,(unsigned int)v)
#define DBG_OP_PRINT_N(p,v) debug("%s%u",p,(unsigned int)v)
#define DBG_OP_PRINT_NL(p,v) debug("%s%u",p,(unsigned int)v)
#define DBG_OP_PRINT_FS(p,v) debug("%s%f",p,(double)v)
#define DBG_OP_PRINT_F(p,v) debug("%s%f",p,v)
#define DBG_OP_PRINT_FL(p,v) debug("%s%lf",p,v)
#define DBG_OP_PRINT_P(p,v) debug("%s%p",p,(void*)(v))
#define DBG_OP_PRINT_OA(p,v) debug("%s%p",p,(void*)v)
#define DBG_OP_PRINT_SZ(p,v) debug("%s%u",p,(unsigned int)v)
#define DBG_OP_PRINT_SC(p,v) debug("%s%u",p,(unsigned int)v)
#define DBG_OP_PRINT_SH(p,v) debug("%s%u",p,(unsigned int)v)
#define DBG_OP_PRINT_LSZ(p,v) debug("%s%u",p,(unsigned int)v)
#define DBG_OP_PRINT_SSZ(p,v) debug("%s%d",p,(signed int)v)
#define DBG_OP_PRINT_RI(p,v) \
	debug("%sr%u:%p",p,VM_REGINDEX(vm,REG(v)),*(void**)(REG(v)))
#define DBG_OP_PRINT_LI(p,v) \
	debug("%ssp(%u):%p",p,(unsigned int)v,*(void**)(VAR(v)))
#define DBG_OP_PRINT(ty,prefix,value) DBG_OP_PRINT_##ty(prefix,value)
#else
#define DBG_OP_PRINT_BEG(x)
#define DBG_OP_PRINT_END()
#define DBG_OP_PRINT(ty,prefix,value)
#endif /* DEBUG */

/* dispatch */

#if defined __GNUC__ && defined HOST_CPU_i386
#define ASMCOMMENT_(x)  do { __asm__ volatile ("; # " #x); } while (0)
#define ASMCOMMENT(x)   ASMCOMMENT_(x)
#else
#define ASMCOMMENT(x)
#endif

#ifdef OPT_DIRECT_THREADED_CODE

#ifdef __GNUC__
#define OPENTRY_ADDR(bits,implid,name)  &&op##bits##_##implid
#define OPENTRY(bits,implid,name) \
	op##bits##_##implid: ASMCOMMENT(name);
#define CONTINUE \
	goto *(*(void**)ip)
#define DISPATCH(n) do { \
	void *p__ = *(void**)(&ip[n]); \
	ip += (n); \
	goto *p__; \
} while (0)
#define OPENTRIES_BEGIN
#define OPENTRIES_END
#define EXIT_ENTRY        &&exit_entry__
#define ABORT_ENTRY       &&abort_entry__
#define EXIT_ENTRY_LABEL  exit_entry__
#define ABORT_ENTRY_LABEL abort_entry__

#else
#error "GNU C compiler required."
#endif /* __GNUC__ */

#else

#define OPENTRY_ADDR(bits,implid,name) ((void*)implid)
#define OPENTRY(bits,implid,name) \
	case implid: ASMCOMMENT(name);
#define CONTINUE \
	goto dispatch__
#define DISPATCH(n) do { \
	ip += (n); \
	goto dispatch__; \
} while (0)
#define OPENTRIES_BEGIN   dispatch__: switch ((int)((void*)*ip)) {
#define OPENTRIES_END     }
#define EXIT_ENTRY        ((void*)-1)
#define ABORT_ENTRY       ((void*)-2)
#define EXIT_ENTRY_LABEL  case -1
#define ABORT_ENTRY_LABEL case -2

#error "not implemented"

#endif

#define NEXT  DISPATCH(OPSIZE)

const struct eval_optable *eval32_optable = NULL;

status_t
eval32(vm_t *vm)
{
#include "optab32.inc"

	static const struct eval_optable optable = {
		optable32,
		EXIT_ENTRY,
		ABORT_ENTRY,
	};

	void *ffiarg[3];   /* for FFCALL1, FFCALL2, FFCALL3 */

	register char * RESTRICT ip ASM_REG_IP;
	register char * RESTRICT sp ASM_REG_SP;
	void * RESTRICT hr;

	/* if vm is NULL, initialize eval32_optable and return. */
	if (vm == NULL) {
		eval32_optable = &optable;
		return 0;
	}

	LOAD_SYSREGS(vm, ip, sp, hr);
	CONTINUE;

OPENTRIES_BEGIN

#include "ops32.inc"

 EXIT_ENTRY_LABEL:
	SAVE_SYSREGS(vm, ip, sp, hr);
	return 0;

 ABORT_ENTRY_LABEL:
	SAVE_SYSREGS(vm, ip, sp, hr);
	return ERR_ABORT;

OPENTRIES_END
}
