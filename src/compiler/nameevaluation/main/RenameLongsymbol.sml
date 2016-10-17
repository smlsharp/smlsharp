structure RenameLongsymbol =
struct
  structure I = IDCalc
  structure V = NameEvalEnv
  val emptyRenameEnv = TypID.Map.empty : I.tfun TypID.Map.map

  fun replacePathLongsymbol (longsymbol, path) =
      let
        val symbol = Symbol.lastSymbol longsymbol
      in
        Symbol.prefixPath(path, symbol)
      end

  fun replacePathTfun renameEnv path tfun =
      case tfun of
        I.TFUN_VAR 
        (ref (I.TFUN_DTY 
                {id=newId,
                 iseq,
                 longsymbol,
                 formals,
                 conSpec,
                 conIDSet,
		 runtimeTy,
                 liftedTys,
                 dtyKind
                }
             )
        ) =>
        let
          val newTfunkind = 
              ref (I.TFUN_DTY 
                     {id=newId,
                      iseq=iseq,
                      longsymbol=replacePathLongsymbol (longsymbol, path),
                      formals=formals,
                      conSpec=conSpec,
                      conIDSet=conIDSet,
		      runtimeTy=runtimeTy,
                      liftedTys=liftedTys,
                      dtyKind=dtyKind
                     })
              val newTfun = I.TFUN_VAR newTfunkind
              fun isSelf (I.TFUN_VAR (ref (I.TFUN_DTY {id,...}))) = TypID.eq(id, newId)
                | isSelf _ = false
              fun replaceTfunTy ty =
                  case ty of
                    I.TYWILD => ty
                  | I.TYERROR => ty
                  | I.TYVAR tvar => ty
                  | I.TYRECORD tyLabelenvMap =>
                    I.TYRECORD (RecordLabel.Map.map replaceTfunTy tyLabelenvMap)
                  | I.TYCONSTRUCT {tfun, args} =>
                    I.TYCONSTRUCT 
                      {tfun = if isSelf tfun then newTfun else tfun,
                       args = map replaceTfunTy args}
                  | I.TYFUNM (tyList,ty) => 
                    I.TYFUNM (map replaceTfunTy tyList, 
                              replaceTfunTy ty)
                  | I.TYPOLY (tvarTvarKindList, ty) =>
                    I.TYPOLY (tvarTvarKindList, 
                              replaceTfunTy ty)
                  | I.INFERREDTY typesTy => ty
              val newConSpec = SymbolEnv.map (Option.map replaceTfunTy) conSpec
              val _ = newTfunkind := 
                      I.TFUN_DTY 
                        {id=newId,
                         iseq=iseq,
                         longsymbol=replacePathLongsymbol (longsymbol, path),
                         formals=formals,
                         conSpec=newConSpec,
                         conIDSet=conIDSet,
		         runtimeTy=runtimeTy,
                         liftedTys=liftedTys,
                         dtyKind=dtyKind
                        }
            in
              (newTfun, TypID.Map.insert(renameEnv, newId, newTfun))
        end
      | _ => (tfun, renameEnv)

  fun replacePathEnv renameEnv path (V.ENV {varE, tyE, strE=V.STR envStrkindSymbolMap}) =
      let
        val (tyE, renameEnv) = replacePathTyE renameEnv path tyE
        val (newenvStrkindSymbolMap, renameEnv) = 
            SymbolEnv.foldri
            (fn (symbol, {env, strKind}, (envStrkindSymbolMap,renameEnv)) =>
                let
                  val newPath = Symbol.prefixPath (path, symbol)
                  val (newEnv, renameEnv) = replacePathEnv renameEnv newPath env
                  val envStrkinSymbolMap =
                      SymbolEnv.insert(envStrkindSymbolMap, symbol, {env=newEnv, strKind=strKind})
                in
                  (envStrkindSymbolMap, renameEnv)
                end
            )
            (SymbolEnv.empty, renameEnv)
            envStrkindSymbolMap
      in
        (V.ENV {varE = varE, tyE = tyE, strE = V.STR envStrkindSymbolMap}, renameEnv)
      end
  and replacePathTyE renameEnv path tyE =
      SymbolEnv.foldri
        (fn (symbol, tstr, (tyE, renameEnv)) => 
            let
              val (tsrt, renameEnv) = replacePathTstr renameEnv path tstr
            in
              (SymbolEnv.insert(tyE, symbol, tstr), renameEnv)
            end)
        (SymbolEnv.empty, renameEnv)
        tyE

  and replacePathTstr renameEnv path tstr = 
      case tstr of
        V.TSTR tfun => 
        let
          val (tfun, renameEnv) = replacePathTfun renameEnv path tfun
        in
          (V.TSTR tfun, renameEnv)
        end
      | V.TSTR_DTY {tfun, varE, formals, conSpec} =>
        let
          val (tfun , renameEnv) = replacePathTfun renameEnv path tfun
        in
          (V.TSTR_DTY {tfun = tfun,
                       varE = varE,
                       formals = formals,
                       conSpec = conSpec},
           renameEnv)
        end

  fun renameLongsymbolTfunSelf renameEnv tfun =
      case tfun of
        I.TFUN_VAR (ref (I.TFUN_DTY {id=newId, ...})) =>
        (case TypID.Map.find(renameEnv, newId) of
           SOME (newTfun as I.TFUN_VAR 
                  (tfunkind as 
                     ref (I.TFUN_DTY {id,
                                      iseq,
                                      longsymbol,
                                      formals,
                                      conSpec,
                                      conIDSet,
		                      runtimeTy,
                                      liftedTys,
                                      dtyKind
                                     }
                         )
                  )
                )  => 
           let
             val newConSpec = SymbolEnv.map (Option.map (renameLongsymbolTy renameEnv)) conSpec
             val _ = tfunkind := 
                     I.TFUN_DTY 
                       {id=id,
                        iseq=iseq,
                        longsymbol=longsymbol,
                        formals=formals,
                        conSpec=newConSpec,
                        conIDSet=conIDSet,
		        runtimeTy=runtimeTy,
                        liftedTys=liftedTys,
                        dtyKind=dtyKind
                       }
           in
             newTfun
           end
         | SOME tfun => tfun
         | NONE => tfun
        )
      | _ => tfun
  and renameLongsymbolTy renameEnv ty =
      case ty of
        I.TYWILD => ty
      | I.TYERROR => ty
      | I.TYVAR tvar => ty
      | I.TYRECORD tyLabelenvMap =>
        I.TYRECORD (RecordLabel.Map.map (renameLongsymbolTy renameEnv) tyLabelenvMap)
      | I.TYCONSTRUCT {tfun, args} =>
        I.TYCONSTRUCT 
          {tfun = renameLongsymbolTfun renameEnv tfun, 
           args = map (renameLongsymbolTy renameEnv) args}
      | I.TYFUNM (tyList,ty) => 
        I.TYFUNM (map (renameLongsymbolTy renameEnv) tyList, 
                  renameLongsymbolTy renameEnv ty)
      | I.TYPOLY (tvarTvarKindList, ty) =>
        I.TYPOLY (tvarTvarKindList, 
                renameLongsymbolTy renameEnv ty)
      | I.INFERREDTY typesTy => ty

  and renameLongsymbolTfun renameEnv tfun =
      case tfun of
        I.TFUN_VAR (ref (I.TFUN_DTY {id=newId, ...})) =>
        (case TypID.Map.find(renameEnv, newId) of
           SOME tfun => tfun
         | NONE => tfun
        )
      | _ => tfun

  fun renameLongsymbolIdstatus renameEnv idstatus =
      case idstatus of
        I.IDVAR  {id, longsymbol} => idstatus
      | I.IDVAR_TYPED {id, ty, longsymbol} => idstatus
      | I.IDEXVAR {exInfo={longsymbol, version, ty}, used, internalId} => 
        I.IDEXVAR {exInfo={longsymbol=longsymbol, 
                           version=version, 
                           ty=renameLongsymbolTy renameEnv ty}, 
                   used=used, 
                   internalId=internalId}
      | I.IDEXVAR_TOBETYPED {longsymbol, id,  version} => idstatus
      | I.IDBUILTINVAR {primitive, ty} => 
        I.IDBUILTINVAR {primitive=primitive, ty=renameLongsymbolTy renameEnv ty}
      | I.IDCON {id, ty, longsymbol} =>
        I.IDCON {id=id, ty=renameLongsymbolTy renameEnv ty, longsymbol=longsymbol}
      | I.IDEXN {id, ty, longsymbol} =>
        I.IDEXN {id=id, ty=renameLongsymbolTy renameEnv ty, longsymbol=longsymbol}
      | I.IDEXNREP {id, ty, longsymbol} =>
        I.IDEXNREP {id=id, ty=renameLongsymbolTy renameEnv ty, longsymbol=longsymbol}
      | I.IDEXEXN ({longsymbol, version, ty}, boolRef)  => idstatus
      | I.IDEXEXNREP ({ty, version, longsymbol}, boolRef)  => idstatus
      | I.IDOPRIM {id, overloadDef, used, longsymbol} => idstatus
      | I.IDSPECVAR {ty, symbol} => idstatus
      | I.IDSPECEXN {ty, symbol} => idstatus
      | I.IDSPECCON {symbol} => idstatus

  fun renameLongsymbolVarE renameEnv varE =
      SymbolEnv.map (renameLongsymbolIdstatus renameEnv) varE

  fun renameLongsymbolConSpec renameEnv conSpec =
      SymbolEnv.map (fn NONE => NONE | SOME ty => SOME (renameLongsymbolTy renameEnv ty)) conSpec

  fun renameLongsymbolTstr renameEnv tstr =
      case tstr of
        V.TSTR tfun => V.TSTR (renameLongsymbolTfunSelf renameEnv tfun)
      | V.TSTR_DTY {tfun, varE, formals, conSpec} =>
        V.TSTR_DTY {tfun =  (renameLongsymbolTfunSelf renameEnv tfun),
                    varE = renameLongsymbolVarE renameEnv varE,
                    formals = formals,
                    conSpec = renameLongsymbolConSpec renameEnv conSpec}

  fun renameLongsymbolTyE renameEnv tyE =
      SymbolEnv.map (renameLongsymbolTstr renameEnv) tyE

  fun renameLomgsymbolEnv renameEnv (V.ENV {varE, tyE, strE=V.STR envSymbolMap}) =
      V.ENV {varE = renameLongsymbolVarE renameEnv varE,
             tyE = renameLongsymbolTyE renameEnv tyE,
             strE = 
             V.STR
               (SymbolEnv.map
                  (fn {env, strKind} => 
                      {env=renameLomgsymbolEnv renameEnv env, strKind=strKind})
                  envSymbolMap)
            }

  fun renameLomgsymbolTopEnv renameEnv {Env = env, FunE, SigE} =
      let
        val env = renameLomgsymbolEnv renameEnv env
      in
        {Env= env, FunE=FunE, SigE=SigE}
      end
end
