/**
 * foreign.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: foreign.c,v 1.4 2008/12/11 10:22:51 katsu Exp $
 */

#include <string.h>
#include <ffi.h>

#include "memory.h"
#include "error.h"
#include "heap.h"
#include "vm.h"
#include "foreign.h"

#define PARSE_STACK_SIZE  64

#define ABI_PREFIX(name,abi) {":"name":", sizeof(":"name), abi}

struct abi_prefix {
	const char *name;
	size_t namelen;
	ffi_abi abi;
};
const struct abi_prefix abi_prefix_table[] = {
	ABI_PREFIX("default", FFI_DEFAULT_ABI),
#if defined(ALPHA)
	ABI_PREFIX("osf", FFI_OSF),
#elif defined(ARM)
	ABI_PREFIX("sysv", FFI_SYSV),
#elif defined(FRV)
	ABI_PREFIX("eabi", FFI_EABI),
#elif defined IA64
	ABI_PREFIX("unix", FFI_UNIX),
#elif defined LIBFFI_CRIS
	ABI_PREFIX("sysv", FFI_SYSV),
#elif defined M32R
	ABI_PREFIX("sysv", FFI_SYSV),
#elif defined M68K
	ABI_PREFIX("sysv", FFI_SYSV),
#elif defined(MIPS) || defined(MIPS_IRIX) || defined(MIPS_LINUX)
	ABI_PREFIX("o32", FFI_O32),
	ABI_PREFIX("n32", FFI_N32),
	ABI_PREFIX("n64", FFI_N64),
	ABI_PREFIX("o32_soft_float", FFI_O32_SOFT_FLOAT),
#elif defined(PA64_HPUX)
	ABI_PREFIX("pa64", FFI_PA64),
#elif defined(PA_HPUX) || defined(PA_LINUX)
	ABI_PREFIX("pa32", FFI_PA32),
#elif defined(POWERPC)
	ABI_PREFIX("sysv", FFI_SYSV),
	ABI_PREFIX("gcc_sysv", FFI_GCC_SYSV),
	ABI_PREFIX("linux64", FFI_LINUX64),
	ABI_PREFIX("linux", FFI_LINUX),
#elif defined(POWERPC_AIX) || defined(POWERPC_DARWIN)
	ABI_PREFIX("aix", FFI_AIX),
	ABI_PREFIX("darwin", FFI_DARWIN),
#elif defined(POWERPC_FREEBSD)
	ABI_PREFIX("sysv", FFI_SYSV),
	ABI_PREFIX("gcc_sysv", FFI_GCC_SYSV),
	ABI_PREFIX("linux64", FFI_LINUX64),
#elif defined(S390)
	ABI_PREFIX("sysv", FFI_SYSV),
#elif defined(SH)
	ABI_PREFIX("sysv", FFI_SYSV),
#elif defined(SH64)
	ABI_PREFIX("sysv", FFI_SYSV),
#elif defined(SPARC)
	ABI_PREFIX("v8", FFI_V8),
	ABI_PREFIX("v8plus", FFI_V8PLUS),
	ABI_PREFIX("v9", FFI_V9),
#elif defined(X86_WIN32)
	ABI_PREFIX("sysv", FFI_SYSV),
	ABI_PREFIX("stdcall", FFI_STDCALL),
#elif defined(X86) || defined(X86_64) || defined(X86_DARWIN)
#if defined(__i386__) || defined(__x86_64__)
	ABI_PREFIX("sysv", FFI_SYSV),
	ABI_PREFIX("unix64", FFI_UNIX64),
#endif
#endif
};

#define NUM_ABI_PREFIXES (sizeof(abi_prefix_table) / sizeof(struct abi_prefix))

static status_t
reduce_ty(obstack_t **obstack, ffi_type **stack, unsigned int *sp,
	  unsigned short type)
{
	unsigned int top, beg, i;
	ffi_type *ty, **elems;

	top = beg = *sp;
	for (;;) {
		if (beg == 0)
			return ERR_INVALID;
		if (stack[beg - 1] == NULL)
			break;
		beg--;
	}

	elems = obstack_alloc(obstack, sizeof(ffi_type*) * (top - beg + 1));
	for (i = 0; i < top - beg; i++)
		elems[i] = stack[beg + i];
	elems[i] = NULL;

	ty = obstack_alloc(obstack, sizeof(ffi_type));
	ty->size = 0;
	ty->alignment = 0;
	ty->elements = elems;
	ty->type = type;

	stack[beg - 1] = ty;
	*sp = beg;
	return 0;
}

ffi_cif *
foreign_prep_cif(obstack_t **obstack, const char *src)
{
	ffi_type *stack[PARSE_STACK_SIZE];
	unsigned int i;
	unsigned int sp = 0;
	unsigned int num_args = 0;
	ffi_abi abi;
	ffi_cif *cif;
	ffi_type **argtys = NULL;
	ffi_type *retty = NULL;
	status_t err = 0;
	ffi_status ffierr;

	abi = FFI_DEFAULT_ABI;

	for (i = 0; i < NUM_ABI_PREFIXES; i++) {
		if (strncmp(src, abi_prefix_table[i].name,
			    abi_prefix_table[i].namelen) == 0) {
			abi = abi_prefix_table[i].abi;
			src += abi_prefix_table[i].namelen;
			break;
		}
	}

	cif = obstack_alloc(obstack, sizeof(ffi_cif));

	while (err == 0 && *src) {
		if (sp >= PARSE_STACK_SIZE) {
			err = ERR_INVALID;
			break;
		}

		switch (*(src++)) {
		case '-':
			if (argtys) {
				err = ERR_INVALID;
				break;
			}
			for (i = 0; i < sp; i++) {
				if (stack[i] == NULL) {
					err = ERR_INVALID;
					break;
				}
			}
			argtys = obstack_alloc(obstack, sizeof(ffi_type*) * sp);
			memcpy(argtys, stack, sizeof(ffi_type*) * sp);
			num_args = sp;
			sp = 0;
			break;
		case 'c':
			stack[sp++] = &ffi_type_ml_char_t;
			break;
		case 'C':
			stack[sp++] = &ffi_type_ml_uchar_t;
			break;
		case 's':
			stack[sp++] = &ffi_type_ml_short_t;
			break;
		case 'S':
			stack[sp++] = &ffi_type_ml_ushort_t;
			break;
		case 'i':
			stack[sp++] = &ffi_type_ml_int_t;
			break;
		case 'I':
			stack[sp++] = &ffi_type_ml_uint_t;
			break;
		case 'l':
			stack[sp++] = &ffi_type_ml_long_t;
			break;
		case 'L':
			stack[sp++] = &ffi_type_ml_ulong_t;
			break;
		case 'f':
			stack[sp++] = &ffi_type_float;
			break;
		case 'd':
			stack[sp++] = &ffi_type_double;
			break;
		case 'D':
			stack[sp++] = &ffi_type_longdouble;
			break;
		case 'p':
			stack[sp++] = &ffi_type_pointer;
			break;
		case '{':
			stack[sp++] = NULL;
			break;
		case '}':
			err = reduce_ty(obstack, stack, &sp, FFI_TYPE_STRUCT);
			break;
		default:
			err = ERR_INVALID;
		}
	}

	if (sp == 0)
		retty = &ffi_type_void;
	else if (sp == 1)
		retty = stack[0];
	else
		err = ERR_INVALID;

	if (argtys == NULL) {
		err = ERR_INVALID;
	} else {
		ffierr = ffi_prep_cif(cif, abi, num_args, retty, argtys);
		if (ffierr != FFI_OK)
			err = ERR_INVALID;
	}

	if (err) {
		obstack_free(obstack, cif);
		return NULL;
	}

	return cif;
}




struct callback {
	runtime_t *rt;
	void *entry;
	void *env;
	ffi_closure *closure;
};

static struct callback *callbacks = NULL;
static unsigned int num_callbacks = 0;

static unsigned int
add_callback(runtime_t *rt, void *entry, void *env, ffi_closure *closure)
{
	unsigned int i;

	for (i = 0; i < num_callbacks; i++) {
		if (callbacks[i].entry == entry && callbacks[i].env == env)
			return i;
	}

	callbacks = array_alloc(callbacks,
				sizeof(struct callback) * (num_callbacks + 1));
	callbacks[num_callbacks].rt = rt;
	callbacks[num_callbacks].entry = entry;
	callbacks[num_callbacks].env = env;
	callbacks[num_callbacks].closure = closure;

	DBG(("%d: callback=%p rt=%p entry=%p env=%p closure=%p",
	     num_callbacks, &callbacks[num_callbacks],
	     rt, entry, env, closure));

	return num_callbacks++;
}

void
foreign_enum_rootset(void (*f)(void **), void *data ATTR_UNUSED)
{
	unsigned int i;

	for (i = 0; i < num_callbacks; i++)
		f(&callbacks[i].env);
}

void
foreign_init()
{
	heap_add_rootset(foreign_enum_rootset, NULL);
}

static void
callback_entry(ffi_cif *cif ATTR_UNUSED, void *result, void **args, void *data)
{
	struct callback *callback = &callbacks[(unsigned int)data];
	runtime_t *rt = callback->rt;
	vm_t *vm = vm_new(rt);

	/* FIXME: fetch args */
	{
		unsigned int i;
		for (i = 0; i < cif->nargs; i++)
			*(void**)vm->rt->ffiarg[i] = *(void**)args[i];
	}

	vm_run(vm, callback->entry, callback->env);

	/* FIXME: set result */
	*(void**)result = *(void**)vm->rt->ffiarg[0];
	vm_free(vm);
}

void *
foreign_export(runtime_t *rt, void *entry, void *env, ffi_cif *cif)
{
	ffi_closure *closure;
	unsigned int callback_id;
	ffi_status ffierr;

	closure = xmalloc(sizeof(ffi_closure));
	callback_id = add_callback(rt, entry, env, closure);
	ffierr = ffi_prep_closure(closure, cif, callback_entry,
				  (void*)callback_id);
	return closure;
}
