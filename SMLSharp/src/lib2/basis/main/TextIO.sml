(**
 * TextIO structure.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "TextIO.smi"
structure TextIO = SMLSharpSMLNJ_TextIO :> TEXT_IO
val print = TextIO.print
