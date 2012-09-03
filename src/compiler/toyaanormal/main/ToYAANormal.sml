(**
 * stub phase for translation into YAANormal.
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure ToYAANormal : sig

  val transform : ClosureANormal.catopdec list -> YAANormal.topdecl list

end =
struct

  structure C = ClosureANormal
  structure A = YAANormal
  structure CT = ConstantTerm
  structure T = AnnotatedTypes
  structure R = RuntimeTypes

  fun flattenTy ty =
      case ty of
        T.MVALty tys => List.concat (map flattenTy tys)
      | _ => [ty]

  fun newVar ty =
      let
        val id = VarID.generate ()
      in
        {id = id, displayName = "$" ^ VarID.toString id,
         ty = ty, varKind = A.LOCAL} : A.varInfo
      end

  type env =
      {
        varEnv : A.varInfo VarID.Map.map,
        btvEnv : C.btvEnv,
        closureEnvVar : C.varInfo option,
        mergePoint : (A.id * C.varInfo list) option
      }

  val emptyEnv =
      {varEnv = VarID.Map.empty,
       btvEnv = BoundTypeVarID.Map.empty,
       closureEnvVar = NONE,
       mergePoint = NONE} : env

  fun newEnv (SOME {argVar:C.varInfo, freeVars:C.varInfo list}) =
      {varEnv = VarID.Map.empty,
       btvEnv = BoundTypeVarID.Map.empty,
       closureEnvVar = SOME argVar,
       mergePoint = NONE} : env
    | newEnv NONE = emptyEnv

  fun transformTy ({btvEnv,...}:env) ty =
      case TypeLayout.runtimeTy btvEnv ty of
        SOME R.UCHARty => A.BYTE
      | SOME R.INTty => A.SINT
      | SOME R.UINTty => A.UINT
      | SOME R.BOXEDty => A.BOXED
      | SOME R.POINTERty => A.POINTER
      | SOME R.CODEPOINTERty => A.CODEPOINT
      | SOME R.DOUBLEty => A.DOUBLE
      | SOME R.FLOATty => A.FLOAT
      | NONE =>
        case ty of
          T.BOUNDVARty tid => A.GENERIC tid
        | _ => raise Control.Bug "transformTy"

  fun decomposeFunTy env ty =
      case ty of
        T.FUNMty {argTyList, bodyTy, ...} =>
        (map (transformTy env) argTyList,
         map (transformTy env) (flattenTy bodyTy))
      | _ => raise Control.Bug "decomposeFunTy"

  fun lookupVar ({varEnv,...}:env) ({id, ...}:C.varInfo) =
      case VarID.Map.find (varEnv, id) of
        SOME var => var
      | NONE => raise Control.Bug ("lookupVar: " ^ VarID.toString id)

  fun bindVar (env:env) varKind ({id, path, ty}:C.varInfo) =
      let
        val var = {id = id,
                   displayName = String.concatWith "." path,
                   ty = transformTy env ty,
                   varKind = varKind} : A.varInfo
      in
        ({varEnv = VarID.Map.insert (#varEnv env, id, var),
          btvEnv = #btvEnv env,
          closureEnvVar = #closureEnvVar env,
          mergePoint = #mergePoint env} : env,
         var)
      end

  fun bindVarList env varKind nil = (env, nil)
    | bindVarList env varKind (var::vars) =
      let
        val (env, var) = bindVar env varKind var
        val (env, vars) = bindVarList env varKind vars
      in
        (env, var::vars)
      end

  fun bindTyvars (env:env, btvEnv) =
      {varEnv = #varEnv env,
       btvEnv = BoundTypeVarID.Map.unionWith #2 (#btvEnv env, btvEnv),
       closureEnvVar = #closureEnvVar env,
       mergePoint = #mergePoint env}: env

  fun setMergePoint (env:env, mergeLabel, mergeVars) =
      {varEnv = #varEnv env,
       btvEnv = #btvEnv env,
       closureEnvVar = #closureEnvVar env,
       mergePoint = SOME (mergeLabel, mergeVars)} : env

  fun isClosureEnvVar ({closureEnvVar=NONE,...}:env) value = false
    | isClosureEnvVar env NONE = false
    | isClosureEnvVar (env as {closureEnvVar=SOME{id,...},...}) (SOME value) =
      case value of
        C.BACONST _ => false
      | C.BAVAR varInfo => #id varInfo = id
      | C.BACAST {exp, expTy, targetTy} => isClosureEnvVar env (SOME exp)
      | C.BATAPP {exp, expTy, instTyList} => isClosureEnvVar env (SOME exp)

  fun multiplyExp (value1, value2, loc) =
      case (value1, value2) of
        (A.ANWORD n1, A.ANWORD n2) => (nil, A.ANWORD (n1 * n2))
      | (A.ANINT n1, A.ANINT n2) => (nil, A.ANINT (n1 * n2))
      | (A.ANINT n1, A.ANWORD n2) =>
        (nil, A.ANWORD (Word32.fromLargeInt (Int32.toLarge n1) * n2))
      | (A.ANWORD n1, A.ANINT n2) =>
        (nil, A.ANWORD (n1 * Word32.fromLargeInt (Int32.toLarge n2)))
      | _ =>
        let
          val var = newVar A.UINT
        in
          ([A.ANVAL {varList = [var],
                     exp = A.ANPRIMAPPLY {prim = BuiltinPrimitive.Word_mul,
                                          argList = [value1, value2],
                                          argTyList = [A.UINT, A.UINT],
                                          resultTyList = [A.UINT],
                                          instSizeList = nil,
                                          instTagList = nil},
                     loc = loc}],
           A.ANVAR var)
        end

  datatype const =
      CONST of A.ty
    | VALUE of A.anvalue

  fun transformConstantTerm const =
      case const of
        CT.INT x => VALUE (A.ANINT x)
      | CT.LARGEINT _ => CONST A.BOXED
      | CT.WORD x => VALUE (A.ANWORD x)
      | CT.BYTE x => VALUE (A.ANBYTE x)
      | CT.STRING _ => CONST A.BOXED
      | CT.REAL _ => CONST A.DOUBLE
      | CT.FLOAT _ => CONST A.FLOAT
      | CT.CHAR x => VALUE (A.ANCHAR x)
      | CT.UNIT => VALUE A.ANUNIT
      | CT.NULLPOINTER => VALUE A.ANNULLPOINTER
      | CT.NULLBOXED => VALUE A.ANNULLBOXED

  fun transformConst baconst =
      case baconst of
        C.BACONSTANT value =>
        (
          case transformConstantTerm value of
            VALUE value => (nil, value)
          | CONST ty =>
            let
              val var = newVar ty
            in
              ([A.ANVAL {varList = [var],
                         exp = A.ANCONST value,
                         loc = Loc.noloc}],
               A.ANVAR var)
            end
        )
      | C.BAGLOBALSYMBOL {name, kind=Absyn.ForeignCodeSymbol, ty} =>
        (nil, A.ANTOPSYMBOL {name = A.TOP_EXTERN name, ty = A.FOREIGNFUN})

  fun transformValue env bavalue =
      case bavalue of
        C.BACONST const => transformConst const
      | C.BAVAR varInfo =>
        (nil, A.ANVAR (lookupVar env varInfo))
      | C.BACAST {exp, expTy, targetTy} => transformValue env exp
      | C.BATAPP {exp, expTy, instTyList} => transformValue env exp

  fun transformValueList env nil = (nil, nil)
    | transformValueList env (value::values) =
      let
        val (dec1, value) = transformValue env value
        val (dec2, values) = transformValueList env values
      in
        (dec1 @ dec2, value::values)
      end

  fun transformPrim env baprim =
      case baprim of
        C.BAVALUE (C.BACONST (C.BACONSTANT const)) =>
        (
          case transformConstantTerm const  of
            VALUE value => (nil, A.ANVALUE value)
          | CONST ty => (nil, A.ANCONST const)
        )
      | C.BAVALUE value =>
        let
          val (dec1, value) = transformValue env value
        in
          (dec1, A.ANVALUE value)
        end
      | C.BAEXVAR {exVarInfo as {path, ty}, varSize} =>
        let
          val displayName = NameMangle.mangle exVarInfo
          val ty = transformTy env ty
          val (dec1, size) = transformValue env varSize
        in
          (dec1,
           A.ANGETFIELD {array = A.ANTOPSYMBOL
                                   {name = A.TOP_EXTERN displayName,
                                    ty = A.POINTER},
                         offset = A.ANWORD 0w0,
                         size = size,
                         needBoundaryCheck = false,
                         ty = ty})
        end
      | C.BAPRIMAPPLY {primInfo={primitive,ty}, argExpList, instTyList,
                       instTagList, instSizeList} =>
        raise Control.Bug "transformPrim: BAPRIMAPPLY"
      | C.BARECORD {fieldList, recordTy, annotation,
                    isMutable, clearPad, totalSizeExp, bitmapExpList} =>
        let
          fun unzip nil = (nil, nil, nil, nil, nil)
            | unzip ({fieldExp,fieldIndex,fieldLabel,fieldSize,fieldTy}::t) =
              let val (l1,l2,l3,l4,l5) = unzip t
              in (fieldExp::l1, fieldIndex::l2, fieldLabel::l3,
                  fieldSize::l4, fieldTy::l5)
              end
          val (expList, indexExpList, labelList, sizeExpList, tyList) =
              unzip fieldList
          val (dec1, bitmaps) = transformValueList env bitmapExpList
          val (dec2, totalSize) = transformValue env totalSizeExp
          val (dec3, fieldList) = transformValueList env expList
          val (dec4, fieldSizeList) = transformValueList env sizeExpList
          val (dec5, fieldIndexList) = transformValueList env indexExpList
        in
          (dec1 @ dec2 @ dec3 @ dec4 @ dec5,
           A.ANRECORD {bitmaps = bitmaps,
                       totalSize = totalSize,
                       fieldList = fieldList,
                       fieldSizeList = fieldSizeList,
                       fieldTyList = map (transformTy env) tyList,
                       fieldIndexList = fieldIndexList,
                       isMutable = isMutable,
                       clearPad = clearPad})
        end
      | C.BASELECT {recordExp, indexExp, label, recordTy, resultTy,
                    resultSize} =>
        if isClosureEnvVar env (SOME recordExp) then
          let
            val offset = case transformValue env indexExp of
                           (nil, A.ANWORD x) => x
                         | _ => raise Control.Bug "BASELECT"
            val (dec1, size) = transformValue env resultSize
          in
            (dec1,
             A.ANENVACC {nestLevel = 0w0,
                         offset = offset,
                         size = size,
                         ty = transformTy env resultTy})
          end
        else
          let
            val (dec1, record) = transformValue env recordExp
            val (dec2, offset) = transformValue env indexExp
            val (dec3, size) = transformValue env resultSize
          in
            (dec1 @ dec2 @ dec3,
             A.ANSELECT {record = record,
                         nestLevel = A.ANWORD 0w0,
                         offset = offset,
                         size = size,
                         ty = transformTy env resultTy})
          end
      | C.BAMODIFY {recordExp, recordTy, indexExp, label, valueExp,
                    valueTy, valueTag, valueSize} =>
        let
          val (dec1, record) = transformValue env recordExp
          val (dec2, offset) = transformValue env indexExp
          val (dec3, value) = transformValue env valueExp
          val (dec4, valueSize) = transformValue env valueSize
          val (dec5, valueTag) = transformValue env valueTag
        in
          (dec1 @ dec2 @ dec3 @ dec4 @ dec5,
           A.ANMODIFY {record = record,
                       nestLevel = A.ANWORD 0w0,
                       offset = offset,
                       value = value,
                       valueTy = transformTy env valueTy,
                       valueSize = valueSize,
                       valueTag = valueTag})
        end

  fun transformCall env bacall =
      case bacall of
        C.BAFOREIGNAPPLY {funExp, foreignFunTy={argTyList,resultTy,attributes},
                          argExpList} =>
        let
          val argTyList = map (transformTy env) argTyList
          val resultTyList = map (transformTy env) (flattenTy resultTy)
          val (dec1, function) = transformValue env funExp
          val (dec2, argList) = transformValueList env argExpList
        in
          (dec1 @ dec2,
           A.ANFOREIGNAPPLY {function = function,
                             argList = argList,
                             argTyList = argTyList,
                             resultTyList = resultTyList,
                             attributes = attributes})
        end
      | C.BAAPPM {funExp, funTy, argExpList} =>
        let
          val (argTyList, resultTyList) = decomposeFunTy env funTy
          val (dec1, funLabel) = transformValue env funExp
          val (dec2, argList) = transformValueList env argExpList
        in
          (dec1 @ dec2,
           if AnnotatedTypesUtils.isLocalFunTy funTy
           then A.ANLOCALCALL {codeLabel = funLabel,
                               argList = argList,
                               argTyList = argTyList,
                               resultTyList = resultTyList,
                               returnLabel = VarID.generate (),
                               knownDestinations = ref nil}
           else A.ANAPPLY {closure = funLabel,
                           argList = argList,
                           argTyList = argTyList,
                           resultTyList = resultTyList})
        end

  fun transformExp env caexp =
      case caexp of
        C.CAVAL {boundVar,
                 boundExp = C.BAPRIMAPPLY {primInfo={primitive,ty}, argExpList,
                                           instTyList,
                                           instTagList, instSizeList},
                 nextExp, loc} =>
        let
          val (env, var) = bindVar env A.LOCAL boundVar
          val funTy = AnnotatedTypesUtils.tpappTy (ty, instTyList)
          val (argTyList, resultTyList) = decomposeFunTy env funTy
          val (dec1, argList) = transformValueList env argExpList
          val (dec2, instSizeList) = transformValueList env instSizeList
          val (dec3, instTagList) = transformValueList env instTagList
          val instTyList = map (transformTy env) instTyList
        in
          dec1 @ dec2 @ dec3 @
          (
            case (primitive, argList, instTyList, instTagList, instSizeList) of
              (BuiltinPrimitive.Array_allocArray, [length],
               [elementTy], [bitmap], [elementSize]) =>
              let
                val (dec1, totalSize) = multiplyExp (length, elementSize, loc)
              in
                dec1 @
                [A.ANVAL {varList = [var],
                          exp = A.ANARRAY {bitmap = bitmap,
                                           totalSize = totalSize,
                                           initialValue = NONE,
                                           elementTy = elementTy,
                                           elementSize = elementSize,
                                           isMutable = true},
                          loc = loc}]
              end
            | (BuiltinPrimitive.Array_allocVector, [length],
               [elementTy], [bitmap], [elementSize]) =>
              let
                val (dec1, totalSize) = multiplyExp (length, elementSize, loc)
              in
                dec1 @
                [A.ANVAL {varList = [var],
                          exp = A.ANARRAY {bitmap = bitmap,
                                           totalSize = totalSize,
                                           initialValue = NONE,
                                           elementTy = elementTy,
                                           elementSize = elementSize,
                                           isMutable = false},
                          loc = loc}]
              end
            | (BuiltinPrimitive.Array_copy_unsafe,
               [src, srcOffset, dst, dstOffset, length],
               [elementTy], [elementTag], [elementSize]) =>
              let
                val (dec1, srcOffset) =
                    multiplyExp (srcOffset, elementSize, loc)
                val (dec2, dstOffset) =
                    multiplyExp (dstOffset, elementSize, loc)
              in
                dec1 @ dec2 @
                [A.ANCOPYARRAY {src = src,
                                srcOffset = srcOffset,
                                dst = dst,
                                dstOffset = dstOffset,
                                length = length,
                                elementTy = elementTy,
                                elementSize = elementSize,
                                elementTag = elementTag,
                                loc = loc},
                 A.ANVAL {varList = [var],
                          exp = A.ANCONST CT.UNIT,
                          loc = loc}]
              end
            | (BuiltinPrimitive.Array_sub,
               [array, offset], [elementTy], [tag], [size]) =>
              let
                val (dec1, offset) = multiplyExp (offset, size, loc)
              in
                dec1 @
                [A.ANVAL {varList = [var],
                          exp = A.ANGETFIELD {array = array,
                                              offset = offset,
                                              size = size,
                                              needBoundaryCheck = true,
                                              ty = elementTy},
                          loc = loc}]
              end
            | (BuiltinPrimitive.Array_update,
               [array, offset, value], [elementTy], [valueTag], [valueSize]) =>
              let
                val (dec1, offset) = multiplyExp (offset, valueSize, loc)
              in
                dec1 @
                [A.ANSETFIELD {array = array,
                               offset = offset,
                               value = value,
                               valueTy = elementTy,
                               valueSize = valueSize,
                               valueTag = valueTag,
                               setGlobal = false,
                               needBoundaryCheck = true,
                               loc = loc},
                 A.ANVAL {varList = [var],
                          exp = A.ANCONST CT.UNIT,
                          loc = loc}]
              end
            | (BuiltinPrimitive.Ref_alloc, [initialValue],
               [elementTy], [bitmap], [elementSize]) =>
              dec1 @
              [A.ANVAL {varList = [var],
                        exp = A.ANARRAY {bitmap = bitmap,
                                         totalSize = elementSize,
                                         initialValue = SOME initialValue,
                                         elementTy = elementTy,
                                         elementSize = elementSize,
                                         isMutable = true},
                        loc = loc}]
            | (BuiltinPrimitive.Ref_assign,
               [array, value], [elementTy], [valueTag], [valueSize]) =>
              [A.ANSETFIELD {array = array,
                             offset = A.ANWORD 0w0,
                             value = value,
                             valueTy = elementTy,
                             valueSize = valueSize,
                             valueTag = valueTag,
                             setGlobal = false,
                             needBoundaryCheck = true,
                             loc = loc},
               A.ANVAL {varList = [var],
                        exp = A.ANCONST CT.UNIT,
                        loc = loc}]
            | (BuiltinPrimitive.Ref_deref,
               [array], [elementTy], [valueTag], [valueSize]) =>
              dec1 @
              [A.ANVAL {varList = [var],
                        exp = A.ANGETFIELD {array = array,
                                            offset = A.ANWORD 0w0,
                                            size = valueSize,
                                            needBoundaryCheck = false,
                                            ty = elementTy},
                        loc = loc}]
            | _ =>
              [A.ANVAL {varList = [var],
                        exp = A.ANPRIMAPPLY {prim = primitive,
                                             argList = argList,
                                             argTyList = argTyList,
                                             resultTyList = resultTyList,
                                             instSizeList = instSizeList,
                                             instTagList = instTagList},
                        loc = loc}]
          )
          @ transformExp env nextExp
        end
      | C.CAVAL {boundVar, boundExp, nextExp, loc} =>
        let
          val (dec1, exp) = transformPrim env boundExp
          val (env, var) = bindVar env A.LOCAL boundVar
        in
          dec1 @
          [A.ANVAL {varList = [var],
                    exp = exp,
                    loc = loc}]
          @ transformExp env nextExp
        end
      | C.CACALL {resultVars, callExp, nextExp, loc} =>
        let
          val (dec1, exp) = transformCall env callExp
          val (env, varList) = bindVarList env A.LOCAL resultVars
        in
          dec1 @
          [A.ANVAL {varList = varList,
                    exp = exp,
                    loc = loc}]
          @ transformExp env nextExp
        end
      | C.CAEXPORTVAR {varInfo as {path,ty,id}, varSize, varTag, nextExp,
                       loc} =>
        let
          val value = A.ANVAR (lookupVar env varInfo)
          val (dec1, valueSize) = transformValue env varSize
          val (dec2, valueTag) = transformValue env varTag
          val displayName = NameMangle.mangle {path=path, ty=ty}
          val ty = transformTy env ty
        in
          dec1 @ dec2 @
          [A.ANSETFIELD {array = A.ANTOPSYMBOL
                                   {name = A.TOP_EXPORT
                                             (A.TOP_GLOBAL displayName),
                                    ty = A.POINTER},
                         offset = A.ANWORD 0w0,
                         value = value,
                         valueTy = ty,
                         valueSize = valueSize,
                         valueTag = valueTag,
                         setGlobal = true,
                         needBoundaryCheck = false,
                         loc = loc}]
          @ transformExp env nextExp
        end
(*
      | C.CASTATEMENT {statement, nextExp, loc} =>
        transformStatement env statement loc
        @ transformExp env nextExp
*)
      | C.CACLOSURE {boundVar, codeId, closureEnv, closureLayout, nextExp,
                     funTy, loc} =>
        if isClosureEnvVar env closureEnv then
          let
            val (env, var) = bindVar env A.LOCAL boundVar
          in
            [A.ANVAL {varList = [var],
                      exp = A.ANRECCLOSURE {funLabel = A.ANLABEL codeId},
                      loc = loc}]
            @ transformExp env nextExp
          end
        else
          let
            val (dec1, closEnv) =
                case closureEnv of
                  NONE => (nil, A.ANNULLBOXED)
                | SOME closureEnv => transformValue env closureEnv
            val (env, var) = bindVar env A.LOCAL boundVar
          in
            dec1 @
            [A.ANVAL {varList = [var],
                      exp = A.ANCLOSURE {funLabel = A.ANLABEL codeId,
                                         env = closEnv},
                      loc = loc}]
            @ transformExp env nextExp
          end
      | C.CACALLBACKCLOSURE {boundVar, codeId, closureEnv, nextExp,
                             foreignFunTy={argTyList,resultTy,attributes},
                             loc} =>
        let
          val argTyList = map (transformTy env) argTyList
          val resultTyList = map (transformTy env) (flattenTy resultTy)
          val (dec1, closureEnv) =
              case closureEnv of
                NONE => (nil, A.ANNULLBOXED)
              | SOME closureEnv => transformValue env closureEnv
          val (env, var) = bindVar env A.LOCAL boundVar
        in
          dec1 @
          [A.ANVAL {varList = [var],
                    exp = A.ANCALLBACKCLOSURE {funLabel = A.ANLABEL codeId,
                                               env = closureEnv,
                                               argTyList = argTyList,
                                               resultTyList = resultTyList,
                                               attributes = attributes},
                    loc = loc}]
          @ transformExp env nextExp
        end
      | C.CALOCALFNM {recbindList, nextExp, loc} =>
        let
          val (env, vars) = bindVarList env A.LOCAL (map #boundVar recbindList)
          val codeList =
              map
                (fn {boundVar, function={argVarList, funTy, bodyExp,
                                         annotation, loc}:C.localFunction} =>
                    let
                      val (argTyList, resultTyList) = decomposeFunTy env funTy
                      val (env, argVarList) = bindVarList env A.ARG argVarList
                      val body = transformExp env bodyExp
                    in
                      {codeId = #id boundVar,
                       argVarList = argVarList,
                       body = body,
                       resultTyList = resultTyList,
                       loc = loc} : A.codeDecl
                    end)
                recbindList
        in
          A.ANVALCODE {codeList = codeList, loc = loc}
          :: transformExp env nextExp
        end
      | C.CAHANDLE {resultVars, tryExp, exnVar, handlerExp, nextExp, loc} =>
        let
          val tryLabel = VarID.generate ()
          val leaveLabel = VarID.generate ()
          val handlerLabel = VarID.generate ()
          val endLabel = VarID.generate ()
          val tryEnv = setMergePoint (env, leaveLabel, resultVars)
          val try = transformExp tryEnv tryExp
          val (handlerEnv, exnVar) = bindVar tryEnv A.LOCAL exnVar
          val handlerEnv = setMergePoint (handlerEnv, endLabel, resultVars)
          val handler = transformExp handlerEnv handlerExp
          val (env, resultVars) = bindVarList env A.LOCAL resultVars
        in
          A.ANHANDLE {try = try,
                      exnVar = exnVar,
                      handler = handler,
                      labels = {tryLabel = tryLabel,
                                leaveLabel = leaveLabel,
                                handlerLabel = handlerLabel},
                      loc = loc}
          :: A.ANMERGEPOINT {label = leaveLabel,
                             varList = resultVars,
                             leaveHandler = SOME {handlerLabel = handlerLabel,
                                                  tryLabel = tryLabel},
                             loc = loc}
          :: A.ANMERGE {label = endLabel,
                        varList = resultVars,
                        loc = loc}
          :: A.ANMERGEPOINT {label = endLabel,
                             varList = resultVars,
                             leaveHandler = NONE,
                             loc = loc}
          :: transformExp env nextExp
        end
(*
      | C.CANEST {resultVars, nestExp, nextExp, loc} =>
        let
          val mergeLabel = VarID.generate ()
          val nestEnv = setMergePoint (env, mergeLabel)
          val (env, resultVars) = bindVarList env A.LOCAL resultVars
        in
          transformExp nestEnv nestExp
          @ [A.ANMERGEPOINT {label = mergeLabel,
                             varList = resultVars,
                             leaveHandler = NONE,
                             loc = loc}]
          @ transformExp env nextExp
        end
*)
      | C.CAMERGE resultVars =>
        let
          val (mergeLabel, mergePointVars) =
              case #mergePoint env of
                SOME x => x
              | NONE => raise Control.Bug ("transformExp: CAMERGE" ^ (VarID.toString (#id (List.hd resultVars))))
          val (env, decls) =
              ListPair.foldrEq
                (fn (mergePointVar, mergeVar, (env, decls)) =>
                    if VarID.eq (#id mergePointVar, #id mergeVar)
                    then (env, decls)
                    else
                      let
                        val (env, var) = bindVar env A.LOCAL mergePointVar
                        val mergeVar = lookupVar env mergeVar
                      in
                        (env, A.ANVAL {varList = [var],
                                       exp = A.ANVALUE (A.ANVAR mergeVar),
                                       loc = Loc.noloc} :: decls)
                      end)
                (env, nil)
                (mergePointVars, resultVars)
        in
          decls @
          [A.ANMERGE {label = mergeLabel,
                      varList = map (lookupVar env) mergePointVars,
                      loc = Loc.noloc}]
        end
      | C.CARETURN {resultVars, funTy, loc} =>
        let
          val (argTyList, resultTyList) = decomposeFunTy env funTy
          val resultValues = map C.BAVAR resultVars
          val (dec1, valueList) = transformValueList env resultValues
        in
          dec1 @
          [if AnnotatedTypesUtils.isLocalFunTy funTy
           then A.ANLOCALRETURN {valueList = valueList,
                                 tyList = resultTyList,
                                 loc = loc,
                                 knownDestinations = ref nil}
           else A.ANRETURN {valueList = valueList,
                            tyList = resultTyList,
                            loc = loc}]
        end
      | C.CATAILAPPM {funExp, funTy, argExpList, loc} =>
        let
          val (argTyList, resultTyList) = decomposeFunTy env funTy
          val (dec1, funExp) = transformValue env funExp
          val (dec2, argList) = transformValueList env argExpList
        in
          dec1 @ dec2 @
          [if AnnotatedTypesUtils.isLocalFunTy funTy
           then A.ANTAILLOCALCALL {codeLabel = funExp,
                                   argList = argList,
                                   argTyList = argTyList,
                                   resultTyList = resultTyList,
                                   loc = loc,
                                   knownDestinations = ref nil}
           else A.ANTAILAPPLY {closure = funExp,
                               argList = argList,
                               argTyList = argTyList,
                               resultTyList = resultTyList,
                               loc = loc}]
        end
      | C.CARAISE {argExp, loc} =>
        let
          val (dec1, value) = transformValue env argExp
        in
          dec1 @ [A.ANRAISE {value = value, loc = loc}]
        end
      | C.CASWITCH {resultVars, switch as {loc,...}, nextExp} =>
        let
          val mergeLabel = VarID.generate ()
          val nestEnv = setMergePoint (env, mergeLabel, resultVars)
          val dec1 = transformSwitch nestEnv switch
          val (env, resultVars) = bindVarList env A.LOCAL resultVars
        in
          dec1 @
          [A.ANMERGEPOINT {label = mergeLabel,
                           varList = resultVars,
                           leaveHandler = NONE,
                           loc = loc}]
          @ transformExp env nextExp
        end
      | C.CATAILSWITCH switch =>
        transformSwitch env switch
      | C.CAPOLY {resultVars, btvEnv, expTyWithoutTAbs, exp, nextExp, loc} =>
        let
          val mergeLabel = VarID.generate ()
          val nestEnv = setMergePoint (env, mergeLabel, resultVars)
          val nestEnv = bindTyvars (nestEnv, btvEnv)
          val (env, resultVars) = bindVarList env A.LOCAL resultVars
        in
          transformExp nestEnv exp
          @ [A.ANMERGEPOINT {label = mergeLabel,
                             varList = resultVars,
                             leaveHandler = NONE,
                             loc = loc}]
          @ transformExp env nextExp
        end

  and transformSwitch env ({switchExp, expTy, branches, defaultExp, loc}
                           :C.switch) =
      let
          val (dec1, value) = transformValue env switchExp
          val branches =
              map (fn {constant, branchExp} =>
                      {constant = A.ANCONST constant,
                       branch = transformExp env branchExp})
                  branches
          val default = transformExp env defaultExp
      in
        dec1 @
        [A.ANSWITCH {value = value,
                     valueTy = transformTy env expTy,
                     branches = branches,
                     default = default,
                     loc = loc}]
      end

  fun transformTopConst ({const, castTy}:C.topconst) =
      raise Fail "FIXME"

  val toUInt32 = Word32.fromLarge : LargeWord.word -> BasicTypes.UInt32

  fun difference (nil, z) = [z : LargeWord.word]
    | difference ([x], z) = [z - x]
    | difference (h1::h::t, z) = (h - h1) :: difference (h::t, z)


  fun tagArgs (argVarList, frameBits) =
      let
        val args =
            List.mapPartial
              (fn v as {ty,...}:C.varInfo =>
                  case ty of
                    T.SINGLETONty (T.TAGty (T.BOUNDVARty tid)) => SOME (tid, v)
                  | _ => NONE)
              argVarList
      in
        foldr (fn (tid, (boundVars, boundTids, freeTids)) =>
                  case List.find (fn (t,v) => t = tid) args of
                    NONE => (boundVars, boundTids, tid::freeTids)
                  | SOME (_, v) => (v::boundVars, tid::boundTids, freeTids))
              (nil, nil, nil)
              frameBits
      end

(*
  fun transformFreeVars env nil = (env, nil)
    | transformFreeVars env ({var, bindExp}::binds) =
      let
        val anexp =
            case bindExp of
              C.CACLOSURE {codeId, nextExp=C.CAMERGE _, ...} =>
              A.ANRECCLOSURE {funLabel = A.ANLABEL codeId}
            | C.CAVAL {boundExp=C.BASELECT {indexExp,resultTy,resultSize,...},
                       nextExp=C.CAMERGE _, ...} =>
              (case transformValue env resultSize of
                 (nil, size) =>
                 A.ANENVACC {nestLevel = 0w0,
                             offset = toWord indexExp,
                             size = size,
                             ty = transformTy env resultTy}
               | _ => raise Control.Bug "transformFreeVars")
            | _ => raise Control.Bug "transformFreeVars"
        val (env, var) = bindVar env A.LOCAL var
        val (env, binds) = transformFreeVars env binds
      in
        (env, (var, anexp)::binds)
      end

  fun transformBitmapFree (binds, bitmaps) =
      case bitmaps of
        nil => A.ANVALUE (A.ANWORD 0w0)
      | _::_::_ => raise Control.Bug "transformBitmapFree"
      | (x:A.varInfo)::nil =>
        case List.find (fn ({id,...}:A.varInfo,_) => id = #id x) binds of
          NONE => raise Control.Bug "transformBitmapFree"
        | SOME (_,exp) => exp

  fun pairToVAL loc (var, exp) =
      A.ANVAL {varList = [var],
               exp = exp,
               loc = loc}
*)

  fun searchEnvAcc (nil, vid) =
      raise Control.Bug ("searchEnvAcc: " ^ VarID.toString vid)
    | searchEnvAcc (decl::decls, vid) =
      case decl of
        A.ANVAL {varList = [v],
                 exp as A.ANENVACC {nestLevel, offset, size, ty}, ...} =>
        if #id v = vid
        then A.ANENVACC {nestLevel = 0w0, offset = offset,
                         size = size, ty = A.UINT}
        else searchEnvAcc (decls, vid)
      | _ => searchEnvAcc (decls, vid)

  fun transformBitmapFree (decls, [value]) =
      (case value of
         C.BACONST (C.BACONSTANT (CT.WORD n)) => A.ANVALUE (A.ANWORD n)
       | C.BACONST _ => raise Control.Bug "toWord: CONST"
       | C.BAVAR {id,...} => (searchEnvAcc (decls, id) handle e => raise e)
       | C.BACAST {exp, expTy, targetTy} =>
         transformBitmapFree (decls, [exp])
       | C.BATAPP {exp, expTy, instTyList} =>
         transformBitmapFree (decls, [exp]))
    | transformBitmapFree (decls, nil) = A.ANVALUE (A.ANWORD 0w0)
    | transformBitmapFree _ = raise Control.Bug "transformBitmapFree"

  fun transformTopdec batopdec =
      case batopdec of
        C.CAFUNCTION {codeId, path, btvEnv, freeTyvars, bodyTy, attributes,
                      closureEnvArg,
                      argVarList, frameBitmapExp, frameBitmaps,
                      frameBitmapBits,
                      outerFrameBitmap=(freeBitmapTids, freeBitmapVars),
                      bodyExp, annotation, loc} =>
        let
          val resultTyList = map (transformTy emptyEnv) (flattenTy bodyTy)
          val env = newEnv closureEnvArg
          val env = bindTyvars (env, freeTyvars)
          val (boundTags, boundTyvars, freeTids) =
              tagArgs (argVarList, frameBitmapBits)
          val (freeBitmapTids, freeBitmapVars) =
              case freeTids of
                nil => (nil, nil)
              | _::_ => (freeBitmapTids, freeBitmapVars)
          val tyvars = boundTyvars @ freeBitmapTids
          val (env, argVarList) = bindVarList env A.ARG argVarList
          val boundTags = map (lookupVar env) boundTags
          local
            val mergeLabel = VarID.generate ()
            val nestEnv = setMergePoint (env, mergeLabel, frameBitmaps)
          in
          val (env, frameBitmaps) = bindVarList env A.LOCAL frameBitmaps
          val body =
              transformExp nestEnv frameBitmapExp
              @ [A.ANMERGEPOINT {label = mergeLabel,
                                 varList = frameBitmaps,
                                 leaveHandler = NONE,
                                 loc = loc}]
              @ transformExp env bodyExp
          end
          val bitmapFree = transformBitmapFree (body, freeBitmapVars)
                           handle e => raise e
        in
          [A.ANCLUSTER {clusterId = ClusterID.generate (),
                        frameInfo = {tyvars = tyvars,
                                     bitmapFree = bitmapFree,
                                     tagArgList = boundTags},
                        entryFunctions =
                          [{codeId = codeId,
                            argVarList = argVarList,
                            body = body,
                            resultTyList = resultTyList,
                            ffiAttributes = attributes,
                            loc = loc}],
                        hasClosureEnv = isSome closureEnvArg,
                        loc = loc}]
        end
      | C.CARECFUNCTION {closureEnvArg, freeTyvars, frameBitmapExp,
                         frameBitmaps, frameBitmapBits, functions, loc} =>
        let
          val env = newEnv closureEnvArg
          val env = bindTyvars (env, freeTyvars)
          local
            val mergeLabel = VarID.generate ()
            val nestEnv = setMergePoint (env, mergeLabel, frameBitmaps)
          in
          val body1 = transformExp nestEnv frameBitmapExp
          end
          val frameBitmaps = map (fn v => C.BAVAR v) frameBitmaps
          val bitmapFree = transformBitmapFree (body1, frameBitmaps)
                           handle e => raise e
          val functions =
              map
                (fn {codeId, path, argVarList, funTy, bodyExp, annotation,
                     loc} =>
                    let
                      val (argTyList, resultTyList) = decomposeFunTy env funTy
                      val (env, argVarList) = bindVarList env A.ARG argVarList
                      val body = transformExp env bodyExp
                    in
                      {codeId = codeId,
                       argVarList = argVarList,
                       body = body,
                       resultTyList = resultTyList,
                       ffiAttributes = NONE,
                       loc = loc}
                    end)
                functions
        in
          [A.ANCLUSTER {clusterId = ClusterID.generate (),
                        frameInfo = {tyvars = frameBitmapBits,
                                     bitmapFree = bitmapFree,
                                     tagArgList = nil},
                        entryFunctions = functions,
                        hasClosureEnv = isSome closureEnvArg,
                        loc = loc}]
        end
      | C.CATOPCONST {id, constant} =>
        [A.ANTOPCONST {globalName = A.TOP_LOCAL id,
                       constant = transformTopConst constant}]
      | C.CATOPRECORD {id, bitmaps, totalSize, fieldList, isMutable} =>
        let
          fun unzip nil = (nil, nil, nil)
            | unzip ({fieldConst, fieldTy, fieldIndex}::t) =
              let val (l1, l2, l3) = unzip t
              in (fieldConst::l1, fieldTy::l2, fieldIndex::l3)
              end
          val (fieldList, fieldTyList, fieldIndexList) = unzip fieldList
          val fieldSizeList = difference (fieldIndexList, totalSize)
        in
          [A.ANTOPRECORD {globalName = A.TOP_LOCAL id,
                          bitmaps = map toUInt32 bitmaps,
                          totalSize = toUInt32 totalSize,
                          fieldList = map transformTopConst fieldList,
                          fieldTyList = map (transformTy emptyEnv) fieldTyList,
                          fieldSizeList = map toUInt32 fieldSizeList,
                          isMutable = isMutable}]
        end
      | C.CATOPCLOSURE {id, codeId, closureEnv, closureLayout} =>
        [A.ANTOPCLOSURE {globalName = A.TOP_LOCAL id,
                         funLabel = codeId,
                         closureEnv = case closureEnv of
                                        NONE => A.ANNULLBOXED
                                      | SOME v => transformTopConst v}]
      | C.CATOPARRAY {id, numElements,
                      initialValues, elementTy, elementSize, elementTag,
                      isMutable} =>
        [A.ANTOPARRAY {globalName = A.TOP_LOCAL id,
                       bitmap = toUInt32 elementTag,
                       totalSize = toUInt32 (elementSize * numElements),
                       initialValues = map transformTopConst initialValues,
                       elementTy = transformTy emptyEnv elementTy,
                       elementSize = toUInt32 elementSize,
                       isMutable = isMutable}]
      | C.CATOPVAR {path, initialValue, elementTy, elementSize} =>
        [A.ANTOPVAR
           {globalName =
              A.TOP_GLOBAL (NameMangle.mangle {path=path, ty=elementTy}),
            initialValue = Option.map transformTopConst initialValue,
            elementTy = transformTy emptyEnv elementTy,
            elementSize = toUInt32 elementSize}]
      | C.CAEXTERNVAR _ => nil
      | C.CATOPLEVEL caexp =>
        let
          val clusterId = ClusterID.generate ()
          val codeId = VarID.generate ()
          val body = transformExp emptyEnv caexp
        in
          [
            A.ANCLUSTER {clusterId = clusterId,
                         frameInfo = {tyvars = nil,
                                      bitmapFree = A.ANVALUE (A.ANWORD 0w0),
                                      tagArgList = nil}:A.frameInfo,
                         entryFunctions =
                           [{codeId = codeId,
                             argVarList = nil,
                             body = transformExp emptyEnv caexp,
                             resultTyList = nil,
                             ffiAttributes = SOME Absyn.defaultFFIAttributes,
                             loc = Loc.noloc}:A.funDecl],
                         hasClosureEnv = false,
                         loc = Loc.noloc},
            A.ANENTERTOPLEVEL codeId
          ]
        end

  fun transform topdecs =
      List.concat (map transformTopdec topdecs)




(*



  fun transform {clusters, toplevelExp} =
      let
        val clusters = map transformCluster clusters
        val toplevel = transformExp emptyEnv toplevelExp
        val toplevelLabel = VarID.generate ()
        val toplevelCluster =
            {
              clusterId = ClusterID.generate (),
              frameInfo =
                {
                  tyvars = [],
                  bitmapFree = A.ANVALUE (A.ANWORD 0w0),
                  tagArgList = []
                },
              entryFunctions =
                [{
                   codeId = toplevelLabel,
                   argVarList = [],
                   body = toplevel,
                   resultTyList = [],
                   ffiAttributes = SOME Absyn.defaultFFIAttributes,
                   loc = Loc.noloc
                 }],
              hasClosureEnv = false,
              loc = Loc.noloc
            } : A.clusterDecl
      in
        map A.ANCLUSTER clusters
        @ [A.ANCLUSTER toplevelCluster,
           A.ANENTERTOPLEVEL toplevelLabel]
      end

*)

end
