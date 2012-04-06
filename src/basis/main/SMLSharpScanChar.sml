(**
 * SMLSharpPreBasis structure.
 * @author UENO Katsuhiro
 * @copyright 2011, Tohoku University.
 *)
_interface "SMLSharpScanChar.smi"

structure SMLSharpScanChar : sig

  val scanDigit : (char, 's) StringCvt.reader -> (int, 's) StringCvt.reader
  val scanOctDigit : (char, 's) StringCvt.reader -> (int, 's) StringCvt.reader
  val scanHexDigit : (char, 's) StringCvt.reader -> (int, 's) StringCvt.reader
  val scanBinDigit : (char, 's) StringCvt.reader -> (int, 's) StringCvt.reader
  val skipSpaces : (char, 's) StringCvt.reader -> 's -> 's
  val scanSpaces : (char, 's) StringCvt.reader -> (unit, 's) StringCvt.reader
  val scanEscapeSpaces : (char, 's) StringCvt.reader
                         -> (unit, 's) StringCvt.reader
  val scanChar : (char, 's) StringCvt.reader -> (char, 's) StringCvt.reader
  val scanCChar : (char, 's) StringCvt.reader -> (char, 's) StringCvt.reader
  val scanRepeat0 : ((char, 's) StringCvt.reader -> ('a, 's) StringCvt.reader)
                    -> (char, 's) StringCvt.reader -> 's -> 'a list * 's
  val scanRepeat1 : ((char, 's) StringCvt.reader -> ('a, 's) StringCvt.reader)
                    -> (char, 's) StringCvt.reader
                    -> ('a list, 's) StringCvt.reader
  val scanInt : StringCvt.radix
                -> (char, 's) StringCvt.reader
                -> ({neg:bool, radix:int, digits:int list}, 's) StringCvt.reader
  val scanWord : StringCvt.radix
                 -> (char, 's) StringCvt.reader
                 -> ({radix:int, digits:int list}, 's) StringCvt.reader

  val radixToInt : StringCvt.radix -> int
  val intToDigit : int -> char

  val fmtInt : (int -> (int, 's) StringCvt.reader)
               -> StringCvt.radix
               -> 's
               -> char list

end =
struct

  infix 7 * / div mod
  infix 6 + -
  infix 4 = <> > >= < <=
  val op + = SMLSharp.Int.add
  val op - = SMLSharp.Int.sub
  val op * = SMLSharp.Int.mul
  val op < = SMLSharp.Int.lt
  val op <= = SMLSharp.Char.lteq
  val ord = SMLSharp.Char.ord
  val chr_unsafe = SMLSharp.Char.chr_unsafe

  fun scanDigit getc strm =
      case getc strm of
        NONE => NONE
      | SOME (c, strm) =>
        if #"0" <= c andalso c <= #"9"
        then SOME (ord c - 0x30, strm) else NONE

  fun scanOctDigit getc strm =
      case getc strm of
        NONE => NONE
      | SOME (c, strm) =>
        if #"0" <= c andalso c <= #"8"
        then SOME (ord c - 0x30, strm) else NONE

  fun scanHexDigit getc strm =
      case getc strm of
        NONE => NONE
      | SOME (c, strm) =>
        if #"0" <= c andalso c <= #"9" then SOME (ord c - 0x30, strm)
        else if #"A" <= c andalso c <= #"F" then SOME (ord c - 0x41 + 10, strm)
        else if #"a" <= c andalso c <= #"f" then SOME (ord c - 0x61 + 10, strm)
        else NONE

  fun scanBinDigit getc strm =
      case getc strm of
        NONE => NONE
      | SOME (#"0", strm) => SOME (0, strm)
      | SOME (#"1", strm) => SOME (1, strm)
      | SOME _ => NONE

  fun scanDec3 getc strm =
      case scanDigit getc strm of
        NONE => NONE
      | SOME (n1, strm) =>
        case scanDigit getc strm of
          NONE => NONE
        | SOME (n2, strm) =>
          case scanDigit getc strm of
            NONE => NONE
          | SOME (n3, strm) => SOME ((n1 * 10 + n2) * 10 + n3, strm)

  fun scanHex4 getc strm =
      case scanHexDigit getc strm of
        NONE => NONE
      | SOME (n1, strm) =>
        case scanHexDigit getc strm of
          NONE => NONE
        | SOME (n2, strm) =>
          case scanHexDigit getc strm of
            NONE => NONE
          | SOME (n3, strm) =>
            case scanHexDigit getc strm of
              NONE => NONE
            | SOME (n4, strm) =>
              SOME (((n1 * 16 + n2) * 16 + n3) * 16 + n4, strm)

  fun skipZero getc strm =
      case getc strm of
        SOME (#"0", strm) => skipZero getc strm
      | _ => strm

  fun scanControlChar getc strm =
      case getc strm of
        SOME (#"a", strm) => SOME (#"\007", strm)
      | SOME (#"b", strm) => SOME (#"\008", strm)
      | SOME (#"t", strm) => SOME (#"\009", strm)
      | SOME (#"n", strm) => SOME (#"\010", strm)
      | SOME (#"v", strm) => SOME (#"\011", strm)
      | SOME (#"f", strm) => SOME (#"\012", strm)
      | SOME (#"r", strm) => SOME (#"\013", strm)
      | SOME (#"\\", strm) => SOME (#"\\", strm)
      | SOME (#"\"", strm) => SOME (#"\"", strm)
      | SOME (#"^", strm) =>
        (case getc strm of
           NONE => NONE
         | SOME (c, strm) =>
           if #"\064" <= c orelse c <= #"\095"
           then SOME (chr_unsafe (ord c - 64), strm)
           else NONE)
      | _ => NONE

  fun isSpace c = (#"\t" <= c andalso c <= #"\r") orelse c = #" "

  fun skipSpaces getc strm =
      case getc strm of
        NONE => strm
      | SOME (c, strm') =>
        if isSpace c then skipSpaces getc strm' else strm

  fun scanSpaces getc strm =
      case getc strm of
        NONE => NONE
      | SOME (c, strm) =>
        if isSpace c then SOME ((), skipSpaces getc strm) else NONE

  fun scanEscapeSpaces getc strm =
      case getc strm of
        SOME (#"\\", strm) =>
        (case scanSpaces getc strm of
           NONE => NONE
         | SOME ((), strm) =>
           case getc strm of
             SOME (#"\\", strm) => SOME ((), strm)
           | _ => NONE)
      | _ => NONE

  fun scanChar getc strm =
      case getc strm of
        NONE => NONE
      | SOME (#"\\", strm) =>
        (
          case scanControlChar getc strm of
            SOME (c, strm) => SOME (c, strm)
          | NONE =>
            case getc strm of
              NONE => NONE
            | SOME (#"u", strm) =>
              (
                case scanHex4 getc strm of
                  NONE => NONE
                | SOME (n, strm) =>
                  if n < 0 orelse 255 < n
                  then NONE else SOME (chr_unsafe n, strm)
              )
            | SOME (c, strm') =>
              (
                case scanDec3 getc strm of
                  SOME (n, strm) => SOME (chr_unsafe n, strm)
                | NONE =>
                  case scanSpaces getc strm of
                    NONE => NONE
                  | SOME ((), strm) =>
                    case getc strm of
                      SOME (#"\\", strm) => scanChar getc strm
                    | _ => NONE
              )
        )
      | SOME (c, strm) =>
        if #"\032" <= c andalso c <= #"\126" then SOME (c, strm) else NONE

  fun scanCChar getc strm =
      case getc strm of
        NONE => NONE
      | SOME (#"\\", strm) =>
        (
          case scanControlChar getc strm of
            SOME (c, strm) => SOME (c, strm)
          | NONE =>
            case getc strm of
              NONE => NONE
            | SOME (#"?", strm) => SOME (#"?", strm)
            | SOME (#"'", strm) => SOME (#"'", strm)
            | SOME (#"x", strm) =>
              let
                val (zero, strm) =
                    case getc strm of
                      SOME (#"0", strm) => (true, skipZero getc strm)
                    | _ => (false, strm)
              in
                case scanHexDigit getc strm of
                  NONE => if zero then SOME (#"\000", strm) else NONE
                | SOME (n1, strm) =>
                  case scanHexDigit getc strm of
                    NONE => SOME (chr_unsafe n1, strm)
                  | SOME (n2, strm) =>
                    case scanHexDigit getc strm of
                      NONE => SOME (chr_unsafe (n1 * 16 + n2), strm)
                    | SOME _ => NONE
              end
            | SOME _ =>
              (
                case scanOctDigit getc strm of
                  NONE => NONE
                | SOME (n1, strm) =>
                  case scanOctDigit getc strm of
                    NONE => SOME (chr_unsafe n1, strm)
                  | SOME (n2, strm) =>
                    case scanOctDigit getc strm of
                      NONE => SOME (chr_unsafe (n1 * 8 + n2), strm)
                    | SOME (n3, strm) =>
                      SOME (chr_unsafe ((n1 * 8 + n2) * 8 + n3), strm)
              )
        )
      | SOME (c, strm) =>
        if #"\032" <= c andalso c <= #"\126" then SOME (c, strm) else NONE

  fun scanRepeat0 scan (getc:(char,'a) StringCvt.reader) strm =
      let
        fun loop (z, strm) =
            case scan getc strm of
              NONE => (rev z, strm)
            | SOME (c, strm:'a) => loop (c::z, strm)
      in
        loop (nil, strm)
      end

  fun scanRepeat1 scan getc strm =
      case scan getc strm of
        NONE => NONE
      | SOME (c, strm) =>
        case scanRepeat0 scan getc strm of
          (t, strm) => SOME (c::t, strm)

  fun scanDigits radix getc strm =
      case radix of
        StringCvt.BIN =>
        (
          case scanRepeat1 scanBinDigit getc strm of
            NONE => NONE
          | SOME (digits, strm) =>
            SOME ({radix=2, digits=digits}, strm)
        )
      | StringCvt.OCT =>
        (
          case scanRepeat1 scanOctDigit getc strm of
            NONE => NONE
          | SOME (digits, strm) =>
            SOME ({radix=8, digits=digits}, strm)
        )
      | StringCvt.DEC =>
        (
          case scanRepeat1 scanDigit getc strm of
            NONE => NONE
          | SOME (digits, strm) =>
            SOME ({radix=10, digits=digits}, strm)
        )
      | StringCvt.HEX =>
        (
          case scanRepeat1 scanHexDigit getc strm of
            NONE => NONE
          | SOME (digits, strm) =>
            SOME ({radix=16, digits=digits}, strm)
        )

  fun scanInt radix getc strm =
      let
        val strm = skipSpaces getc strm
        val (neg, strm) =
            case getc strm of
              SOME (#"+", strm) => (false, strm)
            | SOME (#"-", strm) => (true, strm)
            | SOME (#"~", strm) => (true, strm)
            | _ => (false, strm)
        val strm =
            case radix of
              StringCvt.HEX =>
              (case getc strm of
                 SOME (#"0", strm2) =>
                 (case getc strm2 of
                    SOME (#"X", strm) => strm
                  | SOME (#"x", strm) => strm
                  | _ => strm)
               | _ => strm)
            | _ => strm
      in
        case scanDigits radix getc strm of
          NONE => NONE
        | SOME ({radix, digits}, strm) =>
          SOME ({neg = neg, radix = radix, digits = digits}, strm)
      end

  fun scanWord radix getc strm =
      let
        val strm = skipSpaces getc strm
      in
        case getc strm of
          SOME (#"0", strm2) =>
          let
            val strm2 =
                case getc strm2 of
                  SOME (#"w", strm2) => strm2
                | SOME (#"W", strm2) => strm2
                | _ => strm2
            val ret =
                case radix of
                  StringCvt.HEX =>
                  (case getc strm2 of
                     SOME (#"x", strm2) => scanDigits radix getc strm2
                   | SOME (#"X", strm2) => scanDigits radix getc strm2
                   | _ => NONE)
                | _ => scanDigits radix getc strm2
          in
            case ret of
              SOME _ => ret
            | NONE => scanDigits radix getc strm
          end
        | _ =>
          scanDigits radix getc strm
      end

  fun intToDigit n =
      if n < 0 then #"_"
      else if n < 10 then chr_unsafe (0x30 + n)
      else if n < 16 then chr_unsafe (0x41 + (n - 10))
      else #"_"

  fun fmtInt getc radix num =
      let
        val radix =
            case radix of
              StringCvt.BIN => 2
            | StringCvt.OCT => 8
            | StringCvt.DEC => 10
            | StringCvt.HEX => 16
        val getc = getc radix
        fun loop (num, z) =
            case getc num of
              NONE => z
            | SOME (m, num) => loop (num, intToDigit m :: z)
      in
        loop (num, nil)
      end

  fun radixToInt radix =
      case radix of
        StringCvt.BIN => 2
      | StringCvt.OCT => 8
      | StringCvt.DEC => 10
      | StringCvt.HEX => 16
        
end
