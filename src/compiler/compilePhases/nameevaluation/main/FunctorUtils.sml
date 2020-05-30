(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
(* the initial error code of this file : NEF-001 *)
structure FunctorUtils =
struct
local
  structure V = NameEvalEnv
  structure VP = NameEvalEnvPrims
  structure U = NameEvalUtils
  structure TF = TfunVars
  (* structure A = AbsynTy *)
  structure I = IDCalc
  structure L = SetLiftedTys
  structure N = NormalizeTy
  structure BT = BuiltinTypes
  structure Sig = EvalSig
  structure Ty = EvalTy
  (* structure P = PatternCalc *)
  (* structure EU = UserErrorUtils *)
  fun bug s = Bug.Bug ("NameEval (FunctorUtils): " ^ s)
  val DUMMYIDFUN = "id"
in
  fun evalFunArg (topEnv, argSig, loc) =
      let
        fun materializeTstr path (name:Symbol.symbol, tstr, icdecls) =
            (
            case tstr of
              V.TSTR tfun =>
              (case I.derefTfun tfun of
                 tfun as (I.TFUN_VAR (tfv as ref tfunkind)) =>
                 (case tfunkind of
                    I.TFV_SPEC {longsymbol, id, admitsEq, formals} =>
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
                        U.printLongsymbol longsymbol;
                        U.print "\n";
                       raise bug "spec tfv" 
                       )
                     | _ =>
                       let
                         val longsymbol = path@[name]
                         val funparamProp =
                             case I.propertyOfIty BT.boxedITy of
                               SOME (I.PROP p) => p
                             | _ => raise Bug.Bug "funparam prop"
                         (* 2012-8-6 ohori bug 062_functorPoly.sml; Bug : nil path
                            originalPath=path *)
                         val _ =
                             tfv :=
                             I.TFUN_DTY
                               {id=id,
                                admitsEq=admitsEq,
                                formals=formals,
                                conSpec=SymbolEnv.empty,
                                conIDSet = ConID.Set.empty,
                                longsymbol= longsymbol,
                                liftedTys=I.emptyLiftedTys,
                                dtyKind=I.FUNPARAM funparamProp
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

        fun materializeTyE (path:Symbol.longsymbol) (tyE:V.tyE) =
            SymbolEnv.foldri (materializeTstr path) nil tyE

        fun materializeStrE path (V.STR envMap) =
            SymbolEnv.foldri
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
                 I.TFUN_DEF _ => VP.reinsertTstr(env, name, tstr)
               | I.TFUN_VAR (ref tfunkind) =>
                 (case tfunkind of
                    I.TFV_SPEC _ => raise bug "unmaterialized (1)"
                  | I.TFV_DTY _ =>  raise bug "unmaterialized (2)"
                  | I.TFUN_DTY _ => VP.reinsertTstr(env, name, tstr)
                  | I.REALIZED _ => raise bug "REALIZED"
                  | I.INSTANTIATED {tfunkind, tfun} => raise bug "INSTANTIATED"
                  | I.FUN_DTY _ =>
                    VP.reinsertTstr(env, name, V.TSTR tfun)
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
                     U.printSymbol name;
                     U.print "\n";
                     U.printTstr tstr;
                     raise bug "unmaterialized (4)"
                    )
                  | I.TFUN_DTY _ => VP.reinsertTstr(env, name, tstr)
                  | I.REALIZED _ => raise bug "REALIZED"
                  | I.INSTANTIATED _ => raise bug "INSTANTIATED"
                  | I.FUN_DTY {longsymbol, tfun,varE,formals,liftedTys,conSpec} =>
                    let
                      val envTstr = V.TSTR_DTY {tfun=tfun,
                                                varE=varE,
                                                formals=formals,
                                                conSpec=conSpec}
                    in
                      VP.envWithVarE(VP.reinsertTstr(env, name, envTstr), varE)
                    end
                 )
              )

        fun genArgTyE path tyE env = SymbolEnv.foldri (genArgTstr path) env tyE

        fun genArgVarE path varE env =
            SymbolEnv.foldri
            (fn (name, idstatus, {varPats, exnPats, env, exnTagDecls}) =>
                case idstatus of
                  I.IDSPECVAR {ty, symbol} =>
                  let
                    val varId = VarID.generate()
                    val longsymbol = path@[name]
                    val idstatus = I.IDVAR {id=varId, longsymbol=longsymbol}
                    val pat = ({longsymbol=longsymbol,id=varId},ty)
                  in
                    {varPats=pat::varPats,
                     exnPats=exnPats,
                     env=VP.reinsertId(env, name, idstatus),
                     exnTagDecls=exnTagDecls
                    }
                  end
                | I.IDSPECEXN {ty, symbol} => 
                  let
                    val varId = VarID.generate()
                    val longsymbol = path@[name]
                    val idstatus = I.IDVAR {id=varId, longsymbol=longsymbol}
                    val varInfo = {longsymbol= longsymbol, id=varId}
                    val pat = (varInfo, BT.exntagITy)
                    val exnId = ExnID.generate()
                    val exnInfo = {longsymbol=longsymbol, id=exnId, ty=ty}
                    val idstatus = I.IDEXN {id=exnId, longsymbol=longsymbol, ty=ty}
                    val exnTagDecl =
                        I.ICEXNTAGD ({exnInfo=exnInfo, varInfo=varInfo}, loc)
                  in
                    {varPats=varPats,
                     exnPats=pat::exnPats,
                     env=VP.reinsertId(env, name, idstatus),
                     exnTagDecls=exnTagDecl::exnTagDecls
                    }
                  end
                | I.IDSPECCON {symbol} => 
                  {varPats=varPats, exnPats=exnPats, env=env, exnTagDecls=exnTagDecls}
                | idstatus => {varPats=varPats, exnPats=exnPats, 
                               env=VP.reinsertId(env, name, idstatus), exnTagDecls=exnTagDecls}
            )
            {varPats=nil, exnPats=nil, env=env, exnTagDecls=nil}
            varE
        fun genArgStrE path (V.STR envMap) returnEnv =
            SymbolEnv.foldri
              (fn (name, {env=specEnv, strKind}, {varPats, exnPats, env, exnTagDecls}) =>
                  let
                    val {varPats=newPats, exnPats=newExnPats, strEntry=newStrEntry, exnTagDecls=newExnTagDecls} =
                        genArgStrEntry (path@[name]) specEnv
                  in
                    {varPats=newPats@varPats,
                     exnPats=newExnPats@exnPats,
                     env=VP.reinsertStr(env, name, newStrEntry),
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
(* 2016-11-06 ohori: bug 331_functorSmi:
   Functor argumentを仮に実体化したstrkindは，FUNARGとする．
              val strKind = V.STRENV (StructureID.generate())
*)
              val strKind = V.FUNARG (StructureID.generate())
            in
              {varPats=pats1@pats2,
               exnPats=exnPats@exnPats2, 
               strEntry={env=env, strKind=strKind},
               exnTagDecls=exnTagDecls1@exnTagDecls2}
            end

        val argSigEnv = Sig.evalPlsig topEnv argSig
        val (_,argSpecEnv) = Sig.refreshSpecEnv argSigEnv
        val specTfvs =
            TfvMap.listItemsi
              (TF.tfvsEnv TF.specKind nil (argSpecEnv, TfvMap.empty))
            handle exn => raise exn
        val extraTvarsMap =
            foldr
              (fn ((tfv as ref (tfunkind as I.TFV_SPEC {admitsEq, id, formals, ...}),
                    path),
                   extraTvarsMap)
                  =>
                  (case formals of
                     nil =>
                     let
                       val tvarName = Symbol.coerceLongsymbolToSymbol path
                       val tvar = {symbol=tvarName,
                                   lifted=true,
                                   id = TvarID.generate(),
                                   isEq = admitsEq}
                       val tfun = I.TFUN_DEF {longsymbol=path,
                                              admitsEq=admitsEq,
                                              formals=nil, 
                                              realizerTy= I.TYVAR tvar}
                     in
                       ( 
                        tfv := I.REALIZED{id= id, tfun=tfun};
                        LongsymbolEnv.insert(extraTvarsMap, path, tvar))
                     end
                   | _ => extraTvarsMap
                  )
                | _ => raise bug "non spec tfv"
              )
              LongsymbolEnv.empty
              specTfvs
        val extraTvars = LongsymbolEnv.listItems extraTvarsMap
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
               | I.TFV_DTY {longsymbol, id, admitsEq, formals, conSpec, liftedTys} =>
                 let
                   val loc = Symbol.longsymbolToLoc longsymbol
                   val returnTy =
                       I.TYCONSTRUCT
                         {tfun=I.TFUN_VAR tfv,
(* FIXME
                          args= map (fn tv=>I.TYWILD) formals}
*)
                          args= map (fn tv=>I.TYVAR tv) formals}
                   val (varE, conbinds, conIDSet) =
                       SymbolEnv.foldri
                         (fn (name, tyOpt, (varE, conbinds, conIDSet)) =>
                             let
                               val conId = ConID.generate()
                               val conIDSet = ConID.Set.add (conIDSet, conId)
                               val longsymbol = path@[name]
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
                                          (fn tv =>(tv,I.UNIV I.emptyProperties))
                                          formals,
                                        conTy
                                       )
                               val conInfo = {id=conId, longsymbol=longsymbol, ty=conTy}
(*
                               val _ = V.conEnvAdd(conId, conInfo)
*)
                               val idstatus = I.IDCON conInfo
                             in
                               (SymbolEnv.insert(varE, name, idstatus),
                                {datacon={path=path@[name],id=conId},
                                 tyOpt=tyOpt} :: conbinds,
                                conIDSet
                               )
                             end
                         )
                         (SymbolEnv.empty, nil, ConID.Set.empty)
                         conSpec
                         (* is it safe to create a new var here? *)
		   val property = DatatypeLayout.datatypeLayout conSpec
                   val envTfun =
                       I.TFUN_VAR
                         (ref
                            (I.TFUN_DTY{id=id,
                                        admitsEq=admitsEq,
                                        formals=formals,
                                        conSpec=conSpec,
                                        conIDSet=conIDSet,
                                        longsymbol=longsymbol,
(*
                                        longsymbol=Symbol.mkLongsymbol (path@[name]) loc,
*)
                                        liftedTys=liftedTys,
                                        dtyKind=I.DTY property
				       }
                            )
                         )
                   val _ = tfv := I.FUN_DTY{tfun=envTfun,
                                            varE=varE,
                                            longsymbol= path@[name],
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
                   {ifFlex=false,
                    fields = 
                    RecordLabel.tupleMap
                      (map (fn tvar => I.TYVAR tvar) extraTvars)
                    }
                )
        val dummyIdfunTy =
            case dummyIdfunArgTy of
              SOME ty => SOME (I.TYFUNM([ty],ty))
            | NONE => NONE
        val firstArgPat =
            case dummyIdfunTy of
              SOME ty => 
              SOME ({longsymbol=Symbol.mkLongsymbol [DUMMYIDFUN] loc, id = VarID.generate()},
                    [ty])
            | NONE => NONE
(*
        val typedIdpat =
            I.ICPATTYPED
              (I.ICPATVAR_TRANS({path=[DUMMYIDFUN], id = VarID.generate()}, loc),
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
        argSigEnv=argSigEnv,
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
            SymbolEnv.foldri
              (fn (name, I.IDVAR {id, longsymbol}, vars) => 
                  I.ICVAR {id=id, longsymbol=path@[name]} :: vars
                | (name, I.IDVAR_TYPED {id, longsymbol, ty}, vars) => 
                  I.ICVAR {id=id, longsymbol= path@[name]} :: vars
                | (name, I.IDEXVAR {exInfo, internalId}, vars) =>
                  I.ICEXVAR {exInfo=exInfo, longsymbol=path@[name]} :: vars
(*
                | (name, I.IDEXVAR {longsymbol, ty, used, version, internalId}, vars) =>
                  (* CHECKME:
                   Here we change the external name to the effective name.
                   *)
                  let
                    val exLongsymbol = Symbol.setVersion (longsymbol, version)
(*
                    val exPath = case version of
                                   NONE => exPath
                                 | SOME i => 
                                   Symbol.mkLongsymbol
                                     (Symbol.longsymbolToLongid exPath @ [Int.toString i]) 
                                     origin
*)
(* 2012-9-21 ohori: bug 235_functor
                    val exPath = case version of NONE => exPath | SOME i => path@[Int.toString i]
*)
                  in
                    I.ICEXVAR ({longsymbol=longsymbol, ty=ty}, loc) :: vars
                  end
*)
                | (name, I.IDEXVAR_TOBETYPED _, vars) => raise bug "IDEXVAR_TOBETYPED"
                | (name, I.IDBUILTINVAR {primitive, ty}, vars) => 
                  (* bug 193_primitiveArg *)
                  I.ICBUILTINVAR {primitive=primitive, ty=ty, loc=loc}
                  ::
                  vars
                | (name, I.IDCON _, vars) => vars
                | (name, I.IDEXN _, vars) => vars
                (*
                 if ExnID.Set.member(set, id) then vars
                 else
                   I.ICEXN_CONSTRUCTOR({id=id,ty=ty,path=path@[name]},loc)::vars
                 *)
                | (name, I.IDEXNREP _, vars) => vars
                (*
                 if ExnID.Set.member(set, id) then vars
                 else
	           I.ICEXN_CONSTRUCTOR({id=id,ty=ty,path=path@[name]},loc) ::vars
                 *)
                | (name, I.IDEXEXN _, vars) => vars
                | (name, I.IDEXEXNREP _, vars) => vars
                | (name, I.IDOPRIM _, _) => raise bug "IDOPRIM genActualVarE"
                | (name, I.IDSPECVAR _, vars) => vars
                | (name, I.IDSPECEXN _, vars) => vars
                | (name, I.IDSPECCON _, vars) => vars
              )
              vars
              varE
        and genActualStrE path vars envMap : I.icexp list =
            SymbolEnv.foldri
              (fn (strName, {env, strKind}, vars) => genActualEnv (path@[strName]) vars env
              )
              vars
              envMap
        fun genActualTag (pathList, env) = 
            foldr
              (fn (path, exnCons) => 
(*
                  case V.checkId(env, path) of
*)
                  case VP.findId(env, path) of
                    SOME (I.IDEXN {id, longsymbol, ty}) => 
                    I.ICEXN_CONSTRUCTOR
                      {id=id, ty=ty, longsymbol = path}
                    ::exnCons
                  | SOME (I.IDEXNREP {id, longsymbol, ty}) =>
                    I.ICEXN_CONSTRUCTOR({id=id,ty=ty,
                                         longsymbol = path}) 
                    ::exnCons
                  | SOME (I.IDEXEXN exExnInfo) =>
                    I.ICEXEXN_CONSTRUCTOR {longsymbol=path, exInfo=exExnInfo} ::exnCons
(*
                  | SOME (I.IDEXEXN {exExnInfo, used}) => 
                    let
                      val longsymbol = Symbol.setVersion (longsymbol, version)
                    in
                      I.ICEXEXN_CONSTRUCTOR({ty=ty,longsymbol=longsymbol},loc) ::exnCons
                    end
*)
(*
                  | SOME (I.IDEXEXN {longsymbol, ty, used, version}) => 
                    let
                      val longsymbol = Symbol.setVersion (longsymbol, version)
                    in
                      I.ICEXEXN_CONSTRUCTOR({ty=ty,longsymbol=longsymbol},loc) ::exnCons
                    end
*)
                  | SOME (I.IDEXEXNREP exExnInfo) => 
                    I.ICEXEXN_CONSTRUCTOR 
                      {exInfo=exExnInfo, longsymbol=path}
                    :: exnCons
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

  local 
    fun varsInEnv set loc path vars (V.ENV{varE, strE=V.STR envMap,...})
        : ((Symbol.longsymbol * I.icexp) list * ExnID.Set.set) =
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
        : ((Symbol.longsymbol * I.icexp) list * ExnID.Set.set) =
        SymbolEnv.foldri
          (fn (name, I.IDVAR {id, longsymbol}, (vars, set)) =>
              ((path@[name], I.ICVAR {id=id, longsymbol=longsymbol}) :: vars, 
               set)
            | (name, I.IDVAR_TYPED {id, longsymbol, ty}, (vars, set)) => 
              ((path@[name], I.ICVAR {id=id, longsymbol=longsymbol}) :: vars, 
               set)
            | (name, I.IDEXVAR {exInfo, internalId},  (vars, set)) =>
              (* 2013-7-26 ohori. 061_functor but *)
              (#used exInfo := true;
               ((path@[name], I.ICEXVAR {longsymbol=path@[name], exInfo=exInfo}) :: vars, set)
              )
(*
            | (name, I.IDEXVAR {longsymbol, ty, used, version, internalId}, 
               (vars, set)) =>
              (* CHECKME:
                 Here we change the external name to the effective name.
               *)
              let
                val exLongsymbol = Symbol.setVersion (longsymbol, version)
              in
                ((longsymbol, I.ICEXVAR ({longsymbol=longsymbol, ty=ty}, loc))
                 :: vars, set)
              end
*)
            | (name, I.IDEXVAR_TOBETYPED _, (vars, set)) => raise bug "IDEXVAR_TOBETYPED"
            | (name, I.IDCON _, (vars, set)) => (vars, set)
            | (name, I.IDEXN (exnInfo as {id,...}), (vars, set)) =>
              if ExnID.Set.member(set, id) then (vars, set)
              else
                ((path@[name], I.ICEXN_CONSTRUCTOR exnInfo) ::vars,
                 ExnID.Set.add(set,id)
                )
            | (name, I.IDEXNREP (exnInfo as {id, ...}), (vars, set)) =>
              if ExnID.Set.member(set, id) then (vars, set)
              else
                ((path@[name], I.ICEXN_CONSTRUCTOR exnInfo) ::vars,
                 ExnID.Set.add(set,id)
                )
(*
            I.ICEXN ({id=id, ty=ty, path=path@[name]}, loc) :: vars
*)
            | (name, I.IDEXEXN exExnInfo, (vars, set)) => (vars,set)
            | (name, I.IDEXEXNREP exExnInfo, (vars, set)) => (vars,set)
(*
            I.ICEXEXN({path=path, ty=ty}, loc) :: vars
*)
            | (name, I.IDOPRIM _, _) =>
              raise bug "IDOPRIM varsInVarE"
            | (name, I.IDBUILTINVAR _, (vars, set)) => (vars, set)
            | (name, I.IDSPECVAR _, (vars, set)) => (vars, set)
            | (name, I.IDSPECEXN _, (vars, set)) => (vars, set)
            | (name, I.IDSPECCON _, (vars, set)) => (vars, set)
          )
          (vars, set)
          varE
    and varsInStrE set loc path vars envMap
        : ((Symbol.longsymbol * I.icexp) list * ExnID.Set.set) =
        SymbolEnv.foldri
          (fn (strName, {env,strKind}, (vars, set)) =>
              varsInEnv set loc (path@[strName]) vars env
          )
          (vars, set)
          envMap
  in
    val varsInEnv = fn (env, loc) => varsInEnv ExnID.Set.empty loc nil nil env
  end

  fun typidSet env =
      let
        fun typidSetEnv (V.ENV {tyE,strE=V.STR envMap,...},typidSet) =
            let
              val typidSet = typidSetTyE (tyE,typidSet)
            in
              SymbolEnv.foldl (fn ({env, strKind},typidSet)  => typidSetEnv (env, typidSet)) typidSet envMap
            end
        and typidSetTyE (tyE,typidSet) =
            SymbolEnv.foldl typidSetTstr typidSet tyE
        and typidSetTstr (tstr, typidSet) =
            case tstr of
              V.TSTR tfun => typidSetTfun (tfun, typidSet)
            | V.TSTR_DTY {tfun,...} => typidSetTfun (tfun, typidSet)
        and typidSetTfun (tfun, typidSet) =
            case I.derefTfun tfun of
                (* 2012-7-31 ohori: bug 228_abstypeInFunctor.sml; dtyKind must be processed  *)
                I.TFUN_VAR(ref (I.TFUN_DTY{id, dtyKind = I.OPAQUE{tfun, ...},...})) =>
                TypID.Set.add(typidSetTfun (tfun,typidSet), id)
              | I.TFUN_VAR(ref (I.TFUN_DTY{id, dtyKind = I.INTERFACE tfun,...})) =>
                TypID.Set.add(typidSetTfun (tfun,typidSet), id)
              | I.TFUN_VAR(ref (I.TFUN_DTY{id,...})) =>
                TypID.Set.add(typidSet, id)
              | _ => typidSet
      in
        typidSetEnv (env, TypID.Set.empty)
      end

  exception Fail
  fun raiseFail i = (U.print ( "FuntorUtils Fait exception at " ^ (Int.toString i) ^ "\n"); raise Fail)
  fun makeEqEnv (formals1, formals2) =
      let
        val _ = if length formals1 = length formals2 then ()
                else raiseFail 1
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
           (tfv as (ref(I.TFV_DTY{id=id1,admitsEq,formals, conSpec, liftedTys,...}))),
         I.TFUN_VAR (ref((I.TFV_DTY{longsymbol,id=id2,...})))) =>
        tfv := I.TFV_DTY{id=id2,
                         admitsEq=admitsEq,
                         longsymbol=longsymbol,
                         formals=formals,
                         conSpec=conSpec,
                         liftedTys=liftedTys}
      | (I.TFUN_VAR
           (tfv as (ref(I.TFV_SPEC{id=id1,admitsEq,formals,...}))),
         I.TFUN_VAR (ref((I.TFV_SPEC{longsymbol, id=id2,...})))) =>
        tfv := I.TFV_SPEC{id=id2,
                          longsymbol=longsymbol,
                          admitsEq=admitsEq,
                          formals=formals}
      | (I.TFUN_VAR
           (tfv as (ref(I.TFUN_DTY{id=id1,
                                   admitsEq,
                                   formals,
                                   conSpec,
                                   conIDSet=conIDSet1,
                                   longsymbol,
                                   dtyKind,
                                   liftedTys}))),
         I.TFUN_VAR (ref((I.TFUN_DTY{id=id2,conIDSet=conIDSet2,...})))) =>
        tfv := I.TFUN_DTY{id=id2,
                          admitsEq=admitsEq,
                          formals=formals,
                          conSpec=conSpec,
                          conIDSet=conIDSet2,
                          longsymbol=longsymbol,
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
      (SymbolEnv.appi
         (fn (name, tstr1) =>
             case SymbolEnv.find(tyE2, name) of
               NONE => raiseFail 2
             | SOME tstr2 => visitTstr {specTstr=tstr1, implTstr=tstr2}
         )
         tyE1;
       SymbolEnv.appi
         (fn (name, {env=env1, strKind}) =>
             case SymbolEnv.find(envMap2, name) of
               NONE => raiseFail 3
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
          val _ = if length (SymbolEnv.listItems conSpec1) = 
                     length (SymbolEnv.listItems conSpec2)
                  then ()
                  else raiseFail 4
        in
          SymbolEnv.appi
            (fn (name, tyOpt1) =>
                case SymbolEnv.find(conSpec2, name) of
                  NONE => raiseFail 5
                | SOME tyOpt2 => 
                  (case (tyOpt1, tyOpt2) of
                     (NONE, NONE) => ()
                   | (SOME ty1, SOME ty2) =>
                     if N.equalTy (N.emptyTypIdEquiv, eqEnv) (ty1,ty2) then ()
                     else raiseFail 6
                   | _ => raiseFail 7
                  )
            )
            conSpec2
        end 
      else raiseFail 8

  fun eqTfunkind {specTfunkind=tfunkind1, implTfunkind=tfunkind2} =
      case (tfunkind1, tfunkind2) of
        (I.TFUN_DTY {id=id1,...}, I.TFUN_DTY {id=id2,...}) 
        => if TypID.eq(id1, id2) then () else raiseFail 9
(*
        if TypID.eq(id1, id2) andalso iseq1 = iseq2 then
          eqConSpec ((formals1,conSpec1),(formals2,conSpec2)) 
        else raise Fail
*)
      | (I.INSTANTIATED _, _) => raise bug "INSTANTIATED in spec"
      | (_, I.INSTANTIATED _) => raise bug "INSTANTIATED in spec"
      | (I.FUN_DTY _, _) => raise bug "FUN_DTY in spec"
      | (_, I.FUN_DTY _) => raise bug "FUN_DTY in spec"
      | (I.TFV_SPEC{id=id1,...}, I.TFV_SPEC{id=id2,...})
        => if TypID.eq(id1, id2) then () else raiseFail 10
(*
        if TypID.eq(id1, id2) andalso
              iseq1 = iseq2 andalso
              length formals1 = length formals2
           then ()
           else raise Fail
*)
      | (I.TFV_DTY {id=id1,...}, I.TFV_DTY {id=id2,...}
        ) => if TypID.eq(id1, id2) then () else raiseFail 11
(*
        if TypID.eq(id1, id2) andalso iseq1 = iseq2 then
          eqConSpec ((formals1,conSpec1),(formals2,conSpec2)) 
        else raise Fail
*)
      | _ => 
        (
         U.print "** eqTfunkind 12\n";
         U.print "tfunkind1\n";
         U.printTfunkind tfunkind1;
         U.print "\ntfunkind2\n";
         U.printTfunkind tfunkind2;
         U.print "\n";
         raiseFail 12
        )
                   
  and eqTfun {specTfun=tfun1, implTfun=tfun2} =
      case (I.derefTfun tfun1, I.derefTfun tfun2) of
      (I.TFUN_DEF {admitsEq=admitsEq1, formals=formals1, realizerTy=ty1,...},
       I.TFUN_DEF {admitsEq=admitsEq2, formals=formals2, realizerTy=ty2,...}) =>
      let
        val _ = if admitsEq1 = admitsEq2 then () else raiseFail 13
        val tvarPairs = if length formals1 = length formals2 then 
                          ListPair.zip (formals1, formals2)
                        else raiseFail 14
        val eqEnv = foldl
                      (fn (({id=tv1,symbol=_,isEq=_,lifted=_},
                            {id=tv2,symbol=_,isEq=_,lifted=_}),
                           eqEnv) =>
                          TvarID.Map.insert(eqEnv, tv1, tv2)
                      )
                      TvarID.Map.empty
                      tvarPairs
      in
        if N.equalTy (N.emptyTypIdEquiv, eqEnv) (ty1, ty2) then ()
        else raiseFail 15
      end
    (* 167_functor.sml: without the following check, ChackProvide may loop *)
    | (I.TFUN_VAR(tfv as ref(I.TFUN_DTY{id=id1,admitsEq=eq1,formals=formals1,
                                          dtyKind=I.DTY_INTERFACE ty1,...})),
       I.TFUN_VAR(ref(I.TFUN_DTY{id=id2,admitsEq=eq2,formals=formals2,
                                 dtyKind=I.DTY_INTERFACE ty2,...}))) =>
      if TypID.eq(id1,id2) then ()
      else
        if Ty.compatProperty {abs=I.PROP ty1, impl=I.PROP ty2}
           andalso List.length formals1 = List.length formals2
           andalso (not eq1 orelse eq2)
        then tfv := I.REALIZED {id=id1, tfun=tfun2}
        else raiseFail 16
    | (I.TFUN_VAR(tfv as ref(I.TFUN_DTY{id,admitsEq,formals,dtyKind=I.DTY_INTERFACE property,...})),
       _) =>
      let
        val implProperty = case I.tfunProperty tfun2 of 
                             SOME ty => ty | NONE => raiseFail 17
        val implAdmitsEq = I.tfunAdmitsEq tfun2
        val _ = if Ty.compatProperty {abs=I.PROP property, impl=implProperty}
                   andalso List.length formals = I.tfunArity tfun2
                   andalso (not admitsEq orelse implAdmitsEq)
                then () 
                else raiseFail 18
      in
        tfv := I.REALIZED {id=id, tfun=tfun2}
      end
    | (I.TFUN_VAR (ref (I.FUN_DTY {tfun=specTfun,...})),
       implTfun) => 
      eqTfun {specTfun=specTfun, implTfun=implTfun}
    | (specTfun,
       I.TFUN_VAR (ref (I.FUN_DTY {tfun=implTfun,...}))) =>
      eqTfun {specTfun=specTfun, implTfun=implTfun}
    | (I.TFUN_VAR(ref(tfunKind1)),I.TFUN_VAR(ref(tfunKind2))) => 
      eqTfunkind {specTfunkind=tfunKind1, implTfunkind=tfunKind2}
    | _ => 
      (U.print "** eqTfun **\n";
       U.print "specTfun\n";
       U.printTfun tfun1;
       U.print "\n";
       U.print "inplTfun\n";
       U.printTfun tfun2;
       U.print "\n";
       raiseFail 19)

  fun eqTstr {specTstr=tstr1, implTstr=tstr2} =
      case (tstr1, tstr2) of
        (V.TSTR tfun1, V.TSTR tfun2) => eqTfun {specTfun=tfun1, implTfun=tfun2}
      | (V.TSTR tfun1, V.TSTR_DTY {tfun=tfun2,...}) =>
        (eqTfun {specTfun=tfun1, implTfun=tfun2}
        handle exn =>
               (U.print "eqTfun failed 1 \n";
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
               (U.print "eqTfun failed 2\n";
                U.print "tfun1\n";
                U.printTfun tfun1;
                U.print "\ntfun2\n";
                U.printTfun tfun2;
                U.print "\n";
                raise exn
               )
        )
      | _ => 
        (U.print "eqTstr Fail in other cases\n";
         raiseFail 20)

  fun eqTyE {specTyE=tyE1, implTyE=tyE2} =
      SymbolEnv.appi
        (fn (name, tstr1) =>
            case SymbolEnv.find(tyE2, name) of
              NONE => 
              (
               U.print "eqTyE fail missing name\n";
               U.printSymbol name;
               U.print "\n";
               raiseFail 21
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
      (I.IDSPECVAR {ty=ty1,...},I.IDSPECVAR {ty=ty2,...}) =>
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raiseFail 22
    | (I.IDSPECEXN {ty=ty1, ...}, I.IDSPECEXN {ty=ty2, ...}) => 
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raiseFail 23
    | (I.IDSPECCON _, I.IDSPECCON _) => ()
    | (I.IDCON {ty=ty1,...}, I.IDCON {ty=ty2,...}) =>
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raiseFail 24
    | (I.IDEXN {ty=ty1,...}, I.IDEXN {ty=ty2,...}) =>
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raiseFail 25
    | (I.IDEXNREP {ty=ty1,...}, I.IDEXNREP {ty=ty2,...}) =>
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raiseFail 26
    | (I.IDEXEXN {ty=ty1,...}, I.IDEXN {ty=ty2,...}) =>
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raiseFail 27
    | (I.IDEXEXN {ty=ty1,...}, I.IDEXEXN {ty=ty2,...}) =>
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raiseFail 28
    | (I.IDEXEXNREP {ty=ty1,...}, I.IDEXEXNREP {ty=ty2,...}) =>
      if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1,ty2) then () 
      else raiseFail 29
    | (I.IDEXVAR _, I.IDVAR _) => ()
    | (I.IDEXVAR _, I.IDEXVAR _) => ()
    | (I.IDEXVAR _, I.IDVAR_TYPED _) => ()
    | (I.IDBUILTINVAR {primitive=prim1,...}, I.IDBUILTINVAR {primitive=prim2,...}) =>
      if prim1 = prim2 then () else raiseFail 30
    | _ => raiseFail 31

  fun eqVarE {specVarE=varE1, implVarE=varE2} =
      SymbolEnv.appi
        (fn (name, st1) =>
            case SymbolEnv.find(varE2, name) of
              NONE => 
              (U.print "name not found in varE2\n";
               U.printSymbol name;
               U.print "\n";
               raiseFail 32)
            | SOME st2 => 
              eqIdstatus (st1, st2)
              handle exn =>
                     (U.print "eqVarE eqidstatus fail\n";
                      U.printSymbol name;
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
                      handle Fail => 
                             (U.print "eqEnv; eqTyE; \n";
                              raiseFail 33)
              val _ = eqVarE {specVarE=varE1, implVarE=varE2}
                      handle Fail => 
                             (U.print "eqEnv; eqVarE; \n";
                              raiseFail 34)
              val _ = eqStrE {specStrE=strE1, implStrE=strE2}
                      handle Fail => 
                             (U.print "eqEnv; eqStrE; \n";
                              raiseFail 35)
            in
              true
            end
        and eqStrE {specStrE=V.STR map1, implStrE=V.STR map2} =
            SymbolEnv.appi
              (fn (name, {env=env1, strKind}) =>
                  case SymbolEnv.find(map2, name) of
                    NONE => 
                    (
                    raiseFail 36
                    )
                  | SOME {env=env2, strKind} => if eqEnv' {specEnv=env1, implEnv=env2} then () else raiseFail 37
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
      (SymbolEnv.numItems varE1 = SymbolEnv.numItems varE2
       andalso
       SymbolEnv.numItems tyE1 = SymbolEnv.numItems tyE2
       andalso
       SymbolEnv.numItems strE1 = SymbolEnv.numItems strE2
       andalso
       (SymbolEnv.appi
          (fn (name, {env=env1, strKind}) =>
              case SymbolEnv.find(strE2, name) of
                NONE => raiseFail 38
              | SOME {env=env2, strKind} => 
                if eqSize (env1, env2) then () else raiseFail 39)
        strE1;
        true
        )
      )
      handle Fail => false

  fun setEquiv ((typIdMap1,typIdMap2),id1,id2) = 
      let
        val typIdMap1 = 
            case TypID.Map.find(typIdMap1,id1) of
              SOME id3 => if TypID.eq(id2,id3) then typIdMap1
                          else raiseFail 40
            | NONE => TypID.Map.insert(typIdMap1, id1, id2)
        val typIdMap2 = 
            case TypID.Map.find(typIdMap2,id2) of
              SOME id3 => if TypID.eq(id1,id3) then typIdMap2
                          else raiseFail 41
            | NONE => TypID.Map.insert(typIdMap2, id2, id1)
      in
        (typIdMap1, typIdMap2)
      end

  fun eqShapeTfunkind (tfunkind1, tfunkind2) typEquiv =
      case (tfunkind1, tfunkind2) of
      (I.TFUN_DTY {id=id1,...}, I.TFUN_DTY {id=id2,...}) => setEquiv(typEquiv, id1,id2)
    | (I.TFV_SPEC {id=id1,...}, I.TFV_SPEC {id=id2,...}) =>setEquiv(typEquiv, id1,id2)
    | (I.TFV_DTY {id=id1,...}, I.TFV_DTY {id=id2,...})=> setEquiv(typEquiv, id1,id2)
    | (I.FUN_DTY {tfun=tfun1, ...}, I.FUN_DTY{tfun=tfun2,...}) => eqShapeTfun (tfun2, tfun2) typEquiv
    | _ => raiseFail 42

  and eqShapeTfun (tfun1, tfun2) typEquiv =
      case (I.derefTfun tfun1, I.derefTfun tfun2) of
        (I.TFUN_DEF _,I.TFUN_DEF _) => typEquiv
      | (I.TFUN_VAR (ref tfunkind1), I.TFUN_VAR (ref tfunkind2)) =>
        eqShapeTfunkind (tfunkind1, tfunkind2) typEquiv
      | _ => raiseFail 43

  fun eqShapeTstr (tstr1, tstr2) typEquiv =
      case (tstr1, tstr2) of
        (V.TSTR tfun1, V.TSTR tfun2) => 
        eqShapeTfun (tfun1, tfun2) typEquiv
      | (V.TSTR_DTY {tfun=tfun1,...}, 
         V.TSTR_DTY {tfun=tfun2,...}) => 
        eqShapeTfun (tfun1, tfun2) typEquiv
      | _ => raiseFail 44

  fun eqShapeTyE (tyE1, tyE2) typEquiv = 
      SymbolEnv.foldli
      (fn (name, tstr1, typEquiv) =>
          case SymbolEnv.find(tyE2, name) of
            NONE => raiseFail 45
          | SOME tstr2 => eqShapeTstr (tstr1,tstr2) typEquiv
      )
      typEquiv
      tyE1

  fun eqShapeIdstatus (idstatus1, idstatus2) =
      case (idstatus1, idstatus2) of
      (I.IDSPECVAR _, I.IDSPECVAR _) => ()
    | (I.IDSPECEXN _, I.IDSPECEXN _) => ()
    | (I.IDSPECCON _, I.IDSPECCON _) => ()
    | (I.IDVAR _,I.IDVAR _) => ()
    | (I.IDVAR_TYPED _,I.IDVAR_TYPED _) => ()
    | (I.IDEXVAR _,I.IDEXVAR _) => ()
    | (I.IDEXVAR_TOBETYPED _,I.IDEXVAR_TOBETYPED _) => ()
    | (I.IDBUILTINVAR _,I.IDBUILTINVAR _) => ()
    | (I.IDCON _,I.IDCON _) => ()
    | (I.IDEXN _,I.IDEXN _) => ()
    | (I.IDEXNREP _,I.IDEXNREP _) => ()
    | (I.IDEXEXN _,I.IDEXEXN _) => ()
    | (I.IDEXEXNREP _,I.IDEXEXNREP _) => ()
    | (I.IDOPRIM _,I.IDOPRIM _) => ()
    | _ => raiseFail 46
        
  fun eqShapeVarE (varE1, varE2) =
      SymbolEnv.appi
      (fn (name, idstatus1) =>
          case SymbolEnv.find(varE2, name) of
            SOME idstatus2 => eqShapeIdstatus (idstatus1, idstatus2) 
          | NONE => raiseFail 47
      )
      varE1

  fun eqShapeEnv (V.ENV {varE=varE1, tyE=tyE1, strE=V.STR strE1},
                  V.ENV {varE=varE2, tyE=tyE2, strE=V.STR strE2}) typEquiv =
      let
        val _ = eqShapeVarE (varE1, varE2)
        val typEquiv = eqShapeTyE (tyE1,tyE2) typEquiv
        val typEquiv = eqShapeStrE (strE1,strE2) typEquiv
      in
        typEquiv
      end
  and eqShapeStrE (strE1, strE2) typEquiv =
      SymbolEnv.foldli
      (fn (name, {env=env1, strKind}, typEquiv) =>
          case SymbolEnv.find(strE2, name) of
            SOME {env=env2, strKind=_} => eqShapeEnv(env1,env2) typEquiv
          | NONE => raiseFail 48
      )
      typEquiv
      strE1
  fun eqShape (env1,env2) =
      let
        val typEquiv = (TypID.Map.empty, TypID.Map.empty)
      in
        (eqShapeEnv (env1, env2) typEquiv; true)
      end
      handle Fail => false
end
end
