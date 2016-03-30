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

/*
 * sml_raise requires a 60-byte work area allocated by sml_alloc.
 * See also LLVMGen.sml.
 */
#define SML_RAISE_ALLOC_SIZE  60

#define LANG_SMLSHARP     (('S'<<24)|('M'<<16)|('L'<<8)|'#')
#define VENDOR_SMLSHARP   ((uint64_t)LANG_SMLSHARP << 32)
#define EXNCLASS_SMLSHARP (VENDOR_SMLSHARP | LANG_SMLSHARP)

#define DW_EH_PE_omit     0xff
#define DW_EH_PE_udata4   0x03

/*
 * low-level exception object handled by Itanium C++ ABI.
 * The size of this struct must be smaller than SML_RAISE_ALLOC_SIZE.
 * IA-64 ABI says that struct _Unwind_Exception must be 8 byte aligned;
 * therefore, sizeof(struct exception) should be 60 bytes in any 64-bit
 * platform.
 * NOTE: Linux provides this structure with the maximum alignment.
 * Consequently, the size of this structure is typically 64 bytes in 64-bit
 * Linux. In any case, offsetof(struct exception, found_cleanup) is 48 bytes.
 */
struct exception {
	struct _Unwind_Exception header;
	void *exn_obj;           /* ML's exn object */
	uintptr_t handler_addr;  /* handler address found in SEARCH phase */
	int found_cleanup;       /* a cleanup is found in SEARCH phase or not */
};

/* size of struct exception.  Use offsetof instead of sizeof(struct exception)
 * in order to ignore paddings. */
#define SIZE_OF_STRUCT_EXCEPTION \
	(offsetof(struct exception, found_cleanup) + sizeof(int))
/* size of struct exception as an SML# record object */
#define EXCEPTION_ALLOC_SIZE \
	(CEILING(SIZE_OF_STRUCT_EXCEPTION, SIZEOF_BITMAP) + SIZEOF_BITMAP)
#define EXCEPTION_HEADER \
	OBJ_HEADER_WORD(OBJTYPE_RECORD, EXCEPTION_ALLOC_SIZE - SIZEOF_BITMAP)
#define EXCEPTION_BITMAP \
	STRUCT_BITMAP(struct exception, exn_obj)

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
	struct _Unwind_Exception *exc ATTR_UNUSED)
{
	/* nothing to do */
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
sml_raise(void *work_area, void *exn)
{
	struct exception *e;
	_Unwind_Reason_Code ret;

	/* We allocate an low-level exception object (struct exception)
	 * in SML# heap.  The low-level object must be kept alive until
	 * unwinding is completed and control reaches a landing pad.
	 * Since there is no GC safe point between here to a landing pad,
	 * the low-level object never be traced and reclaimed by garbage
	 * collector until a landing pad; therefore we do not need to
	 * initialize it as an SML# object and add it to the root set. */
	if (EXCEPTION_ALLOC_SIZE > SML_RAISE_ALLOC_SIZE)
		sml_fatal(0, "exception is larger than SML_RAISE_ALLOC_SIZE");

	e = work_area;
	e->header.exception_class = EXNCLASS_SMLSHARP;
	e->header.exception_cleanup = cleanup;
	e->exn_obj = exn;
	e->handler_addr = 0;
	e->found_cleanup = 0;
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

struct landing_pad {
	uintptr_t addr;   /* landing pad address; 0 means no landing pad */
	int catch;        /* 0 = cleanup; non-zero = catch all */
};

static struct landing_pad
search_lpad(struct _Unwind_Context *context)
{
	const unsigned char *src, *tabend;
	uintptr_t lpstart, tablen, ip, start, lpad, len;
	unsigned char action;
	struct landing_pad ret;

	/* The language-specific data is organized by LLVM in the following
	 * structure, which is compatible with GCC's except_tab:
	 * struct packed {
	 *   uint8_t  lpstart_enc;  // always DW_EH_PE_omit (0xff)
	 *   uint8_t  ttype_enc;    // we ignore it
	 *   uleb128  ttype_off;    // we ignore it
	 *   uint8_t  callsite_enc; // always DW_EH_PE_udata4 (0x03)
	 *   uleb128  callsite_len; // length of CallSiteTable in bytes
	 *   struct {
	 *     udata4 cs_start;     // start address (relative to RegionStart)
	 *     udata4 cs_len;       // code range length
	 *     udata4 cs_lpad;      // landing pad address (ditto)
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
	tabend = src + tablen;

	ip = _Unwind_GetIP(context);

	while (src < tabend) {
		start = read_udata4(&src) + lpstart;
		len = read_udata4(&src);
		lpad = read_udata4(&src);
		action = *(src++);

		/* call-site table covers all the possible IP and is sorted
		 * by cs_start.  Abort if we have passed the ip */
		if (ip < start)
			break;

		if (ip <= start + len) {
			/* In SML#, "action" is a 1-bit flag indicating that
			 * this is either an ML exception handler (action != 0)
			 * or a cleanup (action == 0). */
			ret.addr = (lpad == 0) ? 0 : lpad + lpstart;
			ret.catch = action;
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
		if (exnclass != EXNCLASS_SMLSHARP)
			return _URC_CONTINUE_UNWIND;
		lpad = search_lpad(context);
		if (lpad.addr == 0)
			return _URC_CONTINUE_UNWIND;
		if (!lpad.catch) {
			e->found_cleanup = 1;
			return _URC_CONTINUE_UNWIND;
		}
		e->handler_addr = lpad.addr;
		return _URC_HANDLER_FOUND;
	}

	if (!(actions & _UA_CLEANUP_PHASE))
		return _URC_FATAL_PHASE2_ERROR;

	if (actions & _UA_HANDLER_FRAME) {
		if (exnclass != EXNCLASS_SMLSHARP)
			return _URC_FATAL_PHASE2_ERROR;
		lpad.addr = e->handler_addr;

		/* Unwinding is completed and we are going back an SML# code.
		 * _Unwind_Excetion is no longer needed.  Thus we only pass
		 * the ML exn object to the SML# code as the second return
		 * value. */
		ret1 = NULL;
		ret2 = e->exn_obj;
	} else {
		/* If no cleanup is found in SEARCH phase, we can safely skip
		 * searching for a cleanup landing pad. */
		if (exnclass == EXNCLASS_SMLSHARP && !e->found_cleanup)
			return _URC_CONTINUE_UNWIND;
		lpad = search_lpad(context);
		if (lpad.addr == 0)
			return _URC_CONTINUE_UNWIND;
		assert(lpad.catch == 0);

		/* We are going into an SML# code temprarily; unwinding will
		 * be resumed with the low-level exception object. */
		if (exnclass == EXNCLASS_SMLSHARP) {
			/* To protect the low-level object from garbage
			 * collection, its header and bitmap must be
			 * initialized as an SML# record object. */
			*OBJ_BEGIN(e) = EXCEPTION_HEADER;
			*OBJ_BITMAP(e) = EXCEPTION_BITMAP;
			ret1 = NULL;
			ret2 = e;
		} else {
			ret1 = ue;
			ret2 = NULL;
		}
	}

	/* Return to an SML# code through a landing pad.
	 * The first return value is the foreign pointer to _Unwind_Exception.
	 * It may be null if it is no longer needed or it is allocated in
	 * SML# heap.
	 * The second return value is an ML object relevant to the landing
	 * pad.  It may be null if a cleanup handler is invoked with a
	 * foreign exception.
	 * If the second value is not null, the cleanup handler must pass
	 * the second value to _Unwind_Resume.  This means that the cleanup
	 * must protect the second value from garbage collection.
	 *
	 * ToDo: Note that cleanup handlers in other languages may be invoked
	 *       during unwinding.  We assume that cleanup handlers in other
	 *       languages never cause SML# GC.  If some of them would cause
	 *       GC, the low-level exception object would be reclaimed
	 *       unexpectedly.  We need somehow to put it to root set during
	 *       unwinding.
	 */
	_Unwind_SetIP(context, lpad.addr);
	_Unwind_SetGR(context, __builtin_eh_return_data_regno(0),
		      __builtin_extend_pointer(ret1));
	_Unwind_SetGR(context, __builtin_eh_return_data_regno(1),
		      __builtin_extend_pointer(ret2));
	return _URC_INSTALL_CONTEXT;
}
