/**
 * memory.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: memory.c,v 1.3 2008/01/23 08:20:07 katsu Exp $
 */

#include <stdlib.h>
#include "memory.h"
#include "error.h"

void *
xmalloc(size_t size)
{
	void *p = malloc(size);
	if (p == NULL)
		sysfatal("malloc");
	return p;
}

void *
xrealloc(void *p, size_t size)
{
	p = realloc(p, size);
	if (p == NULL)
		sysfatal("realloc");
	return p;
}

/* naive obstack implementation */

struct obstack {
	struct obstack *next;
	char *free;
	size_t rest;
};

#define CHUNKSIZE       64
#define CHUNKHEADERSIZE ALIGN(sizeof(struct obstack), MAXALIGN)

/* for debug */
void
obstack_dump(struct obstack *obstack)
{
	while (obstack) {
		debug("%p: free=%p, rest=%"PRIuMAX"\n",
		      (void*)obstack, (void*)obstack->free,
		      (uintmax_t)obstack->rest);
		obstack = obstack->next;
	}
}

void *
obstack_alloc(struct obstack **obstack, size_t size)
{
	size_t chunksize;
	struct obstack *newchunk;
	void *dst;

	size = ALIGN(size, MAXALIGN);

	if (*obstack == NULL || (*obstack)->rest < size) {
		chunksize = ALIGN(size + CHUNKHEADERSIZE, CHUNKSIZE);
		newchunk = xmalloc(chunksize);
		newchunk->next = *obstack;
		newchunk->free = (char*)newchunk + CHUNKHEADERSIZE;
		newchunk->rest = chunksize - CHUNKHEADERSIZE;
		*obstack = newchunk;
	}

	dst = (*obstack)->free;
	(*obstack)->rest -= size;
	(*obstack)->free += size;
	return dst;
}

void
obstack_free(struct obstack **obstack, void *ptr)
{
	struct obstack *chunk, *next;

	chunk = *obstack;

	while (chunk) {
		if (ptr != NULL
		    && (char*)chunk + CHUNKHEADERSIZE <= (char*)ptr
		    && (char*)ptr <= chunk->free) {
			chunk->rest += chunk->free - (char*)ptr;
			chunk->free = ptr;
			*obstack = chunk;
			return;
		}
		next = chunk->next;
		free(chunk);
		chunk = next;
	}

	if (ptr != NULL)
		fatal(0, "BUG: obstack_free: invalid pointer: %p %p",
		      (void*)*obstack, ptr);

	*obstack = NULL;
}

/* naive extensible array */

struct array {
	size_t filled;
	size_t size;
};

#define ARRAY_SIZE_ALIGN   256
#define ARRAY_HEADER_SIZE  ALIGN(sizeof(struct array), MAXALIGN)

void *
array_alloc(void *buf, size_t size)
{
	struct array *ary;
	size_t bufsize;

	ary = buf ? (struct array *)((char*)buf - ARRAY_HEADER_SIZE) : NULL;

	if (ary && ary->size >= size && ary->size - size <= ARRAY_SIZE_ALIGN) {
		ary->filled = size;
		return buf;
	}

	bufsize = ALIGN(size, ARRAY_SIZE_ALIGN);
	ary = xrealloc(ary, ARRAY_HEADER_SIZE + bufsize);
	ary->size = bufsize;
	ary->filled = size;
	return (void*)((char*)ary + ARRAY_HEADER_SIZE);
}

void
array_free(void *buf)
{
	if (buf)
		free((char*)buf - ARRAY_HEADER_SIZE);
}

size_t
array_size(void *buf)
{
	struct array *ary = (struct array *)((char*)buf - ARRAY_HEADER_SIZE);
	return ary->filled;
}










#if 0

#include <unistd.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <string.h>
#define PAGEHEAD(p) ((void*)(((uintptr_t)(p)-sizeof(size_t)) \
			     & ~(uintptr_t)(getpagesize() - 1)))
#undef xmalloc
#undef xrealloc
#undef free
void *
xmalloc(size_t size, const char *pos)
{
	void *page, *p;
	size_t allocsize;
	size_t pagesize = getpagesize();

	allocsize = ALIGN(size + sizeof(size_t), pagesize) + pagesize;
	page = mmap(NULL, allocsize, PROT_READ|PROT_WRITE,
		    MAP_ANON|MAP_PRIVATE, -1, 0);
	if (page == (void*)-1) sysfatal("mmap");
	mprotect(page + allocsize - pagesize, pagesize, 0);
	p = page + allocsize - pagesize - size;
	if (PAGEHEAD(p) != page) fatal(0, "xmalloc");
	*(size_t*)page = size;
	debug("xmalloc: %p (%p:%u) at %s\n", p, page, (unsigned int)size, pos);
	return p;
}

void
xfree(void *p, const char *pos)
{
	void *page;
	size_t size, allocsize;

	if (!p)	return;
	page = PAGEHEAD(p);
	size = *(size_t*)page;
	allocsize = ALIGN(size + sizeof(size_t), getpagesize());
	mprotect(page, allocsize, 0);
	debug("xfree: %p (%p:%u) at %s\n", p, page, (unsigned int)size, pos);
}

void *
xrealloc(void *p, size_t size, const char *pos)
{
	void *p2;
	size_t oldsize;

	p2 = xmalloc(size, pos);
	if (p) {
		oldsize = *(size_t*)PAGEHEAD(p);
		memcpy(p2, p, oldsize < size ? oldsize : size);
		xfree(p, pos);
	}
	return p2;
}

#endif
