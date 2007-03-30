(**
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: CONSTANT_TABLE.sig,v 1.2 2007/01/23 03:25:16 kiyoshiy Exp $
 *)
signature CONSTANT_TABLE =
sig

  (***************************************************************************)

  exception ParseError of int

  (***************************************************************************)

  val generateFiles : string -> string list -> unit

  (***************************************************************************)

end
