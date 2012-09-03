(**
 * Char structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Char.sml,v 1.6 2005/05/27 12:26:57 kiyoshiy Exp $
 *)
structure Char =
struct
  open Char

  (***************************************************************************)

  type char = char

  type string = string

  (***************************************************************************)

  val minChar = #"\000"

  val maxChar = #"\255"

  val maxOrd = 255

(*
  val ord = Char_ord (* primitive *)
*)

  fun chr index =
      if index < 0 orelse maxOrd < index
      then raise General.Chr
      else Char.chr_unsafe index

  fun succ char =
      if maxChar <= char
      then raise General.Chr
      else chr((ord char) + 1)

  fun pred char =
      if char <= minChar
      then raise General.Chr
      else chr((ord char) - 1)

  fun compare (left : char, right) =
        if left < right
        then General.LESS
        else if left = right then General.EQUAL else General.GREATER
(*
      let val leftCode = ord left val rightCode = ord right
      in
      end
      in Int.compare (leftChar, rightChar) end
*)

  fun contains string char =
      List.exists (fn ch => ch = char) (explode string)

  fun notContains string char = not(contains string char)

  local
    val minLowerAlpha = #"a"
    val maxLowerAlpha = #"z"
    val minUpperAlpha = #"A"
    val maxUpperAlpha = #"Z"
    val diffOfLowerAndUpperAlpha = (ord minUpperAlpha) - (ord minLowerAlpha)
    val minAscii = #"\000"
    val maxAscii = #"\127"
    val minDigit = #"0"
    val maxDigit = #"9"
    val minOctal = #"0"
    val maxOctal = #"7"
  in
  fun isLower char = minLowerAlpha <= char andalso char <= maxLowerAlpha
  fun isUpper char = minUpperAlpha <= char andalso char <= maxUpperAlpha
  fun toLower (char : char) =
      if isUpper char
      then chr((ord char) - diffOfLowerAndUpperAlpha)
      else char
  fun toUpper (char : char) =
      if isLower char
      then chr((ord char) + diffOfLowerAndUpperAlpha)
      else char
  fun isAlpha (char : char) = (isLower char) orelse (isUpper char)
  fun isAscii (char : char) = minAscii <= char andalso char <= maxAscii
  fun isDigit (char : char) = minDigit <= char andalso char <= maxDigit
  fun isOctal (char : char) = minOctal <= char andalso char <= maxOctal
  fun isAlphaNum (char : char) = (isAlpha char) orelse (isDigit char)
  fun isGraph char = #"!" <= char andalso char <= #"~"  
  fun isPrint (char : char) = isGraph char orelse char = #" " 
  fun isCntrl (char : char) = isAscii char andalso not (isPrint char)
  fun isPunct (char : char) = isGraph char andalso not (isAlphaNum char)  
  fun isSpace (char : char) =
      (#"\t" <= char andalso char <= #"\r") orelse char = #" " 
  fun isHexDigit (char : char) =
      isDigit char
      orelse (#"a" <= char andalso char <= #"f")  
      orelse (#"A" <= char andalso char <= #"F")  
  end

  local
    structure PC = ParserComb
    fun accumIntList base ints =
        foldl (fn (int, accum) => accum * base + int) 0 ints
    fun decCharToInt char = ord char - ord #"0"
    fun hexCharToInt char =
        if #"0" <= char andalso char <= #"9"
        then ord char - ord #"0"
        else (ord (toUpper char) - ord #"A") + 10
    fun intListToChar base ints =
        let val code = accumIntList base ints
        in
          if 0 <= code andalso code <= maxOrd
          then PC.result (chr(code))
          else PC.failure
        end
    fun scanNSeq times scanner reader stream =
        let val scanners = List.tabulate (times, fn _ => scanner)
        in
          (List.foldl
               (fn (scanLeft, scanRight) =>
                   PC.seqWith
                       (fn (left, right) => left :: right)
                       (scanLeft, scanRight))
               (PC.result ([] : int list))
               (* ToDo : if the type annotation " : int list" is removed,
                * a compile error occurs. *)
               scanners)
              reader
              stream
        end
      fun scanControl reader stream =
          let
            fun isCtrlChar char = #"@" <= char andalso char <= #"_"
            fun charToCtrl char = chr(ord char - 64)
          in
            PC.seqWith
                #2
                (PC.char #"^", PC.wrap(PC.eatChar isCtrlChar, charToCtrl))
                reader
                stream
          end
  in
    local
      fun scanDecCode reader stream =
          PC.bind
              (
                scanNSeq 3 (PC.wrap(PC.eatChar isDigit, decCharToInt)),
                intListToChar 10
              )
              reader
              stream
      fun scanHexCode reader stream =
          PC.bind
            (
              PC.seqWith
                  #2
                  (
                    PC.char #"u",
                    scanNSeq 4 (PC.wrap(PC.eatChar isHexDigit, hexCharToInt))
                  ),
              intListToChar 16
            )
            reader
            stream
      fun scanFormatting reader stream =
          PC.seqWith
              #2
              (
                PC.seq(PC.oneOrMore (PC.eatChar isSpace), PC.char #"\\"),
                scanString
              )
              reader
              stream
      and scanEscaped reader stream =
          PC.or'
          ((map
                (fn (char, result) =>
                    PC.seqWith #2 (PC.char char, PC.result result))
                [
                  (#"a", #"\a"),
                  (#"b", #"\b"),
                  (#"t", #"\t"),
                  (#"n", #"\n"),
                  (#"v", #"\v"),
                  (#"f", #"\f"),
                  (#"r", #"\r"),
                  (#"\\", #"\\"),
                  (#"\"", #"\"")
                ])
           @ [scanControl, scanDecCode, scanHexCode, scanFormatting])
          reader
          stream
      and scanString reader stream =
          PC.or(PC.seqWith #2 (PC.char #"\\", scanEscaped),
                PC.eatChar (fn ch => ch <> #"\\" andalso not(isCntrl ch)))
               reader
               stream
    in
    val scan = scanString
    end

    local
      fun scanOctalCode reader stream =
          (* "\\ooo", one to three octals. *)
          PC.bind
              (
                scanNSeq 3 (PC.wrap(PC.eatChar isOctal, decCharToInt)),
                intListToChar 8
              )
              reader
              stream
      fun scanHexCode reader stream =
          (* "\\xhhh...", longest sequence of hexadecimals. *)
          PC.bind
            (
              PC.seqWith
                  #2
                  (
                    PC.char #"x",
                    PC.oneOrMore (PC.wrap(PC.eatChar isHexDigit, hexCharToInt))
                  ),
              intListToChar 16
            )
            reader
            stream
      fun scanEscaped reader stream =
          PC.or'
          ((map
                (fn (char, result) =>
                    PC.seqWith #2 (PC.char char, PC.result result))
                [
                  (#"a", #"\a"),
                  (#"b", #"\b"),
                  (#"t", #"\t"),
                  (#"n", #"\n"),
                  (#"v", #"\v"),
                  (#"f", #"\f"),
                  (#"r", #"\r"),
                  (#"?", #"?"),
                  (#"\\", #"\\"),
                  (#"\"", #"\""),
                  (#"'", #"'")
                ])
           @ [scanControl, scanOctalCode, scanHexCode])
          reader
          stream
      and scanCString reader stream =
          PC.or(PC.seqWith #2 (PC.char #"\\", scanEscaped),
                PC.eatChar (fn ch => ch <> #"\\"))
               reader
               stream
    in
    val scanCString = scanCString
    end
  end

  fun fromString string = StringCvt.scanString scan string
  fun fromCString string = StringCvt.scanString scanCString string
(* The following eta equivalent form causes an internal error of the SML/NJ.
  val fromString = StringCvt.scanString scan
  val fromCString = StringCvt.scanString scanCString
*)

  fun toString (char : char) =
      case char of
        #"\\" => "\\\\"
      | #"\"" => "\\\""
      | #"\a" => "\\a"
      | #"\b" => "\\b"
      | #"\t" => "\\t"
      | #"\n" => "\\n"
      | #"\v" => "\\v"
      | #"\f" => "\\f"
      | #"\r" => "\\r"
      | _ =>
        let val code = ord char
        in
          if code < 32
          then implode [#"\\", #"^", chr(code + 64)] (* see Basis doc. *)
          else
            if 999 < code
            then
              "\\u" ^ (StringCvt.padLeft #"0" 4 (Int.fmt StringCvt.HEX code))
            else
              if 126 < code
              then
                "\\" ^ (StringCvt.padLeft #"0" 3 (Int.fmt StringCvt.DEC code))
              else implode [char]
        end

  fun toCString (char : char) =
      case char of
        #"\\" => "\\\\"
      | #"\"" => "\\\""
      | #"?" => "\\?"
      | #"'" => "\\'"
      | #"\a" => "\\a"
      | #"\b" => "\\b"
      | #"\t" => "\\t"
      | #"\n" => "\\n"
      | #"\v" => "\\v"
      | #"\f" => "\\f"
      | #"\r" => "\\r"
      | _ =>
        if isPrint char
        then implode [char]
        else
          let val code = ord char
          in
            "\\" ^ (StringCvt.padLeft #"0" 3 (Int.fmt StringCvt.OCT code))
          end

  fun op < (left : char, right : char) =
      case compare (left, right) of General.LESS => true | _ => false
  fun op <= (left : char, right : char) =
      case compare (left, right) of General.GREATER => false | _ => true
  val op > = not o (op <=)
  val op >= = not o (op <)

  (***************************************************************************)

end;
