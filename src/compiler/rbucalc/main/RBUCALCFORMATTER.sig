(**
 * a pretty printer for the rbucalc
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: RBUCALCFORMATTER.sig,v 1.2 2007/04/18 09:06:08 ducnh Exp $
 *)
signature RBUCALCFORMATTER =
sig
    val rbuexpToString : RBUCalc.rbuexp -> string

    val rbudeclToString : RBUCalc.rbudecl -> string

end
