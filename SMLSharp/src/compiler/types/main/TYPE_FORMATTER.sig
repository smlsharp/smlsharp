(**
 * a pretty printer for the raw symtax of core ML
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: TYPE_FORMATTER.sig,v 1.11 2008/03/18 06:20:50 bochao Exp $
 *)
signature TYPE_FORMATTER =
sig

  val tyToString : Types.ty -> string
  val varEnvToString : Types.varEnv -> string
  val tyConEnvToString : Types.tyConEnv -> string
  val envToString : Types.Env -> string
  val topEnvToString : Types.topEnv -> string
  val interfaceEnvToString : Types.interfaceEnv -> string
  val tyBindInfoToString : Types.tyBindInfo -> string
end
