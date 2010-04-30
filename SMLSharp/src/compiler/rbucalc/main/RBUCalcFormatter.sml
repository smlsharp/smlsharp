(**
 * a pretty printer for the rbucalc
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: RBUCalcFormatter.sml,v 1.4 2008/01/28 03:12:11 katsu Exp $
 *)
structure RBUCalcFormatter : RBUCALCFORMATTER =
struct
local
    fun rbuexpToString exp = 
      Control.prettyPrint (RBUCalc.format_rbuexp exp)

    fun rbuexpToStringTyped exp = 
      Control.prettyPrint (RBUCalc.typedrbuexp exp)

    fun rbudeclToString decl = 
      Control.prettyPrint (RBUCalc.format_rbudecl decl)

    fun rbudeclToStringTyped decl = 
      Control.prettyPrint (RBUCalc.typedrbudecl decl)
in
    val rbuexpToString = fn x =>
       (if !Control.printWithType then rbuexpToStringTyped
        else rbuexpToString) x
      
    val rbudeclToString = fn x =>
       (if !Control.printWithType then rbudeclToStringTyped
        else rbudeclToString) x
end
end
