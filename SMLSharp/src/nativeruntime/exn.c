/**
 * exn.c
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 */

#include <stdlib.h>
#include "smlsharp.h"

SML_PRIMITIVE void
sml_push_handler(void *handler)
{
	/* The detail of structure of handler is platform-dependent except
	 * that runtime may use *(void**)handler for handler chain. */
	struct sml_thread_env *env = SML_THREAD_ENV;

	*((void**)handler) = env->current_handler;

	/* assume that this assignment is atomic. */
	env->current_handler = handler;

	/*DBG(("ip=%p from %p", ((void**)handler)[1],
	  __builtin_return_address(0)));*/
}

SML_PRIMITIVE void *
sml_pop_handler(void)
{
	struct sml_thread_env *env = SML_THREAD_ENV;
	void *handler = env->current_handler;
	void *prev;

	ASSERT(handler != NULL);
	prev = *((void**)env->current_handler);

	/* assume that this assignment is atomic. */
	env->current_handler = prev;

	/*DBG(("ip=%p from %p", ((void**)handler)[1],
	  __builtin_return_address (0)));*/

	return handler;
}

/* for debug */
SML_PRIMITIVE void
sml_before_raise(void *exn ATTR_UNUSED)
{
	if (*(void**)exn == (void*)&sml_exn_MatchCompBug)
		sml_fatal(0, "MatchCompBug detected.");
	if (*(void**)exn == (void*)&sml_exn_Bootstrap)
		sml_fatal(0, "Bootstrap detected.");
}

SML_PRIMITIVE void
sml_stack_corrupted(void *esp, void *ebp)
{
	sml_debug("*** stack corrupted esp=%p ebp=%p\n", esp, ebp);
	abort();
}

/* builtin exceptions */

struct sml_exntag {
	const char *name;
};

struct sml_exntag sml_exn_Bind = { "Bind" };
struct sml_exntag sml_exn_Match = { "Match" };
struct sml_exntag sml_exn_Subscript = { "Subscript" };
struct sml_exntag sml_exn_Size = { "Size" };
struct sml_exntag sml_exn_Overflow = { "Overflow" };
struct sml_exntag sml_exn_Div = { "Div" };
struct sml_exntag sml_exn_Domain = { "Domain" };
struct sml_exntag sml_exn_Fail = { "Fail" };
struct sml_exntag sml_exn_SysErr = { "SysErr" };
struct sml_exntag sml_exn_MatchCompBug = { "MatchCompBug" };
struct sml_exntag sml_exn_Formatter = { "Formatter" };
struct sml_exntag sml_exn_Bootstrap = { "Bootstrap" };
