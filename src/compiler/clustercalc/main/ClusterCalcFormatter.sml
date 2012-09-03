(**
 * a pretty printer for the cluster calclulus.
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: ClusterCalcFormatter.sml,v 1.2 2007/04/18 08:57:12 ducnh Exp $
 *)
structure ClusterCalcFormatter : CLUSTERCALCFORMATTER =
struct
    fun ccexpToString exp = 
      Control.prettyPrint (ClusterCalc.format_ccexp exp)

    fun ccdeclToString decl = 
      Control.prettyPrint (ClusterCalc.format_ccdecl decl)

end
