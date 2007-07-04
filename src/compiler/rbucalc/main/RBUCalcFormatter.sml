(**
 * a pretty printer for the rbucalc
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: RBUCalcFormatter.sml,v 1.2 2007/04/18 09:06:08 ducnh Exp $
 *)
structure RBUCalcFormatter : RBUCALCFORMATTER =
struct
    fun rbuexpToString exp = 
      Control.prettyPrint (RBUCalc.format_rbuexp exp)

    fun rbudeclToString decl = 
      Control.prettyPrint (RBUCalc.format_rbudecl decl)

end
