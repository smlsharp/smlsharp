(**
 * Int structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Int.sml,v 1.9 2007/02/28 13:17:16 katsu Exp $
 *)
structure Int =
struct
  open Int
  local
    val divWord = op div : word * word -> word
    val subWord = op - : word * word -> word
    val modWord = op mod : word * word -> word
  in

  (***************************************************************************)

  structure SC = StringCvt

  (***************************************************************************)

  type int = int

  (***************************************************************************)

  val precision = SOME 32

  val minInt = SOME ~0x80000000
  val maxInt = SOME 0x7FFFFFFF

  fun toLarge int = SMLSharp.Runtime.LargeInt_fromInt int

  fun fromLarge largeInt =
      if largeInt < ~0x80000000 orelse 0x7FFFFFFF < largeInt
      then raise General.Overflow
      else SMLSharp.Runtime.LargeInt_toInt largeInt

  fun toInt int = int

  fun fromInt int = int

  fun compare (left:int, right:int) =
      if left < right
      then General.LESS
      else if left = right then General.EQUAL else General.GREATER

  val ~ = ~ : int -> int

  fun abs num = if num < 0 then ~ num else num

  fun min (left:int, right:int) = if left < right then left else right

  fun max (left:int, right:int) = if left > right then left else right

  fun sign num = if num < 0 then ~1 else if num = 0 then 0 else 1

  fun sameSign (left, right) = (sign left) = (sign right)

  local
    (*
     * Following functions can be defined by using the Char structure.
     * But because the Char structure refers to this Int structure,
     * we cannot rely on it to avoid a cyclic reference.
     *)
    fun charOfNum num = 
        case num of
          0 => #"0"
        | 1 => #"1"
        | 2 => #"2"
        | 3 => #"3"
        | 4 => #"4"
        | 5 => #"5"
        | 6 => #"6"
        | 7 => #"7"
        | 8 => #"8"
        | 9 => #"9"
        | 10 => #"A"
        | 11 => #"B"
        | 12 => #"C"
        | 13 => #"D"
        | 14 => #"E"
        | 15 => #"F"
        | _ => raise Fail "bug: Int.charOfNum"
    fun numOfChar char = 
        case char of
          #"0" => 0 : IntInf.int
        | #"1" => 1
        | #"2" => 2
        | #"3" => 3
        | #"4" => 4
        | #"5" => 5
        | #"6" => 6
        | #"7" => 7
        | #"8" => 8
        | #"9" => 9
        | #"A" => 10
        | #"a" => 10
        | #"B" => 11
        | #"b" => 11
        | #"C" => 12
        | #"c" => 12
        | #"D" => 13
        | #"d" => 13
        | #"E" => 14
        | #"e" => 14
        | #"F" => 15              
        | #"f" => 15
        | _ => raise Fail "bug: Int.numOfChar"
    fun numOfRadix radix =
        case radix of
          SC.BIN => 2 | SC.OCT => 8 | SC.DEC => 10 | SC.HEX => 16
    fun isNumChar radix =
        case radix of
          SC.BIN => (fn char => char = #"0" orelse char = #"1")
        | SC.OCT => (fn char => #"0" <= char andalso char <= #"7")
        | SC.DEC => (fn char => #"0" <= char andalso char <= #"9")
        | SC.HEX =>
          (fn char =>
              (#"0" <= char andalso char <= #"9")
              orelse (#"a" <= char andalso char <= #"f")
              orelse (#"A" <= char andalso char <= #"F"))
  in
  fun fmt radix num =
      let
        val radixNum = Word.fromInt (numOfRadix radix)
        fun loop 0w0 chars = implode chars
          | loop (n:word) chars =
            loop (divWord (n, radixNum))
                 (charOfNum (Word.toIntX (modWord (n, radixNum))) :: chars)
      in
        if 0 = num
        then "0"
        else
          if num < 0
          then "~" ^ (loop (subWord (0w0,Word.fromInt num)) [])
          else loop (Word.fromInt num) []
      end

  fun toString num = fmt SC.DEC num

  local
    structure PC = ParserComb
    fun accumIntList base ints =
        foldl (fn (int, accum) => accum * base + int) 0 ints
    fun scanSign reader stream = 
        PC.or(PC.seqWith #2 (PC.char #"+", PC.result 1),
              PC.or (PC.seqWith #2 (PC.char #"~", PC.result ~1),
                     PC.or(PC.seqWith #2 (PC.char #"-", PC.result ~1),
                           PC.result 1)))
             reader
             stream
    fun scanNumbers radix reader stream =
        let
          val (isNumberChar, charToNumber, base) =
              (isNumChar radix, numOfChar, toLarge (numOfRadix radix))
        in
          PC.wrap
              (
                PC.oneOrMore(PC.wrap(PC.eatChar isNumberChar, charToNumber)),
                accumIntList base
              )
              reader
              stream
        end
    fun scanHex reader stream =
        PC.or
            (
              PC.seqWith
                  #2
                  (
                    (PC.or(PC.string "0x", PC.string "0X")),
                    scanNumbers StringCvt.HEX
                  ),
              scanNumbers StringCvt.HEX
            )
            reader stream
  in
  fun scan radix reader stream =
      let
        fun scanBody reader stream =
            (case radix of
               StringCvt.HEX => scanHex
             | _ => scanNumbers radix)
            reader
            stream
        fun scanner reader stream =
            PC.seqWith (fromLarge o op * ) (scanSign, scanBody) reader stream
      in
        scanner reader (StringCvt.skipWS reader stream)
      end
  end
  end

  fun fromString string = (SC.scanString (scan SC.DEC)) string
(* The following eta equivalent form causes an internal error of the SML/NJ.
  val fromString = (SC.scanString (scan SC.DEC)) : string -> int option
*)

  val op + = op + : int * int -> int
  val op - = op - : int * int -> int
  val op * = op * : int * int -> int
  val op div = op div : int * int -> int
  val op mod = op mod : int * int -> int
(*
  val quot = fn (left, right) => quotInt (left, right)
  val rem = fn (left, right) => remInt (left, right)
*)

  fun op < (left : int, right : int) =
      case compare (left, right) of General.LESS => true | _ => false
  fun op <= (left : int, right : int) =
      case compare (left, right) of General.GREATER => false | _ => true
  val op > = not o (op <=)
  val op >= = not o (op <)

  (***************************************************************************)

  end (* divWord, subWord, modWord *)
end;