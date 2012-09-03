(**
 * a kinded unification for ML core, an imperative version.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: UNIFY.sig,v 1.3 2006/02/28 16:11:09 kiyoshiy Exp $
 *)
signature UNIFY =
sig

  (***************************************************************************)

  exception Unify

  (***************************************************************************)

  val unify : (Types.ty * Types.ty) list -> unit

  val patternUnify : (Types.ty * Types.ty) list -> unit
  (***************************************************************************)

end
