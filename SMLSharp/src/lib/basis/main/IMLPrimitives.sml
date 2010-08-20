(**
 * This structure defines IML primitives to test our Basis implementation on
 * the SML/NJ.
 * @copyright 2010, Tohoku University.
 *)
structure IMLPrimitives =
struct
val quotInt = Int.quot
val remInt = Int.rem
val Word_toIntX = Word.toInt
val Word_fromInt = Word.fromInt
val Word_orb = Word.orb
val Word_xorb = Word.xorb
val Word_andb = Word.andb
val Word_notb = Word.notb
val Word_leftShift = Word.<<
val Word_logicalRightShift = Word.>>
val Word_arithmeticRightShift = Word.~>>
val divWord = Word.div
val modWord = Word.mod
val Int_toString = Int.toString
val Real_toString = Real.toString
val Word_toString = Word.toString
val Char_toString = Char.toString
val Char_ord = Char.ord
val Char_chr = Char.chr
val String_concat2 = op ^
val String_sub = String.sub
val String_size = String.size
val String_substring = String.substring
end;

