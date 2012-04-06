/**
 * exn.c
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 */

#include <stdlib.h>
#include "smlsharp.h"
#include "object.h"

/* ToDo:
 * We should replace this hand-defining exns with a source file for
 * BuiltinContextCore.smi
 */

#define HEAD(n) OBJ_HEADER_WORD(OBJTYPE_UNBOXED_VECTOR, n)
#define DECLARE_EXNNAME(name) \
static const struct { unsigned int head; char body[sizeof(#name)]; } \
	exnname_##name = \
	{ OBJ_HEADER_WORD(OBJTYPE_UNBOXED_VECTOR, sizeof(#name)), \
	  #name }

DECLARE_EXNNAME(Bind);
DECLARE_EXNNAME(Match);
DECLARE_EXNNAME(Subscript);
DECLARE_EXNNAME(Size);
DECLARE_EXNNAME(Overflow);
DECLARE_EXNNAME(Div);
DECLARE_EXNNAME(Domain);
DECLARE_EXNNAME(Fail);
DECLARE_EXNNAME(Chr);
DECLARE_EXNNAME(Span);
DECLARE_EXNNAME(Empty);
DECLARE_EXNNAME(Option);
DECLARE_EXNNAME(MatchCompBug);

/*
 * Current implementation of objspace does not check the object headers of
 * objects placed at outside of the ML heap.  While an exception tag is a
 * BOXED pointer, any code produced by SML# compiler only uses the address
 * of exception tag objects and does not access to their headers and
 * contents. Hence, we can omit the object headers of statically allocated
 * builtin exception tags.
 */

/*
 * Compiler assumes that the implementation type of exception tag
 * is "string ref".
 */
struct sml_exntag {
	void *string;
};

/* statically allocated exception tags. */
const struct sml_exntag sml_exntag_Bind = {&exnname_Bind.body};
const struct sml_exntag sml_exntag_Match = {&exnname_Match.body};
const struct sml_exntag sml_exntag_Subscript = {&exnname_Subscript.body};
const struct sml_exntag sml_exntag_Size = {&exnname_Size.body};
const struct sml_exntag sml_exntag_Overflow = {&exnname_Overflow.body};
const struct sml_exntag sml_exntag_Div = {&exnname_Div.body};
const struct sml_exntag sml_exntag_Domain = {&exnname_Domain.body};
const struct sml_exntag sml_exntag_Fail = {&exnname_Fail.body};
const struct sml_exntag sml_exntag_MatchCompBug = {&exnname_MatchCompBug.body};
const struct sml_exntag sml_exntag_Empty = {&exnname_Empty.body};
const struct sml_exntag sml_exntag_Chr = {&exnname_Chr.body};
const struct sml_exntag sml_exntag_Span = {&exnname_Span.body};
const struct sml_exntag sml_exntag_Option = {&exnname_Option.body};

/* global variables holding exception tags. */
const void *SML4Bind = &sml_exntag_Bind;
const void *SML5Match = &sml_exntag_Match;
const void *SML9Subscript = &sml_exntag_Subscript;
const void *SML4Size = &sml_exntag_Size;
const void *SML8Overflow = &sml_exntag_Overflow;
const void *SML3Div = &sml_exntag_Div;
const void *SML6Domain = &sml_exntag_Domain;
const void *SML4Fail = &sml_exntag_Fail;
const void *SML8SMLSharp12MatchCompBugE = &sml_exntag_MatchCompBug;
const void *SML5Empty = &sml_exntag_Empty;
const void *SML3Chr = &sml_exntag_Chr;
const void *SML4Span = &sml_exntag_Span;
const void *SML6Option = &sml_exntag_Option;

const char *
sml_exn_name(void *exnobj)
{
	/* An exception object is a record whose first field is a pointer
	 * to a heap-allocated exception tag object.
	 * The type of exception tags is "string ref". */
	return **(void***)exnobj;
}

/* for debug */
void
sml_matchcomp_bug()
{
	sml_error(0, "match compiler bug");
	abort();
}
