(**
 * a kinded unification for ML core, an imperative version.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: UNIFY.sig,v 1.6 2008/05/31 12:18:23 ohori Exp $
 *)
signature UNIFY =
sig

  (***************************************************************************)

  exception Unify

  (***************************************************************************)

  val unify : (Types.ty * Types.ty) list -> unit

  val occurres : Types.tvState ref  -> Types.ty -> bool

  val patternUnify : (Types.ty * Types.ty) list -> unit
  (***************************************************************************)

end
