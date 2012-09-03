(**
 * Substring structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Substring.sml,v 1.6 2006/09/16 08:10:20 kiyoshiy Exp $
 *)
local
  structure P =
  struct
    type string = string
    type char = char
    val emptyString = ""
    val sub = SMLSharp.PrimString.sub_unsafe
    val substring = SMLSharp.Runtime.String_substring
    val size = SMLSharp.PrimString.size
    val concat2 = SMLSharp.Runtime.String_concat2
    fun compare (left : string, right) =
        if left < right then LESS else if left = right then EQUAL else GREATER
    fun compareChar (left : char, right) =
        if left < right then LESS else if left = right then EQUAL else GREATER
  end
in
structure Substring = SubstringBase(P)
end;
