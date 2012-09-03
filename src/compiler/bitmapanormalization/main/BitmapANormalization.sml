(**
 * bitmap calc A-normalization.
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure BitmapANormalization : sig

  val normalize : BitmapCalc.bcdecl list -> BitmapANormal.baexp

end =
struct

  structure B = BitmapCalc
  structure A = BitmapANormal
  structure T = AnnotatedTypes

  (* In this file, we use "o" as an commutative operator.
   * Right-associative version is more efficient than left-associative
   * one because the former has more chance of tail-call optimization.
   *   ((f o g) o h) x --> (fn y => (fn x => f (g x)) (h y))
   *   (f o (g o h)) x --> (fn y => f ((fn x => g (h x)) y))
   *)
  infixr 3 o

  fun newVar ty =
      let
        val id = VarID.generate ()
      in
        {id = id, path = ["$" ^ VarID.toString id], ty = ty} : A.varInfo
      end

  fun flattenTy ty =
      case ty of
        T.MVALty tys => List.concat (map flattenTy tys)
      | _ => [ty]

  fun decomposeFunTy ty =
      case ty of
        T.FUNMty {argTyList, bodyTy, ...} => (argTyList, bodyTy)
      | _ => raise Control.Bug "decomposeFunTy"

  fun decomposeRecordTy ty =
      case ty of
        T.RECORDty {fieldTypes,...} => LabelEnv.listItemsi fieldTypes
      | _ => raise Control.Bug "decomposeRecordTy"

  type env =
      {
        used: VarID.Set.set,
        rename: VarID.id VarID.Map.map
      }

  val emptyEnv =
      {used = VarID.Set.empty, rename = VarID.Map.empty} : env

  fun normalizeBoundVar (env as {used, rename}:env)
                        (var as {id, ty, path}:B.varInfo) =
      let
        val newId =
            if VarID.Set.member (used, id) then VarID.generate () else id
        val var = {id = newId, ty = ty, path = path} : A.varInfo
        val newRename = VarID.Map.singleton (id, newId)
      in
        (newRename, var)
      end

  fun normalizeBoundVarList env nil = (VarID.Map.empty, nil)
    | normalizeBoundVarList env (var::vars) =
      let
        val (rename1, var) = normalizeBoundVar env var
        val (rename2, vars) = normalizeBoundVarList env vars
      in
        (VarID.Map.unionWith #2 (rename1, rename2), var::vars)
      end

  fun reserveNames ({used, rename}:env, newRename) =
      let
        val used = VarID.Map.foldl (fn (id, used) => VarID.Set.add (used, id))
                                   used newRename
      in
        {used = used, rename = rename} : env
      end

  fun extendRename (env, newRename) =
      let
        val {used, rename} = reserveNames (env, newRename)
      in
        {used = used, rename = VarID.Map.unionWith #2 (rename, newRename)} : env
      end

  fun normalizeVar ({rename,...}:env) ({id, ty, path}:B.varInfo) =
      let
        val id = case VarID.Map.find (rename, id) of
                   SOME id => id
                 | NONE => raise Control.Bug "normalizeVar"
      in
        {id = id, ty = ty, path = path} : A.varInfo
      end


  val unitValue = A.BACONST (A.BACONSTANT ConstantTerm.UNIT)
  val DummyValueList = [A.BACONST (A.BACONSTANT (ConstantTerm.STRING "DUMMY"))]

  val emptyExp = fn exp:A.baexp => exp

  fun makeLet (nil, nil, loc) = emptyExp
    | makeLet (var::vars, value::values, loc) =
      (fn K => A.BAVAL {boundVar = var, boundExp = A.BAVALUE value,
                        nextExp = K, loc = loc})
      o makeLet (vars, values, loc)
    | makeLet _ = raise Control.Bug "makeLet"

  datatype pos = MIDDLE | TAIL
  datatype context =
      BIND of {pos: pos, vars: A.varInfo list}
    | TEMP of A.ty

  type cont = (A.baexp -> A.baexp) * A.bavalue list

  fun bindVars context =
      case context of
        BIND {vars,...} => vars
      | TEMP ty => map newVar (flattenTy ty)

  fun bindVar context =
      case bindVars context of
        [var] => var
      | _ => raise Control.Bug "bindVar"

  fun TEMPtoBIND context =
      case context of
        BIND bind => bind
      | TEMP ty => {pos = MIDDLE, vars = bindVars context}

  fun nestedMultiBind pos (nil, nil) = nil
    | nestedMultiBind pos (vars, ty::tys) =
      let
        val n = length (flattenTy ty)
        val (h, t) = (List.take (vars, n), List.drop (vars, n))
                     handle Subscript => raise Control.Bug "nestedMultiBind"
      in
        BIND {pos = pos, vars = h} :: nestedMultiBind pos (t, tys)
      end
    | nestedMultiBind pos _ = raise Control.Bug "nestedMultiBind"

  fun returnValues context (values, loc) =
      case context of
        BIND {vars,...} => (makeLet (vars, values, loc), map A.BAVAR vars)
      | TEMP _ => (emptyExp, values) : cont

  fun Val context (baprim, loc) =
      let
        val var = bindVar context
      in
        (fn K => A.BAVAL {boundVar = var, boundExp = baprim,
                          nextExp = K, loc = loc},
         [A.BAVAR var]) : cont
      end

  fun Call context (bacall, loc) =
      let
        val vars = bindVars context
      in
        (fn K => A.BACALL {resultVars = vars, callExp = bacall,
                           nextExp = K, loc = loc},
         map A.BAVAR vars) : cont
      end

  fun normalizeList f nil = (emptyExp, nil)
    | normalizeList f (elem::elems) =
      let
        val (top1, elem) = f elem
        val (top2, elems) = normalizeList f elems
      in
        (top1 o top2, elem::elems)
      end

  fun normalizeArg env ty bcexp =
      case normalizeExp env (TEMP ty) bcexp of
        (ret1, [value]) => (ret1, value)
      | _ => raise Control.Bug "normalizeArg"

  and normalizeArgList env tys exps =
      normalizeList
        (fn (ty, exp) => normalizeArg env ty exp)
        (ListPair.zipEq (tys, exps))

  and normalizeExp env context bcexp =
      case bcexp of
        B.BCFOREIGNAPPLY {funExp, foreignFunTy as {argTyList, ...},
                          argExpList, loc} =>
        let
          val (ret1, funExp) = normalizeArg env T.foreignfunty funExp
          val (ret2, argExpList) = normalizeArgList env argTyList argExpList
          val (ret3, results) =
              Call context (A.BAFOREIGNAPPLY {funExp = funExp,
                                              foreignFunTy = foreignFunTy,
                                              argExpList = argExpList},
                            loc)
        in
          (ret1 o ret2 o ret3, results)
        end
      | B.BCCONSTANT {value, loc} =>
        let
          val value = A.BACONST (A.BACONSTANT value)
        in
          returnValues context ([value], loc)
        end
      | B.BCGLOBALSYMBOL {name, kind, ty, loc} =>
        let
          val const = A.BAGLOBALSYMBOL {name = name, kind = kind, ty = ty}
        in
          returnValues context ([A.BACONST const], loc)
        end
      | B.BCVAR {varInfo, loc} =>
        let
          val varInfo = normalizeVar env varInfo
        in
          returnValues context ([A.BAVAR varInfo], loc)
        end
      | B.BCEXVAR {exVarInfo, varSize, loc} =>
        let
          val varSizeTy = T.SINGLETONty (T.SIZEty (#ty exVarInfo))
          val (ret1, varSize) = normalizeArg env varSizeTy varSize
          val (ret2, results) =
              Val context (A.BAEXVAR {exVarInfo = exVarInfo,
                                      varSize = varSize},
                           loc)
        in
          (ret1 o ret2, results)
        end
(*
      | B.BCGETFIELD {arrayExp, indexExp, elementTy, elementSize, loc} =>
        let
          val arrayTy = T.arrayty elementTy
          val indexTy = T.intty
          val elementSizeTy = T.SINGLETONty (T.SIZEty elementTy)
          val (ret1, arrayExp) = normalizeArg env arrayTy arrayExp
          val (ret2, indexExp) = normalizeArg env indexTy indexExp
          val (ret3, elementSize) = normalizeArg env elementSizeTy elementSize
          val (ret4, results) =
              Val context (A.BAGETFIELD {arrayExp = arrayExp,
                                         indexExp = indexExp,
                                         elementTy = elementTy,
                                         elementSize = elementSize},
                           loc)
        in
          (ret1 o ret2 o ret3 o ret4, results)
        end
      | B.BCSETFIELD {valueExp, arrayExp, indexExp, elementTy, elementTag,
                      elementSize, loc} =>
        let
          val valueTy = elementTy
          val arrayTy = T.arrayty elementTy
          val indexTy = T.intty
          val elementTagTy = T.SINGLETONty (T.TAGty elementTy)
          val elementSizeTy = T.SINGLETONty (T.SIZEty elementTy)
          val (ret1, valueExp) = normalizeArg env valueTy valueExp
          val (ret2, arrayExp) = normalizeArg env arrayTy arrayExp
          val (ret3, indexExp) = normalizeArg env indexTy indexExp
          val (ret4, elementTag) = normalizeArg env elementTagTy elementTag
          val (ret5, elementSize) = normalizeArg env elementSizeTy elementSize
          val (ret6, results) =
              Statement context (A.BASETFIELD {valueExp = valueExp,
                                               arrayExp = arrayExp,
                                               indexExp = indexExp,
                                               elementTy = elementTy,
                                               elementTag = elementTag,
                                               elementSize = elementSize},
                                 loc)
        in
          (ret1 o ret2 o ret3 o ret4 o ret5 o ret6, results)
        end
      | B.BCSETTAIL {consExp, newTailExp, tailLabel, listTy, consRecordTy,
                     listTag, listSize, tailLabelIndex, loc} =>
        let
          val consTy = consRecordTy
          val newTailTy = listTy
          val listTagTy = T.SINGLETONty (T.TAGty listTy)
          val listSizeTy = T.SINGLETONty (T.SIZEty listTy)
          val tailLabelIndexTy =
              T.SINGLETONty (T.INDEXty (tailLabel, consRecordTy))
          val (ret1, consExp) = normalizeArg env consTy consExp
          val (ret2, newTailExp) = normalizeArg env newTailTy newTailExp
          val (ret3, listTag) = normalizeArg env listTagTy listTag
          val (ret4, listSize) = normalizeArg env listTagTy listSize
          val (ret5, tailLabelIndex) =
              normalizeArg env tailLabelIndexTy tailLabelIndex
          val (ret6, results) =
              Statement context (A.BASETTAIL {consExp = consExp,
                                              newTailExp = newTailExp,
                                              tailLabel = tailLabel,
                                              listTy = listTy,
                                              consRecordTy = consRecordTy,
                                              listTag = listTag,
                                              listSize = listSize,
                                              tailLabelIndex = tailLabelIndex},
                                 loc)
        in
          (ret1 o ret2 o ret3 o ret4 o ret5 o ret6, results)
        end
      | B.BCARRAY {sizeExp, initialValue, elementTy, elementTag, elementSize,
                   isMutable, loc} =>
        let
          val sizeTy = T.intty
          val initialValueTy = elementTy
          val elementTagTy = T.SINGLETONty (T.TAGty elementTy)
          val elementSizeTy = T.SINGLETONty (T.SIZEty elementTy)
          val (ret1, sizeExp) = normalizeArg env sizeTy sizeExp
          val (ret2, initialValue) =
              normalizeArg env initialValueTy initialValue
          val (ret3, elementTag) = normalizeArg env elementTagTy elementTag
          val (ret4, elementSize) = normalizeArg env elementSizeTy elementSize
          val (ret5, results) =
              Val context (A.BAARRAY {sizeExp = sizeExp,
                                      initialValue = initialValue,
                                      elementTy = elementTy,
                                      elementTag = elementTag,
                                      elementSize = elementSize,
                                      isMutable = isMutable},
                           loc)
        in
          (ret1 o ret2 o ret3 o ret4 o ret5, results)
        end
      | B.BCCOPYARRAY {srcExp, srcIndexExp, dstExp, dstIndexExp, lengthExp,
                       elementTy, elementTag, elementSize, loc} =>
        let
          val srcTy = T.arrayty elementTy
          val srcIndexTy = T.intty
          val dstTy = srcTy
          val dstIndexTy = T.intty
          val lengthTy = T.intty
          val elementTagTy = T.SINGLETONty (T.TAGty elementTy)
          val elementSizeTy = T.SINGLETONty (T.SIZEty elementTy)
          val (ret1, srcExp) = normalizeArg env srcTy srcExp
          val (ret2, srcIndexExp) = normalizeArg env srcIndexTy srcIndexExp
          val (ret3, dstExp) = normalizeArg env dstTy dstExp
          val (ret4, dstIndexExp) = normalizeArg env dstIndexTy dstIndexExp
          val (ret5, lengthExp) = normalizeArg env lengthTy lengthExp
          val (ret6, elementTag) = normalizeArg env elementTagTy elementTag
          val (ret7, elementSize) = normalizeArg env elementSizeTy elementSize
          val (ret8, results) =
              Statement context (A.BACOPYARRAY {srcExp = srcExp,
                                                srcIndexExp = srcIndexExp,
                                                dstExp = dstExp,
                                                dstIndexExp = dstIndexExp,
                                                lengthExp = lengthExp,
                                                elementTy = elementTy,
                                                elementTag = elementTag,
                                                elementSize = elementSize},
                                 loc)
        in
          (ret1 o ret2 o ret3 o ret4 o ret5 o ret6 o ret7 o ret8, results)
        end
*)
      | B.BCPRIMAPPLY {primInfo, argExpList, instTyList, instTagList,
                       instSizeList, loc} =>
        let
          val funTy = AnnotatedTypesUtils.tpappTy (#ty primInfo, instTyList)
          val (argTyList, bodyTy) = decomposeFunTy funTy
          val instTagTyList =
              map (fn ty => T.SINGLETONty (T.TAGty ty)) instTyList
          val instSizeTyList =
              map (fn ty => T.SINGLETONty (T.SIZEty ty)) instTyList
          val (ret1, argExpList) = normalizeArgList env argTyList argExpList
          val (ret2, instTagList) =
              normalizeArgList env instTagTyList instTagList
          val (ret3, instSizeList) =
              normalizeArgList env instSizeTyList instSizeList
          val (ret4, results) =
              Val context (A.BAPRIMAPPLY {primInfo = primInfo,
                                          argExpList = argExpList,
                                          instTyList = instTyList,
                                          instTagList = instTagList,
                                          instSizeList = instSizeList},
                           loc)
        in
          (ret1 o ret2 o ret3 o ret4, results)
        end
      | B.BCAPPM {funExp, funTy, argExpList, loc} =>
        let
          val (argTyList, bodyTy) = decomposeFunTy funTy
          val (ret1, funExp) = normalizeArg env funTy funExp
          val (ret2, argExpList) = normalizeArgList env argTyList argExpList
          val (ret3, results) =
              case context of
                BIND {pos=TAIL,...} =>
                (fn K => A.BATAILAPPM {funExp = funExp,
                                       funTy = funTy,
                                       argExpList = argExpList,
                                       loc = loc},
                 DummyValueList)
              | _ =>
                Call context (A.BAAPPM {funExp = funExp,
                                        funTy = funTy,
                                        argExpList = argExpList},
                              loc)
        in
          (ret1 o ret2 o ret3, results)
        end
      | B.BCLET {localDeclList, mainExp, loc} =>
        let
          val (ret1, env) = normalizeDeclList env localDeclList
          val (ret2, results) = normalizeExp env context mainExp
        in
          (ret1 o ret2, results)
        end
      | B.BCMVALUES {expList, tyList, loc} =>
        let
          val contexts =
              case context of
                BIND {pos, vars} => nestedMultiBind pos (vars, tyList)
              | TEMP _ => map TEMP tyList
          val (ret1, values) =
              normalizeList
                (fn (context, exp) => normalizeExp env context exp)
                (ListPair.zipEq (contexts, expList))
        in
          (ret1, List.concat values)
        end
      | B.BCRECORD {fieldList, recordTy, annotation, clearPad,
                    isMutable, totalSizeExp, bitmapExpList, loc} =>
        let
          val (ret1, fieldList) =
              normalizeList
                (fn {fieldExp, fieldLabel, fieldTy, fieldSize, fieldIndex} =>
                    let
                      val fieldIndexTy =
                          T.SINGLETONty (T.INDEXty (fieldLabel, recordTy))
                      val fieldSizeTy =
                          T.SINGLETONty (T.SIZEty fieldTy)
                      val (ret1, fieldExp) = normalizeArg env fieldTy fieldExp
                      val (ret2, fieldSize) =
                          normalizeArg env fieldSizeTy fieldSize
                      val (ret3, fieldIndex) =
                          normalizeArg env fieldIndexTy fieldIndex
                    in
                      (ret1 o ret2 o ret3,
                       {fieldExp = fieldExp,
                        fieldLabel = fieldLabel,
                        fieldTy = fieldTy,
                        fieldSize = fieldSize,
                        fieldIndex = fieldIndex})
                    end)
                fieldList
          val totalSizeTy = T.SINGLETONty (T.RECORDSIZEty recordTy)
          val bitmapTyList =
              List.tabulate
                (length bitmapExpList,
                 fn i => T.SINGLETONty (T.RECORDBITMAPty (i, recordTy)))
          val (ret2, totalSizeExp) = normalizeArg env totalSizeTy totalSizeExp
          val (ret3, bitmapExpList) =
              normalizeArgList env bitmapTyList bitmapExpList
          val (ret4, results) =
              Val context (A.BARECORD {fieldList = fieldList,
                                       recordTy = recordTy,
                                       annotation = annotation,
                                       isMutable = isMutable,
                                       clearPad = clearPad,
                                       totalSizeExp = totalSizeExp,
                                       bitmapExpList = bitmapExpList},
                           loc)
        in
          (ret1 o ret2 o ret3 o ret4, results)
        end
      | B.BCSELECT {recordExp, indexExp, label, recordTy, resultTy, resultSize,
                    loc} =>
        let
          val indexTy = T.SINGLETONty (T.INDEXty (label, recordTy))
          val resultSizeTy = T.SINGLETONty (T.SIZEty resultTy)
          val (ret1, recordExp) = normalizeArg env recordTy recordExp
          val (ret2, indexExp) = normalizeArg env indexTy indexExp
          val (ret3, resultSize) = normalizeArg env resultSizeTy resultSize
          val (ret4, results) =
              Val context (A.BASELECT {recordExp = recordExp,
                                       indexExp = indexExp,
                                       label = label,
                                       recordTy = recordTy,
                                       resultTy = resultTy,
                                       resultSize = resultSize},
                           loc)
        in
          (ret1 o ret2 o ret3 o ret4, results)
        end
      | B.BCMODIFY {recordExp, recordTy, indexExp, label, valueExp,
                    valueTy, valueTag, valueSize, loc} =>
        let
          val indexTy = T.SINGLETONty (T.INDEXty (label, recordTy))
          val valueTagTy = T.SINGLETONty (T.TAGty valueTy)
          val valueSizeTy = T.SINGLETONty (T.SIZEty valueTy)
          val (ret1, recordExp) = normalizeArg env recordTy recordExp
          val (ret2, indexExp) = normalizeArg env indexTy indexExp
          val (ret3, valueExp) = normalizeArg env valueTy valueExp
          val (ret4, valueTag) = normalizeArg env valueTagTy valueTag
          val (ret5, valueSize) = normalizeArg env valueSizeTy valueSize
          val (ret6, results) =
              Val context (A.BAMODIFY {recordExp = recordExp,
                                       recordTy = recordTy,
                                       indexExp = indexExp,
                                       label = label,
                                       valueExp = valueExp,
                                       valueTy = valueTy,
                                       valueTag = valueTag,
                                       valueSize = valueSize},
                           loc)
        in
          (ret1 o ret2 o ret3 o ret4 o ret5 o ret6, results)
        end
      | B.BCRAISE {argExp, resultTy, loc} =>
        let
          val argExpTy = T.exnty
          val (ret1, argExp) = normalizeArg env argExpTy argExp
        in
          (ret1 o (fn K => A.BARAISE {argExp = argExp, loc = loc}),
           DummyValueList)
        end
      | B.BCEXPORTCALLBACK {funExp = B.BCFNM func, foreignFunTy, loc} =>
        let
          (* callback function must have a toplevel exception handler. *)
          val exnVar = newVar T.exnty
          val bodyExp =
              B.BCHANDLE
                {tryExp = #bodyExp func,
                 exnVar = exnVar,
                 handlerExp =
                   B.BCRAISE {argExp = B.BCVAR {varInfo=exnVar, loc=loc},
                              resultTy = T.exnty, (* dummy *)
                              loc = loc},
                 loc = loc}
          val func = {argVarList = #argVarList func,
                      funTy = #funTy func,
                      bodyExp = bodyExp,
                      annotation = #annotation func,
                      closureLayout = #closureLayout func,
                      loc = loc}
          val func = normalizeFunction env func
          val var = bindVar context
        in
          (fn K => A.BACALLBACKFNM {boundVar = var,
                                    foreignFunTy = foreignFunTy,
                                    function = func,
                                    nextExp = K},
           [A.BAVAR var])
        end
      | B.BCEXPORTCALLBACK _ =>
        raise Control.Bug "normalizeExp: BCEXPORTCALLBACK"
      | B.BCFNM (func as {loc,...}) =>
        let
          val func = normalizeFunction env func
          val var = bindVar context
        in
          (fn K => A.BAFNM {boundVar = var,
                            btvEnv = BoundTypeVarID.Map.empty,
                            function = func,
                            nextExp = K},
           [A.BAVAR var])
        end
      | B.BCPOLY {btvEnv, expTyWithoutTAbs, exp = B.BCFNM func, loc} =>
        let
          val func = normalizeFunction env func
          val var = bindVar context
        in
          (fn K => A.BAFNM {boundVar = var,
                            btvEnv = btvEnv,
                            function = func,
                            nextExp = K},
           [A.BAVAR var])
        end
      | B.BCPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        let
          val vars = map newVar (flattenTy expTyWithoutTAbs)
          val (exp, _) = normalizeExp env (BIND {pos=TAIL, vars=vars}) exp
          val exp = exp (A.BAMERGE vars)
          val vars = bindVars context
        in
          (fn K => A.BAPOLY {resultVars = vars,
                             btvEnv = btvEnv,
                             expTyWithoutTAbs = expTyWithoutTAbs,
                             exp = exp,
                             nextExp = K,
                             loc = loc},
           map A.BAVAR vars)
        end
      | B.BCTAPP {exp, expTy, instTyList, loc} =>
        let
          val (ret1, exp) = normalizeArg env expTy exp
          val value = A.BATAPP {exp = exp,
                                expTy = expTy,
                                instTyList = instTyList}
          val (ret2, results) = returnValues context ([value], loc)
        in
          (ret1 o ret2, results)
        end
      | B.BCCAST {exp, expTy, targetTy, loc} =>
        let
          val (ret1, exp) = normalizeArg env expTy exp
          val value = A.BACAST {exp = exp,
                                expTy = expTy,
                                targetTy = targetTy}
          val (ret2, results) = returnValues context ([value], loc)
        in
          (ret1 o ret2, results)
        end
      | B.BCHANDLE {tryExp, exnVar, handlerExp, loc} =>
        let
          val {vars,...} = TEMPtoBIND context
          val bind = {pos = MIDDLE, vars = vars}
          val (tryExp, _) = normalizeExp env (BIND bind) tryExp
          val tryExp = tryExp (A.BAMERGE vars)
          val (rename, exnVar) = normalizeBoundVar env exnVar
          val handlerEnv = extendRename (env, rename)
          val (handlerExp, _) = normalizeExp handlerEnv (BIND bind) handlerExp
          val handlerExp = handlerExp (A.BAMERGE vars)
        in
          (fn K => A.BAHANDLE {resultVars = vars,
                               tryExp = tryExp,
                               exnVar = exnVar,
                               handlerExp = handlerExp,
                               nextExp = K,
                               loc = loc},
           map A.BAVAR vars)
        end
      | B.BCSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        let
          val bind as {pos, vars} = TEMPtoBIND context
          val (ret1, switchExp) = normalizeArg env expTy switchExp
          val branches =
              map (fn {constant, branchExp} =>
                      let
                        val (branch, _) = normalizeExp env (BIND bind) branchExp
                      in
                        {constant = constant, branch = branch}
                      end)
                  branches
          val branches =
              fn K => map (fn {constant, branch} =>
                              {constant = constant, branchExp = branch K})
                          branches
          val (defaultExp, _) = normalizeExp env (BIND bind) defaultExp
          val ret2 =
              case pos of
                TAIL =>
                (fn K => A.BATAILSWITCH {switchExp = switchExp,
                                         expTy = expTy,
                                         branches = branches K,
                                         defaultExp = defaultExp K,
                                         loc = loc})
              | MIDDLE =>
                let
                  val merge = A.BAMERGE vars
                  val branches = branches merge
                  val defaultExp = defaultExp merge
                in
                  fn K => A.BASWITCH {resultVars = vars,
                                      switch = {switchExp = switchExp,
                                                expTy = expTy,
                                                branches = branches,
                                                defaultExp = defaultExp,
                                                loc = loc},
                                      nextExp = K}
                end
        in
          (ret1 o ret2, map A.BAVAR vars)
        end

  and normalizeFunction env {argVarList, funTy, bodyExp, annotation,
                             closureLayout, loc} =
      let
        val (rename, argVarList) = normalizeBoundVarList env argVarList
        val env = extendRename (env, rename)
        val (argTyList, bodyTy) = decomposeFunTy funTy
        val vars = map newVar (flattenTy bodyTy)
        val (bodyExp, _) = normalizeExp env (BIND {pos=TAIL,vars=vars}) bodyExp
        val bodyExp = bodyExp (A.BARETURN {resultVars = vars,
                                           funTy = funTy,
                                           loc = loc})
      in
        {argVarList = argVarList,
         funTy = funTy,
         bodyExp = bodyExp,
         annotation = annotation,
         closureLayout = closureLayout,
         loc = loc} : A.function
      end

  and normalizeDeclList env decls =
      foldl (fn (decl, (top1, env)) =>
                let
                  val (top2, env) = normalizeDecl env decl
                in
                  (top1 o top2, env)
                end)
            (emptyExp, env)
            decls

  and normalizeDecl env bcdecl =
      case bcdecl of
        B.BCVAL {boundVars, boundExp, loc} =>
        let
          (* decide varId before normalizing boundExp. *)
          val (rename, boundVars) = normalizeBoundVarList env boundVars
          val nestEnv = reserveNames (env, rename)
          val context = BIND {pos=MIDDLE, vars=boundVars}
          val (boundExp, _) = normalizeExp nestEnv context boundExp
          val env = extendRename (env, rename)
        in
          (boundExp, env)
        end
      | B.BCEXPORTVAR {varInfo as {ty,...}, varSize, varTag, loc} =>
        let
          val varSizeTy = T.SINGLETONty (T.SIZEty ty)
          val varTagTy = T.SINGLETONty (T.TAGty ty)
          val varInfo = normalizeVar env varInfo
          val (ret1, varSize) = normalizeArg env varSizeTy varSize
          val (ret2, varTag) = normalizeArg env varTagTy varTag
          val ret3 =
              fn K => A.BAEXPORTVAR {varInfo = varInfo,
                                     varSize = varSize,
                                     varTag = varTag,
                                     nextExp = K,
                                     loc = loc}
        in
          (ret1 o ret2 o ret3, env)
        end
      | B.BCEXTERNVAR {exVarInfo, loc} =>
        (fn K => A.BAEXTERNVAR {exVarInfo = exVarInfo,
                                nextExp = K,
                                loc = loc},
         env)
      | B.BCVALREC {recbindList, loc} =>
        let
          val boundVars = map #boundVar recbindList
          val (rename, boundVars) = normalizeBoundVarList env boundVars
          val env = extendRename (env, rename)
          val recbindList =
              ListPair.mapEq
                (fn (newVar, {boundVar, boundExp = B.BCFNM func}) =>
                    {boundVar = newVar,
                     function = normalizeFunction env func}
                  | _ => raise Control.Bug "normalizeDecl: BCVALREC")
                (boundVars, recbindList)
        in
          (fn K => A.BAVALREC {recbindList = recbindList, nextExp = K,
                               loc = loc},
           env)
        end

  fun normalize decls =
      let
        val (topExp, _) = normalizeDeclList emptyEnv decls
        val exnVar = newVar T.exnty
        val toplevelFunTy =
            AnnotatedTypesUtils.makeClosureFunTy (nil, T.MVALty nil)
      in
        (* toplevel code must be enclosed in a exception handler. *)
        A.BAHANDLE
          {resultVars = [],
           tryExp = topExp (A.BAMERGE nil),
           exnVar = exnVar,
           handlerExp = A.BARAISE {argExp = A.BAVAR exnVar,
                                   loc = Loc.noloc},
           nextExp = A.BARETURN {resultVars = nil,
                                 funTy = toplevelFunTy,
                                 loc = Loc.noloc},
           loc = Loc.noloc}
      end

end
