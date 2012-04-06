(**
 * IntInf and its alias LargeInt 
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *
 * @author Atsushi Ohori (refactored from IntStructure)
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "IntInf.smi"

structure IntInf : sig
  (* same as INTEGER except IntInf.int *)
  type int = SMLSharp.IntInf.int
  val toLarge : int -> int
  val fromLarge : int -> int
  val toInt : int -> SMLSharp.Int.int
  val fromInt : SMLSharp.Int.int -> int
  val toWord : int -> SMLSharp.Word.word
  val fromWord : SMLSharp.Word.word -> int
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

  val divMod : int * int -> int * int
  val quotRem : int * int -> int * int
  val pow : int * SMLSharp.Int.int -> int
  val log2 : int -> SMLSharp.Int.int
  val orb : int * int -> int
  val xorb : int * int -> int
  val andb : int * int -> int
  val notb : int -> int
  val << : int * SMLSharp.Word.word -> int
  val ~>> : int * SMLSharp.Word.word -> int

end =
struct
local
  infix 7 * / div mod
  infix 6 + -
  infixr 5 ::
  infix 4 = <> > >= < <=
  val minInt = ~0x80000000
  val maxInt = 0x7fffffff
in
  type int = SMLSharp.IntInf.int

  val abs =
      _import "prim_IntInf_abs"
      : __attribute__((pure,no_callback,alloc)) int -> int
  val ~ =
      _import "prim_IntInf_neg"
      : __attribute__((pure,no_callback,alloc)) int -> int
  val op - =
      _import "prim_IntInf_sub"
      : __attribute__((pure,no_callback,alloc)) (int, int) -> int
  val op + =
      _import "prim_IntInf_add"
      : __attribute__((pure,no_callback,alloc)) (int, int) -> int
  val op * =
      _import "prim_IntInf_mul"
      : __attribute__((pure,no_callback,alloc)) (int, int) -> int
  val div_unsafe =
      _import "prim_IntInf_div"
      : __attribute__((pure,no_callback,alloc)) (int, int) -> int
  val mod_unsafe =
      _import "prim_IntInf_mod"
      : __attribute__((pure,no_callback,alloc)) (int, int) -> int
  val cmp =
      _import "prim_IntInf_cmp"
      : __attribute__((pure,no_callback,alloc)) (int, int) -> SMLSharp.Int.int
  val toInt_unsafe =
      _import "prim_IntInf_toInt"
      : __attribute__((pure,no_callback)) int -> SMLSharp.Int.int
  val toWord =
      _import "prim_IntInf_toWord"
      : __attribute__((pure,no_callback)) int -> word
  val fromInt =
      _import "prim_IntInf_fromInt"
      : __attribute__((pure,no_callback,alloc)) SMLSharp.Int.int -> int
  val fromWord =
      _import "prim_IntInf_fromWord"
      : __attribute__((pure,no_callback,alloc)) word -> int
  val quot_unsafe =
      _import "prim_IntInf_quot"
      : __attribute__((pure,no_callback,alloc)) (int, int) -> int
  val rem_unsafe =
      _import "prim_IntInf_rem"
      : __attribute__((pure,no_callback,alloc)) (int, int) -> int
  val pow_unsafe =
      _import "prim_IntInf_pow"
      : __attribute__((pure,no_callback,alloc)) (int, SMLSharp.Int.int) -> int
  val log2_unsafe =
      _import "prim_IntInf_log2"
      : __attribute__((pure,no_callback)) int -> SMLSharp.Int.int
  val orb =
      _import "prim_IntInf_orb"
      : __attribute__((pure,no_callback,alloc)) (int, int) -> int
  val xorb =
      _import "prim_IntInf_xorb"
      : __attribute__((pure,no_callback,alloc)) (int, int) -> int
  val andb =
      _import "prim_IntInf_andb"
      : __attribute__((pure,no_callback,alloc)) (int, int) -> int
  val notb =
      _import "prim_IntInf_notb"
      : __attribute__((pure,no_callback,alloc)) int -> int

  fun compare (x, y) =
      case cmp (x, y) of
        0 => EQUAL
      | n => if SMLSharp.Int.gt(n, 0) then GREATER else LESS
  fun op <= (x, y) = SMLSharp.Int.lteq (cmp (x, y), 0)
  fun op < (x, y) = SMLSharp.Int.lt (cmp (x, y), 0)
  fun op >= (x, y) = SMLSharp.Int.gteq (cmp (x, y), 0)
  fun op > (x, y) = SMLSharp.Int.gt (cmp (x, y), 0)

  fun toLarge n = n : int
  fun fromLarge n = n : int

  fun toInt int =
      if int < fromInt minInt orelse fromInt maxInt < int
      then raise Overflow
      else toInt_unsafe int

  val precision = NONE
  val minInt = NONE
  val maxInt = NONE

  fun op div (x, y) =
      if y = 0 then raise Div else div_unsafe (x, y)
  fun op mod (x, y) =
      if y = 0 then raise Div else mod_unsafe (x, y)

  fun quot (x, y) =
      if y = 0
      then raise Div
      else quot_unsafe (x, y)

  fun rem (x, y) =
      if y = 0
      then raise Div
      else rem_unsafe (x, y)

  (* ToDo : div and mod can be combined to one primitive. *)
  fun divMod (x, y) = (x div y, x mod y)

  (* ToDo : div and mod can be combined to one primitive. *)
  fun quotRem (x, y) = (quot (x, y), rem (x, y))

  fun pow (x, y) =
      if SMLSharp.Int.gt (y, 0)
      then pow_unsafe (x, y)
      else if y = 0 then 1
      else if x = 0 then raise Div
      else if x = 1 then 1
      else if x = ~1 then if SMLSharp.Int.mod (y, 2) = 0 then 1 else ~1
      else 0

  fun log2 x =
      if x <= 0 then raise Domain else log2_unsafe x

  fun << (x, 0w0) = x
    | << (x, width) = << (x * 2, SMLSharp.Word.sub (width, 0w1))
  fun ~>> (x, 0w0) = x
    | ~>> (x, width) = ~>> (x div 2, SMLSharp.Word.sub (width, 0w1))

  fun min (x, y) = if x < y then x else y
  fun max (x, y) = if x < y then y else x
  fun sign num = if num < 0 then ~1 else if num = 0 then 0 else 1
  fun sameSign (x, y) = (sign x) = (sign y)

  fun fmt radix n =
      let
        val r = fromInt (SMLSharpScanChar.radixToInt radix)
        fun loop (n, z) =
            if n <= 0 then z
            else let val m = toInt_unsafe (mod_unsafe (n, r))
                     val n = div_unsafe (n, r)
                 in loop (n, SMLSharpScanChar.intToDigit m :: z)
                 end
      in
        if n = 0 then "0"
        else if n < 0 then implode (#"~" :: loop (~n, nil))
        else implode (loop (n, nil))
      end

  fun toString n =
      fmt StringCvt.DEC n

  fun scan radix getc strm =
      case SMLSharpScanChar.scanInt radix getc strm of
        NONE => NONE
      | SOME ({neg, radix, digits}, strm) =>
        let
          val radix = fromInt radix
          fun loop (z, nil) = z
            | loop (z, h::t) = loop (z * radix + fromInt h, t)
          val n = loop (0, digits)
        in
          SOME (if neg then ~n else n, strm)
        end

  fun fromString string =
      StringCvt.scanString (scan StringCvt.DEC) string

end
end (* IntInf *)

structure LargeInt = IntInf

