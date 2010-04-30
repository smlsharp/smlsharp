(**
 * a pretty printer for the raw symtax of core ML
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: TypeFormatter.sml,v 1.11 2008/03/18 06:20:50 bochao Exp $
 *)
structure TypeFormatter : TYPE_FORMATTER =
struct

  fun tyToString ty = Control.prettyPrint (Types.format_ty nil ty)

  fun varEnvToString varenv =
      Control.prettyPrint (Types.format_varEnv nil varenv)

  fun tyConEnvToString tyConEnv =
      Control.prettyPrint (Types.format_tyConEnv nil tyConEnv)

  fun envToString Env =
      Control.prettyPrint (Types.format_Env nil Env)

  fun topEnvToString Env =
      Control.prettyPrint (Types.format_topEnv nil Env)

  fun interfaceEnvToString Env =
      Control.prettyPrint (Types.format_interfaceEnv nil Env)

  fun tyBindInfoToString tybindinfo =
      Control.prettyPrint (Types.format_tyBindInfo nil tybindinfo)

end
