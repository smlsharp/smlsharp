(**
 * Integer related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *
 * @author Atsushi Ohori (refactored from IntStructure)
 * @copyright 2010, 2011, Tohoku University.
 *)

(*
  2012-1-6 Ohori:
  I rewote this from IntStructre.
  This is of of the fundamental structures that must to be defined directly.
*)

_interface "Word.smi"

structure Word : sig
    (* same as WORD *)
    type word = SMLSharp.Word.word
    val wordSize : int
    val toLarge : word -> word
    val toLargeX : word -> word
    val toLargeWord : word -> word
    val toLargeWordX : word -> word
    val fromLarge : word -> word
    val fromLargeWord : word -> word
    val toLargeInt : word -> IntInf.int
    val toLargeIntX : word -> IntInf.int
    val fromLargeInt : IntInf.int -> word
    val toInt : word -> int
    val toIntX : word -> int
    val fromInt : int -> word
    val andb : word * word -> word
    val orb : word * word -> word
    val xorb : word * word -> word
    val notb : word -> word
    val << : word * SMLSharp.Word.word -> word
    val >> : word * SMLSharp.Word.word -> word
    val ~>> : word * SMLSharp.Word.word -> word
    val + : word * word -> word
    val - : word * word -> word
    val * : word * word -> word
    val div : word * word -> word
    val mod : word * word -> word
    val compare : word * word -> order
    val < : word * word -> bool
    val <= : word * word -> bool
    val > : word * word -> bool
    val >= : word * word -> bool
    val ~ : word -> word
    val min : word * word -> word
    val max : word * word -> word
    val fmt : StringCvt.radix -> word -> string
    val toString : word -> string
    val scan : StringCvt.radix
               -> (char, 'a) StringCvt.reader
               -> (word, 'a) StringCvt.reader
    val fromString : string -> word option
  end =
struct
local
  infix 7 * / div mod
  infix 6 + -
  infixr 5 ::
  infix 4 = <> > >= < <=
in
  type word = SMLSharp.Word.word
  val wordSize = 32  (* 32-bit unsigned integer *)
  fun toLarge x = x : word
  fun toLargeX x = x : word
  val toLargeWord = toLarge
  val toLargeWordX = toLargeX
  fun fromLarge x = x : word
  val fromLargeWord = fromLarge
  val toLargeInt = IntInf.fromWord
  fun toLargeIntX x = IntInf.fromInt (SMLSharp.Word.toIntX x)
  val fromLargeInt = IntInf.toWord

  fun toInt w =
      let val n = SMLSharp.Word.toIntX w
      in if SMLSharp.Int.lt (n, 0) then raise Overflow else n
      end

  val toIntX = SMLSharp.Word.toIntX
  val fromInt = SMLSharp.Word.fromInt
  val andb = SMLSharp.Word.andb
  val orb = SMLSharp.Word.orb
  val xorb = SMLSharp.Word.xorb
  val notb = SMLSharp.Word.notb
  val << = SMLSharp.Word.lshift
  val >> = SMLSharp.Word.rshift
  val ~>> = SMLSharp.Word.arshift
  val op + = SMLSharp.Word.add
  val op - = SMLSharp.Word.sub
  val op * = SMLSharp.Word.mul
  val op div = SMLSharp.Word.div
  val op mod = SMLSharp.Word.mod
  val op < = SMLSharp.Word.lt
  val op <= = SMLSharp.Word.lteq
  val op > = SMLSharp.Word.gt
  val op >= = SMLSharp.Word.gteq
  val op ~ = SMLSharp.Word.neg

  fun compare (x, y) =
      if x = y then EQUAL else if x < y then LESS else GREATER

  fun min (x, y) = if x < y then x else y
  fun max (x, y) = if x > y then x else y

  fun fmt radix n =
      let
        val r = SMLSharp.Word.fromInt (SMLSharpScanChar.radixToInt radix)
        fun loop (n, z) =
            if n = 0w0 then implode z
            else let val (n, m) = (n div r, toInt (n mod r))
                 in loop (n, SMLSharpScanChar.intToDigit m :: z)
                 end
      in
        if n = 0w0 then "0" else loop (n, nil)
      end

  fun scan radix getc strm =
      case SMLSharpScanChar.scanWord radix getc strm of
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
              else loop (z * fromInt r + fromInt h, t)
        in
          loop (0w0, digits)
        end
  fun toString w =
      fmt StringCvt.HEX w

  fun fromString s =
      StringCvt.scanString (scan StringCvt.HEX) s
end
end (* Word *)

structure LargeWord = Word
structure Word32 = Word
