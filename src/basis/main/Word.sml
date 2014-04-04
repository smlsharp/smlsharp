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
structure Word = SMLSharp_Builtin.Word

structure Word =
struct

  type word = word
  val wordSize = 32  (* 32-bit unsigned integer *)

  fun toLarge x = x : word
  fun toLargeX x = x : word
  val toLargeWord = toLarge
  val toLargeWordX = toLargeX
  fun fromLarge x = x : word
  val fromLargeWord = fromLarge

  val toLargeInt =
      _import "prim_IntInf_fromWord"
      : __attribute__((pure,no_callback,alloc)) word -> IntInf.int

  fun toLargeIntX x =
      IntInf.fromInt (Word.toIntX x)

  val fromLargeInt =
      _import "prim_IntInf_toWord"
      : __attribute__((pure,no_callback)) IntInf.int -> word

  val toInt = Word.toInt
  val toIntX = Word.toIntX
  val fromInt = Word.fromInt
  val andb = Word.andb
  val orb = Word.orb
  val xorb = Word.xorb
  val notb = Word.notb
  val << = Word.lshift
  val >> = Word.rshift
  val ~>> = Word.arshift
  val op + = Word.add
  val op - = Word.sub
  val op * = Word.mul
  val op div = Word.div
  val op mod = Word.mod
  val op < = Word.lt
  val op <= = Word.lteq
  val op > = Word.gt
  val op >= = Word.gteq
  val ~ = Word.neg

  fun compare (x, y) =
      if x = y then General.EQUAL
      else if x < y then General.LESS
      else General.GREATER

  fun min (x, y) = if x < y then x else y
  fun max (x, y) = if x > y then x else y

  fun fmt radix n =
      let
        val r = Word.fromInt (SMLSharp_ScanChar.radixToInt radix)
        fun loop (n, z) =
            if n = 0w0 then String.implode z
            else let val q = n div r
                     val r = Word.toIntX (n mod r)
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

structure LargeWord = Word
structure Word32 = Word
