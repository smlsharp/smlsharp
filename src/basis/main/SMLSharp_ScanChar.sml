(**
 * SMLSharpPreBasis structure.
 * @author UENO Katsuhiro
 * @copyright 2011, 2012, 2013, Tohoku University.
 *)

infix 7 * / div mod
infix 6 + - ^
infixr 5 :: @
infix 4 = <> > >= < <=
val op + = SMLSharp_Builtin.Int.add_unsafe
val op - = SMLSharp_Builtin.Int.sub_unsafe
val op * = SMLSharp_Builtin.Int.mul_unsafe
val op < = SMLSharp_Builtin.Int.lt
val op <= = SMLSharp_Builtin.Char.lteq
val ord = SMLSharp_Builtin.Char.ord
structure Word8 = SMLSharp_Builtin.Word8
structure Char = SMLSharp_Builtin.Char

structure SMLSharp_ScanChar =
struct

  fun scanDigit (getc : (char, 'a) StringCvt.reader) strm =
      case getc strm of
        NONE => NONE
      | SOME (c, strm) =>
        if #"0" <= c andalso c <= #"9"
        then SOME (ord c - 0x30, strm) else NONE

  fun scanOctDigit (getc : (char, 'a) StringCvt.reader) strm =
      case getc strm of
        NONE => NONE
      | SOME (c, strm) =>
        if #"0" <= c andalso c <= #"7"
        then SOME (ord c - 0x30, strm) else NONE

  fun scanHexDigit (getc : (char, 'a) StringCvt.reader) strm =
      case getc strm of
        NONE => NONE
      | SOME (c, strm) =>
        if #"0" <= c andalso c <= #"9" then SOME (ord c - 0x30, strm)
        else if #"A" <= c andalso c <= #"F" then SOME (ord c - 0x41 + 10, strm)
        else if #"a" <= c andalso c <= #"f" then SOME (ord c - 0x61 + 10, strm)
        else NONE

  fun scanBinDigit (getc : (char, 'a) StringCvt.reader) strm =
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

  fun scanEscapeSequence getc strm =
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
           then SOME (Word8.castToChar (Word8.sub (Char.castToWord8 c, 0w64)),
                      strm)
           else NONE)
      | _ => NONE

  fun isSpace #" " = true
    | isSpace c = #"\t" <= c andalso c <= #"\r"

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
          case scanEscapeSequence getc strm of
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
                  then NONE else SOME (Word8.castToChar (Word8.fromInt n), strm)
              )
            | SOME _ =>
              (
                case scanDec3 getc strm of
                  SOME (n, strm) =>
                  if n < 0 orelse 255 < n
                  then NONE else SOME (Word8.castToChar (Word8.fromInt n), strm)
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
          case scanEscapeSequence getc strm of
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
                    NONE => SOME (Word8.castToChar (Word8.fromInt n1), strm)
                  | SOME (n2, strm) =>
                    case scanHexDigit getc strm of
                      NONE =>
                      SOME (Word8.castToChar (Word8.fromInt (n1 * 16 + n2)),
                            strm)
                    | SOME _ => NONE
              end
            | SOME _ =>
              (
                case scanOctDigit getc strm of
                  NONE => NONE
                | SOME (n1, strm) =>
                  case scanOctDigit getc strm of
                    NONE => SOME (Word8.castToChar (Word8.fromInt n1), strm)
                  | SOME (n2, strm) =>
                    case scanOctDigit getc strm of
                      NONE =>
                      SOME (Word8.castToChar (Word8.fromInt (n1 * 8 + n2)),
                            strm)
                    | SOME (n3, strm) =>
                      SOME (Word8.castToChar
                              (Word8.fromInt ((n1 * 8 + n2) * 8 + n3)),
                            strm)
              )
        )
      | SOME (c, strm) =>
        if #"\032" <= c andalso c <= #"\126" then SOME (c, strm) else NONE

  fun scanRepeat0
        (scan : (char, 'a) StringCvt.reader -> ('b, 'a) StringCvt.reader)
        getc strm =
      let
        fun loop (z, strm) =
            case scan getc strm of
              NONE => (List.rev z, strm)
            | SOME (c, strm) => loop (c::z, strm)
      in
        loop (nil, strm)
      end

  fun scanRepeat1
        (scan : (char, 'a) StringCvt.reader -> ('b, 'a) StringCvt.reader)
        getc strm =
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

  fun scanInt radix (getc : (char, 'a) StringCvt.reader) strm =
      let
        val strm = skipSpaces getc strm
        val (neg, strm) =
            case getc strm of
              SOME (#"+", strm) => (false, strm)
            | SOME (#"-", strm) => (true, strm)
            | SOME (#"~", strm) => (true, strm)
            | _ => (false, strm)
        fun digits strm =
            case scanDigits radix getc strm of
              NONE => NONE
            | SOME ({radix, digits}, strm) =>
              SOME ({neg = neg, radix = radix, digits = digits}, strm)
        fun xdigits strm =
            case getc strm of
              SOME (#"x", strm) => digits strm
            | SOME (#"X", strm) => digits strm
            | _ => NONE
      in
        case radix of
          StringCvt.HEX =>
          (case getc strm of
             SOME (#"0", strm2) =>
             (case xdigits strm2 of
                ret as SOME _ => ret
              | NONE => digits strm)
           | _ => digits strm)
        | _ => digits strm
      end

  fun scanWord radix (getc : (char, 's) StringCvt.reader)
        strm =
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
      else if n < 10 then Word8.castToChar (Word8.fromInt (0x30 + n))
      else if n < 16 then Word8.castToChar (Word8.fromInt (0x41 + (n - 10)))
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

  (* [+~-]? *)
  fun scanSign getc strm =
      case getc strm of
        SOME (#"+", strm) => (false, strm)
      | SOME (#"~", strm) => (true, strm)
      | SOME (#"-", strm) => (true, strm)
      | _ => (false, strm)

  (* [eE][+~-]?[0-9]+ *)
  fun scanExponent getc strm =
      let
        fun scanNum strm =
            let
              val (sign, strm) = scanSign getc strm
            in
              case scanRepeat1 scanDigit getc strm of
                NONE => NONE
              | SOME (digits, strm) => SOME ((sign, digits), strm)
            end
      in
        case getc strm of
          SOME (#"e", strm) => scanNum strm
        | SOME (#"E", strm) => scanNum strm
        | _ => NONE
      end

  (* \.[0-9]+ *)
  fun scanDecimal getc strm =
      case getc strm of
        SOME (#".", strm2) => scanRepeat1 scanDigit getc strm2
      | _ => NONE

  (* [+~-]?[0-9]+(\.[0-9]+)?|\.[0-9]+ *)
  fun scanMantissa getc strm =
      case scanRepeat1 scanDigit getc strm of
        SOME (il, strm) =>
        (case scanDecimal getc strm of
           SOME (fl, strm) => SOME ((il, fl), strm)
         | NONE => SOME ((il, nil), strm))
      | NONE =>
        case scanDecimal getc strm of
          SOME (fl, strm) => SOME ((nil, fl), strm)
        | NONE => NONE

end
