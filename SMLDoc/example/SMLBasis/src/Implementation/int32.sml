(* int32.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

structure Int32Imp : INTEGER =
  struct
    structure I32 = InlineT.Int32

    type int = Int32.int

    val precision = SOME 32

    val minIntVal : int = ~2147483648
    val minInt : int option = SOME minIntVal
    val maxInt : int option = SOME 2147483647

    val op *    : int * int -> int  = I32.*
    val op quot : int * int -> int  = I32.quot
    val op rem  : int * int -> int  = I32.rem
    val op div  : int * int -> int  = I32.div
    val op mod  : int * int -> int  = I32.mod
    val op +    : int * int -> int  = I32.+
    val op -    : int * int -> int  = I32.-
    val ~       : int -> int = I32.~
    val op <    : int * int -> bool = I32.<
    val op <=   : int * int -> bool = I32.<=
    val op >    : int * int -> bool = I32.>
    val op >=   : int * int -> bool = I32.>=
    val op =    : int * int -> bool = I32.=
    val op <>   : int * int -> bool = I32.<>
    val min     : int * int -> int = I32.min
    val max     : int * int -> int = I32.max
    val abs     : int -> int = I32.abs

    fun sign(0) = 0
      | sign i = if I32.<(i, 0) then ~1 else 1

    fun sameSign(i, j) = I32.andb(I32.xorb(i, j), minIntVal) = 0

    fun compare (i:int, j:int) =
	  if (I32.<(i, j)) then General.LESS
	  else if (I32.>(i, j)) then General.GREATER
	  else General.EQUAL

    val scan = NumScan.scanInt
    val fmt = NumFormat.fmtInt
    val toString = fmt StringCvt.DEC
    val fromString = PreBasis.scanString (scan StringCvt.DEC) 

    val toInt : int -> Int.int = I32.toInt
    val fromInt : Int.int -> int = I32.fromInt
    val toLarge : int -> LargeInt.int = I32.toLarge
    val fromLarge : LargeInt.int -> int = I32.fromLarge
  end


