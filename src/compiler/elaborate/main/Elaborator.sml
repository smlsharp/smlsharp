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

  type fixEnv = Fixity.fixity SEnv.map

  fun extendFixEnv (env1:fixEnv, env2:fixEnv) : fixEnv =
      SEnv.unionWith #2 (env1, env2)

  fun elaborateCompileUnit fixEnv {interface, topdecs} =
      let
        val _ = ElaboratorUtils.initializeErrorQueue ()

        val ({requireFixEnv, provideFixEnv}, interface) =
            ElaborateInterface.elaborate interface
        val fixEnv = extendFixEnv (fixEnv, requireFixEnv)
        val (ptopdecls, topdecFixEnv) =
            ElaborateModule.elabTopDecs fixEnv topdecs
        val ptopdecls = UserTvarScope.decide ptopdecls
        val plunit = {interface = interface, topdecs = ptopdecls}
      in
        case ElaboratorUtils.getErrors () of
          nil => (requireFixEnv, provideFixEnv, topdecFixEnv,
                  plunit, ElaboratorUtils.getWarnings ())
        | _::_ =>
          raise UserError.UserErrors (ElaboratorUtils.getErrorsAndWarnings ())
      end

  fun elaborate fixEnv abunit =
      let
        val (requireFixEnv, provideFixEnv, topdecFixEnv, plunit, warnings) =
            elaborateCompileUnit fixEnv abunit
      in
        (topdecFixEnv, plunit, warnings)
(*
        (provideFixEnv, plunit, warnings)
*)
      end

  fun elaborateRequire abunit =
      let
        val (requireFixEnv, provideFixEnv, topdecFixEnv, plunit, warnings) =
            elaborateCompileUnit SEnv.empty abunit
      in
        (extendFixEnv (requireFixEnv, topdecFixEnv), plunit, warnings)
      end

end
