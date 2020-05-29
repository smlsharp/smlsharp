#pragma once
#include <inttypes.h>

#define RET(x) (void*)(intptr_t)(x)
#define GET(x) (int)(intptr_t)(x)

extern const char threadtype[];

typedef struct thread_t *thread_t;

thread_t create(void *(*f)(void *), void *arg);
void *join(thread_t t);
