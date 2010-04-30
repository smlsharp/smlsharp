(**
 * a pretty printer for the cluster calclulus.
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: ClusterCalcFormatter.sml,v 1.4 2008/01/28 03:12:11 katsu Exp $
 *)
structure ClusterCalcFormatter : CLUSTERCALCFORMATTER =
struct
local
    fun ccexpToStringTyped exp = 
      Control.prettyPrint (ClusterCalc.typedccexp exp)

    fun ccdeclToStringTyped decl = 
      Control.prettyPrint (ClusterCalc.typedccdecl decl)

    fun ccexpToString exp = 
      Control.prettyPrint (ClusterCalc.format_ccexp exp)

    fun ccdeclToString decl = 
      Control.prettyPrint (ClusterCalc.format_ccdecl decl)
in
    val ccexpToString = fn x =>
       (if !Control.printWithType then ccexpToStringTyped
        else ccexpToString) x
      
    val ccdeclToString = fn x =>
       (if !Control.printWithType then ccdeclToStringTyped
        else ccdeclToString) x
end
end
