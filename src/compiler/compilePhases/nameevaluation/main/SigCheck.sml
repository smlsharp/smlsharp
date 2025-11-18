(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure SigCheck =
struct
local
  structure I = IDCalc
  structure Ty = EvalTy
  structure V = NameEvalEnv
  structure VP = NameEvalEnvPrims
  structure S = Subst
  structure TF = TfunVars
  structure U = NameEvalUtils
  structure EU = UserErrorUtils
  structure E = NameEvalError
  structure N = NormalizeTy
  fun bug s = Bug.Bug ("SigCheck: " ^ s)
  infix @@
  val op @@ = SymbolWithLoc.prefixPath'
in
  exception SIGCHECK
  datatype mode = Opaque | Trans
  type sigCheckParam =
       {mode:mode,loc:Loc.loc,strPath:SymbolWithLoc.symbol list,strEnv:V.env,specEnv:V.env}
  type sigCheckResult = V.env * I.icdecl list 

  fun printConSpec string conSpec = 
      (U.print ("conSpec " ^ string ^ "\n");
       SymbolWithLocEnv.mapi
         (fn (symbol, tyOpt) =>
             (
              U.print "symbol\n";
              U.printSymbol symbol;
              U.print "\n tyopt\n";
              (case tyOpt of
                 NONE => U.print "NONE\n"
               | SOME ty => 
                 (U.print "SOME(";
                  U.printTy ty; 
                  U.print ")\n")
              )
             )
         )
         conSpec
      )

  fun printVarE string conSpec = 
      (U.print ("varE " ^ string ^ "\n");
       SymbolWithLocEnv.mapi
         (fn (symbol, idStatus) =>
             (
              U.print "symbol\n";
              U.printSymbol symbol;
              U.print "\n tyopt\n";
              U.printIdstatus idStatus
             )
         )
         conSpec
      )

  fun printTfvSubst string tfvSubst =
      (U.print ("tfvMap " ^ string ^ "\n");
       TfvMap.mapi 
         (fn (ref x, ref y) => 
             (
              U.print "key:\n";
              U.printTfunkind x;
              U.print "\n";
              U.print "value:\n";
              U.printTfunkind y;
              U.print "\n"
             )
         ) 
        tfvSubst
      )
   fun removeVarE (srcVarE, targetVarE) =
       SymbolWithLocEnv.foldli
       (fn (name, _, targetVarE) =>
           let
             val (targetVarE, _) = SymbolWithLocEnv.remove(targetVarE, name)
           in
             targetVarE
           end
           handle LibBase.NotFound => targetVarE
       )
       targetVarE
       srcVarE
   and removeTyE (srcTyE, targetTyE) =
       SymbolWithLocEnv.foldli
       (fn (name, _, targetTyE) =>
           let
             val (targetTyE, _) = SymbolWithLocEnv.remove(targetTyE, name)
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
         SymbolWithLocEnv.foldli
           (fn (name, _, targetStrE) =>
               let
                 val (targetStrE, _) = SymbolWithLocEnv.remove(targetStrE, name)
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
                             V.TSTR {tfun,...} => tfun
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
                                      V.TSTR {tfun,...} => tfun
                                    | V.TSTR_DTY {tfun, ...} => tfun
                    val _ = if I.tfunAdmitsEq tfun andalso not (I.tfunAdmitsEq tstrTfun) then
                              EU.enqueueError
                                (#loc name,
                                 E.SIGEqtype("200",{longsymbol=SymbolWithLoc.toLongsymbol (path@@name)}))
                            else ()
                    val _ = if I.tfunArity tfun <> I.tfunArity tstrTfun then
                              EU.enqueueError
                                (#loc name,
                                 E.SIGArity("210",{longsymbol=SymbolWithLoc.toLongsymbol (path@@name)}))
                            else ()
                  in
                    tfv := I.INSTANTIATED {tfunkind=tfunkind, tfun=tstrTfun}
                  end
                | I.TFUN_VAR (tfv as (ref (tfunkind as I.TFV_DTY _))) =>
                  let
                    val tstrTfun = 
                        case strTstr of
                          V.TSTR {tfun,...} => tfun
                        | V.TSTR_DTY {tfun, ...} => tfun
                    val _ = if I.tfunAdmitsEq tfun andalso not (I.tfunAdmitsEq tstrTfun) then
                              EU.enqueueError
                                (#loc name,
                                 E.SIGEqtype("220",{longsymbol=SymbolWithLoc.toLongsymbol (path@@name)}))
                            else ()
                    val _ = if I.tfunArity tfun <> I.tfunArity tstrTfun then
                              EU.enqueueError
                                (#loc name,
                                 E.SIGArity("230",{longsymbol=SymbolWithLoc.toLongsymbol (path@@name)}))
                            else ()
                  in
                    tfv := I.INSTANTIATED {tfunkind=tfunkind, tfun=tstrTfun}
                  end
              end
          fun instantiateTyE (specTyE, strTyE) =
              SymbolWithLocEnv.appi
                (fn (symbol, specTstr) =>
                    case SymbolWithLocEnv.findi (strTyE, symbol) of
                      NONE => ()
                    | SOME (strEnvSymbol, strTstr) =>  
                      instantiateTstr strEnvSymbol (specTstr, strTstr)
                )
                specTyE
          fun instantiateStrE (V.STR specEnvMap, V.STR strEnvMap) =
              SymbolWithLocEnv.appi
              (fn (specSymbol, {env=specEnv, strKind=_, loc, definedSymbol}) =>
                  case SymbolWithLocEnv.find(strEnvMap, specSymbol) of
                    NONE => () (* error will be checked in checkStrE *)
                  | SOME {env=strEnv, strKind=_, loc, definedSymbol} =>
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
                       (#loc strSymbol,
                        E.SIGArity("240",{longsymbol=SymbolWithLoc.toLongsymbol (path@@strSymbol)}))
                  else if N.eqTydef N.emptyTypIdEquiv ((specFormals,specTy),(strFormals,strTy))
                  then ()
                  else (EU.enqueueError 
                          (#loc strSymbol,
                           E.SIGDtyMismatch ("250",{longsymbol=SymbolWithLoc.toLongsymbol (path@@specSymbol)})))
                | (I.TFUN_VAR (ref (I.TFUN_DTY {id=id1,...})), I.TFUN_VAR (ref (I.TFUN_DTY {id=id2,...}))) =>
                  if TypID.eq(id1,id2) then ()
                  else 
                    (EU.enqueueError 
                       (#loc strSymbol,
                        E.SIGDtyMismatch("260",{longsymbol=SymbolWithLoc.toLongsymbol (path@@specSymbol)})))
                | (I.TFUN_VAR (ref (I.FUN_DTY {tfun=specTfun,...})), strTfun) =>
                  checkTfun (specSymbol, strSymbol) (specTfun, strTfun)
                | (specTfun, I.TFUN_VAR (ref (I.FUN_DTY {tfun=strTfun,...}))) =>
                  checkTfun (specSymbol, strSymbol) (specTfun, strTfun)
                | _ =>(EU.enqueueError
                         (#loc strSymbol,
                          E.SIGDtyMismatch("270",{longsymbol=SymbolWithLoc.toLongsymbol (path@@strSymbol)})))
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
                    SymbolWithLocEnv.foldli
                    (fn (specSymbol, tyopt1, conSpec2) =>
                        let
                          val (strSymbol, conSpec2, tyopt2) = SymbolWithLocEnv.removei(conSpec2, specSymbol)
                        in
                          case (tyopt1,tyopt2) of
                            (NONE, NONE) => conSpec2
                          | (SOME _, NONE) => 
                            (EU.enqueueError 
                               (#loc strSymbol,
                                E.SIGConType ("280",{longsymbol=SymbolWithLoc.toLongsymbol (path@@strSymbol)}));
                             conSpec2)
                          | (NONE, SOME _) =>
                            (EU.enqueueError 
                               (#loc strSymbol,
                                E.SIGConType ("290",{longsymbol=SymbolWithLoc.toLongsymbol (path@@strSymbol)}));
                             conSpec2)
                          | (SOME ty1, SOME ty2) => 
                            if N.equalTy (typIdEquiv, tvarIdEquiv) (ty1, ty2) then 
                              conSpec2
                            else 
                              (EU.enqueueError 
                                 (#loc strSymbol,
                                  E.SIGConType ("300",{longsymbol=SymbolWithLoc.toLongsymbol (path@@strSymbol)}));
                               conSpec2)
                        end
                        handle LibBase.NotFound => 
                            (EU.enqueueError 
                               (#loc specSymbol,
                                E.SIGConNotFoundInDty ("310",{longsymbol=SymbolWithLoc.toLongsymbol (path@@specSymbol)}));
                             conSpec2)
                    )
                    conSpec2
                    conSpec1
                val _ = 
                    SymbolWithLocEnv.appi
                      (fn (strSymbol,_) =>
                          EU.enqueueError 
                            (#loc strSymbol,
                             E.SIGConNotInSig ("320",{longsymbol=SymbolWithLoc.toLongsymbol (path@@strSymbol)})
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
                  SymbolWithLocEnv.appi
                    (fn (conSymbol, idstatus) => 
                        case SymbolWithLocEnv.find(strVarE, conSymbol) of
                          NONE => 
                          EU.enqueueError 
                            (#loc conSymbol,
                             E.SIGConNotFound ("330",{longsymbol=SymbolWithLoc.toLongsymbol (path@@conSymbol)}))
                        | SOME strIdstatus =>
                          (case (idstatus, strIdstatus) of
                             (I.IDCON {id=conid1, ty=ty1,...}, I.IDCON {id=conid2, ty=ty2,...}) =>
                             if ConID.eq(conid1, conid2) then ()
                             else
                               (EU.enqueueError 
                                  (#loc conSymbol,
                                   E.SIGConNotFound ("340",{longsymbol=SymbolWithLoc.toLongsymbol (path@@conSymbol)})))
                           | (I.IDCON _, _) => 
                             EU.enqueueError 
                               (#loc conSymbol,
                                E.SIGConNotFound("350",{longsymbol=SymbolWithLoc.toLongsymbol (path@@conSymbol)}))
                           | (I.IDSPECCON _, I.IDCON _) => ()
                           | _ => raise bug "non conid"
                          )
                    )
                    varE
            in
              case specTstr of
                V.TSTR {tfun = specTfun,...} =>
                (case strTstr of
                   V.TSTR {tfun = strTfun,...} => 
                   (checkTfun (specSymbol, strSymbol) (specTfun, strTfun) ; specTstr)
                 | V.TSTR_DTY {tfun=strTfun, ...} =>
                   (checkTfun (specSymbol, strSymbol) (specTfun, strTfun); specTstr)
                )
              | V.TSTR_DTY {tfun=specTfun,formals, defRange = defRangeStr, conSpec,...} =>
                (case strTstr of
                   V.TSTR _ =>
                   (EU.enqueueError 
                      (#loc strSymbol,
                       E.SIGDtyRequired("360",{longsymbol=SymbolWithLoc.toLongsymbol (path@@strSymbol)}));
                    specTstr)
                 | V.TSTR_DTY {tfun=strTfun, varE=strVarE, formals=strFormals, conSpec=strConSpec,...} =>
                   (checkTfun (specSymbol, strSymbol) (specTfun, strTfun);
                    if List.length formals <> List.length strFormals then
                      EU.enqueueError 
                        (#loc strSymbol,
                         E.SIGArity ("370",{longsymbol=SymbolWithLoc.toLongsymbol (path@@specSymbol)}))
                    else ();
                    checkConSpec 
                      N.emptyTypIdEquiv
                      ((formals, conSpec), (strFormals, strConSpec));
                    checkVarE strVarE;
                    V.TSTR_DTY{tfun=specTfun, formals=formals, conSpec=conSpec, 
                               defRange = defRangeStr, varE=strVarE}
                   )
                )
            end
                
          fun checkTyE (specTyE, strTyE) =
              SymbolWithLocEnv.foldri
                (fn (specSymbol, specTstr, tyE) =>
                    case SymbolWithLocEnv.findi (strTyE, specSymbol) of
                      NONE => 
                      (EU.enqueueError 
                         (#loc specSymbol,
                          E.SIGTypUndefined("380",{longsymbol=SymbolWithLoc.toLongsymbol (path@@specSymbol)}));
                       tyE)
                    | SOME (strSymbol, strTstr) => 
                      let
                        val str = checkTstr (specSymbol, strSymbol) (specTstr, strTstr)
                      in
                        SymbolWithLocEnv.insert(tyE, strSymbol, str)
                      end
                )
                SymbolWithLocEnv.empty
                specTyE

                
          fun isTrans ty = 
              let
                exception OPAQUE 
                fun trace ty =
                    case ty of
                      I.TYWILD => ()
                    | I.TYERROR => ()
                    | I.TYVAR _  => ()
                    | I.TYFREE_TYVAR _  => ()
                    | I.TYRECORD {ifFlex, fields=tyLabelenvMap} =>
                      RecordLabel.Map.app trace tyLabelenvMap
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
              SymbolWithLocEnv.foldri
                (fn (name, specIdStatus, (varE, icdeclList)) =>
                    case specIdStatus of
                      I.IDSPECVAR {ty=specTy, symbol, defRange} =>
                      let
                        fun makeDecl strName icexp =
                            let
                              val newId = VarID.generate()
                              val longsymbol = path@@name
                              val var = {longsymbol=longsymbol,id=newId}
                              val icdecl = 
                               case mode of 
                                 Trans =>
                                 I.ICVAL_TRANS_SIG {var = var, exp = icexp, ty = specTy, loc = loc}
                               | Opaque => 
                                 I.ICVAL_OPAQUE_SIG {var = var,
                                                    revealKey = revealKey,
                                                    exp = icexp,
                                                    ty = specTy, 
                                                    loc = loc}
                            in
                              (SymbolWithLocEnv.insert(varE, strName,
                                                I.IDVAR_TYPED {id=newId, ty=specTy,
                                                               defRange = defRange,
                                                               longsymbol=longsymbol}),
                               icdecl :: icdeclList)
                            end
                        fun makeTypdecl strName (icexp, idstatusActualTyOpt) =
                            case idstatusActualTyOpt of
                              SOME (actualTy, idstatus) =>
                              if isTrans specTy andalso
                                 N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (specTy, actualTy) 
                              then (SymbolWithLocEnv.insert(varE, strName, idstatus), icdeclList)
                              else makeDecl strName icexp
                            | NONE => makeDecl strName icexp
                      in
                        case SymbolWithLocEnv.findi(strVarE, name) of
                          NONE =>
                          (EU.enqueueError
                             (#loc name,
                              E.SIGVarUndefined ("390",{longsymbol = SymbolWithLoc.toLongsymbol (path@@name)}));
                           (varE, icdeclList)
                          )
                        | SOME (strName, I.IDVAR {id,longsymbol,defRange}) => 
                          let
                            val longsymbol = path@@strName
                          in
                            makeTypdecl strName (I.ICVAR {longsymbol=longsymbol,id=id}, NONE)
                          end
                        | SOME (strName, 
                                idstatus as I.IDVAR_TYPED {id, ty, longsymbol,defRange}) => 
                          let
                            val longsymbol = path@@strName
                          in
                            makeTypdecl strName
                                        (I.ICVAR {longsymbol=longsymbol,id=id}, 
                                         SOME (ty, idstatus))
                          end
                        | SOME (strName, idstatus as I.IDEXVAR {exInfo, internalId,defRange}) => 
                          (#used exInfo := true;
                           makeTypdecl strName
                                       (I.ICEXVAR {longsymbol=path@@strName,exInfo=exInfo},
                                        SOME (#ty exInfo, idstatus))
                          )
                        | SOME (strName, I.IDEXVAR_TOBETYPED _) =>  raise bug "IDEXVAR_TOBETYPED"
                        | SOME (strName, idstatus as I.IDBUILTINVAR {primitive, ty, defRange}) => 
                          makeTypdecl strName
                            (I.ICBUILTINVAR {primitive=primitive,ty=ty,loc=loc}, 
                             SOME (ty, idstatus))
                        | SOME (strName, I.IDCON {id, longsymbol, ty, defRange}) =>
                          let
                            val longsymbol = path@@strName
                          in
                            makeTypdecl strName
                              (I.ICCON {longsymbol=longsymbol,ty=ty, id=id}, NONE)
                          end
                        | SOME (strName, I.IDEXN {id, longsymbol, ty, defRange}) => 
                          let
                            val longsymbol = path@@strName
                          in
                            makeTypdecl strName
                              (I.ICEXN {longsymbol=longsymbol,ty=ty, id=id}, NONE)
                          end
                        | SOME (strName, I.IDEXNREP {id, longsymbol, ty, defRange}) => 
                          let
                            val longsymbol = path@@strName
                          in
                            makeTypdecl strName
                              (I.ICEXN {longsymbol=longsymbol,ty=ty, id=id}, NONE)
                          end
                        | SOME (strName, I.IDEXEXN exExnInfo) => 
                          (#used exExnInfo := true;
                           makeTypdecl strName
                             (I.ICEXEXN {exInfo= I.idInfoToExExnInfo exExnInfo,
                                         longsymbol=path@@strName},
                              NONE)
                          )
                        | SOME (strName, I.IDEXEXNREP exExnInfo) => 
                          (#used exExnInfo := true;
                           makeTypdecl strName
                                       (I.ICEXEXN {longsymbol=path@@strName,
                                                   exInfo=I.idInfoToExExnInfo exExnInfo}, NONE)
                          )
                        | SOME (strName, 
                                I.IDOPRIM {id, overloadDef, used, longsymbol, defRange}) => 
                          let
                            val longsymbol = path@@strName
                          in
                            (used := true;
                             makeTypdecl strName (I.ICOPRIM {longsymbol=longsymbol,id=id}, NONE)
                            )
                          end
                        | SOME (strName, I.IDSPECVAR _) => raise bug "IDSPECVAR"
                        | SOME (strName, I.IDSPECEXN _) => raise bug "IDSPECEXN"
                        | SOME (strName, I.IDSPECCON _) => raise bug "IDSPECCON"
                      end
                    | I.IDSPECEXN {ty=ty1, symbol, defRange=dr1} => 
                      (case SymbolWithLocEnv.findi(strVarE, name) of
                         NONE =>
                         (EU.enqueueError
                            (#loc name,
                             E.SIGVarUndefined("400",{longsymbol = SymbolWithLoc.toLongsymbol (path@@name)}));
                          (varE, icdeclList)
                         )
                       | SOME (strName, 
                               idstatus as I.IDEXN {id, ty=ty2, longsymbol, defRange=df2}) =>
                         let
                           val ty1 = N.reduceTy TvarMap.empty ty1
                           val ty2 = N.reduceTy TvarMap.empty ty2
                         in
                           (* we must return ty1 instead of ty2 here,
                              since ty1 may be abstracted *)
                           if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1, ty2) then
                             (SymbolWithLocEnv.insert
                                (varE,
                                 strName,
                                 I.IDEXN {id=id, longsymbol=longsymbol, ty=ty1, 
                                          defRange = df2}),
                              icdeclList)
                           else 
                             (EU.enqueueError 
                                (#loc name,
                                 E.SIGExnType("410",{longsymbol = SymbolWithLoc.toLongsymbol (path@@name)}));
                              (varE, icdeclList)
                             )
                         end
                       | SOME (strName, 
                               idstatus as I.IDEXNREP {id, longsymbol, ty=ty2, defRange}) =>
                         let
                           val ty1 = N.reduceTy TvarMap.empty ty1
                           val ty2 = N.reduceTy TvarMap.empty ty2
                         in
                           if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1, ty2) then
                             (SymbolWithLocEnv.insert(varE, strName, idstatus), icdeclList)
                           else 
                             (EU.enqueueError
                                (#loc strName,
                                 E.SIGExnType("420",{longsymbol = SymbolWithLoc.toLongsymbol (path@@strName)}));
                              (varE, icdeclList)
                             )
                         end
                       | SOME (strName, idstatus as I.IDEXEXN {used, longsymbol, ty=ty2, version, 
                                                               defRange}) => 
                         let
                           val _ = used := true
                           val ty1 = N.reduceTy TvarMap.empty ty1
                           val ty2 = N.reduceTy TvarMap.empty ty2
                         in
                           if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1, ty2) then
                             (SymbolWithLocEnv.insert(varE, strName, idstatus), icdeclList)
                           else 
                             (EU.enqueueError
                                (#loc strName,
                                 E.SIGExnType ("430",{longsymbol = SymbolWithLoc.toLongsymbol (path@@strName)}));
                              (varE, icdeclList)
                             )
                         end
                       | SOME (strName, idstatus as I.IDEXEXNREP {used, ty=ty2,...}) => 
                         let
                           val _ = used := true
                           val ty1 = N.reduceTy TvarMap.empty ty1
                           val ty2 = N.reduceTy TvarMap.empty ty2
                         in
                           if N.equalTy (N.emptyTypIdEquiv, TvarID.Map.empty) (ty1, ty2) then
                             (SymbolWithLocEnv.insert(varE, strName, idstatus), icdeclList)
                           else 
                             (EU.enqueueError 
                                (#loc strName,
                                 E.SIGExnType ("440",{longsymbol = SymbolWithLoc.toLongsymbol (path@@name)}));
                              (varE, icdeclList)
                             )
                         end
                       | SOME (strName, _) =>
                         (EU.enqueueError
                            (#loc strName,
                             E.SIGExnExpected ("450",{longsymbol = SymbolWithLoc.toLongsymbol (path@@strName)}));
                          (varE, icdeclList)
                         )
                      )
                    | I.IDSPECCON {symbol, defRange} =>
                      (case SymbolWithLocEnv.findi(strVarE, name) of
                         NONE =>
                         (EU.enqueueError
                            (#loc name,
                             E.SIGVarUndefined("460",{longsymbol = SymbolWithLoc.toLongsymbol (path@@name)}));
                          (varE, icdeclList)
                         )
                       | SOME (strName, idstatus as I.IDCON {id,ty,...}) => 
                         (SymbolWithLocEnv.insert(varE, strName, idstatus), icdeclList)
                       | SOME (strName, _) => 
                         (EU.enqueueError
                            (#loc strName,
                             E.SIGConNotFound ("470",{longsymbol = SymbolWithLoc.toLongsymbol (path@@strName)}));
                          (varE, icdeclList)
                         )
                      )
                    | I.IDCON {id, longsymbol, ty, defRange} =>
                      (case SymbolWithLocEnv.findi(strVarE, name) of
                         NONE =>
                         (EU.enqueueError
                            (#loc name,
                             E.SIGVarUndefined ("480",{longsymbol = SymbolWithLoc.toLongsymbol (path@@name)}));
                          (varE, icdeclList)
                         )
                       | SOME (strName, idstatus as I.IDCON {id=id2, ty=ty2,...}) => 
                         if ConID.eq(id, id2) then 
                           (SymbolWithLocEnv.insert(varE, strName, idstatus), icdeclList)
                         else 
                           (EU.enqueueError
                              (#loc name,
                               E.SIGConNotFound ("490",{longsymbol = SymbolWithLoc.toLongsymbol (path@@name)}));
                            (varE, icdeclList)
                           )
                       | SOME _ => 
                         (EU.enqueueError
                            (#loc name,
                             E.SIGConNotFound ("500",{longsymbol = SymbolWithLoc.toLongsymbol (path@@name)}));
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
                (SymbolWithLocEnv.empty, nil)
                specVarE

          fun checkStrE (V.STR specEnvMap, V.STR strEnvMap) =
              SymbolWithLocEnv.foldri
                (fn (name, {env=specEnv, strKind=specStrKind, loc, definedSymbol}, 
                     (strE, icdeclList)) =>
                    case SymbolWithLocEnv.findi(strEnvMap, name) of
                      NONE => 
                      (EU.enqueueError
                         (#loc name,
                          E.SIGStrUndefined("510",{longsymbol=SymbolWithLoc.toLongsymbol (path@@name)}));
                       (strE, icdeclList))
                    | SOME (strName, {env=strEnv, strKind=strStrKind, loc, definedSymbol}) =>
                      let
                        val (env, icdeclList1) = checkEnv (path@[strName]) (specEnv, strEnv)
                      in
                        (SymbolWithLocEnv.insert
                           (strE, strName, {env=env, strKind=strStrKind, loc = loc, 
                                            definedSymbol = definedSymbol}), 
                         icdeclList@icdeclList1)
                      end
                )
                (SymbolWithLocEnv.empty, nil)
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
                V.TSTR {tfun,defRange} =>
                (case I.derefTfun tfun of
                   I.TFUN_VAR(tfv as ref (I.INSTANTIATED {tfunkind,tfun})) =>
                   (case tfunkind of (* creating a return env *)
                      I.TFV_SPEC {id, admitsEq, ...} =>
                      let
                        val formals = I.tfunFormals tfun
                        val liftedTys = I.tfunLiftedTys tfun
                        (* 2012-7-14: ohori [name] is added. *)
                        val longsymbol = path@@name
                        val newTfunkind =
                            I.TFUN_DTY {id=id,
                                        admitsEq=admitsEq,
                                        formals=formals,
                                        conSpec=SymbolWithLocEnv.empty,
                                        conIDSet = ConID.Set.empty,
                                        longsymbol=longsymbol,
                                        liftedTys=liftedTys,
                                        dtyKind=I.OPAQUE
                                                  {tfun=tfun,
                                                   revealKey=revealKey}
                                       }
                        val _ = tfv := newTfunkind
                        val tsr = {tfun = I.TFUN_VAR tfv, 
                                   defRange=defRange}
                        val env = 
                            VP.rebindTstr VP.SIGCHECK (env,name, V.TSTR tsr)
                      in
                        env
                      end
                    | I.TFV_DTY {id, admitsEq, ...} =>
                      let
                        val formals = I.tfunFormals tfun
                        val liftedTys = I.tfunLiftedTys tfun
                        val newTfunkind =
                            I.TFUN_DTY 
                              {id=id,
                               admitsEq=admitsEq,
                               formals=formals,
                               conSpec=SymbolWithLocEnv.empty,
                               conIDSet=ConID.Set.empty,
                               (* 2012-7-14: ohori [name] is added. *)
                               longsymbol= path @@ name,
                               liftedTys=liftedTys,
                               dtyKind=
                               I.OPAQUE
                                 {tfun=tfun, revealKey=revealKey}
                              }
                        val _ = tfv := newTfunkind
                        val newTfun = I.TFUN_VAR tfv
                        val tsr = {tfun = newTfun, defRange = defRange}
                        val env = VP.rebindTstr VP.SIGCHECK (env, name,V.TSTR tsr)
                      in
                        env
                      end
                    | _ => raise bug "non tfv (5)"
                   )
                 | I.TFUN_VAR _ => VP.rebindTstr VP.SIGCHECK(env, name, tstr)
                 | I.TFUN_DEF _ => VP.rebindTstr VP.SIGCHECK(env, name, tstr)
                )
              | V.TSTR_DTY {tfun, varE, defRange, ...} =>
                (case I.derefTfun tfun of
                   I.TFUN_VAR
                     (tfv as ref (I.INSTANTIATED{tfunkind,tfun=strTfun})) =>
                      (case tfunkind of
                         I.TFV_DTY {longsymbol=_, id, admitsEq, 
                                    formals, conSpec, liftedTys} =>
                         let
                           val (conspecConId, conIDSet) =
                               SymbolWithLocEnv.foldri
                              (fn (name, tyOpt, (conspecConId, conIDSet)) =>
                                  let
                                    val conId = ConID.generate()
                                  in
                                    (SymbolWithLocEnv.insert
                                       (conspecConId, name, (tyOpt, conId)),
                                     ConID.Set.add(conIDSet, conId))
                                  end
                              )
                               (SymbolWithLocEnv.empty, ConID.Set.empty)
                               conSpec
                           val newTfunkind =
                               I.TFUN_DTY
                                 {id=id,
                                  admitsEq=admitsEq,
                                  formals=formals,
                                  conSpec=conSpec,
                                  conIDSet=conIDSet,
                                  (* 2012-7-14: ohori [name] is added. *)
                                  longsymbol= path @@ name,
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
                               SymbolWithLocEnv.foldri
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
                                                     (fn tv=>(tv,I.UNIV I.emptyProperties))
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
                                                    (fn tv =>(tv,I.UNIV I.emptyProperties))
                                                    formals,
                                                  I.TYFUNM([ty], returnTy)
                                                 )
                                       val longsymbol = path@@name
                                       (* defRangeに設定する値? *)
                                       val conInfo =
                                           {longsymbol=longsymbol, ty=conTy, 
                                            defRange = Loc.noloc,
                                            id=conId}
(*
                                       val _ = V.conEnvAdd(conId, conInfo)
*)
                                       val idstatus = I.IDCON conInfo
                                     in
                                       SymbolWithLocEnv.insert(varE, name, idstatus)
                                     end
                                 )
                                 SymbolWithLocEnv.empty
                                 conspecConId
                           val newTstr = V.TSTR_DTY
                                           {tfun=I.TFUN_VAR tfv,
                                            varE=varE,
                                            formals=formals,
                                            defRange = defRange,
                                            conSpec=conSpec}
                           val env = VP.rebindTstr VP.SIGCHECK(env, name, newTstr)
                           val env = VP.envWithVarE(env, varE)
                         in
                           env
                         end
                       | _ => raise bug "non dty tfv (1)"
                      )
                 | _ => VP.rebindTstr VP.SIGCHECK(env, name, tstr)
                )

          fun makeOpaqueInstanceTyE tyE env =
              SymbolWithLocEnv.foldri
                (fn (name, tstr, env) => makeOpaqueInstanceTstr name (tstr, env)
                )
                env
                tyE
          fun makeOpaqueInstanceStrE (V.STR strEnvMap) env =
              let
                val env =
                    SymbolWithLocEnv.foldri
                      (fn (name, {env=strEnv, strKind, loc, definedSymbol}, env) =>
                          let
                            val strEnv = makeOpaqueInstanceEnv (path@[name]) strEnv
                            val strKind = V.STRENV (StructureID.generate())
                          in
                            VP.rebindStr VP.SIGCHECK
                              (env, name, {env=strEnv, strKind=strKind, 
                                           definedSymbol = definedSymbol,
                                           loc=loc}) 
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
                V.TSTR {tfun,defRange} =>
                (case I.derefTfun tfun of
                   I.TFUN_VAR (tfv as ref tfunkind) =>
                   (case tfunkind of
                      I.INSTANTIATED {tfunkind, tfun} =>
                      (tfv := I.REALIZED{tfun=tfun,id=I.tfunkindId tfunkind};
                       SymbolWithLocEnv.insert
                         (tyE, 
                          name, 
                          V.TSTR {tfun = tfun, defRange = defRange})
                      )
                    | I.TFV_SPEC _ => raise bug "non instantiated tfv (3-1)"
                    | I.TFV_DTY _ => raise bug "non instantiated tfv (3-2)"
                    | I.TFUN_DTY _ => SymbolWithLocEnv.insert(tyE, name, tstr)
                    | I.FUN_DTY _ => SymbolWithLocEnv.insert(tyE, name, tstr)
                    | I.REALIZED _ => raise bug "non instantiated tfv (3-3)"
                   )
                 | _ => SymbolWithLocEnv.insert(tyE, name, tstr)
                )
              | V.TSTR_DTY {tfun=specTfun, defRange, varE=tstrVarE, ...} =>
                (case I.derefTfun specTfun of
                   I.TFUN_VAR (tfv as ref tfunkind) =>
                   (case tfunkind of
                      I.INSTANTIATED {tfunkind, tfun} =>
                      (tfv := I.REALIZED{tfun=tfun,id=I.tfunkindId tfunkind};
                       case I.derefTfun tfun of 
                        I.TFUN_VAR
                          (ref (I.TFUN_DTY{id,admitsEq,formals,conSpec,
                                           conIDSet,
                                           longsymbol,liftedTys,dtyKind})) =>
                        let
                          val varE =
                              SymbolWithLocEnv.mapi
                                (fn (name, _) =>
                                    case SymbolWithLocEnv.find(varE, name) of
                                      SOME idstatus => idstatus
                                    | NONE => raise bug "id not found"
                                )
                                tstrVarE
                        in
                          SymbolWithLocEnv.insert
                            (tyE,
                             name,
                             V.TSTR_DTY {tfun=tfun,
                                         varE=varE,
                                         defRange = defRange,
                                         formals=formals,
                                         conSpec=conSpec}
                            )
                        end
                      | _ => raise bug "non dty instance"
                      )
                    | I.TFV_SPEC _ => raise bug "non instantiated tfv (3)"
                    | I.TFV_DTY _ => raise bug "non instantiated tfv (3)"
                    | I.TFUN_DTY _ => SymbolWithLocEnv.insert(tyE, name, tstr)
                    | _ => raise bug "non instantiated tfv (4)"
                   )
                 | _ => SymbolWithLocEnv.insert(tyE, name, tstr)
                )

          fun makeTransInstanceTyE tyE =
              SymbolWithLocEnv.foldri
                (fn (name, tstr, tyE) =>
                    makeTransInstanceTstr name (tstr, tyE)
                )
                SymbolWithLocEnv.empty
                tyE
          fun makeTransInstanceStrE (V.STR strEnvMap) =
              let
                val strEnvMap =
                    SymbolWithLocEnv.foldri
                      (fn (name, strEntry as {env,...}, strEnvMap) =>
                          let
                            val env = makeTransInstanceEnv (path@[name]) env
(*  structure id is refreshed if necessary in NameEval
                            val strKind = V.STRENV (StructureID.generate())
*)
                          in
                            SymbolWithLocEnv.insert
                              (strEnvMap, name, strEntry # {env=env})
                          end
                      )
                      SymbolWithLocEnv.empty
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

      val (typIdSubst, tfvSubst, conIdSubst) = 
          TfvMap.foldri
          (fn (tfv as ref (I.TFV_SPEC {id=origId, longsymbol, admitsEq, formals,...}),path,
               (typIdSubst, tfvSubst, conIdSubst)) =>
              let
                val id = TypID.generate()
                val newTfv =
                    I.mkTfv (I.TFV_SPEC{longsymbol=longsymbol, id=id,admitsEq=admitsEq,formals=formals})
              in 
                (TypID.Map.insert(typIdSubst, origId, id), 
                 TfvMap.insert(tfvSubst, tfv, newTfv), 
                 conIdSubst)
              end
            | (tfv as ref (I.INSTANTIATED {tfunkind, tfun}),
               path, (typIdSubst, tfvSubst, conIdSubst)) =>
              let
                val newTfv = I.mkTfv (I.INSTANTIATED {tfunkind=tfunkind, tfun=tfun})
              in 
                (typIdSubst, TfvMap.insert(tfvSubst, tfv, newTfv), conIdSubst)
              end
            | (tfv as ref (I.TFV_DTY {id=origId, longsymbol, admitsEq,formals,conSpec,liftedTys,...}),
               path, (typIdSubst, tfvSubst, conIdSubst)) =>
              let
                val id = TypID.generate()
                val newTfv =
                    I.mkTfv (I.TFV_DTY{id=id,
                                       longsymbol=longsymbol,
                                       admitsEq=admitsEq,
                                       conSpec=conSpec,
                                       liftedTys=liftedTys,
                                       formals=formals}
                          )
                val typIdSubst = TypID.Map.insert(typIdSubst, origId, id)
                val tfvSubst = TfvMap.insert(tfvSubst, tfv, newTfv)
              in 
                (typIdSubst, tfvSubst, conIdSubst)
              end
            | (tfv as
                   ref(I.TFUN_DTY
                         {id=origId,admitsEq,formals,longsymbol = originalPath,
                          conIDSet,
                          conSpec,liftedTys,dtyKind}),
               path, (typIdSubst, tfvSubst, conIdSubst)) =>
              if TypID.Set.member(typidSet, origId) then
                let
                  val path = SymbolWithLoc.pathOf path
                  val name = SymbolWithLoc.lastSymbol originalPath
                  val id = TypID.generate()
                  val (conIdSubst, conIDSet) =
                      SymbolWithLocEnv.foldri
                      (fn (name, _, (conIdSubst, conIDSet)) =>
                          case VP.checkSigId(specEnv, path@@name) of
                            SOME (I.IDCON {id, longsymbol, ty, defRange}) =>
                            let
                              val newId = ConID.generate()
                              val newConInfo = {id=newId, longsymbol=longsymbol, defRange=defRange,
                                                ty=ty}
(*
                              val _ = V.conEnvAdd (newId, newConInfo)
*)
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
                            admitsEq=admitsEq,
                            formals=formals,
                            conSpec=conSpec,
                            conIDSet = conIDSet,
                            longsymbol = copyPath @@ name,
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
                  val _ = 
                      newTfv := 
                      I.TFUN_DTY
                        {id=id,
                         admitsEq=admitsEq,
                         formals=formals,
                         conSpec=conSpec,
                         conIDSet = conIDSet,
                         longsymbol = copyPath @@ name,
                            (*
                             originalPath=originalPath,
                             2012-7-22 ohori: bug 222_functorArgumentTyconName.sml
                             This is the real tycon generated here. So we set
                             its real name here.
                             *)
                         liftedTys=liftedTys,
                         dtyKind=dtyKind
                        } 
                  val tfvSubst = TfvMap.insert(tfvSubst, tfv, newTfv)
                  val typIdSubst = TypID.Map.insert(typIdSubst, origId, id)
                in
                  (typIdSubst, tfvSubst, conIdSubst)
                end
              else (typIdSubst, tfvSubst, conIdSubst)
            | _ => raise bug "non tfv (11)"
          )
          (TypID.Map.empty, TfvMap.empty, ConID.Map.empty)
          tfvMap
          handle exn => raise exn
      val _ =
          TfvMap.app
          (fn 
              (tfv as 
                   ref (I.TFV_DTY{longsymbol,admitsEq,formals,conSpec,liftedTys,id})) =>
              let
                val conSpec =
                    SymbolWithLocEnv.map
                    (fn tyOpt =>
                        Option.map (S.substTfvTy tfvSubst) tyOpt)
                    conSpec
              in
                tfv:=
                    I.TFV_DTY
                      {admitsEq=admitsEq,
                       longsymbol=longsymbol,
                       formals=formals,
                       conSpec=conSpec,
                       liftedTys=liftedTys,
                       id=id}
              end
            | 
              (tfv as ref (I.FUN_DTY {tfun,
                                      longsymbol, 
                                      varE,
                                      formals,
                                      conSpec,
                                      liftedTys})) =>

              let
                val tfun = S.substTfvTfun tfvSubst tfun
                val varE = S.substTfvVarE tfvSubst varE
               val conSpec =
                    SymbolWithLocEnv.map
                    (fn tyOpt =>
                        Option.map (S.substTfvTy tfvSubst) tyOpt)
                    conSpec
              in
                tfv:=
                I.FUN_DTY {tfun = tfun,
                           longsymbol = longsymbol, 
                           varE = varE,
                           formals = formals,
                           conSpec = conSpec,
                           liftedTys = liftedTys}
              end
            |
              (tfv as ref (I.TFUN_DTY {admitsEq,
                                       formals,
                                       conSpec,
                                       conIDSet,
                                       longsymbol,
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
                    | I.INTERFACE tfun => 
                      I.INTERFACE (S.substTfvTfun tfvSubst tfun)
                    | _ => dtyKind
                val conSpec =
                    SymbolWithLocEnv.map
                    (fn tyOpt =>
                        Option.map (S.substTfvTy tfvSubst) tyOpt)
                    conSpec
              in
                tfv:=
                    I.TFUN_DTY
                      {admitsEq=admitsEq,
                       formals=formals,
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
                   exnIdS=S.emptyExnIdSubst,
                   conIdS=S.emptyConIdSubst,
                   typIdS=typIdSubst,
                   newProvider=NONE}
      val _ = 
          TfvMap.app
          (fn (tfv as ref tfunkind) => 
              tfv := S.substTfunkind subst tfunkind)
          tfvSubst
          handle exn => raise exn
      val env =S.substTfvEnv tfvSubst specEnv
          handle exn => raise exn
      val subst = {tvarS=S.emptyTvarSubst,
                   exnIdS=exnIdSubst,
                   conIdS=conIdSubst,
                   typIdS=S.emptyTypIdSubst,
                   newProvider=NONE}
      val env =S.substEnv subst env
          handle exn => raise exn
    in
      ((tfvSubst, conIdSubst), env)
    end

end
end
