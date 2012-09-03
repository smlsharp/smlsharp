(**
 * SAContext
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
signature SACONTEXT = sig
  type context

  val empty : context

  val insertVariable : context -> AnnotatedCalc.varInfo -> context
      
  val insertVariables : context -> (AnnotatedCalc.varInfo list) -> context

  val insertExVar : context -> AnnotatedCalc.exVarInfo -> context

  val insertBtvEnv : context -> AnnotatedTypes.btvEnv -> context

  val lookupVariable : context  -> TypedLambda.varInfo -> Loc.loc -> AnnotatedCalc.varInfo

  val lookupExVar : context -> TypedLambda.exVarInfo -> Loc.loc -> AnnotatedCalc.exVarInfo

  val lookupTid : context -> BoundTypeVarID.id -> AnnotatedTypes.btvKind

  val fieldType : context -> (AnnotatedTypes.ty * string) -> AnnotatedTypes.ty

end
