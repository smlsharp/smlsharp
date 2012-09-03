/*
 * prep.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: prep.c,v 1.5 2008/12/11 10:22:51 katsu Exp $
 */

#include "foreign.h"
#include "exe.h"
#include "runtime.h"
#include "eval.h"
#include "prep.h"

#define PREP_FFTYPE(rt, p, size, rest, altid, ptr, patTy, offset) do { \
	void *p__ = *(ptr); \
	p__ = foreign_prep_cif(&(rt)->obstack, p__); \
	if (p__ == NULL) \
		return 0; \
	*(void**)(ptr) = p__; \
} while (0)

#define PREP_FFCALL1 PREP_FFTYPE
#define PREP_FFCALL2 PREP_FFTYPE
#define PREP_FFCALL3 PREP_FFTYPE

#ifdef DEBUG
int debug_prep_print = 0;
#define PREP_ACCEPT(rt, p, name, implid) \
	if (debug_prep_print) { \
		DBG((#name " (%d) at %p : %x -> %p", implid, (void*)p,	\
		     (unsigned int)(*(ML_w32*)(&(p)[0])),		\
		     (void*)eval32_optable->entry[implid]));		\
	}
#else
#define PREP_ACCEPT(rt, p, name, implid)
#endif /* DEBUG */

#define REGADDR(rt,i)  RT_REGADDR(rt, i)

#include "prep32.inc"

void *
preprocess32(runtime_t *rt, executable_t *exe)
{
	char *p = exe->insn_beg;
	size_t size = exe->insn_size;
	size_t rest = exe->insn_size;
	size_t n = 0;

	while (rest > n) {
		p += n, rest -= n;
		n = prep32(rt, p, size, rest);
		if (n == 0)
			return p;
	}

	return 0;
}
