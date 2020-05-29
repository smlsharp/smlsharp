#include <signal.h>
#include <limits.h>
#include "smlsharp.h"

static _Atomic(unsigned int) signals;
static _Atomic(sml_check_hook_fn) signal_hook;

unsigned int
sml_signal_check()
{
	unsigned int r;
	r = load_relaxed(&signals);
	if (r)
		r = swap(relaxed, &signals, 0);
	return r;
}

static void
signal_handler(int signum)
{
	if (signum < sizeof(signals) * CHAR_BIT && signal_hook) {
		fetch_or(relaxed, &signals, 1U << signum);
		sml_set_check_hook(signal_hook);
		sml_gc(0);
	}
}

static int
do_sigaction(int signum, const char *signame, const struct sigaction *sa)
{
	struct sigaction old;
	int r = sigaction(signum, sa, &old);
	if (r == 0 && old.sa_handler != SIG_DFL) {
		sml_warn(0, "%s handler is already set", signame);
		r = sigaction(signum, &old, NULL);
	}
	return r;
}

int
sml_signal_sigaction(sml_check_hook_fn hook)
{
	struct sigaction sa;
	int r;

	store_relaxed(&signal_hook, hook);

	sa.sa_handler = signal_handler;
	sa.sa_flags = 0;
	r = sigemptyset(&sa.sa_mask);
	if (r != 0)
		return r;
	r = do_sigaction(SIGINT, "SIGINT", &sa);
	if (r != 0)
		return r;
	r = do_sigaction(SIGHUP, "SIGHUP", &sa);
	if (r != 0)
		return r;
	r = do_sigaction(SIGPIPE, "SIGPIPE", &sa);
	if (r != 0)
		return r;
#if 0
	/* MassiveThreads handles SIGALRM */
	r = do_sigaction(SIGALRM, "SIGALRM", &sa);
	if (r != 0)
		return r;
#endif
	r = do_sigaction(SIGTERM, "SIGTERM", &sa);
	if (r != 0)
		return r;
	return 0;
}
