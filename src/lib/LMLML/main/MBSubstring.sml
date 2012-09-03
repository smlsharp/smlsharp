(**
 * Subtring structure of multibyte string version.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MBSubstring.sml,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
local
  structure MBS = MultiByteString.String
  structure MBC = MultiByteString.Char
  structure P =
  struct
    type char = MBS.char
    type string = MBS.string
    val sub = MBS.sub
    val substring = MBS.substring
    val size = MBS.size
    val concat = MBS.concat
    val compare = MBS.compare
    val compareChar = MBC.compare
  end
in

structure MBSubstring : MB_SUBSTRING = SubstringBase(P)

end

