(**
 *
 * @author UENO Katsuhiro
 * @version $Id: PRIMITIVE_TABLE.sig,v 1.2 2007/01/23 03:25:16 kiyoshiy Exp $
 *)
signature PRIMITIVE_TABLE =
sig

  exception ParseError of int

  val generateFiles : string -> string list -> unit

end
