(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : CP-001 *)
structure CheckProvide =
struct
local
  structure I = IDCalc
  structure V = NameEvalEnv
  structure BT = BuiltinTypes
  structure PI = PatternCalcInterface
  structure PL = PatternCalc
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure A = AbsynInterface
  structure N = NormalizeTy
  structure Ty = EvalTy
  structure Sig = EvalSig
  structure FU = FunctorUtils
  structure EI = NameEvalInterface
  val nilPath = nil
  fun bug s = Bug.Bug ("CheckProvide: " ^ s)

  val symbolToString = Symbol.symbolToString
  val symbolToLoc = Symbol.symbolToLoc
  val longsymbolToLongid = Symbol.longsymbolToLongid
  val longsymbolToLoc = Symbol.longsymbolToLoc

  exception Fail

  fun genTypedExportVarsIdstatus 
        exLongsymbol
        idstatus
        (exnSet, icdecls as {exportDecls, bindDecls}) =
      case idstatus of
        I.IDVAR {id=varId,...} => 
        (exnSet,
         {exportDecls=exportDecls @ 
                      [I.ICEXPORTTYPECHECKEDVAR
                         {longsymbol=exLongsymbol, version=NONE, id=varId}],
          bindDecls=nil}
        )
      | I.IDVAR_TYPED {id=varId,ty,...} => 
        (exnSet, 
         {exportDecls=exportDecls @ 
                      [I.ICEXPORTTYPECHECKEDVAR
                         {longsymbol=exLongsymbol, version=NONE, id=varId}],
          bindDecls=nil}
        )
      | I.IDEXVAR _ => (exnSet, icdecls)
      | I.IDEXVAR_TOBETYPED _ => raise bug "IDEXVAR_TOBETYPED"
      | I.IDBUILTINVAR _ => (exnSet, icdecls)
      | I.IDCON _ => (exnSet, icdecls)
      | I.IDEXN {id, ty,...} => 
        let
          val exInfo = {longsymbol=exLongsymbol, version=NONE, ty=ty}
        in
          if not (ExnID.Set.member(exnSet, id)) then
            (ExnID.Set.add(exnSet, id), 
             {exportDecls = 
              exportDecls @ [I.ICEXPORTEXN {exInfo=exInfo, id=id}],
              bindDecls=bindDecls}
            )
          else (exnSet, icdecls)
        end
      | I.IDEXNREP {id, ty,...} => 
        let
          val exInfo = {longsymbol=exLongsymbol, version=NONE, ty=ty}
        in
          if not (ExnID.Set.member(exnSet, id)) then
            (ExnID.Set.add(exnSet, id), 
             {exportDecls = 
              exportDecls @ [I.ICEXPORTEXN {exInfo=exInfo, id=id}],
              bindDecls=bindDecls}
            )
          else (exnSet, icdecls)
        end
      | I.IDEXEXN _ => (exnSet, icdecls)
      | I.IDEXEXNREP _ => (exnSet, icdecls)
      | I.IDOPRIM _ => (exnSet, icdecls)
      | I.IDSPECVAR _ => raise bug "IDSPECVAR in genTypedExportVars"
      | I.IDSPECEXN _ => raise bug "IDSPECEXN in genTypedExportVars"
      | I.IDSPECCON _ => raise bug "IDSPECCON in genTypedExportVars"

  fun genTypedExportVarsVarE path varE (exnSet,icdecls) =
      SymbolEnv.foldli
      (fn (name, idstatus, (exnSet, icdecls)) =>
          let
            val exLongsymbol = path@[name]
          in
            genTypedExportVarsIdstatus exLongsymbol idstatus (exnSet, icdecls)
          end
      )
      (exnSet, icdecls)
      varE
  fun genTypedExportVarsEnv path (V.ENV{varE, tyE, strE}) (exnSet,icdecls) =
      let
        val (exnSet, icdecls) = genTypedExportVarsVarE path varE (exnSet, icdecls)
        val (exnSet, icdecls) = genTypedExportVarsStrE path strE (exnSet, icdecls)
      in
        (exnSet, icdecls)
      end
  and genTypedExportVarsStrE path (V.STR strEntryMap) (exnSet,icdecls) =
      SymbolEnv.foldli
      (fn (name, {env, strKind}, (exnSet,icdecls)) =>
          genTypedExportVarsEnv (path@[name]) env (exnSet,icdecls)
      )
      (exnSet, icdecls)
      strEntryMap

  fun checkDatbind
        path evalEnv env
        (name, defTstr, defRealTstr, defRealTfun, {tyvars, symbol=tycon, conbind}, varE) 
    =
    (* datatype 'a foo = FOO of 'a | BAR  *)
    let
      val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
    in
      let
        val {id, iseq, formals, conSpec, dtyKind,...} =
            case I.derefTfun defRealTfun of 
              I.TFUN_DEF _ =>
              (EU.enqueueError
                 (Symbol.symbolToLoc name,
                  E.ProvideDtyExpected ("CP-010",{longsymbol=path@[tycon]}));
               raise Fail)
            | I.TFUN_VAR(ref(I.TFUN_DTY x)) => x
            | _ =>
              (EU.enqueueError
                 (Symbol.symbolToLoc name,
                  E.ProvideDtyExpected ("CP-020",{longsymbol=path@[tycon]}));
               raise Fail)
        val eqEnv =
            if length tvarList = length formals then
              let
                val tvarPairs = ListPair.zip (tvarList, formals)
              in
                foldr
                  (fn (({id=tv1,...}, {id=tv2,...}), eqEnv) =>
                      TvarID.Map.insert(eqEnv, tv1, tv2)
                  )
                  TvarID.Map.empty
                  tvarPairs
              end
            else
              (EU.enqueueError
                 (Symbol.symbolToLoc name, 
                  E.ProvideArity("CP-030",{longsymbol = path@[tycon]}));
               raise Fail
              )
        val (nameTyPairList, conSpec) =
            foldr
              (fn ({symbol=vid, ty}, (nameTyPairList, conSpec)) =>
                  let
                    val ty =
                        Option.map 
                          (Ty.evalTy tvarEnv evalEnv)
                          ty
                          handle e => raise e                          
                    val (actualTyOpt, conSpec) = 
                        case SymbolEnv.find(conSpec, vid) of
                          NONE =>
                          (EU.enqueueError
                             (Symbol.symbolToLoc vid,
                              E.ProvideUndefinedCon
                                ("CP-040",{longsymbol=path@[vid]}));
                           raise Fail
                          )
                        | SOME tyOpt => 
                          (tyOpt, #1 (SymbolEnv.remove(conSpec, vid))
                                  handle LibBase.NotFound => raise bug "SymbolEnv.remove"
                          )
                  in
                    ((vid, ty, actualTyOpt)::nameTyPairList, conSpec)
                  end
              )
              (nil, conSpec)
              conbind
        val _ = 
            SymbolEnv.appi
              (fn (name, _) => 
                  EU.enqueueError
                    (Symbol.symbolToLoc name,
                     E.ProvideRedundantCon("CP-050",{longsymbol=path@[name]}))
              )
              conSpec
        val _ = if SymbolEnv.isEmpty conSpec then () 
                else raise Fail
        val _ = 
            List.app
              (fn (name, tyOpt1, tyOpt2) =>
                  case (tyOpt1, tyOpt2) of
                    (NONE, NONE) => ()
                  | (SOME ty1, SOME ty2) => 
                    if N.equalTy (N.emptyTypIdEquiv, eqEnv) (ty1, ty2) then ()
                    else 
                      (EU.enqueueError
                         (Symbol.symbolToLoc name,
                          E.ProvideConType("CP-060",{longsymbol=path@[name]}));
                       raise Fail)
                  | _ => 
                    (EU.enqueueError
                       (Symbol.symbolToLoc name,
                        E.ProvideConType("CP-070",{longsymbol = path@[name]}));
                     raise Fail)
              )
              nameTyPairList
        val returnEnv = V.reinsertTstr (V.emptyEnv, tycon, defTstr)
      in
        V.envWithVarE(returnEnv, varE)
      end
    end
      
  fun checkDatbindList path evalEnv env (datbinds:A.datbind list) =
      let
        val nameTstrTfunDatbindList =
            foldr
              (fn (datbind as {tyvars, symbol=tycon, conbind},
                   nameTstrTfunDatbindList) =>
                  let
                    val defTstr = 
                        case V.checkTstr(env, [tycon]) of
                          NONE => (EU.enqueueError
                                     (Symbol.symbolToLoc tycon,
                                      E.ProvideUndefinedTypeName
                                        ("CP-080",{longsymbol = path@[tycon]}));
                                   raise Fail)
                        | SOME tstr => tstr
                    val (defTfun, varE) = 
                        case defTstr of
                          V.TSTR tfun => (tfun, SymbolEnv.empty)
                        | V.TSTR_DTY {tfun, varE,...} => (I.derefTfun tfun, varE)

                    val (conSpec, formals) = 
                        case I.derefTfun defTfun of
                          I.TFUN_VAR(ref (I.TFUN_DTY{formals, conSpec,...})) =>
                          (conSpec, formals)
                        | _ => 
                          (EU.enqueueError
                             (Symbol.symbolToLoc tycon,
                              E.ProvideDtyExpected
                                ("CP-090",{longsymbol=path@[tycon]}));
                           raise Fail)
                    val defRealTstr =
                        V.TSTR_DTY{tfun=defTfun,
                                   varE = varE,
                                   formals=formals,
                                   conSpec=conSpec}
                  in
                    (tycon, defTstr, defRealTstr, defTfun, datbind, varE)::
                    nameTstrTfunDatbindList
                  end
              )
              nil
              datbinds
        val evalEnv =
            foldl
              (fn ((name, defTstr, defRealTstr, tfun, dtbind, varE), evalEnv) =>
                  V.reinsertTstr(evalEnv, name, defRealTstr))
              evalEnv
              nameTstrTfunDatbindList
      in
        foldl
          (fn (nameTstrTfunBind, returnEnv) =>
              let
                val newEnv =
                    checkDatbind path evalEnv env nameTstrTfunBind
              in
                V.unionEnv "CP-100" (returnEnv, newEnv)
              end
          )
          V.emptyEnv
          nameTstrTfunDatbindList
      end

  fun checkPidec 
        exnSet
        path
        (evalTopEnv as {Env=evalEnv,FunE, SigE}) 
        (env, pidec) =
      case pidec of
        PI.PIVAL {scopedTvars, symbol=name, body, loc} =>
        let
          val internalLongsymbol = path @ [name]
          (* for declaration and error message *)
          val (tvarEnv, scopedTvars) =
              Ty.evalScopedTvars Ty.emptyTvarEnv evalEnv scopedTvars
          fun processExternVal {externLongsymbol, ty} =
            let
              val ty = Ty.evalTy tvarEnv evalEnv ty handle e => raise e
              val ty = case scopedTvars of
                         nil => ty
                       | _ => I.TYPOLY(scopedTvars, ty)
            in
              case V.checkId(env, [name]) of
                NONE =>
                (EU.enqueueError
                   (Symbol.symbolToLoc name, 
                    E.ProvideUndefinedID("CP-110", {longsymbol = internalLongsymbol}));
                 raise Fail)
              | SOME (idstatus as I.IDVAR {id=varid,...}) =>
                (exnSet,
                 V.reinsertId(V.emptyEnv,name,idstatus),
                 {exportDecls=
                  [I.ICEXPORTVAR 
                     {exInfo={longsymbol=externLongsymbol, ty=ty, version=NONE},
                      id=varid}],
                   bindDecls = nil
                 }
                )
              | SOME (idstatus as I.IDVAR_TYPED {id=varid, ty=varTy,...}) =>
                if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty, varTy) then
                  (exnSet,
                   V.reinsertId(V.emptyEnv,name,idstatus),
                   {exportDecls = 
                    [I.ICEXPORTTYPECHECKEDVAR
                       {id=varid, longsymbol=externLongsymbol, version=NONE}
                    ],
                    bindDecls= nil
                   }
                  )
                else
                  (EU.enqueueError
                     (Symbol.symbolToLoc name, 
                      E.ProvideIDType("CP-120", {longsymbol = internalLongsymbol}));
                   raise Fail)
              | SOME (idstatus as I.IDEXVAR {exInfo, used, internalId}) =>
                (* bug 069_open *)
                (* bug 124_open *)
                let
(*
                  val _ = 
                      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty, #ty exInfo) then
                        ()
                      else
                        (EU.enqueueError
                           (Symbol.symbolToLoc name,
                            E.ProvideIDType ("CP-131", {longsymbol = internalLongsymbol})))
*)
                  val _ = used := true
                  val icexp  =I.ICEXVAR {exInfo=exInfo, longsymbol=internalLongsymbol}
                  val newId = VarID.generate()
                  val icpat = I.ICPATVAR_TRANS {longsymbol=internalLongsymbol,id=newId}
                  val bindDecls = [I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)]
                  val exInfo = {longsymbol=externLongsymbol,ty = ty, version=NONE}
                  val exportDecls = [I.ICEXPORTVAR {exInfo=exInfo, id=newId}]
                  val idstatus = I.IDVAR_TYPED{id=newId, longsymbol=internalLongsymbol, ty = ty}
                in
                  (exnSet,
                   V.reinsertId(V.emptyEnv,name,idstatus),
                   {exportDecls= exportDecls, bindDecls= bindDecls}
                  )
                end
              | SOME (I.IDEXVAR_TOBETYPED _) => raise bug "IDEXVAR_TOBETYPED"
              | SOME (idstatus as I.IDBUILTINVAR {primitive, ty=primTy}) =>
                (* bug 075_builtin *)
                let
(*
                  val _ = 
                      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty, primTy) then
                        ()
                      else
                        (EU.enqueueError
                           (Symbol.symbolToLoc name,
                            E.ProvideIDType ("CP-132", {longsymbol = internalLongsymbol})))
*)
                  val icexp = I.ICBUILTINVAR{primitive=primitive,ty=primTy,loc=loc}
                  val newId = VarID.generate()
                  val icpat = I.ICPATVAR_TRANS {longsymbol=internalLongsymbol,id=newId}
                  val bindDecls = [I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)]
                  val exportDecls = 
                      [I.ICEXPORTVAR 
                         {id=newId,
                          exInfo={longsymbol=externLongsymbol,ty=ty, version=NONE}}
                      ]
                  val idstatus = I.IDVAR_TYPED{id=newId, ty = ty, longsymbol=internalLongsymbol}
                in
                  (exnSet,
                   V.reinsertId(V.emptyEnv,name,idstatus),
                   {exportDecls=exportDecls, bindDecls=bindDecls}
                  )
                end

              | SOME (idstatus as I.IDCON {id=conId, ty=conTy,...}) =>
                let
(*
                  val _ = 
                      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty, conTy) then
                        ()
                      else
                        (EU.enqueueError
                           (Symbol.symbolToLoc name,
                            E.ProvideIDType ("CP-131", {longsymbol = internalLongsymbol})))
*)
                  val icexp  =I.ICCON {longsymbol=internalLongsymbol,ty=conTy, id=conId}
                  val newId = VarID.generate()
                  val icpat = I.ICPATVAR_TRANS {longsymbol=internalLongsymbol,id=newId}
                  val bindDecls = [I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)]
                  val exportDecls = 
                      [I.ICEXPORTVAR
                         {id=newId,
                          exInfo={longsymbol=externLongsymbol,
                                  version=NONE,
                                  ty=ty}}]
                  val idstatus = I.IDVAR_TYPED{id=newId, ty = ty, longsymbol=internalLongsymbol}
                in
                  (exnSet,
                   V.reinsertId(V.emptyEnv,name,idstatus),
                   {exportDecls=exportDecls, bindDecls=bindDecls}
                  )
                end
              | SOME (idstatus as I.IDEXN {id, ty=exnTy,...}) =>
                let
(*
                  val _ = 
                      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty, exnTy) then
                        (print "IDEXN ok\n")
                      else
                        (print "IDEXN ng\n";
                         EU.enqueueError
                           (Symbol.symbolToLoc name,
                            E.ProvideIDType ("CP-131", {longsymbol = internalLongsymbol}))
                        )
*)
                  val icexp  =I.ICEXN {longsymbol=internalLongsymbol,ty=exnTy,id=id}
                  val newId = VarID.generate()
                  val icpat = I.ICPATVAR_TRANS {longsymbol=internalLongsymbol,id=newId}
                  val bindDecls = [I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)]
                  val idstatus = I.IDVAR_TYPED{id=newId, ty = ty, longsymbol=internalLongsymbol}
                in
                  (exnSet,
                   V.reinsertId(V.emptyEnv,name,idstatus),
                  {exportDecls=nil, bindDecls=bindDecls}
                  )
                end
              | SOME (idstatus as I.IDEXNREP {id, ty=exnTy,...}) =>
                let
                  val _ = 
                      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty, exnTy) then
                        ()
                      else
                        (EU.enqueueError
                           (Symbol.symbolToLoc name,
                            E.ProvideIDType ("CP-131", {longsymbol = internalLongsymbol})))
                  val icexp  =I.ICEXN {longsymbol=internalLongsymbol,ty=exnTy,id=id}
                  val newId = VarID.generate()
                  val icpat = I.ICPATVAR_TRANS {longsymbol=internalLongsymbol,id=newId}
                  val bindDecls = [I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)]
                  val exInfo = {longsymbol=externLongsymbol, ty=ty, version=NONE}
                  val exportDecls = [I.ICEXPORTVAR {id=newId, exInfo=exInfo}]
                  val idstatus = I.IDVAR_TYPED{id=newId, ty = ty, longsymbol=internalLongsymbol}
                in
                  (exnSet, 
                   V.reinsertId(V.emptyEnv,name,idstatus), 
                   {exportDecls=nil, bindDecls=bindDecls}
                  )
                end
              | SOME (I.IDEXEXN _) => raise bug "IDEXEXN in env"
              | SOME (I.IDEXEXNREP _) => raise bug "IDEXEXN in env"
              | SOME (I.IDOPRIM _) => raise bug "IDOPRIM in env"
              | SOME (I.IDSPECVAR _) => raise bug "IDSPECVAR in provideEnv"
              | SOME (I.IDSPECEXN _ ) => raise bug "IDSPECEXN in provideEnv"
              | SOME (I.IDSPECCON _) => raise bug "IDSPECCON in provideEnv"
            end
        in
          case body of
            (* val name : ty *)
            A.VAL_EXTERN {ty} => processExternVal {externLongsymbol=internalLongsymbol, ty=ty}
          | (* val name = aliasPath *)
            A.VALALIAS_EXTERN aliasPath =>
            (case V.checkId(env, [name]) of
               NONE =>
               (EU.enqueueError
                  (Symbol.symbolToLoc name,
                   E.ProvideUndefinedID("CP-130", {longsymbol = path@[name]}));
                raise Fail)
             | SOME (idstatus as I.IDEXVAR {exInfo={longsymbol=refSym, ty, version}, used=used1, internalId}) =>
               (case V.checkId(evalEnv, aliasPath) of
                  SOME (idstatus as I.IDEXVAR {exInfo={longsymbol=defSym, ty, version},used=used2, internalId}) =>
                  if Symbol.eqLongsymbol(refSym, defSym) then
                    (used1 := true; used2:=true;
                     (exnSet, 
                      V.reinsertId(V.emptyEnv,name,idstatus), 
                      {exportDecls=nil, bindDecls=nil}
                     )
                    )
                  else 
                    (EU.enqueueError
                       (Symbol.longsymbolToLoc defSym, 
                        E.ProvideVariableAlias("CP-140", {longsymbol = defSym}));
                     raise Fail)
                | SOME _ =>
                  (EU.enqueueError
                     (Symbol.longsymbolToLoc aliasPath,
                      E.ProvideVariableAlias("CP-150", {longsymbol = aliasPath}));
                   raise Fail)
                | NONE =>
                  (EU.enqueueError
                     (Symbol.longsymbolToLoc aliasPath, 
                      E.ProvideUndefinedID("CP-160", {longsymbol = aliasPath}));
                   raise Fail)
               )
             | SOME (idstatus as I.IDBUILTINVAR {primitive=refPrim, ...}) =>
               (case V.checkId(evalEnv, aliasPath) of
                  SOME (I.IDBUILTINVAR {primitive=defPrim, ...}) =>
                  if refPrim = defPrim then
                    (exnSet, 
                     V.reinsertId(V.emptyEnv,name,idstatus), 
                     {exportDecls=nil, bindDecls=nil}
                    )
                  else
                    (EU.enqueueError
                       (Symbol.longsymbolToLoc aliasPath, 
                        E.ProvideVariableAlias("CP-170", {longsymbol = aliasPath}));
                     raise Fail)
                | SOME _ =>
                  (EU.enqueueError
                     (Symbol.longsymbolToLoc aliasPath,
                      E.ProvideVariableAlias("CP-180", {longsymbol = aliasPath}));
                   raise Fail)
                | NONE =>
                  (EU.enqueueError
                     (Symbol.longsymbolToLoc aliasPath,
                      E.ProvideUndefinedID("CP-190", {longsymbol = aliasPath}));
                   raise Fail)
               )
             | SOME (idstatus as (I.IDVAR {id=refId,...})) =>
               (case V.checkId(evalEnv, aliasPath) of
                  SOME (idstatus as (I.IDVAR {id=defId,...})) =>
                  if VarID.eq(refId,defId) then
                    (exnSet, 
                     V.reinsertId(V.emptyEnv,name,idstatus), 
                     {exportDecls=nil, bindDecls=nil}
                    )
                  else 
                    (EU.enqueueError
                       (Symbol.longsymbolToLoc aliasPath,
                        E.ProvideVariableAlias("CP-200", {longsymbol = aliasPath}));
                     raise Fail)
                | SOME (idstatus as (I.IDVAR_TYPED {id=defId, ty,...})) =>
                  if VarID.eq(refId,defId) then
                    (exnSet, 
                     V.reinsertId(V.emptyEnv,name,idstatus), 
                     {exportDecls=nil, bindDecls=nil}
                    )
                  else 
                    (EU.enqueueError
                       (Symbol.longsymbolToLoc aliasPath,
                        E.ProvideVariableAlias("CP-201", {longsymbol = aliasPath}));
                     raise Fail)
                | SOME _ =>
                  (EU.enqueueError
                     (Symbol.longsymbolToLoc aliasPath, 
                      E.ProvideVariableAlias("CP-210", {longsymbol = aliasPath}));
                   raise Fail)
                | NONE =>
                  (EU.enqueueError
                     (Symbol.longsymbolToLoc aliasPath,
                      E.ProvideUndefinedID("CP-220", {longsymbol = aliasPath}));
                   raise Fail)
               )
             | SOME (idstatus as (I.IDVAR_TYPED {id=refId, ty,...})) =>
               (case V.checkId(evalEnv, aliasPath) of
                  SOME (idstatus as (I.IDVAR {id=defId,...})) =>
                  if VarID.eq(refId,defId) then
                    (exnSet, 
                     V.reinsertId(V.emptyEnv,name,idstatus), 
                     {exportDecls=nil, bindDecls=nil}
                    )
                  else 
                    (EU.enqueueError
                       (loc, E.ProvideVariableAlias("CP-200", {longsymbol = internalLongsymbol}));
                     raise Fail)
                | SOME (idstatus as (I.IDVAR_TYPED {id=defId, ty,...})) =>
                  if VarID.eq(refId,defId) then
                    (exnSet, 
                     V.reinsertId(V.emptyEnv,name,idstatus), 
                     {exportDecls=nil, bindDecls=nil}
                    )
                  else 
                    (EU.enqueueError
                       (loc, E.ProvideVariableAlias("CP-201", {longsymbol = internalLongsymbol}));
                     raise Fail)
                | SOME _ =>
                  (EU.enqueueError
                     (loc, E.ProvideVariableAlias("CP-210", {longsymbol = internalLongsymbol}));
                   raise Fail)
                | NONE =>
                  (EU.enqueueError
                     (loc, E.ProvideUndefinedID("CP-220", {longsymbol = internalLongsymbol}));
                   raise Fail)
               )
             | SOME _ =>
               (EU.enqueueError
                  (loc, E.ProvideVarIDExpected("CP-230", {longsymbol = internalLongsymbol}));
                raise Fail)
            )
          | A.VAL_BUILTIN _ => raise bug "VAL_BUILTIN in provideSpec"
          | A.VAL_OVERLOAD _ => (exnSet, 
                                 V.emptyEnv, 
                                 {exportDecls=nil, bindDecls=nil}
                                )
        end

      | PI.PITYPE {tyvars, symbol=name, ty, loc} =>
        (* type 'a foo = ty  *)
        let
          val internalLongsymbol = path @ [name]
          val _ = EU.checkSymbolDuplication
                    (fn {symbol, eq} => symbol)
                    tyvars
                    (fn s => E.DuplicateTypParms("CP-240",s))
          val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
          val ty = Ty.evalTy tvarEnv evalEnv ty handle e => raise e
          val tfunSpec =
              case N.tyForm tvarList ty of
                N.TYNAME tfun => tfun
              | N.TYTERM ty =>
                let
                  val iseq = N.admitEq tvarList ty
                in
                  I.TFUN_DEF {iseq=iseq,
                              longsymbol = internalLongsymbol,
                              formals=tvarList,
                              realizerTy=ty
                             }
                end
          val tstrDef =
              case V.checkTstr(env, [name]) of
                NONE =>
                (EU.enqueueError
                   (loc,
                    E.ProvideUndefinedTypeName("CP-250",{longsymbol = internalLongsymbol}));
                 raise Fail)
              | SOME tstr => tstr
          val tfunDef = 
              case tstrDef of
                V.TSTR tfun => I.derefTfun tfun
              | V.TSTR_DTY {tfun,...} => I.derefTfun tfun
          val _ =
              if N.equalTfun N.emptyTypIdEquiv (tfunSpec, tfunDef) then  ()
              else 
                (EU.enqueueError
                   (loc, E.ProvideInequalTfun("CP-260",{longsymbol = internalLongsymbol}));
                 raise Fail)
        in
          (exnSet, 
           V.reinsertTstr (V.emptyEnv, name, tstrDef), 
           {exportDecls=nil, bindDecls=nil}
          )
        end

      | PI.PIOPAQUE_TYPE {tyvars, symbol=name, runtimeTy, loc} =>
       (* type 'a foo (= runtimeTy )  *)
        let
          val internalLongsymbol = path @ [name]
          val _ = EU.checkSymbolDuplication
                    (fn {symbol, eq} => symbol)
                    tyvars
                    (fn s => E.DuplicateTypParms("CP-270",s))
          val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
          val tstrDef =
              case V.checkTstr(env, [name]) of
                NONE =>
                (EU.enqueueError
                   (loc,
                    E.ProvideUndefinedTypeName("CP-280",{longsymbol = internalLongsymbol}));
                 raise Fail)
              | SOME tstr => tstr
          val tfunDef = 
              case tstrDef of
                V.TSTR tfun => I.derefTfun tfun
              | V.TSTR_DTY {tfun,...} => I.derefTfun tfun
          val defRuntimeTy = 
              case I.tfunRuntimeTy tfunDef of
                SOME ty => ty
              | NONE => raise bug "tfunRuntimeTy"
          val _ =
              if Ty.compatRuntimeTy {absTy=Ty.evalRuntimeTy tvarEnv evalEnv runtimeTy, implTy=defRuntimeTy} 
              then  ()
              else 
                (
                 EU.enqueueError
                   (loc, E.ProvideRuntimeType("CP-290",{longsymbol = internalLongsymbol}));
                 raise Fail)
          val arity = I.tfunArity tfunDef
          val _ =
              if List.length tyvars = arity then  ()
              else 
                (EU.enqueueError
                   (loc, E.ProvideArity("CP-300",{longsymbol = internalLongsymbol}));
                 raise Fail)
        in
          (exnSet, 
           V.reinsertTstr (V.emptyEnv, name, tstrDef), 
           {exportDecls=nil, bindDecls=nil}
          )
        end

      | PI.PIOPAQUE_EQTYPE {tyvars, symbol=name, runtimeTy, loc} =>
       (* eqtype 'a foo (= runtimeTy )  *)
        let
          val internalLongsymbol = path @ [name]
          val _ = EU.checkSymbolDuplication
                    (fn {symbol, eq} => symbol)
                    tyvars
                    (fn s => E.DuplicateTypParms("CP-310",s))
          val (tvarEnv, tvarList) = Ty.genTvarList Ty.emptyTvarEnv tyvars
          val tstrDef =
              case V.checkTstr(env, [name]) of
                NONE =>
                (EU.enqueueError
                   (loc,
                    E.ProvideUndefinedTypeName("CP-320",{longsymbol = internalLongsymbol}));
                 raise Fail)
              | SOME tstr => tstr
          val tfunDef = 
              case tstrDef of
                V.TSTR tfun => I.derefTfun tfun
              | V.TSTR_DTY {tfun,...} => I.derefTfun tfun
          val defRuntimeTy = 
              case I.tfunRuntimeTy tfunDef of
                SOME ty => ty
              | NONE => raise bug "tfunRuntimeTy"
          val _ =
              if Ty.compatRuntimeTy {absTy=Ty.evalRuntimeTy tvarEnv evalEnv runtimeTy, implTy=defRuntimeTy} 
              then ()
              else 
                (
                 EU.enqueueError
                   (loc, E.ProvideRuntimeType("CP-330",{longsymbol = internalLongsymbol}));
                 raise Fail)
          val arity = I.tfunArity tfunDef
          val _ =
              if List.length tyvars = arity then  ()
              else 
                (EU.enqueueError
                   (loc, E.ProvideArity("CP-340",{longsymbol = internalLongsymbol}));
                 raise Fail)
          val iseq = I.tfunIseq tfunDef
          val _ = if iseq then ()
                  else
                (EU.enqueueError
                   (loc, E.ProvideEquality("CP-350",{longsymbol = internalLongsymbol}));
                 raise Fail)
        in
          (exnSet, 
           V.reinsertTstr (V.emptyEnv, name, tstrDef), 
           {exportDecls=nil, bindDecls=nil}
          )
        end

      | PI.PITYPEBUILTIN {symbol, builtinSymbol, loc} =>
        raise bug "PITYPEBUILTIN in provideSpec"

      | PI.PITYPEREP {symbol=tycon, longsymbol=origTycon, loc} =>
        (* datatype foo = datatype bar *)
         let
           val internalPath = path @ [tycon]
           val specTstr =
               case V.checkTstr(evalEnv, origTycon) of
                 NONE => (EU.enqueueError
                            (loc,
                             E.ProvideUndefinedTypeName
                               ("CP-360",{longsymbol = internalPath}));
                          raise Fail)
               | SOME tstr => tstr
           val specTfun =
               case specTstr of
                 V.TSTR tfun => I.derefTfun tfun
               | V.TSTR_DTY {tfun,...} => I.derefTfun tfun
           val defTstr = 
               case V.checkTstr(env, [tycon]) of
                 NONE => (EU.enqueueError
                            (loc,
                             E.ProvideUndefinedTypeName
                               ("CP-370",{longsymbol = internalPath}));
                          raise Fail)
               | SOME tstr => tstr
(* 2013-3-21 ohori bug 
           val defTfun = 
               case defTstr of
                 V.TSTR tfun => I.derefTfun tfun
               | V.TSTR_DTY {tfun,...} => I.derefTfun tfun
*)
           val (varE, defTfun) = 
               case defTstr of
                 V.TSTR tfun => (SymbolEnv.empty, I.derefTfun tfun)
               | V.TSTR_DTY {tfun,varE, ...} => (varE, I.derefTfun tfun)
         in
           if N.equalTfun N.emptyTypIdEquiv (defTfun, specTfun) then 
             let
               val returnEnv = V.reinsertTstr(V.emptyEnv,tycon, defTstr)
             in
               (exnSet, 
                V.envWithVarE(returnEnv, varE),
(* 2013-3-21 ohori
                returnEnv, 
*)
                {exportDecls=nil, bindDecls=nil}
                )
             end
           else 
             (EU.enqueueError
                (loc,
                 E.ProvideDtyExpected ("CP-380",{longsymbol = internalPath}));
              raise Fail)
         end

      | PI.PIEXCEPTION {symbol=name, ty=tyOpt, loc} => 
        let
          val longsymbol = path @ [name]
          val tySpec =
              case tyOpt of 
                NONE => BT.exnITy
              | SOME ty => I.TYFUNM([Ty.evalTy Ty.emptyTvarEnv evalEnv ty],
                                    BT.exnITy)
                handle e => raise e
        in
          case V.checkId (env, [name]) of
            NONE =>
            (EU.enqueueError
               (loc, E.ProvideUndefinedID("CP-390", {longsymbol = longsymbol}));
             raise Fail)
          | SOME (idstatus as I.IDEXN {id,longsymbol=_,ty}) => 
            if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty, tySpec) then
              (ExnID.Set.add(exnSet, id),
               V.reinsertId(V.emptyEnv, name, idstatus),
               {exportDecls=
                [I.ICEXPORTEXN {id=id,exInfo={ty=ty,longsymbol=longsymbol, version=NONE}}],
                bindDecls=nil
               }
              )
            else 
              (EU.enqueueError
                 (loc, E.ProvideExceptionType("CP-400", {longsymbol = longsymbol}));
               raise Fail)
          | SOME (I.IDEXNREP {id,longsymbol=_, ty}) =>
            (* BUG 128_functor.sml *)
            if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty, tySpec)
            then
              if not (ExnID.Set.member(exnSet, id)) then
                (ExnID.Set.add(exnSet, id),
(* 2012-12-23
                 V.reinsertId(V.emptyEnv, name, I.IDEXN {id=id, longsymbol=longsymbol, ty=ty}),
*)
                 V.reinsertId(V.emptyEnv, name, I.IDEXNREP {id=id, longsymbol=longsymbol, ty=ty}),
                 {exportDecls =
                  [I.ICEXPORTEXN
                     {id=id,exInfo={ty=ty,longsymbol=longsymbol, version=NONE}}],
                  bindDecls=nil
                 }
                )
              else 
                (exnSet, 
                 V.emptyEnv, 
                 {exportDecls=nil, bindDecls=nil}
                )
            else 
              (EU.enqueueError
                 (loc, E.ProvideExceptionType("CP-410", {longsymbol = longsymbol}));
               raise Fail)
          | SOME (idstatus as I.IDEXEXN _) => 
            (EU.enqueueError
               (loc, E.ProvideExceptionType("CP-420", {longsymbol = longsymbol}));
             raise Fail)
          | SOME (idstatus as I.IDEXEXNREP _) => 
            (EU.enqueueError
               (loc, E.ProvideExceptionType("CP-430", {longsymbol = longsymbol}));
             raise Fail)
          | _ => 
            (EU.enqueueError
               (loc,
                E.ProvideUndefinedException("CP-440", {longsymbol = longsymbol}));
             raise Fail)
        end
      | PI.PIEXCEPTIONREP {symbol=name, longsymbol=origPath, loc} =>
        (
        let
          val refIdstatus = 
              case V.checkId (evalEnv, origPath) of
                NONE =>
                (
                 EU.enqueueError
                   (loc, E.ExceptionNameUndefined
                           ("CP-450",{longsymbol = origPath}));
                 raise Fail)
              | SOME (idstatus as I.IDEXN _) => idstatus
              | SOME (idstatus as I.IDEXNREP _) => idstatus
              | SOME (idstatus as I.IDEXEXN _) => idstatus
              | SOME (idstatus as I.IDEXEXNREP _) => idstatus
              | _ => 
                (EU.enqueueError
                   (loc, E.ExceptionExpected
                           ("CP-460",{longsymbol = origPath}));
                 raise Fail)
          val defIdstatus =
              case V.checkId (env, [name]) of
                NONE =>
                (EU.enqueueError
                   (loc, E.ProvideUndefinedID
                           ("CP-470",{longsymbol = origPath}));
                 raise Fail)
              | SOME (I.IDEXN _) => 
                (EU.enqueueError
                   (loc, E.ProvideExceptionRep
                           ("CP-480",{longsymbol = origPath}));
                 raise Fail)
              | SOME (idstatus as I.IDEXNREP _) => idstatus
              | SOME (idstatus as I.IDEXEXN _) => idstatus
              | SOME (idstatus as I.IDEXEXNREP _) => idstatus
              | _ => 
                (EU.enqueueError
                   (loc, E.ExceptionExpected
                           ("CP-490",{longsymbol = origPath}));
                 raise Fail)
        in
          case defIdstatus of
            I.IDEXNREP {id=id1, ...} =>
            (case refIdstatus of
               I.IDEXN {id=id2,...} =>
               if ExnID.eq(id1, id2) then 
                 (exnSet,
                  V.reinsertId(V.emptyEnv, name, defIdstatus),
                  {exportDecls=nil, bindDecls=nil}
                 )
               else
                 (EU.enqueueError
                    (loc, E.ProvideExceptionRepID("CP-500", {longsymbol = path@[name]}));
                  raise Fail)
             | I.IDEXNREP {id=id2,...} => 
               if ExnID.eq(id1, id2) then 
                 (exnSet, 
                  V.reinsertId(V.emptyEnv, name, defIdstatus),
                  {exportDecls=nil, bindDecls=nil}
                 )
               else
                 (EU.enqueueError
                    (loc, E.ProvideExceptionRepID("CP-510", {longsymbol = path@[name]}));
                  raise Fail)
             | _ =>
               (EU.enqueueError
                  (loc, E.ProvideExceptionRepID("CP-520", {longsymbol = path@[name]}));
                raise Fail)
            )
          | I.IDEXEXN ({longsymbol=longsymbol1, ...},_) =>
            (case refIdstatus of
               I.IDEXEXN ({longsymbol=longsymbol2,...},_) =>
               if Symbol.eqLongsymbol (longsymbol1, longsymbol2) then 
                 (exnSet, 
                  V.reinsertId(V.emptyEnv, name, defIdstatus), 
                  {exportDecls=nil, bindDecls=nil}
                 )
               else
                 (EU.enqueueError
                    (loc, E.ProvideExceptionRepID("CP-530", {longsymbol = path@[name]}));
                  raise Fail)
             | _ =>
               (EU.enqueueError
                  (loc, E.ProvideExceptionRepID("CP-540", {longsymbol = path@[name]}));
                raise Fail)
            )
          | I.IDEXEXNREP ({longsymbol=longsymbol1, ...},_) =>
            (case refIdstatus of
               I.IDEXEXNREP ({longsymbol=longsymbol2,...},_) =>
               if Symbol.eqLongsymbol(longsymbol1, longsymbol2) then 
                 (exnSet, 
                  V.reinsertId(V.emptyEnv, name, defIdstatus),
                  {exportDecls=nil, bindDecls=nil}
                 )
               else
                 (EU.enqueueError
                    (loc, E.ProvideExceptionRepID("CP-550", {longsymbol = path@[name]}));
                  raise Fail)
(* 2012-9-25 ohori: added the following case due to the fix of 237_functorExn
   _require file
      exception FOO       => IDEXEXN
      exception BAR = FOO => IDEXEXNREP
   source:
     exception Foo = FOO  => IDEXEXNREP
     exception Bar = BAR  => IDEXEXNREP
   interface file: 
     exception Foo = FOO 
     exception Bar = BAR
  In this case, Foo = IDEXEXNREP and FOO = IDEXEXN
*)
             | I.IDEXEXN ({longsymbol=longsymbol2,...},_) =>
               if Symbol.eqLongsymbol(longsymbol1, longsymbol2) then 
                 (exnSet, 
                  V.reinsertId(V.emptyEnv, name, defIdstatus),
                  {exportDecls=nil, bindDecls=nil}
                 )
               else
                 (EU.enqueueError
                    (loc, E.ProvideExceptionRepID("CP-550", {longsymbol = path@[name]}));
                  raise Fail)
             | _ =>
               (EU.enqueueError
                  (loc, E.ProvideExceptionRepID("CP-560", {longsymbol = path@[name]}));
                raise Fail)
            )
          | _ => raise bug "impossible"
        end
        handle Fail => 
               (exnSet, 
                V.emptyEnv, 
                {exportDecls=nil, bindDecls=nil}
               )
        )
      | PI.PIDATATYPE {datbind, loc} =>
        (exnSet,
         checkDatbindList path evalEnv env datbind,
         {exportDecls=nil, bindDecls=nil}
        )
      | PI.PISTRUCTURE {symbol=strSymbol, strexp=PI.PISTRUCT {decs,loc=strLoc}, loc} =>
        (case V.checkStr(env, [strSymbol]) of
           SOME {env, strKind} => 
           let
             val (exnSet, returnEnv, icdecls) =
                 checkPidecList
                   exnSet strLoc (path@[strSymbol]) evalTopEnv (env, decs)
             val strEntry = {env=returnEnv, strKind=strKind}
           in
             (exnSet, V.reinsertStr(V.emptyEnv, strSymbol, strEntry), icdecls)
           end
         | NONE =>
           (EU.enqueueError
              (loc, E.ProvideUndefinedStr("CP-570", {longsymbol=path@[strSymbol]}));
            raise Fail)
        )

      | PI.PISTRUCTURE {symbol=strSymbol, 
                        strexp=PI.PISTRUCTREP {longsymbol=strPath,loc=strLoc}, loc} =>
        let
          val defLongsymbol = [strSymbol]
        in
          (case V.checkStr(env, defLongsymbol) of
             SOME (strEntry1 as {env = env1, strKind}) =>
             let
               val defId = case strKind of
                             V.STRENV id => id
                           | V.FUNAPP {id, ...} => id
                           | _ => 
                             (EU.enqueueError
                                (loc, E.ProvideStrRep("CP-580", {longsymbol=path@[strSymbol]}));
                              raise Fail)
             in
               (case V.checkStr(evalEnv, strPath) of
                  SOME (strEntry as {env=_, strKind}) =>
                  let
                    val refId =
                        case strKind of
                          V.STRENV id => id
                        | V.FUNAPP {id,...} => id
                        | _ => 
                          (EU.enqueueError
                             (loc, E.ProvideStrRep("CP-590", {longsymbol=path@[strSymbol]}));
                           raise Fail)
                  in
                    if StructureID.eq(defId, refId) then 
                      (exnSet, 
(* 2012-12-23 
                       V.reinsertStr(V.emptyEnv, strSymbol, strEntry), 
*)
                       V.reinsertStr(V.emptyEnv, strSymbol, {env=env1, strKind=strKind}), 
                       {exportDecls=nil, bindDecls=nil}
                      )
                    else 
                      (EU.enqueueError
                         (loc, E.ProvideStrRep("CP-600", {longsymbol=path@[strSymbol]}));
                       raise Fail)
                  end
                | NONE => 
                  (EU.enqueueError
                     (loc, E.ProvideUndefinedStr("CP-610", {longsymbol=strPath}));
                   raise Fail
                  )
               )
             end
           | NONE =>
             (EU.enqueueError
                (loc, E.ProvideUndefinedStr("CP-620", {longsymbol=path@[strSymbol]}));
              raise Fail)
          )
        end
      | PI.PISTRUCTURE {symbol=strSymbol, 
                        strexp=PI.PIFUNCTORAPP
                                 {functorSymbol,
                                  argument, 
                                  loc=argLoc}, 
                        loc} =>
        let
          val defLongsymbol = [strSymbol]
        in
          (case V.checkStr(env, defLongsymbol) of
             SOME (strEntry as {env=strEnv, strKind}) => 
             (case strKind of
                V.FUNAPP {id, funId=funId1, argId=argId1} =>
                let
                  val {FunE, Env, ...} = evalTopEnv
                  val ({id=funId2,...}:V.funEEntry) = 
                      (* case SymbolEnv.find(FunE, functorSymbol) of *)
                      case V.checkFunETopEnv(evalTopEnv, functorSymbol) of
                        SOME entry => entry
                      | NONE =>
                        (EU.enqueueError
                           (loc,E.ProvideUndefinedFunctorName ("CP-630",{longsymbol = [functorSymbol]}));
                         raise Fail)
                  val {strKind=argStrKind, env=_} = 
                      case V.checkStr(Env, argument) of
                        SOME entry => entry
                      | NONE => 
                        (EU.enqueueError
                           (loc, E.StrNotFound ("CP-640",{longsymbol = argument}));
                         raise Fail)
                  val argId2 = 
                      case argStrKind of
                        V.STRENV id => id
                      | V.FUNAPP {id,...} => id
                      | _ => 
                        (EU.enqueueError
                           (loc, E.StrNotFound ("CP-650",{longsymbol = argument}));
                         raise Fail)
                  val _ = if FunctorID.eq(funId1, funId2) then ()
                          else 
                            (
                             EU.enqueueError
                               (loc,
                                E.ProvideFunctorIdMismatchInFunapp ("CP-660",{longsymbol = [functorSymbol]}));
                             raise Fail)
                  val _ = if StructureID.eq(argId1, argId2) then ()
                          else 
                            (
                             EU.enqueueError
                               (loc,
                                E.ProvideParamIdMismatchInFunapp ("CP-665",{longsymbol = argument}));
                             raise Fail)
                  val (exnSet, icdecls) = 
                      genTypedExportVarsEnv (path@[strSymbol]) strEnv (exnSet,{exportDecls=nil, bindDecls=nil})
                in
                  (exnSet, 
                   V.reinsertStr(V.emptyEnv, strSymbol, {strKind=strKind, env=strEnv}), 
                   icdecls)
                end
              | _ => 
                (EU.enqueueError
                   (loc, E.ProvideUndefinedStr("CP-670", {longsymbol=path@[strSymbol]}));
                 raise Fail)
             )
           | _ => 
             (EU.enqueueError
                (loc, E.ProvideUndefinedStr("CP-680", {longsymbol=path@[strSymbol]}));
              raise Fail)
          )
        end
  and checkPidecList 
        exnSet
        loc
        path
        (evalTopEnv as {Env=evalEnv, FunE, SigE}) 
        (env, declList) =
      foldl
        (fn (decl, (exnSet, returnEnv, {exportDecls, bindDecls})) =>
            let
               val evalEnv = V.envWithEnv (evalEnv, returnEnv)
               val evalTopEnv = {Env=evalEnv, FunE=FunE, SigE=SigE}
               val (exnSet, newEnv, {exportDecls=newExportDecls, bindDecls=newBindDecls}) =
                   checkPidec exnSet path evalTopEnv (env, decl)
               val returnEnv = V.unionEnv "CP-690" (returnEnv, newEnv)
            in
              (exnSet, returnEnv, {exportDecls=exportDecls@newExportDecls,
                                   bindDecls=bindDecls@newBindDecls})
            end
        )
        (exnSet, 
         V.emptyEnv, 
         {exportDecls=nil, bindDecls=nil}
        )
        declList


  fun checkPitopdec 
        exnSet
        (evalTopEnv as {Env=evalEnv, FunE=evalFunE, SigE=evalSigE})
        (topEnv as {Env, FunE, SigE}, pitopDec) =
      case pitopDec of
        PI.PIDEC pidec =>
        let
          val (exnSet, env, decls) =
              checkPidec exnSet nilPath evalTopEnv (Env, pidec)
        in
          (exnSet, V.topEnvWithEnv(V.emptyTopEnv, env), decls)
        end
      | PI.PIFUNDEC (piFunbind as
                    {functorSymbol,
                     param={strSymbol, sigexp=specArgSig},
                     strexp=specBodyStr,
                     loc})
        =>
        let
          val funEEntry
                as {id, version, used, argSigEnv, argStrEntry, argStrName, dummyIdfunArgTy, polyArgTys, 
                    typidSet, exnIdSet, bodyEnv, bodyVarExp}
            =
            (* case SymbolEnv.find(FunE, functorSymbol) of *)
            case V.checkFunETopEnv(topEnv, functorSymbol) of
              NONE =>
              (EU.enqueueError
                 (symbolToLoc functorSymbol,
                  E.ProvideUndefinedFunctorName("CP-700",{longsymbol=[functorSymbol]}));
               raise Fail
              )
            | SOME entry => entry
          val specArgSigEnv = Sig.evalPlsig evalTopEnv specArgSig
          val _ = if EU.isAnyError () then raise Fail
                  else if FU.eqSize(specArgSigEnv, argSigEnv) 
(*
                          andalso FU.eqEnv {specEnv=specArgSigEnv, implEnv=argSigEnv} then ()
*)
                          andalso FU.eqShape (specArgSigEnv, argSigEnv)
                  then
                    FU.eqEnv {specEnv=specArgSigEnv, implEnv=argSigEnv}
                  else
                    (
                     EU.enqueueError
                       (loc,
                        E.ProvideFunparamMismatch("CP-710",
                                                  {longsymbol=[functorSymbol]}));
                     raise Fail
                    )

          val argEnv = V.reinsertStr(V.emptyEnv, strSymbol, argStrEntry)
(*
          val argEnv =
              V.ENV {varE=SymbolEnv.empty,
                     tyE=SymbolEnv.empty,
                     strE=V.STR (SymbolEnv.singleton(symbolToString strSymbol, argStrEntry))
                    }
*)
          val evalEnv = V.topEnvWithEnv (evalTopEnv, argEnv)
          val (_, {env=specBodyInterfaceEnv, strKind}, _) =
              EI.evalPistr [functorSymbol] evalEnv (LongsymbolSet.empty, specBodyStr)
          val specBodyEnv = EI.internalizeEnv specBodyInterfaceEnv
          val _ = if EU.isAnyError () then raise Fail 
                  else if FU.eqEnv {specEnv=specBodyEnv, implEnv=bodyEnv} then 
                    ()
                  else 
                    (
                     EU.enqueueError
                       (loc,E.ProvideFunctorMismatch("CP-720",{longsymbol=[functorSymbol]}));
                     raise Fail
                    )
          val typidSet = FU.typidSet specBodyEnv
          val (allVars,exnIdSet) = FU.varsInEnv (specBodyEnv, loc)

          fun varToTy (_, var) =
              case var of
                I.ICEXVAR {exInfo={ty,...},...} => ty
              | I.ICEXN {ty,...} => ty
              | I.ICEXN_CONSTRUCTOR _ => BT.exntagITy
              | _ =>  raise bug "VARTOTY\n"
          val bodyTy =
              case allVars of
                nil => BT.unitITy
              | _ => I.TYRECORD (Utils.listToFields (map varToTy allVars))
          val (extraTvars, firstArgTy) = 
              case dummyIdfunArgTy of
                NONE => (nil, NONE)
              | SOME (ty as I.TYRECORD fields) => 
                (map (fn (I.TYVAR tvar) => tvar
                       | _ => raise bug "non tvar in dummyIdfunArgTy")
                     (LabelEnv.listItems fields),
                 SOME (I.TYFUNM([ty],ty)))
              | _ => raise bug "non record ty in dummyIdfunArgTy"

          (* four possibilities in functorTy 
             1. TYPOLY(btvs, TYFUNM([first], TYFUNM(polyList, body)))
                ICFNM1([first], ICFNM1_POLY(polyPats, BODY))
             2. TYPOLY(btvs, TYFUNM([first], body))
                ICFNM1([first], BODY)
             3. TYFUNM(polyList, body)
                ICFNM1_POLY(polyPats, BODY)
             4. TYFUNM([unit], body)
                ICFNM1(UNIT, BODY)
            where body is either
              unit (TYCONSTRUCT ..) 
             or
              record (TYRECORD ..)
            BODY is ICLET(..., ICCONSTANT or ICRECORD)
           *)
          val functorTy1 =
              case polyArgTys of
                nil => bodyTy
              | _ => I.TYFUNM(polyArgTys, bodyTy)

          val functorTy2 =
              case firstArgTy of
                NONE => functorTy1
              | SOME ty => 
                I.TYPOLY
                  (map (fn x => (x, I.UNIV)) extraTvars,
                   I.TYFUNM([ty], functorTy1))

          val functorTy =
              case functorTy2 of
                I.TYPOLY _ => functorTy2
              | I.TYFUNM _ => functorTy2
              | _ => I.TYFUNM([BT.unitITy], functorTy2)

          val exportDecls =
              case bodyVarExp of 
                I.ICVAR {longsymbol, id} => 
                [I.ICEXPORTFUNCTOR 
                   {exInfo={longsymbol=longsymbol, ty=functorTy, version=NONE}, 
                    id=id}
                ]
              | I.ICEXVAR _ => nil
              | _ => raise bug "nonvar in bodyVarExp"
          val funEEntry =
              {id=id, 
               version = NONE,
               used = ref false,
               argSigEnv=argSigEnv, 
               argStrEntry=argStrEntry, 
               argStrName=argStrName, 
               dummyIdfunArgTy=dummyIdfunArgTy, 
               polyArgTys=polyArgTys, 
               typidSet=typidSet, 
               exnIdSet=exnIdSet, 
               bodyEnv=bodyEnv, 
               bodyVarExp=bodyVarExp
              }

          (* val funE =  SymbolEnv.singleton(functorSymbol, funEEntry) *)
          val funE =  SymbolEnv.singleton(functorSymbol, funEEntry)
          val returnTopEnv = V.topEnvWithFunE(V.emptyTopEnv, funE)
        in
          (exnSet, 
           returnTopEnv, 
           {exportDecls=exportDecls,bindDecls=nil}
           )
        end

in
  fun checkProvideFunctorBody
        {topEnv:V.topEnv, evalEnv:V.topEnv, argSigEnv:V.env, 
         specArgSig:PL.plsigexp, defLoc:Loc.loc,
         functorSymbol:Symbol.symbol, returnEnv:V.env, 
         specBodyStr:PI.pistrexp, specLoc:Loc.loc} =
      let
        val specArgSigEnv = Sig.evalPlsig topEnv specArgSig
        val _ = if FU.eqSize(specArgSigEnv, argSigEnv) 
                   andalso FU.eqShape (specArgSigEnv, argSigEnv)
                then
                  FU.eqEnv {specEnv=specArgSigEnv, implEnv=argSigEnv}
                else
                  (
                   EU.enqueueError
                     (defLoc,
                      E.ProvideFunparamMismatch("CP-710",
                                                {longsymbol=[functorSymbol]}));
                   raise Fail
                  )
        val pidec = PI.PISTRUCTURE {symbol=functorSymbol, strexp=specBodyStr, loc=specLoc}
        val strKind = V.STRENV (StructureID.generate())
        val strEntry = {env=returnEnv, strKind=strKind}
        val bodyEnv = V.reinsertStr(V.emptyEnv, functorSymbol, strEntry)
(*
        val bodyEnv = V.ENV {varE=SymbolEnv.empty,
                             tyE=SymbolEnv.empty,
                             strE=V.STR (SymbolEnv.singleton(funid, strEntry))
                            }
*)
        val (exnSet, bodyEnv as V.ENV{strE=V.STR strMap,...}, {exportDecls, bindDecls}) =
            checkPidec ExnID.Set.empty nilPath evalEnv (bodyEnv, pidec)
        val newEnv = 
            case SymbolEnv.find(strMap, functorSymbol) of
              NONE => raise bug "impossible"
            | SOME {env,...} => env
      in
        (bindDecls, newEnv)
      end
      handle Fail => (nil, returnEnv)

  (* 
     evalTopEnv: the top-level environment constructred so far
     topEnv : the top-level environment of the current declarations 
              to be checked
   *)
  fun checkPitopdecList
        (evalTopEnv: NameEvalEnv.topEnv)
        (topEnv:NameEvalEnv.topEnv, pitopdecList:PatternCalcInterface.pitopdec list) 
       : {exportDecls:IDCalc.icdecl list, bindDecls:IDCalc.icdecl list} =
      let
        val (exnSet, returnTopEnv, icdecls) =
            foldl
              (fn (pitopdec, (exnSet, returnTopEnv, {exportDecls, bindDecls})) =>
                  let
                    val evalTopEnv = V.topEnvWithTopEnv (evalTopEnv, returnTopEnv)
                    val (exnSet, newTopEnv, {exportDecls=newExportDecls, bindDecls=newBindDecls}) =
                        checkPitopdec exnSet evalTopEnv (topEnv,pitopdec)
                        handle e => raise e
                    val returnTopEnv =
                        V.unionTopEnv "CP-730" (returnTopEnv, newTopEnv)
                  in
                    (exnSet, 
                     returnTopEnv, 
                     {exportDecls=exportDecls@newExportDecls,
                      bindDecls=bindDecls@newBindDecls}
                     )
                  end
              )
              (ExnID.Set.empty,
               V.emptyTopEnv, 
               {exportDecls=nil, bindDecls=nil}
              )
              pitopdecList
      in
        icdecls
      end
      handle Fail => {exportDecls=nil, bindDecls=nil}
           | exn => raise exn

end
end
