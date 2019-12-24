type i = int
type i8 = int8
type i16 = int16
type i32 = int32
type i64 = int64
type iInf = intInf

val i : i = 1 : int
val i8 = 0x7F : int8
val i16 : i16 = 0x7FFF : int16
val i32 : i32 = 0x7FFFFFFF : int32
val i64 : int64 = 0x7FFFFFFFFFFFFFFF : int64
val iInf : iInf = 0x8FFFFFFFFFFFFFFF : intInf

type w = word
type w8 = word8
type w16 = word16
type w32 = word32
type w64 = word64

val w : w = 0w1 : word
val w8 : w8 = 0wxFF : word8
val w16 : w16 = 0wxFFFF : word16
val w32 : w32 = 0wxFFFFFFFF : word32
val w64 : w64 = 0wxFFFFFFFFFFFFFFFF : word64

type r = real
type r32 = real32
type c = char
type s = string
type b = bool
type u = unit

val r : r = 0.1 : real
val r32 : r32  = 0.2 : real32
val c : c = #"A"
val s : s = "ABC"
val b : b = true
val u : u = ()

type t2 = int
