(**
 * Word structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Word.sml,v 1.5 2007/04/02 09:42:29 katsu Exp $
 *)
structure Word =
struct

  (***************************************************************************)

  structure SC = StringCvt

  (***************************************************************************)

  type word = word

  (***************************************************************************)

  val wordSize = 32

  fun toLarge word = word

  fun toLargeX word = word

  fun fromLarge largeWord = largeWord

  val toLargeWord = toLarge

  val toLargeWordX = toLargeX

  val fromLargeWord = fromLarge

  fun toLargeInt word =
      let val largeInt = Word_toIntX word
      in if largeInt < 0 then raise Overflow else largeInt end

  fun toLargeIntX word = Word_toIntX word

  fun fromLargeInt largeInt = Word_fromInt largeInt

  fun toInt word = toLargeInt word

  fun toIntX word = toLargeIntX word

  fun fromInt int = Word_fromInt int

  val orb = fn (left, right) => Word_orb (left, right)

  val xorb = fn (left, right) => Word_xorb (left, right)

  val andb = fn (left, right) => Word_andb (left, right)

  val notb = fn word => Word_notb word

  val op << = fn (left, right) => Word_leftShift (left, right)

  val op >> = fn (left, right) => Word_logicalRightShift (left, right)

  val op ~>> = fn (left, right) => Word_arithmeticRightShift (left, right)

  val ~ = fn word => fromInt(Int.~(toInt word))

  val op + = fn (left : word, right) => left + right

  val op - = fn (left : word, right) => left - right

  val op * = fn (left : word, right) => left * right

  val op div = fn (left, right) => divWord (left, right)

  val op mod = fn (left, right) => modWord (left, right)

  fun compare (left : word, right) =
      if left < right
      then General.LESS
      else if left = right then General.EQUAL else General.GREATER

  fun min (left : word, right) = if left < right then left else right

  fun max (left : word, right) = if left > right then left else right

  local
    (*
     * Following functions can be defined by using the Char structure.
     * But because the Char structure refers to this Int structure,
     * we cannot rely on it to avoid a cyclic reference.
     *)
    fun charOfNum num = 
        case num of
          0w0 => #"0"
        | 0w1 => #"1"
        | 0w2 => #"2"
        | 0w3 => #"3"
        | 0w4 => #"4"
        | 0w5 => #"5"
        | 0w6 => #"6"
        | 0w7 => #"7"
        | 0w8 => #"8"
        | 0w9 => #"9"
        | 0w10 => #"A"
        | 0w11 => #"B"
        | 0w12 => #"C"
        | 0w13 => #"D"
        | 0w14 => #"E"
        | 0w15 => #"F"
        | _ => raise Fail "bug: Word.charOfNum"
    fun numOfChar char = 
        case char of
          #"0" => 0w0
        | #"1" => 0w1
        | #"2" => 0w2
        | #"3" => 0w3
        | #"4" => 0w4
        | #"5" => 0w5
        | #"6" => 0w6
        | #"7" => 0w7
        | #"8" => 0w8
        | #"9" => 0w9
        | #"A" => 0w10
        | #"a" => 0w10
        | #"B" => 0w11
        | #"b" => 0w11
        | #"C" => 0w12
        | #"c" => 0w12
        | #"D" => 0w13
        | #"d" => 0w13
        | #"E" => 0w14
        | #"e" => 0w14
        | #"F" => 0w15              
        | #"f" => 0w15
        | _ => raise Fail "bug: Int.numOfChar"
    fun numOfRadix radix =
        case radix of
          SC.BIN => 0w2 | SC.OCT => 0w8 | SC.DEC => 0w10 | SC.HEX => 0w16
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
  fun fmt radix (num : word) =
      let
        val radixNum = numOfRadix radix
        fun loop 0w0 chars = implode chars
          | loop n chars =
            loop (n div radixNum) ((charOfNum (n mod radixNum)) :: chars)
      in
        if 0w0 = num
        then "0"
        else loop num []
      end

  fun toString num = fmt SC.HEX num

  local
    structure PC = ParserComb
    fun accumIntList base ints =
        foldl (fn (int, accum) => accum * base + int) 0w0 ints
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
    fun scanZeroW reader stream =
        PC.option(PC.string "0w") reader stream
    fun scanZeroX reader stream =
        PC.option
        (PC.or'
         [PC.string "0wx", PC.string "0wX", PC.string "0x", PC.string "0X"])
        reader
        stream
  in
  fun scan radix reader stream =
      let
        fun scanBody reader stream =
            (case radix of
               StringCvt.HEX =>
               PC.seqWith #2 (scanZeroX, scanNumbers radix)
             | _ => PC.seqWith #2 (scanZeroW, scanNumbers radix))
            reader
            stream
      in
        scanBody reader (StringCvt.skipWS reader stream)
      end
  end
  end
  fun fromString string = (SC.scanString (scan SC.HEX)) string


  fun op < (left : word, right : word) =
      case compare (left, right) of General.LESS => true | _ => false
  fun op <= (left : word, right : word) =
      case compare (left, right) of General.GREATER => false | _ => true
  val op > = not o (op <=)
  val op >= = not o (op <)

  (***************************************************************************)

end;