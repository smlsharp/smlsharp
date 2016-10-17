(**
 * Word, LargeWord
 * @author SASAKI Tomohiro
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2014, Tohoku University.
 *)

infix 7 * / div mod
infix 6 + -
infixr 5 ::
infix 4 = <> > >= < <=
structure Word64 = SMLSharp_Builtin.Word64

structure Word64 =
struct

  type word = Word64.word
  val wordSize = 64  (* 64-bit unsigned integer *)

  fun toLarge x = x : word
  fun toLargeX x = x : word
  val toLargeWord = toLarge
  val toLargeWordX = toLargeX
  fun fromLarge x = x : word
  val fromLargeWord = fromLarge

  val toLargeInt =
      _import "prim_IntInf_fromWord64"
      : __attribute__((unsafe,pure,fast,gc)) word -> IntInf.int

  val intInf_fromInt64 =
      _import "prim_IntInf_fromInt64"
      : __attribute__((unsafe,pure,fast,gc)) Int64.int -> IntInf.int

  fun toLargeIntX x = intInf_fromInt64 (Word64.toInt64X x)

  val fromLargeInt =
      _import "prim_IntInf_toWord64"
      : __attribute__((pure,fast)) IntInf.int -> word

  val toInt = Word64.toInt32
  val toIntX = Word64.toInt32X
  val fromInt = Word64.fromInt32
  val andb = Word64.andb
  val orb = Word64.orb
  val xorb = Word64.xorb
  val notb = Word64.notb
  val << = Word64.lshift
  val >> = Word64.rshift
  val ~>> = Word64.arshift
  val op + = Word64.add
  val op - = Word64.sub
  val op * = Word64.mul
  val op div = Word64.div
  val op mod = Word64.mod
  val op < = Word64.lt
  val op <= = Word64.lteq
  val op > = Word64.gt
  val op >= = Word64.gteq
  val ~ = Word64.neg

  fun compare (x, y) =
      if x = y then General.EQUAL
      else if x < y then General.LESS
      else General.GREATER

  fun min (x, y) = if x < y then x else y
  fun max (x, y) = if x > y then x else y

  fun fmt radix n =
      let
        val r = fromInt (SMLSharp_ScanChar.radixToInt radix)
        fun loop (n, z) =
            if n = 0w0 then String.implode z
            else let val q = n div r
                     val r = toInt (n mod r)
                 in loop (q, SMLSharp_ScanChar.intToDigit r :: z)
                 end
      in
        if n = 0w0 then "0" else loop (n, nil)
      end

  fun scan radix (getc : (char, 'a) StringCvt.reader) strm =
      case SMLSharp_ScanChar.scanWord radix getc strm of
        NONE => NONE
      | SOME ({radix=r, digits}, strm) =>
        let
          fun loop (z, nil) = SOME (z, strm)
            | loop (z, h::t) =
              if (case radix of
                    StringCvt.BIN => z >= 0wx8000000000000000
                  | StringCvt.OCT => z >= 0wx2000000000000000
                  | StringCvt.DEC => z >= 0wx199999999999999a
                  | StringCvt.HEX => z >= 0wx1000000000000000)
              then raise Overflow
              else if fromInt h > notb (z * fromInt r) then raise Overflow
              else loop (z * fromInt r + fromInt h, t)
        in
          loop (0w0, digits)
        end

  fun toString w =
      fmt StringCvt.HEX w

  fun fromString s =
      StringCvt.scanString (scan StringCvt.HEX) s

end

structure LargeWord = Word64
