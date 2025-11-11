(**
 * ElaboratorInterface.sml
 * @copyright (C) 2021 SML# Development Team.
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
  datatype loc = datatype Loc.loc
  fun toSymbol ((sym, loc):T.vid) = {symbol = sym, loc = LOC loc}
  fun toLongsymbol ((ids, _):T.longvid) = map toSymbol ids
  fun seq (SOME (items, _)) = items | seq NONE = nil

  type fixEnv = (Fixity.fixity * (Loc.pos * Loc.pos)) Symbol.Map.map
  val emptyFixEnv = Symbol.Map.empty : fixEnv

  fun unionFixEnv (env1, env2) =
      Symbol.Map.mergeWithi
        (fn (k, x, NONE) => x
          | (k, NONE, x) => x
          | (k, x as (SOME (_, loc)), y as (SOME _)) =>
            (EU.enqueueError
               (LOC loc, E.MultipleInfixInInterface k);
             y))
        (env1, env2)

  (* ToDo: integrate expandWithTypesInDataBind in ElaborateCore.sml *)
  type subst =
      {
        tyvar : T.ty Symbol.Map.map,
        tycon : Absyn.typbind Symbol.Map.map
      }

  fun maskTyvar ({tyvar, tycon}:subst) (tvars : T.tyvar list) : subst =
      {tycon = tycon,
       tyvar = foldl (fn ((isEq, (symbol, _)), z) =>
                         if Symbol.Map.inDomain (z, symbol)
                         then #1 (Symbol.Map.remove (z, symbol))
                         else z)
                     tyvar
                     tvars}

  fun tyconSubst typbinds : subst =
      {tyvar = Symbol.Map.empty,
       tycon = foldl (fn (x, z) => Symbol.Map.insert (z, #1 (#2 x), x))
                     Symbol.Map.empty
                     typbinds}

  fun tyvarSubst pairs : subst =
      {tycon = Symbol.Map.empty,
       tyvar = foldl (fn ((x, ty), z) => Symbol.Map.insert (z, #symbol x, ty))
                     Symbol.Map.empty
                     pairs}

  fun substTy subst ty =
      case ty of
        T.TYWILD _ => ty
      | T.TYVAR (tvar as (isEq, (symbol, loc))) =>
        (case Symbol.Map.find (#tyvar subst, symbol) of
           NONE => T.TYVAR tvar
         | SOME ty => ty)
      | T.TYVAR_FREE _ => raise Bug.Bug "FREE_TYID to substTy in ElaborateInterface"
      | T.TYRECORD (fields, ifFlex, loc) =>
        T.TYRECORD (substRecordTy subst fields, ifFlex, loc)
      | T.TYCON (tyseq, tyCon as ([(symbol, _)], _), loc) =>
        let
          val (tyList, con) =
              case tyseq of
                SOME (tys, loc) => (tys, fn tys => SOME (tys, loc))
              | NONE => (nil, fn tys => NONE)
        in
          case Symbol.Map.find (#tycon subst, symbol) of
            NONE =>
            T.TYCON (con (map (substTy subst) tyList), tyCon, loc)
          | SOME (tyvars, symbol, ty, loc) =>
            substTy
              (tyvarSubst
                 (ListPair.zipEq (map (toSymbol o #2) (seq tyvars), tyList)
                  handle ListPair.UnequalLengths =>
                         (EU.enqueueError
                            (LOC loc,
                             E.ArityMismatchInTypeDeclaration
                               {tyCon = #1 symbol,
                                wants = length (seq tyvars),
                                given = length tyList});
                          nil)))
              ty
        end
      | T.TYCON (SOME (tyList, argLoc), tyCon, loc) =>
        T.TYCON (SOME (map (substTy subst) tyList, argLoc), tyCon, loc)
      | T.TYCON (NONE, tyCon, loc) => ty
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
      | T.TYPAREN (ty, loc) => T.TYPAREN (substTy subst ty, loc)

  and substRecordTy subst fields =
      map (fn (l, ty, loc) => (l, substTy subst ty, loc)) fields

  and substTvar subst ((tvar, kind, loc) : T.kinded_tyvar) =
      (tvar, substTvarKind subst kind, loc)

  and substTvarKind subst tvarKind =
      case tvarKind of
        NONE => tvarKind
      | SOME (T.UNIV _) => tvarKind
      | SOME (T.REC (properties, recordKind, loc)) =>
        SOME (T.REC (properties, substRecordTy subst recordKind, loc))

  fun substConbind subst ((_, id, _), ty, loc) =
      case ty of
        NONE => {symbol = toSymbol id, ty = NONE, loc = LOC loc}
      | SOME ty => {symbol = toSymbol id, ty = SOME (substTy subst ty), loc = LOC loc}

  fun substDatbind subst (tyvars, symbol, conbind, loc) =
      {tyvars = seq tyvars,
       symbol = toSymbol symbol,
       loc = LOC loc,
       conbind = map (substConbind subst) conbind}

  fun checkSigexp sigexp =
      case sigexp of
        PC.PLSIGEXPBASIC (spec, loc) => checkSpec spec
      | PC.PLSIGID symbol =>
        EU.enqueueError
          (SymbolWithLoc.symbolToLoc symbol,
           E.SigIDFoundInInterface (#symbol symbol))
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
      | PC.PLSPECSEQ (spec1, spec2) =>
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
  fun elabOverloadCase (tyvar, ty, mrules, loc) =
      {tyvar = tyvar,
       expTy = ty,
       matches = map elabOverloadMrule mrules,
       loc = LOC loc}

  and elabOverloadMrule (ty, inst, loc) =
      {instTy = ty, instance = elabOverloadInst inst}

  and elabOverloadInst (I.INST_OVERLOAD c) =
      P.INST_OVERLOAD (elabOverloadCase c)
    | elabOverloadInst (I.INST_LONGVID id) =
      P.INST_LONGVID {longsymbol = toLongsymbol id}
    | elabOverloadInst (I.INST_PAREN (inst, loc)) =
      elabOverloadInst inst

  fun elabValbind (valbind, loc) =
      case valbind of
        I.VAL_EXTERN (id, ty, loc) =>
        (ElaborateCore.checkReservedNameForValBind (toSymbol id);
         P.PIVAL {scopedTvars = nil,
                  symbol = toSymbol id,
                  body = P.VAL_EXTERN {ty = ty},
                  loc = LOC loc})
      | I.VAL_ALIAS (id, longid, loc) =>
        (ElaborateCore.checkReservedNameForValBind (toSymbol id);
         P.PIVAL {scopedTvars = nil,
                  symbol = toSymbol id,
                  body = P.VALALIAS_EXTERN (toLongsymbol longid),
                  loc = LOC loc})
      | I.VAL_BUILTIN (id, name, ty, loc) =>
        (ElaborateCore.checkReservedNameForValBind (toSymbol id);
         P.PIVAL {scopedTvars = nil,
                  symbol = toSymbol id,
                  body = P.VAL_BUILTIN {builtinSymbol = toSymbol name, ty = ty},
                  loc = LOC loc})
      | I.VAL_OVERLOAD (id, exp, loc) =>
        (ElaborateCore.checkReservedNameForValBind (toSymbol id);
         P.PIVAL {scopedTvars = nil,
                  symbol = toSymbol id,
                  body = P.VAL_OVERLOAD (elabOverloadCase exp),
                  loc = LOC loc})

  fun elabExbind exbind =
      case exbind of
        I.EXBIND ((_, id, _), ty, loc) =>
        (ElaborateCore.checkReservedNameForConstructorBind (toSymbol id);
         P.PIEXCEPTION {symbol=toSymbol id, ty=ty, loc=LOC loc})
      | I.EXBINDREP ((_, id, _), (_, longid, _), loc) =>
        (ElaborateCore.checkReservedNameForConstructorBind (toSymbol id);
         P.PIEXCEPTIONREP {symbol=toSymbol id, longsymbol=toLongsymbol longid, loc=LOC loc})

  fun elabOpaqueImpl impl =
      case impl of
        I.IMPL_TY longid => P.IMPL_TY (toLongsymbol longid)
      | I.IMPL_TUPLE _ => P.IMPL_TUPLE
      | I.IMPL_RECORD _ => P.IMPL_RECORD
      | I.IMPL_FUNC _ => P.IMPL_FUNC

  fun elabTypdesc eq (tyvars, symbol, runtimeTy, loc) =
      P.PIOPAQUE_TYPE
        {eq=eq, tyvars=seq tyvars, symbol= toSymbol symbol, runtimeTy=elabOpaqueImpl runtimeTy, loc=LOC loc}

  fun elabTypbind typbind =
      case typbind of
      I.TYPBIND (tyvars, symbol, ty, loc) =>
      P.PITYPE {tyvars=seq tyvars, symbol = toSymbol symbol, ty=ty, loc=LOC loc}
    | I.TYPDESC typdesc => elabTypdesc false typdesc

  fun elabDec dec =
      case dec of
        I.VAL (valbind, loc) => [elabValbind (valbind, loc)]
      | I.TYPE (typbindList, _) => map elabTypbind typbindList
      | I.EQTYPE (typdescList, _) => map (elabTypdesc true) typdescList
      | I.DATATYPE (datbind, withType, loc) =>
        (EU.checkSymbolDuplication
           (fn x => toSymbol x)
           (map #2 datbind @ map #2 withType)
           E.DuplicateTypeNameInDatatype;
         EU.checkSymbolDuplication
           (fn x => toSymbol x)
           (List.concat (map (map (#2 o #1) o #3) datbind))
           E.DuplicateConstructorNameInDatatype;
         app ElaborateCore.checkReservedNameForValBind
             (map toSymbol (List.concat (map (map (#2 o #1) o #3) datbind)));
         P.PIDATATYPE
           {datbind = map (substDatbind (tyconSubst withType)) datbind,
            loc = LOC loc}
         :: map (fn (tyvars, id, ty, loc) =>
                    P.PITYPE {tyvars = seq tyvars, symbol = toSymbol id,
                              ty = ty, loc = LOC loc})
                withType)
      | I.DATATYPEREP (symbol, longsymbol, loc) =>
        [P.PITYPEREP {loc=LOC loc, longsymbol = toLongsymbol longsymbol, symbol= toSymbol symbol}]
      | I.TYPEBUILTIN (symbol, builtinSymbol, loc) =>
        [P.PITYPEBUILTIN {builtinSymbol= toSymbol builtinSymbol, loc=LOC loc, symbol= toSymbol symbol}]
      | I.EXCEPTION (exbind, _) => map elabExbind exbind
      | I.STRUCTURE (strbind, _) => [elabStrbind strbind]
      | I.SEMICOLON _ => nil

  and elabStrbind ((symbol, strexp, loc):I.strbind) =
      P.PISTRUCTURE {symbol = toSymbol symbol,
                     strexp = elabStrexp strexp,
                     loc = LOC loc}

  and elabStrexp strexp =
      case strexp of
        I.STRBASIC (decs, loc) =>
        P.PISTRUCT {decs = List.concat (map elabDec decs), loc = LOC loc}
      | I.STRID longvid => P.PISTRUCTREP{longsymbol= toLongsymbol longvid, loc= LOC (#2 longvid)}
      | I.STRAPP (functorSymbol, argument, loc) =>
        P.PIFUNCTORAPP{functorSymbol= toSymbol functorSymbol, argument= toLongsymbol argument, loc=LOC loc}

  fun elabFunbind ((functorSymbol, param, strexp, loc):I.funbind) =
      let
        val strexp = elabStrexp strexp
        val param =
            case param of
              I.FUNPARAM (symbol, sigexp) =>
              {strSymbol = toSymbol symbol, sigexp = elabSigexp sigexp}
            | I.FUNPARAM_SPEC spec =>
              let
                val dummySym = SymbolWithLoc.mkSymbol "" (LOC loc)
              in
                (EU.enqueueError
                   (LOC loc, E.DerivedFormFunArg);
                 {strSymbol = dummySym, sigexp = PatternCalc.PLSIGID dummySym}
                )
              end
      in
        P.PIFUNDEC {functorSymbol = toSymbol functorSymbol,
                    param = param,
                    strexp = strexp,
                    loc = LOC loc}
      end

  fun toFixEnv fixity ids =
      foldl unionFixEnv
            emptyFixEnv
            (map (fn id => Symbol.Map.singleton (#1 id, (fixity, #2 id))) ids)

  fun elabTopdec itopdec =
      case itopdec of
      I.DEC dec =>
      (Symbol.Map.empty, map P.PIDEC (elabDec dec))
    | I.FUNCTOR (funbind, _) =>
      (Symbol.Map.empty, [elabFunbind funbind])
    | I.INFIX (NONE, ids, _) =>
      (toFixEnv (Fixity.INFIX 0) ids, nil)
    | I.INFIX (SOME n, ids, loc) =>
      (toFixEnv (Fixity.INFIX (ElaborateCore.elabInfixPrec (n, loc))) ids, nil)
    | I.INFIXR (NONE, ids, _) =>
      (toFixEnv (Fixity.INFIXR 0) ids, nil)
    | I.INFIXR (SOME n, ids, loc) =>
      (toFixEnv (Fixity.INFIXR (ElaborateCore.elabInfixPrec (n, loc))) ids, nil)
    | I.NONFIX (ids, _) =>
      (toFixEnv Fixity.NONFIX ids, nil)

  and elabTopdecList fixEnv nil = (emptyFixEnv, nil)
    | elabTopdecList fixEnv (dec :: decs) =
      let
        val (fixEnv1, decs1) = elabTopdec dec
        val fixEnv = unionFixEnv (fixEnv, fixEnv1)
        val (fixEnv2, decs2) = elabTopdecList fixEnv decs
      in
        (Symbol.Map.unionWith #2 (fixEnv1, fixEnv2), decs1 @ decs2)
      end

  fun elaborateTopdecList decs =
      elabTopdecList emptyFixEnv decs

  fun elabInterfaceDec ({interfaceId, interfaceName, requiredIds,
                         provideTopdecs} : AbsynInterfaceLoaded.interface_dec) =
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

  fun elaborate ({interfaceDecs, provide}:'a AbsynInterfaceLoaded.interface) =
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

        val interface : 'a P.interface =
            {interfaceDecs = pinterfaceDecs,
             requiredIds = requiredIds,
             locallyRequiredIds = locallyRequiredIds,
             provideTopdecs = provideTopdecs}
        val requireFixEnv =
            foldl
              (fn ({id, ...}, z) =>
                  case InterfaceID.Map.find (interfaceEnv, id) of
                    NONE => raise Bug.Bug "elaborate: id not found"
                  | SOME fixEnv => Symbol.Map.unionWith #2 (z, fixEnv))
              emptyFixEnv
              (requiredIds @ locallyRequiredIds)
      in
        {interface = interface,
         provideFixEnv = provideFixEnv,
         requireFixEnv = requireFixEnv,
         topdecsInclude = topdecsInclude}
      end

end
