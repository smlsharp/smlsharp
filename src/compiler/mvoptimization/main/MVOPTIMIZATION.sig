(**
 * multiplevaluecalc optimization
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
signature MVOPTIMIZATION = sig

    val optimize :  MultipleValueCalc.mvdecl list
                    -> MultipleValueCalc.mvdecl list

end
