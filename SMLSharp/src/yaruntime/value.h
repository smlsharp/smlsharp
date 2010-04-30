/*
 * value.h
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: value.h,v 1.7 2010/01/05 04:56:55 katsu Exp $
 */
#ifndef SMLSHARP__VALUE_H__
#define SMLSHARP__VALUE_H__

#include "cdecl.h"

/*
 * types for unboxed runtime values.
 */

/* assumption: size of pointer */
#if SIZEOF_VOIDP == 4
#define POINTER_SIZE 32
#elif SIZEOF_VOIDP == 8
#define POINTER_SIZE 64
#else
#error "required either sizeof(void*) == 4 or sizeof(void*) == 8"
#endif /* SIZEOF_VOIDP */

/* assumption: float is IEEE754 single-precision floating point number */
#if SIZEOF_FLOAT != 4
#error "required sizeof(float) == 4"
#endif

/* assumption: double is IEEE754 double-precision floating point number */
#if SIZEOF_DOUBLE != 8
#error "required sizeof(double) == 8"
#endif

/* assumption: long double is smaller than 16 bytes. */
#if SIZEOF_LONGDOUBLE > 16
#error "required sizeof(long double) <= 16"
#endif

typedef uint8_t ml_uchar_t;
typedef uint16_t ml_ushort_t;
typedef uint32_t ml_uint_t;
typedef uint64_t ml_ulong_t;
typedef int32_t ml_int_t;
typedef int64_t ml_long_t;
/* for single precision floating-point, float is used. */
/* for double precision floating-point, double is used. */
/* for long double precision floating-point, long double is used. */
/* for heap object, void * is used. */

#define ffi_type_ml_char_t     ffi_type_sint8
#define ffi_type_ml_uchar_t    ffi_type_uint8
#define ffi_type_ml_short_t    ffi_type_sint16
#define ffi_type_ml_ushort_t   ffi_type_uint16
#define ffi_type_ml_int_t      ffi_type_sint32
#define ffi_type_ml_uint_t     ffi_type_uint32
#define ffi_type_ml_long_t     ffi_type_sint64
#define ffi_type_ml_ulong_t    ffi_type_uint64

/*
 * size of a generic slot in stack frames.
 */
/* FIXME: double word for the time being */
#define SIZEOF_GENERIC    sizeof(uint64_t)

/*
 * size of a bitmap word in heap objects and stack frames.
 */
#define SIZEOF_BITMAP     sizeof(ml_uint_t)
#define BITMAP_NUM_BITS   32U  /* SIZEOF_BITMAP * CHAR_BIT */

#define BITMAP_BIT(bitmaps, index) \
	(((bitmaps)[(index) / BITMAP_NUM_BITS] >> ((index) % BITMAP_NUM_BITS)) \
	 & 0x1)

#define TAG_UNBOXED      0
#define TAG_BOXED        1

/*
 * Heap object header:
 *
 *  MSB                                           LSB
 *  +--------+------+-------------------------------+
 *  |  type  |  gc  |           size                |
 *  +--------+------+-------------------------------+
 *   31    28 27  26 25                            0
 */

#define OBJ_HEADER_SIZE  sizeof(ml_uint_t)

#define OBJ_TYPE_MASK    (~(ml_uint_t)0U << 28)
#define OBJ_GC1_MASK     ((ml_uint_t)1U << 26)
#define OBJ_GC2_MASK     ((ml_uint_t)1U << 27)
#define OBJ_SIZE_MASK    (~(OBJ_TYPE_MASK | OBJ_GC1_MASK | OBJ_GC2_MASK))

#define OBJTYPE_UNBOXED_VECTOR  ((ml_uint_t)0x0U << 29 | (ml_uint_t)0U << 28)
#define OBJTYPE_BOXED_VECTOR    ((ml_uint_t)0x0U << 29 | (ml_uint_t)1U << 28)
#define OBJTYPE_UNBOXED_ARRAY   ((ml_uint_t)0x1U << 29 | (ml_uint_t)0U << 28)
#define OBJTYPE_BOXED_ARRAY     ((ml_uint_t)0x1U << 29 | (ml_uint_t)1U << 28)
#define OBJTYPE_RECORD          ((ml_uint_t)0x2U << 29)
#define OBJTYPE_INTINF          ((ml_uint_t)0x3U << 29)

#define OBJ_HEADER(obj)      (*(ml_uint_t*)((char*)(obj) - sizeof(ml_uint_t)))
#define OBJ_TYPE(obj)        (OBJ_HEADER(obj) & OBJ_TYPE_MASK)
#define OBJ_SIZE(obj)        (OBJ_HEADER(obj) & OBJ_SIZE_MASK)
#define OBJ_GC1(obj)         (OBJ_HEADER(obj) & OBJ_GC1_MASK)
#define OBJ_GC2(obj)         (OBJ_HEADER(obj) & OBJ_GC2_MASK)
#define OBJ_BITMAP(obj)      ((ml_uint_t*)((char*)(obj) + OBJ_SIZE(obj)))

/* note that object has bitmap only when OBJ_TYPE == OBJTYPE_RECORD. */
#define OBJ_BITMAPS_LEN(payload_size) \
	(((payload_size) / sizeof(void*) + BITMAP_NUM_BITS - 1) \
	 / BITMAP_NUM_BITS)
#define OBJ_NUM_BITMAPS(obj) OBJ_BITMAPS_LEN(OBJ_SIZE(obj))

#define OBJ_TOTAL_SIZE(obj) \
	(OBJ_HEADER_SIZE + \
	 OBJ_SIZE(obj) + (OBJ_TYPE(obj) == OBJTYPE_RECORD \
			  ? OBJ_NUM_BITMAPS(obj) * SIZEOF_BITMAP : 0))


typedef void *ml_intinf_t;
int obj_equal(void *obj1, void *obj2);
void *obj_dup(void *obj);
void obj_enum_pointers(void *obj, void (*)(void **));
char *string_alloc(size_t len);
char *string_alloc_with(const char *str, size_t len);
char *bytearray_alloc(size_t len);
size_t string_size(void *obj);


/*
 * immutable empty record constant
 */
extern const ml_uint_t empty_object__[1];
/* empty_object__[0] is object header. */
#define empty_object ((void*)&empty_object__[1])


#endif /* SMLSHARP__VALUE_H__ */
