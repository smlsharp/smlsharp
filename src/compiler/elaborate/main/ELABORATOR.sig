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
 * @version $Id: ELABORATOR.sig,v 1.9 2006/02/28 16:11:01 kiyoshiy Exp $
 *)
signature ELABORATOR =
sig

  (***************************************************************************)

  val elaborate :
      StaticEnv.fixity SEnv.map ->
      Absyn.topdec list ->
      PatternCalc.pltopdec list * StaticEnv.fixity SEnv.map *  UserError.errorInfo list

  (***************************************************************************)

end
