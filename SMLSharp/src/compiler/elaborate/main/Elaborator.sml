(*
 * Elaborator.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @version $Id: Elaborator.sml,v 1.105.6.8 2010/02/10 05:17:29 hiro-en Exp $
 *)
structure Elaborator : ELABORATOR =
struct
  fun elaborate {interface, topdecs} =
      let
        (* initiallize *)
        val _ = ElaboratorUtils.initializeErrorQueue ()

        val (fixEnv, interface) = ElaborateInterface.elaborate interface

        val (ptopdecls, env) = ElaborateModule.elabTopDecs fixEnv topdecs
        val ptopdecls = UserTvarScope.decide ptopdecls
        val plunit =
            {interface = interface,
             topdecs = ptopdecls}
            : PatternCalcInterface.compileUnit

      (* finalizne *)
      in
        case ElaboratorUtils.getErrors () of
          [] => (
                 plunit,
                 ElaboratorUtils.getWarnings ()
                 )
        | errors =>
          raise UserError.UserErrors (ElaboratorUtils.getErrorsAndWarnings ())
      end
      handle exn => raise exn
end
