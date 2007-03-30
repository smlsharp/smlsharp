(**
 * utility functions for manupilating types (needs re-writing).
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: TYPESUTILS.sig,v 1.5 2007/02/11 16:39:51 kiyoshiy Exp $
 *)
signature TYPESUTILS =
sig

  val tyconSpan : Types.tyCon -> int
  val isBoxedData : Types.ty -> bool

  val pruneTy : Types.ty -> Types.ty
  val derefTy : Types.ty -> Types.ty
  val domTy : Types.ty -> Types.ty
  val ranTy : Types.ty -> Types.ty
  val polyBodyTy : Types.ty -> Types.ty
  val tpappTy : Types.ty * Types.ty list -> Types.ty

  val performSubst : Types.ty * Types.ty -> unit
  val monoTy : Types.ty -> bool
  val eqTyCon : Types.conInfo * Types.conInfo -> bool
  val freshSubst : Types.btvEnv -> Types.ty IEnv.map

  val applyMatch : Types.ty IEnv.map -> Types.ty -> Types.ty
  val complementBSubst :
      Types.ty IEnv.map
      -> Types.btvKind IEnv.map
      -> Types.ty IEnv.map
  val EFTV : Types.ty -> OTSet.set
  val rank1 : int -> Types.ty -> bool
  val substBTvar : Types.subst -> Types.ty -> Types.ty
  val substBTvarBTKind : Types.subst -> Types.btvKind -> Types.btvKind
  val substBTvarRecKind : Types.subst -> Types.recKind -> Types.recKind
  val substBTvEnv : Types.subst -> Types.btvEnv -> Types.btvKind IEnv.map

  val substituteBTV : int * int -> Types.ty -> Types.ty
  val instantiate :
      {body : Types.ty, boundtvars : Types.btvEnv}
      -> (Types.ty * Types.ty IEnv.map) 
  val newTyCon :
      {
        arity : int,
	strpath : Types.path,
        datacon : Types.varEnv ref,
        eqKind : Types.eqKind ref,
        name : string
      }
      -> Types.tyCon
end
