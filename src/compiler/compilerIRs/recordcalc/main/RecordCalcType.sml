(**
 * @copyright (C) 2024 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure RecordCalcType =
struct

  structure R = RecordCalc
  structure T = Types
  structure B = BuiltinTypes

  fun typeOfInt int =
      case int of
        R.INT8 _ => B.int8Ty
      | R.INT16 _ => B.int16Ty
      | R.INT32 _ => B.int32Ty
      | R.INT64 _ => B.int64Ty
      | R.WORD8 _ => B.word8Ty
      | R.WORD16 _ => B.word16Ty
      | R.WORD32 _ => B.word32Ty
      | R.WORD64 _ => B.word64Ty
      | R.CONTAG _ => B.contagTy
      | R.CHAR _ => B.charTy

  fun typeOfTlconst const =
      case const of
        R.REAL64 _ => B.real64Ty
      | R.REAL32 _ => B.real32Ty
      | R.UNIT => B.unitTy
      | R.NULLPOINTER => T.CONSTRUCTty {tyCon = B.ptrTyCon, args = [B.unitTy]}
      | R.NULLBOXED => B.boxedTy
      | R.FOREIGNSYMBOL {name, ty} => ty

  fun typeOfConst const =
      case const of
        R.INT int => typeOfInt int
      | R.CONST const => typeOfTlconst const
      | R.SIZE (_, ty) => T.SINGLETONty (T.SIZEty ty)
      | R.TAG (_, ty) => T.SINGLETONty (T.TAGty ty)

  fun typeOfString string =
      case string of
        R.STRING _ => B.stringTy
      | R.INTINF _ => B.intInfTy

  fun typeOfValue value =
      case value of
        R.RCCONSTANT const => typeOfConst const
      | R.RCVAR {ty, ...} => ty

  fun typeOfExp exp =
      case exp of
        R.RCVALUE (value, _) => typeOfValue value
      | R.RCSTRING (string, _) => typeOfString string
      | R.RCEXVAR (var, _) => #ty var
      | R.RCFNM {btvEnv, constraints, argVarList, bodyTy, bodyExp, loc} =>
        if BoundTypeVarID.Map.isEmpty btvEnv andalso null constraints
        then T.FUNMty (map #ty argVarList, bodyTy)
        else T.POLYty {boundtvars = btvEnv,
                       constraints = constraints,
                       body = T.FUNMty (map #ty argVarList, bodyTy)}
      | R.RCAPPM {funTy, instTyList = nil, ...} =>
        (case TypesBasics.revealTy funTy of
           T.FUNMty (_, retTy) => retTy
         | _ => raise Bug.Bug "typeOfExp: RCAPPM")
      | R.RCAPPM {funTy, instTyList as _ :: _, ...} =>
        (case TypesBasics.revealTy (TypesBasics.tpappTy (funTy, instTyList)) of
           T.FUNMty (_, retTy) => retTy
         | _ => raise Bug.Bug "typeOfExp: RCAPPM")
      | R.RCSWITCH {resultTy, ...} => resultTy
      | R.RCPRIMAPPLY {primOp = {ty, ...}, instTyList, ...} =>
        #resultTy (TypesBasics.tpappPrimTy (ty, instTyList))
      | R.RCRECORD {fields, ...} =>
        T.RECORDty (RecordLabel.Map.map #ty fields)
      | R.RCSELECT {resultTy, ...} => resultTy
      | R.RCMODIFY {recordTy, ...} => recordTy
      | R.RCLET {decl, body, loc} => typeOfExp body
      | R.RCRAISE {resultTy, ...} => resultTy
      | R.RCHANDLE {resultTy, ...} => resultTy
      | R.RCTHROW {resultTy, ...} => resultTy
      | R.RCCATCH {resultTy, ...} => resultTy
      | R.RCFOREIGNAPPLY {resultTy = SOME ty, ...} => ty
      | R.RCFOREIGNAPPLY {resultTy = NONE, ...} => B.unitTy
      | R.RCCALLBACKFN {attributes, argVarList, resultTy, ...} =>
        T.BACKENDty
          (T.FOREIGNFUNPTRty
             {argTyList = map #ty argVarList,
              varArgTyList = NONE,
              resultTy = resultTy,
              attributes = attributes})
      | R.RCCAST {targetTy, ...} => targetTy
      | R.RCINDEXOF {fields, label, ...} =>
        T.SINGLETONty
          (T.INDEXty (label, T.RECORDty (RecordLabel.Map.map #ty fields)))

  type ty_subst = Types.ty BoundTypeVarID.Map.map
  type var_subst = RecordCalc.rcvalue VarID.Map.map
  type subst = {tySubst : ty_subst, varSubst : var_subst}

  fun addBoundVar (subst as {varSubst, ...} : subst) ({id, ...} : R.varInfo) =
      if VarID.Map.inDomain (varSubst, id)
      then subst # {varSubst = #1 (VarID.Map.remove (varSubst, id))}
      else subst

  fun addBoundVars subst vars =
      foldl (fn (v, z) => addBoundVar z v) subst vars

  fun instantiateVar tySubst (var as {id, ty, ...} : R.varInfo) =
      var # {ty = TypesBasics.substBTvar tySubst ty}

  fun instantiateTlconst tySubst const =
      case const of
        R.REAL64 _ => const
      | R.REAL32 _ => const
      | R.UNIT => const
      | R.NULLPOINTER => const
      | R.NULLBOXED => const
      | R.FOREIGNSYMBOL {name, ty} =>
        R.FOREIGNSYMBOL {name = name, ty = TypesBasics.substBTvar tySubst ty}

  fun instantiateConst tySubst const =
      case const of
        R.INT _ => const
      | R.CONST const => R.CONST (instantiateTlconst tySubst const)
      | R.SIZE (size, ty) => R.SIZE (size, TypesBasics.substBTvar tySubst ty)
      | R.TAG (tag, ty) => R.TAG (tag, TypesBasics.substBTvar tySubst ty)

  fun substValue {tySubst, varSubst} value =
      case value of
        R.RCCONSTANT const =>
        R.RCCONSTANT (instantiateConst tySubst const)
      | R.RCVAR var =>
        case VarID.Map.find (varSubst, #id var) of
          SOME value => value
        | NONE => R.RCVAR (instantiateVar tySubst var)

  fun substTy ({tySubst, ...} : subst) ty =
      TypesBasics.substBTvar tySubst ty

  fun substExp subst exp =
      case exp of
        R.RCVALUE (value, loc) =>
        R.RCVALUE (substValue subst value, loc)
      | R.RCSTRING (string, loc) => exp
      | R.RCEXVAR (var, loc) => exp
      | R.RCFNM {btvEnv, constraints, argVarList, bodyTy, bodyExp, loc} =>
        let
          val polyTy = T.POLYty {boundtvars = btvEnv,
                                 constraints = constraints,
                                 body = T.ERRORty (* dummy *)}
          val {boundtvars = btvEnv, constraints, ...} =
              case TypesBasics.revealTy (substTy subst polyTy) of
                T.POLYty x => x
              | _ => raise Bug.Bug "RCFNM"
          val tySubst =
              BoundTypeVarID.Map.filteri
                (fn (id, _) => not (BoundTypeVarID.Map.inDomain (btvEnv, id)))
                (#tySubst subst)
          val subst = subst # {tySubst = tySubst}
          val subst = addBoundVars subst argVarList
          val bodyExp = substExp subst bodyExp
        in
          R.RCFNM {btvEnv = btvEnv,
                   constraints = constraints,
                   argVarList = map (instantiateVar tySubst) argVarList,
                   bodyTy = typeOfExp bodyExp,
                   bodyExp = bodyExp,
                   loc = loc}
        end
      | R.RCAPPM {funExp, funTy, instTyList, argExpList, loc} =>
        let
          val funExp = substExp subst funExp
        in
          R.RCAPPM {funExp = funExp,
                    funTy = typeOfExp funExp,
                    instTyList = map (substTy subst) instTyList,
                    argExpList = map (substExp subst) argExpList,
                    loc = loc}
        end
      | R.RCSWITCH {exp, expTy, branches, defaultExp, resultTy, loc} =>
        let
          val exp = substExp subst exp
          val defaultExp = substExp subst defaultExp
        in
          R.RCSWITCH {exp = exp,
                      expTy = typeOfExp exp,
                      branches = map (fn {const, body} =>
                                         {const = const,
                                          body = substExp subst body})
                                     branches,
                      defaultExp = defaultExp,
                      resultTy = typeOfExp defaultExp,
                      loc = loc}
        end
      | R.RCPRIMAPPLY {primOp, instTyList, instSizeList, instTagList,
                       argExpList, loc} =>
        R.RCPRIMAPPLY
          {primOp = primOp,
           instTyList = map (substTy subst) instTyList,
           instSizeList = map (substValue subst) instSizeList,
           instTagList = map (substValue subst) instTagList,
           argExpList = map (substExp subst) argExpList,
           loc = loc}
      | R.RCRECORD {fields, loc} =>
        R.RCRECORD
          {fields = RecordLabel.Map.map
                      (fn {exp, ty, size, tag} =>
                          let
                            val exp = substExp subst exp
                          in
                            {exp = exp,
                             ty = typeOfExp exp,
                             size = substValue subst size,
                             tag = substValue subst tag}
                          end)
                      fields,
           loc = loc}
      | R.RCSELECT {label, indexExp, recordExp, recordTy, resultTy, resultSize,
                    resultTag, loc} =>
        let
          val recordExp = substExp subst recordExp
        in
          R.RCSELECT
            {label = label,
             indexExp = substExp subst indexExp,
             recordExp = recordExp,
             recordTy = typeOfExp recordExp,
             resultTy = substTy subst resultTy,
             resultSize = substValue subst resultSize,
             resultTag = substValue subst resultTag,
             loc = loc}
        end
      | R.RCMODIFY {label, indexExp, recordExp, recordTy, elementExp, elementTy,
                    elementSize, elementTag, loc} =>
        let
          val recordExp = substExp subst recordExp
          val elementExp = substExp subst elementExp
        in
          R.RCMODIFY
            {label = label,
             indexExp = substExp subst indexExp,
             recordExp = recordExp,
             recordTy = typeOfExp recordExp,
             elementExp = elementExp,
             elementTy = typeOfExp elementExp,
             elementSize = substValue subst elementSize,
             elementTag = substValue subst elementTag,
             loc = loc}
        end
      | R.RCLET {decl, body, loc} =>
        R.RCLET {decl = substDecl subst decl,
                 body = substExp subst body,
                 loc = loc}
      | R.RCRAISE {exp, resultTy, loc} =>
        R.RCRAISE {exp = substExp subst exp,
                   resultTy = substTy subst resultTy,
                   loc = loc}
      | R.RCHANDLE {exp, exnVar, handler, resultTy, loc} =>
        let
          val exp = substExp subst exp
        in
          R.RCHANDLE {exp = exp,
                      exnVar = instantiateVar (#tySubst subst) exnVar,
                      handler = substExp (addBoundVar subst exnVar) handler,
                      resultTy = typeOfExp exp,
                      loc = loc}
        end
      | R.RCTHROW {catchLabel, argExpList, resultTy, loc} =>
        R.RCTHROW {catchLabel = catchLabel,
                   argExpList = map (substExp subst) argExpList,
                   resultTy = substTy subst resultTy,
                   loc = loc}
      | R.RCCATCH {recursive, rules, tryExp, resultTy, loc} =>
        let
          val {tySubst, ...} = subst
          val tryExp = substExp subst tryExp
        in
          R.RCCATCH
            {recursive = recursive,
             rules =
               map (fn {catchLabel, argVarList, catchExp} =>
                       {catchLabel = catchLabel,
                        argVarList = map (instantiateVar tySubst) argVarList,
                        catchExp = substExp (addBoundVars subst argVarList)
                                            catchExp})
                   rules,
             tryExp = tryExp,
             resultTy = typeOfExp tryExp,
             loc = loc}
        end
      | R.RCFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        R.RCFOREIGNAPPLY
          {funExp = substExp subst funExp,
           argExpList = map (substExp subst) argExpList,
           attributes = attributes,
           resultTy = Option.map (substTy subst) resultTy,
           loc = loc}
      | R.RCCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
        let
          val bodyExp = substExp (addBoundVars subst argVarList) bodyExp
        in
          R.RCCALLBACKFN
            {attributes = attributes,
             argVarList = map (instantiateVar (#tySubst subst)) argVarList,
             bodyExp = bodyExp,
             resultTy = case resultTy of NONE => NONE
                                       | SOME _ => SOME (typeOfExp bodyExp),
             loc = loc}
        end
      | R.RCCAST {exp, expTy, targetTy, cast, loc} =>
        let
          val exp = substExp subst exp
        in
          R.RCCAST {exp = exp,
                    expTy = typeOfExp exp,
                    targetTy = substTy subst targetTy,
                    cast = cast,
                    loc = loc}
        end
      | R.RCINDEXOF {fields, label, loc} =>
        R.RCINDEXOF
          {fields = RecordLabel.Map.map
                      (fn {ty, size} =>
                          {ty = substTy subst ty,
                           size = substValue subst size})
                      fields,
           label = label,
           loc = loc}

  and substDecl subst decl =
      case decl of
        R.RCVAL {var, exp, loc} =>
        let
          val exp = substExp subst exp
        in
          R.RCVAL {var = var # {ty = typeOfExp exp},
                   exp = exp,
                   loc = loc}
        end
      | R.RCVALREC (recbinds, loc) =>
        let
          val recbinds =
              map (fn {var, exp} =>
                      let
                        val exp = substExp subst exp
                      in
                        {var = var # {ty = typeOfExp exp}, exp = exp}
                      end)
                  recbinds
        in
          R.RCVALREC (recbinds, loc)
        end
      | R.RCEXPORTVAR {weak, var, exp = SOME exp} =>
        let
          val exp = substExp subst exp
        in
          R.RCEXPORTVAR {weak = weak,
                         var = var # {ty = typeOfExp exp},
                         exp = SOME exp}
        end
      | R.RCEXPORTVAR {weak, var, exp = NONE} => decl
      | R.RCEXTERNVAR _ => decl

  fun instantiateValue tySubst value =
      substValue {tySubst = tySubst, varSubst = VarID.Map.empty} value

  fun instantiateExp tySubst exp =
      substExp {tySubst = tySubst, varSubst = VarID.Map.empty} exp

end
