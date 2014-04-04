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
                  SymbolEnv.insert(fundeclEnv, functorSymbol, funbind)
            )
            SymbolEnv.empty
            provideList
      in
        fundeclEnv
      end

  fun spliceFunbind (funbind as {name, ...}, (funbindsRev, fundeclEnv)) =
      let
        val (fundeclEnv, providedecl) = SymbolEnv.remove(fundeclEnv, name)
      in
        ({pltopdec=funbind, pitopdec=SOME providedecl}::funbindsRev, fundeclEnv)
      end
      handle LibBase.NotFound => ({pltopdec=funbind, pitopdec=NONE}::funbindsRev, fundeclEnv)

  fun spliceTopdec (topdec, (topdecRev, fundeclEnv)) =
      case topdec of
        PL.PLTOPDECSTR (plstrdec, loc) => (PI.TOPDECSTR (plstrdec, loc)::topdecRev, fundeclEnv)
      | PL.PLTOPDECSIG (sigdeclList, loc) => (PI.TOPDECSIG (sigdeclList, loc)::topdecRev, fundeclEnv)
      | PL.PLTOPDECFUN (funbindList, loc) =>
        let
          val (funbindListRev, fundeclEnv) = foldl spliceFunbind (nil,fundeclEnv) funbindList 
        in
          (PI.TOPDECFUN (List.rev funbindListRev, loc)::topdecRev, fundeclEnv)
        end

  fun spliceProvideFundecl ({interface,
                             topdecsInclude,
                             topdecsSource} :PI.compileUnit) 
      : PI.source =
      let
        val provideTopdecs  =
            case interface of NONE => nil
                            | SOME {provideTopdecs, ...} => provideTopdecs
        val fundeclEnv = filterFundecls provideTopdecs
        val (topdecsIncludeRev, fundeclEnv) =
            foldl
            spliceTopdec
            (nil, fundeclEnv)
            topdecsInclude
        val (topdecsSourceRev, fundeclEnv) =
            foldl
            spliceTopdec
            (nil, fundeclEnv)
            topdecsSource
        val _ = SymbolEnv.app 
                  (fn {functorSymbol, ...} =>
                      EU.enqueueError
                        (Symbol.symbolToLoc functorSymbol,
                         E.ProvideUndefinedFunctor("200",{symbol=functorSymbol}))
                  )
                  fundeclEnv
      in
        {interface = interface,
         topdecsInclude = List.rev topdecsIncludeRev,
         topdecsSource = List.rev topdecsSourceRev}
      end
end
end
