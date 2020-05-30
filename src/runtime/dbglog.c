#include <stdio.h>
#include <stdlib.h>
#include <stdatomic.h>
#include <inttypes.h>
#include "dbglog.h"

#ifndef DBG__BUFSIZE
#define DBG__BUFSIZE (8 * 1024 * 1024)
#endif
static struct DBG__log {
	_Atomic(uintptr_t) idx;
	uintptr_t buf[DBG__BUFSIZE + DBG__MAXARGS - 1];
} DBG__log;
#define DBG__fetchadd(p,v) atomic_fetch_add_explicit(p, v, memory_order_relaxed)

uintptr_t *
DBG__alloc(const char *fmt)
{
	unsigned int size = *(const unsigned char *)fmt;
	uintptr_t start = DBG__fetchadd(&DBG__log.idx, size);
	DBG__log.buf[(start + size - 1) % DBG__BUFSIZE] = (uintptr_t)fmt;
	return &DBG__log.buf[start % DBG__BUFSIZE];
}

struct log {
	uintptr_t size;
	const char *fmt;
	uintptr_t *args;
};

static inline struct log
DBG__getlog(uintptr_t index)
{
	struct log log;
	const char *fmt = (const char *)DBG__log.buf[index % DBG__BUFSIZE];
	log.size = *(unsigned char *)fmt;
	log.fmt = &fmt[1];
	log.args = &DBG__log.buf[(index - log.size + 1) % DBG__BUFSIZE];
	return log;
}

static inline void
DBG__printlog(FILE *out, struct log log)
{
#define A(i) log.args[i]
	switch(log.size) {
	case 1: fprintf(out,log.fmt); break; /* ignore warning */
	case 2: fprintf(out,log.fmt,A(0)); break;
	case 3: fprintf(out,log.fmt,A(0),A(1)); break;
	case 4: fprintf(out,log.fmt,A(0),A(1),A(2)); break;
	case 5: fprintf(out,log.fmt,A(0),A(1),A(2),A(3)); break;
	case 6: fprintf(out,log.fmt,A(0),A(1),A(2),A(3),A(4)); break;
	case 7: fprintf(out,log.fmt,A(0),A(1),A(2),A(3),A(4),A(5));break;
	case 8: fprintf(out,log.fmt,A(0),A(1),A(2),A(3),A(4),A(5),A(6));break;
	default: fprintf(out, "*** malformed log ***\n"); break;
	}
#undef A
}

static inline uintptr_t *
DBG__indexarray(uintptr_t top, uintptr_t *bottom)
{
	uintptr_t limit = *bottom;
	uintptr_t *buf = malloc(sizeof(uintptr_t) * (DBG__BUFSIZE + 1));
	if (!buf) {
		perror("malloc");
		return NULL;
	}
	*buf = (uintptr_t)-1;

	while (limit < top) {
		struct log log = DBG__getlog(top - 1);
		if (top - limit < log.size)
			break;
		*(++buf) = top - 1;
		top -= log.size;
	}
	*bottom = top;
	return buf;
}

static inline void
DBG__dump(FILE *out)
{
	uintptr_t top = DBG__log.idx;
	uintptr_t limit = top < DBG__BUFSIZE ? 0 : top - DBG__BUFSIZE;
	uintptr_t *p;

	p = DBG__indexarray(top, &limit);
	if (!p)
		return;
	if (top > DBG__BUFSIZE)
		fprintf(out, "  - -- %"PRIuPTR" words lost -- -\n", limit);
	if (*p == (uintptr_t)-1)
		fprintf(out, "  - -- no log found -- -\n");
	for (; *p != (uintptr_t)-1; p--)
		DBG__printlog(out, DBG__getlog(*p));
	free(p);
}

void
DBGdump(const char *filename)
{
	if (!filename) {
		DBG__dump(stderr);
	} else {
		FILE *out = fopen(filename, "w");
		if (!out) {
			perror(filename);
			return;
		}
		DBG__dump(out);
		fclose(out);
	}
}
