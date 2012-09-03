(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: CODEC.sig,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
signature CODEC =
sig

  structure String : MB_STRING

  structure Char : MB_CHAR

  sharing type Char.string = String.string
  sharing type Char.char = String.char

end