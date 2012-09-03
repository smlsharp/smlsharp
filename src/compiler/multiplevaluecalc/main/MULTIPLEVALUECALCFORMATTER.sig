(**
 * a pretty printer for the multiple value calclulus.
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: MULTIPLEVALUECALCFORMATTER.sig,v 1.3 2008/02/23 15:49:53 bochao Exp $
 *)
signature MULTIPLEVALUECALCFORMATTER =
sig
    val mvexpToString : MultipleValueCalc.mvexp -> string

    val mvdeclToString : MultipleValueCalc.mvdecl -> string

end
