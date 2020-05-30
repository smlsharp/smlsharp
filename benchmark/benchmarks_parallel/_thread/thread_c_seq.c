#include <myth/myth.h>
#include "thread_c.h"

const char threadtype[] = "seq";

thread_t
create(void *(*f)(void *), void *arg)
{
	return (thread_t)f(arg);
}

void *
join(thread_t t)
{
	return (void*)t;
}
