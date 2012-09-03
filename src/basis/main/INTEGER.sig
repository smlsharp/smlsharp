include "General.smi"
include "Int.smi"
include "IntInf.smi"
include "StringCvt.smi"

signature INTEGER =
sig
  eqtype int
  val toLarge : int -> LargeInt.int
  val fromLarge : LargeInt.int -> int
  val toInt : int -> SMLSharp.Int.int
  val fromInt : SMLSharp.Int.int -> int
  val precision : SMLSharp.Int.int option
  val minInt : int option
  val maxInt : int option
  val + : int * int -> int
  val - : int * int -> int
  val * : int * int -> int
  val div : int * int -> int
  val mod : int * int -> int
  val quot : int * int -> int
  val rem : int * int -> int
  val compare : int * int -> order
  val < : int * int -> bool
  val <= : int * int -> bool
  val > : int * int -> bool
  val >= : int * int -> bool
  val ~ : int -> int
  val abs : int -> int
  val min : int * int -> int
  val max : int * int -> int
  val sign : int -> SMLSharp.Int.int
  val sameSign : int * int -> bool
  val fmt : StringCvt.radix -> int -> string
  val toString : int -> string
  val scan : StringCvt.radix
             -> (char, 'a) StringCvt.reader
             -> (int, 'a) StringCvt.reader
  val fromString : string -> int option
end
