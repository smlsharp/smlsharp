(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : NEF-001 *)
structure FunctorUtils  :
sig
  val evalFunArg : NameEvalEnv.topEnv * PatternCalc.plsigexp * Loc.loc
                   -> {argStrEntry : NameEvalEnv.strEntry, 
                       argSig : NameEvalEnv.env,
                       dummyIdfunArgTy : IDCalc.ty option,
                       exnTagDecls : IDCalc.icdecl list,
                       extraTvars : IDCalc.tvar list,
                       firstArgPat : (IDCalc.varInfo * IDCalc.ty list) option,
                       polyArgPats : (IDCalc.varInfo * IDCalc.ty) list, 
                       tfvDecls : IDCalc.icdecl list}
  val varsInEnv : ExnID.Set.set
                  -> Loc.loc
                  -> string list
                  -> (string list * IDCalc.icexp) list
                  -> NameEvalEnv.env
                  -> (string list * IDCalc.icexp) list * ExnID.Set.set
  val makeBodyEnv : NameEvalEnv.env
                    -> Loc.loc
                       -> {allVars:(string list * IDCalc.icexp) list,
                           exnIdSet:ExnID.Set.set, typidSet:TypID.Set.set}
  val eqEnv : {specEnv:NameEvalEnv.env, implEnv:NameEvalEnv.env} -> bool
  val eqSize : NameEvalEnv.env * NameEvalEnv.env -> bool
  val makeFunctorArgs : Loc.loc -> string list list -> NameEvalEnv.env -> IDCalc.icexp list
end
=
struct
local
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
  fun bug s = Control.Bug ("NameEval (FunctorUtils): " ^ s)
  val DUMMYIDFUN = "id"
in
  fun evalFunArg (topEnv, argSig, loc) =
      let
        fun materializeTstr path (name, tstr, icdecls) =
            (
            case tstr of
              V.TSTR tfun =>
              (case I.derefTfun tfun of
                 tfun as (I.TFUN_VAR (tfv as ref tfunkind)) =>
                 (case tfunkind of
                    I.TFV_SPEC {id, iseq, formals} =>
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
                             I.TFUN_DTY
                               {id=id,
                                iseq=iseq,
				runtimeTy = BuiltinType.BOXEDty,
                                formals=formals,
                                conSpec=SEnv.empty,
                                originalPath=path,
                                liftedTys=I.emptyLiftedTys,
                                dtyKind=I.FUNPARAM
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
            (fn (name, {env,strKind}, icdecls) =>
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

        fun genArgTstr path (name, tstr, env) =
            case tstr of
              V.TSTR tfun =>
              (case I.derefTfun tfun of
                 I.TFUN_DEF _ => V.rebindTstr(env, name, tstr)
               | I.TFUN_VAR (ref tfunkind) =>
                 (case tfunkind of
                    I.TFV_SPEC _ => raise bug "unmaterialized (1)"
                  | I.TFV_DTY _ =>  raise bug "unmaterialized (2)"
                  | I.TFUN_DTY _ => V.rebindTstr(env, name, tstr)
                  | I.REALIZED _ => raise bug "REALIZED"
                  | I.INSTANTIATED {tfunkind, tfun} => raise bug "INSTANTIATED"
                  | I.FUN_DTY {tfun, varE, formals, conSpec, liftedTys} =>
                    V.rebindTstr(env, name, V.TSTR tfun)
                 )
              )
            | V.TSTR_DTY {tfun, varE=_, formals=_, conSpec=_} =>
              (case I.derefTfun tfun of
                 I.TFUN_DEF _ => raise bug "DEF in TSTR_DTY"
               | I.TFUN_VAR (ref tfunkind) =>
                 (case tfunkind of
                    I.TFV_SPEC _ => raise bug "unmaterialized (3)"
                  | I.TFV_DTY _ =>  
                    (U.print "TFV_DTY to genArgTstr\n";
                     U.print name;
                     U.print "\n";
                     U.printTstr tstr;
                     raise bug "unmaterialized (4)"
                    )
                  | I.TFUN_DTY _ => V.rebindTstr(env, name, tstr)
                  | I.REALIZED _ => raise bug "REALIZED"
                  | I.INSTANTIATED _ => raise bug "INSTANTIATED"
                  | I.FUN_DTY {tfun,varE,formals,liftedTys,conSpec} =>
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

        fun genArgTyE path tyE env = SEnv.foldri (genArgTstr path) env tyE

        fun genArgVarE path varE env =
            SEnv.foldri
            (fn (name, idstatus, {varPats, exnPats, env, exnTagDecls}) =>
                case idstatus of
                  I.IDSPECVAR ty =>
                  let
                    val varId = VarID.generate()
                    val idstatus = I.IDVAR varId
                    val pat = ({path=path@[name],id=varId},ty)
                  in
                    {varPats=pat::varPats,
                     exnPats=exnPats,
                     env=V.rebindId(env, name, idstatus),
                     exnTagDecls=exnTagDecls
                    }
                  end
                | I.IDSPECEXN ty => 
                  let
                    val varId = VarID.generate()
                    val idstatus = I.IDVAR varId
                    val varInfo = {path=path@[name],id=varId}
                    val pat = (varInfo, BV.exntagTy)
                    val exnId = ExnID.generate()
                    val exnInfo = {path=path, id=exnId, ty=ty}
                    val idstatus = I.IDEXN {id=exnId, ty=ty}
                    val exnTagDecl =
                        I.ICEXNTAGD ({exnInfo=exnInfo, varInfo=varInfo}, loc)
                  in
                    {varPats=varPats,
                     exnPats=pat::exnPats,
                     env=V.rebindId(env, name, idstatus),
                     exnTagDecls=exnTagDecl::exnTagDecls
                    }
                  end
                | I.IDSPECCON => {varPats=varPats, exnPats=exnPats, env=env, exnTagDecls=exnTagDecls}
                | idstatus => {varPats=varPats, exnPats=exnPats, 
                               env=V.rebindId(env, name, idstatus), exnTagDecls=exnTagDecls}
            )
            {varPats=nil, exnPats=nil, env=env, exnTagDecls=nil}
            varE
        fun genArgStrE path (V.STR envMap) returnEnv =
            SEnv.foldri
              (fn (name, {env=specEnv, strKind}, {varPats, exnPats, env, exnTagDecls}) =>
                  let
                    val {varPats=newPats, exnPats=newExnPats, strEntry=newStrEntry, exnTagDecls=newExnTagDecls} =
                        genArgStrEntry (path@[name]) specEnv
                  in
                    {varPats=newPats@varPats,
                     exnPats=newExnPats@exnPats,
                     env=V.rebindStr(env, name, newStrEntry),
                     exnTagDecls=newExnTagDecls @ exnTagDecls
                    }
                  end
              )
              {varPats=nil, exnPats=nil, env=returnEnv, exnTagDecls=nil}
              envMap
        (* the order must be the same as that of varsInEnv
           the order is foldr and str -> env
         *)
        and genArgStrEntry path (V.ENV {varE, tyE, strE, ...}) =
            let
              val {varPats=pats1, exnPats=exnPats, env=env, exnTagDecls=exnTagDecls1} =
                  genArgStrE path strE V.emptyEnv
              val {varPats=pats2, exnPats=exnPats2, env=env, exnTagDecls=exnTagDecls2} = 
                  genArgVarE path varE env
              val env = genArgTyE path tyE env
              val strKind = V.STRENV (StructureID.generate())
            in
              {varPats=pats1@pats2, 
               exnPats=exnPats@exnPats2, 
               strEntry={env=env, strKind=strKind},
               exnTagDecls=exnTagDecls1@exnTagDecls2}
            end

        val argSig = Sig.evalPlsig topEnv argSig
        val (_,argSpecEnv) = Sig.refreshSpecEnv argSig
        val specTfvs =
            TfvMap.listItemsi
              (TF.tfvsEnv TF.specKind nil (argSpecEnv, TfvMap.empty))
            handle exn => raise exn
        val extraTvarsMap =
            foldr
              (fn ((tfv as ref (tfunkind as I.TFV_SPEC {iseq, id, formals, ...}),
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
                       val tfun = I.TFUN_DEF {iseq=iseq, formals=nil, realizerTy= I.TYVAR tvar}
                     in
                       ( 
                        tfv := I.REALIZED{id= id, tfun=tfun};
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
(*
val _ = U.print "argSpecEnv before materializeEnv\n"
val _ = U.printEnv argSpecEnv
val _ = U.print "\n"
*)
        val tfvDecls = materializeEnv nil argSpecEnv
(*
val _ = U.print "argSpecEnv aftre materializeEnv\n"
val _ = U.printEnv argSpecEnv
val _ = U.print "\n"
*)
        fun materializeDtyTstr (path,tfv) =
            let
              val (name, path) = case List.rev path of
                                   h::tl => (h, List.rev tl)
                                 | _ => raise bug "nil path"
            in
              case !tfv of
                 I.TFV_SPEC _ => raise bug "non dty tfv (4)"
               | I.TFV_DTY {id, iseq, formals, conSpec, liftedTys} =>
                 let
                   val returnTy =
                       I.TYCONSTRUCT
                         {typ={path=path@[name],tfun=I.TFUN_VAR tfv},
(* FIXME
                          args= map (fn tv=>I.TYWILD) formals}
*)
                          args= map (fn tv=>I.TYVAR tv) formals}
                   val (varE, conbinds) =
                       SEnv.foldri
                         (fn (name, tyOpt, (varE, conbinds)) =>
                             let
                               val conId = ConID.generate()
                               val conInfo = {id=conId, path=path@[name]}
                               val conTy = 
                                   case tyOpt of
                                     NONE => returnTy
                                   | SOME ty => I.TYFUNM([ty], returnTy)
                               val conTy =
                                   case formals of
                                     nil => conTy
                                   | _ => 
                                     I.TYPOLY
                                       (
                                        map
                                          (fn tv =>(tv,I.UNIV))
                                          formals,
                                        conTy
                                       )
                               val idstatus = I.IDCON {id=conId,ty=conTy}
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
		   val runtimeTy = U.runtimeTyOfConspec conSpec
                   val envTfun =
                       I.TFUN_VAR
                         (ref
                            (I.TFUN_DTY{id=id,
                                        iseq=iseq,
                                        formals=formals,
					runtimeTy=runtimeTy,
                                        conSpec=conSpec,
                                        originalPath=path,
                                        liftedTys=liftedTys,
                                        dtyKind=I.DTY
				       }
                            )
                         )
                   val _ = tfv := I.FUN_DTY{tfun=envTfun,
                                            varE=varE,
                                            formals=formals,
                                            liftedTys=liftedTys,
                                            conSpec=conSpec
                                           }
                 in
                   ()
                 end
               | _ => raise bug "non tfv"
            end
        val _ = 
            map (fn pathTfvList =>
                    (map materializeDtyTstr pathTfvList))
                pathTfvListList
(*
val _ = U.print "argSpecEnv before evalEnv\n"
val _ = U.printEnv argSpecEnv
val _ = U.print "\n"
*)
        val {varPats, exnPats, strEntry=argStrEntry, exnTagDecls} = genArgStrEntry nil argSpecEnv 
(*
val _ = U.print "agrEnv after evalEnv\n"
val _ = U.printStrEntry argStrEntry
val _ = U.print "\n"
*)
        val dummyIdfunArgTy =
            case extraTvars of
              nil => NONE
            | _ => 
              SOME
                (
                 I.TYRECORD
                   (Utils.listToFields
                      (map (fn tvar => I.TYVAR tvar) extraTvars)
                   )
                )
        val dummyIdfunTy =
            case dummyIdfunArgTy of
              SOME ty => SOME (I.TYFUNM([ty],ty))
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
        argStrEntry=argStrEntry,
        extraTvars=extraTvars,
        polyArgPats=varPats@exnPats,
        exnTagDecls=exnTagDecls,
        dummyIdfunArgTy=dummyIdfunArgTy,
        firstArgPat=firstArgPat,
        tfvDecls = tfvDecls
       }
     end

  fun makeFunctorArgs loc pathList env =
      let
        fun genActualEnv path vars (V.ENV{varE, strE=V.STR envMap,...})
            : I.icexp list =
              let
                val vars = genActualVarE path vars varE
              in
                genActualStrE path vars envMap
              end
        and genActualVarE path vars varE : I.icexp list =
            SEnv.foldri
              (fn (name, I.IDVAR id, vars) => 
                  I.ICVAR({id=id, path=path@[name]}, loc) :: vars
                | (name, I.IDVAR_TYPED {id, ty}, vars) => 
                  I.ICVAR({id=id, path=path@[name]}, loc) :: vars
                | (name, I.IDEXVAR {path=exPath, ty, used, loc, version, internalId}, vars) =>
                  (* CHECKME:
                   Here we change the external name to the effective name.
                   *)
                  let
                    val exPath = case version of NONE => exPath | SOME i => path@[Int.toString i]
                  in
                    I.ICEXVAR ({path=exPath, ty=ty},loc) :: vars
                  end
                | (name, I.IDEXVAR_TOBETYPED _, vars) => raise bug "IDEXVAR_TOBETYPED"
                | (name, I.IDBUILTINVAR {primitive, ty}, vars) => 
                  (* bug 193_primitiveArg *)
                  I.ICBUILTINVAR {primitive=primitive, ty=ty, loc=loc}
                  ::
                  vars
                | (name, I.IDCON _, vars) => vars
                | (name, I.IDEXN {id, ty}, vars) => vars
                (*
                 if ExnID.Set.member(set, id) then vars
                 else
                   I.ICEXN_CONSTRUCTOR({id=id,ty=ty,path=path@[name]},loc)::vars
                 *)
                | (name, I.IDEXNREP {id, ty}, vars) => vars
                (*
                 if ExnID.Set.member(set, id) then vars
                 else
	           I.ICEXN_CONSTRUCTOR({id=id,ty=ty,path=path@[name]},loc) ::vars
                 *)
                | (name, I.IDEXEXN {path,ty, used, loc, version}, vars) => vars
                | (name, I.IDEXEXNREP {path,ty, used, loc, version}, vars) => vars
                | (name, I.IDOPRIM _, _) =>
                  (print name; print "\n"; raise bug "IDOPRIM genActualVarE")
                | (name, I.IDSPECVAR _, vars) => vars
                | (name, I.IDSPECEXN _, vars) => vars
                | (name, I.IDSPECCON, vars) => vars
              )
              vars
              varE
        and genActualStrE path vars envMap : I.icexp list =
            SEnv.foldri
              (fn (strName, {env, strKind}, vars) => genActualEnv (path@[strName]) vars env
              )
              vars
              envMap
        fun genActualTag (pathList, env) = 
            foldr
              (fn (path, exnCons) => 
                  case V.findId(env, path) of
                    SOME (I.IDEXN {id, ty}) => 
                    I.ICEXN_CONSTRUCTOR({id=id,ty=ty,path=path},loc)::exnCons
                  | SOME (I.IDEXNREP {id, ty}) => 
                    I.ICEXN_CONSTRUCTOR({id=id,ty=ty,path=path},loc) ::exnCons
                  | SOME (I.IDEXEXN {path, ty, used, loc, version}) => 
                    let
                      val path = case version of NONE => path | SOME i => path @ [Int.toString i]
                    in
                      I.ICEXEXN_CONSTRUCTOR({ty=ty,path=path},loc) ::exnCons
                    end
                  | SOME (I.IDEXEXNREP {path, ty, used, loc, version}) => 
                    let
                      val path = case version of NONE => path | SOME i => path @ [Int.toString i]
                    in
                      I.ICEXEXN_CONSTRUCTOR({ty=ty,path=path},loc) ::exnCons
                    end
                  | SOME idstatus => raise bug "non exn idstatus"
                  | NONE => raise bug "exn not found"
              )
              nil
              pathList
        val expList = genActualEnv nil nil env
        val exnCons = genActualTag (pathList, env) 
      in
        expList@exnCons
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
        (fn (name, I.IDVAR id, (vars, set)) => 
            ((path@[name],I.ICVAR({id=id, path=path@[name]}, loc))
             :: vars, set)
          | (name, I.IDVAR_TYPED {id, ty}, (vars, set)) => 
            ((path@[name],I.ICVAR({id=id, path=path@[name]}, loc))
             :: vars, set)
          | (name, I.IDEXVAR {path=exPath, ty, used, loc, version, internalId}, (vars, set)) =>
            (* CHECKME:
               Here we change the external name to the effective name.
             *)
            let
              val exPath = case version of NONE => exPath | SOME i => exPath @ [Int.toString i]
            in
              ((path@[name], I.ICEXVAR ({path=exPath, ty=ty},loc))
               :: vars, set)
            end
          | (name, I.IDEXVAR_TOBETYPED _, (vars, set)) => raise bug "IDEXVAR_TOBETYPED"
          | (name, I.IDCON _, (vars, set)) => (vars, set)
          | (name, I.IDEXN {id, ty}, (vars, set)) =>
            if ExnID.Set.member(set, id) then (vars, set)
            else
              ((path@[name],
               I.ICEXN_CONSTRUCTOR({id=id,ty=ty,path=path@[name]},loc))
              ::vars,
               ExnID.Set.add(set,id)
              )
          | (name, I.IDEXNREP {id, ty}, (vars, set)) =>
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
          | (name, I.IDEXEXN {path,ty, used, loc, version}, (vars, set)) => (vars,set)
          | (name, I.IDEXEXNREP {path,ty, used, loc, version}, (vars, set)) => (vars,set)
(*
            I.ICEXEXN({path=path, ty=ty}, loc) :: vars
*)
          | (name, I.IDOPRIM _, _) =>
            (print name; print "\n"; raise bug "IDOPRIM varsInVarE")
          | (name, I.IDBUILTINVAR _, (vars, set)) => (vars, set)
          | (name, I.IDSPECVAR _, (vars, set)) => (vars, set)
          | (name, I.IDSPECEXN _, (vars, set)) => (vars, set)
          | (name, I.IDSPECCON, (vars, set)) => (vars, set)
        )
        (vars, set)
        varE
  and varsInStrE set loc path vars envMap
      : ((string list * I.icexp) list * ExnID.Set.set) =
      SEnv.foldri
        (fn (strName, {env,strKind}, (vars, set)) =>
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
              SEnv.foldl (fn ({env, strKind},typidSet)  => typidSetEnv (env, typidSet)) typidSet envMap
            end
        and typidSetTyE (tyE,typidSet) =
            SEnv.foldl typidSetTstr typidSet tyE
        and typidSetTstr (tstr, typidSet) =
            case tstr of
              V.TSTR tfun => typidSetTfun (tfun, typidSet)
            | V.TSTR_DTY {tfun,...} => typidSetTfun (tfun, typidSet)
        and typidSetTfun (tfun, typidSet) =
            case I.derefTfun tfun of
              I.TFUN_VAR(ref (I.TFUN_DTY{id,...})) =>
              TypID.Set.add(typidSet, id)
            | _ => typidSet
        val typidSet = typidSetEnv (returnEnv, TypID.Set.empty)
        val (allVars,exnIdSet) = varsInEnv ExnID.Set.empty loc nil nil returnEnv
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

  fun visitTfun {specTfun=tfun1, implTfun=tfun2} =
      case (I.derefTfun tfun1, I.derefTfun tfun2) of
        (I.TFUN_VAR
           (tfv as (ref(I.TFV_DTY{id=id1,iseq,formals, conSpec, liftedTys}))),
         I.TFUN_VAR (ref((I.TFV_DTY{id=id2,...})))) =>
        tfv := I.TFV_DTY{id=id2,
                          iseq=iseq,
                          formals=formals,
                          conSpec=conSpec,
                          liftedTys=liftedTys}
      | (I.TFUN_VAR
           (tfv as (ref(I.TFV_SPEC{id=id1,iseq,formals}))),
         I.TFUN_VAR (ref((I.TFV_SPEC{id=id2,...})))) =>
        tfv := I.TFV_SPEC{id=id2,
                           iseq=iseq,
                           formals=formals}
      | (I.TFUN_VAR
           (tfv as (ref(I.TFUN_DTY{id=id1,
                                   iseq,
                                   formals,
				   runtimeTy,
                                   conSpec,
                                   originalPath,
                                   dtyKind,
                                   liftedTys}))),
         I.TFUN_VAR (ref((I.TFUN_DTY{id=id2,...})))) =>
        tfv := I.TFUN_DTY{id=id2,
                          iseq=iseq,
                          formals=formals,
			  runtimeTy=runtimeTy,
                          conSpec=conSpec,
                          originalPath=originalPath,
                          dtyKind=dtyKind,
                          liftedTys=liftedTys}
      | _ => ()

  fun visitTstr {specTstr=tstr1, implTstr=tstr2} =
      case (tstr1, tstr2) of
        (V.TSTR tfun1, V.TSTR tfun2) => visitTfun {specTfun=tfun1, implTfun=tfun2}
      | (V.TSTR_DTY {tfun=tfun1,...}, V.TSTR_DTY {tfun=tfun2,...}) => 
        visitTfun {specTfun=tfun1, implTfun=tfun2}
      | _ => ()

  fun visitEnv {specEnv=V.ENV {varE=varE1, tyE=tyE1, strE=V.STR envMap1},
                implEnv=V.ENV {varE=varE2, tyE=tyE2, strE=V.STR envMap2}}
      =
      (SEnv.appi
         (fn (name, tstr1) =>
             case SEnv.find(tyE2, name) of
               NONE => raise Fail
             | SOME tstr2 => visitTstr {specTstr=tstr1, implTstr=tstr2}
         )
         tyE1;
       SEnv.appi
         (fn (name, {env=env1, strKind}) =>
             case SEnv.find(envMap2, name) of
               NONE => raise Fail
             | SOME {env=env2, strKind} => visitEnv {specEnv=env1, implEnv=env2}
            )
         envMap1
      )
                        
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
                     if N.equalTy (N.emptyTypIdEquiv, eqEnv) (ty1,ty2) then ()
                     else raise Fail
                   | _ => raise Fail
                  )
            )
            conSpec2
        end 
      else raise Fail

  fun eqTfunkind {specTfunkind=tfunkind1, implTfunkind=tfunkind2} =
      case (tfunkind1, tfunkind2) of
        (I.TFUN_DTY {id=id1,
                      iseq=iseq1,
                      formals=formals1,
                      conSpec=conSpec1,...},
         I.TFUN_DTY {id=id2,
                      iseq=iseq2,
                      formals=formals2,
                      conSpec=conSpec2,...}
        ) => if TypID.eq(id1, id2) then () else raise Fail
(*
        if TypID.eq(id1, id2) andalso iseq1 = iseq2 then
          eqConSpec ((formals1,conSpec1),(formals2,conSpec2)) 
        else raise Fail
*)
      | (I.INSTANTIATED _, _) => raise bug "INSTANTIATED in spec"
      | (_, I.INSTANTIATED _) => raise bug "INSTANTIATED in spec"
      | (I.FUN_DTY _, _) => raise bug "FUN_DTY in spec"
      | (_, I.FUN_DTY _) => raise bug "FUN_DTY in spec"
      | (I.TFV_SPEC{id=id1, iseq=iseq1, formals=formals1},
         I.TFV_SPEC{id=id2, iseq=iseq2, formals=formals2})
        => if TypID.eq(id1, id2) then () else raise Fail
(*
        if TypID.eq(id1, id2) andalso
              iseq1 = iseq2 andalso
              length formals1 = length formals2
           then ()
           else raise Fail
*)
      | (I.TFV_DTY {id=id1,
                     iseq=iseq1,
                     formals=formals1,
                     conSpec=conSpec1,
                     liftedTys=liftedTys1},
         I.TFV_DTY {id=id2,
                     iseq=iseq2,
                     formals=formals2,
                     conSpec=conSpec2,
                     liftedTys=liftedTys2}
        ) => if TypID.eq(id1, id2) then () else raise Fail
(*
        if TypID.eq(id1, id2) andalso iseq1 = iseq2 then
          eqConSpec ((formals1,conSpec1),(formals2,conSpec2)) 
        else raise Fail
*)
      | _ => raise Fail
                   
  fun eqTfun {specTfun=tfun1, implTfun=tfun2} =
      case (I.derefTfun tfun1, I.derefTfun tfun2) of
      (I.TFUN_DEF {iseq=iseq1, formals=formals1, realizerTy=ty1},
       I.TFUN_DEF {iseq=iseq2, formals=formals2, realizerTy=ty2}) =>
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
        if N.equalTy (N.emptyTypIdEquiv, eqEnv) (ty1, ty2) then ()
        else raise Fail
      end
    (* 167_functor.sml: without the following check, ChackProvide may loop *)
    | (I.TFUN_VAR(tfv as ref(I.TFUN_DTY{id=id1,iseq=eq1,formals=formals1,runtimeTy=ty1,
                                          dtyKind=I.DTY_INTERFACE,...})),
       I.TFUN_VAR(ref(I.TFUN_DTY{id=id2,iseq=eq2,formals=formals2,runtimeTy=ty2,
                                 dtyKind=I.DTY_INTERFACE,...}))) =>
      if TypID.eq(id1,id2) then ()
      else 
        if BuiltinType.compatTy {absTy=ty1, implTy=ty2}
           andalso List.length formals1 = List.length formals2
           andalso (not eq1 orelse eq2)
        then tfv := I.REALIZED {id=id1, tfun=tfun2}
        else raise Fail
    | (I.TFUN_VAR(tfv as ref(I.TFUN_DTY{id,iseq,formals,runtimeTy,dtyKind=I.DTY_INTERFACE,...})),
       _) =>
      let
        val implRuntimeTy = case I.tfunRuntimeTy tfun2 of 
                              SOME ty => ty | NONE => raise Fail
        val implIseq = I.tfunIseq tfun2
        val _ = if BuiltinType.compatTy {absTy=runtimeTy, implTy=implRuntimeTy}
                   andalso List.length formals = I.tfunArity tfun2
                   andalso (not iseq orelse implIseq)
                then () 
                else raise Fail
      in
        tfv := I.REALIZED {id=id, tfun=tfun2}
      end
    | (I.TFUN_VAR(ref(tfunKind1)),I.TFUN_VAR(ref(tfunKind2))) => 
      eqTfunkind {specTfunkind=tfunKind1, implTfunkind=tfunKind2}
    | _ => raise Fail

  fun eqTstr {specTstr=tstr1, implTstr=tstr2} =
      case (tstr1, tstr2) of
        (V.TSTR tfun1, V.TSTR tfun2) => eqTfun {specTfun=tfun1, implTfun=tfun2}
      | (V.TSTR tfun1, V.TSTR_DTY {tfun=tfun2,...}) =>
        (eqTfun {specTfun=tfun1, implTfun=tfun2}
        handle exn =>
               (U.print "eqTfun failed\n";
                U.print "tfun1\n";
                U.printTfun tfun1;
                U.print "\ntfun2\n";
                U.printTfun tfun2;
                U.print "\n";
                raise exn
               )
        )
      | (V.TSTR_DTY {tfun=tfun1,...}, V.TSTR_DTY {tfun=tfun2,...}) =>
        (eqTfun {specTfun=tfun1, implTfun=tfun2}
         handle exn =>
               (U.print "eqTfun failed\n";
                U.print "tfun1\n";
                U.printTfun tfun1;
                U.print "\ntfun2\n";
                U.printTfun tfun2;
                U.print "\n";
                raise exn
               )
        )
      | _ => raise Fail

  fun eqTyE {specTyE=tyE1, implTyE=tyE2} =
      SEnv.appi
        (fn (name, tstr1) =>
            case SEnv.find(tyE2, name) of
              NONE => 
              (
               U.print "eqTyE fail missing name\n";
               U.print name;
               U.print "\n";
               raise Fail
              )
            | SOME tstr2 => 
              eqTstr {specTstr=tstr1, implTstr=tstr2}
              handle exn =>
                     (U.print "eqTstr failed\n";
                      U.print "tstr1\n";
                      U.printTstr tstr1;
                      U.print "\ntstr2\n";
                      U.printTstr tstr2;
                      U.print "\n";
                      raise exn
                     )
         )
         tyE1

  fun eqIdstatus (st1, st2) =
      case (st1, st2) of
      (I.IDSPECVAR ty1,I.IDSPECVAR ty2) =>
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raise Fail
    | (I.IDSPECEXN ty1, I.IDSPECEXN ty2) => 
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raise Fail
    | (I.IDSPECCON, I.IDSPECCON) => ()
    | (I.IDCON {ty=ty1,...}, I.IDCON {ty=ty2,...}) =>
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raise Fail
    | (I.IDEXN {ty=ty1,...}, I.IDEXN {ty=ty2,...}) =>
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raise Fail
    | (I.IDEXNREP {ty=ty1,...}, I.IDEXNREP {ty=ty2,...}) =>
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raise Fail
    | (I.IDEXEXN {ty=ty1,...}, I.IDEXN {ty=ty2,...}) =>
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raise Fail
    | (I.IDEXEXN {ty=ty1,...}, I.IDEXEXN {ty=ty2,...}) =>
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raise Fail
    | (I.IDEXEXNREP {ty=ty1,...}, I.IDEXEXNREP {ty=ty2,...}) =>
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raise Fail
    | (I.IDEXVAR _, I.IDVAR _) => ()
    | (I.IDEXVAR _, I.IDEXVAR _) => ()
    | (I.IDEXVAR _, I.IDVAR_TYPED _) => ()
    | (I.IDBUILTINVAR {primitive=prim1,ty=_}, I.IDBUILTINVAR {primitive=prim2,ty=_}) =>
      if prim1 = prim2 then () else raise Fail
    | _ => raise Fail

  fun eqVarE {specVarE=varE1, implVarE=varE2} =
      SEnv.appi
        (fn (name, st1) =>
            case SEnv.find(varE2, name) of
              NONE => raise Fail
            | SOME st2 => 
              eqIdstatus (st1, st2)
              handle exn =>
                     (U.print "eqVarE eqidstatus fail\n";
                      U.print name;
                      U.print "\n";
                      U.print "st1:\n";
                      U.printIdstatus st1;
                      U.print "\n";
                      U.print "st2:\n";
                      U.printIdstatus st2;
                      U.print "\n";
                      raise exn
                     )
        )
         varE1

  fun eqEnv {specEnv= env1, implEnv= env2}  =
      let
        fun eqEnv' {specEnv= env1 as V.ENV {varE=varE1, tyE=tyE1, strE=strE1},
                    implEnv= env2 as V.ENV {varE=varE2, tyE=tyE2, strE=strE2}}  =
            let
              val _ = eqTyE {specTyE=tyE1, implTyE=tyE2}
              val _ = eqVarE {specVarE=varE1, implVarE=varE2}
              val _ = eqStrE {specStrE=strE1, implStrE=strE2}
            in
              true
            end
        and eqStrE {specStrE=V.STR map1, implStrE=V.STR map2} =
            SEnv.appi
              (fn (name, {env=env1, strKind}) =>
                  case SEnv.find(map2, name) of
                    NONE => 
                    (
                    raise Fail
                    )
                  | SOME {env=env2, strKind} => if eqEnv' {specEnv=env1, implEnv=env2} then () else raise Fail
              )
              map1
        val _ = visitEnv {specEnv=env1, implEnv=env2}
        val _ = eqEnv' {specEnv=env1, implEnv=env2}
      in
        true
      end
      handle Fail => false

  fun eqSize (V.ENV {varE=varE1, tyE=tyE1, strE=V.STR strE1},
              V.ENV {varE=varE2, tyE=tyE2, strE=V.STR strE2})  =
      (SEnv.numItems varE1 = SEnv.numItems varE2
       andalso
       SEnv.numItems tyE1 = SEnv.numItems tyE2
       andalso
       SEnv.numItems strE1 = SEnv.numItems strE2
       andalso
       (SEnv.appi
          (fn (name, {env=env1, strKind}) =>
              case SEnv.find(strE2, name) of
                NONE => raise Fail
              | SOME {env=env2, strKind} => 
                if eqSize (env1, env2) then () else raise Fail)
        strE1;
        true
        )
      )
      handle Fail => false
end
end
