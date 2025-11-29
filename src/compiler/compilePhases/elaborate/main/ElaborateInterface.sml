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
  fun ftvValbind valbind =
      case valbind of
        I.VAL_EXTERN (id, ty, loc) => ftvTy ty
      | I.VAL_ALIAS (id, longid, loc) => Symbol.Map.empty
      | I.VAL_BUILTIN (id, name, ty, loc) => ftvTy ty
      | I.VAL_OVERLOAD (id, ovcase, loc) => ftvOverloadCase ovcase
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
        (#2 tyvar,
         ElaborateTy.elabMonoTy ty,
         map (elabOverloadMrule env) mrules,
         LOC loc)
      end

  and elabOverloadMrule env (ty, inst, loc) =
      (ElaborateTy.elabMonoTy ty, elabOverloadInst env inst, LOC loc)

  and elabOverloadInst env inst =
      case inst of
        I.INST_OVERLOAD ovcase =>
        P.INST_OVERLOAD (elabOverloadCase env ovcase)
      | I.INST_LONGVID id =>
        P.INST_LONGVID id
      | I.INST_PAREN (inst, loc) =>
        elabOverloadInst env inst

  fun elabValbind valbind =
      case valbind of
        I.VAL_EXTERN (id, ty, loc) =>
        P.VAL_EXTERN (id, ElaborateTy.elabPolyTy ty, LOC loc)
      | I.VAL_ALIAS (id, longid, loc) =>
        P.VAL_ALIAS (id, longid, LOC loc)
      | I.VAL_BUILTIN (id, name, ty, loc) =>
        P.VAL_BUILTIN (id, name, ElaborateTy.elabPolyTy ty, LOC loc)
      | I.VAL_OVERLOAD (id, ovcase as (_, _, _, loc1), loc) =>
        P.VAL_OVERLOAD (id, elabOverloadCase Symbol.Map.empty ovcase, LOC loc)

  fun elabTypdesc eq (tyvars, tycon, impl, loc) =
      P.DECTYPDESC (eq, (map #2 (seq tyvars), tycon, impl, LOC loc))

  fun elabTypbind typbind =
      case typbind of
      I.TYPBIND typbind =>
      P.DECTYPBIND (ElaborateCore.elabTypbind typbind)
    | I.TYPDESC typdesc =>
      elabTypdesc false typdesc

  fun elabDec dec =
      case dec of
        I.DECVAL (tyvarseq, valbind, _) =>
        let
          val ftv = ftvValbind valbind
          val btv = ElaborateTy.kindedTyvarseqToSet tyvarseq
          val implicitlyScoped = ElaborateTy.setMinus (ftv, btv)
          val tyvars = ElaborateTy.toKindedTyvars implicitlyScoped
          val tyvarseq = ElaborateTy.appendTyvarseq (tyvarseq, tyvars)
          val tyvarseq = ElaborateTy.elabKindedTyvarseq tyvarseq
        in
          [P.DECVAL (tyvarseq, elabValbind valbind)]
        end
      | I.DECTYPE (typbinds, _) =>
        map elabTypbind typbinds
      | I.DECEQTYPE (typdescs, _) =>
        map (elabTypdesc true) typdescs
      | I.DECDATATYPE (datbinds, withty, loc) =>
        let
          val datbinds = ElaborateTy.reduceDatbind (datbinds, withty)
          val datbinds = map ElaborateCore.elabDatbind datbinds
          val typbinds = map ElaborateCore.elabTypbind (seq withty)
        in
          P.DECDATATYPE (datbinds, typbinds, LOC loc)
          :: map P.DECTYPBIND typbinds
        end
      | I.DECDATATYPEREP (tycon, longtycon, loc) =>
        [P.DECDATATYPEREP (tycon, longtycon, LOC loc)]
      | I.DECTYPEBUILTIN (tycon, builtin, loc) =>
        [P.DECTYPEBUILTIN (tycon, builtin, LOC loc)]
      | I.DECEXCEPTION (exbind, _) =>
        map (P.DECEXCEPTION o ElaborateCore.elabExbind) exbind
      | I.DECSTRUCTURE ((strid, strexp, loc), _) =>
        [P.DECSTRUCTURE (strid, elabStrexp strexp, LOC loc)]
      | I.DECSEMICOLON _ => nil

  and elabDecs decs =
      List.concat (map elabDec decs)

  and elabStrexp strexp =
      case strexp of
        I.STRBASIC (decs, loc) =>
        P.STRBASIC (elabDecs decs, LOC loc)
      | I.STRID strid =>
        P.STRID strid
      | I.STRAPP (funid, strid, loc) =>
        P.STRAPP (funid, strid, LOC loc)

  fun elabFunbind ((funid, param, strexp, loc):I.funbind) =
      let
        val (strid, sigexp) =
            case param of
              SOME (I.FUNPARAM (symbol, sigexp, loc)) =>
              (symbol, sigexp)
            | SOME (I.FUNPARAM_SPEC (specLoc as (_, loc))) =>
              (enqueueError (loc, E.DerivedFormFunArg);
               ((Symbol.generate NONE, loc), A.SIGBASIC specLoc))
            | NONE =>
              (enqueueError (loc, E.DerivedFormFunArg);
               ((Symbol.generate NONE, loc), A.SIGBASIC (nil, loc)))
      in
        (funid,
         strid,
         ElaborateModule.elabSigexp sigexp,
         elabStrexp strexp,
         LOC loc)
      end

  fun toFixEnv fixity ids =
      foldl unionFixEnv
            emptyFixEnv
            (map (fn id => Symbol.Map.singleton (#1 id, (fixity, #2 id))) ids)

  fun elabTopdec itopdec =
      case itopdec of
      I.TOPDEC dec =>
      (Symbol.Map.empty, map P.TOPDEC (elabDec dec))
    | I.TOPFUNCTOR (funbind, _) =>
      (Symbol.Map.empty, [P.TOPFUNCTOR (elabFunbind funbind)])
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
        val dec : P.interface_dec =
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
             provide =
               {requiredIds = requiredIds,
                locallyRequiredIds = locallyRequiredIds,
                provideTopdecs = provideTopdecs},
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
