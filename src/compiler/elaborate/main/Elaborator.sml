(*
 * Elaborator.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @version $Id: Elaborator.sml,v 1.105.6.8 2010/02/10 05:17:29 hiro-en Exp $
 *)
structure Elaborator =
struct

  structure UE = UserError
  structure EU = UserErrorUtils

  structure A = AbsynInterface
  structure P = PatternCalcInterface

  type fixEnv = Fixity.fixity SEnv.map

  fun extendFixEnv (env1:fixEnv, env2:fixEnv) : fixEnv =
      SEnv.unionWith #2 (env1, env2)

  fun elaborate fixEnv ({interface, topdecsInclude, topdecsSource}:A.compileUnit) =
      let
        val _ = EU.initializeErrorQueue ()

        val (fixEnv, interface) =
            case interface of
              NONE => (fixEnv, NONE)
            | SOME interface => 
              let
                val (requireFixEnv, interface) =
                    ElaborateInterface.elaborate interface
                val interface = UserTvarScope.decideInterface interface
              in
                (extendFixEnv (fixEnv, requireFixEnv), SOME interface)
              end

        val (ptopdeclsInclude, topdecFixEnvInclude) =
            ElaborateModule.elabTopDecs fixEnv topdecsInclude
        val ptopdeclsInclude = UserTvarScope.decide ptopdeclsInclude

        val (ptopdeclsSource, topdecFixEnvSource) =
            ElaborateModule.elabTopDecs fixEnv topdecsSource
        val ptopdeclsSource = UserTvarScope.decide ptopdeclsSource

        val topdecFixEnv = extendFixEnv(topdecFixEnvInclude, topdecFixEnvSource)

        val resultFixEnv = topdecFixEnv
        val plunit = {interface = interface,
                      topdecsInclude = ptopdeclsInclude,
                      topdecsSource = ptopdeclsSource}
      in
        case EU.getErrors () of
          nil => (resultFixEnv, plunit, EU.getWarnings ())
        | _::_ =>
          raise UE.UserErrors (EU.getErrorsAndWarnings ())
      end

  fun elaborateInteractiveEnv
        fixEnv
        ({interface, interfaceDecls, topdecsInclude}:A.interactiveUnit) =
      let
        val _ = EU.initializeErrorQueue ()
        val (requireFixEnv, interface) =
            ElaborateInterface.elaborate interface
        val interface = UserTvarScope.decideInterface interface
        val fixEnv = extendFixEnv (fixEnv, requireFixEnv)
        val (ptopdeclsInclude, topdecFixEnvInclude) =
            ElaborateModule.elabTopDecs fixEnv topdecsInclude
        val ptopdeclsInclude = UserTvarScope.decide ptopdeclsInclude
        val (interfaceDeclsFixEnv, interfaceDecls) =
            ElaborateInterface.elaborateTopdecList interfaceDecls
        val interfaceDecls = UserTvarScope.decidePitopdecs interfaceDecls
        val resultFixEnv = extendFixEnv (topdecFixEnvInclude, interfaceDeclsFixEnv)
        val interactiveUnit = {interface = interface,
                               topdecsInclude = ptopdeclsInclude,
                               interfaceDecls = interfaceDecls}
      in
        case EU.getErrors () of
          nil => (resultFixEnv, interactiveUnit, EU.getWarnings ())
        | _::_ =>
          raise UE.UserErrors (EU.getErrorsAndWarnings ())
      end

end
