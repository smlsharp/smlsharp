(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure SpliceProvicdeFundecl =
struct
local
  structure PL = PatternCalc
  structure PI = PatternCalcInterface
  structure EU = UserErrorUtils
  structure E = NameEvalError
in
  fun filterFundecls provideList =
      let
        val fundeclEnv =
            foldl
            (fn (pitopdec, fundeclEnv) =>
                case pitopdec of
                  PI.PIDEC _ => fundeclEnv
                | PI.PIFUNDEC (funbind as {functorSymbol,...}) => 
                  Symbol.Map.insert(fundeclEnv, #symbol functorSymbol, funbind)
            )
            Symbol.Map.empty
            provideList
      in
        fundeclEnv
      end

  fun spliceFunbind (funbind as {name, ...}, (funbindsRev, fundeclEnv)) =
      let
        val (fundeclEnv, providedecl) = Symbol.Map.remove(fundeclEnv, #symbol name)
      in
        ({pltopdec=funbind, pitopdec=SOME providedecl}::funbindsRev, fundeclEnv)
      end
      handle LibBase.NotFound => ({pltopdec=funbind, pitopdec=NONE}::funbindsRev, fundeclEnv)

  fun spliceTopdec (topdec, (topdecRev, fundeclEnv)) =
      case topdec of
        PL.PLTOPDECSTR plstrdec => (PI.TOPDECSTR plstrdec::topdecRev, fundeclEnv)
      | PL.PLTOPDECSIG (sigdeclList, loc) =>
        (PI.TOPDECSIG (sigdeclList, loc)::topdecRev, fundeclEnv)
      | PL.PLTOPDECFUN (funbindList, loc) =>
        let
          val (funbindListRev, fundeclEnv) = foldl spliceFunbind (nil,fundeclEnv) funbindList 
        in
          (PI.TOPDECFUN (List.rev funbindListRev, loc)::topdecRev, fundeclEnv)
        end

  fun spliceProvideFundecl ({interface, topdecsSource} : PI.compile_unit)
      : PI.compile_unit_spliced =
      let
        val {provideTopdecs, topdecsInclude, ...} = interface
        val fundeclEnv = filterFundecls provideTopdecs
        val (topdecsIncludeRev, fundeclEnv) =
            foldl
            spliceTopdec
            (nil, fundeclEnv)
            (map PL.PLTOPDECSIG topdecsInclude)
        val (topdecsSourceRev, fundeclEnv) =
            foldl
            spliceTopdec
            (nil, fundeclEnv)
            topdecsSource
        val _ = Symbol.Map.app
                  (fn {functorSymbol, ...} =>
                      EU.enqueueError
                        (#loc functorSymbol,
                         E.ProvideUndefinedFunctor("200",{symbol= #symbol functorSymbol}))
                  )
                  fundeclEnv
      in
        {interface = interface,
         topdecsInclude = List.rev topdecsIncludeRev,
         topdecsSource = List.rev topdecsSourceRev}
      end
end
end
