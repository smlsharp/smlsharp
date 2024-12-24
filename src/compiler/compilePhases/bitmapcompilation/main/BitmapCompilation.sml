(**
 * record layout and bitmap compilation
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Huu-Duc Nguyen
 * @author Atsushi Ohori
 *)
structure BitmapCompilation =
struct

  structure R = RecordCalc
  structure B = BitmapCalc2
  structure T = Types
  structure P = BuiltinPrimitive
  type varInfo = RecordCalc.varInfo

  fun newVar ty =
      {id = VarID.generate (), path = [Symbol.generate ()], ty = ty} : B.varInfo

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

  fun Cast (exp, targetTy, loc) =
      B.BCCAST {exp = exp,
                expTy = BuiltinTypes.word32Ty,
                targetTy = targetTy,
                cast = P.TypeCast,
                loc = loc}

  fun toPrimInfo op2 =
      {primitive =
         case op2 of
           RecordLayoutCalc.ADD => P.R (P.M P.Word_add)
         | RecordLayoutCalc.SUB => P.R (P.M P.Word_sub)
         | RecordLayoutCalc.DIV => P.R (P.M P.Word_div_unsafe)
         | RecordLayoutCalc.AND => P.R (P.M P.Word_andb)
         | RecordLayoutCalc.OR => P.R (P.M P.Word_orb)
         | RecordLayoutCalc.LSHIFT => P.R (P.M P.Word_lshift_unsafe)
         | RecordLayoutCalc.RSHIFT => P.R (P.M P.Word_rshift_unsafe),
       ty = {boundtvars = BoundTypeVarID.Map.empty,
             argTyList = [BuiltinTypes.word32Ty, BuiltinTypes.word32Ty],
             resultTy = BuiltinTypes.word32Ty}}

  type accum =
      {comp : RecordLayout.computation_accum,
       subst : (BitmapCalc2.loc -> BitmapCalc2.bcexp) VarID.Map.map ref}

  fun newAccum () : accum =
      {comp = RecordLayout.newComputationAccum (),
       subst = ref VarID.Map.empty}

  fun toVarInfo {id, path} : BitmapCalc2.varInfo =
      {id = id, path = path, ty = BuiltinTypes.word32Ty}

  fun toBcexp ({subst, ...}:accum) loc value =
      case value of
        RecordLayoutCalc.WORD n =>
        B.BCCONSTANT {const = R.INT (R.WORD32 n), loc = loc}
      | RecordLayoutCalc.VAR v =>
        case VarID.Map.find (!subst, #id v) of
          NONE => B.BCVAR {varInfo = toVarInfo v, loc = loc}
        | SOME exp => exp loc

  fun toBcdecl accum loc decl =
      case decl of
        RecordLayoutCalc.VAL (v, RecordLayoutCalc.VALUE value) =>
        B.BCVAL {boundVar = toVarInfo v,
                 boundExp = toBcexp accum loc value,
                 loc = loc}
      | RecordLayoutCalc.VAL (v, RecordLayoutCalc.OP (op2, (v1, v2))) =>
        B.BCVAL {boundVar = toVarInfo v,
                 boundExp = B.BCPRIMAPPLY
                              {primInfo = toPrimInfo op2,
                               argExpList = [toBcexp accum loc v1,
                                             toBcexp accum loc v2],
                               instTyList = nil,
                               instTagList = nil,
                               instSizeList = nil,
                               loc = loc},
                 loc = loc}

  fun extractDecls (accum as {comp, ...}) loc =
      map (toBcdecl accum loc) (RecordLayout.extractDecls comp)

  fun toValue ({subst, ...}:accum) bcexp =
      case bcexp of
        B.BCCONSTANT {const = B.SIZE (size, ty), loc} =>
        RecordLayoutCalc.WORD (Word32.fromInt (RuntimeTypes.getSize size))
      | B.BCCONSTANT {const = B.TAG (tag, ty), loc} =>
        RecordLayoutCalc.WORD (Word32.fromInt (RuntimeTypes.tagValue tag))
      | B.BCVAR {varInfo = {id, path, ty}, loc} =>
        let
          val e = fn loc => B.BCCAST {exp = bcexp,
                                      expTy = ty,
                                      targetTy = BuiltinTypes.word32Ty,
                                      cast = P.TypeCast,
                                      loc = loc}
        in
          subst := VarID.Map.insert (!subst, id, e);
          RecordLayoutCalc.VAR {id = id, path = path}
        end
      | _ => raise Bug.Bug "toValue"

  fun compileValue loc rcvalue =
      case rcvalue of
        R.RCCONSTANT const => B.BCCONSTANT {const = const, loc = loc}
      | R.RCVAR var => B.BCVAR {varInfo = var, loc = loc}

  fun compileExp accum tlexp =
      case tlexp of
        R.RCFOREIGNAPPLY {funExp, attributes, resultTy, argExpList, loc} =>
        let
          val funExp = compileExp accum funExp
          val argExpList = map (compileExp accum) argExpList
        in
          B.BCFOREIGNAPPLY {funExp = funExp,
                            attributes = attributes,
                            resultTy = resultTy,
                            argExpList = argExpList,
                            loc = loc}
        end
      | R.RCCALLBACKFN {attributes, resultTy, argVarList, bodyExp, loc} =>
        let
          val bodyExp = compileExp accum bodyExp
        in
          B.BCCALLBACKFN {attributes = attributes,
                          resultTy = resultTy,
                          argVarList = argVarList,
                          bodyExp = bodyExp,
                          loc = loc}
        end
      | R.RCINDEXOF {label, fields, loc} =>
        let
          val recordTy = T.RECORDty (RecordLabel.Map.map #ty fields)
          val fields =
              map (fn (label, {ty, size}) =>
                      {label = label,
                       size = toValue accum (compileValue loc size)})
              (RecordLabel.Map.listItemsi fields)
          fun find (fields, nil) = raise Bug.Bug "compileExp: RCINDEXOF"
            | find (fields, {label=l,size}::t) =
              if l = label then (rev fields, {size=size})
              else find ({size=size}::fields, t)
          val (fields, lastField) = find (nil, fields)
          val index = RecordLayout.computeIndex (#comp accum)
                                                (fields, lastField)
        in
          Cast (toBcexp accum loc index,
                T.SINGLETONty (T.INDEXty (label, recordTy)),
                loc)
        end
      | R.RCVALUE (value, loc) =>
        compileValue loc value
      | R.RCSTRING (string, loc) =>
        B.BCSTRING {string = string, loc = loc}
      | R.RCEXVAR (exVarInfo, loc) =>
        B.BCEXVAR {exVarInfo = exVarInfo, loc=loc}
      | R.RCPRIMAPPLY {primOp, argExpList, instTyList, instSizeList,
                       instTagList, loc} =>
        let
          val argExpList = map (compileExp accum) argExpList
          val instTagList = map (compileValue loc) instTagList
          val instSizeList = map (compileValue loc) instSizeList
        in
          B.BCPRIMAPPLY {primInfo = primOp,
                         argExpList = argExpList,
                         instTyList = instTyList,
                         instTagList = instTagList,
                         instSizeList = instSizeList,
                         loc = loc}
        end
      | R.RCAPPM {funExp, instTyList, argExpList, funTy, loc} =>
        let
          val funExp = compileExp accum funExp
          val argExpList = map (compileExp accum) argExpList
        in
          B.BCAPPM {funExp = funExp,
                    instTyList = instTyList,
                    argExpList = argExpList,
                    funTy = funTy,
                    loc = loc}
        end
      | R.RCLET {decl, body, loc} =>
        let
          val localDecl = compileDecl accum decl
          val mainExp = compileExp accum body
        in
          B.BCLET {localDecl = localDecl, mainExp = mainExp, loc = loc}
        end
      | R.RCRECORD {fields, loc} =>
        let
          val recordTy =
              T.RECORDty (RecordLabel.Map.map #ty fields)
          val fields =
              map (fn (label, {exp, ty, tag, size}) =>
                      {label = label,
                       ty = ty,
                       tag = compileValue loc tag,
                       size = compileValue loc size,
                       exp = compileExp accum exp})
                  (RecordLabel.Map.listItemsi fields)
          val {allocSize, fieldIndexes, bitmaps, padding} =
              RecordLayout.computeRecord
                (#comp accum)
                (map (fn {tag, size, ...} =>
                         {tag = toValue accum tag, size = toValue accum size})
                     fields)
          val allocSize =
              Cast (toBcexp accum loc allocSize,
                    T.BACKENDty (T.RECORDSIZEty recordTy),
                    loc)
          val fieldList =
              ListPair.mapEq
                (fn ({label, ty, size, tag, exp}, index) =>
                    {fieldExp = exp,
                     fieldLabel = label,
                     fieldTy = ty,
                     fieldIndex =
                       Cast (toBcexp accum loc index,
                             T.SINGLETONty (T.INDEXty (label, recordTy)),
                             loc),
                     fieldSize = size,
                     fieldTag = tag})
                (fields, fieldIndexes)
          val bitmaps =
              mapi (fn (i, {index, bitmap}) =>
                       {bitmapIndex =
                          Cast
                            (toBcexp accum loc index,
                             T.BACKENDty (T.RECORDBITMAPINDEXty (i, recordTy)),
                             loc),
                        bitmapExp =
                          Cast
                            (toBcexp accum loc bitmap,
                             T.BACKENDty (T.RECORDBITMAPty (i, recordTy)),
                             loc)})
                   bitmaps
        in
          B.BCRECORD {fieldList = fieldList,
                      recordTy = recordTy,
                      isMutable = false,
                      clearPad = padding,
                      allocSizeExp = allocSize,
                      bitmaps = bitmaps,
                      loc = loc}
        end
      | R.RCSELECT {recordExp, indexExp, label, recordTy, resultTy,
                    resultSize, resultTag, loc} =>
        let
          val recordExp = compileExp accum recordExp
          val indexExp = compileExp accum indexExp
          val resultSize = compileValue loc resultSize
          val resultTag = compileValue loc resultTag
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
      | R.RCMODIFY {recordExp, recordTy, indexExp, label, elementExp, elementTy,
                    elementSize, elementTag, loc} =>
        let
          val recordExp = compileExp accum recordExp
          val indexExp = compileExp accum indexExp
          val valueExp = compileExp accum elementExp
(* 379_polyRecordUpdate.sml 
          val valueTag = compileValue loc elementSize
          val valueSize = compileValue loc elementTag
*)
          val valueTag = compileValue loc elementTag
          val valueSize = compileValue loc elementSize
        in
          B.BCMODIFY {recordExp = recordExp,
                      recordTy = recordTy,
                      indexExp = indexExp,
                      label = label,
                      valueExp = valueExp,
                      valueTy = elementTy,
                      valueTag = valueTag,
                      valueSize = valueSize,
                      loc = loc}
        end
      | R.RCRAISE {exp, resultTy, loc} =>
        let
          val argExp = compileExp accum exp
        in
          B.BCRAISE {argExp = argExp,
                     resultTy = resultTy,
                     loc = loc}
        end
      | R.RCHANDLE {exp, exnVar, handler, resultTy, loc} =>
        let
          val exp = compileExp accum exp
          val handler = compileExp accum handler
        in
          B.BCHANDLE {tryExp = exp,
                      exnVar = exnVar,
                      handlerExp = handler,
                      resultTy = resultTy,
                      loc = loc}
        end
      | R.RCSWITCH {exp, expTy, branches, defaultExp, resultTy, loc} =>
        let
          val switchExp = compileExp accum exp
          val branches = map (fn {const, body} =>
                                 {constant = const,
                                  branchExp = compileExp accum body})
                         branches
          val defaultExp = compileExp accum defaultExp
        in
          B.BCSWITCH {switchExp = switchExp,
                      expTy = expTy,
                      branches = branches,
                      defaultExp = defaultExp,
                      resultTy = resultTy,
                      loc = loc}
        end
      | R.RCCAST {exp, expTy, targetTy, cast, loc} =>
        let
          val exp = compileExp accum exp
        in
          B.BCCAST {exp = exp,
                    expTy = expTy,
                    targetTy = targetTy,
                    cast = cast,
                    loc = loc}
        end
      | R.RCFNM {btvEnv, constraints, argVarList, bodyExp, bodyTy, loc} =>
        let
          val accum2 = newAccum ()
          val bodyExp = compileExp accum2 bodyExp
          val decls = extractDecls accum2 loc
        in
          B.BCFNM {btvEnv = btvEnv,
                   constraints = constraints,
                   argVarList = argVarList,
                   retTy = bodyTy,
                   bodyExp = Let (decls, bodyExp, loc),
                   loc = loc}
        end
      | R.RCCATCH {recursive, rules, tryExp, resultTy, loc} =>
        let
          val rules = map (fn {catchLabel, argVarList, catchExp} =>
                              {catchLabel = catchLabel,
                               argVarList = argVarList,
                               catchExp = compileExp accum catchExp})
                          rules
          val tryExp = compileExp accum tryExp
        in
          B.BCCATCH {recursive = recursive,
                     rules = rules,
                     tryExp = tryExp,
                     resultTy = resultTy,
                     loc = loc}
        end
      | R.RCTHROW {catchLabel, argExpList, resultTy, loc} =>
        let
          val argExpList = map (compileExp accum) argExpList
        in
          B.BCTHROW {catchLabel = catchLabel,
                     argExpList = argExpList,
                     resultTy = resultTy,
                     loc = loc}
        end

  and compileDecl accum tldecl =
      case tldecl of
        R.RCVAL {var, exp, loc} =>
        let
          val boundExp = compileExp accum exp
        in
          B.BCVAL {boundVar = var,
                   boundExp = boundExp,
                   loc = loc}
        end
      | R.RCVALREC (recbindList, loc) =>
        let
          val recbindList =
              map (fn {var, exp} =>
                      {boundVar = var,
                       boundExp = compileExp accum exp})
                  recbindList
        in
          B.BCVALREC {recbindList = recbindList, loc = loc}
        end
    | R.RCEXPORTVAR {weak, var, exp} =>
      B.BCEXPORTVAR {weak = weak,
                     exVarInfo = var,
                     exp = compileExp accum exp,
                     loc = Loc.noloc}
    | R.RCEXTERNVAR (exVarInfo, provider) =>
      B.BCEXTERNVAR {exVarInfo = exVarInfo, provider = provider,
                     loc = Loc.noloc}

  fun compile decls =
      let
        val accum = newAccum ()
        val decls = map (compileDecl accum) decls
      in
        case extractDecls accum Loc.noloc of
          nil => ()
        | _ => raise Bug.Bug "compile: extra computation at toplevel";
        decls
      end

end
