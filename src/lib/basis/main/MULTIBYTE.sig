(* multibyte-sig.sml
 *
 * COPYRIGHT (c) 1997 Bell Labs, Lucent Technologies.
 *)

signature MULTIBYTE =
  sig

    type  state

    exception Invalid

    val initial : state

    val mbStringToWide : Word8Vector.vector -> WideString.string

    val wideStringToMB : WideString.string -> Word8Vector.vector

    val mbCharSize : (state * substring) -> (state * substring * int)

    val mbCharToWide : (state * substring) -> (state * substring * WideString.char)

    val mbSubstringToWide : (state * substring) -> (state * WideString.string)

    val wideCharToMB : (state * WideString.Char.char) -> (state * string)

    val wideSubstringToMB : (state * WideSubstring.substring) -> (state * string)

    val wideCharToChar : WideString.char -> char option

    val collate : (WideSubstring.substring * WideSubstring.substring) -> order

  end;
