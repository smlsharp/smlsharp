(*
 * Elaborator.
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @version $Id: Elaborator.sml,v 1.105.6.8 2010/02/10 05:17:29 hiro-en Exp $
 *)
structure Elaborator =
struct

  structure UE = UserError
  structure EU = UserErrorUtils
  structure A = AbsynInterfaceLoaded
  structure E = ElaborateError
  datatype loc = datatype Loc.loc

  type fix_env = (Fixity.fixity * Absyn.loc) Symbol.Map.map

  fun extendFixEnv (env1, env2) : fix_env =
      Symbol.Map.unionWith #2 (env1, env2)

  fun elaborate fixEnv ({interface, topdecsSource} : A.compile_unit) =
      let
        val _ = EU.initializeErrorQueue ()
        val (interface, requireFixEnv, provideFixEnv, topdecsInclude) =
            case interface of
              NONE => (NONE, Symbol.Map.empty, Symbol.Map.empty, nil)
            | SOME interface =>
              case ElaborateInterface.elaborate interface of
                {interface, requireFixEnv, provideFixEnv, topdecsInclude} =>
                (SOME interface, requireFixEnv, provideFixEnv, topdecsInclude)

        val fixEnv = extendFixEnv (fixEnv, requireFixEnv)
        val (topdecsIncludeFixEnv, topdecsInclude) =
            ResolveInfix.resolveTopdecs fixEnv topdecsInclude
        val topdecsInclude = UserTvarScope.decideTopdecs topdecsInclude
        val ptopdecsInclude = ElaborateModule.elabTopdecs topdecsInclude
        val fixEnv = extendFixEnv (fixEnv, topdecsIncludeFixEnv)
        val (topdecsSourceFixEnv, topdecsSource) =
            ResolveInfix.resolveTopdecs fixEnv topdecsSource
        val topdecsSource = UserTvarScope.decideTopdecs topdecsSource
        val ptopdecsSource = ElaborateModule.elabTopdecs topdecsSource

        (* provide check *)
        val _ =
            Symbol.Map.mergeWithi
              (fn (k, x as SOME (_, loc), NONE) =>
                  (EU.enqueueError (LOC loc, E.ProvideInfixNotDefined k); x)
                | (k, SOME (fix1, _), x as SOME (fix2, loc)) =>
                  if fix1 = fix2
                  then x
                  else (EU.enqueueError (LOC loc, E.ProvideInfixMismatch k); x)
                | (_, NONE, _) => NONE)
              (provideFixEnv, topdecsSourceFixEnv)

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
        ({interfaceDecs, requiredIds, topdecsInclude} : A.interface_unit) =
      let
        val _ = EU.initializeErrorQueue ()
        val {interface, requireFixEnv, provideFixEnv, topdecsInclude} =
            ElaborateInterface.elaborate
              {interfaceDecs = interfaceDecs,
               provide = {requiredIds = requiredIds,
                          locallyRequiredIds = nil,
                          provideTopdecs = nil,
                          topdecsInclude = topdecsInclude}}
        val fixEnv = extendFixEnv (fixEnv, requireFixEnv)
        val (topdecsIncludeFixEnv, topdecsInclude) =
            ResolveInfix.resolveTopdecs fixEnv topdecsInclude
        val topdecsInclude = UserTvarScope.decideTopdecs topdecsInclude
        val ptopdecsInclude = ElaborateModule.elabTopdecs topdecsInclude
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
