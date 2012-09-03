/**
 * exe.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: exe.h,v 1.2 2008/01/10 04:43:13 katsu Exp $
 */
#ifndef SMLSHARP__EXE_H__
#define SMLSHARP__EXE_H__

#include "cdecl.h"

struct executable {
	void *prog, *mem;
	void *init_beg, *insn_beg, *bbss_beg;
	size_t init_size, insn_size, bbss_size;
};
typedef struct executable executable_t;

executable_t *exe_new(size_t progbits, size_t nobits);
void exe_merge(executable_t **exe1, executable_t *exe2);
void exe_free(executable_t *exe);
void exe_enum_rootset(void (*f)(void **), void *executable);

#if 0
executable_t *exe_new(size_t progbits, size_t nobits);
void exe_free(executable_t *exe);
void exe_free_all(void);
#endif

#endif /* SMLSHARP__EXE_H__ */
