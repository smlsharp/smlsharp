(**
 * SAConstraint
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
signature SACONSTRAINT = sig
  val convertLocalType : Types.ty -> AnnotatedTypes.ty
  val convertGlobalType : Types.ty -> AnnotatedTypes.ty
  val convertSingleValueType : Types.ty -> AnnotatedTypes.ty
  val convertLocalBtvEnv : Types.btvEnv -> AnnotatedTypes.btvEnv

  val globalType : AnnotatedTypes.ty -> unit 
  val singleValueType : AnnotatedTypes.ty -> unit 

  val unify : AnnotatedTypes.ty * AnnotatedTypes.ty -> unit
  exception Unify

  val solve : unit -> unit
  val initialize : unit -> unit
end
