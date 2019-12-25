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
  structure E = ElaborateError

  type fixEnv = Fixity.fixity SymbolEnv.map

  fun extendFixEnv (env1:fixEnv, env2:fixEnv) : fixEnv =
      SymbolEnv.unionWith #2 (env1, env2)

  fun fixEnvToLocEnv (env:fixEnv) =
      SymbolEnv.mapi (fn (k, _) => Symbol.symbolToLoc k) env

  fun elaborate fixEnv ({interface, topdecsSource}:A.compile_unit) =
      let
        val _ = EU.initializeErrorQueue ()
        val (interface, requireFixEnv, provideFixEnv, topdecsInclude) =
            case interface of
              NONE => (NONE, SymbolEnv.empty, SymbolEnv.empty, nil)
            | SOME interface =>
              case ElaborateInterface.elaborate interface of
                {interface, requireFixEnv, provideFixEnv, topdecsInclude} =>
                (SOME interface, requireFixEnv, provideFixEnv, topdecsInclude)

        val interface = Option.map UserTvarScope.decideInterface interface
        val fixEnv = extendFixEnv (fixEnv, requireFixEnv)
        val (ptopdecsInclude, topdecsIncludeFixEnv) =
            ElaborateModule.elabTopDecs fixEnv topdecsInclude
        val ptopdecsInclude = UserTvarScope.decide ptopdecsInclude
        val fixEnv = extendFixEnv (fixEnv, topdecsIncludeFixEnv)
        val (ptopdecsSource, topdecsSourceFixEnv) =
            ElaborateModule.elabTopDecs fixEnv topdecsSource
        val ptopdecsSource = UserTvarScope.decide ptopdecsSource

        (* provide check *)
        val _ =
            SymbolEnv.mergeWithi
              (fn (k, x as SOME loc, NONE) =>
                  (EU.enqueueError (loc, E.ProvideInfixNotDefined k); x)
                | (k, x, y) => x)
              (fixEnvToLocEnv provideFixEnv, fixEnvToLocEnv topdecsSourceFixEnv)

        val plunit : PatternCalcInterface.compile_unit =
            {interface = interface,
             topdecsInclude = ptopdecsInclude,
             topdecsSource = ptopdecsSource}
      in
        case EU.getErrors () of
          nil => (topdecsSourceFixEnv, plunit, EU.getWarnings ())
        | _::_ =>
          raise UE.UserErrors (EU.getErrorsAndWarnings ())
      end

  fun elaborateInterface
        fixEnv
        ({interfaceDecs, requiredIds, topdecsInclude}:A.interface_unit) =
      let
        val _ = EU.initializeErrorQueue ()
        val {interface, requireFixEnv, provideFixEnv, topdecsInclude} =
            ElaborateInterface.elaborate
              {interfaceDecs = interfaceDecs,
               provide = {requiredIds = requiredIds,
                          locallyRequiredIds = nil,
                          provideTopdecs = nil,
                          topdecsInclude = topdecsInclude}}
        val interface = UserTvarScope.decideInterface interface
        val fixEnv = extendFixEnv (fixEnv, requireFixEnv)
        val (ptopdecsInclude, topdecsIncludeFixEnv) =
            ElaborateModule.elabTopDecs fixEnv topdecsInclude
        val ptopdecsInclude = UserTvarScope.decide ptopdecsInclude
        val resultFixEnv = extendFixEnv (requireFixEnv, topdecsIncludeFixEnv)
        val plunit =
            {interfaceDecs = #interfaceDecs interface,
             requiredIds = #requiredIds interface,
             topdecsInclude = ptopdecsInclude}
      in
        case EU.getErrors () of
          nil => (resultFixEnv, plunit, EU.getWarnings ())
        | _::_ =>
          raise UE.UserErrors (EU.getErrorsAndWarnings ())
      end

end
