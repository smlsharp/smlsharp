(**
 * String converter structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MBStringConverter.sml,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
local
  structure MBS = MultiByteString.String
  structure MBC = MultiByteString.Char
  structure P =
  struct
    type string = MBS.string
    type char = MBS.char
    val sub = MBS.sub
    val size = MBS.size
    val concat = MBS.concat
    val implode = MBS.implode
    val isSpace = MBC.isSpace
  end
in

structure MBStringConverter : STRING_CONVERTER = StringConverterBase(P)

end
