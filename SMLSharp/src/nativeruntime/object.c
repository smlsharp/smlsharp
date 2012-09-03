/*
 * object.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: value.c,v 1.5 2008/02/05 08:54:35 katsu Exp $
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "smlsharp.h"
#include "intinf.h"
#include "object.h"
#include "objspace.h"
#include "heap.h"

/* for debug */
static void
obj_dump__(int indent, void *obj)
{
	unsigned int i;
	unsigned int *bitmap;
	void **field = obj;
	char *buf;

	if (obj == NULL) {
		sml_debug("%*sNULL\n", indent, "");
		return;
	}

	switch (OBJ_TYPE(obj)) {
	case OBJTYPE_UNBOXED_ARRAY:
	case OBJTYPE_UNBOXED_VECTOR:
		sml_debug("%*s%p:%u:%s\n",
			  indent, "", obj, OBJ_SIZE(obj),
			  (OBJ_TYPE(obj) == OBJTYPE_UNBOXED_ARRAY)
			  ? "UNBOXED_ARRAY" : "UNBOXED_VECTOR");
		for (i = 0; i < OBJ_SIZE(obj) / sizeof(unsigned int); i++)
			sml_debug("%*s0x%08x\n",
				  indent + 2, "", ((unsigned int *)field)[i]);
		for (i = i * sizeof(unsigned int); i < OBJ_SIZE(obj); i++)
			sml_debug("%*s0x%02x\n",
				  indent + 2, "", ((unsigned char*)field)[i]);
		break;

	case OBJTYPE_BOXED_ARRAY:
	case OBJTYPE_BOXED_VECTOR:
		sml_debug("%*s%p:%u:%s\n",
			  indent, "", obj, OBJ_SIZE(obj),
			  (OBJ_TYPE(obj) == OBJTYPE_BOXED_ARRAY)
			  ? "BOXED_ARRAY" : "BOXED_VECTOR");
		for (i = 0; i < OBJ_SIZE(obj) / sizeof(void*); i++)
			obj_dump__(indent + 2, field[i]);
		for (i = i * sizeof(void*); i < OBJ_SIZE(obj); i++)
			sml_debug("%*s0x%02x\n",
				  indent + 2, "", ((char*)field)[i]);
		break;

	case OBJTYPE_RECORD:
		sml_debug("%*s%p:%u:RECORD\n",
			  indent, "", obj, OBJ_SIZE(obj));
		bitmap = OBJ_BITMAP(obj);
		for (i = 0; i < OBJ_SIZE(obj) / sizeof(void*); i++) {
			if (BITMAP_BIT(bitmap, i) != TAG_UNBOXED)
				obj_dump__(indent + 2, field[i]);
			else
				sml_debug("%*s%p\n", indent + 2, "", field[i]);
		}
		break;

	case OBJTYPE_INTINF:
		buf = sml_intinf_fmt((sml_intinf_t*)obj, 10);
		sml_debug("%*s%p:%u:INTINF: %s\n",
			  indent, "", obj, OBJ_SIZE(obj), buf);
		free(buf);
		break;

	default:
		sml_debug("%*s%p:%u:unknown type %u",
			  indent, "", obj, OBJ_SIZE(obj), OBJ_TYPE(obj));
		break;
	}
}

void
sml_obj_dump(void *obj)
{
	obj_dump__(0, obj);
}

int
sml_obj_equal(void *obj1, void *obj2)
{
	if (OBJ_TYPE(obj1) != OBJ_TYPE(obj2))
		return 0;

	if (obj1 == obj2)
		return 1;

	switch (OBJ_TYPE(obj1)) {
	case OBJTYPE_UNBOXED_ARRAY:
	case OBJTYPE_BOXED_ARRAY:
		return (obj1 == obj2);

	case OBJTYPE_UNBOXED_VECTOR:
		if (OBJ_SIZE(obj1) != OBJ_SIZE(obj2))
			return 0;
		return (memcmp(obj1, obj2, OBJ_SIZE(obj1)) == 0);

	case OBJTYPE_BOXED_VECTOR:
	{
		unsigned int i;
		void **p1 = obj1;
		void **p2 = obj2;

		if (OBJ_SIZE(obj1) != OBJ_SIZE(obj2))
			return 0;

		ASSERT(OBJ_SIZE(obj1) % sizeof(void*) == 0);

		for (i = 0; i < OBJ_SIZE(obj1) / sizeof(void*); i++) {
			if (!sml_obj_equal(p1[i], p2[i]))
				return 0;
		}
		return 1;
	}

	case OBJTYPE_RECORD:
	{
		unsigned int i;
		unsigned int *bitmap1 = OBJ_BITMAP(obj1);
		unsigned int *bitmap2 = OBJ_BITMAP(obj2);
		void *slot1, *slot2;

		if (OBJ_SIZE(obj1) != OBJ_SIZE(obj2)
		    || OBJ_NUM_BITMAPS(obj1) != OBJ_NUM_BITMAPS(obj2))
			return 0;

		ASSERT(OBJ_SIZE(obj1) % sizeof(void*) == 0);

		for (i = 0; i < OBJ_NUM_BITMAPS(obj1); i++) {
			if (bitmap1[i] != bitmap2[i])
				return 0;
		}

		for (i = 0; i < OBJ_SIZE(obj1) / sizeof(void*); i++) {
			slot1 = ((void**)obj1)[i];
			slot2 = ((void**)obj2)[i];
			if (BITMAP_BIT(bitmap1, i) == TAG_UNBOXED) {
				if (slot1 != slot2)
					return 0;
			} else {
				if (!sml_obj_equal(slot1, slot2))
					return 0;
			}
		}
		return 1;
	}

	case OBJTYPE_INTINF:
		return sml_intinf_cmp((sml_intinf_t*)obj1,
				      (sml_intinf_t*)obj2) == 0;

	default:
		sml_fatal(0, "BUG: invalid object type : %d", OBJ_TYPE(obj1));
	}
}

void *
sml_obj_dup(void *obj)
{
	void *newobj;
	size_t obj_size;

	switch (OBJ_TYPE(obj)) {
	case OBJTYPE_UNBOXED_ARRAY:
	case OBJTYPE_BOXED_ARRAY:
	case OBJTYPE_UNBOXED_VECTOR:
	case OBJTYPE_BOXED_VECTOR:
		obj_size = OBJ_SIZE(obj);
		newobj = sml_obj_alloc(OBJ_TYPE(obj), obj_size);
		memcpy(newobj, obj, obj_size);
		return newobj;

	case OBJTYPE_RECORD:
		obj_size = OBJ_SIZE(obj);
		newobj = sml_record_alloc(obj_size);
		memcpy(newobj, obj,
		       obj_size + SIZEOF_BITMAP * OBJ_BITMAPS_LEN(obj_size));
		return newobj;

	case OBJTYPE_INTINF:
		newobj = sml_intinf_new();
		sml_intinf_set((sml_intinf_t*)newobj, (sml_intinf_t*)obj);
		return newobj;


	default:
		sml_fatal(0, "BUG: invalid object type : %d", OBJ_TYPE(obj));
	}
}

void
sml_obj_enum_ptr(void *obj, sml_trace_cls *trace)
{
	unsigned int i, size;
	unsigned int *bitmaps;

	size = OBJ_SIZE(obj);

	/*
	DBG(("%p: size=%lu, type=%08x",
	     obj, (unsigned long)OBJ_SIZE(obj), (unsigned int)OBJ_TYPE(obj)));
	*/

	switch (OBJ_TYPE(obj)) {
	case OBJTYPE_UNBOXED_ARRAY:
	case OBJTYPE_UNBOXED_VECTOR:
	case OBJTYPE_INTINF:
		break;

	case OBJTYPE_BOXED_ARRAY:
	case OBJTYPE_BOXED_VECTOR:
		for (i = 0; i < OBJ_SIZE(obj) / sizeof(void*); i++)
			(*trace)((void**)obj + i, trace);
		break;

	case OBJTYPE_RECORD:
		bitmaps = OBJ_BITMAP(obj);
		for (i = 0; i < OBJ_SIZE(obj) / sizeof(void*); i++) {
			if (BITMAP_BIT(bitmaps, i) != TAG_UNBOXED)
				(*trace)((void**)obj + i, trace);
		}
		break;

	default:
		sml_fatal(0, "BUG: invalid object type : %d", OBJ_TYPE(obj));
	}
}

#ifndef HEAP_OWN_SML_ALLOC
SML_PRIMITIVE void *
sml_alloc(unsigned int objsize, void *frame_pointer)
{
	/* objsize = payload_size + bitmap_size */
	void *obj;
	size_t inc = HEAP_ROUND_SIZE(OBJ_HEADER_SIZE + objsize);
	HEAP_FAST_ALLOC(obj, inc, (sml_save_frame_pointer(frame_pointer),
				   sml_heap_slow_alloc(inc)));
	OBJ_HEADER(obj) = 0;
	return obj;
}
#endif /* HEAP_OWN_SML_ALLOC */

void *
sml_obj_alloc(unsigned int objtype, size_t payload_size)
{
	void *obj;
#ifndef HEAP_OWN_SML_ALLOC
	size_t alloc_size;
#endif /* HEAP_OWN_SML_ALLOC */

	ASSERT(((unsigned int)payload_size & OBJ_SIZE_MASK) == payload_size);

#ifdef HEAP_OWN_SML_ALLOC
	obj = sml_alloc(payload_size, sml_load_frame_pointer());
#else
	alloc_size = HEAP_ROUND_SIZE(OBJ_HEADER_SIZE + payload_size);
	HEAP_FAST_ALLOC(obj, alloc_size, sml_heap_slow_alloc(alloc_size));
#endif /* HEAP_OWN_SML_ALLOC */
	OBJ_HEADER(obj) = OBJ_HEADER_WORD(objtype, payload_size);

	ASSERT(OBJ_SIZE(obj) == payload_size);
	ASSERT(OBJ_TYPE(obj) == OBJTYPE_UNBOXED_VECTOR
	       || OBJ_TYPE(obj) == OBJTYPE_BOXED_VECTOR
	       || OBJ_TYPE(obj) == OBJTYPE_UNBOXED_ARRAY
	       || OBJ_TYPE(obj) == OBJTYPE_BOXED_ARRAY
	       || OBJ_TYPE(obj) == OBJTYPE_INTINF);
	ASSERT(OBJ_GC1(obj) == 0 && OBJ_GC2(obj) == 0);

	return obj;
}

SML_PRIMITIVE void *
sml_alloc_code(unsigned int objsize, void *frame_pointer)
{
	sml_save_frame_pointer(frame_pointer);
	return sml_obj_malloc(objsize);
}

void *
sml_record_alloc(size_t payload_size)
{
	void *obj;
	size_t bitmap_size;

	ASSERT(((unsigned int)payload_size & OBJ_SIZE_MASK) == payload_size);

	payload_size = ALIGNSIZE(payload_size, sizeof(void*));
	bitmap_size = OBJ_BITMAPS_LEN(payload_size) * SIZEOF_BITMAP;
	obj = sml_obj_alloc(OBJTYPE_RECORD, payload_size + bitmap_size);

	ASSERT(OBJ_SIZE(obj) == payload_size);
	ASSERT(OBJ_TYPE(obj) == OBJTYPE_RECORD);
	ASSERT(OBJ_GC1(obj) == 0 && OBJ_GC2(obj) == 0);

	return obj;
}

char *
sml_str_alloc(size_t len)
{
	char *obj;
	obj = sml_obj_alloc(OBJTYPE_UNBOXED_VECTOR, len + 1);
	obj[len] = '\0';
	return obj;
}

char *
sml_str_new2(const char *str, size_t len)
{
	char *obj;
	obj = sml_obj_alloc(OBJTYPE_UNBOXED_VECTOR, len + 1);
	memcpy(obj, str, len);
	obj[len] = '\0';
	return obj;
}

char *
sml_str_new(const char *str)
{
	return sml_str_new2(str, strlen(str));
}

static void
intinf_free(void *obj, void *data ATTR_UNUSED)
{
	sml_intinf_clear((sml_intinf_t*)obj);
}

sml_intinf_t *
sml_intinf_new()
{
	sml_intinf_t *obj;
	obj = sml_obj_alloc(OBJTYPE_INTINF, sizeof(sml_intinf_t));
	obj = sml_add_finalizer(obj, intinf_free, NULL);
	sml_intinf_init(obj);
	return obj;
}

SML_PRIMITIVE void *
sml_obj_empty()
{
	static const unsigned int emptyobj[2] = {OBJTYPE_UNBOXED_VECTOR, 0};
	return (void*)&emptyobj[1];
}

SML_PRIMITIVE void
sml_write_barrier(void *writeaddr, void *objaddr)
{
	/* DBG(("%p of %p", writeaddr, objaddr)); */
	HEAP_WRITE_BARRIER(writeaddr, objaddr);
}
