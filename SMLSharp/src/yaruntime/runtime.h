/*
 * runtime.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: runtime.h,v 1.3 2008/12/11 10:22:51 katsu Exp $
 */
#ifndef SMLSHARP__RUNTIME_H__
#define SMLSHARP__RUNTIME_H__

#include "cdecl.h"
#include "value.h"
#include "error.h"
#include "memory.h"
#include "env.h"
#include "file.h"
#include "exe.h"

/* virtual machine general purpose registers.
 *
 * VM register is one of storage, not a part of virtual machine state.
 */

#define RT_NUM_REGS  64
#define RT_NUM_FFIARGS  (RT_NUM_REGS / 4 - 2)

union rt_reg1 {
	ml_uchar_t c; ml_ushort_t h; ml_int_t i; float f; void *p;
};
union rt_reg2 {
	union rt_reg1 reg1[2];
	double d; ml_long_t ll;
};
union rt_reg4 {
	union rt_reg2 reg2[2];
	long double ld;
};
#define REGADDR__(reg4,i) \
	((void*)(&((reg4)[(i)/4].reg2[((i)%4)/2].reg1[(i)%2])))
#define REGINDEX__(reg4,p) \
	((unsigned int) \
	 (((char*)(p) - (char*)(reg4)) / sizeof(union rt_reg4) * 4 + \
	  ((char*)(p) - (char*)(reg4)) % sizeof(union rt_reg4) \
	  / sizeof(union rt_reg2) * 2 + \
	  ((char*)(p) - (char*)(reg4)) % sizeof(union rt_reg4) \
	  % sizeof(union rt_reg2) / sizeof(union rt_reg1)))

/* toplevel runtime system */
struct runtime {
	executable_t *executable;
	env_t *symbol_env;
	obstack_t *obstack;

	union rt_reg4 reg4[RT_NUM_REGS / 4];
	void *ffiarg[RT_NUM_FFIARGS]; /* pointers to slots holding ffiarg */
};
typedef struct runtime runtime_t;

#define RT_REGADDR(rt,i)   REGADDR__((rt)->reg4, i)
#define RT_REGINDEX(rt,p)  REGINDEX__((rt)->reg4, p)

/*
 * create a new runtime.
 */
runtime_t *runtime_new(void);

/*
 * destroy a runtime.
 */
void runtime_free(runtime_t *rt);

/*
 * enumerate root pointers in a runtime.
 */
void runtime_enum_rootset(void (*f)(void **), void *rt);

/*
 * load a executable file to runtime.
 */
status_t runtime_load(runtime_t *rt, file_t *file, executable_t **exe_ret);

/*
 * execute an execuable loaded by runtime_load.
 */
status_t runtime_exec(runtime_t *rt, executable_t *exe);


#endif /* SMLSHARP__RUNTIME_H */
