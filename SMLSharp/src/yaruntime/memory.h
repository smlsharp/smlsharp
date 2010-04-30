/**
 * memory.h - simple memory management for C.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: memory.h,v 1.3 2008/01/23 08:20:07 katsu Exp $
 */
#ifndef SMLSHARP__MEMORY_H__
#define SMLSHARP__MEMORY_H__

#include <stdlib.h>
#include "cdecl.h"

/*
 * the number of elements of an array.
 */
#define arraysize(a)   (sizeof(a) / sizeof(a[0]))

/*
 * MAXALIGN : the conservative maximum system alignment constraint.
 */
union alignment__ {
	char c; short s; int i; long n;
	float f; double d; void *p;
};
#define MAXALIGN    (sizeof(union alignment__))

/*
 * ALIGN(x,y) : round up x to the multiple of y.
 */
#define ALIGN(x,y)  (((x) + (y) - 1) - ((x) + (y) - 1) % (y))

/*
 * an safe malloc.
 */
void *xmalloc(size_t size) ATTR_MALLOC;

/*
 * an safe realloc.
 */
void *xrealloc(void *p, size_t size) ATTR_MALLOC;


#if 0
#define XFILELINE__(x,y)  x":"#y
#define XFILELINE_(x,y) XFILELINE__(x,y)
#define XFILELINE XFILELINE_(__FILE__,__LINE__)
void *xmalloc(size_t size, const char *pos) ATTR_MALLOC;
void *xrealloc(void *p, size_t size, const char *pos);
void xfree(void *p, const char *pos);
#define xmalloc(x) xmalloc(x, XFILELINE)
#define xrealloc(x,y) xrealloc(x, y, XFILELINE)
#define free(x) xfree(x,XFILELINE)
#endif


/* naive obstack implementation */

typedef struct obstack obstack_t;
void *obstack_alloc(obstack_t **obstack, size_t size);
void obstack_free(obstack_t **obstack, void *ptr);

/* naive extensible array */

void *array_alloc(void *ary, size_t size);
void array_free(void *ary);
size_t array_size(void *ary);


#endif /* SMLSHARP__MEMORY_H__ */
