/**
 * exe.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: exe.c,v 1.3 2008/01/23 08:20:07 katsu Exp $
 */

#include "memory.h"
#include "error.h"
#include "exe.h"

struct exec_list {
	struct executable exe;         /* must be first member */
	struct exec_list *next;
};

struct executable *
exe_new(size_t progbits, size_t nobits)
{
	size_t headsize, progsize, memsize;
	struct exec_list *exe;

	headsize = ALIGN(sizeof(struct exec_list), sizeof(void*));
	progsize = ALIGN(progbits, sizeof(void*));
	memsize = ALIGN(nobits, sizeof(void*));

	exe = xmalloc(headsize + progsize + memsize);
	exe->exe.prog = (char*)exe + headsize;
	exe->exe.mem = (char*)exe->exe.prog + progsize;
	exe->exe.init_beg = NULL;
	exe->exe.insn_beg = NULL;
	exe->exe.bbss_beg = NULL;
	exe->exe.init_size = 0;
	exe->exe.insn_size = 0;
	exe->exe.bbss_size = 0;
	exe->next = NULL;

	return (struct executable *)exe;
}

void
exe_merge(executable_t **exe1, executable_t *exe2)
{
	struct exec_list *list2 = (struct exec_list *)exe2;

	while (list2->next)
		list2 = list2->next;
	list2->next = (struct exec_list *)*exe1;
	*exe1 = exe2;
}

void
exe_enum_rootset(void (*f)(void **), void *executable)
{
	executable_t *exe = executable;
	struct exec_list *list = (struct exec_list *)exe;
	size_t i;
	char *p;

	while (list) {
		p = list->exe.bbss_beg;

		DBG(("%p: %p - %p",
		     (void*)list, (void*)p, (void*)p + list->exe.bbss_size));

		for (i = 0; i < list->exe.bbss_size; i += sizeof(void*))
			f((void**)(&p[i]));
		list = list->next;
	}
}

void
exe_free(executable_t *exe)
{
	struct exec_list *l = (struct exec_list *)exe, *next;

	while (l) {
		next = l->next;
		free(l);
		l = next;
	}
}
