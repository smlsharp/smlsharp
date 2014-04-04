(**
 * Char structure.
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infix 7 * / div mod
infix 6 + - ^
infix 4 = <> > >= < <=
val op + = SMLSharp_Builtin.Int.add_unsafe
val op - = SMLSharp_Builtin.Int.sub_unsafe
val op >= = SMLSharp_Builtin.Int.gteq
structure String = SMLSharp_Builtin.String
structure Array = SMLSharp_Builtin.Array
structure Char = SMLSharp_Builtin.Char
structure Word8 = SMLSharp_Builtin.Word8

structure Char =
struct

  type char = char
  type string = string

  (* 8-bit unsigned integer *)
  val minChar = #"\000"
  val maxChar = #"\255"
  val maxOrd = 255

  val ord = Char.ord
  val chr = Char.chr
  val op < = Char.lt
  val op <= = Char.lteq
  val op > = Char.gt

  fun succ char =
      if maxChar <= char then raise Chr
      else Word8.castToChar (Word8.add (Char.castToWord8 char, 0w1))
  fun pred char =
      if char <= minChar then raise Chr
      else Word8.castToChar (Word8.sub (Char.castToWord8 char, 0w1))

  fun compare (left, right) =
      if left < right then General.LESS
      else if left = right then General.EQUAL
      else General.GREATER

  fun contains string char =
      let
        val len = String.size string
        fun loop i =
            if i >= len then false
            else Array.sub_unsafe (String.castToArray string, i) = char
                 orelse loop (i + 1)
      in
        loop 0
      end

  fun notContains string char =
      if contains string char then false else true

  fun isUpper c = #"A" <= c andalso c <= #"Z"
  fun isLower c = #"a" <= c andalso c <= #"z"
  fun isDigit c = #"0" <= c andalso c <= #"9"
  fun isAlpha c = isUpper c orelse isLower c
  fun isAlphaNum c = isAlpha c orelse isDigit c
  fun isHexDigit c = isDigit c
                     orelse (#"a" <= c andalso c <= #"f")
	             orelse (#"A" <= c andalso c <= #"F")
  fun isGraph c = #"!" <= c andalso c <= #"~"
  fun isPrint c = #" " <= c andalso c <= #"~"
  fun isPunct c = (#"!" <= c andalso c <= #"/")
                  orelse (#":" <= c andalso c <= #"@")
                  orelse (#"[" <= c andalso c <= #"`")
                  orelse (#"{" <= c andalso c <= #"~")
  fun isCntrl c = (#"\000" <= c andalso c <= #"\031") orelse c = #"\127"
  fun isSpace c = (#"\t" <= c andalso c <= #"\r") orelse c = #" "
  fun isAscii c = #"\000" <= c andalso c <= #"\127"
  fun toLower c =
      if isUpper c
      then Word8.castToChar (Word8.add (Char.castToWord8 c, 0w32))
      else c
  fun toUpper c =
      if isLower c
      then Word8.castToChar (Word8.sub (Char.castToWord8 c, 0w32))
      else c

  local

    fun escapeChar radix ch =
        let
          val buf = String.alloc 4
          val _ = Array.update_unsafe (String.castToArray buf, 0, #"\\")
          fun loop (0, n) = ()
            | loop (i, n) =
              if Word8.lteq (n, 0w0) then
                (Array.update_unsafe (String.castToArray buf, i, #"0");
                 loop (i - 1, n))
              else
                let
                  val m = Word8.mod_unsafe (n, radix)
                  val digit = Word8.castToChar (Word8.add (m, 0wx30))
                in
                  Array.update_unsafe (String.castToArray buf, i, digit);
                  loop (i - 1, Word8.div_unsafe (n, radix))
                end
          val _ = loop (3, Char.castToWord8 ch)
        in
          buf
        end

    fun escapeCharDec ch = escapeChar 0w10 ch
    fun escapeCharHex ch = escapeChar 0w8 ch

    fun escapeControl n =
        let
          val buf = String.alloc_unsafe 3
          val c = Word8.castToChar (Word8.add (n, 0w64))
        in
          Array.update_unsafe (String.castToArray buf, 0, #"\\");
          Array.update_unsafe (String.castToArray buf, 1, #"^");
          Array.update_unsafe (String.castToArray buf, 2, c);
          buf
        end

    fun str c =
        let
          val buf = String.alloc 1
        in
          Array.update_unsafe (String.castToArray buf, 0, c);
          buf
        end

  in

  fun toString c =
      case c of
        #"\\" => "\\\\"
      | #"\"" => "\\\""
      | #"\007" => "\\a"
      | #"\008" => "\\b"
      | #"\009" => "\\t"
      | #"\010" => "\\n"
      | #"\011" => "\\v"
      | #"\012" => "\\f"
      | #"\013" => "\\r"
      | _ =>
        if c < #"\032" then escapeControl (Char.castToWord8 c)
        else if #"\127" <= c then escapeCharDec c
        else str c   (* c < 256 *)

  fun toRawString c =
      case c of
        #"\\" => "\\\\"
      | #"\"" => "\\\""
      | #"\007" => "\\a"
      | #"\008" => "\\b"
      | #"\009" => "\\t"
      | #"\010" => "\\n"
      | #"\011" => "\\v"
      | #"\012" => "\\f"
      | #"\013" => "\\r"
      | _ =>
        if c < #"\032" then escapeControl (Char.castToWord8 c)
        else str c 

  fun toCString c =
      case c of
        #"\\" => "\\\\"
      | #"\"" => "\\\""
      | #"?" => "\\?"
      | #"'" => "\\'"
      | #"\007" => "\\a"
      | #"\008" => "\\b"
      | #"\009" => "\\t"
      | #"\010" => "\\n"
      | #"\011" => "\\v"
      | #"\012" => "\\f"
      | #"\013" => "\\r"
      | _ =>
        if c < #"\032" orelse #"\127" <= c
        then escapeCharHex c
        else str c   (* c < 256 *)

  end (* local *)

  val scan = SMLSharp_ScanChar.scanChar

  fun fromString string =
      StringCvt.scanString scan string
  fun fromCString string =
      StringCvt.scanString SMLSharp_ScanChar.scanCChar string

  val op >= = Char.gteq

end
