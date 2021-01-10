#include <stdatomic.h>

int incr()
{
	static _Atomic(int) n;
	return atomic_fetch_add_explicit(&n, 1, memory_order_relaxed);
}
