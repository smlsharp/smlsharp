(**
 * A parser of type expression.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: TYPE_PARSER.sig,v 1.5 2007/01/19 14:06:39 kiyoshiy Exp $
 *)
signature TYPE_PARSER =
sig

  (***************************************************************************)

  (** raised by readTy when argument string is not valid type expression. *)
  exception TypeFormat of string

  (** parse string to type expression. *)
  val readTy : Types.tyConEnv -> string -> Types.ty

  (***************************************************************************)

end
