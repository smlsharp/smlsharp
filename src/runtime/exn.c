/**
 * exn.c
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 */

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <unwind.h>
#include "smlsharp.h"

#define LANG_SMLSHARP \
	(((uint64_t)'S' << 24)	 \
	 | ((uint64_t)'M' << 16) \
	 | ((uint64_t)'L' << 8)	 \
	 | ((uint64_t)'#'))

#define EXNCLASS_SMLSHARP ((LANG_SMLSHARP << 32) | LANG_SMLSHARP)

struct exception {
	void *exn_obj;
	void *dummy;
	/* header must be double-word aligned */
	struct _Unwind_Exception header;
};

#define HEADER_TO_EXCEPTION(e) \
	(struct exception *)((char*)(e) - offsetof(struct exception, header))

static void
cleanup(_Unwind_Reason_Code reason ATTR_UNUSED,	struct _Unwind_Exception *exc)
{
	struct exception *e = HEADER_TO_EXCEPTION(exc);
	e->exn_obj = NULL;
}

void *
sml_exn_init()
{
	struct exception *e;

	e = xmalloc(sizeof(*e));
	e->header.exception_class = EXNCLASS_SMLSHARP;
	e->header.exception_cleanup = cleanup;
	e->exn_obj = NULL;
	return e;
}

void
sml_exn_free(void *e)
{
	free(e);
}

void
sml_exn_enum_ptr(void *p, void (*trace)(void **))
{
	struct exception *e = p;
	trace(&e->exn_obj);
}

static const char *
sml_exn_name(void *exnobj)
{
	/* An exception object is a record whose first field is a pointer
	 * to a heap-allocated exception tag object.
	 * The type of exception tags is "(string * fn) ref". */
	return ***(void****)exnobj;
}

/* for debug */
void
sml_matchcomp_bug()
{
	sml_error(0, "match compiler bug");
	abort();
}

SML_PRIMITIVE void
sml_raise(void *exn)
{
	struct exception *e = sml_current_thread_exn();
	_Unwind_Reason_Code ret;

	e->exn_obj = exn;
	ret = _Unwind_RaiseException(&e->header);

	if (ret == _URC_END_OF_STACK) {
		sml_error(0, "uncaught exception: %s", sml_exn_name(exn));
		abort();
	}
	sml_fatal(0, "sml_raise: fatal error");
}

static uintptr_t
read_uleb128(const unsigned char **src_p)
{
	const unsigned char *src = *src_p;
	unsigned char c;
	uintptr_t result = 0;
	unsigned int shift = 0;

	do {
		c = *src++;
		result |= ((uintptr_t)c & 0x7f) << shift;
		shift += 7;
	} while ((c & 0x80) != 0);

	*src_p = src;
	return result;
}

static uintptr_t
read_udata4(const unsigned char **src_p)
{
	const unsigned char *src = *src_p;
	union { int n; unsigned char c[4]; } buf;

	/* prevent unaligned access */
	buf.c[0] = *src++;
	buf.c[1] = *src++;
	buf.c[2] = *src++;
	buf.c[3] = *src++;
	*src_p = src;
	return *(int*)&buf.c;
}

#define DW_EH_PE_omit 0xff
#define DW_EH_PE_udata4 0x03

struct lpad {
	unsigned char is_handle;
	uintptr_t addr;
};

static struct lpad
search_lpad(struct _Unwind_Context *context, unsigned char allow_cleanup)
{
	const unsigned char *src, *tabend;
	uintptr_t lpstart, tablen, pc, start, lpad, len;
	unsigned char action;
	struct lpad ret = {0, 0};

	src = (const unsigned char *)_Unwind_GetLanguageSpecificData(context);

	/* LLVM always omits LPStart */
	if (*src++ != DW_EH_PE_omit)
		sml_fatal(0, "@LPStart must be DW_EH_PE_omit");
	lpstart = _Unwind_GetRegionStart(context);

	/* We don't use TTypes. Just ignore them */
	src++;
	read_uleb128(&src);

	/* LLVM uses only udata4 to generate callsite table */
	if (*src++ != DW_EH_PE_udata4)
		sml_fatal(0, "callsite encoding must be DW_EH_PE_udata4");
	tablen = read_uleb128(&src);
	tabend = src + tablen;

	pc = _Unwind_GetIP(context);

	while (src < tabend) {
		start = read_udata4(&src) + lpstart;
		len = read_udata4(&src);
		lpad = read_udata4(&src);
		action = *src++;

		if (pc < start) /* callsite table is sorted */
			break;
		if (pc <= start + len) {
			/* we use "action" as a 1-bit flag indicating which
			 * this catcher is an ML handler (action != 0) or a
			 * cleanup handler (action == 0).  We just ignore
			 * the action table. */
			if (lpad > 0 && (action || allow_cleanup)) {
				ret.addr = lpad + lpstart;
				ret.is_handle = action;
			}
			return ret;
		}
	}

	sml_fatal(0, "ip not present in the callsite table");
}

_Unwind_Reason_Code
sml_personality(int version, _Unwind_Action actions, uint64_t exnclass,
		struct _Unwind_Exception *exception,
		struct _Unwind_Context *context)
{
	struct exception *e = HEADER_TO_EXCEPTION(exception);
	struct lpad lpad;
	void *switch_obj;

	if (version != 1)
		return _URC_FATAL_PHASE1_ERROR;

	if (actions & _UA_SEARCH_PHASE) {
		if (exnclass == EXNCLASS_SMLSHARP
		    && search_lpad(context, 0).addr != 0)
			return _URC_HANDLER_FOUND;
		return _URC_CONTINUE_UNWIND;
	}

	lpad = search_lpad(context, 1);

	if (lpad.addr == 0)
		return _URC_CONTINUE_UNWIND;

	if (exnclass == EXNCLASS_SMLSHARP
	    && !(actions & _UA_FORCE_UNWIND)
	    && (actions & _UA_HANDLER_FRAME)) {
		ASSERT(lpad.is_handle);
		switch_obj = e->exn_obj;
		e->exn_obj = NULL;
	} else {
		if (lpad.is_handle)
			return _URC_CONTINUE_UNWIND;
		switch_obj = NULL;
	}

	_Unwind_SetIP(context, lpad.addr);
	_Unwind_SetGR(context, __builtin_eh_return_data_regno(0),
		      __builtin_extend_pointer(&e->header));
	_Unwind_SetGR(context, __builtin_eh_return_data_regno(1),
		      __builtin_extend_pointer(switch_obj));
	return _URC_INSTALL_CONTEXT;
}
