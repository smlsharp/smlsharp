(**
 * a pretty printer for the raw symtax of core ML
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: TypeFormatter.sml,v 1.6 2006/02/28 16:11:10 kiyoshiy Exp $
 *)
structure TypeFormatter : TYPE_FORMATTER =
struct

  fun tyToString ty = Control.prettyPrint (Types.format_ty nil ty)

  fun varenvToString varenv =
      Control.prettyPrint (Types.format_varEnv nil varenv)
  fun envToString Env =
      Control.prettyPrint (Types.format_Env nil Env)

end
