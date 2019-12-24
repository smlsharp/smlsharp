#include <myth/myth.h>
#include <stdlib.h>
#include <inttypes.h>

myth_barrier_t b;

static void *
task(void *p)
{
	unsigned int i;
	myth_detach(myth_self());
	for (i = 0; i < 256; i++)
		myth_barrier_wait(&b);
	return NULL;
}

static void *
start(void *p)
{
	uintptr_t n = (uintptr_t)p;
	myth_detach(myth_self());
	if (n <= 0)
		return NULL;
	if (n <= 1) {
		myth_create(task, (void*)n);
		return NULL;
	}
	uintptr_t m = n / 2;
	myth_create(start, (void*)m);
	myth_create(start, (void*)(n - m));
	return NULL;
}

int
main(int argc, char **argv)
{
	unsigned int i;
	uintptr_t n = 0;

	if (argc >= 2)
		n = atoi(argv[1]);

	myth_barrier_init(&b, NULL, n + 1);
	start((void*)n);
	for (i = 0; i < 256; i++)
		myth_barrier_wait(&b);

	return 0;
}
