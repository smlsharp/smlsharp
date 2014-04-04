(**
 * ElaboratorInterface.sml
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
(*
sig
  type fixEnv
  val elaborate
    : AbsynInterface.interface
       -> {requireFixEnv: fixEnv, provideFixEnv: fixEnv}
          * PatternCalcInterface.interface
end
*)
structure ElaborateInterface =
struct

  structure EU = UserErrorUtils
  structure E = ElaborateError

  structure I = AbsynInterface
  structure P = PatternCalcInterface
  structure PC = PatternCalc
  val symbolToString = Symbol.symbolToString
  val longsymbolToLongid = Symbol.longsymbolToLongid
  val symbolToLoc = Symbol.symbolToLoc
  val mkSymbol = Symbol.mkSymbol

  type fixEnv = Fixity.fixity SEnv.map

  fun checkSigexp sigexp =
      case sigexp of
        PC.PLSIGEXPBASIC (spec, loc) => checkSpec spec
      | PC.PLSIGID symbol =>
        EU.enqueueError
          (symbolToLoc symbol, 
           E.SigIDFoundInInterface (symbolToString symbol))
      | PC.PLSIGWHERE (sigexp, typbinds, loc) => checkSigexp sigexp

  and checkSpec spec =
      case spec of
        PC.PLSPECVAL _ => ()
      | PC.PLSPECTYPE _ => ()
      | PC.PLSPECTYPEEQUATION _ => ()
      | PC.PLSPECDATATYPE _ => ()
      | PC.PLSPECREPLIC _ => ()
      | PC.PLSPECEXCEPTION _ => ()
      | PC.PLSPECSTRUCT (strdecs, loc) =>
        app (fn (symbol, sigexp) => checkSigexp sigexp) strdecs
      | PC.PLSPECINCLUDE (sigexp, loc) => checkSigexp sigexp
      | PC.PLSPECSEQ (spec1, spec2, loc) =>
        (checkSpec spec1; checkSpec spec2)
      | PC.PLSPECSHARE (spec, ids, loc) => checkSpec spec
      | PC.PLSPECSHARESTR (spec, ids, loc) => checkSpec spec
      | PC.PLSPECEMPTY => ()

  fun elabSigexp sigexp =
      let
        val sigexp = ElaborateModule.elabSigExp sigexp
(*
        val sigexp = UserTvarScope.decideSigexp sigexp
*)
        val _ = checkSigexp sigexp
      in
        sigexp
      end

(*
  fun tyvarsOverloadInstance inst =
      case inst of
        P.INST_OVERLOAD overloadCase => tyvarsOverloadCase overloadCase
      | P.INST_LONGVID {longsymbol} => UserTvarScope.empty

  and tyvarsOverloadMatch {instTy, instance} =
      UserTvarScope.union (UserTvarScope.ftv instTy,
                            tyvarsOverloadInstance instance)
  and tyvarsOverloadCase ({tyvar, expTy, matches, loc}:P.overloadCase) =
      UserTvarScope.union
        (UserTvarScope.union (UserTvarScope.singleton (tyvar, loc),
                              UserTvarScope.ftv expTy),
         UserTvarScope.tyvarsList tyvarsOverloadMatch matches)

  fun tyvarsValbindBody body =
      case body of
        P.VAL_EXTERN {ty} => UserTvarScope.ftv ty
      | P.VALALIAS_EXTERN longsymbol => UserTvarScope.empty
      | P.VAL_BUILTIN {builtinSymbol, ty} => UserTvarScope.ftv ty
      | P.VAL_OVERLOAD overloadCase => tyvarsOverloadCase overloadCase

  fun checkUniqueOverloadTvars used ({tyvar, expTy, matches, loc}
                                     :P.overloadCase) =
      let
        val _ =
            if UserTvarScope.member (used, tyvar)
            then (EU.enqueueError
                   (loc, E.UserTvarScopedAtOuterDecl
                           {tvar = tyvar}))
            else ()
        val set =
            UserTvarScope.union
              (UserTvarScope.singleton (tyvar, loc),
               UserTvarScope.ftv expTy)
        val used = UserTvarScope.union (used, set)
      in
        app (fn {instTy, instance} =>
                case instance of
                  P.INST_OVERLOAD c => checkUniqueOverloadTvars used c
                | P.INST_LONGVID _ => ())
            matches
      end
  fun elabValbindBody body =
      case body of
        P.VAL_EXTERN _ => body
      | P.VALALIAS_EXTERN _ => body
      | P.VAL_BUILTIN _ => body
      | P.VAL_OVERLOAD c =>
        (checkUniqueOverloadTvars UserTvarScope.empty c; body)

*)
  fun elabValbind ({symbol, body, loc}:I.valbind) =
      let
        val _ = ElaborateCore.checkReservedNameForValBind symbol
(*
        val body = elabValbindBody body
        val tvset = tyvarsValbindBody body
        val tvars = UserTvarScope.toTvarList tvset
*)
      in
        P.PIVAL {scopedTvars = nil, symbol = symbol, body = body, loc = loc}
      end

  fun elabExbind exbind =
      case exbind of
        I.EXNDEF {symbol, ty, loc} => 
        (ElaborateCore.checkReservedNameForConstructorBind symbol;
         P.PIEXCEPTION {symbol= symbol, ty=ty, loc=loc})
      | I.EXNREP {symbol, longsymbol, loc} =>
        (ElaborateCore.checkReservedNameForConstructorBind symbol;
         P.PIEXCEPTIONREP {symbol= symbol, longsymbol= longsymbol, loc=loc})

  fun elabTypbind typbind =
      case typbind of 
      I.TRANSPARENT {tyvars, symbol, ty, loc} => 
      P.PITYPE {tyvars=tyvars, symbol = symbol, ty=ty, loc=loc}
    | I.OPAQUE_NONEQ {tyvars, symbol, runtimeTy, loc} =>
      let
        val runtimeTy = 
            case longsymbolToLongid runtimeTy of 
              [name] =>
              (case BuiltinTypeNames.findType name of
                 SOME ty => P.BUILTINty ty
               | NONE => P.LIFTEDty runtimeTy
              )
            | _ => P.LIFTEDty runtimeTy
      in
        P.PIOPAQUE_TYPE 
          {tyvars=tyvars, symbol= symbol, runtimeTy=runtimeTy, loc=loc}
      end
    | I.OPAQUE_EQ {tyvars, symbol, runtimeTy, loc} =>
      let
        val runtimeTy = 
            case longsymbolToLongid runtimeTy of 
              [name] => 
              (case BuiltinTypeNames.findType name of
                 SOME ty => P.BUILTINty ty
               | NONE => P.LIFTEDty runtimeTy)
            | _ => P.LIFTEDty runtimeTy
      in
        P.PIOPAQUE_EQTYPE 
          {tyvars=tyvars, symbol= symbol, runtimeTy=runtimeTy, loc=loc}
      end

  fun elabDec dec =
      case dec of
        I.IVAL valbind => map elabValbind valbind
      | I.ITYPE typbindList => map elabTypbind typbindList
      | I.IDATATYPE {datbind, loc} =>
        (app (fn {tyvars, symbol, conbind} =>
                 (EU.checkSymbolDuplication
                    (fn {symbol, ty} => symbol)
                    conbind
                    E.DuplicateConstructorNameInDatatype;
                  app (fn {symbol, ty} =>
                          ElaborateCore.checkReservedNameForValBind symbol)
                      conbind))
             datbind;
         [P.PIDATATYPE {datbind=datbind, loc=loc}])
      | I.ITYPEREP {loc, longsymbol, symbol} => 
        [P.PITYPEREP {loc=loc, longsymbol = longsymbol, symbol= symbol}]
      | I.ITYPEBUILTIN {builtinSymbol, loc, symbol} => 
        [P.PITYPEBUILTIN {builtinSymbol= builtinSymbol, loc=loc, symbol= symbol}]
      | I.IEXCEPTION exbind => map elabExbind exbind
      | I.ISTRUCTURE strbind => [elabStrbind strbind]

  and elabStrbind ({symbol, strexp, loc}:I.strbind) =
      P.PISTRUCTURE {symbol = symbol,
                     strexp = elabStrexp strexp,
                     loc = loc}

  and elabStrexp strexp =
      case strexp of
        I.ISTRUCT {decs, loc} =>
        P.PISTRUCT {decs = List.concat (map elabDec decs), loc = loc}
      | I.ISTRUCTREP{longsymbol, loc} => P.PISTRUCTREP{longsymbol= longsymbol, loc=loc}
      | I.IFUNCTORAPP{functorSymbol, argument, loc} => 
        P.PIFUNCTORAPP{functorSymbol= functorSymbol, argument= argument, loc=loc}

  fun elabFunbind ({functorSymbol, param, strexp, loc}:I.funbind) =
      let
        val strexp = elabStrexp strexp
        val param =
            case param of
              I.FUNPARAM_FULL {symbol, sigexp} =>
              {strSymbol = symbol, sigexp = elabSigexp sigexp}
            | I.FUNPARAM_SPEC spec =>
              let
                val dummySym = mkSymbol "" loc
              in
                (EU.enqueueError
                   (loc, E.DerivedFormFunArg);
                 {strSymbol = dummySym, sigexp = PatternCalc.PLSIGID dummySym}
                )
              end
      in
        P.PIFUNDEC {functorSymbol = functorSymbol,
                    param = param,
                    strexp = strexp,
                    loc = loc}
      end

  fun elabTopdec fixEnv itopdec =
      case itopdec of
      I.IDEC dec =>
      (SEnv.empty, map P.PIDEC (elabDec dec))
    | I.IFUNDEC funbind =>
      (SEnv.empty, [elabFunbind funbind])
    | I.IINFIX {fixity, symbols, loc} =>
      let
        val fixity =
            case fixity of
              I.INFIXL NONE => Fixity.INFIX 0
            | I.INFIXL (SOME n) =>
              Fixity.INFIX (ElaborateCore.elabInfixPrec (n, loc))
            | I.INFIXR NONE => Fixity.INFIXR 0
            | I.INFIXR (SOME n) =>
              Fixity.INFIXR (ElaborateCore.elabInfixPrec (n, loc))
            | I.NONFIX => Fixity.NONFIX

        (* check duplicate declarations *)
        val _ =
            app (fn symbol =>
                    case SEnv.find (fixEnv, symbolToString symbol) of
                      SOME (fixity1, loc1) =>
                      if fixity = fixity1 then ()
                      else EU.enqueueError
                             (loc, E.MultipleInfixInInterface
                                     (symbolToString symbol, loc))
                    | NONE => ())
                symbols

        val fixEnv =
            foldl (fn (symbol,z) => SEnv.insert (z, symbolToString symbol, (fixity, loc)))
                  SEnv.empty
                  symbols
      in
        (fixEnv, nil)
      end

  and elabTopdecList fixEnv nil = (SEnv.empty, nil)
    | elabTopdecList fixEnv (dec::decs) =
      let
        val (newFixEnv1, dec) = elabTopdec fixEnv dec
        val fixEnv = SEnv.unionWith #2 (fixEnv, newFixEnv1)
        val (newFixEnv2, decs) = elabTopdecList fixEnv decs
      in
        (SEnv.unionWith #2 (newFixEnv1, newFixEnv2), dec @ decs)
      end

  fun elabInterfaceDec fixEnv ({interfaceId, interfaceName, requiredIds, provideTopdecs}
                               :I.interfaceDec) =
      let
        val (newFixEnv, provideTopdecs) = elabTopdecList fixEnv provideTopdecs
      in
        (newFixEnv,
         {interfaceId = interfaceId,
          requiredIds = requiredIds,
          provideTopdecs = provideTopdecs} : P.interfaceDec)
      end

  fun elabInterfaceDecs fixEnv nil = (InterfaceID.Map.empty, nil)
    | elabInterfaceDecs fixEnv (dec::decs) =
      let
        val (newFixEnv, dec) = elabInterfaceDec fixEnv dec
        val fixEnvMap1 = InterfaceID.Map.singleton (#interfaceId dec, newFixEnv)
        val fixEnv = SEnv.unionWith #2 (fixEnv, newFixEnv)
        val (fixEnvMap2, decs) = elabInterfaceDecs fixEnv decs
        val fixEnvMap = InterfaceID.Map.unionWith #2 (fixEnvMap1, fixEnvMap2)
      in
        (fixEnvMap, dec::decs)
      end

  fun toFixEnv env =
      SEnv.map (fn (x, _:I.loc) => x) env : fixEnv

  fun elaborate ({interfaceDecs, provideInterfaceNameOpt, requiredIds, provideTopdecs}:I.interface) =
      let
        val (fixEnvMap, newDecls) =
            elabInterfaceDecs SEnv.empty interfaceDecs
        val allFixEnv =
            InterfaceID.Map.foldl (SEnv.unionWith #2) SEnv.empty fixEnvMap
        val (provideFixEnv, provideTopdecs) = elabTopdecList allFixEnv provideTopdecs
        val interface =
            {
              interfaceDecs = newDecls,
              requiredIds = requiredIds,
              provideTopdecs = provideTopdecs
            }
            : P.interface

        val requireFixEnv =
            foldl (fn ({id, loc}, z) =>
                      case InterfaceID.Map.find (fixEnvMap, id) of
                        SOME env => SEnv.unionWith #2 (z, env)
                      | NONE => raise Bug.Bug "elaborate: interface not found")
                  SEnv.empty
                  requiredIds
      in
        (toFixEnv requireFixEnv, interface)
      end

  fun elaborateTopdecList decs =
      let
        val (fixEnv, decs) = elabTopdecList SEnv.empty decs
      in
        (toFixEnv fixEnv, decs)
      end

end
