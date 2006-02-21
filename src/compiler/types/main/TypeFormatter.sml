(**
 * Copyright (c) 2006, Tohoku University.
 *
 * a pretty printer for the raw symtax of core ML
 * @author Atsushi Ohori 
 * @version $Id: TypeFormatter.sml,v 1.5 2006/02/18 04:59:36 ohori Exp $
 *)
structure TypeFormatter : TYPE_FORMATTER =
struct

  fun tyToString ty = Control.prettyPrint (Types.format_ty nil ty)

  fun varenvToString varenv =
      Control.prettyPrint (Types.format_varEnv nil varenv)
  fun envToString Env =
      Control.prettyPrint (Types.format_Env nil Env)

end
