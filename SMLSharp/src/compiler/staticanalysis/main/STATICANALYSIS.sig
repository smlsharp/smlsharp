(**
 * Static analysis
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
signature STATICANALYSIS = 
sig
  val analyse : TypedLambda.topBlock list -> AnnotatedCalc.topBlock list
end
