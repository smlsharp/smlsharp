(**
 * Static analysis
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
signature STATICANALYSIS = sig

  val analyse : (TypedLambda.tldecl list) -> (AnnotatedCalc.acdecl list)
end
