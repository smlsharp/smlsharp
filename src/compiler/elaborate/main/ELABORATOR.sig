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
 * @version $Id: ELABORATOR.sig,v 1.10 2007/01/21 13:41:32 kiyoshiy Exp $
 *)
signature ELABORATOR =
sig

  (***************************************************************************)

  val elaborate :
      Fixity.fixity SEnv.map
      -> Absyn.topdec list
      -> PatternCalc.pltopdec list
         * Fixity.fixity SEnv.map
         * UserError.errorInfo list

  (***************************************************************************)

end
