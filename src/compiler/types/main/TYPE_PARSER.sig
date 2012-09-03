(**
 * A parser of type expression.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: TYPE_PARSER.sig,v 1.4 2006/02/28 16:11:10 kiyoshiy Exp $
 *)
signature TYPE_PARSER =
sig

  (***************************************************************************)

  (** raised by readTy when argument string is not valid type expression. *)
  exception TypeFormat of string

  (** parse string to type expression. *)
  val readTy : string -> Types.ty

  (***************************************************************************)

end
