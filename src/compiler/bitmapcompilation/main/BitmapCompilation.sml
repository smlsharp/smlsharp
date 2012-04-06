(**
 * record layout and bitmap compilation
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 * @author Huu-Duc Nguyen
 * @author Atsushi Ohori
 *)
structure BitmapCompilation : sig

  val compile : MultipleValueCalc.mvdecl list -> BitmapCalc.bcdecl list

end =
struct

  structure M = MultipleValueCalc
  structure B = BitmapCalc
  structure T = AnnotatedTypes

  fun newVar ty =
      let
        val id = VarID.generate ()
      in
        {id = id, path = ["$" ^ VarID.toString id], ty = ty} : B.varInfo
      end

  fun mapi f l =
      let
        fun loop f i nil = nil
          | loop f i (h::t) = f (i,h) :: loop f (i+1) t
      in
        loop f 0 l
      end

  fun valueToBcexp (value, sty, loc) =
      case value of
        RecordLayout.CONST n =>
        let
          val const = ConstantTerm.WORD (Word32.fromLarge n)
          val exp = B.BCCONSTANT {value = const, loc = loc}
        in
          case sty of
            NONE => exp
          | SOME sty =>
            B.BCCAST {exp = exp, expTy = T.wordty,
                      targetTy = T.SINGLETONty sty, loc = loc}
        end
      | RecordLayout.VAR (v, castTy) =>
        let
          val castTy =
              case (castTy, sty) of
                (_, SOME x) => SOME (T.SINGLETONty x)
              | (SOME x, NONE) => SOME x
              | (NONE, NONE) => NONE
          val exp = B.BCVAR {varInfo = v, loc = loc}
        in
          case castTy of
            NONE => exp
          | SOME ty =>
            B.BCCAST {exp = exp, expTy = #ty v, targetTy = ty, loc = loc}
        end

  fun toBcdecl loc decl =
      case decl of
        RecordLayout.MOVE (var, value) =>
        B.BCVAL {boundVars = [var],
                 boundExp = valueToBcexp (value, NONE, loc),
                 loc = loc}
      | RecordLayout.PRIMAPPLY {boundVar, primInfo, argList} =>
        let
          val argExpList = map (fn v => valueToBcexp (v, NONE, loc)) argList
        in
          B.BCVAL {boundVars = [boundVar],
                   boundExp = B.BCPRIMAPPLY {primInfo = primInfo,
                                             argExpList = argExpList,
                                             instTyList = nil,
                                             instTagList = nil,
                                             instSizeList = nil,
                                             loc = loc},
                   loc = loc}
        end

  fun Let (nil, mainExp, loc) = mainExp
    | Let (decls, mainExp, loc) =
      B.BCLET {localDeclList = decls, mainExp = mainExp, loc = loc}

  fun findTag (env, ty) =
      SingletonTyEnv.findTag env ty

  fun findSize (env, ty) =
      SingletonTyEnv.findSize env ty

  fun findTagExp (env, ty, loc) =
      case valueToBcexp (findTag (env, ty), NONE, loc) of
        exp as B.BCVAR _ => exp
      | exp => B.BCCAST {exp = exp, expTy = T.wordty,
                         targetTy = T.SINGLETONty (T.TAGty ty),
                         loc = loc}

  fun findSizeExp (env, ty, loc) =
      case valueToBcexp (findSize (env, ty), NONE, loc) of
        exp as B.BCVAR _ => exp
      | exp => B.BCCAST {exp = exp, expTy = T.wordty,
                         targetTy = T.SINGLETONty (T.SIZEty ty),
                         loc = loc}

  fun recordFieldTys env recordTy =
      let
        val (needAlign, fields) =
            case recordTy of
              T.RECORDty {fieldTypes, annotation = ref {align,...}} =>
              (align, LabelEnv.listItemsi fieldTypes)
            | _ => raise Control.Bug "recordFieldTys"
        fun sizeOf ty = findSize (env, ty)
(*
2011-12-27 Ohori.
The noAlign (passed as needAlign in the above) predicate set by StaticAnalysis 
should have some special semantics and no for this purpose. So we should ignore this.
In neare future we shall review and rewrite StaticAnalysis.

        fun sizeOf ty = 
            if needAlign
            then findSize (env, ty)
            else RecordLayout.const TypeLayout.maxSize
*)
      in
        map (fn (label, ty) =>
                {label = label,
                 ty = ty,
                 size = sizeOf ty,
                 tag = findTag (env, ty)})
            fields
      end

  fun closureLayout () =
      let
        val entryTy = RuntimeTypes.CODEPOINTERty
        val envTy = RuntimeTypes.BOXEDty
        val entrySize = RecordLayout.const (TypeLayout.sizeOf entryTy)
        val entryTag = RecordLayout.const (TypeLayout.tagOf entryTy)
        val envSize = RecordLayout.const (TypeLayout.sizeOf envTy)
        val envTag = RecordLayout.const (TypeLayout.tagOf envTy)
        val fieldInfo = [{size = entrySize, tag = entryTag},
                         {size = envSize, tag = envTag}]
        val (calc, {totalSize, fieldIndexes, bitmap}) =
            RecordLayout.computeRecord fieldInfo
        val _ = case calc of
                  nil => () | _ => raise Control.Bug "closureLayout"
        val totalSize =
            case RecordLayout.toLargeWord totalSize of
              SOME x => LargeWord.toInt x
            | _ => raise Control.Bug "closureLayout: totalSize"
        val (entryIndex, envIndex) =
            case map RecordLayout.toLargeWord fieldIndexes of
              [SOME x, SOME y] => (LargeWord.toInt x, LargeWord.toInt y)
            | _ => raise Control.Bug "closureLayout: index"
        val bitmap =
            case map RecordLayout.toLargeWord bitmap of
              [SOME x] => Word.fromLarge x
            | _ => raise Control.Bug "closureLayout: bitmap"
      in
        {
          recordSize = totalSize,
          recordBitmap = bitmap,
          codeAddressIndex = entryIndex,
          closureEnvIndex = envIndex
        } : B.closureLayout
      end

  fun compileExp env mvexp =
      case mvexp of
        M.MVFOREIGNAPPLY {funExp, foreignFunTy, argExpList, loc} =>
        let
          val funExp = compileExp env funExp
          val argExpList = map (compileExp env) argExpList
        in
          B.BCFOREIGNAPPLY {funExp = funExp,
                            foreignFunTy = foreignFunTy,
                            argExpList = argExpList,
                            loc = loc}
        end
      | M.MVEXPORTCALLBACK {funExp, foreignFunTy, loc} =>
        let
          val funExp = compileExp env funExp
        in
          B.BCEXPORTCALLBACK {funExp = funExp,
                              foreignFunTy = foreignFunTy,
                              loc = loc}
        end
      | M.MVTAGOF {ty, loc} => findTagExp (env, ty, loc)
      | M.MVSIZEOF {ty, loc} => findSizeExp (env, ty, loc)
      | M.MVINDEXOF {label, recordTy, loc} =>
        let
          val fields = recordFieldTys env recordTy
          fun find (fields, nil) = raise Control.Bug "compileExp: MVINDEXOF"
            | find (fields, {label=l,size,tag,ty}::t) =
              if l = label then (rev fields, {size=size})
              else find ({size=size}::fields, t)
          val (fields, lastField) = find (nil, fields)
          val (decls, index) = RecordLayout.computeIndex (fields, lastField)
          val indexExp =
              valueToBcexp (index, SOME (T.INDEXty (label, recordTy)), loc)
        in
          Let (map (toBcdecl loc) decls, indexExp, loc)
        end
      | M.MVCONSTANT {value, loc} =>
        B.BCCONSTANT {value = value, loc = loc}
      | M.MVGLOBALSYMBOL {name, kind, ty, loc} =>
        B.BCGLOBALSYMBOL {name = name, kind = kind, ty = ty, loc = loc}
      | M.MVVAR {varInfo, loc} => B.BCVAR {varInfo = varInfo, loc = loc}
      | M.MVEXVAR {exVarInfo, loc} =>
        B.BCEXVAR {exVarInfo = exVarInfo,
                   varSize = findSizeExp (env, #ty exVarInfo, loc),
                   loc=loc}
(*
      | M.MVGETFIELD {arrayExp, indexExp, elementTy, loc} =>
        let
          val arrayExp = compileExp env arrayExp
          val indexExp = compileExp env indexExp
          val elementSize = findSizeExp (env, elementTy, loc)
        in
          B.BCGETFIELD {arrayExp = arrayExp,
                        indexExp = indexExp,
                        elementTy = elementTy,
                        elementSize = elementSize,
                        loc = loc}
        end
      | M.MVSETFIELD {valueExp, arrayExp, indexExp, elementTy, loc} =>
        let
          val valueExp = compileExp env valueExp
          val arrayExp = compileExp env arrayExp
          val indexExp = compileExp env indexExp
          val elementTag = findTagExp (env, elementTy, loc)
          val elementSize = findSizeExp (env, elementTy, loc)
        in
          B.BCSETFIELD {valueExp = valueExp,
                        arrayExp = arrayExp,
                        indexExp = indexExp,
                        elementTy = elementTy,
                        elementTag = elementTag,
                        elementSize = elementSize,
                        loc = loc}
        end
      | M.MVSETTAIL {consExp, newTailExp, tailLabel, listTy, consRecordTy,
                     loc} =>
        let
          val consExp = compileExp env consExp
          val newTailExp = compileExp env newTailExp
          val listTag = findTagExp (env, listTy, loc)
          val listSize = findSizeExp (env, listTy, loc)
          val tailLabelIndex =
              compileExp env (M.MVINDEXOF {label = tailLabel,
                                           recordTy = consRecordTy,
                                           loc = loc})
        in
          B.BCSETTAIL {consExp = consExp,
                       newTailExp = newTailExp,
                       tailLabel = tailLabel,
                       listTy = listTy,
                       consRecordTy = consRecordTy,
                       listTag = listTag,
                       listSize = listSize,
                       tailLabelIndex = tailLabelIndex,
                       loc = loc}
        end
      | M.MVARRAY {sizeExp, initialValue, elementTy, isMutable, loc} =>
        let
          val sizeExp = compileExp env sizeExp
          val initialValue = compileExp env initialValue
          val elementTag = findTagExp (env, elementTy, loc)
          val elementSize = findSizeExp (env, elementTy, loc)
        in
          B.BCARRAY {sizeExp = sizeExp,
                     initialValue = initialValue,
                     elementTy = elementTy,
                     elementTag = elementTag,
                     elementSize = elementSize,
                     isMutable = isMutable,
                     loc = loc}
        end
      | M.MVCOPYARRAY {srcExp, srcIndexExp, dstExp, dstIndexExp,
                       lengthExp, elementTy, loc} =>
        let
          val srcExp = compileExp env srcExp
          val srcIndexExp = compileExp env srcIndexExp
          val dstExp = compileExp env dstExp
          val dstIndexExp = compileExp env dstIndexExp
          val lengthExp = compileExp env lengthExp
          val elementTag = findTagExp (env, elementTy, loc)
          val elementSize = findSizeExp (env, elementTy, loc)
        in
          B.BCCOPYARRAY {srcExp = srcExp,
                         srcIndexExp = srcIndexExp,
                         dstExp = dstExp,
                         dstIndexExp = dstIndexExp,
                         lengthExp = lengthExp,
                         elementTy = elementTy,
                         elementTag = elementTag,
                         elementSize = elementSize,
                         loc = loc}
        end
*)
      | M.MVPRIMAPPLY {primInfo, argExpList, instTyList, loc} =>
        let
          val argExpList = map (compileExp env) argExpList
          val instTagList =
              map (fn ty => findTagExp (env, ty, loc)) instTyList
          val instSizeList =
              map (fn ty => findSizeExp (env, ty, loc)) instTyList
        in
          B.BCPRIMAPPLY {primInfo = primInfo,
                         argExpList = argExpList,
                         instTyList = instTyList,
                         instTagList = instTagList,
                         instSizeList = instSizeList,
                         loc = loc}
        end
      | M.MVAPPM {funExp, funTy, argExpList, loc} =>
        let
          val funExp = compileExp env funExp
          val argExpList = map (compileExp env) argExpList
        in
          B.BCAPPM {funExp = funExp,
                    funTy = funTy,
                    argExpList = argExpList,
                    loc = loc}
        end
      | M.MVLET {localDeclList, mainExp, loc} =>
        let
          val (env, localDeclList) = compileDeclList env localDeclList
          val mainExp = compileExp env mainExp
        in
          B.BCLET {localDeclList = localDeclList,
                   mainExp = mainExp,
                   loc = loc}
        end
      | M.MVMVALUES {expList, tyList, loc} =>
        let
          val expList = map (compileExp env) expList
        in
          B.BCMVALUES {expList = expList,
                       tyList = tyList,
                       loc = loc}
        end
      | M.MVRECORD {fields, recordTy, annotation, isMutable, loc} =>
        let
          val fieldList =
              map (fn {label, fieldExp} =>
                      {label = label, fieldExp = compileExp env fieldExp})
                  fields
          val fieldMap =
              foldl (fn ({label, fieldExp}, z) =>
                        if SEnv.inDomain (z, label)
                        then raise Control.Bug "MVRECORD: doubled label"
                        else SEnv.insert (z, label, fieldExp))
                    SEnv.empty
                    fieldList
          val fields = recordFieldTys env recordTy
          val fieldInfo = map (fn {tag, size, ...} => {tag = tag, size = size})
                              fields
          val (decls, {totalSize, fieldIndexes, bitmap}) =
              RecordLayout.computeRecord fieldInfo
          val totalSize =
              valueToBcexp (totalSize, SOME (T.RECORDSIZEty recordTy), loc)
          val fieldList =
              ListPair.mapEq
                (fn ({label, ty, size, ...}, index) =>
                    case SEnv.find (fieldMap, label) of
                      NONE => raise Control.Bug "MVRECORD: not found"
                    | SOME exp =>
                      {fieldExp = exp,
                       fieldLabel = label,
                       fieldTy = ty,
                       fieldIndex =
                         valueToBcexp (index,
                                       SOME (T.INDEXty (label, recordTy)),
                                       loc),
                       fieldSize =
                         valueToBcexp (RecordLayout.castToWord size,
                                       SOME (T.SIZEty ty), loc)})
                (fields, fieldIndexes)
          val bitmap =
              mapi (fn (i, v) =>
                       valueToBcexp (v, SOME (T.RECORDBITMAPty (i, recordTy)),
                                     loc))
                   bitmap
        in
          Let (map (toBcdecl loc) decls,
               B.BCRECORD {fieldList = fieldList,
                           recordTy = recordTy,
                           annotation = annotation,
                           isMutable = isMutable,
                           clearPad = true,
                           totalSizeExp = totalSize,
                           bitmapExpList = bitmap,
                           loc = loc},
               loc)
        end
      | M.MVSELECT {recordExp, indexExp, label, recordTy, resultTy, loc} =>
        let
          val recordExp = compileExp env recordExp
          val indexExp = compileExp env indexExp
          val resultSize = findSizeExp (env, resultTy, loc)
        in
          B.BCSELECT {recordExp = recordExp,
                      indexExp = indexExp,
                      label = label,
                      recordTy = recordTy,
                      resultTy = resultTy,
                      resultSize = resultSize,
                      loc = loc}
        end
      | M.MVMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy,
                    loc} =>
        let
          val recordExp = compileExp env recordExp
          val indexExp = compileExp env indexExp
          val valueExp = compileExp env valueExp
          val valueTag = findTagExp (env, valueTy, loc)
          val valueSize = findSizeExp (env, valueTy, loc)
        in
          B.BCMODIFY {recordExp = recordExp,
                      recordTy = recordTy,
                      indexExp = indexExp,
                      label = label,
                      valueExp = valueExp,
                      valueTy = valueTy,
                      valueTag = valueTag,
                      valueSize = valueSize,
                      loc = loc}
        end
      | M.MVRAISE {argExp, resultTy, loc} =>
        let
          val argExp = compileExp env argExp
        in
          B.BCRAISE {argExp = argExp,
                     resultTy = resultTy,
                     loc = loc}
        end
      | M.MVHANDLE {exp, exnVar, handler, loc} =>
        let
          val exp = compileExp env exp
          val env = SingletonTyEnv.bindVar (env, exnVar)
          val handler = compileExp env handler
        in
          B.BCHANDLE {tryExp = exp,
                      exnVar = exnVar,
                      handlerExp = handler,
                      loc = loc}
        end
      | M.MVPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        let
          val env = SingletonTyEnv.bindTyvars (env, btvEnv)
          val exp = compileExp env exp
        in
          B.BCPOLY {btvEnv = btvEnv,
                    expTyWithoutTAbs = expTyWithoutTAbs,
                    exp = exp,
                    loc = loc}
        end
      | M.MVTAPP {exp, expTy, instTyList, loc} =>
        let
          val exp = compileExp env exp
        in
          B.BCTAPP {exp = exp,
                    expTy = expTy,
                    instTyList = instTyList,
                    loc = loc}
        end
      | M.MVSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        let
          val switchExp = compileExp env switchExp
          val branches = map (fn {constant, exp} =>
                                 {constant = constant,
                                  branchExp = compileExp env exp})
                         branches
          val defaultExp = compileExp env defaultExp
        in
          B.BCSWITCH {switchExp = switchExp,
                      expTy = expTy,
                      branches = branches,
                      defaultExp = defaultExp,
                      loc = loc}
        end
      | M.MVCAST {exp, expTy, targetTy, loc} =>
        let
          val exp = compileExp env exp
        in
          B.BCCAST {exp = exp,
                    expTy = expTy,
                    targetTy = targetTy,
                    loc = loc}
        end
      | M.MVFNM {argVarList, funTy, bodyExp, annotation, loc} =>
        let
          val env = SingletonTyEnv.bindVars (env, argVarList)
          val bodyExp = compileExp env bodyExp
        in
          B.BCFNM {argVarList = argVarList,
                   funTy = funTy,
                   bodyExp = bodyExp,
                   annotation = annotation,
                   closureLayout = closureLayout (),
                   loc = loc}
        end

  and compileDecl env mvdecl =
      case mvdecl of
        M.MVVAL {boundVars, boundExp, loc} =>
        let
          val boundExp = compileExp env boundExp
        in
          (SingletonTyEnv.bindVars (env, boundVars),
           [B.BCVAL {boundVars = boundVars,
                     boundExp = boundExp,
                     loc = loc}])
        end
      | M.MVVALREC {recbindList, loc} =>
        let
          val env = SingletonTyEnv.bindVars (env, map #boundVar recbindList)
          val recbindList =
              map (fn {boundVar, boundExp} =>
                      {boundVar = boundVar,
                       boundExp = compileExp env boundExp})
                  recbindList
        in
          (env,
           [B.BCVALREC {recbindList = recbindList, loc = loc}])
        end
    | M.MVEXPORTVAR {varInfo, loc} =>
      (env,
       [B.BCEXPORTVAR {varInfo = varInfo,
                       varTag = findTagExp (env, #ty varInfo, loc),
                       varSize = findSizeExp (env, #ty varInfo, loc),
                       loc = loc}])
    | M.MVEXTERNVAR {exVarInfo, loc} =>
      (env,
       [B.BCEXTERNVAR {exVarInfo=exVarInfo, loc=loc}])

  and compileDeclList env (decl::decls) =
      let
        val (env, decls1) = compileDecl env decl
        val (env, decls2) = compileDeclList env decls
      in
        (env, decls1 @ decls2)
      end
    | compileDeclList env nil = (env, nil)

  fun compile decls =
      let
        val (env, decls) = compileDeclList SingletonTyEnv.emptyEnv decls
      in
        decls
      end

end
