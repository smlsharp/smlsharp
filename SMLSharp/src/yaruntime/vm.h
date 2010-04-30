/*
 * vm.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: vm.h,v 1.5 2008/12/11 10:22:51 katsu Exp $
 */
#ifndef SMLSHARP__VM_H__
#define SMLSHARP__VM_H__

#include "runtime.h"

/* types for byte code format */
/* assume that size of pointer is 32 bit. */
typedef uint32_t ML_w32;
typedef uint64_t ML_l32;
typedef int32_t ML_n32;
typedef int64_t ML_nl32;
typedef float ML_fs32;     /* 32bit float */
typedef double ML_f32;     /* 64bit float */
typedef uint32_t ML_sz32;
typedef uint32_t ML_lsz32;
typedef int32_t ML_ssz32;
typedef int32_t ML_oa32;
typedef uint32_t ML_ri32;
typedef uint32_t ML_li32;

/* vitrual machine state */

struct vm_trap {
	void *ip, *sp;
};
typedef struct vm_trap vm_trap_t;

struct vm {
	/* frame_stack_limit is accessed frequently. */
	void *frame_stack_limit, *frame_stack_top;
	vm_trap_t *handler_stack_limit;
	void *ip;                    /* instruction pointer */
	void *sp;                    /* stack pointer; glows down */
	vm_trap_t *hsp;              /* handler stack pointer; glows down */
	void *hr;                    /* handler register */ /* FIXME */
	runtime_t *rt;
};
typedef struct vm vm_t;

vm_t *vm_new(runtime_t *rt);
void vm_free(vm_t *vm);
status_t vm_run(vm_t *vm, void *entry, void *env);

#define LOAD_SYSREGS(vm,ip_,sp_,hr_) \
	(ip_ = (vm)->ip, sp_ = (vm)->sp, hr_ = (vm)->hr)
#define SAVE_SYSREGS(vm,ip_,sp_,hr_) \
	((vm)->ip = (void*)(ip_), (vm)->sp = (void*)(sp_), \
	 (vm)->hr = (void*)(hr_))

#define VM_REGADDR(vm,i)   RT_REGADDR((vm)->rt, i)
#define VM_REGINDEX(vm,p)  RT_REGINDEX((vm)->rt, p)

/* VM spec: r1 = link register */
#define VM_LINKREG(vm)     (*(void**)VM_REGADDR(vm, 1))
/* VM spec: r2 = closure environment register */
#define VM_ENVREG(vm)      (*(void**)VM_REGADDR(vm, 2))
/* VM spec: r4 = exception register */
#define VM_EXNREG(vm)      (*(void**)VM_REGADDR(vm, 4))

void vm_extend_handler_stack(vm_t *vm);

#define VM_PUSHTRAP(vm, entry, sp_) do { \
	if ((vm)->hsp <= (vm)->handler_stack_limit) \
		vm_extend_handler_stack(vm); \
	(vm)->hsp--; \
	(vm)->hsp->ip = (entry); \
	(vm)->hsp->sp = (sp_); \
} while (0)

#define VM_POPTRAP(vm) ((vm)->hsp++)

#define VM_RAISE(vm,ip_,sp_) \
	(ip_ = (vm)->hsp->ip, sp_ = (vm)->hsp->sp, VM_POPTRAP(vm))

void vm_extend_frame_stack(vm_t *vm, size_t size);

void vm_enum_rootset(void (*f)(void**), void *vm);


#endif /* SMLSHARP__VM_H */
