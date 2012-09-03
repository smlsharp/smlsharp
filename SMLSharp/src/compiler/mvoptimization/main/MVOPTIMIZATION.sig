(**
 * multiplevaluecalc optimization
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
signature MVOPTIMIZATION = sig

    val optimize : Counters.stamp
                   -> MultipleValueCalc.topBlock list
                   -> Counters.stamp * MultipleValueCalc.topBlock list

end
