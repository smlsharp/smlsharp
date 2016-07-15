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

  type fixEnv = Fixity.fixity SymbolEnv.map

  fun extendFixEnv (env1:fixEnv, env2:fixEnv) : fixEnv =
      SymbolEnv.unionWith #2 (env1, env2)

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
        val fixEnv = extendFixEnv (fixEnv, topdecFixEnvInclude)

        val (ptopdeclsSource, topdecFixEnvSource) =
            ElaborateModule.elabTopDecs fixEnv topdecsSource
        val ptopdeclsSource = UserTvarScope.decide ptopdeclsSource

        val plunit = {interface = interface,
                      topdecsInclude = ptopdeclsInclude,
                      topdecsSource = ptopdeclsSource}
      in
        case EU.getErrors () of
          nil => (topdecFixEnvSource, plunit, EU.getWarnings ())
        | _::_ =>
          raise UE.UserErrors (EU.getErrorsAndWarnings ())
      end

  fun elaborateInterface
        fixEnv
        ({interfaceDecs, requiredIds, topdecsInclude}:A.interface_unit) =
      let
        val _ = EU.initializeErrorQueue ()
        val interface = {interfaceDecs = interfaceDecs,
                         provideInterfaceNameOpt = NONE,
                         requiredIds = requiredIds,
                         locallyRequiredIds = nil,
                         provideTopdecs = nil}
        val (fixEnvRequire, interface) =
            ElaborateInterface.elaborate interface
        val {interfaceDecs, requiredIds, ...} =
            UserTvarScope.decideInterface interface
        val fixEnv = extendFixEnv (fixEnv, fixEnvRequire)
        val (ptopdecsInclude, fixEnvInclude) =
            ElaborateModule.elabTopDecs fixEnv topdecsInclude
        val ptopdecsInclude = UserTvarScope.decide ptopdecsInclude
        val warnings =
            case EU.getErrors () of
              nil => EU.getWarnings ()
            | _::_ => raise UE.UserErrors (EU.getErrorsAndWarnings ())
      in
        (* return fixEnv for codes requiring this interface *)
        (extendFixEnv (fixEnvRequire, fixEnvInclude),
         {interfaceDecs = interfaceDecs,
          requiredIds = requiredIds,
          topdecsInclude = ptopdecsInclude},
         warnings)
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
