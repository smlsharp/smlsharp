#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include "thread_c.h"

const char threadtype[] = "pthread";

thread_t
create(void *(*f)(void *), void *arg)
{
	pthread_t t;
	int n;
	n = pthread_create(&t, NULL, f, arg);
	if (n != 0) {
		perror("pthread_create");
		abort();
	}
	return (thread_t)t;
}

void *
join(thread_t t)
{
	void *r;
	int n;
	n = pthread_join((pthread_t)t, &r);
	if (n != 0) {
		perror("pthread_join");
		abort();
	}
	return r;
}
