#include <myth/myth.h>
#include "thread_c.h"

const char threadtype[] = "myth";

thread_t
create(void *(*f)(void *), void *arg)
{
	return (thread_t)myth_create(f, arg);
}

void *
join(thread_t t)
{
	void *r;
	myth_join((myth_thread_t)t, &r);
	return r;
}
