

structure MachineCodeRename : sig

  val rename : MachineCode.topdec list * MachineCode.toplevel
               -> MachineCode.topdec list * MachineCode.toplevel

end =
struct

  structure M = MachineCode

  val usedVarIds = ref VarID.Set.empty
  val usedLabels = ref FunLocalLabel.Set.empty
  val usedHandlers = ref HandlerLabel.Set.empty

  fun freshVarId id =
      if VarID.Set.member (!usedVarIds, id)
      then VarID.generate ()
      else (usedVarIds := VarID.Set.add (!usedVarIds, id); id)

  fun freshLabel id =
      if FunLocalLabel.Set.member (!usedLabels, id)
      then FunLocalLabel.generate nil
      else (usedLabels := FunLocalLabel.Set.add (!usedLabels, id); id)

  fun freshHandler id =
      if HandlerLabel.Set.member (!usedHandlers, id)
      then HandlerLabel.generate nil
      else (usedHandlers := HandlerLabel.Set.add (!usedHandlers, id); id)

  fun initUsedIds () =
      (usedVarIds := VarID.Set.empty;
       usedLabels := FunLocalLabel.Set.empty;
       usedHandlers := HandlerLabel.Set.empty)

  type subst =
      {varSubst : VarID.id VarID.Map.map,
       labelSubst : FunLocalLabel.id FunLocalLabel.Map.map,
       handlerSubst : HandlerLabel.id HandlerLabel.Map.map}

  val emptySubst =
      {varSubst = VarID.Map.empty,
       labelSubst = FunLocalLabel.Map.empty,
       handlerSubst = HandlerLabel.Map.empty} : subst

  fun bindVar ({varSubst, labelSubst, handlerSubst}:subst)
              (var as {id,ty}:M.varInfo) =
      let
        val newId = freshVarId id
      in
        ({id=newId, ty=ty},
         {varSubst = VarID.Map.insert (varSubst, id, newId),
          labelSubst = labelSubst,
          handlerSubst = handlerSubst} : subst)
      end

  fun bindLabel ({varSubst, labelSubst, handlerSubst}:subst) id =
      let
        val newId = freshLabel id
      in
        (newId,
         {varSubst = varSubst,
          labelSubst = FunLocalLabel.Map.insert (labelSubst, id, newId),
          handlerSubst = handlerSubst}
         : subst)
      end

  fun bindHandler ({varSubst, labelSubst, handlerSubst}:subst) id =
      let
        val newId = freshHandler id
      in
        (newId,
         {varSubst = varSubst,
          labelSubst = labelSubst,
          handlerSubst = HandlerLabel.Map.insert (handlerSubst, id, newId)}
         : subst)
      end

  fun bindHandlerOption subst NONE = (NONE, subst)
    | bindHandlerOption subst (SOME label) =
      let
        val (label, subst) = bindHandler subst label
      in
        (SOME label, subst)
      end

  fun bindVarOption subst NONE = (NONE, subst)
    | bindVarOption subst (SOME var) =
      let
        val (var, subst) = bindVar subst var
      in
        (SOME var, subst)
      end

  fun bindVarList subst nil = (nil, subst)
    | bindVarList subst (var::vars) =
      let
        val (var, subst) = bindVar subst var
        val (vars, subst) = bindVarList subst vars
      in
        (var::vars, subst)
      end

  fun bindLabelList subst nil = (nil, subst)
    | bindLabelList subst (label::labels) =
      let
        val (label, subst) = bindLabel subst label
        val (labels, subst) = bindLabelList subst labels
      in
        (label::labels, subst)
      end

  fun renameLabel ({labelSubst,...}:subst) label =
      case FunLocalLabel.Map.find (labelSubst, label) of
        NONE => raise Bug.Bug "renameLabel"
      | SOME id => id

  fun renameHandler _ NONE = NONE
    | renameHandler ({handlerSubst,...}:subst) (SOME label) =
      case HandlerLabel.Map.find (handlerSubst, label) of
        NONE => raise Bug.Bug "renameHandler"
      | SOME id => SOME id

  fun renameValue (subst as {varSubst,...}:subst) value =
      case value of
        M.ANCONST _ => value
      | M.ANBOTTOM => value
      | M.ANCAST {exp, expTy, targetTy} =>
        M.ANCAST {exp = renameValue subst exp, expTy = expTy,
                  targetTy = targetTy}
      | M.ANVAR {id, ty} =>
        case VarID.Map.find (varSubst, id) of
          NONE => raise Bug.Bug ("renameValue " ^ VarID.toString id)
        | SOME id => M.ANVAR {id=id, ty=ty}

  fun renameObjType subst objtype =
      case objtype of
        M.OBJTYPE_VECTOR value => M.OBJTYPE_VECTOR (renameValue subst value)
      | M.OBJTYPE_ARRAY value => M.OBJTYPE_ARRAY (renameValue subst value)
      | M.OBJTYPE_UNBOXED_VECTOR => M.OBJTYPE_UNBOXED_VECTOR
      | M.OBJTYPE_RECORD => M.OBJTYPE_RECORD
      | M.OBJTYPE_INTINF => M.OBJTYPE_INTINF

  fun renameAddress subst addr =
      case addr of
        M.MAPTR ptrExp =>
        M.MAPTR (renameValue subst ptrExp)
      | M.MAPACKED base =>
        M.MAPACKED (renameValue subst base)
      | M.MAOFFSET {base, offset} =>
        M.MAOFFSET {base = renameValue subst base,
                    offset = renameValue subst offset}
      | M.MARECORDFIELD {recordExp, fieldIndex} =>
        M.MARECORDFIELD
          {recordExp = renameValue subst recordExp,
           fieldIndex = renameValue subst fieldIndex}
      | M.MAARRAYELEM {arrayExp, elemSize, elemIndex} =>
        M.MAARRAYELEM
          {arrayExp = renameValue subst arrayExp,
           elemSize = elemSize,
           elemIndex = renameValue subst elemIndex}

  fun renameMid subst mid =
      case mid of
        M.MCINTINF {resultVar, dataLabel, loc} =>
        let
          val (resultVar, subst) = bindVar subst resultVar
        in
          (M.MCINTINF {dataLabel = dataLabel,
                       resultVar = resultVar,
                       loc = loc},
           subst)
        end
      | M.MCFOREIGNAPPLY {resultVar, funExp, attributes, argExpList,
                          handler, loc} =>
        let
          val funExp = renameValue subst funExp
          val argExpList = map (renameValue subst) argExpList
          val (resultVar, subst) =
              case resultVar of
                SOME var =>
                let
                  val (var, subst) = bindVar subst var
                in
                  (SOME var, subst)
                end
              | NONE => (NONE, subst)
        in
          (M.MCFOREIGNAPPLY {funExp = funExp,
                             attributes = attributes,
                             argExpList = argExpList,
                             resultVar = resultVar,
                             handler = renameHandler subst handler,
                             loc = loc},
           subst)
        end
      | M.MCEXPORTCALLBACK {resultVar, codeExp, closureEnvExp, instTyvars,
                            loc} =>
        let
          val codeExp = renameValue subst codeExp
          val clsoureEnvExp = renameValue subst closureEnvExp
          val (resultVar, subst) = bindVar subst resultVar
        in
          (M.MCEXPORTCALLBACK {codeExp = codeExp,
                               closureEnvExp = closureEnvExp,
                               instTyvars = instTyvars,
                               resultVar = resultVar,
                               loc = loc},
           subst)
        end
      | M.MCEXVAR {resultVar, id, loc} =>
        let
          val (resultVar, subst) = bindVar subst resultVar
        in
          (M.MCEXVAR {id = id,
                      resultVar = resultVar,
                      loc = loc},
           subst)
        end
      | M.MCMEMCPY_FIELD {dstAddr, srcAddr, copySize, loc} =>
        (M.MCMEMCPY_FIELD {dstAddr = renameAddress subst dstAddr,
                           srcAddr = renameAddress subst srcAddr,
                           copySize = renameValue subst copySize,
                           loc = loc},
         subst)
      | M.MCMEMMOVE_UNBOXED_ARRAY {dstAddr, srcAddr, numElems, elemSize, loc} =>
        (M.MCMEMMOVE_UNBOXED_ARRAY {dstAddr = renameAddress subst dstAddr,
                                    srcAddr = renameAddress subst srcAddr,
                                    numElems = renameValue subst numElems,
                                    elemSize = renameValue subst elemSize,
                                    loc = loc},
         subst)
      | M.MCMEMMOVE_BOXED_ARRAY {dstArray, srcArray, dstIndex, srcIndex,
                                 numElems, loc} =>
        (M.MCMEMMOVE_BOXED_ARRAY {dstArray = renameValue subst dstArray,
                                  srcArray = renameValue subst srcArray,
                                  dstIndex = renameValue subst dstIndex,
                                  srcIndex = renameValue subst srcIndex,
                                  numElems = renameValue subst numElems,
                                  loc = loc},
         subst)
      | M.MCALLOC {resultVar, allocSize, payloadSize, objType, loc} =>
        let
          val allocSize = renameValue subst allocSize
          val payloadSize = renameValue subst payloadSize
          val objType = renameObjType subst objType
          val (resultVar, subst) = bindVar subst resultVar
        in
          (M.MCALLOC {objType = objType,
                      payloadSize = payloadSize,
                      allocSize = allocSize,
                      resultVar = resultVar,
                      loc = loc},
           subst)
        end
      | M.MCALLOC_COMPLETED =>
        (M.MCALLOC_COMPLETED, subst)
      | M.MCCHECK {handler} =>
        (M.MCCHECK {handler = renameHandler subst handler},
         subst)
      | M.MCRECORDDUP_ALLOC {resultVar, copySizeVar, recordExp, loc} =>
        let
          val recordExp = renameValue subst recordExp
          val (resultVar, subst) = bindVar subst resultVar
          val (copySizeVar, subst) = bindVar subst copySizeVar
        in
          (M.MCRECORDDUP_ALLOC {resultVar = resultVar,
                                copySizeVar = copySizeVar,
                                recordExp = recordExp,
                                loc = loc},
           subst)
        end
      | M.MCRECORDDUP_COPY {dstRecord, srcRecord, copySize, loc} =>
        let
          val dstRecord = renameValue subst dstRecord
          val srcRecord = renameValue subst srcRecord
          val copySize = renameValue subst copySize
        in
          (M.MCRECORDDUP_COPY {dstRecord = dstRecord,
                               srcRecord = srcRecord,
                               copySize = copySize,
                               loc = loc},
           subst)
        end
      | M.MCBZERO {recordExp, recordSize, loc} =>
        (M.MCBZERO {recordExp = renameValue subst recordExp,
                    recordSize = renameValue subst recordSize,
                    loc = loc},
         subst)
      | M.MCSAVESLOT {slotId, value, loc} =>
        (M.MCSAVESLOT {slotId = slotId,
                       value = renameValue subst value,
                       loc = loc},
         subst)
      | M.MCLOADSLOT {resultVar, slotId, loc} =>
        let
          val (resultVar, subst) = bindVar subst resultVar
        in
          (M.MCLOADSLOT {resultVar = resultVar,
                         slotId = slotId,
                         loc = loc},
           subst)
        end
      | M.MCLOAD {resultVar, srcAddr, loc} =>
        let
          val srcAddr = renameAddress subst srcAddr
          val (resultVar, subst) = bindVar subst resultVar
        in
          (M.MCLOAD {srcAddr = srcAddr,
                     resultVar = resultVar,
                     loc = loc},
           subst)
        end
      | M.MCPRIMAPPLY {resultVar, primInfo, argExpList, instTyList, argTyList,
                       resultTy, instTagList, instSizeList, loc} =>
        let
          val argExpList = map (renameValue subst) argExpList
          val instTagList = map (renameValue subst) instTagList
          val instSizeList = map (renameValue subst) instSizeList
          val (resultVar, subst) = bindVar subst resultVar
        in
          (M.MCPRIMAPPLY {primInfo = primInfo,
                          argExpList = argExpList,
                          argTyList = argTyList,
                          resultTy = resultTy,
                          instTyList = instTyList,
                          instTagList = instTagList,
                          instSizeList = instSizeList,
                          resultVar = resultVar,
                          loc = loc},
           subst)
        end
      | M.MCBITCAST {resultVar, exp, expTy, targetTy, loc} =>
        let
          val exp = renameValue subst exp
          val (resultVar, subst) = bindVar subst resultVar
        in
          (M.MCBITCAST {resultVar = resultVar,
                        exp = exp,
                        expTy = expTy,
                        targetTy = targetTy,
                        loc = loc},
           subst)
        end
      | M.MCCALL {resultVar, resultTy, codeExp, closureEnvExp, instTyList,
                  argExpList, tail, handler, loc} =>
        let
          val codeExp = renameValue subst codeExp
          val closureEnvExp = Option.map (renameValue subst) closureEnvExp
          val argExpList = map (renameValue subst) argExpList
          val (resultVar, subst) = bindVarOption subst resultVar
        in
          (M.MCCALL {codeExp = codeExp,
                     closureEnvExp = closureEnvExp,
                     instTyList = instTyList,
                     argExpList = argExpList,
                     resultVar = resultVar,
                     resultTy = resultTy,
                     tail = tail,
                     handler = renameHandler subst handler,
                     loc = loc},
           subst)
        end
      | M.MCSTORE {srcExp, srcTy, dstAddr, barrier, loc} =>
        (M.MCSTORE {srcExp = renameValue subst srcExp,
                    srcTy = srcTy,
                    dstAddr = renameAddress subst dstAddr,
                    barrier = barrier,
                    loc = loc},
         subst)
      | M.MCEXPORTVAR {id, ty, valueExp, loc} =>
        (M.MCEXPORTVAR {id = id,
                        ty = ty,
                        valueExp = renameValue subst valueExp,
                        loc = loc},
         subst)
      | M.MCKEEPALIVE {value, loc} =>
        (M.MCKEEPALIVE {value = renameValue subst value,
                        loc = loc},
         subst)

  fun renameMidList subst nil = (nil, subst)
    | renameMidList subst (mid::mids) =
      let
        val (mid, subst) = renameMid subst mid
        val (mids, subst) = renameMidList subst mids
      in
        (mid::mids, subst)
      end

  fun renameLast subst last =
      case last of
        M.MCRETURN {value, loc} =>
        M.MCRETURN {value = renameValue subst value,
                    loc = loc}
      | M.MCRAISE {argExp, cleanup, loc} =>
        M.MCRAISE {argExp = renameValue subst argExp,
                   cleanup = renameHandler subst cleanup,
                   loc = loc}
      | M.MCHANDLER {nextExp, id, exnVar, handlerExp, cleanup, loc} =>
        let
          val (id, subst2) = bindHandler subst id
          val nextExp = renameExp subst2 nextExp
          val (exnVar, subst) = bindVar subst exnVar
          val handlerExp = renameExp subst handlerExp
        in
          M.MCHANDLER {nextExp = nextExp,
                       id = id,
                       exnVar = exnVar,
                       handlerExp = handlerExp,
                       cleanup = renameHandler subst cleanup,
                       loc = loc}
        end
      | M.MCSWITCH {switchExp, expTy, branches, default, loc} =>
        M.MCSWITCH {switchExp = renameValue subst switchExp,
                    expTy = expTy,
                    branches = branches,
                    default = default,
                    loc = loc}
      | M.MCGOTO {id, argList, loc} =>
        M.MCGOTO {id = renameLabel subst id,
                  argList = map (renameValue subst) argList,
                  loc = loc}
      | M.MCLOCALCODE {recursive, binds, nextExp, loc} =>
        let
          val labels = map #id binds
          val (labels, subst2) = bindLabelList subst labels
          val nextExp = renameExp subst2 nextExp
          val subst3 = if recursive then subst2 else subst
          val binds =
              ListPair.mapEq
                (fn (id, {id = _, argVarList, bodyExp}) =>
                    let
                      val (argVarList, subst4) = bindVarList subst3 argVarList
                    in
                      {id = id,
                       argVarList = argVarList,
                       bodyExp = renameExp subst4 bodyExp}
                    end)
                (labels, binds)
        in
          M.MCLOCALCODE {recursive = recursive,
                         binds = binds,
                         nextExp = nextExp,
                         loc = loc}
        end
      | M.MCUNREACHABLE =>
        M.MCUNREACHABLE

  and renameExp subst ((mids, last):M.mcexp) =
      let
        val (mids, subst) = renameMidList subst mids
        val last = renameLast subst last
      in
        (mids, last) : M.mcexp
      end

  fun renameTopdec topdec =
      case topdec of
        M.MTFUNCTION {id, tyvarKindEnv, tyArgs, argVarList, closureEnvVar,
                      frameSlots, bodyExp, retTy, gcCheck, loc} =>
        let
          val (argVarList, subst) = bindVarList emptySubst argVarList
          val (closureEnvVar, subst) = bindVarOption subst closureEnvVar
          val bodyExp = renameExp subst bodyExp
        in
          M.MTFUNCTION
            {id = id,
             tyvarKindEnv = tyvarKindEnv,
             tyArgs = tyArgs,
             argVarList = argVarList,
             closureEnvVar = closureEnvVar,
             frameSlots = frameSlots,
             bodyExp = bodyExp,
             retTy = retTy,
             gcCheck = gcCheck,
             loc = loc}
        end
      | M.MTCALLBACKFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
                              frameSlots, bodyExp, attributes, retTy,
                              cleanupHandler, loc} =>
        let
          val (argVarList, subst) = bindVarList emptySubst argVarList
          val (closureEnvVar, subst) = bindVarOption subst closureEnvVar
          val (cleanupHandler, subst) = bindHandlerOption subst cleanupHandler
          val bodyExp = renameExp subst bodyExp
        in
          M.MTCALLBACKFUNCTION
            {id = id,
             tyvarKindEnv = tyvarKindEnv,
             argVarList = argVarList,
             closureEnvVar = closureEnvVar,
             frameSlots = frameSlots,
             bodyExp = bodyExp,
             attributes = attributes,
             retTy = retTy,
             cleanupHandler = cleanupHandler,
             loc = loc}
        end

  fun renameToplevel {frameSlots, bodyExp, cleanupHandler} =
      let
        val (cleanupHandler, subst) =
            bindHandlerOption emptySubst cleanupHandler
      in
        {frameSlots = frameSlots,
         bodyExp = renameExp subst bodyExp,
         cleanupHandler = cleanupHandler} : M.toplevel
      end

  fun rename (topdecs, toplevel) =
      (initUsedIds ();
       (map renameTopdec topdecs, renameToplevel toplevel))

end
