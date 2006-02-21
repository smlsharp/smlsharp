(**
 * Copyright (c) 2006, Tohoku University.
 *
 * A parser of type expression.
 * @author YAMATODANI Kiyoshi
 * @version $Id: TYPE_PARSER.sig,v 1.3 2006/02/18 04:59:36 ohori Exp $
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
