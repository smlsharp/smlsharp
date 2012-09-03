(**
 *
 * @author UENO Katsuhiro
 * @version $Id: PRIMITIVE_TABLE.sig,v 1.1 2005/05/27 03:30:31 kiyoshiy Exp $
 *)
signature PRIMITIVE_TABLE =
sig

  (***************************************************************************)

  datatype primitive = Internal of string | External of int * string | None

  type spec =
       {
         bindName : string,
         typeSpec : string,
         arity : int,
         primitive : primitive
       }

  (***************************************************************************)

  exception ParseError of int

  (***************************************************************************)

  val input : string -> spec list
  val primitivesSML : spec list -> string
  val primitivesListC  : spec list -> string
  val formatTemplate : spec list * string * string -> unit
  val generateFiles : string -> string list -> unit

  (***************************************************************************)

end
