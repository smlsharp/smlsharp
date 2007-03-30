(* bind-largest32.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * Bindings of Int, LargeInt, Word, LargeWord and SysWord
 * structures for 32-bit implementations.
 *
 *)

structure Int : INTEGER = Int31
structure Word : WORD = Word31
structure LargeInt : INTEGER = IntInf
structure FixedInt : INTEGER = Int32
structure LargeWord : WORD = Word32
structure Real : REAL = Real64
structure LargeReal : REAL = Real64
structure SysWord : WORD = Word32
structure Position : INTEGER = Int31

