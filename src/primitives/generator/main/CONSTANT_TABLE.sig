(**
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: CONSTANT_TABLE.sig,v 1.1 2005/08/10 07:38:53 kiyoshiy Exp $
 *)
signature CONSTANT_TABLE =
sig

  (***************************************************************************)

  datatype constant =
           Int of int
         | Word of word
         | String of string
         | Char of char
         | Real of real

  type spec =
       {
         bindName : string,
         constant : constant
       }

  (***************************************************************************)

  exception ParseError of int

  (***************************************************************************)

  val input : string -> spec list
  val constantsSML : spec list -> string
  val constantsC  : spec list -> string
  val formatTemplate : spec list * string * string -> unit
  val generateFiles : string -> string list -> unit

  (***************************************************************************)

end
