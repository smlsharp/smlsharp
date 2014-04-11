/*
 * object.h - SML# heap object format
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 */
#ifndef SMLSHARP__OBJECT_H__
#define SMLSHARP__OBJECT_H__

#include <limits.h>

/*
 * size of a bitmap word in heap objects and stack frames.
 */
#define SIZEOF_BITMAP     sizeof(unsigned int)
#define BITMAP_NUM_BITS   (SIZEOF_BITMAP * CHAR_BIT)

#define BITMAP_BIT(bitmaps, index) \
	(((bitmaps)[(index) / BITMAP_NUM_BITS] >> ((index) % BITMAP_NUM_BITS)) \
	 & 0x1)

#define TAG_UNBOXED  0
#define TAG_BOXED    1

#define BITMAP_WORD(offset) \
	((unsigned int)(1U << ((offset) / sizeof(void*))))

/*
 * Object format:
 *
 *  +------+-----------------------------------+---------------+
 *  |header|            payload                |     bitmap    |
 *--+------+-----------------------------------+---------------+--> addr
 *         ^
 *         |
 *       objptr
 *
 * header (unsigned int) :
 *   Header of the object. See below.
 * objptr (void*) :
 *   The pointer indicating the object.
 *   This pointer is always aligned for arbitrary type.
 * payload :
 *   Payload data of the object.
 *   Payload may be either
 *   - arbitrary data,
 *   - array of heap object pointers,
 *   - arbitrary data with bitmap, or
 *   - intinf.
 * bitmap (unsigned int[]) :
 *   bitmap indicating the position of pointers in payload.
 *   (exists only if header.type == OBJTYPE_RECORD)
 *
 * Heap object header:
 *
 * Heap object header is an "unsigned int" value placed at
 * (objptr - sizeof(unsigned int)).
 * we assume that sizeof(unsigned int) >= 4.
 *
 *  MSB                                           LSB
 *  +--------+------+-------------------------------+
 *  |  type  |  gc  |           size                |
 *  +--------+------+-------------------------------+
 *   31    28 27  26 25                            0
 *
 *                          equality        pointer_detection
 * OBJTYPE_UNBOXED_VECTOR   obj_equal       no pointer
 * OBJTYPE_BOXED_VECTOR     obj_equal       pointer array
 * OBJTYPE_UNBOXED_ARRAY    pointer_equal   no pointer
 * OBJTYPE_BOXED_ARRAY      pointer_equal   pointer array
 * OBJTYPE_RECORD           obj_equal       bitmap
 * OBJTYPE_INTINF           intinf_equal    no pointer
 *
 * gc: Flags for garbage collector.
 *     Allocator must be set 0 to these bits.
 *
 * size: The size of payload part of the object.
 */

#define OBJ_HEADER_SIZE  sizeof(unsigned int)

#define OBJ_TYPE_MASK    (~0U << 28)
#define OBJ_GC1_MASK     (1U << 26)
#define OBJ_GC2_MASK     (1U << 27)
#define OBJ_SIZE_MASK    (~(OBJ_TYPE_MASK | OBJ_GC1_MASK | OBJ_GC2_MASK))

#define OBJTYPE_UNBOXED         (0U << 28)
#define OBJTYPE_BOXED           (1U << 28)
#define OBJTYPE_VECTOR          (0x0U << 29)
#define OBJTYPE_ARRAY           (0x1U << 29)

#define OBJTYPE_UNBOXED_VECTOR  (OBJTYPE_VECTOR | OBJTYPE_UNBOXED)
#define OBJTYPE_BOXED_VECTOR    (OBJTYPE_VECTOR | OBJTYPE_BOXED)
#define OBJTYPE_UNBOXED_ARRAY   (OBJTYPE_ARRAY | OBJTYPE_UNBOXED)
#define OBJTYPE_BOXED_ARRAY     (OBJTYPE_ARRAY | OBJTYPE_BOXED)
#define OBJTYPE_RECORD          ((0x2U << 29) | OBJTYPE_BOXED)
#define OBJTYPE_INTINF          ((0x3U << 29) | OBJTYPE_UNBOXED)

#define OBJ_DUMMY_HEADER   0  /* valid header for dummy object */

#define OBJ_HEADER_WORD(objtype, size) \
	((unsigned int)(objtype) | (unsigned int)(size))

#define OBJ_HEADER(obj)  (*(unsigned int*)((char*)(obj) - sizeof(unsigned int)))
#define OBJ_TYPE(obj)    (OBJ_HEADER(obj) & OBJ_TYPE_MASK)
#define OBJ_SIZE(obj)    (OBJ_HEADER(obj) & OBJ_SIZE_MASK)
#define OBJ_GC1(obj)     (OBJ_HEADER(obj) & OBJ_GC1_MASK)
#define OBJ_GC2(obj)     (OBJ_HEADER(obj) & OBJ_GC2_MASK)
#define OBJ_BITMAP(obj)  ((unsigned int*)((char*)(obj) + OBJ_SIZE(obj)))

/* note that object has bitmap only when OBJ_TYPE == OBJTYPE_RECORD. */
#define OBJ_BITMAPS_LEN(payload_size) \
	(((payload_size) / sizeof(void*) + BITMAP_NUM_BITS - 1) \
	 / BITMAP_NUM_BITS)
#define OBJ_NUM_BITMAPS(obj) OBJ_BITMAPS_LEN(OBJ_SIZE(obj))

#define OBJ_TOTAL_SIZE(obj) \
	(OBJ_HEADER_SIZE + \
	 OBJ_SIZE(obj) + (OBJ_TYPE(obj) == OBJTYPE_RECORD \
			  ? OBJ_NUM_BITMAPS(obj) * SIZEOF_BITMAP : 0))

/* payload of string object includes a sentinel ('\0') */
#define OBJ_STR_SIZE(obj)  ((size_t)(OBJ_SIZE(obj) - 1))

#endif /* SMLSHARP__OBJECT_H__ */
