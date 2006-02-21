(**
 * Copyright (c) 2006, Tohoku University.
 *
 * a pretty printer for the raw symtax of core ML
 * @author Atsushi Ohori 
 * @version $Id: TYPE_FORMATTER.sig,v 1.5 2006/02/18 04:59:36 ohori Exp $
 *)
signature TYPE_FORMATTER =
sig

  val tyToString : Types.ty -> string
  val varenvToString : Types.varEnv -> string
  val envToString : Types.Env -> string

end
