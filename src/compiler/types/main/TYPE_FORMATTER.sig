(**
 * a pretty printer for the raw symtax of core ML
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: TYPE_FORMATTER.sig,v 1.6 2006/02/28 16:11:10 kiyoshiy Exp $
 *)
signature TYPE_FORMATTER =
sig

  val tyToString : Types.ty -> string
  val varenvToString : Types.varEnv -> string
  val envToString : Types.Env -> string

end
