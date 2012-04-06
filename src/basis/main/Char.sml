(**
 * Char structure.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "Char.smi"

structure Char :> CHAR
  where type char = char
  where type string = string
=
struct

  infix 7 * / div mod
  infix 6 + -
  infix 4 = <> > >= < <=
  val op + = SMLSharp.Int.add
  val op - = SMLSharp.Int.sub
  val op mod = SMLSharp.Int.mod
  val op div = SMLSharp.Int.div
  val op >= = SMLSharp.Int.gteq
  val op < = SMLSharp.Int.lt
  fun not false = true | not true = false

  type char = char
  type string = string

  (* 8-bit unsigned integer *)
  val minChar = #"\000"
  val maxChar = #"\255"
  val maxOrd = 255

  val ord = SMLSharp.Char.ord

  fun chr index =
      if index < 0 orelse maxOrd < index
      then raise General.Chr
      else SMLSharp.Char.chr_unsafe index

  val op < = SMLSharp.Char.lt
  val op <= = SMLSharp.Char.lteq
  val op > = SMLSharp.Char.gt

  fun succ char =
      if maxChar <= char then raise General.Chr
      else SMLSharp.Char.chr_unsafe (ord char + 1)
  fun pred char =
      if char <= minChar then raise General.Chr
      else SMLSharp.Char.chr_unsafe (ord char - 1)

  fun compare (left : char, right) =
      if left < right then General.LESS
      else if left = right then General.EQUAL
      else General.GREATER

  fun contains string char =
      let
        val len = SMLSharp.PrimString.size string
        fun loop i =
            if i >= len then false
            else SMLSharp.PrimString.sub_unsafe (string, i) = char
                 orelse loop (i + 1)
      in
        loop 0
      end

  fun notContains string char =
      not (contains string char)

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
  fun toLower c = if isUpper c then SMLSharp.Char.chr_unsafe (ord c + 32) else c
  fun toUpper c = if isLower c then SMLSharp.Char.chr_unsafe (ord c - 32) else c

  local

    fun escapeChar divmod ch =
        let
          val buf = SMLSharp.PrimString.allocVector 4
          val _ = SMLSharp.PrimString.update_unsafe (buf, 0, #"\\")
          fun loop (0, n) = ()
            | loop (i, n) =
              if 0 >= n then
                (SMLSharp.PrimString.update_unsafe (buf, i, #"0");
                 loop (i - 1, n))
              else
                let
                  val (n, m) = divmod n
                  val digit = SMLSharp.Char.chr_unsafe (0x30 + m)
                in
                  SMLSharp.PrimString.update_unsafe (buf, i, digit);
                  loop (i - 1, n)
                end
          val _ = loop (3, ord ch)
        in
          buf
        end

    fun escapeCharDec ch =
        escapeChar (fn x => (x div 10, x mod 10)) ch
    fun escapeCharHex ch =
        escapeChar (fn x => (x div 8, x mod 8)) ch

    fun escapeControl n =
        let
          val c = SMLSharp.Char.chr_unsafe (n + 64)
          val buf = SMLSharp.PrimString.allocVector 3
        in
          SMLSharp.PrimString.update_unsafe (buf, 0, #"\\");
          SMLSharp.PrimString.update_unsafe (buf, 1, #"^");
          SMLSharp.PrimString.update_unsafe (buf, 2, c);
          buf
        end

    fun str c =
        let
          val buf = SMLSharp.PrimString.allocVector 1
        in
          SMLSharp.PrimString.update_unsafe (buf, 0, c);
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
        if c < #"\032" then escapeControl (ord c)
        else if #"\127" <= c then escapeCharDec c
        else str c   (* c < 256 *)

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

  val scan = SMLSharpScanChar.scanChar

  fun fromString string =
      StringCvt.scanString scan string
  fun fromCString string =
      StringCvt.scanString SMLSharpScanChar.scanCChar string

  val op >= = SMLSharp.Char.gteq

end

val chr = Char.chr
val ord = Char.ord
