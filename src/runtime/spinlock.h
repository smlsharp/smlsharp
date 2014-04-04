/*
 * spinlock.h
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 */
#ifndef SMLSHARP__SPINLOCK_H__
#define SMLSHARP__SPINLOCK_H__

#include "smlsharp.h"

#if defined(__GNUC__) && !defined(NOASM) && defined(HOST_CPU_i386)

#define ATOMIC_SWAP(addr, new_value) ({ \
	void *old_value__; \
	__asm__ volatile ("xchg %1, %0" \
			  : "+m" (*(addr)), "=a" (old_value__) \
			  : "1" (new_value) \
			  : "memory"); \
	old_value__;})

#define ATOMIC_CMPSWAP(addr, cmp, new_value) ({ \
	void *old_value__; \
	__asm__ volatile ("lock; cmpxchg %2, %0" \
			  : "+m" (*(addr)), "=a" (old_value__) \
			  : "r" (new_value), "1" (cmp) \
			  : "memory", "cc"); \
	old_value__;})

/* equivalent to (*(item_next) = *(head), *(head) = item) */
#define ATOMIC_APPEND(head, item_next, item) do { \
	void *oldhead__, *newhead__;   \
	oldhead__ = *(head); \
	for (;;) { \
		*(item_next) = oldhead__; \
		newhead__ = ATOMIC_CMPSWAP(head, oldhead__, item); \
		if (oldhead__ == newhead__) break; \
		oldhead__ = newhead__; \
	} \
} while (0)

#define ATOMIC_LOAD(addr) ({ \
	void *ret__; \
	__asm__ volatile ("movl %1, %0" : "=r" (ret__) : "m" (*(addr)) \
			  : "memory"); \
	ret__; })

#define ATOMIC_STORE(addr, value) do { \
	__asm__ volatile ("movl %1, %0" : "=m" (*(addr)) : "g" (value) \
			  : "memory"); \
} while (0)

#define ACQUIRE_AND_LOAD_INT(addr)  ((int)ATOMIC_LOAD(addr))
#define STORE_AND_RELEASE_INT(addr, value)  ATOMIC_STORE(addr, value)
#define ACQUIRE_AND_LOAD_PTR(addr)  ATOMIC_LOAD(addr)
#define STORE_AND_RELEASE_PTR(addr, value)  ATOMIC_STORE(addr, value)


#define ATOMIC_COUNTER_INC(addr) do { \
	__asm__ volatile ("lock; addl $1, %0" : "+m" (*(addr)) \
			  : : "memory", "cc"); \
} while (0)
#define ATOMIC_COUNTER_SWAP(addr, new_value) \
	((int)ATOMIC_SWAP(addr, new_value))
#define ATOMIC_COUNTER_READ(addr) \
	ACQUIRE_AND_LOAD_INT(addr)



typedef int spinlock_t;
#define SPIN_INIT(lock) (*(lock) = 0)
#define SPIN_FREE(lock) ((void)0)
/* xchg also acts as full memory barrier */
#define SPIN_LOCK(lock) do { \
	int tmp__ = 1; \
	__asm__ volatile ("\n1:\n\t" \
			  "xchg %1, %0\n\t" \
			  "testl %1, %1\n\t" \
			  "jz 1f\n\t" \
			  "2:\n" \
			  "rep\n\t"  /* rep nop == pause hint */ \
			  "nop\n\t" \
			  "cmpl $0, %0\n\t" \
			  "jnz 2b\n\t" \
			  "jmp 1b\n" \
			  "1:" \
			  : "+m" (*(lock)), "+a" (tmp__) \
			  : : "memory", "cc"); \
} while (0)
#define SPIN_UNLOCK(lock) do { \
	int tmp__ = 0; \
	__asm__ volatile ("xchg %1, %0" \
			  : "+m" (*(lock)), "+a" (tmp__) \
			  : : "memory", "cc");	\
} while (0)

#define MEM_ACQUIRE(p)  __asm__ volatile ("mfence" : : : "memory")
#define MEM_RELEASE(p)  __asm__ volatile ("mfence" : : : "memory")

#else /* NOASM */
typedef pthread_mutex_t spinlock_t;
#define SPIN_INIT(lock)   pthread_mutex_init(lock), NULL)
#define SPIN_FREE(lock)   pthread_mutex_free(lock)
#define SPIN_LOCK(lock)   pthread_mutex_lock(lock)
#define SPIN_UNLOCK(lock) pthread_mutex_unlock(lock)
#endif /* NOASM */

#endif /* SMLSHARP__SPINLOCK_H__ */
