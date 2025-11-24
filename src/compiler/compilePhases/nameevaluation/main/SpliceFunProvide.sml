(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure SpliceProvicdeFundecl =
struct
local
  structure PL = PatternCalc
  structure PI = PatternCalcInterface
  structure PI1 = PatternCalcInterface1
  structure EU = UserErrorUtils
  structure E = NameEvalError
  fun toSymbol (sym, loc) = {symbol = sym, loc = Loc.LOC loc}
in
  fun filterFundecls provideList =
      let
        val fundeclEnv =
            foldl
            (fn (pitopdec, fundeclEnv) =>
                case pitopdec of
                  PI.TOPDEC _ => fundeclEnv
                | PI.TOPFUNCTOR (funbind as {1=functorSymbol,...}) =>
                  Symbol.Map.insert(fundeclEnv, #1 functorSymbol, funbind)
            )
            Symbol.Map.empty
            provideList
      in
        fundeclEnv
      end

  fun spliceFunbind (funbind as {1=name, ...}, (funbindsRev, fundeclEnv)) =
      let
        val (fundeclEnv, providedecl) = Symbol.Map.remove(fundeclEnv, #1 name)
      in
        ({pltopdec=funbind, pitopdec=SOME providedecl}::funbindsRev, fundeclEnv)
      end
      handle LibBase.NotFound => ({pltopdec=funbind, pitopdec=NONE}::funbindsRev, fundeclEnv)

  fun spliceTopdec (topdec, (topdecRev, fundeclEnv)) =
      case topdec of
        PL.TOPSTRDEC plstrdec => (PI1.TOPDECSTR plstrdec::topdecRev, fundeclEnv)
      | PL.TOPSIGNATURE (sigdeclList, loc) =>
        (PI1.TOPDECSIG (map (fn (s,e,l) => (toSymbol s, e, l)) sigdeclList, loc)::topdecRev, fundeclEnv)
      | PL.TOPFUNCTOR (funbindList, loc) =>
        let
          val (funbindListRev, fundeclEnv) = foldl spliceFunbind (nil,fundeclEnv) funbindList 
        in
          (PI1.TOPDECFUN (List.rev funbindListRev, loc)::topdecRev, fundeclEnv)
        end

  fun spliceProvideFundecl ({interface, topdecsSource} : PI.compile_unit)
      : PI1.compile_unit_spliced =
      let
        val {provideTopdecs, topdecsInclude, ...} = interface
        val fundeclEnv = filterFundecls provideTopdecs
        val (topdecsIncludeRev, fundeclEnv) =
            foldl
            spliceTopdec
            (nil, fundeclEnv)
            (map PL.TOPSIGNATURE topdecsInclude)
        val (topdecsSourceRev, fundeclEnv) =
            foldl
            spliceTopdec
            (nil, fundeclEnv)
            topdecsSource
        val _ = Symbol.Map.app
                  (fn {1=functorSymbol, ...} =>
                      EU.enqueueError
                        (Loc.LOC (#2 functorSymbol),
                         E.ProvideUndefinedFunctor("200",{symbol= #1 functorSymbol}))
                  )
                  fundeclEnv
      in
        {interface = interface,
         topdecsInclude = List.rev topdecsIncludeRev,
         topdecsSource = List.rev topdecsSourceRev}
      end
end
end
