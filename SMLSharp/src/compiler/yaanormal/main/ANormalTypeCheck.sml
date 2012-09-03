(**
 * type checker for A-Normal.
 * @copyright (c) 2008, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: ANormalTypeCheck.sml,v 1.5 2008/08/06 17:23:41 ohori Exp $
 *)
structure YAANormalTypeCheck : sig

  val typecheck : YAANormal.clusterDecl list -> UserError.errorInfo list

end =
struct

  structure AN = YAANormal
  structure CT = ConstantTerm
  structure E = ANormalTypeCheckError

  val errorQueue = UserError.createQueue ()
  fun initErrorQueue () = UserError.clearQueue errorQueue
  fun getDiagnoses () = UserError.getDiagnoses errorQueue
  val error = UserError.enqueueDiagnosis errorQueue

  datatype position = TOP | LOCALCODE | BRANCH

  type context =
      {
        position: position,
        resultTyList: AN.ty list,
        varEnv: AN.varInfo VarID.Map.map,
        codeEnv: AN.codeDecl VarID.Map.map,
        funEnv: AN.funDecl VarID.Map.map,
        mergePointEnv: AN.varInfo list VarID.Map.map,
        globalEnv: (AN.ty * AN.anvalue) ExVarID.Map.map
      }

  fun setPosition (context:context) position =
      {
        position = position,
        resultTyList = #resultTyList context,
        varEnv = #varEnv context,
        codeEnv = #codeEnv context,
        funEnv = #funEnv context,
        mergePointEnv = #mergePointEnv context,
        globalEnv = #globalEnv context
      } : context

  fun setResultTyList (context:context) resultTyList =
      {
        position = #position context,
        resultTyList = resultTyList,
        varEnv = #varEnv context,
        codeEnv = #codeEnv context,
        funEnv = #funEnv context,
        mergePointEnv = #mergePointEnv context,
        globalEnv = #globalEnv context
      } : context

  fun addVar (context as {varEnv,...}:context)
             (varInfo as {id,...}:AN.varInfo) =
      {
        position = #position context,
        resultTyList = #resultTyList context,
        varEnv = VarID.Map.insert (varEnv, id, varInfo),
        codeEnv = #codeEnv context,
        funEnv = #funEnv context,
        mergePointEnv = #mergePointEnv context,
        globalEnv = #globalEnv context
      } : context

  fun addVarList context varInfoList =
      foldl (fn (varInfo, context) => addVar context varInfo)
            context varInfoList

  fun addCode (context as {codeEnv,...}:context)
              (codeDecl as {codeId,...}:AN.codeDecl) =
      {
        position = #position context,
        resultTyList = #resultTyList context,
        varEnv = #varEnv context,
        codeEnv = VarID.Map.insert (codeEnv, codeId, codeDecl),
        funEnv = #funEnv context,
        mergePointEnv = #mergePointEnv context,
        globalEnv = #globalEnv context
      } : context

  fun addCodeList context codeDeclList =
      foldl (fn (codeDecl, context) => addCode context codeDecl)
            context codeDeclList

  fun addMergePoint (context as {mergePointEnv,...}:context)
                    {label, varList, leaveHandler, loc} =
      {
        position = #position context,
        resultTyList = #resultTyList context,
        varEnv = #varEnv context,
        codeEnv = #codeEnv context,
        funEnv = #funEnv context,
        mergePointEnv = VarID.Map.insert (mergePointEnv, label, varList),
        globalEnv = #globalEnv context
      } : context

  fun addMergePointList context MergePointList =
      foldl (fn (MergePoint, context) => addMergePoint context MergePoint)
            context MergePointList

  fun addGlobal (context as {globalEnv,...}:context) id ty size =
      {
        position = #position context,
        resultTyList = #resultTyList context,
        varEnv = #varEnv context,
        codeEnv = #codeEnv context,
        funEnv = #funEnv context,
        mergePointEnv = #mergePointEnv context,
        globalEnv = ExVarID.Map.insert (globalEnv, id, (ty, size))
      } : context

  fun eqList eq (nil, nil) = true
    | eqList eq (h1::t1, h2::t2) = eq (h1, h2) andalso eqList eq (t1, t2)
    | eqList eq (nil, l1) = false
    | eqList eq (l2, nil) = false

  fun eqTy (ty1, ty2) =
      case (ty1, ty2) of
        (AN.UINT, AN.UINT) => true
      | (AN.SINT, AN.SINT) => true
      | (AN.BYTE, AN.BYTE) => true
      | (AN.CHAR, AN.CHAR) => true
      | (AN.BOXED, AN.BOXED) => true
      | (AN.POINTER, AN.POINTER) => true
      | (AN.FUNENTRY, AN.FUNENTRY) => true
      | (AN.CODEPOINT, AN.CODEPOINT) => true
      | (AN.FOREIGNFUN, AN.FOREIGNFUN) => true
      | (AN.FLOAT, AN.FLOAT) => true
      | (AN.DOUBLE, AN.DOUBLE) => true
      | (AN.PAD, AN.PAD) => true
      | (AN.SIZE, AN.SIZE) => true
      | (AN.INDEX, AN.INDEX) => true
      | (AN.BITMAP, AN.BITMAP) => true
      | (AN.OFFSET, AN.OFFSET) => true
      | (AN.TAG, AN.TAG) => true
      | (AN.DOUBLEty, AN.DOUBLEty) => true
      | (AN.ATOMty, AN.ATOMty) => true
      | (AN.SINGLEty tid1, AN.SINGLEty tid2) => tid1 = tid2
      | (AN.UNBOXEDty tid1, AN.UNBOXEDty tid2) => tid1 = tid2
      | (AN.GENERIC tid1, AN.GENERIC tid2) => tid1 = tid2
      | (AN.UINT, _) => false
      | (AN.SINT, _) => false
      | (AN.BYTE, _) => false
      | (AN.CHAR, _) => false
      | (AN.BOXED, _) => false
      | (AN.POINTER, _) => false
      | (AN.FUNENTRY, _) => false
      | (AN.CODEPOINT, _) => false
      | (AN.FOREIGNFUN, _) => false
      | (AN.FLOAT, _) => false
      | (AN.DOUBLE, _) => false
      | (AN.PAD, _) => false
      | (AN.SIZE, _) => false
      | (AN.INDEX, _) => false
      | (AN.BITMAP, _) => false
      | (AN.OFFSET, _) => false
      | (AN.TAG, _) => false
      | (AN.DOUBLEty, _) => false
      | (AN.ATOMty, _) => false
      | (AN.SINGLEty _, _) => false
      | (AN.UNBOXEDty _, _) => false
      | (AN.GENERIC _, _) => false

  val eqTyList = eqList eqTy

  fun eqKind (kind1, kind2) =
      case (kind1, kind2) of
        (AN.ARG, AN.ARG) => true
      | (AN.LOCALARG, AN.LOCALARG) => true
      | (AN.LOCAL, AN.LOCAL) => true
      | (AN.ARG, _) => false
      | (AN.LOCALARG, _) => false
      | (AN.LOCAL, _) => false

  fun eqKindAll kind kindList =
      List.all (fn k => eqKind (k, kind)) kindList

  fun eqVar ({id=id1,ty=ty1,varKind=kind1,displayName=_}:AN.varInfo,
             {id=id2,ty=ty2,varKind=kind2,displayName=_}:AN.varInfo) =
      VarID.compare (id1, id2) = EQUAL
      andalso eqTy (ty1, ty2) andalso eqKind (kind1, kind2)

  val eqVarList = eqList eqVar

  fun eqSize (v1, v2) =
      case (v1, v2) of
        (AN.ANWORD c1, AN.ANWORD c2) => c1 = c2
      | (AN.ANVAR v1, AN.ANVAR v2) => eqVar (v1, v2)
      | _ => false

  fun checkArgTys loc msg (actualTyList, argTyList) =
      if eqTyList (actualTyList, argTyList) then ()
      else error (loc, msg, E.ArgTyListAndActualTyListMismatch
                                {argTyList = argTyList,
                                 actualTyList = actualTyList})

  fun checkOperandTyList loc msg (operandTyList, operatorTyList) =
      if eqTyList (operandTyList, operatorTyList) then ()
      else error (loc, msg, E.OperatorOperandMismatch
                                {operatorTyList = operatorTyList,
                                 operandTyList = operandTyList})

  fun checkResultTyList loc msg (context:context) actualTyList =
      if eqTyList (actualTyList, #resultTyList context) then ()
      else error (loc, msg, E.ResultTyListAndActualTyListMismatch
                                {resultTyList = #resultTyList context,
                                 actualTyList = actualTyList})

  fun checkKnownDestinations loc msg knownDestinations =
      case knownDestinations of
        nil => ()
      | _::_ => error (loc, msg,
                       E.KnownDestinationsMustBeNil
                           {knownDestinations = knownDestinations})

  fun typecheckConst const =
      case const of
        CT.INT _ => AN.UINT
      | CT.LARGEINT _ => AN.BOXED
      | CT.WORD _ => AN.UINT
      | CT.BYTE _ => AN.BYTE
      | CT.STRING _ => AN.BOXED
      | CT.REAL _ => AN.DOUBLE
      | CT.FLOAT _ => AN.FLOAT
      | CT.CHAR _ => AN.CHAR
      | CT.UNIT => AN.UINT
      | CT.NULL => AN.POINTER

  fun typecheckValue (context:context) loc anvalue =
      case anvalue of
        AN.ANINT _ => AN.SINT
      | AN.ANWORD _ => AN.UINT
      | AN.ANBYTE _ => AN.BYTE
      | AN.ANCHAR _ => AN.CHAR
      | AN.ANUNIT => AN.UINT
      | AN.ANGLOBALSYMBOL {ty,...} => ty
      | AN.ANVAR (varInfo as {id,ty,...}) =>
        (
          case VarID.Map.find (#varEnv context, id) of
            SOME v =>
            if eqVar (varInfo, v) then ()
            else error (loc, "typecheckValue 2",
                        E.VarMismatch {definition = v, reference = varInfo})
          | NONE => error (loc, "typecheckValue 3", E.VarNotFound varInfo);
          ty
        )
      | AN.ANLABEL codeId =>
        (
          case VarID.Map.find (#funEnv context, codeId) of
            SOME _ => ()
          | NONE => error (loc, "typecheckValue 4", E.FunNotFound codeId);
          AN.FUNENTRY
        )
      | AN.ANLOCALCODE codeId =>
        (
          case VarID.Map.find (#codeEnv context, codeId) of
            SOME _ => ()
          | NONE => error (loc, "typecheckValue 5", E.CodeNotFound codeId);
          AN.CODEPOINT
        )

  fun typecheckExp context loc anexp =
      case anexp of
        AN.ANVALUE anvalue =>
        [typecheckValue context loc anvalue]

      | AN.ANCONST const =>
        [typecheckConst const]

      | AN.ANFOREIGNAPPLY {function, argList, argTyList, resultTyList,
                           attributes} =>
        let
          val argTys = map (typecheckValue context loc) argList
        in
          checkArgTys loc "typecheckExp 1" (argTys, argTyList);
          resultTyList
        end

      | AN.ANCALLBACKCLOSURE {funLabel, env,
                              argTyList, resultTyList, attributes} =>
        let
          val funLabelTy = typecheckValue context loc funLabel
          val envTy = typecheckValue context loc env
        in
          checkOperandTyList loc "typecheckExp 2"
              ([funLabelTy, envTy], [AN.FUNENTRY, AN.BOXED]);
          [AN.POINTER]
        end

      | AN.ANENVACC {nestLevel, offset, size, ty} =>
        let
          val sizeTy = typecheckValue context loc size
        in
          checkOperandTyList loc "typecheckExp 5" ([sizeTy], [AN.SIZE]);
          [ty]
        end

      | AN.ANGETFIELD {array, offset, size, ty, needBoundaryCheck} =>
        let
          val arrayTy = typecheckValue context loc array
          val offsetTy = typecheckValue context loc offset
          val sizeTy = typecheckValue context loc size
        in
          checkOperandTyList loc "typecheckExp 6"
             ([arrayTy, offsetTy, sizeTy],
              [AN.BOXED, AN.OFFSET, AN.SIZE]);
          [ty]
        end

      | AN.ANARRAY {bitmap, totalSize, initialValue, elementTy, elementSize,
                    isMutable} =>
        let
          val bitmapTy = typecheckValue context loc bitmap
          val totalSizeTy = typecheckValue context loc totalSize
          val initialValueTy = typecheckValue context loc initialValue
          val elementSizeTy = typecheckValue context loc elementSize
        in
          checkOperandTyList loc "typecheckExp 7"
              ([bitmapTy, totalSizeTy, initialValueTy, elementSizeTy],
               [AN.BITMAP, AN.OFFSET, elementTy, AN.SIZE]);
          [AN.BOXED]
        end

      | AN.ANRECORD {bitmap, totalSize, fieldList, fieldSizeList,
                     fieldTyList} =>
        let
          val bitmapTy = typecheckValue context loc bitmap
          val totalSizeTy = typecheckValue context loc totalSize
          val fieldTys = map (typecheckValue context loc) fieldList
          val fieldSizeTys = map (typecheckValue context loc) fieldSizeList
          val expectFieldSizeTys = map (fn _ => AN.SIZE) fieldList
        in
          checkOperandTyList loc "typecheckExp 8"
              ([bitmapTy, totalSizeTy] @ fieldTys @ fieldSizeTys,
               [AN.BITMAP, AN.OFFSET] @ fieldTyList @ expectFieldSizeTys);
          [AN.BOXED]
        end

      | AN.ANENVRECORD {bitmap, totalSize, fieldList, fieldSizeList,
                        fieldTyList, fixedSizeList} =>
        let
          val bitmapTy = typecheckValue context loc bitmap
          val fieldTys = map (typecheckValue context loc) fieldList
          val fieldSizeTys = map (typecheckValue context loc) fieldSizeList
          val expectFieldSizeTys = map (fn _ => AN.SIZE) fieldList
        in
          checkOperandTyList loc "typecheckExp 9"
              ([bitmapTy] @ fieldTys @ fieldSizeTys,
               [AN.BITMAP] @ fieldTyList @ expectFieldSizeTys);
          [AN.BOXED]
        end

      | AN.ANSELECT {record, nestLevel, offset, size, ty} =>
        let
          val recordTy = typecheckValue context loc record
          val nestLevelTy = typecheckValue context loc nestLevel
          val offsetTy = typecheckValue context loc offset
          val sizeTy = typecheckValue context loc size
        in
          checkOperandTyList loc "typecheckExp 10"
              ([recordTy, nestLevelTy, offsetTy, sizeTy],
               [AN.BOXED, AN.OFFSET, AN.OFFSET, AN.SIZE]);
          [ty]
        end

      | AN.ANMODIFY {record, nestLevel, offset, value, valueTy, valueSize,
                     valueTag} =>
        let
          val recordTy = typecheckValue context loc record
          val nestLevelTy = typecheckValue context loc nestLevel
          val offsetTy = typecheckValue context loc offset
          val valueTy' = typecheckValue context loc value
          val valueSizeTy = typecheckValue context loc valueSize
          val valueTagTy = typecheckValue context loc valueTag
        in
          checkOperandTyList loc "typecheckExp 11"
              ([recordTy, nestLevelTy, offsetTy, valueTy', valueSizeTy,
                valueTagTy],
               [AN.BOXED, AN.OFFSET, AN.OFFSET, valueTy, AN.SIZE, AN.TAG]);
          [AN.BOXED]
        end

      | AN.ANPRIMAPPLY {prim, argList, argTyList, resultTyList,
                        instSizeList, instTagList} =>
        let
          val argTys = map (typecheckValue context loc) argList
          val instSizeTys = map (typecheckValue context loc) instSizeList
          val instTagTys = map (typecheckValue context loc) instTagList
        in
          checkArgTys loc "typecheckExp 12" (argTys, argTyList);
          checkOperandTyList loc "typecheckExp 13"
              (instSizeTys @ instTagTys,
               map (fn _ => AN.SIZE) instSizeTys
               @ map (fn _ => AN.TAG) instTagTys);
          if length instSizeList = length instTagList then ()
          else error (loc, "typecheckExp 14",
                      E.PrimApplyNumInstMismatch
                          {numInstSize = length instSizeList,
                           numInstTag = length instTagList});
          resultTyList
        end

      | AN.ANCLOSURE {funLabel, env} =>
        let
          val funLabelTy = typecheckValue context loc funLabel
          val envTy = typecheckValue context loc env
        in
          checkOperandTyList loc "typecheckExp 15"
              ([funLabelTy, envTy], [AN.FUNENTRY, AN.BOXED]);
          [AN.BOXED]
        end

      | AN.ANRECCLOSURE {funLabel} =>
        let
          val funLabelTy = typecheckValue context loc funLabel
        in
          checkOperandTyList loc "typecheckExp 16" ([funLabelTy], [AN.FUNENTRY]);
          [AN.BOXED]
        end

      | AN.ANAPPLY {closure, argList, argTyList, argSizeList, resultTyList} =>
        let
          (* argSizeList is only for YASIGenerator. no check here. *)
          val closureTy = typecheckValue context loc closure
          val argTys = map (typecheckValue context loc) argList
        in
          checkOperandTyList loc "typecheckExp 17" ([closureTy], [AN.BOXED]);
          checkArgTys loc "typecheckExp 18" (argTys, argTyList);
          resultTyList
        end

      | AN.ANCALL {funLabel, env, argList, argSizeList, argTyList,
                   resultTyList} =>
        let
          (* argSizeList is only for YASIGenerator. no check here. *)
          val funLabelTy = typecheckValue context loc funLabel
          val envTy = typecheckValue context loc env
          val argTys = map (typecheckValue context loc) argList
        in
          checkOperandTyList loc "typecheckExp 19"
              ([funLabelTy, envTy], [AN.FUNENTRY, AN.BOXED]);
          checkArgTys loc "typecheckExp 20" (argTys, argTyList);
          resultTyList
        end

      | AN.ANRECCALL {funLabel, argList, argSizeList, argTyList,
                      resultTyList} =>
        let
          (* argSizeList is only for YASIGenerator. no check here. *)
          val funLabelTy = typecheckValue context loc funLabel
          val argTys = map (typecheckValue context loc) argList
        in
          checkOperandTyList loc "typecheckExp 21"
                             ([funLabelTy], [AN.FUNENTRY]);
          checkArgTys loc "typecheckExp 22" (argTys, argTyList);
          resultTyList
        end

      | AN.ANLOCALCALL {codeLabel, argList, argSizeList, argTyList,
                        resultTyList, returnLabel, knownDestinations} =>
        let
          (* argSizeList is only for YASIGenerator. no check here. *)
          val codeLabelTy = typecheckValue context loc codeLabel
          val argTys = map (typecheckValue context loc) argList
        in
          checkOperandTyList loc "typecheckExp 23"
                             ([codeLabelTy], [AN.CODEPOINT]);
          checkArgTys loc "typecheckExp 24" (argTys, argTyList);
          checkKnownDestinations loc "typecheckExp 25" (!knownDestinations);
          resultTyList
        end

  fun splitMergePoint context andeclList =
      let
        fun split l ((decl as AN.ANMERGEPOINT m) :: decls) =
            let
              val mergePoints = split [decl] decls
              val body = rev l
              val definedMerges =
                  List.mapPartial (fn (_, AN.ANMERGEPOINT m::_) => SOME m
                                    | _ => NONE)
                                  mergePoints
              val context =
                  addMergePointList context definedMerges
            in
              (context, body) :: mergePoints
            end
          | split l (decl::decls) = split (decl::l) decls
          | split nil nil = nil
          | split l nil = [(context, rev l)]
      in
        split nil andeclList
      end

  fun typecheckDecl context andecl =
      case andecl of
        AN.ANSETFIELD {array, offset, value, valueTy, valueSize, valueTag,
                       needBoundaryCheck, loc} =>
        let
          val arrayTy = typecheckValue context loc array
          val offsetTy = typecheckValue context loc offset
          val valueTy' = typecheckValue context loc value
          val valueSizeTy = typecheckValue context loc valueSize
          val valueTagTy = typecheckValue context loc valueTag
        in
          checkOperandTyList loc "typecheckDecl 2"
              ([arrayTy, offsetTy, valueTy', valueSizeTy, valueTagTy],
               [AN.BOXED, AN.OFFSET, valueTy, AN.SIZE, AN.TAG]);
          SOME context
        end

      | AN.ANSETTAIL {record, nestLevel, offset, value, valueTy, valueSize,
                      valueTag, loc} =>
        let
          val recordTy = typecheckValue context loc record
          val nestLevelTy = typecheckValue context loc nestLevel
          val offsetTy = typecheckValue context loc offset
          val valueTy' = typecheckValue context loc value
          val valueSizeTy = typecheckValue context loc valueSize
          val valueTagTy = typecheckValue context loc valueTag
        in
          checkOperandTyList loc "typecheckDecl 3"
              ([recordTy, nestLevelTy, offsetTy, valueTy', valueSizeTy,
                valueTagTy],
               [AN.BOXED, AN.OFFSET, AN.OFFSET, valueTy, AN.SIZE, AN.TAG]);
          SOME context
        end

      | AN.ANCOPYARRAY {src, srcOffset, dst, dstOffset, length, elementTy,
                        elementSize, elementTag, loc} =>
        let
          val srcTy = typecheckValue context loc src
          val srcOffsetTy = typecheckValue context loc srcOffset
          val dstTy = typecheckValue context loc dst
          val dstOffsetTy = typecheckValue context loc dstOffset
          val lengthTy = typecheckValue context loc length
          val elementSizeTy = typecheckValue context loc elementSize
          val elementTagTy = typecheckValue context loc elementTag
        in
          checkOperandTyList loc "typecheckDecl 4"
              ([srcTy, srcOffsetTy, dstTy, dstOffsetTy, lengthTy,
                elementSizeTy, elementTagTy],
               [AN.BOXED, AN.OFFSET, AN.BOXED, AN.OFFSET, AN.OFFSET,
                AN.SIZE, AN.TAG]);
          SOME context
        end

      | AN.ANTAILAPPLY {closure, argList, argTyList, argSizeList,
                        resultTyList, loc} =>
        let
          (* argSizeList is only for YASIGenerator. no check here. *)
          val closureTy = typecheckValue context loc closure
          val argTys = map (typecheckValue context loc) argList
        in
          checkOperandTyList loc "typecheckDecl 5" ([closureTy], [AN.BOXED]);
          checkArgTys loc "typecheckDecl 6" (argTys, argTyList);
          checkResultTyList loc "typecheckDecl 7" context resultTyList;
          NONE
        end

      | AN.ANTAILCALL {funLabel, env, argList, argSizeList, argTyList,
                       resultTyList, loc} =>
        let
          (* argSizeList is only for YASIGenerator. no check here. *)
          val funLabelTy = typecheckValue context loc funLabel
          val envTy = typecheckValue context loc env
          val argTys = map (typecheckValue context loc) argList
        in
          checkOperandTyList loc "typecheckDecl 8"
              ([funLabelTy, envTy], [AN.FUNENTRY, AN.BOXED]);
          checkArgTys loc "typecheckDecl 9" (argTys, argTyList);
          checkResultTyList loc "typecheckDecl 10" context resultTyList;
          NONE
        end

      | AN.ANTAILRECCALL {funLabel, argList, argSizeList, argTyList,
                          resultTyList, loc} =>
        let
          (* argSizeList is only for YASIGenerator. no check here. *)
          val funLabelTy = typecheckValue context loc funLabel
          val argTys = map (typecheckValue context loc) argList
        in
          checkOperandTyList loc "typecheckDecl 11"
                             ([funLabelTy], [AN.FUNENTRY]);
          checkArgTys loc "typecheckDecl 12" (argTys, argTyList);
          checkResultTyList loc "typecheckDecl 13" context resultTyList;
          NONE
        end

      | AN.ANTAILLOCALCALL {codeLabel, argList, argSizeList, argTyList,
                            resultTyList, loc, knownDestinations} =>
        let
          (* argSizeList is only for YASIGenerator. no check here. *)
          val codeLabelTy = typecheckValue context loc codeLabel
          val argTys = map (typecheckValue context loc) argList
        in
          checkOperandTyList loc "typecheckDecl 14"
                             ([codeLabelTy], [AN.CODEPOINT]);
          checkArgTys loc "typecheckDecl 15" (argTys, argTyList);
          checkResultTyList loc "typecheckDecl 16" context resultTyList;
          checkKnownDestinations loc "typecheckExp 17" (!knownDestinations);
          NONE
        end

      | AN.ANRETURN {valueList, tyList, sizeList, loc} =>
        let
          (* sizeList is only for YASIGenerator. no check here. *)
          val valueTys = map (typecheckValue context loc) valueList
        in
          checkOperandTyList loc "typecheckDecl 18" (valueTys, tyList);
          checkResultTyList loc "typecheckDecl 19" context tyList;
          NONE
        end

      | AN.ANLOCALRETURN {valueList, tyList, sizeList, loc,
                          knownDestinations} =>
        let
          (* sizeList is only for YASIGenerator. no check here. *)
          val valueTys = map (typecheckValue context loc) valueList
        in
          checkOperandTyList loc "typecheckDecl 20" (valueTys, tyList);
          checkResultTyList loc "typecheckDecl 21" context tyList;
          checkKnownDestinations loc "typecheckExp 22" (!knownDestinations);
          if #position context = LOCALCODE then ()
          else error (loc, "typecheckDecl 23", E.LocalReturnIsNotInLocalCode);
          NONE
        end

      | AN.ANVAL {varList, sizeList, exp, loc} =>
        let
          (* sizeList is only for YASIGenerator. no check here. *)
          val expTy = typecheckExp context loc exp

          val () =
              if eqKindAll AN.LOCAL (map #varKind varList) then ()
              else error (loc, "typecheckDecl 24",
                          E.LocalVarIsNotLocal {varList = varList})
          val () =
              checkOperandTyList loc "typecheckDecl 25" (expTy, map #ty varList)

          val context = addVarList context varList
        in
          SOME context
        end

      | AN.ANVALCODE {codeList, loc} =>
        let
          val context = addCodeList context codeList
        in
          app (typecheckCodeDecl context) codeList;
          SOME context
        end

      | AN.ANMERGE {label, varList, loc} =>
        let
          val _ = map (typecheckValue context loc) (map AN.ANVAR varList)
        in
          case VarID.Map.find (#mergePointEnv context, label) of
            NONE => error (loc, "typecheckDecl 26", E.MergePointNotFound label)
          | SOME vars =>
            if eqVarList (varList, vars) then ()
            else error (loc, "typecheckDecl 27",
                        E.MergeAndMergePointMismatch
                           {label = label,
                            mergeVarList = varList,
                            mergePointVarList = vars});
          NONE
        end

      | AN.ANMERGEPOINT {label, varList, leaveHandler, loc} =>
        let
          val () =
              if #position context = TOP then ()
              else error (loc, "typecheckDecl 28", E.MergePointIsNotInTop label)
          val () =
              if eqKindAll AN.LOCAL (map #varKind varList) then ()
              else error (loc, "typecheckDecl 29",
                          E.MergePointArgIsNotLocal {label = label,
                                                     varList = varList})

          val context = addVarList context varList
        in
          SOME context
        end

      | AN.ANRAISE {value, loc} =>
        let
          val valueTy = typecheckValue context loc value
        in
          checkOperandTyList loc "typecheckDecl 30" ([valueTy], [AN.BOXED]);
          NONE
        end

      | AN.ANHANDLE {try, exnVar, handler, labels, loc} =>
        let
          val () =
              if eqKind (#varKind exnVar, AN.LOCAL) then ()
              else error (loc, "typecheckDecl 31", E.ExnVarIsNotLocal exnVar)

          val context = setPosition context BRANCH
          val () = typecheckDeclList context loc try

          val context = addVar context exnVar
          val () = typecheckDeclList context loc handler
        in
          NONE
        end

      | AN.ANSWITCH {value, valueTy, branches, default, loc} =>
        let
          val valueTy' = typecheckValue context loc value
          val () = checkOperandTyList loc "typecheckDecl 32"
                                      ([valueTy'], [valueTy])

          val context = setPosition context BRANCH
          val _ =
              app (fn {constant, branch} =>
                      let
                        val constTy = typecheckValue context loc value
                        val () = checkOperandTyList loc "typecheckDecl 33"
                                                    ([constTy], [valueTy])
                      in
                        case constant of
                          AN.ANCONST _ => ()
                        | AN.ANVALUE (AN.ANGLOBALSYMBOL _) => ()
                        | _ =>
                          error (loc, "typecheckDecl 34",
                                 E.InvalidExpression constant);
                        typecheckDeclList context loc branch
                      end)
                  branches

          val () = typecheckDeclList context loc default
        in
          NONE
        end

  and typecheckDeclList context loc andeclList =
      let
        val mergePoints = splitMergePoint context andeclList
      in
        app
          (fn (context, decls) =>
              let
                val context =
                    foldl
                      (fn (decl, NONE) =>
                          (error (YAANormalUtils.getLoc decl,
                                  "typecheckDeclList 1", E.DeadCode);
                           NONE)
                        | (decl, SOME context) => typecheckDecl context decl)
                      (SOME context)
                      decls
              in
                case context of
                  SOME _ => error (loc, "typecheckDeclList 2", E.NoTermination)
                | NONE => ()
              end)
          mergePoints
      end

  and typecheckCodeDecl context
                        ({codeId, argVarList, argSizeList, body, resultTyList,
                          loc}:AN.codeDecl) =
      let
        (* argSizeList is for YASIGenerator. no check here. *)
        val _ =
            if eqKindAll AN.LOCALARG (map #varKind argVarList) then ()
            else error (loc, "typecheckCodeDecl 1",
                        E.CodeDeclArgIsNotLocalArg {label = codeId,
                                                    varList = argVarList})

        val context = setResultTyList context resultTyList
        val context = addVarList context argVarList
        val context = setPosition context LOCALCODE
      in
        typecheckDeclList context loc body
      end

  fun typecheckFunDecl context
                       ({codeId, argVarList, argSizeList, body, resultTyList,
                         ffiAttributes, loc}:AN.funDecl) =
      let
        (* argSizeList is for YASIGenerator. no check here. *)
        val _ =
            if eqKindAll AN.ARG (map #varKind argVarList) then ()
            else error (loc, "typecheckFunDecl 1",
                        E.FunDeclArgIsNotArg {label = codeId,
                                              varList = argVarList})

        val context = setResultTyList context resultTyList
        val context = addVarList context argVarList
        val context = setPosition context TOP
      in
        typecheckDeclList context loc body
      end

  fun typecheckFrameInfo context
                         ({tyvars, bitmapFree, tagArgList}:AN.frameInfo) loc =
      (
        case bitmapFree of
          AN.ANVALUE (AN.ANWORD 0w0) => ()
        | AN.ANENVACC {nestLevel = 0w0, offset,
                       size = AN.ANWORD _,
                       ty = AN.BITMAP} => ()
        | _ => error (loc, "typecheckFrameInfo 1",
                      E.InvalidExpression bitmapFree);
        app
          (fn varInfo =>
              let
                val ty = typecheckValue context loc (AN.ANVAR varInfo)
              in
                if eqTy (ty, AN.TAG) then ()
                else error (loc, "typecheckFrameInfo 1",
                            E.InvalidTagArg varInfo)
              end)
          tagArgList
      )

  fun typecheckCluster context
                       ({clusterId, frameInfo, entryFunctions, hasClosureEnv,
                         loc}:AN.clusterDecl) =
      let
        (* FIXME: semantics of tagArg *)
        val context' =
            foldl (fn ({argVarList,...}, context') =>
                      addVarList context' argVarList)
                  context entryFunctions
        val _ = typecheckFrameInfo context' frameInfo loc

        val codeDecls = map YAANormalUtils.funDeclToCodeDecl entryFunctions
        val context = addCodeList context codeDecls
      in
        app (typecheckFunDecl context) entryFunctions
      end

  fun typecheck clusters =
      let
        val funEnv =
            foldl (fn ({entryFunctions,...}, funEnv) =>
                      foldl (fn (funDecl as {codeId,...}, funEnv) =>
                                VarID.Map.insert (funEnv, codeId, funDecl))
                            funEnv
                            entryFunctions)
                  VarID.Map.empty
                  clusters

        val context =
            {
              position = TOP,
              resultTyList = nil,  (* dummy *)
              varEnv = VarID.Map.empty,
              codeEnv = VarID.Map.empty,
              funEnv = funEnv,
              mergePointEnv = VarID.Map.empty,
              globalEnv = ExVarID.Map.empty
            } : context
      in
        app (typecheckCluster context) clusters;
        getDiagnoses ()
      end

end
