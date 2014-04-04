(**
 * IntInf, LargeInt
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infix 7 * / div mod
infix 6 + -
infixr 5 ::
infix 4 = <> > >= < <=
structure Int = SMLSharp_Builtin.Int
structure Word = SMLSharp_Builtin.Word

val minInt = ~0x80000000   (* 32 bit *)
val maxInt = 0x7fffffff    (* 32 bit *)

structure IntInf =
struct

  type int = SMLSharp_Builtin.IntInf.int

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
      : __attribute__((pure,no_callback)) (int, int) -> Int.int
  val toInt_unsafe =
      _import "prim_IntInf_toInt"
      : __attribute__((pure,no_callback)) int -> Int.int
  val fromInt =
      _import "prim_IntInf_fromInt"
      : __attribute__((pure,no_callback,alloc)) Int.int -> int
  val quot_unsafe =
      _import "prim_IntInf_quot"
      : __attribute__((pure,no_callback,alloc)) (int, int) -> int
  val rem_unsafe =
      _import "prim_IntInf_rem"
      : __attribute__((pure,no_callback,alloc)) (int, int) -> int
  val pow_unsafe =
      _import "prim_IntInf_pow"
      : __attribute__((pure,no_callback,alloc)) (int, Int.int) -> int
  val log2_unsafe =
      _import "prim_IntInf_log2"
      : __attribute__((pure,no_callback)) int -> Int.int
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
        0 => General.EQUAL
      | n => if Int.gt (n, 0) then General.GREATER else General.LESS

  fun op <= (x, y) = Int.lteq (cmp (x, y), 0)
  fun op < (x, y) = Int.lt (cmp (x, y), 0)
  fun op >= (x, y) = Int.gteq (cmp (x, y), 0)
  fun op > (x, y) = Int.gt (cmp (x, y), 0)

  fun toLarge n = n : int
  fun fromLarge n = n : int

  fun toInt int =
      if int < fromInt minInt orelse fromInt maxInt < int
      then raise Overflow
      else toInt_unsafe int

  val precision : Int.int option = NONE
  val minInt : int option = NONE
  val maxInt : int option = NONE

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
      if Int.gt (y, 0)
      then pow_unsafe (x, y)
      else if y = 0 then 1
      else if x = 0 then raise Div
      else if x = 1 then 1
      else if x = ~1
      then if Word.andb (Word.fromInt y, 0w1) = 0w0 then 1 else ~1
      else 0

  fun log2 x =
      if x <= 0 then raise Domain else log2_unsafe x

  fun << (x, 0w0) = x
    | << (x, width) = << (x + x, Word.sub (width, 0w1))
  fun ~>> (x, 0w0) = x
    | ~>> (x, width) = ~>> (quot_unsafe (x, 2), Word.sub (width, 0w1))

  fun min (x, y) = if x < y then x else y
  fun max (x, y) = if x < y then y else x
  fun sign num = if num < 0 then ~1 else if num = 0 then 0 else 1
  fun sameSign (x, y) = (sign x) = (sign y)

  fun fmt radix n =
      let
        val r = fromInt (SMLSharp_ScanChar.radixToInt radix)
        fun loop (n, z) =
            if n <= 0 then z
            else let val m = toInt_unsafe (mod_unsafe (n, r))
                     val n = div_unsafe (n, r)
                 in loop (n, SMLSharp_ScanChar.intToDigit m :: z)
                 end
      in
        if n = 0 then "0"
        else if n < 0 then String.implode (#"~" :: loop (~n, nil))
        else String.implode (loop (n, nil))
      end

  fun toString n =
      fmt StringCvt.DEC n

  fun scan radix (getc : (char, 'a) StringCvt.reader) strm =
      case SMLSharp_ScanChar.scanInt radix getc strm of
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

structure LargeInt = IntInf
