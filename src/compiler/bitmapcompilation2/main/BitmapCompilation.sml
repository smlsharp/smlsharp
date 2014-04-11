(**
 * record layout and bitmap compilation
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 * @author Huu-Duc Nguyen
 * @author Atsushi Ohori
 *)
structure BitmapCompilation2 : sig

  val compile : TypedLambda.tldecl list -> BitmapCalc2.bcdecl list

end =
struct

  structure L = TypedLambda
  structure B = BitmapCalc2
  structure T = Types
  type varInfo = RecordCalc.varInfo

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

  fun Let (decls, mainExp, loc) =
      foldr
        (fn (decl, mainExp) =>
            B.BCLET {localDecl = decl, mainExp = mainExp, loc = loc})
        mainExp
        decls

  fun Cast ((exp, ty), targetTy, loc) =
      B.BCCAST {exp = exp, expTy = ty, targetTy = targetTy,
                runtimeTyCast = false, bitCast = false,
                loc = loc}

  fun valueToBcexp (value, loc) =
      case value of
        SingletonTyEnv2.CONST n =>
        (B.BCCONSTANT {const = ConstantTerm.WORD n,
                       ty = BuiltinTypes.wordTy,
                       loc = loc},
         BuiltinTypes.wordTy)
      | SingletonTyEnv2.VAR v =>
        (B.BCVAR {varInfo = v, loc = loc}, #ty v)
      | SingletonTyEnv2.TAG (ty, n) =>
        (B.BCTAG {tag = n, ty = ty, loc = loc},
         T.SINGLETONty (T.TAGty ty))
      | SingletonTyEnv2.SIZE (ty, n) =>
        (B.BCCAST
           {exp = B.BCCONSTANT {const = ConstantTerm.WORD (Word32.fromInt n),
                                ty = BuiltinTypes.wordTy,
                                loc = loc},
            expTy = BuiltinTypes.wordTy,
            targetTy = T.SINGLETONty (T.SIZEty ty),
            runtimeTyCast = false,
            bitCast = false,
            loc = loc},
         T.SINGLETONty (T.SIZEty ty))
      | SingletonTyEnv2.CAST (v, ty2) =>
        (Cast (valueToBcexp (v, loc), ty2, loc), ty2)

  fun toBcdecl loc decl =
      case decl of
        RecordLayout2.PRIMAPPLY {boundVar, primInfo, argList} =>
        let
          val argExpList = map (fn v => #1 (valueToBcexp (v, loc))) argList
        in
          B.BCVAL {boundVar = boundVar,
                   boundExp = B.BCPRIMAPPLY {primInfo = primInfo,
                                             argExpList = argExpList,
                                             instTyList = nil,
                                             instTagList = nil,
                                             instSizeList = nil,
                                             loc = loc},
                   loc = loc}
        end

  fun findTag (env, ty) =
      SingletonTyEnv2.findTag env ty

  fun findSize (env, ty) =
      SingletonTyEnv2.findSize env ty

  fun findTagExp (env, ty, loc) =
      #1 (valueToBcexp (findTag (env, ty), loc))

  fun findSizeExp (env, ty, loc) =
      #1 (valueToBcexp (findSize (env, ty), loc))

  fun recordFieldTys env recordTy =
      let
        val fields =
            case TypesBasics.derefTy recordTy of
              T.RECORDty fieldTypes => LabelEnv.listItemsi fieldTypes
            | _ => raise Bug.Bug "recordFieldTys"
      in
        map (fn (label, ty) =>
                {label = label,
                 ty = ty,
                 size = findSize (env, ty),
                 tag = findTag (env, ty)})
            fields
      end

  fun compileExp env comp tlexp =
      case tlexp of
        L.TLFOREIGNAPPLY {funExp, attributes, resultTy, argExpList, loc} =>
        let
          val funExp = compileExp env comp funExp
          val argExpList = map (compileExp env comp) argExpList
        in
          B.BCFOREIGNAPPLY {funExp = funExp,
                            attributes = attributes,
                            resultTy = resultTy,
                            argExpList = argExpList,
                            loc = loc}
        end
      | L.TLCALLBACKFN {attributes, resultTy, argVarList, bodyExp, loc} =>
        let
          val bodyExp = compileExp env comp bodyExp
        in
          B.BCCALLBACKFN {attributes = attributes,
                          resultTy = resultTy,
                          argVarList = argVarList,
                          bodyExp = bodyExp,
                          loc = loc}
        end
      | L.TLTAGOF {ty, loc} =>
        findTagExp (env, ty, loc)
      | L.TLSIZEOF {ty, loc} =>
        findSizeExp (env, ty, loc)
      | L.TLINDEXOF {label, recordTy, loc} =>
        let
          val fields = recordFieldTys env recordTy
          fun find (fields, nil) = raise Bug.Bug "compileExp: MVINDEXOF"
            | find (fields, {label=l,size,tag,ty}::t) =
              if l = label then (rev fields, {size=size})
              else find ({size=size}::fields, t)
          val (fields, lastField) = find (nil, fields)
          val index = RecordLayout2.computeIndex comp (fields, lastField)
        in
          Cast (valueToBcexp (index, loc),
                T.SINGLETONty (T.INDEXty (label, recordTy)),
                loc)
        end
      | L.TLCONSTANT {const, ty, loc} =>
        B.BCCONSTANT {const = const, ty = ty, loc = loc}
      | L.TLFOREIGNSYMBOL {name, ty, loc} =>
        B.BCFOREIGNSYMBOL {name = name, ty = ty, loc = loc}
      | L.TLVAR {varInfo, loc} =>
        B.BCVAR {varInfo = varInfo, loc = loc}
      | L.TLEXVAR {exVarInfo, loc} =>
        B.BCEXVAR {exVarInfo = exVarInfo, loc=loc}
      | L.TLPRIMAPPLY {primInfo, argExpList, instTyList, loc} =>
        let
          val argExpList = map (compileExp env comp) argExpList
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
      | L.TLAPPM {funExp, argExpList, funTy, loc} =>
        let
          val funExp = compileExp env comp funExp
          val argExpList = map (compileExp env comp) argExpList
        in
          B.BCAPPM {funExp = funExp,
                    argExpList = argExpList,
                    funTy = funTy,
                    loc = loc}
        end
      | L.TLLET {localDecl, mainExp, loc} =>
        let
          val (env, localDeclList) = compileDecl env comp localDecl
          val mainExp = compileExp env comp mainExp
        in
          Let (localDeclList, mainExp, loc)
        end
      | L.TLRECORD {fields, recordTy, isMutable, loc} =>
        let
          val fields =
              ListPair.mapEq
                (fn ({label, ty, tag, size}, (l2, exp)) =>
                    if label = l2
                    then {label=label, ty=ty, tag=tag, size=size,
                          exp = compileExp env comp exp}
                    else raise Bug.Bug "MVRECORD: label mismatch")
                (recordFieldTys env recordTy,
                 LabelEnv.listItemsi fields)
          val {allocSize, fieldIndexes, bitmaps, padding} =
              RecordLayout2.computeRecord
                comp
                (map (fn {tag, size, ...} => {tag = tag, size = size}) fields)
          val allocSize =
              Cast (valueToBcexp (allocSize, loc),
                    T.BACKENDty (T.RECORDSIZEty recordTy),
                    loc)
          val fieldList =
              ListPair.mapEq
                (fn ({label, ty, size, tag, exp}, index) =>
                    {fieldExp = exp,
                     fieldLabel = label,
                     fieldTy = ty,
                     fieldIndex =
                       Cast (valueToBcexp (index, loc),
                             T.SINGLETONty (T.INDEXty (label, recordTy)),
                             loc),
                     fieldSize = #1 (valueToBcexp (size, loc)),
                     fieldTag = #1 (valueToBcexp (tag, loc))})
                (fields, fieldIndexes)
          val bitmaps =
              mapi (fn (i, {index, bitmap}) =>
                       {bitmapIndex =
                          Cast
                            (valueToBcexp (index, loc),
                             T.BACKENDty (T.RECORDBITMAPINDEXty (i, recordTy)),
                             loc),
                        bitmapExp =
                          Cast
                            (valueToBcexp (bitmap, loc),
                             T.BACKENDty (T.RECORDBITMAPty (i, recordTy)),
                             loc)})
                   bitmaps
        in
          B.BCRECORD {fieldList = fieldList,
                      recordTy = recordTy,
                      isMutable = isMutable,
                      clearPad = padding,
                      allocSizeExp = allocSize,
                      bitmaps = bitmaps,
                      loc = loc}
        end
      | L.TLSELECT {recordExp, indexExp, label, recordTy, resultTy, loc} =>
        let
          val recordExp = compileExp env comp recordExp
          val indexExp = compileExp env comp indexExp
          val resultSize = findSizeExp (env, resultTy, loc)
          val resultTag = findTagExp (env, resultTy, loc)
        in
          B.BCSELECT {recordExp = recordExp,
                      indexExp = indexExp,
                      label = label,
                      recordTy = recordTy,
                      resultTy = resultTy,
                      resultSize = resultSize,
                      resultTag = resultTag,
                      loc = loc}
        end
      | L.TLMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy,
                    loc} =>
        let
          val recordExp = compileExp env comp recordExp
          val indexExp = compileExp env comp indexExp
          val valueExp = compileExp env comp valueExp
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
      | L.TLRAISE {argExp, resultTy, loc} =>
        let
          val argExp = compileExp env comp argExp
        in
          B.BCRAISE {argExp = argExp,
                     resultTy = resultTy,
                     loc = loc}
        end
      | L.TLHANDLE {exp, exnVar, handler, resultTy, loc} =>
        let
          val exp = compileExp env comp exp
          val env = SingletonTyEnv2.bindVar (env, exnVar)
          val handler = compileExp env comp handler
        in
          B.BCHANDLE {tryExp = exp,
                      exnVar = exnVar,
                      handlerExp = handler,
                      resultTy = resultTy,
                      loc = loc}
        end
      | L.TLPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        let
          val env = SingletonTyEnv2.bindTyvars (env, btvEnv)
          val exp = compileExp env comp exp
        in
          B.BCPOLY {btvEnv = btvEnv,
                    expTyWithoutTAbs = expTyWithoutTAbs,
                    exp = exp,
                    loc = loc}
        end
      | L.TLTAPP {exp, expTy, instTyList, loc} =>
        let
          val exp = compileExp env comp exp
        in
          B.BCTAPP {exp = exp,
                    expTy = expTy,
                    instTyList = instTyList,
                    loc = loc}
        end
      | L.TLSWITCH {switchExp, expTy, branches, defaultExp, resultTy, loc} =>
        let
          val switchExp = compileExp env comp switchExp
          val branches = map (fn {constant, exp} =>
                                 {constant = constant,
                                  branchExp = compileExp env comp exp})
                         branches
          val defaultExp = compileExp env comp defaultExp
        in
          B.BCSWITCH {switchExp = switchExp,
                      expTy = expTy,
                      branches = branches,
                      defaultExp = defaultExp,
                      resultTy = resultTy,
                      loc = loc}
        end
      | L.TLCAST {exp, expTy, targetTy, runtimeTyCast, bitCast, loc} =>
        let
          val exp = compileExp env comp exp
        in
          B.BCCAST {exp = exp,
                    expTy = expTy,
                    targetTy = targetTy,
                    runtimeTyCast = runtimeTyCast,
                    bitCast = bitCast,
                    loc = loc}
        end
      | L.TLFNM {argVarList, bodyExp, bodyTy, loc} =>
        let
          val env = SingletonTyEnv2.bindVars (env, argVarList)
          val comp2 = RecordLayout2.newComputationAccum ()
          val bodyExp = compileExp env comp2 bodyExp
          val decls = RecordLayout2.extractDecls comp2
        in
          B.BCFNM {argVarList = argVarList,
                   retTy = bodyTy,
                   bodyExp = Let (map (toBcdecl loc) decls, bodyExp, loc),
                   loc = loc}
        end
      | L.TLLOCALCODE {codeLabel, argVarList, codeBodyExp, mainExp, resultTy,
                       loc} =>
        let
          val env2 = SingletonTyEnv2.bindVars (env, argVarList)
          val codeBodyExp = compileExp env2 comp codeBodyExp
          val mainExp = compileExp env comp mainExp
        in
          B.BCLOCALCODE {codeLabel = codeLabel,
                         argVarList = argVarList,
                         codeBodyExp = codeBodyExp,
                         mainExp = mainExp,
                         resultTy = resultTy,
                         loc = loc}
        end
      | L.TLGOTO {destinationLabel, argExpList, resultTy, loc} =>
        let
          val argExpList = map (compileExp env comp) argExpList
        in
          B.BCGOTO {destinationLabel = destinationLabel,
                    argExpList = argExpList,
                    resultTy = resultTy,
                    loc = loc}
        end

  and compileDecl env comp tldecl =
      case tldecl of
        L.TLVAL {boundVar, boundExp, loc} =>
        let
          val boundExp = compileExp env comp boundExp
        in
          (SingletonTyEnv2.bindVars (env, [boundVar]),
           [B.BCVAL {boundVar = boundVar,
                     boundExp = boundExp,
                     loc = loc}])
        end
      | L.TLVALREC {recbindList, loc} =>
        let
          val env = SingletonTyEnv2.bindVars (env, map #boundVar recbindList)
          val recbindList =
              map (fn {boundVar, boundExp} =>
                      {boundVar = boundVar,
                       boundExp = compileExp env comp boundExp})
                  recbindList
        in
          (env, [B.BCVALREC {recbindList = recbindList, loc = loc}])
        end
    | L.TLEXPORTVAR (exVarInfo, exp, loc) =>
      (env, [B.BCEXPORTVAR {exVarInfo = exVarInfo,
                            exp = compileExp env comp exp,
                            loc = loc}])
    | L.TLEXTERNVAR (exVarInfo, loc) =>
      (env, [B.BCEXTERNVAR {exVarInfo = exVarInfo, loc = loc}])

  fun compileDeclList env comp (decl::decls) =
      let
        val (env, decls1) = compileDecl env comp decl
        val (env, decls2) = compileDeclList env comp decls
      in
        (env, decls1 @ decls2)
      end
    | compileDeclList env comp nil = (env, nil)

  fun compile decls =
      let
        val comp = RecordLayout2.newComputationAccum ()
        val (env, decls) = compileDeclList SingletonTyEnv2.emptyEnv comp decls
      in
        case RecordLayout2.extractDecls comp of
          nil => ()
        | _ => raise Bug.Bug "compile: extra computation at toplevel";
        decls
      end

end
