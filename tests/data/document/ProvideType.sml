type i = int
type i8 = int8
type i16 = int16
type i32 = int32
type i64 = int64
type iInf = intInf

type w = word
type w8 = word8
type w16 = word16
type w32 = word32
type w64 = word64

type r = real
type r32 = real32
type c = char
type s = string
type b = bool

type ref1 = int ref
type tuple1 = int * string
type tuple2 = {1:int, 2:string}
type record1 = {A:int, B:string}
type list1 = int list
type 'a list2 = 'a list

type 'a f1 = 'a -> 'a
type f2 = int -> int
type f3 = word -> word
type ('a, 'b) f4 = 'a -> 'b

type t1 = int
type t2 = t1
