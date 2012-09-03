(* int31.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * The following structures must be without signatures so that inlining 
 * can take place: Bits, Vector, Array, RealArray, Int, Real
 *
 *)

structure Int31Imp : INTEGER =
  struct
    structure I31 = InlineT.Int31
    structure I32 = InlineT.Int32

    exception Div = Assembly.Div
    exception Overflow = Assembly.Overflow

    type int = int

    val precision = SOME 31
    val minIntVal = ~1073741824
    val minInt = SOME minIntVal
    val maxInt = SOME 1073741823

    val toLarge : int -> LargeInt.int = I31.toLarge
    val fromLarge : LargeInt.int -> int = I31.fromLarge
    val toInt = I31.toInt
    val fromInt = I31.fromInt

    val ~ 	: int -> int = I31.~
    val op * 	: int * int -> int  = I31.*
    val op + 	: int * int -> int  = I31.+
    val op - 	: int * int -> int  = I31.-
    val op div 	: int * int -> int  = I31.div
    val op mod 	: int * int -> int  = I31.mod
    val op quot : int * int -> int  = I31.quot
    val op rem 	: int * int -> int  = I31.rem
    val min 	: int * int -> int  = I31.min
    val max 	: int * int -> int  = I31.max
    val abs 	: int -> int = I31.abs

    fun sign 0 = 0
      | sign i = if I31.<(i, 0) then ~1 else 1
    fun sameSign (i, j) = (I31.andb(I31.xorb(i, j), minIntVal) = 0)

    fun compare (i, j) =
	  if (I31.<(i, j)) then General.LESS
	  else if (I31.>(i, j)) then General.GREATER
	  else General.EQUAL
    val op > 	: int * int -> bool = I31.>
    val op >= 	: int * int -> bool = I31.>=
    val op < 	: int * int -> bool = I31.<
    val op <= 	: int * int -> bool = I31.<=

    fun fmt radix = (NumFormat.fmtInt radix) o Int32Imp.fromInt

    fun scan radix = let
      val scanLarge = NumScan.scanInt radix
      fun f getc cs = 
	(case scanLarge getc cs
	  of NONE => NONE
	   | SOME(i, cs') => 
	     if I32.>(i, 0x3fffffff) orelse I32.<(i, ~0x40000000) then
	       raise Overflow
	     else
	       SOME(Int32Imp.toInt i, cs')
	(*esac*))
    in f
    end
(*
    val scan = NumScan.scanInt
*)

    val toString = fmt StringCvt.DEC
    val fromString = PreBasis.scanString (scan StringCvt.DEC)

  end  (* structure Int31 *)

