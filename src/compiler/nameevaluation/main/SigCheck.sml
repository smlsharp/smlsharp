(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure SigCheck =
struct
local
  structure I = IDCalc
  structure Ty = EvalTy
  structure ITy = EvalIty
  structure V = NameEvalEnv
  structure L = SetLiftedTys
  structure S = Subst
  structure TF = TfunVars
  structure P = PatternCalc
  structure PI = PatternCalcInterface
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure A = Absyn
  structure N = NormalizeTy
  structure Sig = EvalSig
  structure FU = FunctorUtils
  fun bug s = Bug.Bug ("SigCheck: " ^ s)
in
  exception SIGCHECK
  datatype mode = Opaque | Trans
  type sigCheckParam =
       {mode:mode,loc:Loc.loc,strPath:Symbol.longsymbol,strEnv:V.env,specEnv:V.env}
  type sigCheckResult = V.env * I.icdecl list 

   fun removeVarE (srcVarE, targetVarE) =
       SymbolEnv.foldli
       (fn (name, _, targetVarE) =>
           let
             val (targetVarE, _) = SymbolEnv.remove(targetVarE, name)
           in
             targetVarE
           end
           handle LibBase.NotFound => targetVarE
       )
       targetVarE
       srcVarE
   and removeTyE (srcTyE, targetTyE) =
       SymbolEnv.foldli
       (fn (name, _, targetTyE) =>
           let
             val (targetTyE, _) = SymbolEnv.remove(targetTyE, name)
           in
             targetTyE
           end
           handle LibBase.NotFound => targetTyE
       )
       targetTyE
       srcTyE
   and removeStrE (V.STR srcStrE, V.STR targetStrE) =
       let
         val targetStrE =
         SymbolEnv.foldli
           (fn (name, _, targetStrE) =>
               let
                 val (targetStrE, _) = SymbolEnv.remove(targetStrE, name)
               in
                 targetStrE
               end
               handle LibBase.NotFound => targetStrE
           )
           targetStrE
           srcStrE
       in
         V.STR targetStrE
       end
   and removeEnv (V.ENV{varE=srcVarE,tyE=srcTyE, strE=srcStrE}, 
                      V.ENV{varE=targetVarE,tyE=targetTyE, strE=targetStrE}) =
      let
        val varE = removeVarE (srcVarE, targetVarE)
        val tyE = removeTyE (srcTyE, targetTyE)
        val strE = removeStrE(srcStrE, targetStrE)
      in
        V.ENV{varE=varE, tyE=tyE, strE=strE}
      end
      
  fun sigCheck (param as {mode, loc, ...} : sigCheckParam) : sigCheckResult =
    let
      val revealKey = RevealID.generate() (* for each sigCheck instance *)
      fun instantiateEnv path (specEnv, strEnv) =
        let
          fun instantiateTstr name (specTstr, strTstr) =
              let
                val tfun = case specTstr of
                             V.TSTR tfun => tfun
                           | V.TSTR_DTY {tfun, ...} => tfun
              in
                case I.derefTfun tfun of
                  I.TFUN_DEF _ => ()
                | I.TFUN_VAR (tfv as (ref (I.REALIZED _))) => 
                  raise bug "REALIZED"
                | I.TFUN_VAR (tfv as (ref (I.INSTANTIATED _))) => ()
                | I.TFUN_VAR (tfv as (ref (I.FUN_DTY _))) => ()
                | I.TFUN_VAR (tfv as (ref (I.TFUN_DTY _))) => ()
                | I.TFUN_VAR (tfv as (ref (tfunkind as I.TFV_SPEC _))) =>
                  (* 2012-7-14 ohori: bug 206_eqtype.sml eq check is added.
                     2012-7-19 ohori: bug 214_typeSpecMaching.sml arity check is added
                   *)
                  let
                    val tstrTfun =  case strTstr of
                                      V.TSTR tfun => tfun
                                    | V.TSTR_DTY {tfun, ...} => tfun
                    val _ = if I.tfunIseq tfun andalso not (I.tfunIseq tstrTfun) then
                              EU.enqueueError
                                (Symbol.symbolToLoc name,
                                 E.SIGEqtype("200",{longsymbol=path@[name]}))
                            else ()
                    val _ = if I.tfunArity tfun <> I.tfunArity tstrTfun then
                              EU.enqueueError
                                (Symbol.symbolToLoc name,
                                 E.SIGArity("200",{longsymbol=path@[name]}))
                            else ()
                  in
                    tfv := I.INSTANTIATED {tfunkind=tfunkind, tfun=tstrTfun}
                  end
                | I.TFUN_VAR (tfv as (ref (tfunkind as I.TFV_DTY _))) =>
                  let
                    val tstrTfun = 
                        case strTstr of
                          V.TSTR tfun => tfun
                        | V.TSTR_DTY {tfun, ...} => tfun
                    val _ = if I.tfunIseq tfun andalso not (I.tfunIseq tstrTfun) then
                              EU.enqueueError
                                (Symbol.symbolToLoc name,
                                 E.SIGEqtype("200",{longsymbol=path@[name]}))
                            else ()
                    val _ = if I.tfunArity tfun <> I.tfunArity tstrTfun then
                              EU.enqueueError
                                (Symbol.symbolToLoc name,
                                 E.SIGArity("200",{longsymbol=path@[name]}))
                            else ()
                  in
                    tfv := I.INSTANTIATED {tfunkind=tfunkind, tfun=tstrTfun}
                  end
              end
          fun instantiateTyE (specTyE, strTyE) =
              SymbolEnv.appi
                (fn (symbol, specTstr) =>
                    case SymbolEnv.findi (strTyE, symbol) of
                      NONE => ()
                    | SOME (strEnvSymbol, strTstr) =>  
                      instantiateTstr strEnvSymbol (specTstr, strTstr)
                )
                specTyE
          fun instantiateStrE (V.STR specEnvMap, V.STR strEnvMap) =
              SymbolEnv.appi
              (fn (specSymbol, {env=specEnv, strKind=_}) =>
                  case SymbolEnv.find(strEnvMap, specSymbol) of
                    NONE => () (* error will be checked in checkStrE *)
                  | SOME {env=strEnv, strKind=_} =>
                    instantiateEnv (path@[specSymbol]) (specEnv, strEnv)
              )
              specEnvMap
          val V.ENV{tyE=specTyE, strE=specStrE, ...} = specEnv
          val V.ENV{tyE=strTyE, strE=strStrE, ...} = strEnv
        in
          instantiateTyE (specTyE, strTyE);
          instantiateStrE (specStrE, strStrE)
        end

      fun checkEnv path (specEnv, strEnv) : sigCheckResult =
        let
          val V.ENV{varE=specVarE,tyE=specTyE, strE=specStrE} = specEnv
          val V.ENV{varE=strVarE,tyE=strTyE, strE=strStrE} = strEnv
          fun checkTfun (specSymbol, strSymbol) (specTfun, strTfun) =
              let
                val specTfun = I.pruneTfun (N.reduceTfun(I.pruneTfun specTfun))
                val strTfun = I.derefTfun (N.reduceTfun (I.pruneTfun strTfun))
              in
                case (specTfun, strTfun) of
                  (I.TFUN_DEF {formals=specFormals, realizerTy=specTy,...},
                   I.TFUN_DEF {formals=strFormals, realizerTy=strTy,...}) =>
                  if List.length specFormals <> List.length strFormals then
                     EU.enqueueError 
                       (Symbol.symbolToLoc strSymbol,
                        E.SIGArity("205",{longsymbol=path@[strSymbol]}))
                  else if N.eqTydef N.emptyTypIdEquiv ((specFormals,specTy),(strFormals,strTy))
                  then ()
                  else (EU.enqueueError 
                          (Symbol.symbolToLoc strSymbol,
                           E.SIGDtyMismatch ("210",{longsymbol=path@[specSymbol]})))
                | (I.TFUN_VAR (ref (I.TFUN_DTY {id=id1,...})), I.TFUN_VAR (ref (I.TFUN_DTY {id=id2,...}))) =>
                  if TypID.eq(id1,id2) then ()
                  else 
                    (EU.enqueueError 
                       (Symbol.symbolToLoc strSymbol,
                        E.SIGDtyMismatch("220",{longsymbol=path@[specSymbol]})))
                | (I.TFUN_VAR (ref (I.FUN_DTY {tfun=specTfun,...})), strTfun) =>
                  checkTfun (specSymbol, strSymbol) (specTfun, strTfun)
                | (specTfun, I.TFUN_VAR (ref (I.FUN_DTY {tfun=strTfun,...}))) =>
                  checkTfun (specSymbol, strSymbol) (specTfun, strTfun)
                | _ =>(EU.enqueueError
                         (Symbol.symbolToLoc strSymbol,
                          E.SIGDtyMismatch("230",{longsymbol=path@[strSymbol]})))
              end

          fun checkConSpec typIdEquiv ((formals1, conSpec1), (formals2, conSpec2)) =
              (* this assumes that |formals1| = |formals2|. *)
              let
                val tvarIdEquiv =
                    foldl
                    (fn (({id=id1,...}:I.tvar,{id=id2,...}:I.tvar), equiv) =>
                        TvarID.Map.insert(equiv, id1, id2))
                    TvarID.Map.empty
                    (ListPair.zip (formals1,formals2))
                val conSpec2 =
                    SymbolEnv.foldli
                    (fn (specSymbol, tyopt1, conSpec2) =>
                        let
                          val (strSymbol, conSpec2, tyopt2) = SymbolEnv.removei(conSpec2, specSymbol)
                        in
                          case (tyopt1,tyopt2) of
                            (NONE, NONE) => conSpec2
                          | (SOME _, NONE) => 
                            (EU.enqueueError 
                               (Symbol.symbolToLoc strSymbol,
                                E.SIGConType ("275",{longsymbol=path@[strSymbol]}));
                             conSpec2)
                          | (NONE, SOME _) =>
                            (EU.enqueueError 
                               (Symbol.symbolToLoc strSymbol,
                                E.SIGConType ("275",{longsymbol=path@[strSymbol]}));
                             conSpec2)
                          | (SOME ty1, SOME ty2) => 
                            if N.equalTy (typIdEquiv, tvarIdEquiv) (ty1, ty2) then 
                              conSpec2
                            else 
                              (EU.enqueueError 
                                 (Symbol.symbolToLoc strSymbol,
                                  E.SIGConType ("275",{longsymbol=path@[strSymbol]}));
                               conSpec2)
                        end
                        handle LibBase.NotFound => 
                            (EU.enqueueError 
                               (Symbol.symbolToLoc specSymbol,
                                E.SIGConNotFoundInDty ("275",{longsymbol=path@[specSymbol]}));
                             conSpec2)
                    )
                    conSpec2
                    conSpec1
                val _ = 
                    SymbolEnv.appi
                      (fn (strSymbol,_) =>
                          EU.enqueueError 
                            (Symbol.symbolToLoc strSymbol,
                             E.SIGConNotInSig ("275",{longsymbol=path@[strSymbol]})
                            )
                      )
                      conSpec2
              in
                ()
              end

          fun checkTstr (specSymbol, strSymbol) (specTstr, strTstr) =
            let
              (* 2013-07-02 check that DTY varE is exported. 
                 I am not sure this is necessary, since we check varE separately
               *)
              fun checkVarE varE =
                  SymbolEnv.appi
                    (fn (conSymbol, idstatus) => 
                        case SymbolEnv.find(strVarE, conSymbol) of
                          NONE => 
                          EU.enqueueError 
                            (Symbol.symbolToLoc conSymbol, 
                             E.SIGConNotFound ("240",{longsymbol=path@[conSymbol]}))
                        | SOME strIdstatus =>
                          (case (idstatus, strIdstatus) of
                             (I.IDCON {id=conid1, ty=ty1,...}, I.IDCON {id=conid2, ty=ty2,...}) =>
                             if ConID.eq(conid1, conid2) then ()
                             else
                               (EU.enqueueError 
                                  (Symbol.symbolToLoc conSymbol,
                                   E.SIGConNotFound ("250",{longsymbol=path@[conSymbol]})))
                           | (I.IDCON _, _) => 
                             EU.enqueueError 
                               (Symbol.symbolToLoc conSymbol,
                                E.SIGConNotFound("260",{longsymbol=path@[conSymbol]}))
                           | (I.IDSPECCON _, I.IDCON _) => ()
                           | _ => raise bug "non conid"
                          )
                    )
                    varE
            in
              case specTstr of
                V.TSTR specTfun =>
                (case strTstr of
                   V.TSTR strTfun => (checkTfun (specSymbol, strSymbol) (specTfun, strTfun) ; specTstr)
                 | V.TSTR_DTY {tfun=strTfun, ...} =>
                   (checkTfun (specSymbol, strSymbol) (specTfun, strTfun); specTstr)
                )
              | V.TSTR_DTY {tfun=specTfun,formals, conSpec,...} =>
                (case strTstr of
                   V.TSTR strTfun =>
                   (EU.enqueueError 
                      (Symbol.symbolToLoc strSymbol,
                       E.SIGDtyRequired("270",{longsymbol=path@[strSymbol]}));
                    specTstr)
                 | V.TSTR_DTY {tfun=strTfun, varE=strVarE, formals=strFormals, conSpec=strConSpec,...} =>
                   (checkTfun (specSymbol, strSymbol) (specTfun, strTfun);
                    if List.length formals <> List.length strFormals then
                      EU.enqueueError 
                        (Symbol.symbolToLoc strSymbol,
                         E.SIGArity ("275",{longsymbol=path@[specSymbol]}))
                    else ();
                    checkConSpec 
                      N.emptyTypIdEquiv
                      ((formals, conSpec), (strFormals, strConSpec));
                    checkVarE strVarE;
                    V.TSTR_DTY{tfun=specTfun, formals=formals, conSpec=conSpec, varE=strVarE}
                   )
                )
            end
                
          fun checkTyE (specTyE, strTyE) =
              SymbolEnv.foldri
                (fn (specSymbol, specTstr, tyE) =>
                    case SymbolEnv.findi (strTyE, specSymbol) of
                      NONE => 
                      (EU.enqueueError 
                         (Symbol.symbolToLoc specSymbol,
                          E.SIGTypUndefined("290",{longsymbol=path@[specSymbol]}));
                       tyE)
                    | SOME (strSymbol, strTstr) => 
                      let
                        val str = checkTstr (specSymbol, strSymbol) (specTstr, strTstr)
                      in
                        SymbolEnv.insert(tyE, strSymbol, str)
                      end
                )
                SymbolEnv.empty
                specTyE

          fun isTrans ty = 
            let
              exception OPAQUE 
              fun trace ty =
                  case ty of
                    I.TYWILD => ()
                  | I.TYERROR => ()
                  | I.TYVAR _  => ()
                  | I.TYRECORD tyLabelenvMap =>
                    LabelEnv.app trace tyLabelenvMap
                  | I.TYCONSTRUCT {tfun, args} =>
                    (traceTfun tfun; List.app trace args)
                  | I.TYFUNM (tyList, ty) =>
                    (List.app trace tyList; trace ty)
                  | I.TYPOLY (kindedTvarList, ty) => trace ty
                  | I.INFERREDTY ty => ()
              and traceTfun tfun = 
                  case tfun of
                    I.TFUN_DEF {realizerTy,...} => trace realizerTy
                  | I.TFUN_VAR (ref tfunkind) => traceTfunkind tfunkind
              and traceTfunkind tfunkind =
                  case tfunkind of
                    I.TFUN_DTY _ => ()
                  | I.TFV_SPEC _ => ()
                  | I.TFV_DTY _ => ()
                  | I.REALIZED {id, tfun} => traceTfun tfun
                  | I.INSTANTIATED _ => raise OPAQUE
                  | I.FUN_DTY _ => ()
            in
              case mode of 
                Trans => true
              | Opaque => ((trace ty; true) handle OPAQUE => false)
            end
                
          fun checkVarE (specVarE, strVarE) =
              SymbolEnv.foldri
                (fn (name, specIdStatus, (varE, icdeclList)) =>
                    case specIdStatus of
                      I.IDSPECVAR {ty=specTy, symbol} =>
                      let
                        fun makeDecl icexp =
                            let
                              val revealKey = 
                                  case mode of Trans => NONE | Opaque => SOME revealKey
                              val icexp = 
                                  I.ICSIGTYPED {icexp=icexp, revealKey=revealKey,
                                                ty=specTy, loc=loc}
                              val newId = VarID.generate()
                              val longsymbol = path@[name]
                              val icpat = 
                                  case mode of
                                    Trans => I.ICPATVAR_TRANS {longsymbol=longsymbol,id=newId}
                                  | Opaue => I.ICPATVAR_OPAQUE {longsymbol=longsymbol,id=newId}
                            in
                              (SymbolEnv.insert(varE, name, I.IDVAR_TYPED {id=newId, ty=specTy, longsymbol=longsymbol}),
                               I.ICVAL(Ty.emptyScopedTvars,[(icpat,icexp)],loc)
                               :: icdeclList)
                            end
                        fun makeTypdecl (icexp, idstatusActualTyOpt) =
                            case idstatusActualTyOpt of
                              SOME (actualTy, idstatus) =>
                              if isTrans specTy andalso
                                 N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (specTy, actualTy) 
                              then (SymbolEnv.insert(varE, name, idstatus), icdeclList)
                              else makeDecl icexp
                            | NONE => makeDecl icexp
                      in
                        case SymbolEnv.find(strVarE, name) of
                          NONE =>
                          (EU.enqueueError
                             (Symbol.symbolToLoc name, 
                              E.SIGVarUndefined ("300",{longsymbol = path@[name]}));
                           (varE, icdeclList)
                          )
                        | SOME (I.IDVAR {id,longsymbol}) => 
                          let
                            val longsymbol = path@[name]
                          in
                            makeTypdecl (I.ICVAR {longsymbol=longsymbol,id=id}, NONE)
                          end
                        | SOME (idstatus as I.IDVAR_TYPED {id, ty, longsymbol}) => 
                          let
                            val longsymbol = path@[name]
                          in
                            makeTypdecl (I.ICVAR {longsymbol=longsymbol,id=id}, 
                                         SOME (ty, idstatus))
                          end
                        | SOME (idstatus as I.IDEXVAR {exInfo, used, internalId}) => 
                          (used := true;
                           makeTypdecl (I.ICEXVAR {longsymbol=path@[name],exInfo=exInfo}, SOME (#ty exInfo, idstatus))
                          )
                        | SOME (I.IDEXVAR_TOBETYPED _) =>  raise bug "IDEXVAR_TOBETYPED"
                        | SOME (idstatus as I.IDBUILTINVAR {primitive, ty}) => 
                          makeTypdecl
                            (I.ICBUILTINVAR {primitive=primitive,ty=ty,loc=loc}, 
                             SOME (ty, idstatus))
                        | SOME (I.IDCON {id, longsymbol, ty}) =>
                          let
                            val longsymbol = path@[name]
                          in
                            makeTypdecl
                              (I.ICCON {longsymbol=longsymbol,ty=ty, id=id}, NONE)
                          end
                        | SOME (I.IDEXN {id, longsymbol, ty}) => 
                          let
                            val longsymbol = path@[name]
                          in
                            makeTypdecl
                              (I.ICEXN {longsymbol=longsymbol,ty=ty, id=id}, NONE)
                          end
                        | SOME (I.IDEXNREP {id, longsymbol, ty}) => 
                          let
                            val longsymbol = path@[name]
                          in
                            makeTypdecl
                              (I.ICEXN {longsymbol=longsymbol,ty=ty, id=id}, NONE)
                          end
                        | SOME (I.IDEXEXN (exExnInfo, used)) => 
                          (used := true;
                           makeTypdecl (I.ICEXEXN {exInfo=exExnInfo,
                                                   longsymbol=path@[name]},
                                                   NONE)
                          )
                        | SOME (I.IDEXEXNREP (exExnInfo, used)) => 
                          (used := true;
                           makeTypdecl (I.ICEXEXN {longsymbol=path@[name],exInfo=exExnInfo}, NONE)
                          )
                        | SOME (I.IDOPRIM {id, overloadDef, used, longsymbol}) => 
                          let
                            val longsymbol = path@[name]
                          in
                            (used := true;
                             makeTypdecl (I.ICOPRIM {longsymbol=longsymbol,id=id}, NONE)
                            )
                          end
                        | SOME (I.IDSPECVAR _) => raise bug "IDSPECVAR"
                        | SOME (I.IDSPECEXN _) => raise bug "IDSPECEXN"
                        | SOME (I.IDSPECCON _) => raise bug "IDSPECCON"
                      end
                    | I.IDSPECEXN {ty=ty1, symbol} => 
                      (case SymbolEnv.find(strVarE, name) of
                         NONE =>
                         (EU.enqueueError
                            (Symbol.symbolToLoc name,
                             E.SIGVarUndefined("310",{longsymbol = path@[name]}));
                          (varE, icdeclList)
                         )
                       | SOME (idstatus as I.IDEXN {id, ty=ty2, longsymbol}) =>
                         let
                           val ty1 = N.reduceTy TvarMap.empty ty1
                           val ty2 = N.reduceTy TvarMap.empty ty2
                         in
                           (* we must return ty1 instead of ty2 here,
                              since ty1 may be abstracted *)
                           if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1, ty2) then
                             (SymbolEnv.insert(varE,
                                          name,
                                          I.IDEXN {id=id, longsymbol=longsymbol, ty=ty1}),
                              icdeclList)
                           else 
                             (EU.enqueueError 
                                (Symbol.symbolToLoc name, 
                                 E.SIGExnType("320",{longsymbol = path@[name]}));
                              (varE, icdeclList)
                             )
                         end
                       | SOME (idstatus as I.IDEXNREP {id, longsymbol, ty=ty2}) =>
                         let
                           val ty1 = N.reduceTy TvarMap.empty ty1
                           val ty2 = N.reduceTy TvarMap.empty ty2
                         in
                           if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1, ty2) then
                             (SymbolEnv.insert(varE, name, idstatus), icdeclList)
                           else 
                             (EU.enqueueError
                                (Symbol.symbolToLoc name,
                                 E.SIGExnType("330",{longsymbol = path@[name]}));
                              (varE, icdeclList)
                             )
                         end
                       | SOME (idstatus as I.IDEXEXN ({longsymbol, ty=ty2, version}, used)) => 
                         let
                           val _ = used := true
                           val ty1 = N.reduceTy TvarMap.empty ty1
                           val ty2 = N.reduceTy TvarMap.empty ty2
                         in
                           if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1, ty2) then
                             (SymbolEnv.insert(varE, name, idstatus), icdeclList)
                           else 
                             (EU.enqueueError
                                (Symbol.symbolToLoc name,
                                 E.SIGExnType ("340",{longsymbol = path@[name]}));
                              (varE, icdeclList)
                             )
                         end
                       | SOME (idstatus as I.IDEXEXNREP ({ty=ty2,...}, used)) => 
                         let
                           val _ = used := true
                           val ty1 = N.reduceTy TvarMap.empty ty1
                           val ty2 = N.reduceTy TvarMap.empty ty2
                         in
                           if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1, ty2) then
                             (SymbolEnv.insert(varE, name, idstatus), icdeclList)
                           else 
                             (EU.enqueueError 
                                (Symbol.symbolToLoc name, 
                                 E.SIGExnType ("340",{longsymbol = path@[name]}));
                              (varE, icdeclList)
                             )
                         end
                       | _ =>
                         (EU.enqueueError
                            (Symbol.symbolToLoc name, 
                             E.SIGExnExpected ("350",{longsymbol = path@[name]}));
                          (varE, icdeclList)
                         )
                      )
                    | I.IDSPECCON {symbol} =>
                      (case SymbolEnv.find(strVarE, name) of
                         NONE =>
                         (EU.enqueueError
                            (Symbol.symbolToLoc name, 
                             E.SIGVarUndefined("360",{longsymbol = path@[name]}));
                          (varE, icdeclList)
                         )
                       | SOME (idstatus as I.IDCON {id,ty,...}) => 
                         (SymbolEnv.insert(varE, name, idstatus), icdeclList)
                       | SOME _ => 
                         (EU.enqueueError
                            (Symbol.symbolToLoc name,
                             E.SIGConNotFound ("370",{longsymbol = path@[name]}));
                          (varE, icdeclList)
                         )
                      )
                    | I.IDCON {id, longsymbol, ty} =>
                      (case SymbolEnv.find(strVarE, name) of
                         NONE =>
                         (EU.enqueueError
                            (Symbol.symbolToLoc name, 
                             E.SIGVarUndefined ("380",{longsymbol = path@[name]}));
                          (varE, icdeclList)
                         )
                       | SOME (idstatus as I.IDCON {id=id2, ty=ty2,...}) => 
                         if ConID.eq(id, id2) then 
                           (SymbolEnv.insert(varE, name, idstatus), icdeclList)
                         else 
                           (EU.enqueueError
                              (Symbol.symbolToLoc name, 
                               E.SIGConNotFound ("390",{longsymbol = path@[name]}));
                            (varE, icdeclList)
                           )
                       | SOME _ => 
                         (EU.enqueueError
                            (Symbol.symbolToLoc name, 
                             E.SIGConNotFound ("400",{longsymbol = path@[name]}));
                          (varE, icdeclList)
                         )
                      )
                    | _ =>
                      (U.print "\ncheckVarE\n";
                       U.printIdstatus specIdStatus;
                       U.print "\n";
                       raise bug "illeagal idstatus"
                      )
                )
                (SymbolEnv.empty, nil)
                specVarE

          fun checkStrE (V.STR specEnvMap, V.STR strEnvMap) =
              SymbolEnv.foldri
                (fn (name, {env=specEnv, strKind=specStrKind}, (strE, icdeclList)) =>
                    case SymbolEnv.find(strEnvMap, name) of
                      NONE => 
                      (EU.enqueueError
                         (Symbol.symbolToLoc name,
                          E.SIGStrUndefined("410",{longsymbol=path@[name]}));
                       (strE, icdeclList))
                    | SOME {env=strEnv, strKind=strStrKind} =>
                      let
                        val (env, icdeclList1) = checkEnv (path@[name]) (specEnv, strEnv)
                      in
                        (SymbolEnv.insert(strE, name, {env=env, strKind=strStrKind}), icdeclList@icdeclList1)
                      end
                )
                (SymbolEnv.empty, nil)
                specEnvMap
          (* checkEnv body *)
          val tyE = checkTyE (specTyE, strTyE)
          val (varE, icdeclList1) = checkVarE(specVarE, strVarE)
          val (strE, icdeclList2) = checkStrE (specStrE, strStrE)
          val env = V.ENV{varE=varE, tyE=tyE, strE=V.STR strE}
        in
          if EU.isAnyError () then raise SIGCHECK
          else (env, icdeclList1@icdeclList2)
        end

      fun makeOpaqueInstanceEnv path env =
        let
          fun makeOpaqueInstanceTstr name (tstr, env) =
              case tstr of 
                V.TSTR tfun =>
                (case I.derefTfun tfun of
                   I.TFUN_VAR(tfv as ref (I.INSTANTIATED {tfunkind,tfun})) =>
                   (case tfunkind of (* creating a return env *)
                      I.TFV_SPEC {id, iseq, ...} => 
                      let
                        val formals = I.tfunFormals tfun
                        val liftedTys = I.tfunLiftedTys tfun
                        val runtimeTy = 
                            case I.tfunRuntimeTy tfun of
                              SOME ty => ty
                            | NONE => raise bug "runtimeTy"
                        (* 2012-7-14: ohori [name] is added. *)
                        val longsymbol = path@[name]
                        val newTfunkind =
                            I.TFUN_DTY {id=id,
                                        iseq=iseq,
                                        formals=formals,
                                        runtimeTy=runtimeTy,
                                        conSpec=SymbolEnv.empty,
                                        conIDSet = ConID.Set.empty,
                                        longsymbol=longsymbol,
                                        liftedTys=liftedTys,
                                        dtyKind=I.OPAQUE
                                                  {tfun=tfun,
                                                   revealKey=revealKey}
                                       }
                        val _ = tfv := newTfunkind
                        val env = V.reinsertTstr(env,name,V.TSTR (I.TFUN_VAR tfv))
                      in
                        env
                      end
                    | I.TFV_DTY {id, iseq, ...} => 
                      let
                        val formals = I.tfunFormals tfun
                        val liftedTys = I.tfunLiftedTys tfun
                        val runtimeTy = 
                            case I.tfunRuntimeTy tfun of
                              SOME ty => ty
                            | NONE => raise bug "runtimeTy"
                        val newTfunkind =
                            I.TFUN_DTY {id=id,
                                        iseq=iseq,
                                        formals=formals,
                                        runtimeTy=runtimeTy,
                                        conSpec=SymbolEnv.empty,
                                        conIDSet=ConID.Set.empty,
                                        (* 2012-7-14: ohori [name] is added. *)
                                        longsymbol= path @ [name], 
                                        liftedTys=liftedTys,
                                        dtyKind=
                                        I.OPAQUE
                                          {tfun=tfun, revealKey=revealKey}
                                       }
                        val _ = tfv := newTfunkind
                        val newTfun = I.TFUN_VAR tfv
                        val env = V.reinsertTstr(env, name,V.TSTR newTfun)
                      in
                        env
                      end
                    | _ => raise bug "non tfv (5)"
                   )
                 | I.TFUN_VAR _ => V.reinsertTstr(env, name, tstr)
                 | I.TFUN_DEF _ => V.reinsertTstr(env, name, tstr)
                )
              | V.TSTR_DTY {tfun, varE, ...} =>
                (case I.derefTfun tfun of
                   I.TFUN_VAR
                     (tfv as ref (I.INSTANTIATED{tfunkind,tfun=strTfun})) =>
                      (case tfunkind of
                         I.TFV_DTY {longsymbol=_, id, iseq, formals, conSpec, liftedTys} =>
                         let
                           val runtimeTy = 
                               case I.tfunRuntimeTy strTfun of
                                 SOME ty => ty
                               | NONE => raise bug "runtimeTy"
                           val (conspecConId, conIDSet) =
                               SymbolEnv.foldri
                              (fn (name, tyOpt, (conspecConId, conIDSet)) =>
                                  let
                                    val conId = ConID.generate()
                                  in
                                    (SymbolEnv.insert(conspecConId, name, (tyOpt, conId)),
                                     ConID.Set.add(conIDSet, conId))
                                  end
                              )
                               (SymbolEnv.empty, ConID.Set.empty)
                               conSpec
                           val newTfunkind =
                               I.TFUN_DTY {id=id,
                                           iseq=iseq,
                                           formals=formals,
                                           runtimeTy=runtimeTy,
                                           conSpec=conSpec,
                                           conIDSet=conIDSet,
                                           (* 2012-7-14: ohori [name] is added. *)
                                           longsymbol= path @ [name],
                                           liftedTys=liftedTys,
                                           dtyKind=
                                           I.OPAQUE
                                             {tfun=strTfun,revealKey=revealKey}
                                          }
                           val _ = tfv := newTfunkind
                           val returnTy =
                               I.TYCONSTRUCT
                                 {tfun=tfun,
                                  args= map (fn tv=>I.TYVAR tv) formals}
                           val varE =
                               SymbolEnv.foldri
                                 (fn (name, (tyOpt, conId), varE) =>
                                     let
                                       val conTy =
                                           case tyOpt of
                                             NONE => 
                                             (case formals of 
                                                nil => returnTy
                                              | _ => 
                                                I.TYPOLY
                                                  (
                                                   map 
                                                     (fn tv=>(tv,I.UNIV))
                                                     formals,
                                                   returnTy
                                                  )
                                             )
                                           | SOME ty => 
                                             case formals of 
                                               nil =>
                                               I.TYFUNM([ty], returnTy)
                                             | _ => 
                                               I.TYPOLY
                                                 (
                                                  map
                                                    (fn tv =>(tv,I.UNIV))
                                                    formals,
                                                  I.TYFUNM([ty], returnTy)
                                                 )
                                       val longsymbol = path@[name]
                                       val conInfo =
                                           {longsymbol=longsymbol, ty=conTy, id=conId}
                                       val _ = V.conEnvAdd(conId, conInfo)
                                       val idstatus = I.IDCON conInfo
                                     in
                                       SymbolEnv.insert(varE, name, idstatus)
                                     end
                                 )
                                 SymbolEnv.empty
                                 conspecConId
                           val newTstr = V.TSTR_DTY
                                           {tfun=I.TFUN_VAR tfv,
                                            varE=varE,
                                            formals=formals,
                                            conSpec=conSpec}
                           val env = V.reinsertTstr(env, name, newTstr)
                           val env = V.envWithVarE(env, varE)
                         in
                           env
                         end
                       | _ => raise bug "non dty tfv (1)"
                      )
                 | _ => V.reinsertTstr(env, name, tstr)
                )

          fun makeOpaqueInstanceTyE tyE env =
              SymbolEnv.foldri
                (fn (name, tstr, env) => makeOpaqueInstanceTstr name (tstr, env)
                )
                env
                tyE
          fun makeOpaqueInstanceStrE (V.STR strEnvMap) env =
              let
                val env =
                    SymbolEnv.foldri
                      (fn (name, {env=strEnv, strKind}, env) =>
                          let
                            val strEnv = makeOpaqueInstanceEnv (path@[name]) strEnv
                            val strKind = V.STRENV (StructureID.generate())
                          in
                            V.reinsertStr(env, name, {env=strEnv, strKind=strKind}) 
                          end
                      )
                      env
                      strEnvMap
              in
                env
              end

          val V.ENV {varE, tyE, strE} = env
          val env = makeOpaqueInstanceTyE tyE env
          val env = makeOpaqueInstanceStrE strE env
        in
          env
        end

      fun makeTransInstanceEnv path env =
        let
          val V.ENV {varE, tyE, strE} = env
          fun makeTransInstanceTstr name (tstr, tyE) =
              case tstr of 
                V.TSTR tfun =>
                (case I.derefTfun tfun of
                   I.TFUN_VAR (tfv as ref tfunkind) =>
                   (case tfunkind of
                      I.INSTANTIATED {tfunkind, tfun} =>
                      (tfv := I.REALIZED{tfun=tfun,id=I.tfunkindId tfunkind};
                       SymbolEnv.insert(tyE, name, V.TSTR tfun)
                      )
                    | I.TFV_SPEC _ => raise bug "non instantiated tfv (3-1)"
                    | I.TFV_DTY _ => raise bug "non instantiated tfv (3-2)"
                    | I.TFUN_DTY _ => SymbolEnv.insert(tyE, name, tstr)
                    | I.FUN_DTY _ => SymbolEnv.insert(tyE, name, tstr)
                    | I.REALIZED _ => raise bug "non instantiated tfv (3-3)"
                   )
                 | _ => SymbolEnv.insert(tyE, name, tstr)
                )
              | V.TSTR_DTY {tfun=specTfun, varE=tstrVarE, ...} =>
                (case I.derefTfun specTfun of
                   I.TFUN_VAR (tfv as ref tfunkind) =>
                   (case tfunkind of
                      I.INSTANTIATED {tfunkind, tfun} =>
                      (tfv := I.REALIZED{tfun=tfun,id=I.tfunkindId tfunkind};
                       case I.derefTfun tfun of 
                        I.TFUN_VAR
                          (ref (I.TFUN_DTY{id,iseq,formals,runtimeTy,conSpec,
                                           conIDSet,
                                           longsymbol,liftedTys,dtyKind})) =>
                        let
                          val varE =
                              SymbolEnv.mapi
                                (fn (name, _) =>
                                    case SymbolEnv.find(varE, name) of
                                      SOME idstatus => idstatus
                                    | NONE => raise bug "id not found"
                                )
                                tstrVarE
                        in
                          SymbolEnv.insert
                            (tyE,
                             name,
                             V.TSTR_DTY {tfun=tfun,
                                         varE=varE,
                                         formals=formals,
                                         conSpec=conSpec}
                            )
                        end
                      | _ => raise bug "non dty instance"
                      )
                    | I.TFV_SPEC _ => raise bug "non instantiated tfv (3)"
                    | I.TFV_DTY _ => raise bug "non instantiated tfv (3)"
                    | I.TFUN_DTY _ => SymbolEnv.insert(tyE, name, tstr)
                    | _ => raise bug "non instantiated tfv (4)"
                   )
                 | _ => SymbolEnv.insert(tyE, name, tstr)
                )

          fun makeTransInstanceTyE tyE =
              SymbolEnv.foldri
                (fn (name, tstr, tyE) =>
                    makeTransInstanceTstr name (tstr, tyE)
                )
                SymbolEnv.empty
                tyE
          fun makeTransInstanceStrE (V.STR strEnvMap) =
              let
                val strEnvMap =
                    SymbolEnv.foldri
                      (fn (name, {env, strKind}, strEnvMap) =>
                          let
                            val env = makeTransInstanceEnv (path@[name]) env
(*  structure id is refreshed if necessary in NameEval
                            val strKind = V.STRENV (StructureID.generate())
*)
                          in
                            SymbolEnv.insert(strEnvMap, name, {env=env, strKind=strKind})
                          end
                      )
                      SymbolEnv.empty
                      strEnvMap
              in
                V.STR strEnvMap
              end
          val tyE = makeTransInstanceTyE tyE
          val strE = makeTransInstanceStrE strE
        in
          V.ENV {varE=varE, tyE=tyE, strE=strE}
        end

      fun makeInstanceEnv path env =
          case mode of 
            Opaque => makeOpaqueInstanceEnv path env
          | Trans => makeTransInstanceEnv path env

      (* sigCheck body *)
      val path = #strPath param
      val specEnv = #specEnv param
      val strEnv = #strEnv param
      val _ = instantiateEnv path (specEnv, strEnv)
      val (env, icdeclList1) = checkEnv path (specEnv, strEnv)
      val env = makeInstanceEnv path env
      val env = N.reduceEnv env
    in
      (env, icdeclList1)
    end

  fun refreshEnv copyPath (typidSet, exnIdSubst) specEnv
      : (S.tfvSubst * S.conIdSubst) * V.env =
    let
      val tfvMap = TF.tfvsEnv TF.allTfvKind nil (specEnv, TfvMap.empty)
      val (tfvSubst, conIdSubst) = 
          TfvMap.foldri
          (fn (tfv as ref (I.TFV_SPEC {longsymbol, iseq, formals,...}),path,
               (tfvSubst, conIdSubst)) =>
              let
                val id = TypID.generate()
                val newTfv =
                    I.mkTfv (I.TFV_SPEC{longsymbol=longsymbol, id=id,iseq=iseq,formals=formals})
              in 
                (TfvMap.insert(tfvSubst, tfv, newTfv), conIdSubst)
              end
            | (tfv as ref (I.INSTANTIATED {tfunkind, tfun}),
               path, (tfvSubst, conIdSubst)) =>
              let
                val newTfv = I.mkTfv (I.INSTANTIATED {tfunkind=tfunkind, tfun=tfun})
              in 
                (TfvMap.insert(tfvSubst, tfv, newTfv), conIdSubst)
              end
            | (tfv as ref (I.TFV_DTY {longsymbol, iseq,formals,conSpec,liftedTys,...}),
               path, (tfvSubst, conIdSubst)) =>
              let
                val id = TypID.generate()
                val newTfv =
                    I.mkTfv (I.TFV_DTY{id=id,
                                       longsymbol=longsymbol,
                                       iseq=iseq,
                                       conSpec=conSpec,
                                       liftedTys=liftedTys,
                                       formals=formals}
                          )
              in 
                (TfvMap.insert(tfvSubst, tfv, newTfv), conIdSubst)
              end
            | (tfv as
                   ref(I.TFUN_DTY
                         {id,iseq,formals,runtimeTy,longsymbol = originalPath,
                          conIDSet,
                          conSpec,liftedTys,dtyKind}),
               path, (tfvSubst, conIdSubst)) =>
              if TypID.Set.member(typidSet, id) then
                let
                  val (name, path) = case List.rev path of
                                       h::tl => (h, List.rev tl)
                                     | _ => raise bug "nil path (2)"
                  val (name, _) = case List.rev originalPath of
                                       h::tl => (h, List.rev tl)
                                     (* 2012-8-6 ohori bug 062_functorPoly.sml
                                        This should not happen; but
                                        in case we can use the the above 
                                        name here; they should be the same.
                                     | _ => raise bug "nil path (2)"
                                      *)
                                     | _ => (name, path)
                  val id = TypID.generate()
                  val (conIdSubst, conIDSet) =
                      SymbolEnv.foldri
                      (fn (name, _, (conIdSubst, conIDSet)) =>
                          case V.checkId(specEnv, path@[name]) of
                            SOME (I.IDCON {id, longsymbol, ty}) =>
                            let
                              val newId = ConID.generate()
                              val newConInfo = {id=newId, longsymbol=longsymbol, ty=ty}
                              val _ = V.conEnvAdd (newId, newConInfo)
                            in
                              (ConID.Map.insert(conIdSubst, id, I.IDCON newConInfo),
                               ConID.Set.map (fn i => if ConID.eq(i, id) then newId else i) conIDSet)
                            end
                          | _ => (conIdSubst, conIDSet)
                      )
                      (conIdSubst, conIDSet)
                      conSpec
                  val newTfv =
                      I.mkTfv 
                        (I.TFUN_DTY
                           {id=id,
                            iseq=iseq,
                            formals=formals,
                            runtimeTy=runtimeTy,
                            conSpec=conSpec,
                            conIDSet = conIDSet,
                            longsymbol = copyPath @ [name],
                            (*
                             originalPath=originalPath,
                             2012-7-22 ohori: bug 222_functorArgumentTyconName.sml
                             This is the real tycon generated here. So we set
                             its real name here.
                             *)
                            liftedTys=liftedTys,
                            dtyKind=dtyKind
                           }
                        )
                in 
                  (TfvMap.insert(tfvSubst, tfv, newTfv), conIdSubst)
                end
              else (tfvSubst, conIdSubst)
            | _ => raise bug "non tfv (11)"
          )
          (TfvMap.empty, ConID.Map.empty)
          tfvMap
          handle exn => raise exn
      val _ =
          TfvMap.app
          (fn (tfv as 
                   ref (I.TFV_DTY{longsymbol,iseq,formals,conSpec,liftedTys,id})) =>
              let
                val conSpec =
                    SymbolEnv.map
                    (fn tyOpt =>
                        Option.map (S.substTfvTy tfvSubst) tyOpt)
                    conSpec
              in
                tfv:=
                    I.TFV_DTY
                      {iseq=iseq,
                       longsymbol=longsymbol,
                       formals=formals,
                       conSpec=conSpec,
                       liftedTys=liftedTys,
                       id=id}
              end
            | (tfv as ref (I.TFUN_DTY {iseq,
                                       formals,
                                       conSpec,
                                       conIDSet,
                                       longsymbol,
                                       runtimeTy,
                                       liftedTys,
                                       id,
                                       dtyKind
                                      })) =>
              let
                val dtyKind =
                    case dtyKind of
                      I.OPAQUE{tfun, revealKey} => 
                      I.OPAQUE{tfun=S.substTfvTfun tfvSubst tfun,
                                revealKey=revealKey}
                    | _ => dtyKind
                val conSpec =
                    SymbolEnv.map
                    (fn tyOpt =>
                        Option.map (S.substTfvTy tfvSubst) tyOpt)
                    conSpec
              in
                tfv:=
                    I.TFUN_DTY
                      {iseq=iseq,
                       formals=formals,
                       runtimeTy=runtimeTy,
                       conSpec=conSpec,
                       conIDSet=conIDSet,
                       longsymbol=longsymbol,
                       liftedTys=liftedTys,
                       dtyKind=dtyKind,
                       id=id}
              end
            | _ => ())
          tfvSubst
          handle exn => raise exn
      val subst = {tvarS=S.emptyTvarSubst,
                   exnIdS=exnIdSubst,
                   conIdS=conIdSubst} 
      val env =S.substTfvEnv tfvSubst specEnv
      val env =S.substEnv subst env
    in
      ((tfvSubst, conIdSubst), env)
    end

end
end
