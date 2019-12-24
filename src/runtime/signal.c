#include <signal.h>
#include "smlsharp.h"

static _Atomic(unsigned int) signaled;

#define FLAG_SIGINT   0x1
#define FLAG_SIGHUP   0x2
#define FLAG_SIGPIPE  0x4
#define FLAG_SIGALRM  0x8
#define FLAG_SIGTERM  0x16

static void
signal_handler(int signum)
{
	switch (signum) {
	case SIGINT: fetch_or(relaxed, &signaled, FLAG_SIGINT); break;
	case SIGHUP: fetch_or(relaxed, &signaled, FLAG_SIGHUP); break;
	case SIGPIPE: fetch_or(relaxed, &signaled, FLAG_SIGPIPE); break;
	case SIGALRM: fetch_or(relaxed, &signaled, FLAG_SIGALRM); break;
	case SIGTERM: fetch_or(relaxed, &signaled, FLAG_SIGTERM); break;
	}
	sml_send_signal();
}

unsigned int
sml_signal_check()
{
	return swap(relaxed, &signaled, 0);
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
sml_signal_sigaction()
{
	struct sigaction sa;
	int r;

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
