(**
 * a pretty printer for the multiple value calclulus.
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: MULTIPLEVALUECALCFORMATTER.sig,v 1.2 2007/04/18 09:04:00 ducnh Exp $
 *)
signature MULTIPLEVALUECALCFORMATTER =
sig
    val mvexpToString : MultipleValueCalc.mvexp -> string

    val mvdeclToString : MultipleValueCalc.mvdecl -> string

end
