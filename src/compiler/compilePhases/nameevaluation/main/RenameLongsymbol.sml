structure RenameLongsymbol =
struct
  structure I = IDCalc
  structure V = NameEvalEnv
  val emptyRenameEnv = TypID.Map.empty : I.tfun TypID.Map.map

  fun replaceLongsymbolTfun renameEnv newLongsymbol tfun =
      case tfun of
        I.TFUN_VAR 
        (ref (I.TFUN_DTY 
                {id=newId, admitsEq, longsymbol, formals, conSpec,
                 conIDSet, liftedTys, dtyKind })) =>
        let
          val newTfunkind = 
              ref (I.TFUN_DTY 
                     {id=newId,
                      admitsEq=admitsEq,
                      longsymbol=newLongsymbol,
                      formals=formals,
                      conSpec=conSpec,
                      conIDSet=conIDSet,
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
                  | I.TYFREE_TYVAR tvar => ty
                  | I.TYRECORD {ifFlex, fields=tyLabelenvMap} =>
                    I.TYRECORD 
                      {ifFlex=ifFlex, 
                       fields=RecordLabel.Map.map replaceTfunTy tyLabelenvMap}
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
                         admitsEq=admitsEq,
                         longsymbol=newLongsymbol,
                         formals=formals,
                         conSpec=newConSpec,
                         conIDSet=conIDSet,
                         liftedTys=liftedTys,
                         dtyKind=dtyKind
                        }
            in
              (newTfun, TypID.Map.insert(renameEnv, newId, newTfun))
        end
      | _ => (tfun, renameEnv)


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
                {id=newId, admitsEq, longsymbol, formals, conSpec,
                 conIDSet, liftedTys, dtyKind})) =>
        let
          val newTfunkind = 
              ref (I.TFUN_DTY 
                     {id=newId,
                      admitsEq=admitsEq,
                      longsymbol=replacePathLongsymbol (longsymbol, path),
                      formals=formals,
                      conSpec=conSpec,
                      conIDSet=conIDSet,
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
                  | I.TYFREE_TYVAR tvar => ty
                  | I.TYRECORD {ifFlex, fields=tyLabelenvMap} =>
                    I.TYRECORD 
                      {ifFlex=ifFlex, 
                       fields=RecordLabel.Map.map replaceTfunTy tyLabelenvMap}
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
                         admitsEq=admitsEq,
                         longsymbol=replacePathLongsymbol (longsymbol, path),
                         formals=formals,
                         conSpec=newConSpec,
                         conIDSet=conIDSet,
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
            (fn (symbol, strEntry as {env,...}, (envStrkindSymbolMap,renameEnv)) =>
                let
                  val newPath = Symbol.prefixPath (path, symbol)
                  val (newEnv, renameEnv) = replacePathEnv renameEnv newPath env
                  val envStrkinSymbolMap =
                      SymbolEnv.insert
                        (envStrkindSymbolMap, symbol, strEntry # {env=newEnv})
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
        V.TSTR (tsr as {tfun,...}) => 
        let
          val (tfun, renameEnv) = replacePathTfun renameEnv path tfun
        in
          (V.TSTR (tsr # {tfun = tfun}), renameEnv)
        end
      | V.TSTR_DTY (tsr as {tfun, ...}) =>
        let
          val (tfun , renameEnv) = replacePathTfun renameEnv path tfun
        in
          (V.TSTR_DTY (tsr # {tfun = tfun}), renameEnv)
        end

  fun renameLongsymbolTfunSelf renameEnv tfun =
      case tfun of
        I.TFUN_VAR (ref (I.TFUN_DTY {id=newId, ...})) =>
        (case TypID.Map.find(renameEnv, newId) of
           SOME (newTfun as I.TFUN_VAR 
                  (tfunkind as 
                     ref (I.TFUN_DTY {id,
                                      admitsEq,
                                      longsymbol,
                                      formals,
                                      conSpec,
                                      conIDSet,
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
                        admitsEq=admitsEq,
                        longsymbol=longsymbol,
                        formals=formals,
                        conSpec=newConSpec,
                        conIDSet=conIDSet,
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
      | I.TYFREE_TYVAR freeTvar => ty
      | I.TYRECORD {ifFlex, fields=tyLabelenvMap} =>
        I.TYRECORD
          {ifFlex=ifFlex, 
           fields=RecordLabel.Map.map (renameLongsymbolTy renameEnv) tyLabelenvMap}
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
        I.IDVAR  {id, longsymbol,defRange} => idstatus
      | I.IDVAR_TYPED {id, ty, longsymbol,defRange} => idstatus
      | I.IDEXVAR {exInfo={used, longsymbol, version, ty}, internalId,defRange} => 
        I.IDEXVAR {exInfo={longsymbol=longsymbol, 
                           used = used,
                           version=version, 
                           ty=renameLongsymbolTy renameEnv ty}, 
                   defRange = defRange,
                   internalId=internalId}
      | I.IDEXVAR_TOBETYPED {longsymbol, id,  version, defRange} => idstatus
      | I.IDBUILTINVAR {primitive, ty, defRange} => 
        I.IDBUILTINVAR {primitive=primitive, defRange = defRange,
                        ty=renameLongsymbolTy renameEnv ty}
      | I.IDCON {id, ty, longsymbol, defRange} =>
        I.IDCON {id=id, ty=renameLongsymbolTy renameEnv ty, defRange = defRange,
                 longsymbol=longsymbol}
      | I.IDEXN {id, ty, longsymbol, defRange} =>
        I.IDEXN {id=id, ty=renameLongsymbolTy renameEnv ty, defRange = defRange,
                 longsymbol=longsymbol}
      | I.IDEXNREP {id, ty, longsymbol, defRange} =>
        I.IDEXNREP {id=id, ty=renameLongsymbolTy renameEnv ty, defRange = defRange,
                    longsymbol=longsymbol}
      | I.IDEXEXN {used, longsymbol, version, ty, defRange}  => idstatus
      | I.IDEXEXNREP {used, ty, version, longsymbol, defRange} => idstatus
      | I.IDOPRIM {id, overloadDef, used, longsymbol, defRange} => idstatus
      | I.IDSPECVAR {ty, symbol, defRange} => idstatus
      | I.IDSPECEXN {ty, symbol, defRange} => idstatus
      | I.IDSPECCON {symbol, defRange} => idstatus

  fun renameLongsymbolVarE renameEnv varE =
      SymbolEnv.map (renameLongsymbolIdstatus renameEnv) varE

  fun renameLongsymbolConSpec renameEnv conSpec =
      SymbolEnv.map (fn NONE => NONE | SOME ty => SOME (renameLongsymbolTy renameEnv ty)) conSpec

  fun renameLongsymbolTstr renameEnv tstr =
      case tstr of
        V.TSTR (tsr as {tfun,...}) => 
        V.TSTR (tsr # {tfun = renameLongsymbolTfunSelf renameEnv tfun})
      | V.TSTR_DTY {tfun, defRange, varE, formals, conSpec} =>
        V.TSTR_DTY {tfun =  (renameLongsymbolTfunSelf renameEnv tfun),
                    varE = renameLongsymbolVarE renameEnv varE,
                    formals = formals,
                    defRange = defRange,
                    conSpec = renameLongsymbolConSpec renameEnv conSpec}

  fun renameLongsymbolTyE renameEnv tyE =
      SymbolEnv.map (renameLongsymbolTstr renameEnv) tyE

  fun renameLomgsymbolEnv renameEnv (V.ENV {varE, tyE, strE=V.STR envSymbolMap}) =
      V.ENV {varE = renameLongsymbolVarE renameEnv varE,
             tyE = renameLongsymbolTyE renameEnv tyE,
             strE = 
             V.STR
               (SymbolEnv.map
                  (fn strEntry as {env,...} => 
                      strEntry # {env=renameLomgsymbolEnv renameEnv env})
                  envSymbolMap)
            }

  fun renameLomgsymbolTopEnv renameEnv {Env = env, FunE, SigE} =
      let
        val env = renameLomgsymbolEnv renameEnv env
      in
        {Env= env, FunE=FunE, SigE=SigE}
      end
end
