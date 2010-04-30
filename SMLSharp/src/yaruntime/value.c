/*
 * value.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: value.c,v 1.5 2008/02/05 08:54:35 katsu Exp $
 */

#include <stdio.h>
#include <string.h>
#include "error.h"
#include HEAP_H
#include "intinf.h"
#include "value.h"
#include "memory.h"  /* FIXME: for ZINC method */

const ml_uint_t empty_object__[1] = { OBJTYPE_UNBOXED_VECTOR };

/* for debug */
static void
obj_dump__(int indent, void *obj)
{
	unsigned int i;
	ml_uint_t *bitmap;
	void **field = obj;

	debug("%*s%p:%u:", indent, "", obj, OBJ_SIZE(obj));

	switch (OBJ_TYPE(obj)) {
	case OBJTYPE_UNBOXED_ARRAY:
	case OBJTYPE_UNBOXED_VECTOR:
		debug("%s\n",
		      (OBJ_TYPE(obj) == OBJTYPE_UNBOXED_ARRAY)
		      ? "UNBOXED_ARRAY" : "UNBOXED_VECTOR");
		for (i = 0; i < OBJ_SIZE(obj) / sizeof(void*); i++)
			debug("%*s%p\n", indent + 1, "", field[i]);
		break;

	case OBJTYPE_BOXED_ARRAY:
	case OBJTYPE_BOXED_VECTOR:
		debug("%s\n",
		      (OBJ_TYPE(obj) == OBJTYPE_BOXED_ARRAY)
		      ? "BOXED_ARRAY" : "BOXED_VECTOR");
		for (i = 0; i < OBJ_SIZE(obj) / sizeof(void*); i++)
			obj_dump__(indent + 1, field[i]);
		break;

	case OBJTYPE_RECORD:
		debug("RECORD\n");
		bitmap = OBJ_BITMAP(obj);
		for (i = 0; i < OBJ_SIZE(obj) / sizeof(void*); i++) {
			if (BITMAP_BIT(bitmap, i) != TAG_UNBOXED)
				obj_dump__(indent + 1, field[i]);
			else
				debug("%*s%p\n", indent+1, "", field[i]);
		}
		break;

	case OBJTYPE_INTINF:
		debug("INTINF\n");
		break;

	default:
		fatal(0, "BUG: invalid object type : %d", OBJ_TYPE(obj));
	}
}

void
obj_dump(void *obj)
{
	obj_dump__(0, obj);
}

int
obj_equal(void *obj1, void *obj2)
{
	//obj_dump(obj1);

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
			if (!obj_equal(p1[i], p2[i]))
				return 0;
		}
		return 1;
	}

	case OBJTYPE_RECORD:
	{
		unsigned int i;
		ml_uint_t *bitmap1 = OBJ_BITMAP(obj1);
		ml_uint_t *bitmap2 = OBJ_BITMAP(obj2);
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
				if (!obj_equal(slot1, slot2))
					return 0;
			}
		}
		return 1;
	}

	case OBJTYPE_INTINF:
		return intinf_cmp((intinf_t*)obj1, (intinf_t*)obj2) == 0;

	default:
		fatal(0, "BUG: invalid object type : %d", OBJ_TYPE(obj1));
	}
}

void *
obj_dup(void *obj)
{
	void *newobj;
	size_t obj_size;

	switch (OBJ_TYPE(obj)) {
	case OBJTYPE_UNBOXED_ARRAY:
	case OBJTYPE_BOXED_ARRAY:
	case OBJTYPE_UNBOXED_VECTOR:
	case OBJTYPE_BOXED_VECTOR:
		obj_size = OBJ_SIZE(obj);
		newobj = obj_alloc(OBJ_TYPE(obj), obj_size);
		memcpy(newobj, obj, obj_size);
		return newobj;

	case OBJTYPE_RECORD:
		obj_size = OBJ_SIZE(obj);
		newobj = record_alloc(obj_size);
		memcpy(newobj, obj,
		       obj_size + SIZEOF_BITMAP * OBJ_BITMAPS_LEN(obj_size));
		return newobj;

	case OBJTYPE_INTINF:
		return intinf_alloc_with((intinf_t*)obj);

	default:
		fatal(0, "BUG: invalid object type : %d", OBJ_TYPE(obj));
	}
}

void
obj_enum_pointers(void *obj, void (*f)(void **))
{
	unsigned int i, size;
	ml_uint_t *bitmaps;

	size = OBJ_SIZE(obj);

	DBG(("%p: size=%"PRIuMAX", type=%08x",
	     obj, (intmax_t)OBJ_SIZE(obj), (unsigned int)OBJ_TYPE(obj)));

	switch (OBJ_TYPE(obj)) {
	case OBJTYPE_UNBOXED_ARRAY:
	case OBJTYPE_UNBOXED_VECTOR:
	case OBJTYPE_INTINF:
		break;

	case OBJTYPE_BOXED_ARRAY:
	case OBJTYPE_BOXED_VECTOR:
		for (i = 0; i < OBJ_SIZE(obj) / sizeof(void*); i++)
			f((void**)obj + i);
		break;

	case OBJTYPE_RECORD:
		bitmaps = OBJ_BITMAP(obj);
		for (i = 0; i < OBJ_SIZE(obj) / sizeof(void*); i++) {
			if (BITMAP_BIT(bitmaps, i) != TAG_UNBOXED)
				f((void**)obj + i);
		}
		break;

	default:
		fatal(0, "BUG: invalid object type : %d", OBJ_TYPE(obj));
	}
}

static char *
alloc_str(unsigned int objtype, size_t len)
{
	char *obj;
	size_t alloc_size;

	/* FIXME: ZINC method is not needed now. */
	/*
	 * |<----------- multiple of words ------------->|
	 * [head] [word1] [word2] ... [wordN] [tail] [pad]
	 *
	 * tail:
	 *   c1 c2 c3 c4  -> c1 c2 c3 c4 00 00 00 04
	 *   c1 c2 c3 00  -> c1 c2 c3 00 00 00 00 05
	 *   c1 c2 00 00  -> c1 c2 00 02
	 *   c1 00 00 00  -> c1 00 00 03
	 *
	 * payloadSize = wordSize * N + tail size
	 */
	alloc_size = ALIGN(len + 2, sizeof(ml_uint_t));

	obj = obj_alloc(objtype, alloc_size);
	*((ml_uint_t*)&obj[OBJ_SIZE(obj)] - 1) = 0;
	*((ml_uint_t*)&obj[OBJ_SIZE(obj)] - 1) = 0;
	obj[OBJ_SIZE(obj) - 1] = OBJ_SIZE(obj) - len; /* pad size */
	obj[len] = '\0'; /* sentinel */
	return obj;
}

size_t
string_size(void *obj)
{
	size_t len;

	ASSERT(OBJ_TYPE(obj) == OBJTYPE_UNBOXED_VECTOR
	       || OBJ_TYPE(obj) == OBJTYPE_UNBOXED_ARRAY);
	ASSERT(OBJ_SIZE(obj) > 0);

	len = OBJ_SIZE(obj);
	return len - ((unsigned char*)obj)[len - 1];
}

char *
string_alloc(size_t len)
{
	return alloc_str(OBJTYPE_UNBOXED_VECTOR, len);
}

char *
bytearray_alloc(size_t len)
{
	return alloc_str(OBJTYPE_UNBOXED_ARRAY, len);
}

char *
string_alloc_with(const char *str, size_t len)
{
	char *obj;
	obj = string_alloc(len);
	memcpy(obj, str, len);
	return obj;
}
