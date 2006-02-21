(**
 * Copyright (c) 2006, Tohoku University.
 *
 * Elaborator.
 * <p>
 * In this pahse, we do the following:
 * <ol>
 *   <li>infix elaboration</li>
 *   <li>expand derived form (incomplete; revise later)</li>
 * </ol>
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: ELABORATOR.sig,v 1.8 2006/02/18 04:59:21 ohori Exp $
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
