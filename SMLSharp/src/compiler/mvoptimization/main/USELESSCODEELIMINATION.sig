(**
 * Useless code elimination
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
signature USELESSCODEELIMINATION = sig

  val optimize : MultipleValueCalc.topBlock list -> MultipleValueCalc.topBlock list

end
