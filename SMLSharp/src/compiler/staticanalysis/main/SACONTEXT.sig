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

  val insertBtvEnv : context -> AnnotatedTypes.btvEnv -> context

  val lookupVariable : context  -> VarID.id -> (string * Loc.loc) -> AnnotatedCalc.varInfo

  val lookupTid : context -> int -> AnnotatedTypes.btvKind

  val fieldType : context -> (AnnotatedTypes.ty * string) -> AnnotatedTypes.ty

end
