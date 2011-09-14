(**
 * Int structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: IntInf.sml,v 1.4 2007/08/07 14:04:29 kiyoshiy Exp $
 *)
structure IntInf =
struct
  (*
    IntInf.int
    IntInf._format_int
  *)
  open IntInf

  (***************************************************************************)

  structure SC = StringCvt

  (***************************************************************************)

  fun toLarge int = int

  fun fromLarge largeInt = largeInt

  fun toInt int =
      if int < ~0x80000000 orelse 0x7FFFFFFF < int
      then raise General.Overflow
      else SMLSharp.Runtime.LargeInt_toInt int

  fun fromInt int = SMLSharp.Runtime.LargeInt_fromInt int

  val precision = NONE

  val minInt = NONE
  val maxInt = NONE

  val ~ = fn (num : int) => ~ num

  val op * = fn ((left : int), right) => left * right

  val op div = fn ((left : int), right) =>
                  if right = 0
                  then raise General.Div
                  else left div right

  val op mod = fn ((left : int), right) =>
                  if right = 0
                  then raise General.Div
                  else left mod right

  val quot = fn ((left : int), right) =>
                if right = 0
                then raise General.Div
                else SMLSharp.Runtime.quotLargeInt (left, right)

  val rem = fn ((left : int), right) =>
               if right = 0
               then raise General.Div
               else SMLSharp.Runtime.remLargeInt (left, right)

  fun compare ((left : int), right) =
      if left < right
      then General.LESS
      else if left = right then General.EQUAL else General.GREATER

  fun abs num = if (num : int) < 0 then ~ num else num

  fun min ((left : int), right) = if left < right then left else right

  fun max ((left : int), right) = if left > right then left else right

  fun sign num = if (num : int) < 0 then ~1 else if num = 0 then 0 else 1

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
          #"0" => (0 : int)
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
          SC.BIN => (2 : int) | SC.OCT => 8 | SC.DEC => 10 | SC.HEX => 16
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
  fun fmt radix (num : int) =
      let
        val radixNum = numOfRadix radix
        fun loop 0 chars = implode chars
          | loop (n:int) chars =
            loop (n div radixNum)
                 (charOfNum (toInt (n mod radixNum)) :: chars)
      in
        if 0 = num
        then "0"
        else
          if num < 0
          then "~" ^ (loop (abs num) [])
          else loop num []
      end

  fun toString num = fmt SC.DEC num

  local
    structure PC = ParserComb
    fun accumIntList base ints =
        foldl (fn (int, accum) => accum * base + int) 0 ints
    fun scanSign reader stream = 
        PC.or(PC.seqWith #2 (PC.char #"+", PC.result (1 : int)),
              PC.or (PC.seqWith #2 (PC.char #"~", PC.result ~1),
                     PC.or(PC.seqWith #2 (PC.char #"-", PC.result ~1),
                           PC.result 1)))
             reader
             stream
    fun scanNumbers radix reader stream =
        let
          val (isNumberChar, charToNumber, base) =
              (isNumChar radix, numOfChar, numOfRadix radix)
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
            PC.seqWith (fn (x, y) => x * y) (scanSign, scanBody) reader stream
      in
        scanner reader (StringCvt.skipWS reader stream)
      end
  end
  end

  fun fromString string = (SC.scanString (scan SC.DEC)) string
(* The following eta equivalent form causes an internal error of the SML/NJ.
  val fromString = (SC.scanString (scan SC.DEC)) : string -> int option
*)

  fun op < (left : int, right : int) =
      case compare (left, right) of General.LESS => true | _ => false
  fun op <= (left : int, right : int) =
      case compare (left, right) of General.GREATER => false | _ => true
  fun op > x = not (op <= x)
  fun op >= x = not (op < x)

  (* ToDo : div and mod can be combined to one primitive. *)
  fun divMod (x, y) = (x div y, x mod y)

  (* ToDo : div and mod can be combined to one primitive. *)
  fun quotRem (x, y) = (quot (x, y), rem (x, y))

  fun pow (x, y) =
      if Int.< (0, y)
      then SMLSharp.Runtime.LargeInt_pow (x, y)
      else if 0 = y then 1
      else
        if x = 0 then raise Div
        else if abs x = 1 then (if (0 = Int.mod (y, 2)) then 1 else ~1)
        else 0

  fun log2 x =
      if x <= 0
      then raise General.Domain
      else SMLSharp.Runtime.LargeInt_log2 x

  val orb = SMLSharp.Runtime.LargeInt_orb
  val xorb = SMLSharp.Runtime.LargeInt_xorb
  val andb = SMLSharp.Runtime.LargeInt_andb
  val notb = SMLSharp.Runtime.LargeInt_notb

  fun << (x, 0w0) = x
    | << (x, width) = << (x * 2, width - 0w1)
  fun ~>> (x, 0w0) = x
    | ~>> (x, width) = ~>> (x div 2, width - 0w1)

  val op + = fn ((left : int), right) => left + right

  val op - = fn ((left : int), right) => left - right

  (***************************************************************************)

end
