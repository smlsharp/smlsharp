/**
 * runtime.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: runtime.c,v 1.5 2008/12/11 10:22:51 katsu Exp $
 */

#include <string.h>
#include "error.h"
#include "memory.h"
#include "file.h"
#include "prim.h"
#include HEAP_H
#include "loader.h"
#include "prep.h"
#include "runtime.h"
#include "vm.h"

runtime_t *
runtime_new()
{
	status_t err;
	runtime_t *rt;
	obstack_t *obstack = NULL;
	unsigned int i;

	rt = obstack_alloc(&obstack, sizeof(runtime_t));

	rt->symbol_env = env_new();
	err = init_primitives(rt->symbol_env);
	if (err)
		fatal(err, "init_primitives failed");

	rt->executable = NULL;
	rt->obstack = obstack;

	/* clear registers */
	memset(rt->reg4, 0, sizeof(rt->reg4));
	/* VM Spec: r8 = 1st arg, ..., r60 = 14th arg */
	for (i = 0; i < RT_NUM_FFIARGS; i++) {
		((void**)rt->ffiarg)[i] = &rt->reg4[i + 2];
	}
#if 0
	for (i = 0; i < RT_NUM_TMP_ROOTS; i++)
		vm->tmp_root[i] = NULL;
#endif

	heap_add_rootset(runtime_enum_rootset, rt);
	return rt;
}

void
runtime_free(runtime_t *rt)
{
	obstack_t *obstack;

	env_free(rt->symbol_env);
	exe_free(rt->executable);
	obstack = rt->obstack;
	obstack_free(&obstack, NULL);
	heap_remove_rootset(runtime_enum_rootset, rt);
}

void
runtime_enum_rootset(void (*f)(void **), void *runtime)
{
	runtime_t *rt = runtime;
	exe_enum_rootset(f, rt->executable);
}

status_t
runtime_load(runtime_t *rt, file_t *file, executable_t **exe_ret)
{
	status_t err;
	executable_t *exe;
	void *errpos;
	void *rollback_ptr;

	rollback_ptr = obstack_alloc(&rt->obstack, 0);

	err = load_elf(file, rt->symbol_env, &exe);
	file->close(file);

	if (err)
		return err;

	errpos = preprocess32(rt, exe);
	if (errpos) {
		error(0, "%s: preprocess failed at %p", file->filename, errpos);
		env_rollback(rt->symbol_env);
		obstack_free(&rt->obstack, rollback_ptr);
		return ERR_INVALID;
	}

	exe_merge(&rt->executable, exe);
	env_commit(rt->symbol_env);

	*exe_ret = exe;
	return 0;
}

status_t
runtime_exec(runtime_t *rt, executable_t *exe)
{
	vm_t *vm = vm_new(rt);
	status_t err = 0;
	size_t i;
	void *p;

	for (i = 0; i < exe->init_size; i += sizeof(void*)) {
		p = *(void**)(&((char*)exe->init_beg)[i]);
		err = vm_run(vm, p, NULL);
		if (err)
			break;
	}

	vm_free(vm);
	return err;
}
