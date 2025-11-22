(**
 * ElaboratorInterface.sml
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)
structure ElaborateInterface =
struct
  structure E = ElaborateError
  structure I = AbsynInterface
  structure A = Absyn
  structure P = PatternCalcInterface
  datatype loc = datatype Loc.loc

  fun enqueueError (loc, exn) = UserErrorUtils.enqueueError (LOC loc, exn)
  fun toSymbol ((sym, loc) : A.vid) = {symbol = sym, loc = LOC loc}
  fun seq (SOME (items, _)) = items | seq NONE = nil

  type fix_env = (Fixity.fixity * Absyn.loc) Symbol.Map.map
  val emptyFixEnv = Symbol.Map.empty : fix_env

  fun unionFixEnv (env1, env2) : fix_env =
      Symbol.Map.mergeWithi
        (fn (k, x, NONE) => x
          | (k, NONE, x) => x
          | (k, x as (SOME (fix1, _)), y as (SOME (fix2, loc))) =>
            if fix1 = fix2
            then x
            else (enqueueError (loc, E.MultipleInfixInInterface k); y))
        (env1, env2)

  local
    open ElaborateTy
  in
  fun ftvOverloadInstance inst =
      case inst of
        I.INST_OVERLOAD ovcase => ftvOverloadCase ovcase
      | I.INST_LONGVID _ => Symbol.Map.empty
      | I.INST_PAREN (inst, loc) => ftvOverloadInstance inst
  and ftvOverloadMrule (ty, inst, loc) =
      union (ftvTy ty, ftvOverloadInstance inst)
  and ftvOverloadCase (tyvar, ty, mrules, loc) =
      unionList (singleton tyvar :: ftvTy ty :: map ftvOverloadMrule mrules)
  end

  fun toScopedTvars ftv loc =
      (ElaborateTy.toKindedTyvars ftv, LOC loc)

  fun elabOverloadCase env (tyvar, ty, mrules, loc) =
      let
        open ElaborateTy
        val _ =
            if Symbol.Map.inDomain (env, #1 (#2 tyvar))
            then enqueueError (loc, E.UserTvarScopedAtOuterDecl tyvar)
            else ()
        val env = union (env, union (singleton tyvar, ftvTy ty))
      in
        {tyvar = tyvar,
         expTy = ElaborateTy.elabMonoTy ty,
         matches = map (elabOverloadMrule env) mrules,
         loc = LOC loc}
      end

  and elabOverloadMrule env (ty, inst, loc) =
      {instTy = ElaborateTy.elabMonoTy ty,
       instance = elabOverloadInst env inst}

  and elabOverloadInst env inst =
      case inst of
        I.INST_OVERLOAD ovcase =>
        P.INST_OVERLOAD (elabOverloadCase env ovcase)
      | I.INST_LONGVID id =>
        P.INST_LONGVID {longsymbol = SymbolWithLoc.fromAbsyn id}
      | I.INST_PAREN (inst, loc) =>
        elabOverloadInst env inst

  fun elabValbind (valbind, loc) =
      case valbind of
        I.VAL_EXTERN (id, ty, loc) =>
        P.PIVAL {scopedTvars = toScopedTvars (ElaborateTy.ftvTy ty) loc,
                 symbol = toSymbol id,
                 body = P.VAL_EXTERN {ty = ElaborateTy.elabRank1Ty ty},
                 loc = LOC loc}
      | I.VAL_ALIAS (id, longid, loc) =>
        P.PIVAL {scopedTvars = (nil, Loc.NOLOC),
                 symbol = toSymbol id,
                 body = P.VALALIAS_EXTERN (SymbolWithLoc.fromAbsyn longid),
                 loc = LOC loc}
      | I.VAL_BUILTIN (id, name, ty, loc) =>
        P.PIVAL {scopedTvars = toScopedTvars (ElaborateTy.ftvTy ty) loc,
                 symbol = toSymbol id,
                 body = P.VAL_BUILTIN {builtinSymbol = toSymbol name,
                                       ty = ElaborateTy.elabRank1Ty ty},
                 loc = LOC loc}
      | I.VAL_OVERLOAD (id, exp, loc) =>
        P.PIVAL {scopedTvars = toScopedTvars (ftvOverloadCase exp) loc,
                 symbol = toSymbol id,
                 body = P.VAL_OVERLOAD (elabOverloadCase Symbol.Map.empty exp),
                 loc = LOC loc}

  fun elabExbind exbind =
      case exbind of
        I.EXBIND ((_, id, _), ty, loc) =>
        P.PIEXCEPTION {symbol = toSymbol id,
                       ty = Option.map ElaborateTy.elabMonoTy ty,
                       loc = LOC loc}
      | I.EXBINDREP ((_, id, _), (_, longid, _), loc) =>
        P.PIEXCEPTIONREP {symbol = toSymbol id,
                          longsymbol = SymbolWithLoc.fromAbsyn longid,
                          loc = LOC loc}

  fun elabOpaqueImpl impl =
      case impl of
        I.IMPL_TY longid => P.IMPL_TY (SymbolWithLoc.fromAbsyn longid)
      | I.IMPL_TUPLE _ => P.IMPL_TUPLE
      | I.IMPL_RECORD _ => P.IMPL_RECORD
      | I.IMPL_FUNC _ => P.IMPL_FUNC

  fun elabTypdesc eq (tyvars, tycon, runtimeTy, loc) =
      P.PIOPAQUE_TYPE {eq = eq,
                       tyvars = seq tyvars,
                       symbol = toSymbol tycon,
                       runtimeTy = elabOpaqueImpl runtimeTy,
                       loc = LOC loc}

  fun elabTypbind typbind =
      case typbind of
      I.TYPBIND (tyvars, tycon, ty, loc) =>
      P.PITYPE {tyvars = seq tyvars,
                symbol = toSymbol tycon,
                ty = ElaborateTy.elabMonoTy ty,
                loc = LOC loc}
    | I.TYPDESC typdesc => elabTypdesc false typdesc

  fun elabConbind ((_, vid, _), ty, loc) =
      {symbol = toSymbol vid,
       ty = Option.map ElaborateTy.elabMonoTy ty,
       loc = LOC loc}

  fun elabDatbind (tyvarseq, tycon, conbinds, loc) =
      {tyvars = seq tyvarseq,
       symbol = toSymbol tycon,
       conbind = map elabConbind conbinds,
       loc = LOC loc}

  fun elabDec dec =
      case dec of
        I.DECVAL (valbind, loc) =>
        [elabValbind (valbind, loc)]
      | I.DECTYPE (typbinds, _) =>
        map elabTypbind typbinds
      | I.DECEQTYPE (typdescs, _) =>
        map (elabTypdesc true) typdescs
      | I.DECDATATYPE (datbinds, withty, loc) =>
        let
          val datbinds = ElaborateTy.reduceDatbind (datbinds, withty)
        in
          P.PIDATATYPE
            {datbind = map elabDatbind datbinds,
             withty = map (fn (tvars, id, ty, loc) =>
                              (seq tvars,
                               toSymbol id,
                               ElaborateTy.elabMonoTy ty,
                               LOC loc))
                          (seq withty),
             loc = LOC loc}
          :: map (elabTypbind o I.TYPBIND) (seq withty)
        end
      | I.DECDATATYPEREP (tycon, longtycon, loc) =>
        [P.PITYPEREP {symbol = toSymbol tycon,
                      longsymbol = SymbolWithLoc.fromAbsyn longtycon,
                      loc = LOC loc}]
      | I.DECTYPEBUILTIN (tycon, builtin, loc) =>
        [P.PITYPEBUILTIN {symbol = toSymbol tycon,
                          builtinSymbol = toSymbol builtin,
                          loc = LOC loc}]
      | I.DECEXCEPTION (exbind, _) =>
        map elabExbind exbind
      | I.DECSTRUCTURE ((strid, strexp, loc), _) =>
        [P.PISTRUCTURE {symbol = toSymbol strid,
                        strexp = elabStrexp strexp,
                        loc = LOC loc}]
      | I.DECSEMICOLON _ => nil

  and elabDecs decs =
      List.concat (map elabDec decs)

  and elabStrexp strexp =
      case strexp of
        I.STRBASIC (decs, loc) =>
        P.PISTRUCT {decs = elabDecs decs, loc = LOC loc}
      | I.STRID (strid as (_, _, loc)) =>
        P.PISTRUCTREP
          {longsymbol = SymbolWithLoc.fromAbsyn strid, loc = LOC loc}
      | I.STRAPP (funid, strid, loc) =>
        P.PIFUNCTORAPP {functorSymbol = toSymbol funid,
                        argument = SymbolWithLoc.fromAbsyn strid,
                        loc = LOC loc}

  fun elabFunbind ((funid, param, strexp, loc):I.funbind) =
      let
        val param =
            case param of
              SOME (I.FUNPARAM (symbol, sigexp, loc)) =>
              {strSymbol = toSymbol symbol,
               sigexp = ElaborateModule.elabSigexp sigexp}
            | SOME (I.FUNPARAM_SPEC (specLoc as (_, loc))) =>
              (enqueueError (loc, E.DerivedFormFunArg);
               {strSymbol = {symbol = Symbol.generate NONE, loc = LOC loc},
                sigexp = ElaborateModule.elabSigexp (A.SIGBASIC specLoc)})
            | NONE =>
              (enqueueError (loc, E.DerivedFormFunArg);
               {strSymbol = {symbol = Symbol.generate NONE, loc = LOC loc},
                sigexp = ElaborateModule.elabSigexp (A.SIGBASIC (nil, loc))})
      in
         P.PIFUNDEC {functorSymbol = toSymbol funid,
                     param = param,
                     strexp = elabStrexp strexp,
                     loc = LOC loc}
      end

  fun toFixEnv fixity ids =
      foldl unionFixEnv
            emptyFixEnv
            (map (fn id => Symbol.Map.singleton (#1 id, (fixity, #2 id))) ids)

  fun elabTopdec itopdec =
      case itopdec of
      I.TOPDEC dec =>
      (Symbol.Map.empty, map P.PIDEC (elabDec dec))
    | I.TOPFUNCTOR (funbind, _) =>
      (Symbol.Map.empty, [elabFunbind funbind])
    | I.TOPINFIX (n, ids, loc) =>
      (toFixEnv (Fixity.INFIX (ElaborateCore.elabInfixPrec (n, loc))) ids, nil)
    | I.TOPINFIXR (n, ids, loc) =>
      (toFixEnv (Fixity.INFIXR (ElaborateCore.elabInfixPrec (n, loc))) ids, nil)
    | I.TOPNONFIX (ids, _) =>
      (toFixEnv Fixity.NONFIX ids, nil)

  fun elabTopdecs decs =
      let
        val (fixEnv, decs) =
            CompileUtils.compileList
              {extend = fn _ => {},
               accum = Symbol.Map.unionWith #2,
               empty = Symbol.Map.empty}
              (fn _ => elabTopdec)
              {}
              decs
      in
        (fixEnv, List.concat decs)
      end

  fun elabInterfaceDec ({interfaceId, interfaceName, requiredIds,
                         provideTopdecs} : AbsynInterfaceLoaded.interface_dec) =
      let
        val (fixEnv, provideTopdecs) = elabTopdecs provideTopdecs
        val dec : P.interfaceDec =
            {interfaceId = interfaceId,
             interfaceName = interfaceName,
             requiredIds = requiredIds,
             provideTopdecs = provideTopdecs}
      in
        (InterfaceID.Map.singleton (interfaceId, fixEnv), dec)
      end

  fun elabInterfaceDecs decs =
      CompileUtils.compileList
        {extend = fn _ => {},
         accum = InterfaceID.Map.unionWith #2,
         empty = InterfaceID.Map.empty}
        (fn _ => elabInterfaceDec)
        {}
        decs

  fun elaborate ({interfaceDecs, provide, topdecsInclude}
                 : 'a AbsynInterfaceLoaded.interface) =
      let
        val {requiredIds, locallyRequiredIds, provideTopdecs} = provide
        val (interfaceEnv, pinterfaceDecs) = elabInterfaceDecs interfaceDecs
        val (provideFixEnv, provideTopdecs) = elabTopdecs provideTopdecs
        val topdecsInclude = map ElaborateModule.elabSigdec topdecsInclude

        (* check duplicate infix among interfaces *)
        val _ = InterfaceID.Map.foldl
                  (fn (fixEnv, z) => unionFixEnv (z, fixEnv))
                  provideFixEnv
                  interfaceEnv

        val interface : 'a P.interface =
            {interfaceDecs = pinterfaceDecs,
             requiredIds = requiredIds,
             locallyRequiredIds = locallyRequiredIds,
             provideTopdecs = provideTopdecs,
             topdecsInclude = topdecsInclude}
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
         requireFixEnv = requireFixEnv}
      end

end
