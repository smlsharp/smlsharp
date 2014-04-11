/*
 * object.c
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
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

/* for debug */
void
sml_obj_dump(void *obj)
{
	obj_dump__(0, obj);
}

SML_PRIMITIVE int
sml_obj_equal(void *obj1, void *obj2)
{
	unsigned int i, tag;
	unsigned int *bitmap1, *bitmap2;
	void **p1, **p2;

	if (obj1 == obj2)
		return 1;

	if (obj1 == NULL || obj2 == NULL)
		return 0;

	if (OBJ_SIZE(obj1) != OBJ_SIZE(obj2))
		return 0;

	if (OBJ_TYPE(obj1) != OBJ_TYPE(obj2)) {
		if (OBJ_TYPE(obj1) == OBJTYPE_RECORD) {
			void *tmp = obj1;
			obj1 = obj2, obj2 = tmp;
		}
		else if (OBJ_TYPE(obj2) != OBJTYPE_RECORD)
			return 0;
		if (OBJ_TYPE(obj1) == OBJTYPE_UNBOXED_VECTOR)
			tag = TAG_UNBOXED;
		else if (OBJ_TYPE(obj1) == OBJTYPE_BOXED_VECTOR)
			tag = TAG_BOXED;
		else
			return 0;

		ASSERT(OBJ_SIZE(obj2) % sizeof(void*) == 0);
		bitmap2 = OBJ_BITMAP(obj2);
		for (i = 0; i < OBJ_SIZE(obj2) / sizeof(void*); i++) {
			if (BITMAP_BIT(bitmap2, i) != tag)
				return 0;
		}
	}

	switch (OBJ_TYPE(obj1)) {
	case OBJTYPE_UNBOXED_ARRAY:
	case OBJTYPE_BOXED_ARRAY:
		return 0;

	case OBJTYPE_UNBOXED_VECTOR:
		return memcmp(obj1, obj2, OBJ_SIZE(obj1)) == 0;

	case OBJTYPE_BOXED_VECTOR:
		p1 = obj1;
		p2 = obj2;
		ASSERT(OBJ_SIZE(obj1) % sizeof(void*) == 0);
		for (i = 0; i < OBJ_SIZE(obj1) / sizeof(void*); i++) {
			if (!sml_obj_equal(p1[i], p2[i]))
				return 0;
		}
		return 1;

	case OBJTYPE_INTINF:
		return sml_intinf_cmp((sml_intinf_t*)obj1,
				      (sml_intinf_t*)obj2) == 0;

	case OBJTYPE_RECORD:
		bitmap1 = OBJ_BITMAP(obj1);
		bitmap2 = OBJ_BITMAP(obj2);
		p1 = obj1;
		p2 = obj2;

		ASSERT(OBJ_NUM_BITMAPS(obj1) == OBJ_NUM_BITMAPS(obj2));
		ASSERT(OBJ_SIZE(obj1) % sizeof(void*) == 0);

		for (i = 0; i < OBJ_NUM_BITMAPS(obj1); i++) {
			if (bitmap1[i] != bitmap2[i])
				return 0;
		}
		for (i = 0; i < OBJ_SIZE(obj1) / sizeof(void*); i++) {
			if (BITMAP_BIT(bitmap1, i) == TAG_UNBOXED) {
				if (p1[i] != p2[i])
					return 0;
			} else {
				if (!sml_obj_equal(p1[i], p2[i]))
					return 0;
			}
		}
		return 1;

	default:
		sml_fatal(0, "BUG: invalid object type : %d", OBJ_TYPE(obj1));
	}
}

SML_PRIMITIVE void *
sml_obj_dup(void *obj)
{
	void **slot, *newobj;
	size_t obj_size;

	switch (OBJ_TYPE(obj)) {
	case OBJTYPE_UNBOXED_ARRAY:
	case OBJTYPE_BOXED_ARRAY:
	case OBJTYPE_UNBOXED_VECTOR:
	case OBJTYPE_BOXED_VECTOR:
		obj_size = OBJ_SIZE(obj);
		slot = sml_tmp_root();
		*slot = obj;
		newobj = sml_obj_alloc(OBJ_TYPE(obj), obj_size);
		memcpy(newobj, *slot, obj_size);
		break;

	case OBJTYPE_RECORD:
		obj_size = OBJ_SIZE(obj);
		slot = sml_tmp_root();
		*slot = obj;
		newobj = sml_record_alloc(obj_size);
		memcpy(newobj, *slot,
		       obj_size + SIZEOF_BITMAP * OBJ_BITMAPS_LEN(obj_size));
		break;

	case OBJTYPE_INTINF:
		newobj = sml_intinf_new();
		sml_intinf_set((sml_intinf_t*)newobj, (sml_intinf_t*)obj);
		break;

	default:
		sml_fatal(0, "BUG: invalid object type : %d", OBJ_TYPE(obj));
	}

	return newobj;
}

void
sml_obj_enum_ptr(void *obj, void (*trace)(void **))
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
			trace((void**)obj + i);
		break;

	case OBJTYPE_RECORD:
		bitmaps = OBJ_BITMAP(obj);
		for (i = 0; i < OBJ_SIZE(obj) / sizeof(void*); i++) {
			if (BITMAP_BIT(bitmaps, i) != TAG_UNBOXED)
				trace((void**)obj + i);
		}
		break;

	default:
		sml_fatal(0, "BUG: invalid object type : %d", OBJ_TYPE(obj));
	}
}

void *
sml_obj_alloc(unsigned int objtype, size_t payload_size)
{
	void *obj;

	ASSERT(sml_alloc_available());
	ASSERT(((unsigned int)payload_size & OBJ_SIZE_MASK) == payload_size);

	obj = sml_alloc(payload_size);
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

void *
sml_record_alloc(size_t payload_size)
{
	void *obj;
	size_t bitmap_size;

	ASSERT(sml_alloc_available());
	ASSERT(((unsigned int)payload_size & OBJ_SIZE_MASK) == payload_size);

	payload_size = ALIGNSIZE(payload_size, sizeof(void*));
	bitmap_size = OBJ_BITMAPS_LEN(payload_size) * SIZEOF_BITMAP;
	obj = sml_alloc(payload_size + bitmap_size);
	OBJ_HEADER(obj) = OBJ_HEADER_WORD(OBJTYPE_RECORD, payload_size);

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
intinf_free(void *obj)
{
	sml_intinf_clear((sml_intinf_t*)obj);
}

sml_intinf_t *
sml_intinf_new()
{
	sml_intinf_t *obj;
	obj = sml_obj_malloc(sizeof(sml_intinf_t));
	OBJ_HEADER(obj) = OBJ_HEADER_WORD(OBJTYPE_INTINF, sizeof(sml_intinf_t));
	sml_set_finalizer(obj, intinf_free);
	sml_intinf_init(obj);
	return obj;
}

SML_PRIMITIVE void *
sml_load_intinf(const char *hexsrc)
{
	sml_intinf_t *obj;
	obj = sml_intinf_new();
	sml_intinf_set_str(obj, hexsrc, 16);
	return obj;
}

void *
sml_intinf_hex(void *obj)
{
	char *buf;
	void *ret;

	ASSERT(OBJ_TYPE(obj) == OBJTYPE_INTINF);

	buf = sml_intinf_fmt((sml_intinf_t*)obj, 16);
	ret = sml_str_new(buf);
	free(buf);
	return ret;
}

void
sml_copyary(void **src, unsigned int si, void **dst, unsigned int di,
	    unsigned int len)
{
	if (src == dst) {
		/* source array and dstination array may overlap */
		while (len > 0) {
			len--;
			sml_write(dst, dst + di + len, src[si + len]);
		}
	} else {
		while (len > 0) {
			sml_write(dst, dst + di, src[si]);
			di++, si++, len--;
		}
	}
}
