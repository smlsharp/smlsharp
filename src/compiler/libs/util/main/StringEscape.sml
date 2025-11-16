(**
 * @author Katsuhiro Ueno
 * @copyright (C) 2025 SML# Development Team.
 *)
structure StringEscape =
struct

  fun oct3 i = StringCvt.padLeft #"0" 3 (Int.fmt StringCvt.OCT i)
  fun dec3 i = StringCvt.padLeft #"0" 3 (Int.fmt StringCvt.DEC i)
  fun chr3 i = if i < 32 then "^" ^ str (chr (i + 64)) else dec3 i

  val c20 = #"\032"
  val c7F = #"\127"
  val c80 = #"\128"
  val c8F = #"\143"
  val c90 = #"\144"
  val c9F = #"\159"
  val cA0 = #"\160"
  val cBF = #"\191"
  val cC2 = #"\194"
  val cDF = #"\223"
  val cE0 = #"\224"
  val cED = #"\237"
  val cEF = #"\239"
  val cF0 = #"\240"
  val cF4 = #"\244"

  fun utf8_range b e ss =
      case Substring.getc ss of
        NONE => NONE
      | SOME (c, ss) =>
        if b <= c andalso c <= e
        then SOME ss
        else NONE

  fun utf8_2 ss =
      case utf8_range c80 cBF ss of
        NONE => 0
      | SOME ss => 2

  fun utf8_3 ss =
      case utf8_range c80 cBF ss of
        NONE => 0
      | SOME ss => 3

  fun utf8_4 ss =
      case utf8_range c80 cBF ss of
        NONE => 0
      | SOME ss =>
        case utf8_range c80 cBF ss of
          NONE => 0
        | SOME ss => 4

  fun getUtf8 ss =
      case Substring.getc ss of
        NONE => 0
      | SOME (c, ss) =>
        if c < c20 (* control *)
        then 0
        else if c <= c7F (* ascii *)
        then 1
        else if c < cC2 (* 110 00000 *)
        then 0
        else if c <= cDF (* 110 11111 *)
        then utf8_2 ss
        else if c = cE0 (* 1110 0000 *)
        then case utf8_range cA0 cBF ss of (* avoid redundancy *)
               NONE => 0
             | SOME ss => utf8_3 ss
        else if c = cED
        then case utf8_range c80 c9F ss of (* avoid sarogate pair *)
               NONE => 0
             | SOME ss => utf8_3 ss
        else if c <= cEF (* 1110 1111 *)
        then case utf8_range c80 cBF ss of
               NONE => 0
             | SOME ss => utf8_3 ss
        else if c = cF0 (* 11110 000 *)
        then case utf8_range c90 cBF ss of (* avoid redundancy *)
               NONE => 0
             | SOME ss => utf8_4 ss
        else if c = cF4 (* 11110 100 *)
        then case utf8_range c80 c8F ss of (* maximum code point *)
               NONE => 0
             | SOME ss => utf8_4 ss
        else if c <= cF4
        then case utf8_range c80 cBF ss of
               NONE => 0
             | SOME ss => utf8_4 ss
        else 0

  fun escape digit3 ss r =
      case Substring.getc ss of
        NONE => r
      | SOME (#"\007", ss) => escape digit3 ss (r ::> Substring.full "\\a")
      | SOME (#"\008", ss) => escape digit3 ss (r ::> Substring.full "\\b")
      | SOME (#"\009", ss) => escape digit3 ss (r ::> Substring.full "\\t")
      | SOME (#"\010", ss) => escape digit3 ss (r ::> Substring.full "\\n")
      | SOME (#"\011", ss) => escape digit3 ss (r ::> Substring.full "\\v")
      | SOME (#"\012", ss) => escape digit3 ss (r ::> Substring.full "\\f")
      | SOME (#"\013", ss) => escape digit3 ss (r ::> Substring.full "\\r")
      | SOME (#"\\", ss) => escape digit3 ss (r ::> Substring.full "\\\\")
      | SOME (#"\"", ss) => escape digit3 ss (r ::> Substring.full "\\\"")
      | SOME (c, ss2) =>
        case getUtf8 ss of
          0 => escape digit3 ss2 (r ::> Substring.full ("\\" ^ digit3 (ord c)))
        | n => case Substring.splitAt (ss, n) of
                 (l, ss) => escape digit3 ss (r ::> l)

  fun unquoted digit3 s =
      escape digit3 (Substring.full s) NIL

  fun quoted digit3 s =
      escape digit3 (Substring.full s) (NIL ::> Substring.full "\"")
      ::> Substring.full "\""

  fun concat r = Substring.concat (Snoc.toList r)

  fun toString s = concat (unquoted chr3 s)
  fun toCString s = concat (unquoted oct3 s)
  fun toStringLiteral s = concat (quoted chr3 s)
  fun toCStringLiteral s = concat (quoted oct3 s)

  fun getc ss =
      if Substring.isEmpty ss
      then NONE
      else SOME (Substring.splitAt (ss, Int.max (getUtf8 ss, 1)))

  fun isAlphaNumUtf8String ss =
      case getc ss of
        NONE => true
      | SOME (s, ss) =>
        (Substring.size s > 1 orelse Char.isAlphaNum (Substring.sub (s, 0)))
        andalso isAlphaNumUtf8String ss

  fun isAlphaNumUtf8Id ss =
      case getc (Substring.full ss) of
        NONE => false
      | SOME (s, ss) =>
        (Substring.size s > 1 orelse Char.isAlpha (Substring.sub (s, 0)))
        andalso isAlphaNumUtf8String ss

end
