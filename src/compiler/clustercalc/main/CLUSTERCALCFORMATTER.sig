(**
 * a pretty printer for the cluster calclulus.
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: CLUSTERCALCFORMATTER.sig,v 1.2 2007/04/18 08:57:12 ducnh Exp $
 *)
signature CLUSTERCALCFORMATTER =
sig
    val ccexpToString : ClusterCalc.ccexp -> string

    val ccdeclToString : ClusterCalc.ccdecl -> string

end
