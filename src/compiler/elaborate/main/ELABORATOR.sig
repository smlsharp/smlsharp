(**
 * Elaborator.
 * <p>
 * In this pahse, we do the following:
 * <ol>
 *   <li>infix elaboration</li>
 *   <li>expand derived form (incomplete; revise later)</li>
 * </ol>
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: ELABORATOR.sig,v 1.16 2008/08/06 17:23:39 ohori Exp $
 *)
signature ELABORATOR =
sig

  type fixEnv 

  val extendFixEnv : fixEnv * fixEnv -> fixEnv

  val elaborate :
      fixEnv
      -> AbsynInterface.compileUnit
      -> fixEnv * PatternCalcInterface.compileUnit * UserError.errorInfo list

  val elaborateRequire :
      AbsynInterface.compileUnit
      -> fixEnv * PatternCalcInterface.compileUnit * UserError.errorInfo list

end
