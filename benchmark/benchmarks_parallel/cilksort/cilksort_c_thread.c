#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include "thread_c.h"

static int repeat = 10;
static int size = 4194304;
static int cutOff = 32;

static void
copy(const double *a, int b, int e, double *d, int j)
{
	while (e >= b)
		d[j++] = a[b++];
}

static int
search(const double *a, int b, int e, double k)
{
	int m;
	for (;;) {
		if (e < b) return e + 1;
		if (e == b) return k < a[e] ? e : e + 1;
		m = (b + e) / 2;
		if (k < a[m])
			e = m;
		else
			b = m + 1;
	}
}

static void
merge(const double *a, int b1, int e1, int b2, int e2, double *d, int j);

struct merge_env {
	const double *a;
	int b1, e1, b2, e2;
	double *d;
	int j;
};
static void *
merge_fn(void *arg)
{
	const struct merge_env *e = arg;
	merge(e->a, e->b1, e->e1, e->b2, e->e2, e->d, e->j);
	return NULL;
}

static void
merge(const double *a, int b1, int e1, int b2, int e2, double *d, int j)
{
	if (e1 < b1)
		copy(a, b2, e2, d, j);
	else if (e2 < b2)
		copy(a, b1, e1, d, j);
	else if (e1 - b1 < e2 - b2)
		merge(a, b2, e2, b1, e1, d, j);
	else if (a[e1] <= a[b2]) {
		copy(a, b1, e1, d, j);
		copy(a, b2, e2, d, j+(e1-b1+1));
	} else if (a[e2] <= a[b1]) {
		copy(a, b2, e2, d, j);
		copy(a, b1, e1, d, j+(e2-b2+1));
	} else {
		int m = (b1 + e1) / 2;
		int n = search(a, b2, e2, a[m]);
		if (e1 - b1 <= cutOff) {
			merge(a, b1, m, b2, n-1, d, j);
			merge(a, m+1, e1, n, e2, d, j+(m-b1+1)+(n-b2));
		} else {
			struct merge_env e = {a, b1, m, b2, n-1, d, j};
			thread_t t1 = create(merge_fn, &e);
			merge(a, m+1, e1, n, e2, d, j+(m-b1+1)+(n-b2));
			join(t1);
		}
	}
}

static void
cilksort(double *a, int b, int e, double *d, int j);

struct cilksort_env {
	double *a;
	int b, e;
	double *d;
	int j;
};
static void *
cilksort_fn(void *arg)
{
	const struct cilksort_env *e = arg;
	cilksort(e->a, e->b, e->e, e->d, e->j);
	return NULL;
}

struct cilksort_env1 {
	double *a;
	int b, q1, q2;
	double *d;
	int j;
};
static void *
cilksort_fn1(void *arg)
{
	const struct cilksort_env1 *e = arg;
	struct cilksort_env e0 = {e->a, e->b, e->q1, e->d, e->j};
	thread_t t1 = create(cilksort_fn, &e0);
	cilksort(e->a, e->q1+1, e->q2, e->d, e->j+(e->q1-e->b+1));
	join(t1);
	merge(e->a, e->b, e->q1, e->q1+1, e->q2, e->d, e->j);
	return NULL;
}

static void
cilksort(double *a, int b, int e, double *d, int j)
{
	if (e <= b) return;
	int q2 = (b + e) / 2;
	int q1 = (b + q2) / 2;
	int q3 = (q2+1 + e) / 2;
	if (e - b <= cutOff) {
		cilksort(a, b, q1, d, j);
		cilksort(a, q1+1, q2, d, j+(q1-b+1));
		cilksort(a, q2+1, q3, d, j+(q2-b+1));
		cilksort(a, q3+1, e, d, j+(q3-b+1));
		merge(a, b, q1, q1+1, q2, d, j);
		merge(a, q2+1, q3, q3+1, e, d, j+(q2-b+1));
		merge(d, b, q2, q2+1, e, a, b);
	} else {
		struct cilksort_env1 e1 = {a, b, q1, q2, d, j};
		thread_t t1 = create(cilksort_fn1, &e1);
		struct cilksort_env e2 = {a, q2+1, q3, d, j+(q2-b+1)};
		thread_t t2 = create(cilksort_fn, &e2);
		cilksort(a, q3+1, e, d, j+(q3-b+1));
		join(t2);
		merge(a, q2+1, q3, q3+1, e, d, j+(q2-b+1));
		join(t1);
		merge(d, b, q2, q2+1, e, a, b);
	}
}

static int pmseed = 1;
static int
pmrand()
{
	int hi = pmseed / (2147483647 / 48271);
	int lo = pmseed % (2147483647 / 48271);
	int test = 48271 * lo - (2147483647 % 48271) * hi;
	pmseed = test > 0 ? test : test + 2147483647;
	return pmseed;
}

static double
randReal()
{
	double d1 = pmrand();
	double d2 = pmrand();
	return d1 / d2;
}

static double *
init_a()
{
	int i;
	double *a = malloc(sizeof(double) * size);
	if (!a) abort();
	pmseed = 1;
	for (i = 0; i < size; i++) a[i] = randReal();
	return a;
}

static double *
init_d()
{
	double *d = malloc(sizeof(double) * size);
	if (!d) abort();
	return d;
}

static void
doit(double *a, double *d)
{
	cilksort(a, 0, size - 1, d, 0);
}

static void
rep(int n)
{
	struct timeval t1, t2;
	double d1, d2;
	while (n > 0) {
		double *a = init_a();
		double *d = init_d();
		gettimeofday(&t1, NULL);
		doit(a, d);
		gettimeofday(&t2, NULL);
#if 0
		for (int i = 0; i < size; i++) fprintf(stderr, "%.6f\n", a[i]);
#endif
		free(a);
		free(d);
		d1 = t1.tv_sec + (double)t1.tv_usec / 1000000;
		d2 = t2.tv_sec + (double)t2.tv_usec / 1000000;
		printf(" - {result: %d, time: %.6f}\n", 0, d2 - d1);
		n--;
	}
}

int
main(int argc, char **argv)
{
	if (argc > 1) repeat = atoi(argv[1]);
	if (argc > 2) size = atoi(argv[2]);
	if (argc > 3) cutOff = atoi(argv[3]);
	printf(" bench: cilksort_c_%s\n size: %d\n cutoff: %d\n results:\n",
	       threadtype, size, cutOff);
	rep(repeat);
	return 0;
}
