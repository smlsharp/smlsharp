(* the initial error code of this file : NEF-001 *)
structure FunctorUtils =
struct

  structure IT = IDTypes
  structure V = NameEvalEnv
  structure U = NameEvalUtils
  structure TF = TfunVars
  structure A = Absyn
  structure I = IDCalc
  structure L = SetLiftedTys
  structure N = NormalizeTy
  structure BV = BuiltinEnv
  structure Sig = EvalSig
  structure P = PatternCalc
  structure EU = UserErrorUtils
(*
  structure Ty = EvalTy
  structure ITy = EvalIty
  structure S = Subst
  structure PI = PatternCalcInterface
  structure E = NameEvalError
  structure N = NormalizeTy
*)
  fun bug s = Control.Bug ("NameEval (FunctorUtils): " ^ s)

  val DUMMYIDFUN = "id"

local
in
  fun evalFunArg (topEnv, argSig, loc) =
      let
        fun materializeTstr path (name, tstr, icdecls) =
            (
            case tstr of
              V.TSTR tfun =>
              (case IT.derefTfun tfun of
                 tfun as (IT.TFUN_VAR (tfv as ref tfunkind)) =>
                 (case tfunkind of
                    IT.TFV_SPEC {id, iseq, formals} =>
                    (case formals of 
                       nil => 
                       (U.print "spec tfv\n";
                        U.print "tstr\n";
                        U.printTstr tstr;
                        U.print "\n";
                        U.print "tfun\n";
                        U.printTfun tfun;
                        U.print "\n";
                        U.print "name\n";
                        U.print name;
                        U.print "\n";
                       raise bug "spec tfv" 
                       )
                     | _ =>
                       let
                         val _ =
                             tfv :=
                             IT.TFUN_DTY
                               {id=id,
                                iseq=iseq,
                                formals=formals,
                                conSpec=SEnv.empty,
                                liftedTys=IT.emptyLiftedTys,
                                dtyKind=IT.FUNPARAM
                               }
                       in
                         icdecls
                       end
                    )
                  | _ => icdecls
                 )
               | _ => icdecls
              )
            | _ => icdecls
            )

        fun materializeTyE path tyE =
            SEnv.foldri (materializeTstr path) nil tyE

        fun materializeStrE path (V.STR envMap) =
            SEnv.foldri
            (fn (name, env, icdecls) =>
                let
                  val icdecls1 = materializeEnv (path@[name]) env
                in
                  icdecls @ icdecls1
                end
            )
            nil
            envMap

        and materializeEnv path (V.ENV {varE, tyE, strE, ...}) =
            let
              val icdecls1 = materializeTyE path tyE
              val icdecls2 = materializeStrE path strE
            in
              icdecls1 @ icdecls2
            end

        fun evalTstr path (name, tstr, env) =
            case tstr of
              V.TSTR tfun =>
              (case IT.derefTfun tfun of
                 IT.TFUN_DEF _ => V.rebindTstr(env, name, tstr)
               | IT.TFUN_VAR (ref tfunkind) =>
                 (case tfunkind of
                    IT.TFV_SPEC _ => raise bug "unmaterialized (1)"
                  | IT.TFV_DTY _ =>  raise bug "unmaterialized (2)"
                  | IT.TFUN_DTY _ => V.rebindTstr(env, name, tstr)
                  | IT.REALIZED _ => raise bug "REALIZED"
                  | IT.INSTANTIATED {tfunkind, tfun} => raise bug "INSTANTIATED"
                  | IT.FUN_TOTVAR {tfunkind, tvar} =>
                    (case tfunkind of
                       IT.TFV_SPEC{id,iseq,...} =>
                       let
                         val tstr = V.TSTR_TOTVAR{id=id, iseq=iseq,tvar=tvar}
                       in
                         V.rebindTstr(env, name, tstr)
                       end
                     | _ => raise bug "non spec tfv"
                    )
                  | IT.FUN_DTY {tfun, varE, formals, conSpec, liftedTys} =>
                    let
                      val env = 
                          V.rebindTstr(env,
                                       name,
                                       V.TSTR_DTY {tfun=tfun,
                                                   varE=varE,
                                                   formals=formals,
                                                   conSpec=conSpec}
                                      )
                      val env = V.envWithVarE(env, varE)
                    in
                      env
                    end
                 )
              )
            | V.TSTR_DTY {tfun, varE=_, formals=_, conSpec=_} =>
              (case IT.derefTfun tfun of
                 IT.TFUN_DEF _ => raise bug "DEF in TSTR_DTY"
               | IT.TFUN_VAR (ref tfunkind) =>
                 (case tfunkind of
                    IT.TFV_SPEC _ => raise bug "unmaterialized (3)"
                  | IT.TFV_DTY _ =>  
                    (U.print "TFV_DTY to evalTstr\n";
                     U.print name;
                     U.print "\n";
                     U.printTstr tstr;
                     raise bug "unmaterialized (4)"
                    )
                  | IT.TFUN_DTY _ => V.rebindTstr(env, name, tstr)
                  | IT.REALIZED _ => raise bug "REALIZED"
                  | IT.INSTANTIATED _ => raise bug "INSTANTIATED"
                  | IT.FUN_TOTVAR _ => raise bug "TOTVAR(4)"
                  | IT.FUN_DTY {tfun,varE,formals,liftedTys,conSpec} =>
                    let
                      val envTstr = V.TSTR_DTY {tfun=tfun,
                                                varE=varE,
                                                formals=formals,
                                                conSpec=conSpec}
                    in
                      V.envWithVarE(V.rebindTstr(env, name, envTstr), varE)
                    end
                 )
              )
            | V.TSTR_TOTVAR _ => V.rebindTstr(env, name, tstr)

        fun evalTyE path tyE env =
            SEnv.foldri (evalTstr path) env tyE
        fun evalVarE path varE env =
            SEnv.foldri
            (fn (name, idstatus, (pats, env, exnTagDecls)) =>
                case idstatus of
                  IT.IDSPECVAR ty =>
                  let
                    val varId = VarID.generate()
                    val idstatus = IT.IDVAR varId
                    val pat = ({path=path@[name],id=varId},ty)
(*
                    val pat =
                        I.ICPATTYPED
                          (I.ICPATVAR({path=path@[name],id=varId},loc),ty,loc)
*)
                  in
                    (pat::pats,
                     V.rebindId(env, name, idstatus),
                     exnTagDecls
                    )
                  end
                | IT.IDSPECEXN ty => 
                  let
                    val varId = VarID.generate()
                    val idstatus = IT.IDVAR varId
(*
                    val pat =
                        I.ICPATTYPED
                          (I.ICPATVAR
                             ({path=path@[name],id=varId},loc),
                           BV.exntagTy,
                           loc)
*)
                    val varInfo = {path=path@[name],id=varId}
                    val pat = (varInfo, BV.exntagTy)
                    val exnId = ExnID.generate()
                    val exnInfo = {path=path, id=exnId, ty=ty}
                    val idstatus = IT.IDEXN {id=exnId, ty=ty}
                    val exnTagDecl =
                        I.ICEXNTAGD ({exnInfo=exnInfo, varInfo=varInfo}, loc)
(*
                    val pat =
                        I.ICPATEXN_CONSTRUCTOR
                          ({path=path@[name],ty=ty, id=exnId},loc)
*)
                  in
                    (pat::pats,
                     V.rebindId(env, name, idstatus),
                     exnTagDecl::exnTagDecls
                    )
                  end
                | IT.IDSPECCON => (pats, env, exnTagDecls)
                | idstatus =>
                  (pats, V.rebindId(env, name, idstatus), exnTagDecls)
            )
            (nil, env, nil)
            varE
        fun evalSpecStrE path (V.STR envMap) returnEnv =
            SEnv.foldri
              (fn (name, specEnv, (pats, returnEnv, exnTagDecls)) =>
                  let
                    val (newPats, newEnv, newExnTagDecls) =
                        evalEnv (path@[name]) specEnv
                  in
                    (newPats@pats,
                     V.rebindStr(returnEnv, name, newEnv),
                     newExnTagDecls @ exnTagDecls
                    )
                  end
              )
              (nil, returnEnv, nil)
              envMap
        (* the order must be the same as that of varsInEnv
           the order is foldr and str -> env
         *)
        and evalEnv path (V.ENV {varE, tyE, strE, ...}) =
            let
              val (pats1, env, exnTagDecls1) =
                  evalSpecStrE path strE V.emptyEnv
              val (pats2, env, exnTagDecls2) = evalVarE path varE env
              val env = evalTyE path tyE env
            in
              (pats1@pats2, env, exnTagDecls1@exnTagDecls2)
            end

        val argSig = Sig.evalPlsig topEnv argSig
        val (_,argSpecEnv) = Sig.refreshSpecEnv argSig
        val specTfvs =
            TfvMap.listItemsi
              (TF.tfvsEnv TF.specKind nil (argSpecEnv, TfvMap.empty))
            handle exn => raise exn
        val extraTvarsMap =
            foldr
              (fn ((tfv as ref (tfunkind as IT.TFV_SPEC {iseq, formals, ...}),
                    path),
                   extraTvarsMap)
                  =>
                  (case formals of
                     nil =>
                     let
                       val tvarName =String.concatWith "." path
                       val tvar = {name=tvarName,
                                   lifted=true,
                                   id = TvarID.generate(),
                                   eq = if iseq then A.EQ else A.NONEQ}
                     in
                       (tfv := IT.FUN_TOTVAR{tfunkind=tfunkind, tvar=tvar};
                        PathEnv.insert(extraTvarsMap, path, tvar))
                     end
                   | _ => extraTvarsMap
                  )
                | _ => raise bug "non spec tfv"
              )
              PathEnv.empty
              specTfvs
        val extraTvars = PathEnv.listItems extraTvarsMap
        val pathTfvListList = L.setLiftedTysSpecEnv argSpecEnv
        val tfvDecls = materializeEnv nil argSpecEnv
        fun materializeDtyTstr (path,tfv) =
            let
              val (name, path) = case List.rev path of
                                   h::tl => (h, List.rev tl)
                                 | _ => raise bug "nil path"
            in
              case !tfv of
                 IT.TFV_SPEC _ => raise bug "non dty tfv (4)"
               | IT.TFV_DTY {id, iseq, formals, conSpec, liftedTys} =>
                 let
                   val returnTy =
                       IT.TYCONSTRUCT
                         {typ={path=path@[name],tfun=IT.TFUN_VAR tfv},
(* FIXME
                          args= map (fn tv=>IT.TYWILD) formals}
*)
                          args= map (fn tv=>IT.TYVAR tv) formals}
                   val (varE, conbinds) =
                       SEnv.foldri
                         (fn (name, tyOpt, (varE, conbinds)) =>
                             let
                               val conId = ConID.generate()
                               val conInfo = {id=conId, path=path@[name]}
                               val conTy = 
                                   case tyOpt of
                                     NONE => returnTy
                                   | SOME ty => IT.TYFUNM([ty], returnTy)
                               val conTy =
                                   case formals of
                                     nil => conTy
                                   | _ => 
                                     IT.TYPOLY
                                       (
                                        map
                                          (fn tv =>(tv,IT.UNIV))
                                          formals,
                                        conTy
                                       )
                               val idstatus = IT.IDCON {id=conId,ty=conTy}
                             in
                               (SEnv.insert(varE, name, idstatus),
                                {datacon={path=path@[name],id=conId},
                                 tyOpt=tyOpt}
                                :: conbinds
                               )
                             end
                         )
                         (SEnv.empty, nil)
                         conSpec
                         (* is it safe to create a new var here? *)
                   val envTfun =
                       IT.TFUN_VAR
                         (ref
                            (IT.TFUN_DTY{id=id,
                                        iseq=iseq,
                                        formals=formals,
                                        conSpec=conSpec,
                                        liftedTys=liftedTys,
                                        dtyKind=IT.DTY
                                       }
                            )
                         )
                   val _ = tfv := IT.FUN_DTY{tfun=envTfun,
                                            varE=varE,
                                            formals=formals,
                                            liftedTys=liftedTys,
                                            conSpec=conSpec
                                           }
                   val decl =
                       {args=formals,
                        typInfo={path=path@[name], tfun=envTfun},
                        conbinds=conbinds,
                        loc = loc
                       }
                 in
                   decl
                 end
               | _ => raise bug "non tfv"
            end
        val _ = 
            map (fn pathTfvList =>
                    (map materializeDtyTstr pathTfvList))
                pathTfvListList
        val (polyArgPats, argEnv, exnTagDecls) = evalEnv nil argSpecEnv 
        val dummyIdfunArgTy =
            case extraTvars of
              nil => NONE
            | _ => 
              SOME
                (
                 IT.TYRECORD
                   (Utils.listToFields
                      (map (fn tvar => IT.TYVAR tvar) extraTvars)
                   )
                )
        val dummyIdfunTy =
            case dummyIdfunArgTy of
              SOME ty => SOME (IT.TYFUNM([ty],ty))
            | NONE => NONE
        val firstArgPat =
            case dummyIdfunTy of
              SOME ty => 
              SOME ({path=[DUMMYIDFUN], id = VarID.generate()},
                    [ty])
            | NONE => NONE
(*
        val typedIdpat =
            I.ICPATTYPED
              (I.ICPATVAR({path=[DUMMYIDFUN], id = VarID.generate()}, loc),
               dummyIdfunTy,
               loc)
*)
(*
        val recordPat =
            I.ICPATRECORD{flex=false,
                          fields=Utils.listToTuple argPatList,
                          loc=loc}
*)
     in
       {
        argSig=argSig,
        argEnv=argEnv,
        extraTvars=extraTvars,
        polyArgPats=polyArgPats,
        exnTagDecls=exnTagDecls,
        dummyIdfunArgTy=dummyIdfunArgTy,
        firstArgPat=firstArgPat,
        tfvDecls = tfvDecls
       }
     end

  fun varsInEnv set loc path vars (V.ENV{varE, strE=V.STR envMap,...})
      : ((string list * I.icexp) list * ExnID.Set.set) =
        let
          val (vars, set) = varsInVarE set loc path vars varE
        in
          varsInStrE 
            set
            loc
            path
            vars
            envMap
        end
  and varsInVarE set loc path vars varE
      : ((string list * I.icexp) list * ExnID.Set.set) =
      SEnv.foldri
        (fn (name, IT.IDVAR id, (vars, set)) => 
            ((path@[name],I.ICVAR({id=id, path=path@[name]}, loc))
             :: vars, set)
          | (name, IT.IDEXVAR {path=exPath, ty}, (vars, set)) =>
            (* CHECKME:
               Here we change the external name to the effective name.
             *)
            ((path@[name], I.ICEXVAR ({path=exPath, ty=ty},loc))
             :: vars, set)
          | (name, IT.IDCON _, (vars, set)) => (vars, set)
          | (name, IT.IDEXN {id, ty}, (vars, set)) =>
            if ExnID.Set.member(set, id) then (vars, set)
            else
              ((path@[name],
               I.ICEXN_CONSTRUCTOR({id=id,ty=ty,path=path@[name]},loc))
              ::vars,
               ExnID.Set.add(set,id)
              )
          | (name, IT.IDEXNREP {id, ty}, (vars, set)) =>
            if ExnID.Set.member(set, id) then (vars, set)
            else
              ((path@[name],
                I.ICEXN_CONSTRUCTOR({id=id,ty=ty,path=path@[name]},loc))
               ::vars,
               ExnID.Set.add(set,id)
              )
(*
            I.ICEXN ({id=id, ty=ty, path=path@[name]}, loc) :: vars
*)
          | (name, IT.IDEXEXN {path,ty}, (vars, set)) => (vars,set)
(*
            I.ICEXEXN({path=path, ty=ty}, loc) :: vars
*)
          | (name, IT.IDOPRIM _, _) =>
            (print name; print "\n"; raise bug "IDOPRIM varsInVarE")
          | (name, IT.IDBUILTINVAR _, (vars, set)) => (vars, set)
          | (name, IT.IDSPECVAR _, (vars, set)) => (vars, set)
          | (name, IT.IDSPECEXN _, (vars, set)) => (vars, set)
          | (name, IT.IDSPECCON, (vars, set)) => (vars, set)
        )
        (vars, set)
        varE
  and varsInStrE set loc path vars envMap
      : ((string list * I.icexp) list * ExnID.Set.set) =
      SEnv.foldri
        (fn (strName,env, (vars, set)) =>
            varsInEnv set loc (path@[strName]) vars env
        )
        (vars, set)
        envMap


  fun makeBodyEnv returnEnv loc =
      let
        fun typidSetEnv (V.ENV {tyE,strE=V.STR envMap,...},typidSet) =
            let
              val typidSet = typidSetTyE (tyE,typidSet)
            in
              SEnv.foldl typidSetEnv typidSet envMap
            end
        and typidSetTyE (tyE,typidSet) =
            SEnv.foldl typidSetTstr typidSet tyE
        and typidSetTstr (tstr, typidSet) =
            case tstr of
              V.TSTR tfun => typidSetTfun (tfun, typidSet)
            | V.TSTR_DTY {tfun,...} => typidSetTfun (tfun, typidSet)
            | V.TSTR_TOTVAR _ => typidSet
        and typidSetTfun (tfun, typidSet) =
            case IT.derefTfun tfun of
              IT.TFUN_VAR(ref (IT.TFUN_DTY{id,...})) =>
              TypID.Set.add(typidSet, id)
            | _ => typidSet
                         
        val typidSet = typidSetEnv (returnEnv, TypID.Set.empty)
(*
        val typidSet = 
            foldl
            (fn (decl,typidSet) =>
                case decl of
                  I.ICDATATYPE dtyBinds => 
                  foldl
                   (fn ({typInfo={tfun,...},...}, typidSet) =>
                       case IT.derefTfun tfun of
                         IT.TFUN_VAR(ref (IT.TFUN_DTY{id,...})) =>
                         TypID.Set.add(typidSet, id)
                       | _ => raise bug "non dty"
                   )
                   typidSet
                   dtyBinds
                | I.ICOPAQUETYPE {tfun,...} => 
                  (case IT.derefTfun tfun of
                     IT.TFUN_VAR(ref (IT.TFUN_DTY{id,...})) =>
                     TypID.Set.add(typidSet, id)
                   | _ => raise bug "non dty"
                  )
                | _ => typidSet
            )
            TypID.Set.empty
            bodyDecls
*)
        val (allVars,exnIdSet) =
            varsInEnv ExnID.Set.empty loc nil nil returnEnv
      in
        {allVars=allVars,
         typidSet=typidSet,
         exnIdSet=exnIdSet
        }
      end


  exception Fail
  fun makeEqEnv (formals1, formals2) =
      let
        val _ = if length formals1 = length formals2 then ()
                else raise Fail
        val tvarPairs = ListPair.zip (formals1, formals2)
      in
        foldl
        (fn ((tvar1, tvar2), eqEnv) =>
            TvarMap.insert(eqEnv, tvar1, tvar2))
        TvarMap.empty
        tvarPairs
      end

  fun visitTfun (tfun1, tfun2) =
      case (IT.derefTfun tfun1, IT.derefTfun tfun2) of
        (IT.TFUN_VAR
           (tfv as (ref(IT.TFV_DTY{id=id1,iseq,formals, conSpec, liftedTys}))),
         IT.TFUN_VAR (ref((IT.TFV_DTY{id=id2,...})))) =>
        tfv := IT.TFV_DTY{id=id2,
                          iseq=iseq,
                          formals=formals,
                          conSpec=conSpec,
                          liftedTys=liftedTys}
      | (IT.TFUN_VAR
           (tfv as (ref(IT.TFV_SPEC{id=id1,iseq,formals}))),
         IT.TFUN_VAR (ref((IT.TFV_SPEC{id=id2,...})))) =>
        tfv := IT.TFV_SPEC{id=id2,
                           iseq=iseq,
                           formals=formals}
      | (IT.TFUN_VAR
           (tfv as (ref(IT.TFUN_DTY{id=id1,
                                    iseq,
                                    formals,
                                    conSpec,
                                    dtyKind,
                                    liftedTys}))),
         IT.TFUN_VAR (ref((IT.TFUN_DTY{id=id2,...})))) =>
        tfv := IT.TFUN_DTY{id=id2,
                           iseq=iseq,
                           formals=formals,
                           conSpec=conSpec,
                           dtyKind=dtyKind,
                           liftedTys=liftedTys}
      | _ => ()

  fun visitTstr (tstr1, tstr2) =
      case (tstr1, tstr2) of
        (V.TSTR tfun1, V.TSTR tfun2) => visitTfun (tfun1, tfun2)
      | (V.TSTR_DTY {tfun=tfun1,...}, V.TSTR_DTY {tfun=tfun2,...}) => 
        visitTfun (tfun1, tfun2)
      | _ => ()

  fun visitEnv (V.ENV {varE=varE1, tyE=tyE1, strE=V.STR envMap1},
                V.ENV {varE=varE2, tyE=tyE2, strE=V.STR envMap2}
               )
      =
      let
        val tyE2rest =
            SEnv.foldli
            (fn (name, tstr1, tyE2rest) =>
                let
                  val (tyE2rest, tstr2) =
                      if SEnv.inDomain(tyE2, name) then
                        SEnv.remove(tyE2, name)
                      else raise Fail
                  val _ = visitTstr (tstr1, tstr2)
                in
                  tyE2rest
                end
            )
            tyE2
            tyE1
        val envMap2rest = 
            SEnv.foldli
            (fn (name, env1, envMap2rest) =>
                let
                  val (envMap2rest, env2) =
                      if SEnv.inDomain(envMap2rest, name) then
                        SEnv.remove(envMap2rest, name)
                      else raise Fail
                  val _ = visitEnv (env1, env2)
                in
                  envMap2rest
                end
            )
            envMap2
            envMap1
      in
        ()
      end
                        
  fun eqConSpec ((formals1, conSpec1), (formals2, conSpec2)) =
      if length formals1 = length formals2 then 
        let
          val tvarPairs = ListPair.zip (formals1, formals2)
          val eqEnv = foldl
                        (fn (({id=tv1,name=_,eq=_,lifted=_},
                              {id=tv2,name=_,eq=_,lifted=_}),
                             eqEnv) =>
                            TvarID.Map.insert(eqEnv, tv1, tv2)
                        )
                        TvarID.Map.empty
                        tvarPairs
          val _ = if length (SEnv.listItems conSpec1) = 
                     length (SEnv.listItems conSpec2)
                  then ()
                  else raise Fail
        in
          SEnv.appi
            (fn (name, tyOpt1) =>
                case SEnv.find(conSpec2, name) of
                  NONE => raise Fail
                | SOME tyOpt2 => 
                  (case (tyOpt1, tyOpt2) of
                     (NONE, NONE) => ()
                   | (SOME ty1, SOME ty2) =>
                     if N.equalTy eqEnv (ty1,ty2) then ()
                     else raise Fail
                   | _ => raise Fail
                  )
            )
            conSpec2
        end 
      else raise Fail

  fun eqTfunkind (tfunkind1, tfunkind2) =
      case (tfunkind1, tfunkind2) of
        (IT.TFUN_DTY {id=id1,
                      iseq=iseq1,
                      formals=formals1,
                      conSpec=conSpec1,...},
         IT.TFUN_DTY {id=id2,
                      iseq=iseq2,
                      formals=formals2,
                      conSpec=conSpec2,...}
        ) => 
        if TypID.eq(id1, id2) andalso iseq1 = iseq2 then
          eqConSpec((formals1,conSpec1),(formals2,conSpec2)) 
        else raise Fail
      | (IT.INSTANTIATED _, _) => raise bug "INSTANTIATED in spec"
      | (_, IT.INSTANTIATED _) => raise bug "INSTANTIATED in spec"
      | (IT.FUN_TOTVAR _, _) => raise bug "FUN_TOTVAR in spec"
      | (_, IT.FUN_TOTVAR _) => raise bug "FUN_TOTVAR in spec"
      | (IT.FUN_DTY _, _) => raise bug "FUN_DTY in spec"
      | (_, IT.FUN_DTY _) => raise bug "FUN_DTY in spec"
      | (IT.TFV_SPEC{id=id1, iseq=iseq1, formals=formals1},
         IT.TFV_SPEC{id=id2, iseq=iseq2, formals=formals2})
        => if TypID.eq(id1, id2) andalso
              iseq1 = iseq2 andalso
              length formals1 = length formals2
           then ()
           else raise Fail
      | (IT.TFV_DTY {id=id1,
                     iseq=iseq1,
                     formals=formals1,
                     conSpec=conSpec1,
                     liftedTys=liftedTys1},
         IT.TFV_DTY {id=id2,
                     iseq=iseq2,
                     formals=formals2,
                     conSpec=conSpec2,
                     liftedTys=liftedTys2}
        ) => 
        if TypID.eq(id1, id2) andalso iseq1 = iseq2 then
          eqConSpec((formals1,conSpec1),(formals2,conSpec2)) 
        else raise Fail
      | _ => raise Fail
                   
  fun eqTfun (tfun1, tfun2) =
      case (IT.derefTfun tfun1, IT.derefTfun tfun2) of
      (IT.TFUN_DEF {iseq=iseq1, formals=formals1, realizerTy=ty1},
       IT.TFUN_DEF {iseq=iseq2, formals=formals2, realizerTy=ty2}) =>
      let
        val _ = if iseq1 = iseq2 then () else raise Fail
        val tvarPairs = if length formals1 = length formals2 then 
                          ListPair.zip (formals1, formals2)
                        else raise Fail
        val eqEnv = foldl
                      (fn (({id=tv1,name=_,eq=_,lifted=_},
                            {id=tv2,name=_,eq=_,lifted=_}),
                           eqEnv) =>
                          TvarID.Map.insert(eqEnv, tv1, tv2)
                      )
                      TvarID.Map.empty
                      tvarPairs
      in
        if N.equalTy eqEnv (ty1, ty2) then ()
        else raise Fail
      end
    | (IT.TFUN_VAR(ref(tfunKind1)),IT.TFUN_VAR(ref(tfunKind2))) => 
      eqTfunkind (tfunKind1, tfunKind2)
    | _ => raise Fail
                
  fun eqTstr (tstr1, tstr2) =
      case (tstr1, tstr2) of
        (V.TSTR tfun1, V.TSTR tfun2) =>
        eqTfun (tfun1, tfun2)
      | (V.TSTR_DTY {tfun=tfun1,...}, V.TSTR_DTY {tfun=tfun2,...}) =>
        eqTfun (tfun1, tfun2)
      | (V.TSTR_TOTVAR _,_) => raise bug "TSTR_TOTVAR in sig"
      | (_,V.TSTR_TOTVAR _) => raise bug "TSTR_TOTVAR in sig"
      | _ => raise Fail
  fun eqTyE (tyE1, tyE2) =
      let
        val _ = if length (SEnv.listItems tyE1) = length (SEnv.listItems tyE1)
                   then ()
                else raise Fail
      in
        SEnv.appi
          (fn (name, tstr1) =>
              case SEnv.find(tyE2, name) of
                NONE => raise Fail
              | SOME tstr2 => eqTstr (tstr1, tstr2)
          )
          tyE1
      end
  fun eqIdstatus (st1, st2) =
      case (st1, st2) of
      (IT.IDSPECVAR ty1,IT.IDSPECVAR ty2) =>
      if N.equalTy TvarID.Map.empty (ty1,ty2) then () else raise Fail
    | (IT.IDSPECEXN ty1, IT.IDSPECEXN ty2) => 
      if N.equalTy TvarID.Map.empty (ty1,ty2) then () else raise Fail
    | (IT.IDSPECCON, IT.IDSPECCON) => ()
    | (IT.IDCON {ty=ty1,...}, IT.IDCON {ty=ty2,...}) =>
      if N.equalTy TvarID.Map.empty (ty1,ty2) then () else raise Fail
    | (IT.IDEXN {ty=ty1,...}, IT.IDEXN {ty=ty2,...}) =>
      if N.equalTy TvarID.Map.empty (ty1,ty2) then () else raise Fail
    | (IT.IDEXNREP {ty=ty1,...}, IT.IDEXNREP {ty=ty2,...}) =>
      if N.equalTy TvarID.Map.empty (ty1,ty2) then () else raise Fail
    | (IT.IDEXEXN {ty=ty1,...}, IT.IDEXN {ty=ty2,...}) =>
      if N.equalTy TvarID.Map.empty (ty1,ty2) then () else raise Fail
    | (IT.IDEXEXN {ty=ty1,...}, IT.IDEXEXN {ty=ty2,...}) =>
      if N.equalTy TvarID.Map.empty (ty1,ty2) then () else raise Fail
    | (IT.IDEXVAR _, IT.IDVAR _) => ()
    | _ => 
      (U.print "eqIdstatus\n";
       U.print "st1:\n";
       U.printIdstatus st1;
       U.print "\n";
       U.print "st2:\n";
       U.printIdstatus st2;
       U.print "\n";
      raise Fail
      )

  fun eqVarE (varE1, varE2) =
      let
        val _ = if length(SEnv.listItems varE1) = length(SEnv.listItems varE2)
                then ()
                else raise Fail
      in
        SEnv.appi
          (fn (name, st1) =>
              case SEnv.find(varE2, name) of
                NONE => raise Fail
              | SOME st2 => eqIdstatus (st1, st2)
          )
          varE1
      end
  fun eqEnv (env1 as V.ENV {varE=varE1, tyE=tyE1, strE=strE1},
             env2 as V.ENV {varE=varE2, tyE=tyE2, strE=strE2}
            )
      =
      let
        val _ = visitEnv (env1, env2)
        val _ = eqTyE (tyE1, tyE2)
        val _ = eqVarE (varE1, varE2)
        val _ = eqStrE (strE1, strE2)
      in
        true
      end
      handle Fail => false
   and eqStrE (V.STR map1, V.STR map2) =
      let
        val _ = if length(SEnv.listItems map1) = length(SEnv.listItems map2)
                then ()
                else raise Fail
      in
        SEnv.appi
          (fn (name, env1) =>
              case SEnv.find(map2, name) of
                NONE => raise Fail
              | SOME env2 => if eqEnv (env1, env2) then () else raise Fail
          )
          map1
      end
       

  fun sigEq topEnv (sig1, sig2) =
      let
        val env1 = Sig.evalPlsig topEnv sig1
        val env2 = Sig.evalPlsig topEnv sig2
      in
        if EU.isAnyError () then false 
        else eqEnv (env1,env2)
      end

end
end
