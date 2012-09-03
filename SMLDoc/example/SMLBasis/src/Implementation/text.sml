(* text.sml
 *
 * COPYRIGHT (c) 1998 Bell Labs, Lucent Technologies.
 *)

structure Text : TEXT =
  struct
    structure Char = Char
    structure String = StringImp
    structure Substring = Substring
    structure CharVector = CharVector
    structure CharArray = CharArray
  end;

