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
  structure T = AbsynTy
  structure P = PatternCalcInterface
  structure PC = PatternCalc
  val symbolToLoc = Symbol.symbolToLoc
  val mkSymbol = Symbol.mkSymbol

  type fixEnv = (Fixity.fixity * Loc.loc) SymbolEnv.map
  val emptyFixEnv = SymbolEnv.empty : fixEnv

  fun unionFixEnv (env1, env2) =
      SymbolEnv.mergeWithi
        (fn (k, x, NONE) => x
          | (k, NONE, x) => x
          | (k, x as (SOME _), y as (SOME _)) =>
            (EU.enqueueError
               (Symbol.symbolToLoc k, E.MultipleInfixInInterface k);
             y))
        (env1, env2)

  (* ToDo: integrate expandWithTypesInDataBind in ElaborateCore.sml *)
  type subst =
      {
        tyvar : T.ty SymbolEnv.map,
        tycon : I.typbind_trans SymbolEnv.map
      }

  fun maskTyvar ({tyvar, tycon}:subst) (tvars : T.tvar list) : subst =
      {tycon = tycon,
       tyvar = foldl (fn ({symbol, isEq}, z) =>
                         if SymbolEnv.inDomain (z, symbol)
                         then #1 (SymbolEnv.remove (z, symbol))
                         else z)
                     tyvar
                     tvars}

  fun tyconSubst typbinds : subst =
      {tyvar = SymbolEnv.empty,
       tycon = foldl (fn (x, z) => SymbolEnv.insert (z, #symbol x, x))
                     SymbolEnv.empty
                     typbinds}

  fun tyvarSubst pairs : subst =
      {tycon = SymbolEnv.empty,
       tyvar = foldl (fn ((x, ty), z) => SymbolEnv.insert (z, #symbol x, ty))
                     SymbolEnv.empty
                     pairs}

  fun substTy subst ty =
      case ty of
        T.TYWILD _ => ty
      | T.TYID (tvar as {symbol, isEq}, loc) =>
        (case SymbolEnv.find (#tyvar subst, symbol) of
           NONE => T.TYID (tvar, loc)
         | SOME ty => ty)
      | T.FREE_TYID _ => raise Bug.Bug "FREE_TYID to substTy in ElaborateInterface"
      | T.TYRECORD {ifFlex, fields, loc} =>
        T.TYRECORD {ifFlex = ifFlex, fields = substRecordTy subst fields, loc=loc}
      | T.TYCONSTRUCT (tyList, tyCon as [symbol], loc) =>
        (case SymbolEnv.find (#tycon subst, symbol) of
           NONE =>
           T.TYCONSTRUCT (map (substTy subst) tyList, tyCon, loc)
         | SOME {tyvars, symbol, ty, loc} =>
           substTy 
             (tyvarSubst
                (ListPair.zipEq (tyvars, tyList)
                 handle ListPair.UnequalLengths =>
                        (EU.enqueueError
                           (loc, E.ArityMismatchInTypeDeclaration
                                   {tyCon = symbol,
                                    wants = length tyvars,
                                    given = length tyList});
                         nil)))
             ty)
      | T.TYCONSTRUCT (tyList, tyCon, loc) =>
        T.TYCONSTRUCT (map (substTy subst) tyList, tyCon, loc)
      | T.TYTUPLE (tys, loc) =>
        T.TYTUPLE (map (substTy subst) tys, loc)
      | T.TYFUN (ty1, ty2, loc) =>
        T.TYFUN (substTy subst ty1, substTy subst ty2, loc)
      | T.TYPOLY (tvars, ty, loc) =>
        let
          val subst = maskTyvar subst (map #1 tvars)
        in
          T.TYPOLY (map (substTvar subst) tvars,
                    substTy subst ty,
                    loc)
        end

  and substRecordTy subst fields =
      map (fn (l, ty) => (l, substTy subst ty)) fields

  and substTvar subst ((tvar, kind) : T.kindedTvar) =
      (tvar, substTvarKind subst kind)

  and substTvarKind subst tvarKind =
      case tvarKind of
        T.UNIV _ => tvarKind
      | T.REC ({properties, recordKind}, loc) =>
        T.REC ({properties = properties,
                recordKind = substRecordTy subst recordKind},
               loc)

  fun substConbind subst (conbind as {symbol, ty, loc}:I.conbind) =
      case ty of
        NONE => conbind
      | SOME ty => {symbol = symbol, ty = SOME (substTy subst ty), loc = loc}

  fun substDatbind subst ({tyvars, symbol, conbind, loc}:I.datbind) =
      {tyvars = tyvars,
       symbol = symbol,
       loc = loc,
       conbind = map (substConbind subst) conbind}

  fun checkSigexp sigexp =
      case sigexp of
        PC.PLSIGEXPBASIC (spec, loc) => checkSpec spec
      | PC.PLSIGID symbol =>
        EU.enqueueError
          (symbolToLoc symbol, 
           E.SigIDFoundInInterface symbol)
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
    | I.OPAQUE {eq, tyvars, symbol, runtimeTy, loc} =>
      P.PIOPAQUE_TYPE
        {eq=eq, tyvars=tyvars, symbol= symbol, runtimeTy=runtimeTy, loc=loc}

  fun elabDec dec =
      case dec of
        I.IVAL valbind => [elabValbind valbind]
      | I.ITYPE typbindList => map elabTypbind typbindList
      | I.IDATATYPE {datbind, withType, loc} =>
        (EU.checkSymbolDuplication
           (fn x => x)
           (map #symbol datbind @ map #symbol withType)
           E.DuplicateTypeNameInDatatype;
         EU.checkSymbolDuplication
           (fn x => x)
           (List.concat (map (map #symbol o #conbind) datbind))           
           E.DuplicateConstructorNameInDatatype;
         app ElaborateCore.checkReservedNameForValBind
             (List.concat (map (map #symbol o #conbind) datbind));
         P.PIDATATYPE
           {datbind = map (substDatbind (tyconSubst withType)) datbind,
            loc = loc}
         :: map P.PITYPE withType)
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

  fun elabTopdec itopdec =
      case itopdec of
      I.IDEC dec =>
      (SymbolEnv.empty, map P.PIDEC (elabDec dec))
    | I.IFUNDEC funbind =>
      (SymbolEnv.empty, [elabFunbind funbind])
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
        val fixEnvs = map (fn k => SymbolEnv.singleton (k, (fixity,loc))) symbols
        val fixEnv = foldl unionFixEnv emptyFixEnv fixEnvs
      in
        (fixEnv, nil)
      end

  and elabTopdecList fixEnv nil = (emptyFixEnv, nil)
    | elabTopdecList fixEnv (dec :: decs) =
      let
        val (fixEnv1, decs1) = elabTopdec dec
        val fixEnv = unionFixEnv (fixEnv, fixEnv1)
        val (fixEnv2, decs2) = elabTopdecList fixEnv decs
      in
        (SymbolEnv.unionWith #2 (fixEnv1, fixEnv2), decs1 @ decs2)
      end

  fun elaborateTopdecList decs =
      elabTopdecList emptyFixEnv decs

  fun elabInterfaceDec ({interfaceId, interfaceName, requiredIds,
                         provideTopdecs} : I.interface_dec) =
      let
        val (fixEnv, provideTopdecs) = elaborateTopdecList provideTopdecs
        val dec : P.interfaceDec =
            {interfaceId = interfaceId,
             interfaceName = interfaceName,
             requiredIds = requiredIds,
             provideTopdecs = provideTopdecs}
      in
        (InterfaceID.Map.singleton (interfaceId, fixEnv), dec)
      end

  fun elabInterfaceDecList nil = (InterfaceID.Map.empty, nil)
    | elabInterfaceDecList (dec :: decs) =
      let
        val (env1, pdec) = elabInterfaceDec dec
        val (env2, pdecs) = elabInterfaceDecList decs
      in
        (InterfaceID.Map.unionWith
           (fn _ => raise Bug.Bug "duplicate interface id")
           (env1, env2),
         pdec :: pdecs)
      end

  fun elaborate ({interfaceDecs, provide}:I.interface) =
      let
        val {requiredIds, locallyRequiredIds, provideTopdecs, topdecsInclude} =
            provide
        val (interfaceEnv, pinterfaceDecs) =
            elabInterfaceDecList interfaceDecs
        val (provideFixEnv, provideTopdecs) =
            elaborateTopdecList provideTopdecs

        (* check duplicate infix among interfaces *)
        val _ = InterfaceID.Map.foldl
                  (fn (fixEnv, z) => unionFixEnv (z, fixEnv))
                  provideFixEnv
                  interfaceEnv

        val interface : P.interface =
            {interfaceDecs = pinterfaceDecs,
             requiredIds = requiredIds,
             locallyRequiredIds = locallyRequiredIds,
             provideTopdecs = provideTopdecs}
        val requireFixEnv =
            foldl
              (fn ({id, ...}, z) =>
                  case InterfaceID.Map.find (interfaceEnv, id) of
                    NONE => raise Bug.Bug "elaborate: id not found"
                  | SOME fixEnv => SymbolEnv.unionWith #2 (z, fixEnv))
              emptyFixEnv
              (requiredIds @ locallyRequiredIds)
      in
        {interface = interface,
         provideFixEnv = provideFixEnv,
         requireFixEnv = requireFixEnv,
         topdecsInclude = topdecsInclude}
      end

end
