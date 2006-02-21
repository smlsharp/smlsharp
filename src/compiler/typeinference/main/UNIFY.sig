(**
 * Copyright (c) 2006, Tohoku University.
 *
 * a kinded unification for ML core, an imperative version.
 * @author Atsushi Ohori 
 * @version $Id: UNIFY.sig,v 1.2 2006/02/18 04:59:34 ohori Exp $
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
