/**
 * exn.c
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 */

#include <stdlib.h>
#include <setjmp.h>
#include "smlsharp.h"

struct sml_exn_jmpbuf {
	jmp_buf buf;
};

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

SML_PRIMITIVE void
sml_check_handler(void *exn)
{
	struct sml_thread_env *env = SML_THREAD_ENV;
	void *handler = env->current_handler;

	if (handler != NULL)
		return;

#if 0
	if (*(void**)exn == (void*)&sml_exn_MatchCompBug)
		sml_fatal(0, "MatchCompBug detected.");
	if (*(void**)exn == (void*)&sml_exn_Bootstrap)
		sml_fatal(0, "Bootstrap detected.");
#endif
	/* uncaught exception */
	if (env->exn_jmpbuf) {
		longjmp(env->exn_jmpbuf->buf, 1);
	} else {
		sml_error(0, "uncaught exception: %s", **(char***)exn);
		abort();
	}
}

/* for debug */
SML_PRIMITIVE void
sml_stack_corrupted(void *esp, void *ebp)
{
	sml_debug("*** stack corrupted esp=%p ebp=%p\n", esp, ebp);
	abort();
}

int
sml_protect(void (*func)(void *), void *data)
{
	struct sml_thread_env *env = SML_THREAD_ENV;
	struct sml_exn_jmpbuf *prev = env->exn_jmpbuf;
	struct sml_exn_jmpbuf *buf;
	int ret;

	buf = xmalloc(sizeof(jmp_buf));
	env->exn_jmpbuf = buf;

	ret = setjmp(buf->buf);
	if (ret == 0)
		func(data);

	env->exn_jmpbuf = prev;
	return ret;
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
