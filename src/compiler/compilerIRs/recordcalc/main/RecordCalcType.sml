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

  fun instantiateVar subst (var as {ty, ...} : R.varInfo) =
      var # {ty = TypesBasics.substBTvar subst ty}

  fun instantiateTlconst subst const =
      case const of
        R.REAL64 _ => const
      | R.REAL32 _ => const
      | R.UNIT => const
      | R.NULLPOINTER => const
      | R.NULLBOXED => const
      | R.FOREIGNSYMBOL {name, ty} =>
        R.FOREIGNSYMBOL {name = name, ty = TypesBasics.substBTvar subst ty}

  fun instantiateConst subst const =
      case const of
        R.INT _ => const
      | R.CONST const => R.CONST (instantiateTlconst subst const)
      | R.SIZE (size, ty) => R.SIZE (size, TypesBasics.substBTvar subst ty)
      | R.TAG (tag, ty) => R.TAG (tag, TypesBasics.substBTvar subst ty)

  fun instantiateValue subst value =
      case value of
        R.RCCONSTANT const =>
        R.RCCONSTANT (instantiateConst subst const)
      | R.RCVAR var =>
        R.RCVAR (instantiateVar subst var)

  fun instantiateExp subst exp =
      case exp of
        R.RCVALUE (value, loc) =>
        R.RCVALUE (instantiateValue subst value, loc)
      | R.RCSTRING (string, loc) => exp
      | R.RCEXVAR (var, loc) => exp
      | R.RCFNM {btvEnv, constraints, argVarList, bodyTy, bodyExp, loc} =>
        let
          val polyTy = T.POLYty {boundtvars = btvEnv,
                                 constraints = constraints,
                                 body = T.ERRORty (* dummy *)}
          val {boundtvars = btvEnv, constraints, ...} =
              case TypesBasics.revealTy (TypesBasics.substBTvar subst polyTy) of
                T.POLYty x => x
              | _ => raise Bug.Bug "RCFNM"
          val subst =
              BoundTypeVarID.Map.filteri
                (fn (id, _) => not (BoundTypeVarID.Map.inDomain (btvEnv, id)))
                subst
          val bodyExp = instantiateExp subst bodyExp
        in
          R.RCFNM {btvEnv = btvEnv,
                   constraints = constraints,
                   argVarList = map (instantiateVar subst) argVarList,
                   bodyTy = typeOfExp bodyExp,
                   bodyExp = bodyExp,
                   loc = loc}
        end
      | R.RCAPPM {funExp, funTy, instTyList, argExpList, loc} =>
        let
          val funExp = instantiateExp subst funExp
        in
          R.RCAPPM {funExp = funExp,
                    funTy = typeOfExp funExp,
                    instTyList = map (TypesBasics.substBTvar subst) instTyList,
                    argExpList = map (instantiateExp subst) argExpList,
                    loc = loc}
        end
      | R.RCSWITCH {exp, expTy, branches, defaultExp, resultTy, loc} =>
        let
          val exp = instantiateExp subst exp
          val defaultExp = instantiateExp subst defaultExp
        in
          R.RCSWITCH {exp = exp,
                      expTy = typeOfExp exp,
                      branches = map (fn {const, body} =>
                                         {const = const,
                                          body = instantiateExp subst body})
                                     branches,
                      defaultExp = defaultExp,
                      resultTy = typeOfExp defaultExp,
                      loc = loc}
        end
      | R.RCPRIMAPPLY {primOp, instTyList, instSizeList, instTagList,
                       argExpList, loc} =>
        R.RCPRIMAPPLY
          {primOp = primOp,
           instTyList = map (TypesBasics.substBTvar subst) instTyList,
           instSizeList = map (instantiateValue subst) instSizeList,
           instTagList = map (instantiateValue subst) instTagList,
           argExpList = map (instantiateExp subst) argExpList,
           loc = loc}
      | R.RCRECORD {fields, loc} =>
        R.RCRECORD
          {fields = RecordLabel.Map.map
                      (fn {exp, ty, size, tag} =>
                          let
                            val exp = instantiateExp subst exp
                          in
                            {exp = exp,
                             ty = typeOfExp exp,
                             size = instantiateValue subst size,
                             tag = instantiateValue subst tag}
                          end)
                      fields,
           loc = loc}
      | R.RCSELECT {label, indexExp, recordExp, recordTy, resultTy, resultSize,
                    resultTag, loc} =>
        let
          val recordExp = instantiateExp subst recordExp
        in
          R.RCSELECT
            {label = label,
             indexExp = instantiateExp subst indexExp,
             recordExp = recordExp,
             recordTy = typeOfExp recordExp,
             resultTy = TypesBasics.substBTvar subst resultTy,
             resultSize = instantiateValue subst resultSize,
             resultTag = instantiateValue subst resultTag,
             loc = loc}
        end
      | R.RCMODIFY {label, indexExp, recordExp, recordTy, elementExp, elementTy,
                    elementSize, elementTag, loc} =>
        let
          val recordExp = instantiateExp subst recordExp
          val elementExp = instantiateExp subst elementExp
        in
          R.RCMODIFY
            {label = label,
             indexExp = instantiateExp subst indexExp,
             recordExp = recordExp,
             recordTy = typeOfExp recordExp,
             elementExp = elementExp,
             elementTy = typeOfExp elementExp,
             elementSize = instantiateValue subst elementSize,
             elementTag = instantiateValue subst elementTag,
             loc = loc}
        end
      | R.RCLET {decl, body, loc} =>
        R.RCLET {decl = instantiateDecl subst decl,
                 body = instantiateExp subst body,
                 loc = loc}
      | R.RCRAISE {exp, resultTy, loc} =>
        R.RCRAISE {exp = instantiateExp subst exp,
                   resultTy = TypesBasics.substBTvar subst resultTy,
                   loc = loc}
      | R.RCHANDLE {exp, exnVar, handler, resultTy, loc} =>
        let
          val exp = instantiateExp subst exp
        in
          R.RCHANDLE {exp = exp,
                      exnVar = instantiateVar subst exnVar,
                      handler = instantiateExp subst handler,
                      resultTy = typeOfExp exp,
                      loc = loc}
        end
      | R.RCTHROW {catchLabel, argExpList, resultTy, loc} =>
        R.RCTHROW {catchLabel = catchLabel,
                   argExpList = map (instantiateExp subst) argExpList,
                   resultTy = TypesBasics.substBTvar subst resultTy,
                   loc = loc}
      | R.RCCATCH {recursive, rules, tryExp, resultTy, loc} =>
        let
          val tryExp = instantiateExp subst tryExp
        in
          R.RCCATCH
            {recursive = recursive,
             rules =
               map (fn {catchLabel, argVarList, catchExp} =>
                       {catchLabel = catchLabel,
                        argVarList = map (instantiateVar subst) argVarList,
                        catchExp = instantiateExp subst catchExp})
                   rules,
             tryExp = tryExp,
             resultTy = typeOfExp tryExp,
             loc = loc}
        end
      | R.RCFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        R.RCFOREIGNAPPLY
          {funExp = instantiateExp subst funExp,
           argExpList = map (instantiateExp subst) argExpList,
           attributes = attributes,
           resultTy = Option.map (TypesBasics.substBTvar subst) resultTy,
           loc = loc}
      | R.RCCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
        let
          val bodyExp = instantiateExp subst bodyExp
        in
          R.RCCALLBACKFN
            {attributes = attributes,
             argVarList = map (instantiateVar subst) argVarList,
             bodyExp = bodyExp,
             resultTy = case resultTy of NONE => NONE
                                       | SOME _ => SOME (typeOfExp bodyExp),
             loc = loc}
        end
      | R.RCCAST {exp, expTy, targetTy, cast, loc} =>
        let
          val exp = instantiateExp subst exp
        in
          R.RCCAST {exp = exp,
                    expTy = typeOfExp exp,
                    targetTy = TypesBasics.substBTvar subst targetTy,
                    cast = cast,
                    loc = loc}
        end
      | R.RCINDEXOF {fields, label, loc} =>
        R.RCINDEXOF
          {fields = RecordLabel.Map.map
                      (fn {ty, size} =>
                          {ty = TypesBasics.substBTvar subst ty,
                           size = instantiateValue subst size})
                      fields,
           label = label,
           loc = loc}

  and instantiateDecl subst decl =
      case decl of
        R.RCVAL {var, exp, loc} =>
        let
          val exp = instantiateExp subst exp
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
                        val exp = instantiateExp subst exp
                      in
                        {var = var # {ty = typeOfExp exp}, exp = exp}
                      end)
                  recbinds
        in
          R.RCVALREC (recbinds, loc)
        end
      | R.RCEXPORTVAR {weak, var, exp = SOME exp} =>
        let
          val exp = instantiateExp subst exp
        in
          R.RCEXPORTVAR {weak = weak,
                         var = var # {ty = typeOfExp exp},
                         exp = SOME exp}
        end
      | R.RCEXPORTVAR {weak, var, exp = NONE} => decl
      | R.RCEXTERNVAR _ => decl

end
