(**
 * Word, Word32, LargeWord
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

(* NOTE: Word assumes that integer is 32 bit *)

infix 7 * / div mod
infix 6 + -
infixr 5 ::
infix 4 = <> > >= < <=
structure Word32 = SMLSharp_Builtin.Word32

structure Word32 =
struct

  type word = word
  val wordSize = 32  (* 32-bit unsigned integer *)

  val toLarge = Word32.toWord64
  val toLargeX = SMLSharp_Builtin.Word32.toWord64X
  val toLargeWord = toLarge
  val toLargeWordX = toLargeX
  val fromLarge = SMLSharp_Builtin.Word64.toWord32
  val fromLargeWord = fromLarge

  val toLargeInt =
      _import "prim_IntInf_fromWord"
      : __attribute__((unsafe,pure,fast,gc))
        word -> IntInf.int

  fun toLargeIntX x =
      IntInf.fromInt (Word32.toInt32X x)

  val fromLargeInt =
      _import "prim_IntInf_toWord"
      : __attribute__((unsafe,pure,fast)) IntInf.int -> word

  val toInt = Word32.toInt32
  val toIntX = Word32.toInt32X
  val fromInt = Word32.fromInt32
  val andb = Word32.andb
  val orb = Word32.orb
  val xorb = Word32.xorb
  val notb = Word32.notb
  val << = Word32.lshift
  val >> = Word32.rshift
  val ~>> = Word32.arshift
  val op + = Word32.add
  val op - = Word32.sub
  val op * = Word32.mul
  val op div = Word32.div
  val op mod = Word32.mod
  val op < = Word32.lt
  val op <= = Word32.lteq
  val op > = Word32.gt
  val op >= = Word32.gteq
  val ~ = Word32.neg

  fun compare (x, y) =
      if x = y then General.EQUAL
      else if x < y then General.LESS
      else General.GREATER

  fun min (x, y) = if x < y then x else y
  fun max (x, y) = if x > y then x else y

  fun fmt radix n =
      let
        val r = Word32.fromInt32 (SMLSharp_ScanChar.radixToInt radix)
        fun loop (n, z) =
            if n = 0w0 then String.implode z
            else let val q = n div r
                     val r = Word32.toInt32X (n mod r)
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
                    StringCvt.BIN => z >= 0wx80000000
                  | StringCvt.OCT => z >= 0wx20000000
                  | StringCvt.DEC => z >= 0wx1999999a
                  | StringCvt.HEX => z >= 0wx10000000)
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

structure Word = Word32
