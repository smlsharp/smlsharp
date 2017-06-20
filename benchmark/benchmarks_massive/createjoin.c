#include <myth/myth.h>
#include <stdlib.h>

struct arg {
	unsigned int i, n;
};

static void *
task(unsigned int i)
{
	return NULL;
}

static void *
start(void *p)
{
	struct arg *arg = p;
	if (arg->n <= 0)
		return NULL;
	if (arg->n <= 1)
		return task(arg->i);
	unsigned int m = arg->n / 2;
	struct arg a1 = {arg->i, m};
	struct arg a2 = {arg->i + m, arg->n - m};
	myth_thread_t t1 = myth_create(start, &a1);
	myth_thread_t t2 = myth_create(start, &a2);
	myth_join(t1, NULL);
	myth_join(t2, NULL);
	return NULL;
}

int
main(int argc, char **argv)
{
	unsigned int i;
	struct arg arg = {0, 0};

	if (argc >= 2)
		arg.n = atoi(argv[1]);
	
	for (i = 0; i < 256; i++)
		start(&arg);
}
