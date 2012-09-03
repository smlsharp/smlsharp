(**
 * A parser of type expression.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: TYPE_PARSER.sig,v 1.10 2008/05/31 12:18:23 ohori Exp $
 *)
signature TYPE_PARSER =
sig

  (***************************************************************************)

  (** raised by readTy when argument string is not valid type expression. *)
  exception TypeFormat of string

  (** parse string to type expression. *)
  val readTy : Types.topTyConEnv -> 
               string -> 
               Types.ty 

  (***************************************************************************)

end
