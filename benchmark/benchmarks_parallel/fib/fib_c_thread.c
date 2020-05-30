#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include "thread_c.h"

static int repeat = 10;
static int size = 40;
static int cutOff = 10;

static int
fib(int n)
{
	if (n == 0) return 0;
	if (n == 1) return 1;
	return fib(n - 1) + fib(n - 2);
}

static int pfib(int n);
struct pfib_env {
	int n;
};
static void *
pfib_fn(void *arg)
{
	const struct pfib_env *e = arg;
	return RET(pfib(e->n - 2));
}

static int
pfib(int n)
{
	if (n <= cutOff) {
		return fib(n);
	} else {
		struct pfib_env e = {n};
		thread_t t2 = create(pfib_fn, &e);
		int x = pfib(n - 1);
		int y = GET(join(t2));
		return x + y;
	}
}

static int
doit()
{
	return pfib(size);
}

static void
rep(int n)
{
	struct timeval t1, t2;
	double d1, d2;
	int r;
	while (n > 0) {
		gettimeofday(&t1, NULL);
		r = doit();
		gettimeofday(&t2, NULL);
		d1 = t1.tv_sec + (double)t1.tv_usec / 1000000;
		d2 = t2.tv_sec + (double)t2.tv_usec / 1000000;
		printf(" - {result: %d, time: %.6f}\n", r, d2 - d1);
		n--;
	}
}

int
main(int argc, char **argv)
{
	if (argc > 1) repeat = atoi(argv[1]);
	if (argc > 2) size = atoi(argv[2]);
	if (argc > 3) cutOff = atoi(argv[3]);
	printf(" bench: fib_c_%s\n size: %d\n cutoff: %d\n results:\n",
	       threadtype, size, cutOff);
	rep(repeat);
	return 0;
}
