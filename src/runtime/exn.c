/**
 * exn.c
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 */

#include "smlsharp.h"
#include <stdlib.h>
#include <string.h>
#include <unwind.h>
#ifdef HAVE_LIBUNWIND_H
#include <libunwind.h>
#endif
#include "object.h"

#define LANG_SMLSHARP     (('S'<<24)|('M'<<16)|('L'<<8)|'#')
#define VENDOR_SMLSHARP   ((uint64_t)LANG_SMLSHARP << 32)
#define EXNCLASS_SMLSHARP (VENDOR_SMLSHARP | LANG_SMLSHARP)

#define DW_EH_PE_omit     0xff
#define DW_EH_PE_udata4   0x03

/*
 * low-level exception object handled by Itanium C++ ABI.
 */
struct exception {
	struct _Unwind_Exception header;
	void *exn_obj;           /* ML's exn object */
	uintptr_t handler_addr;  /* handler address found in SEARCH phase */
	unsigned int num_cleanup;
};

/*
 * The internal structure of SML# exception objects.
 * See also EmitTypedLambda.sml.
 */
struct exn {
	struct exntag {
		const char *name;
		uint32_t msg_index;
	} **tag;
	const char *loc;
	void *arg;
};
#define FLAG_MSG_IN_ARG   0x1U
#define MASK_MSG_INDEX    (~(0x1U))

static const char *
exn_msg(const struct exn *e)
{
	uint32_t index = (*(e->tag))->msg_index;
	void *base;

	if (index == 0)
		return NULL;
	base = (index & FLAG_MSG_IN_ARG) ? (void*)e->arg : (void*)e;
	return *(void**)((char*)base + (index & MASK_MSG_INDEX));
}

static void ATTR_NORETURN
uncaught_exception(void *exnobj)
{
	const struct exn *e = exnobj;
	const char *msg = exn_msg(e);
	int q = msg == NULL ? 0 : 1;

	sml_fatal(0, "uncaught exception: %s %.*s%s%.*s at %s",
		  (*(e->tag))->name, q, "\"", msg ? msg : "", q, "\"", e->loc);
}

/* this never be called unless SML# compiler has a bug */
void
sml_matchcomp_bug()
{
	sml_fatal(0, "match compiler bug");
}

/* called if an SML# exception is caught by a handler in another language. */
static void
cleanup(_Unwind_Reason_Code reason ATTR_UNUSED,
	struct _Unwind_Exception *exc)
{
	free(exc);
}

static void
backtrace()
{
#ifdef HAVE_UNW_GETCONTEXT
	unw_context_t c;
	unw_cursor_t cursor;
	unw_proc_info_t i;
	char buf[128];
	unw_word_t offset;
	int r, count = 1;

	if (unw_getcontext(&c) != 0)
		return;
	if (unw_init_local(&cursor, &c) != 0)
		return;
	sml_error(0, "backtrace:");
	do {
		if (unw_get_proc_info(&cursor, &i) != 0)
			return;
		if (unw_get_proc_name(&cursor, buf, sizeof(buf), &offset) != 0)
			return;
		sml_error(0, "  frame #%d: %p %s + %llu",
			  count++, (void*)(i.start_ip + offset), buf,
			  (unsigned long long int)offset);
		r = unw_step(&cursor);
	} while (r > 0);
#endif /* HAVE_UNW_GETCONTEXT */
}

SML_PRIMITIVE void
sml_raise(void *exn)
{
	struct exception *e;
	_Unwind_Reason_Code ret;

	/* The exn object must be kept alive until control reaches an SML#
	 * exception handler, but must not be in a stack frame.  To protect
	 * it from GC, we perform unwinding of ML stack frames in SML#
	 * context.  Before switching to C stack frames, the exn object must
	 * be saved by sml_save_exn.
	 */
	e = xmalloc(sizeof(struct exception));
	e->header.exception_class = EXNCLASS_SMLSHARP;
	e->header.exception_cleanup = cleanup;
	e->exn_obj = exn;
	e->handler_addr = 0;
	e->num_cleanup = 0;

	ret = _Unwind_RaiseException(&e->header);

	/* control reaches here if unwinding failed */
	if (ret == _URC_END_OF_STACK) {
		backtrace();
		uncaught_exception(exn);
	}

	sml_fatal(0, "unwinding failed");
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
		result |= (uintptr_t)(c & 0x7f) << shift;
		shift += 7;
	} while (c & 0x80);

	*src_p = src;
	return result;
}

static uintptr_t
read_udata4(const unsigned char **src_p)
{
	uint32_t ret;
	memcpy(&ret, *src_p, 4);  /* prevent unaligned load */
	*src_p += 4;
	return ret;
}

#define CATCH 0x1
#define CLEANUP 0x2

struct landing_pad {
	uintptr_t addr;   /* landing pad address; 0 means no landing pad */
	unsigned int catch;
};

static struct landing_pad
search_lpad(struct _Unwind_Context *context)
{
	const unsigned char *src, *actiontab;
	uintptr_t lpstart, tablen, ip, start, lpad, len;
	unsigned char action;
	struct landing_pad ret;

	/* The language-specific data is organized by LLVM in the following
	 * structure, which is compatible with GCC's except_tab:
	 * struct packed {
	 *   uint8_t   lpstart_enc;  // always DW_EH_PE_omit (0xff)
	 *   uint8_t   ttype_enc;    // we ignore it
	 *   uleb128   ttype_off;    // we ignore it
	 *   uint8_t   callsite_enc; // always DW_EH_PE_udata4 (0x03)
	 *   uleb128   callsite_len; // length of CallSiteTable in bytes
	 *   struct {
	 *     udata4  cs_start;     // start address (relative to RegionStart)
	 *     udata4  cs_len;       // code range length
	 *     udata4  cs_lpad;      // landing pad address (ditto)
	 *     uleb128 action;       // ([index of action] - 1) or 0
	 *   } CallSiteTable[];
	 * };
	 */
	src = (const unsigned char *)_Unwind_GetLanguageSpecificData(context);

	if (*src++ != DW_EH_PE_omit)
		sml_fatal(0, "@LPStart must be omitted");
	lpstart = _Unwind_GetRegionStart(context);

	/* ignore @TType */
	src++;
	read_uleb128(&src);

	/* LLVM seems to use only udata4 to generate call-site table */
	if (*(src++) != DW_EH_PE_udata4)
		sml_fatal(0, "call-site table encoding must be udata4");
	tablen = read_uleb128(&src);
	actiontab = src + tablen;

	ip = _Unwind_GetIP(context);

	while (src < actiontab) {
		start = read_udata4(&src) + lpstart;
		len = read_udata4(&src);
		lpad = read_udata4(&src);
		action = *(src++);

		/* call-site table covers all the possible IP and is sorted
		 * by cs_start.  Abort if we have passed the ip */
		if (ip < start)
			break;

		if (ip <= start + len) {
			ret.addr = (lpad == 0) ? 0 : lpad + lpstart;
			/* In SML#, there are only three kinds of landing pads:
			 * cleanup, catch i8* null, and cleanup catch i8* null.
			 */
			if (action == 0)
				ret.catch = CLEANUP;
			else if (*(actiontab + action) == 0)
				ret.catch = CATCH;
			else
				ret.catch = CLEANUP | CATCH;
			return ret;
		}
	}

	sml_fatal(0, "search_lpad failed");
}

_Unwind_Reason_Code
sml_personality(int version, _Unwind_Action actions, uint64_t exnclass,
		struct _Unwind_Exception *ue, struct _Unwind_Context *context)
{
	struct exception *e = (struct exception *)ue;
	struct landing_pad lpad;
	void *ret1, *ret2;

	if (version != 1)
		return _URC_FATAL_PHASE1_ERROR;

	if (actions & _UA_SEARCH_PHASE) {
		lpad = search_lpad(context);
		if (exnclass == EXNCLASS_SMLSHARP
		    && lpad.addr
		    && (lpad.catch & CATCH)) {
			e->handler_addr = lpad.addr;
			return _URC_HANDLER_FOUND;
		}
		if (lpad.catch & CLEANUP)
			e->num_cleanup++;
		return _URC_CONTINUE_UNWIND;
	}

	if (!(actions & _UA_CLEANUP_PHASE))
		return _URC_FATAL_PHASE2_ERROR;

	if (actions & _UA_HANDLER_FRAME) {
		if (exnclass != EXNCLASS_SMLSHARP)
			return _URC_FATAL_PHASE2_ERROR;
		lpad.addr = e->handler_addr;

		/* Unwinding is completed. */
		ret1 = NULL;
		ret2 = e->exn_obj;
		free(e);
	} else {
		/* If no cleanup is found in SEARCH phase, we can safely skip
		 * searching for a cleanup landing pad. */
		if (e->num_cleanup == 0)
			return _URC_CONTINUE_UNWIND;

		lpad = search_lpad(context);
		if (lpad.addr == 0)
			return _URC_CONTINUE_UNWIND;
		assert(lpad.catch & CLEANUP);
		e->num_cleanup--;

		ret1 = ue;
		ret2 = (exnclass == EXNCLASS_SMLSHARP) ? e->exn_obj : NULL;
	}

	/* We are going back to SML# code through a landing pad.
	 * There are two pointers passed to SML# code: "ret1" for a pointer
	 * to _Unwind_Exception and "ret2" for an SML# exception object.
	 * "ret1" is NULL when unwinding is finished.  "ret2" may be NULL
	 * if the exception is a foreign exception, i.e. not an SML#
	 * exception.  Note that "ret1" is allocated in SML# heap but its
	 * liveness is not ensured by the runtime; liveness management of
	 * ret1 and ret2 is the responsibility of the user code.
	 * To keep _Unwind_Exception alive during unwinding of C frames,
	 * the runtime provides sml_save_exn feature.
	 */

	_Unwind_SetIP(context, lpad.addr);
	_Unwind_SetGR(context, __builtin_eh_return_data_regno(0),
		      __builtin_extend_pointer(ret1));
	_Unwind_SetGR(context, __builtin_eh_return_data_regno(1),
		      __builtin_extend_pointer(ret2));
	return _URC_INSTALL_CONTEXT;
}

SML_PRIMITIVE void
sml_save_exn(void *arg)
{
	struct _Unwind_Exception *ue = arg;
	if (ue && ue->exception_class == EXNCLASS_SMLSHARP)
		sml_save_exn_internal(((struct exception *)ue)->exn_obj);
}

SML_PRIMITIVE void *
sml_unsave_exn(void *arg)
{
	struct _Unwind_Exception *ue = arg;
	void *obj = NULL;

	if (!ue || ue->exception_class == EXNCLASS_SMLSHARP) {
		obj = sml_save_exn_internal(NULL);
		if (ue)
			((struct exception *)ue)->exn_obj = obj;
	}
	return obj;
}
