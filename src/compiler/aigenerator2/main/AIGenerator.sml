(**
 * abstract instruction generator version 2
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: AIGenerator.sml,v 1.27 2008/12/10 11:37:21 katsu Exp $
 *)
structure AIGenerator2 : AIGENERATOR2 =
struct

  structure AbstractInstruction = AbstractInstruction2

  structure ID = VarID
  structure CT = ConstantTerm
  structure AN = YAANormal
  structure AI = AbstractInstruction
  structure Target = AI.Target
  structure CA = CallAnalysis

  fun newLocalId () = VarID.generate()

  (* FIXME: nested block; adjust with RBUTransformation *)
  val nestedBlockIndex = AI.UInt 0w0

  (* FIXME: platform dependent *)
  fun sizeOfBoxed () = if Control.nativeGen() then 0w4 else 0w1 : Target.uint
  fun sizeOfEntry () = if Control.nativeGen() then 0w4 else 0w1 : Target.uint
  fun sizeOfFloat () = if Control.nativeGen() then 0w4 else 0w1 : Target.uint
  fun sizeOfDouble () = if Control.nativeGen() then 0w8 else 0w2 : Target.uint

  val SubscriptExceptionTag = AI.Extern ("sml_exntag_Subscript", AI.BOXED)
  val DivExceptionTag = AI.Extern ("sml_exntag_Div", AI.BOXED)
  val SizeExceptionTag = AI.Extern ("sml_exntag_Size", AI.BOXED)
  val arrayMaxLen = 0x01ffffff

  fun newArg (ty, argKind) =
      {id = newLocalId (), ty = ty, argKind = argKind} : AI.argInfo

  fun newVar ty =
      let
        val id = newLocalId ()
        val displayName = "$" ^ ID.toString id
      in
        {id = id,
         ty = ty,
         displayName = displayName} : AI.varInfo
       end

  val newLabel = newLocalId

  fun newANVarInfo anty varKind =
      let
        val id = newLocalId ()
      in
        {id = id,
         displayName = "$" ^ ID.toString id,
         ty = anty,
         varKind = varKind} : AN.varInfo
      end

  fun onlyOne [x] = x
    | onlyOne _ = raise Control.Bug "onlyOne"

  (*********************************************************************)

  (*
   * Unless there is a variable of specified type in the variable list,
   * create a fresh variable and add to the list.
   *)
  fun ensureVars (varInfo::varList) (anty::tyList) =
      if #ty varInfo = anty
      then varInfo :: ensureVars varList tyList
      else varInfo :: ensureVars varList (anty::tyList)
    | ensureVars nil tyList =
      map (fn anty => newANVarInfo anty AN.LOCAL) tyList
    | ensureVars varList nil =
      varList

  (*
   * Pick up a sequence of local variables of specified types from
   * variable list.
   *)
  fun pickupVars ((varInfo:AN.varInfo)::varList) (anty::tyList) =
      if #ty varInfo = anty
      then varInfo :: pickupVars varList tyList
      else pickupVars varList (anty::tyList)
    | pickupVars varList nil = nil
    | pickupVars nil tyList = raise Control.Bug "pickupVars"

  (*********************************************************************)

  type routineInfo =
       {
         codeId: AI.label,
         body: AN.andecl list,
         argVarList: AN.varInfo list,
         resultTyList: AN.ty list,
         ffiAttributes: AN.ffiAttributes option,
         loc: AI.loc,
         (* variables for holding arguments *)
         paramVars: AN.varInfo list,
         (* variable which holds a return address of LOCALRETURN *)
         linkVar: AN.varInfo option,
         (* informations of entry blocks *)
         initialHandlers: AI.label option list,
         funEntry: AI.label option,
         codeEntry: AI.label option,
         selfLoopEntry: AI.label option,
         selfBackEntry: AI.label option
       }

  type context =
       {
         raiseDivLabel: AI.label option,
         raiseSizeLabel: AI.label option,
         boundaryCheckFailedLabel: AI.label option,
         envVar: AI.varInfo option,
         linkVar: AI.varInfo,
(*
         linkArg: AI.argInfo,
*)
         funIdMap: AI.clusterId ID.Map.map,      (* functionId -> clusterId *)
(*
         genericTys: AI.genericTyRep IEnv.map,        (* tid -> genTyRep *)
*)
         routineInfoMap: routineInfo ID.Map.map, (* routineInfo table *)
         (* paramMap for each routine *)
         paramMapMap: AI.value ID.Map.map ID.Map.map,
         passVars: AN.varInfo list,              (* vars for passing values *)
         constants: AI.data ID.Map.map           (* constant table *)
       }

  type environment =
       {
         routineLabel: AI.label,                 (* current code label *)
         paramMap: AI.value ID.Map.map,          (* param -> value *)
         handler: AI.handler                     (* exception handler *)
       }

  fun addConst (context as {constants, ...}:context) const =
      let
        val constid = newLocalId ()
      in
        ({
           raiseDivLabel = #raiseDivLabel context,
           raiseSizeLabel = #raiseSizeLabel context,
           boundaryCheckFailedLabel = #boundaryCheckFailedLabel context,
           envVar = #envVar context,
           linkVar = #linkVar context,
           funIdMap = #funIdMap context,
           routineInfoMap = #routineInfoMap context,
           paramMapMap = #paramMapMap context,
           passVars = #passVars context,
           constants = ID.Map.insert (constants, constid, const)
         } : context,
         constid)
      end

  fun getClusterId (context as {funIdMap, ...}:context) label =
      case ID.Map.find (funIdMap, label) of
        SOME clusterId => clusterId
      | NONE => raise Control.Bug ("getClusterId: " ^ ID.toString label)

  fun getRoutineInfo (context as {routineInfoMap, ...}:context) label =
      case ID.Map.find (routineInfoMap, label) of
        SOME routineInfo => routineInfo
      | NONE => raise Control.Bug ("getRoutineInfo: " ^ ID.toString label)

  fun addParamMap (context as {paramMapMap, ...}:context) label paramMap =
      {
        raiseDivLabel = #raiseDivLabel context,
        raiseSizeLabel = #raiseSizeLabel context,
        boundaryCheckFailedLabel = #boundaryCheckFailedLabel context,
        envVar = #envVar context,
        linkVar = #linkVar context,
        funIdMap = #funIdMap context,
(*
        genericTys = #genericTys context,
*)
        routineInfoMap = #routineInfoMap context,
        paramMapMap = ID.Map.insert (paramMapMap, label, paramMap),
        passVars = #passVars context,
        constants = #constants context
      } : context

  fun setBoundaryCheckFailedLabel (context:context) label =
      {
        raiseDivLabel = #raiseDivLabel context,
        raiseSizeLabel = #raiseSizeLabel context,
        boundaryCheckFailedLabel = SOME label,
        envVar = #envVar context,
        linkVar = #linkVar context,
        funIdMap = #funIdMap context,
(*
        genericTys = #genericTys context,
*)
        routineInfoMap = #routineInfoMap context,
        paramMapMap = #paramMapMap context,
        passVars = #passVars context,
        constants = #constants context
      } : context

  fun setRaiseDivLabel (context:context) label =
      {
        raiseDivLabel = SOME label,
        raiseSizeLabel = #raiseSizeLabel context,
        boundaryCheckFailedLabel = #boundaryCheckFailedLabel context,
        envVar = #envVar context,
        linkVar = #linkVar context,
        funIdMap = #funIdMap context,
(*
        genericTys = #genericTys context,
*)
        routineInfoMap = #routineInfoMap context,
        paramMapMap = #paramMapMap context,
        passVars = #passVars context,
        constants = #constants context
      } : context

  fun setRaiseSizeLabel (context:context) label =
      {
        raiseDivLabel = #raiseDivLabel context,
        raiseSizeLabel = SOME label,
        boundaryCheckFailedLabel = #boundaryCheckFailedLabel context,
        envVar = #envVar context,
        linkVar = #linkVar context,
        funIdMap = #funIdMap context,
(*
        genericTys = #genericTys context,
*)
        routineInfoMap = #routineInfoMap context,
        paramMapMap = #paramMapMap context,
        passVars = #passVars context,
        constants = #constants context
      } : context

  fun currentClosureEnv ({envVar,...}:context) =
      case envVar of
        SOME v => AI.Var v
      | NONE => AI.Empty

  (* for debug *)
  fun currentLoc context ({routineLabel, ...}:environment) =
      Control.prettyPrint
          (Loc.format_loc (#loc (getRoutineInfo context routineLabel)))

  fun setHandler (env:environment) handler =
      {
        routineLabel = #routineLabel env,
        paramMap = #paramMap env,
        handler = handler
      } : environment

  (*********************************************************************)

  type code =
       {
         blocks: AI.basicBlock list,          (* generated basic blocks *)
         currentBlock: AI.basicBlock option,  (* header of current block *)
         insns: AI.instruction list list      (* insns in current block *)
       }

  fun getCurrentLabel ({currentBlock = SOME {label, ...}, ...}:code) = label
    | getCurrentLabel _ = raise Control.Bug "getCurrentLabel"

  fun beginBlock (code:code) label blockKind (env:environment) loc =
      (* assert begin *)
      case #currentBlock code of
        SOME {label = opened, ...} =>
        raise Control.Bug ("beginBlock " ^ ID.toString label
                           ^ " in " ^ ID.toString opened)
      | NONE =>
      (* assert end *)
      {
        blocks = #blocks code,
        currentBlock = SOME {label = label,
                             blockKind = blockKind,
                             handler = #handler env,
                             loc = loc,
                             instructionList = nil},   (* dummy *)
        insns = nil
      } : code

  fun closeBlock (code as {currentBlock = SOME currentBlock, ...}:code) =
      let
        val block =
            {
              label = #label currentBlock,
              blockKind = #blockKind currentBlock,
              handler = #handler currentBlock,
              loc = #loc currentBlock,
              instructionList = List.concat (rev (#insns code))
            } : AI.basicBlock
      in
        {
          blocks = block :: #blocks code,
          currentBlock = NONE,
          insns = nil
        } : code
      end
    | closeBlock code =
      (* We need to allow to close closed code.
       * SWITCH or HANDLE at tail position of a function may cause such case.
       *)
      code

  fun addInsn (code:code) insns =
      {
        blocks = #blocks code,
        currentBlock = #currentBlock code,
        insns = insns :: #insns code
      } : code

  fun forceBeginBlock (code:code) label blockKind env loc =
      let
        val code =
            case #currentBlock code of
              NONE => code
            | SOME {label = opened, ...} =>
              let
                val code = addInsn code
                             [
                               AI.Jump {label = AI.Label label,
                                        knownDestinations = [label],
                                        loc = loc}
                             ]
              in
                closeBlock code
              end
      in
        beginBlock code label blockKind env loc
      end

  (*********************************************************************)

  fun transformTy anty =
      case anty of
        AN.UINT => AI.UINT
      | AN.SINT => AI.SINT
      | AN.BYTE => AI.BYTE
      | AN.BOXED => AI.BOXED
      | AN.POINTER => AI.CPOINTER
      | AN.CODEPOINT => AI.CODEPOINTER
      | AN.FUNENTRY => AI.ENTRY
      | AN.FOREIGNFUN => AI.CODEPOINTER
      | AN.FLOAT => AI.FLOAT
      | AN.DOUBLE => AI.DOUBLE
      | AN.GENERIC tid => AI.GENERIC tid

(*
  (*
   * MEMO: Every parameter and local variable should have a fixed size type.
   *)
  fun transformParamInfo (anvarInfo as {id,...}:AN.varInfo) =
      case #varKind anvarInfo of
        AN.ARG =>
        {
          id = id,
          displayName = #displayName anvarInfo,
          ty = transformTy (#ty anvarInfo)
        } : AI.paramInfo
      | AN.LOCALARG =>
        {
          id = id,
          displayName = #displayName anvarInfo,
          ty = transformTy (#ty anvarInfo)
        } : AI.paramInfo
      | AN.LOCAL =>
        raise Control.Bug ("transformParamInfo: LOCAL " ^ ID.toString id)
*)

  fun transformVarInfo (anvarInfo as {id,...}:AN.varInfo) =
      case #varKind anvarInfo of
        AN.LOCAL =>
        {
          id = id,
          displayName = #displayName anvarInfo,
          ty = transformTy (#ty anvarInfo)
        } : AI.varInfo
      | AN.ARG =>
        raise Control.Bug ("transformVarInfo: ARG " ^ ID.toString id)
      | AN.LOCALARG =>
        raise Control.Bug ("transformVarInfo: LOCALARG " ^ ID.toString id)

  fun transformBarrier (value, setGlobal) =
      case (value, setGlobal) of
        (AI.UInt 0w0, _) => AI.NoBarrier
      | (AI.UInt 0w1, false) => AI.WriteBarrier
      | (AI.UInt 0w1, true) => AI.GlobalWriteBarrier
      | (_, false) => AI.BarrierTag value
      | (_, true) => raise Control.Bug "transformBarrier"

  fun transformGlobalRef (name, ty) =
        case (name, ty) of
          (AN.TOP_EXTERN name, AN.FOREIGNFUN) => AI.ExtFunLabel name
        | (AN.TOP_EXTERN name, AN.POINTER) => AI.Extern (name, AI.CPOINTER)
        | (AN.TOP_EXPORT (AN.TOP_GLOBAL name), AN.POINTER) =>
          AI.Global (name, AI.CPOINTER)
        | (AN.TOP_EXTERN name, _) => AI.Extern (name, AI.BOXED)
        | (AN.TOP_EXPORT (AN.TOP_GLOBAL name), _) => AI.Global (name, AI.BOXED)
        | (AN.TOP_EXPORT (AN.TOP_LOCAL id), _) => AI.Const id

  fun getPassVars (context as {passVars, ...}:context) antyList =
      pickupVars passVars antyList

  (*********************************************************************)

  fun unrollNestedBlock env code record (AI.UInt 0w0) loc =
      (code, record)
    | unrollNestedBlock env code record (AI.UInt n) loc =
      let
        val var = newVar AI.BOXED
        val code = addInsn code
                     [
                       AI.Load {dst = var,
                                ty = AI.BOXED,
                                block = record,
                                offset = nestedBlockIndex,
                                size = AI.UInt (sizeOfBoxed ()),
                                loc = loc}
                     ]
      in
        unrollNestedBlock env code (AI.Var var) (AI.UInt (n - 0w1)) loc
      end
    | unrollNestedBlock env code record nestLevel loc =
      let
        val currentLabel = getCurrentLabel code
        val loopLabel = newLabel ()
        val bodyLabel = newLabel ()
        val exitLabel = newLabel ()
        val counterVar = newVar AI.UINT
        val blockVar = newVar AI.BOXED

        val code =
            addInsn code
              [
                (* counter = nestLevel; *)
                AI.Move    {dst = counterVar,
                            ty = AI.UINT,
                            value = nestLevel,
                            loc = loc},
                (* block = record; *)
                AI.Move    {dst = blockVar,
                            ty = AI.BOXED,
                            value = record,
                            loc = loc},
                AI.Jump    {label = AI.Label loopLabel,
                            knownDestinations = [loopLabel],
                            loc = loc}
              ]
        val code = closeBlock code

        val code = beginBlock code loopLabel AI.Loop env loc
        val code =
            addInsn code
              [
                (* while (counter != 0) { *)
                AI.If      {value1 = AI.Var counterVar,
                            value2 = AI.UInt 0w0,
                            op2 = (AI.MonoEqual, AI.UINT, AI.UINT, AI.UINT),
                            thenLabel = exitLabel,
                            elseLabel = bodyLabel,
                            loc = loc}
              ]
        val code = closeBlock code

        val code = beginBlock code bodyLabel AI.Branch env loc
        val code =
            addInsn code
              [
                (*   block = block[nestedBlockIndex]; *)
                AI.Load    {dst = blockVar,
                            ty = AI.BOXED,
                            block = AI.Var blockVar,
                            offset = nestedBlockIndex,
                            size = AI.UInt (sizeOfBoxed ()),
                            loc = loc},
                (*   counter = counter - 1; *)
                AI.PrimOp2 {dst = counterVar,
                            op2 = (AI.Sub, AI.UINT, AI.UINT, AI.UINT),
                            arg1 = AI.Var counterVar,
                            arg2 = AI.UInt 0w1,
                            loc = loc},
                (* } *)
                AI.Jump    {label = AI.Label loopLabel,
                            knownDestinations = [loopLabel],
                            loc = loc}
              ]
        val code = closeBlock code

        val code = beginBlock code exitLabel AI.Branch env loc
      in
        (code, AI.Var blockVar)
      end

  fun initializeArray env code
                      (dst, totalSize, initialValue, elementTy, elementSize,
                       loc) =
      let
        val currentLabel = getCurrentLabel code
        val loopLabel = newLabel ()
        val bodyLabel = newLabel ()
        val exitLabel = newLabel ()

        val counterVar = newVar AI.UINT
        val code =
            addInsn code
              [
                (* counter = 0; *)
                AI.Move   {dst = counterVar,
                           ty = AI.UINT,
                           value = AI.UInt 0w0,
                           loc = loc},
                AI.Jump   {label = AI.Label loopLabel,
                           knownDestinations = [loopLabel],
                           loc = loc}
              ]
        val code = closeBlock code

        val code = beginBlock code loopLabel AI.Loop env loc
        val code =
            addInsn code
              [
                (* while (counter < totalSize) { *)
                AI.If         {value1 = AI.Var counterVar,
                               value2 = totalSize,
                               op2 = (AI.Lt, AI.UINT, AI.UINT, AI.UINT),
                               thenLabel = bodyLabel,
                               elseLabel = exitLabel,
                               loc = loc}
              ]
        val code = closeBlock code

        val code = beginBlock code bodyLabel AI.Branch env loc
        val code =
            addInsn code
              [
                (* update for initialization. barrier is not needed. *)
                (*   dst[counter] = value; *)
                AI.Update     {block = AI.Var dst,
                               offset = AI.Var counterVar,
                               size = elementSize,
                               ty = elementTy,
                               value = initialValue,
                               barrier = AI.NoBarrier,
                               loc = loc},
                (*   counter = counter + elementSize; *)
                AI.PrimOp2    {dst = counterVar,
                               op2 = (AI.Add, AI.UINT, AI.UINT, AI.UINT),
                               arg1 = AI.Var counterVar,
                               arg2 = elementSize,
                               loc = loc},
                (* } *)
                AI.Jump       {label = AI.Label loopLabel,
                               knownDestinations = [loopLabel],
                               loc = loc}
              ]
        val code = closeBlock code
                   
        val code = beginBlock code exitLabel AI.Branch env loc
      in
        code
      end

  fun isNoPad (fieldSizeList, fieldIndexList, totalSize) =
      let
        fun toInt (AI.UInt v1) = SOME v1
          | toInt (AI.SInt v1) = SOME (Target.SIntToUInt v1)
          | toInt _ = NONE
        fun check (total, nil, nil) = toInt totalSize = SOME total
          | check (total, size::sizes, index::indexes) =
            (case (toInt size, toInt index) of
               (SOME size, SOME index) =>
               total = index andalso check (index + size, sizes, indexes)
             | _ => false)
          | check (total, _, _) = raise Control.Bug "isNoPad"
      in
        check (0w0, fieldSizeList, fieldIndexList)
      end

  fun allocRecord (context:context) env code
                  {dst, bitmaps, payloadSize, fieldTyList, fieldSizeList,
                   fieldIndexList, clearPad, loc} =
      let
        val noPad = isNoPad (fieldSizeList, fieldIndexList, payloadSize)
        val zeroClear = if noPad then false else clearPad

        (* optimization: use Vector if every field has same tag. *)
        val (objectType, bitmaps) =
            if Control.nativeGen() then
              case bitmaps of
                [AI.UInt 0w0] => (AI.Vector, bitmaps)
              | _ =>
                if noPad andalso
                   List.all (fn AN.BOXED => true | _ => false) fieldTyList
                then (AI.Vector, [AI.UInt 0w1])
                else (AI.Record {mutable=false}, bitmaps)
            (* workaround for YASIGenerator *)
            else (AI.Record {mutable=false}, bitmaps)

        val code = addInsn code
                     [
                       AI.Alloc {dst = dst,
                                 objectType = objectType,
                                 bitmaps = bitmaps,
                                 payloadSize = payloadSize,
                                 loc = loc}
                     ]
        val code =
            if clearPad andalso not noPad
            then initializeArray
                   env code
                   (dst, payloadSize, AI.UInt 0w0, AI.BYTE, AI.UInt 0w1, loc)
            else code
      in
        code
      end

  (* initializeBlock doesn't generate codes calling barrier. *)
  fun yaInitializeBlock (context:context) code block
                        {antyList, sizeList, indexList, valueList} loc =
      let
        fun initField (code, nil, nil, nil, nil) =
            code
          | initField (code, anty::antys, size::sizes, index::indexes,
                       value::values) =
            let
              val code =
                  addInsn code
                    [
                      AI.Update {block = block,
                                 offset = index,
                                 size = size,
                                 ty = transformTy anty,
                                 value = value,
                                 barrier = AI.NoBarrier,
                                 loc = loc}
                    ]
            in
              initField (code, antys, sizes, indexes, values)
            end
          | initField _ =
            raise Control.Bug "initField"
      in
        initField (code, antyList, sizeList, indexList, valueList)
      end

  fun yaMakeRecord context env code
                   (args as {dst, fieldTyList, fieldSizeList, fieldIndexList,
                             loc, ...})
                   fieldList =
      let
        val code = allocRecord context env code args
        val code = yaInitializeBlock
                       context code (AI.Var dst)
                       {antyList=fieldTyList,
                        sizeList=fieldSizeList,
                        indexList=fieldIndexList,
                        valueList=fieldList}
                       loc
      in
        code
      end

  fun closureLayout () =
      {
        closureBitmap = 0w1 : Target.uint,   (* |BOXED, ENTRY| *)
        closureFieldTys = [AN.BOXED, AN.FUNENTRY],
        closureFieldSizes = [sizeOfBoxed(), sizeOfEntry()],
        closureFieldIndexes = [0w0, sizeOfBoxed()],
        closureSize = sizeOfBoxed() + sizeOfEntry()
      }

  fun makeClosure context env code dst funEntry closureEnv loc =
      let
        val {closureBitmap, closureFieldTys, closureFieldSizes,
             closureFieldIndexes, closureSize} = closureLayout ()
      in
        yaMakeRecord context env code
                     {dst = dst,
                      bitmaps = [AI.UInt closureBitmap],
                      payloadSize = AI.UInt closureSize,
                      fieldTyList = closureFieldTys,
                      fieldSizeList = map AI.UInt closureFieldSizes,
                      fieldIndexList = map AI.UInt closureFieldIndexes,
                      clearPad = false,
                      loc = loc}
                     [closureEnv, funEntry]
      end

  fun expandClosure code closure entry env loc =
      addInsn code
        [
          AI.Load {dst = entry,
                   ty = AI.ENTRY,
                   block = closure,
                   offset = AI.UInt (sizeOfBoxed ()),
                   size = AI.UInt (sizeOfEntry ()),
                   loc = loc},
          AI.Load {dst = env,
                   ty = AI.BOXED,
                   block = closure,
                   offset = AI.UInt 0w0,
                   size = AI.UInt (sizeOfBoxed ()),
                   loc = loc}
        ]

  fun transformIntSwitch caseTy setupSwitch
                         context env code
                         switchValue branchCases defaultLabel loc =
      let
        val branchCases = setupSwitch branchCases

        fun beginBlockIfNeeded code (SOME label) blockKind env loc =
            beginBlock code label blockKind env loc
          | beginBlockIfNeeded code NONE blockKind env loc = code

        fun genCmp (context, code, env, (caseConst, label),
                    blockLabel, leftLabel, rightLabel) =
            let
              val (noneqLabel, compare) =
                  case (leftLabel, rightLabel) of
                    (SOME l, SOME r) => (newLabel (), SOME (l, r))
                  | (SOME l, NONE) => (l, NONE)
                  | (NONE, SOME r) => (r, NONE)
                  | (NONE, NONE) => (defaultLabel, NONE)

              val code = beginBlockIfNeeded code blockLabel AI.Branch env loc
              val code =
                  addInsn code
                    [
                      (* if (switchValue == const) then goto label; *)
                      AI.If {value1 = switchValue,
                             value2 = caseConst,
                             op2 = (AI.MonoEqual, caseTy, caseTy, AI.UINT),
                             thenLabel = label,
                             elseLabel = noneqLabel,
                             loc = loc}
                    ]
              val code = closeBlock code

              val code =
                  case compare of
                    NONE => code
                  | SOME (leftLabel, rightLabel) =>
                    let
                      val code = beginBlock code noneqLabel AI.Branch env loc
                      val code =
                          addInsn code
                            [
                              (*if (switchValue < const) then left else right;*)
                              AI.If {value1 = switchValue,
                                     value2 = caseConst,
                                     op2 = (AI.Lt, caseTy, caseTy, AI.UINT),
                                     thenLabel = leftLabel,
                                     elseLabel = rightLabel,
                                     loc = loc}
                            ]
                      val code = closeBlock code
                    in
                      code
                    end
            in
              (context, code, env, env, env)
            end
      in
        BinarySearchCode.generate genCmp (context, code, env, branchCases)
      end

  fun setupSwitchInt branchCases =
      let
        val cases =
            map (fn (AN.ANCONST (CT.INT n), label, _) =>
                    (Target.toSInt n, label)
                  | _ => raise Control.Bug "setupSwitchInt")
                branchCases
        val cases =
            ListSorter.sort
                (fn ((n1, _), (n2, _)) => Target.SInt.compare (n1, n2))
                cases
      in
        map (fn (x, l) => (AI.SInt x, l)) cases
      end

  fun setupSwitchWord branchCases =
      let
        val cases =
            map (fn (AN.ANCONST (CT.WORD n), label, _) =>
                    (Target.toUInt n, label)
                  | _ => raise Control.Bug "setupSwitchWord")
                branchCases
        val cases =
            ListSorter.sort
                (fn ((n1, _), (n2, _)) => Target.UInt.compare (n1, n2))
                cases
      in
        map (fn (x, l) => (AI.UInt x, l)) cases
      end

  fun setupSwitchChar branchCases =
      let
        val cases =
            map (fn (AN.ANCONST (CT.CHAR n), label, _) =>
                    (Target.charToUInt n, label)
                  | _ => raise Control.Bug "setupSwitchChar")
                branchCases
        val cases =
            ListSorter.sort
                (fn ((n1, _), (n2, _)) => Target.UInt.compare (n1, n2))
                cases
      in
        map (fn (x, l) => (AI.Byte x, l)) cases
      end

  fun setupSwitchByte branchCases =
      let
        val cases =
            map (fn (AN.ANCONST (CT.BYTE n), label, _) =>
                    (Target.toUInt (BasicTypes.UInt8ToUInt32 n), label)
                  | _ => raise Control.Bug "setupSwitchByte")
                branchCases
        val cases =
            ListSorter.sort
                (fn ((n1, _), (n2, _)) => Target.UInt.compare (n1, n2))
                cases
      in
        map (fn (x, l) => (AI.Byte x, l)) cases
      end

  fun transformBinarySwitch cmpOp
                            context env code
                            switchValue branchCases defaultLabel loc =
      let
        (* branchCases must be already set up. *)

        fun beginBlockIfNeeded code (SOME label) blockKind env loc =
            beginBlock code label blockKind env loc
          | beginBlockIfNeeded code NONE blockKind env loc = code

        fun genCmp (context, code, env, (loadInsn, caseConst, label),
                    blockLabel, leftLabel, rightLabel) =
            let
              val (noneqLabel, compare) =
                  case (leftLabel, rightLabel) of
                    (SOME l, SOME r) => (newLabel (), SOME (l, r))
                  | (SOME l, NONE) => (l, NONE)
                  | (NONE, SOME r) => (r, NONE)
                  | (NONE, NONE) => (defaultLabel, NONE)

              val cmp = newVar AI.SINT
              val code = beginBlockIfNeeded code blockLabel AI.Branch env loc
              val code = addInsn code loadInsn
              val code =
                  addInsn code
                    (
                      (* cmp = cmpOp(strVar, string); *)
                      cmpOp {dst = cmp,
                             arg1 = switchValue,
                             arg2 = caseConst,
                             loc = loc} @
                      [
                        (* if (cmp == 0) then goto label; *)
                        AI.If {value1 = AI.Var cmp,
                               value2 = AI.SInt 0,
                               op2 = (AI.MonoEqual, AI.SINT, AI.SINT, AI.UINT),
                               thenLabel = label,
                               elseLabel = noneqLabel,
                               loc = loc}
                      ]
                    )
              val code = closeBlock code

              val code =
                  case compare of
                    NONE => code
                  | SOME (leftLabel, rightLabel) =>
                    let
                      val code = beginBlock code noneqLabel AI.Branch env loc
                      val code =
                          addInsn code
                            [
                              (* if (cmp < 0) then goto left else right; *)
                              AI.If {value1 = AI.Var cmp,
                                     value2 = AI.SInt 0,
                                     op2 = (AI.Lt, AI.SINT, AI.SINT, AI.UINT),
                                     thenLabel = leftLabel,
                                     elseLabel = rightLabel,
                                     loc = loc}
                            ]
                      val code = closeBlock code
                    in
                      code
                    end
            in
              (context, code, env, env, env)
            end
      in
        BinarySearchCode.generate genCmp (context, code, env, branchCases)
      end

  fun transformStringSwitch context env code
                            switchValue branchCases defaultLabel loc =
      let
        val branchCases =
            map (fn (AN.ANCONST (CT.STRING s), label, _) => (s, label)
                  | _ => raise Control.Bug "transformStringSwitch")
                branchCases

        val branchCases =
            ListSorter.sort
                (fn ((str1, _), (str2, _)) =>
                    Target.compareString (str1, str2))
                branchCases

        fun addCaseConsts context ((x, label)::cases) =
            let
              val (context, constId) = addConst context (AI.StringData x)
              val (context, cases) = addCaseConsts context cases
            in
              (context, (nil, AI.Const constId, label)::cases)
            end
          | addCaseConsts context nil = (context, nil)

        val (context, branchCases) =
            addCaseConsts context branchCases
      in
        transformBinarySwitch AIPrimitive.StrCmp
                              context env code
                              switchValue branchCases defaultLabel loc
      end

  fun transformLargeIntSwitch context env code
                              switchValue branchCases defaultLabel loc =
      let
        val branchCases =
            map (fn (AN.ANCONST (CT.LARGEINT n), label, _) => (n, label)
                  | _ => raise Control.Bug "transformLargeIntSwitch")
                branchCases

        val branchCases =
            ListSorter.sort
                (fn ((str1, _), (str2, _)) => BigInt.compare (str1, str2))
                branchCases

        fun addCaseConsts context ((x, label)::cases) =
            let
              val (context, constId) = addConst context (AI.IntInfData x)
              val var = newVar AI.BOXED
              val loadInsn =
                  AIPrimitive.LoadIntInf {dst = var,
                                          arg = AI.Init constId,
                                          loc = loc}
              val (context, cases) = addCaseConsts context cases
            in
              (context, (loadInsn, AI.Var var, label)::cases)
            end
          | addCaseConsts context nil = (context, nil)

        val (context, branchCases) =
            addCaseConsts context branchCases
      in
        transformBinarySwitch AIPrimitive.IntInfCmp
                              context env code
                              switchValue branchCases defaultLabel loc
      end

  fun transformExceptionSwitch context env code
                               switchValue branchCases defaultLabel loc =
      let
        val (context, branchCases) =
            foldr (fn ((AN.ANVALUE (AN.ANTOPSYMBOL {name,ty,...}), label, _),
                       (context,branches)) =>
                      let
                        val tag = transformGlobalRef (name, ty)
                      in
                        (context, (tag,label)::branches)
                      end
                    | ((AN.ANCONST CT.NULLBOXED, label, _),
                        (context, branches)) =>
                      (context, (AI.Empty, label)::branches)
                    | _ => raise Control.Bug "transformExceptionTag")
                  (context, nil)
                  branchCases

        (*
         * NOTE: Since exception type is open sum, exception tag values are
         *       not decided at compilation time. So we cannot compile
         *       exception switch into efficient search code.
         *       Here we compile it to linear search.
         *)
        fun genSwitch code nil = code
          | genSwitch code [(tag, label)] =
            let
              val code =
                  addInsn code
                    [
                      (* if (value == tag) goto label else defaultLabel; *)
                      AI.If {value1 = switchValue,
                             value2 = tag,
                             op2 = (AI.MonoEqual,
                                    AI.BOXED, AI.BOXED, AI.UINT),
                             thenLabel = label,
                             elseLabel = defaultLabel,
                             loc = loc}
                    ]
            in
              closeBlock code
            end
          | genSwitch code ((tag, label)::branches) =
            let
              val nextLabel = newLabel ()
              val code =
                  addInsn code
                    [
                      (* if (value == tag) goto label; *)
                      AI.If {value1 = switchValue,
                             value2 = tag,
                             op2 = (AI.MonoEqual,
                                    AI.BOXED, AI.BOXED, AI.UINT),
                             thenLabel = label,
                             elseLabel = nextLabel,
                             loc = loc}
                    ]
              val code = closeBlock code
              val code = beginBlock code nextLabel AI.Branch env loc
            in
              genSwitch code branches
            end
      in
        (context, genSwitch code branchCases, map (fn _ => env) branchCases)
      end

  fun checkFailedBlock context get set exnTag loc =
      case get context of
        SOME label => (context, fn x => fn _ => x, label)
      | NONE =>
        let
          val label = newLabel ()
          val exnVar = newArg (AI.BOXED, AI.Exn)
          val exnValue = newVar AI.BOXED
          val context = set context label
          (* In the current implementation, an exception object is a
           * record whose first field is a pointer to a heap-allocated
           * exception tag object. *)
          val insns =
              [
                AI.Alloc  {dst = exnValue,
                           objectType = AI.Vector,
                           bitmaps = [AI.UInt 0w1],
                           payloadSize = AI.UInt (sizeOfBoxed ()),
                           loc = loc},
                AI.Update {block = AI.Var exnValue,
                           offset = AI.UInt 0w0,
                           size = AI.UInt (sizeOfBoxed ()),
                           ty = AI.BOXED,
                           value = exnTag,
                           barrier = AI.NoBarrier,
                           loc = loc},
                AI.Set    {dst = exnVar,
                           ty = AI.BOXED,
                           value = AI.Var exnValue,
                           loc = loc},
                AI.Raise  {exn = exnVar,
                           loc = loc}
              ]
          fun addCode code env =
              let
                val code = beginBlock code label AI.CheckFailed env loc
                val code = addInsn code insns
                val code = closeBlock code
              in
                code
              end
        in
          (context, addCode, label)
        end

  fun boundaryCheck context env code block offset size loc =
      let
        val (context, addFailBlock, failLabel) =
            checkFailedBlock context
                             #boundaryCheckFailedLabel
                             setBoundaryCheckFailedLabel
                             SubscriptExceptionTag
                             loc

        val passLabel = newLabel ()
        val objectSize = newVar AI.UINT

        val code =
            addInsn code
              [
                AI.PrimOp1 {dst = objectSize,
                            op1 = (AI.PayloadSize, AI.BOXED, AI.UINT),
                            arg = block,
                            loc = loc},
                AI.CheckBoundary {offset = offset,
                                  size = size,
                                  objectSize = AI.Var objectSize,
                                  passLabel = passLabel,
                                  failLabel = failLabel,
                                  loc = loc}
              ]

        val code = closeBlock code
        val code = addFailBlock code env
        val code = beginBlock code passLabel AI.Branch env loc
      in
        (context, code)
      end

  fun arraySizeCheck context env code value loc =
      if (case value of
            AI.UInt n => n < Target.intToUInt arrayMaxLen
          | AI.SInt n => n < 0 andalso n < Target.intToSInt arrayMaxLen
          | _ => false)
      then (context, code)   (* no need to check dynamically *)
      else
        let
          val (context, addFailBlock, failLabel) =
              checkFailedBlock context
                               #raiseSizeLabel
                               setRaiseSizeLabel
                               SizeExceptionTag
                               loc
          val ty =
              case value of
                AI.UInt _ => AI.UINT
              | AI.SInt _ => AI.SINT
              | AI.Var {ty,...} => ty
              | _ => raise Control.Bug "arraySizeCheck"
          val passLabel = newLabel ()
          val code =
              case ty of
                AI.SINT =>
                let
                  val passLabel = newLabel ()
                  val code =
                      addInsn code
                        [
                          AI.If {value1 = value,
                                 value2 = AI.SInt 0,
                                 op2 = (AI.Lt, ty, ty, AI.UINT),
                                 thenLabel = failLabel,
                                 elseLabel = passLabel,
                                 loc = loc}
                        ]
                  val code = closeBlock code
                  val code = beginBlock code passLabel AI.Branch env loc
                in
                  code
                end
              | _ => code
          val arrayMaxLen =
              case ty of
                AI.UINT => AI.UInt (Target.intToUInt arrayMaxLen)
              | AI.SINT => AI.SInt (Target.intToSInt arrayMaxLen)
              | _ => raise Control.Bug "arraySizeCheck"
          val code =
              addInsn code
                [
                  AI.If {value1 = value,
                         value2 = arrayMaxLen,
                         op2 = (AI.Gt, ty, ty, AI.UINT),
                         thenLabel = failLabel,
                         elseLabel = passLabel,
                         loc = loc}
                ]
          val code = closeBlock code
          val code = addFailBlock code env
          val code = beginBlock code passLabel AI.Branch env loc
        in
          (context, code)
        end

  fun divZeroCheck context env code value ty loc =
      if (case value of
            AI.UInt 0w0 => false
          | AI.UInt _ => true
          | AI.SInt 0 => false
          | AI.SInt _ => true
          | AI.Byte 0w0 => false
          | AI.Byte _ => true
          | _ => false)
      then (context, code)   (* no need to check dynamically *)
      else
        let
          val (context, addFailBlock, failLabel) =
              checkFailedBlock context
                               #raiseDivLabel
                               setRaiseDivLabel
                               DivExceptionTag
                               loc
          val passLabel = newLabel ()
          val zero =
              case ty of
                AI.UINT => AI.UInt 0w0
              | AI.SINT => AI.SInt 0
              | AI.BYTE => AI.Byte 0w0
              | _ => raise Control.Bug ("divZeroCheck "
                                        ^ Control.prettyPrint (AI.format_ty ty))
          val code =
              addInsn code
                [
                  AI.If {value1 = value,
                         value2 = zero,
                         op2 = (AI.MonoEqual, ty, ty, AI.UINT),
                         thenLabel = failLabel,
                         elseLabel = passLabel,
                         loc = loc}
                ]
          val code = closeBlock code
          val code = addFailBlock code env
          val code = beginBlock code passLabel AI.Branch env loc
        in
          (context, code)
        end

  fun transformConst context env code dst const loc =
      case const of
        CT.INT n =>
        (context, addInsn code [AI.Move {dst = dst,
                                         ty = AI.SINT,
                                         value = AI.SInt (Target.toSInt n),
                                         loc = loc}])
      | CT.WORD n =>
        (context, addInsn code [AI.Move {dst = dst,
                                         ty = AI.UINT,
                                         value = AI.UInt (Target.toUInt n),
                                         loc = loc}])
      | CT.BYTE n =>
        let
          val n = BasicTypes.UInt8ToUInt32 n
        in
          (context, addInsn code [AI.Move {dst = dst,
                                           ty = AI.UINT,
                                           value = AI.UInt (Target.toUInt n),
                                           loc = loc}])
        end
      | CT.CHAR n =>
        (context, addInsn code [AI.Move {dst = dst,
                                         ty = AI.UINT,
                                         value = AI.UInt (Target.charToUInt n),
                                         loc = loc}])
      | CT.UNIT => (* assume UNIT is an integer. *)
        (context, addInsn code [AI.Move {dst = dst,
                                         ty = AI.UINT,
                                         value = AI.UInt 0w0,
                                         loc = loc}])
      | CT.NULLPOINTER =>
        (context, addInsn code [AI.Move {dst = dst,
                                         ty = AI.CPOINTER,
                                         value = AI.Null,
                                         loc = loc}])
      | CT.NULLBOXED =>
        (context, addInsn code [AI.Move {dst = dst,
                                         ty = AI.BOXED,
                                         value = AI.Empty,
                                         loc = loc}])

      | CT.STRING s =>
        let
          val (context, constId) = addConst context (AI.StringData s)
        in
          (context, addInsn code [AI.Move {dst = dst,
                                           ty = AI.BOXED,
                                           value = AI.Const constId,
                                           loc = loc}])
        end

      | CT.LARGEINT n =>
        let
          val (context, constId) = addConst context (AI.IntInfData n)
          val code =
              addInsn code
                (
                  AIPrimitive.LoadIntInf {dst = dst,
                                          arg = AI.Init constId,
                                          loc = loc}
                )
        in
          (context, code)
        end

      | CT.REAL r =>
        let
          val (context, constId) =
              addConst context (AI.PrimData (AI.RealData r))
          val code =
              addInsn code
                [
                  if !Control.enableUnboxedFloat
                  then
                    AI.Load {dst = dst,
                             ty = AI.DOUBLE,
                             block = AI.Init constId,
                             offset = AI.UInt 0w0,
                             size = AI.UInt (sizeOfDouble ()),
                             loc = loc}
                  else
                    AI.Move {dst = dst,
                             ty = AI.DOUBLE,
                             value = AI.Init constId,
                             loc = loc}
                ]
        in
          (context, code)
        end

      | CT.FLOAT r =>
        let
          val (context, constId) =
              addConst context (AI.PrimData (AI.FloatData r))
          val code =
              addInsn code
                [
                  AI.Load {dst = dst,
                           ty = AI.FLOAT,
                           block = AI.Init constId,
                           offset = AI.UInt 0w0,
                           size = AI.UInt (sizeOfFloat ()),
                           loc = loc}
                ]
        in
          (context, code)
        end

  (*********************************************************************)

  fun transformCodePoint context label =
      case #codeEntry (getRoutineInfo context label) of
        SOME x => x
      | NONE => raise Control.Bug ("transformCodePoint: no entry point of "^
                                   ID.toString label)

  fun transformPrimData funIdMap anvalue =
      case anvalue of
        AN.ANINT n => AI.SIntData (Target.toSInt n)
      | AN.ANWORD n => AI.UIntData (Target.toUInt n)
      | AN.ANBYTE n => AI.UIntData (Target.toUInt (BasicTypes.UInt8ToUInt32 n))
      | AN.ANCHAR c => AI.ByteData (Target.intToUInt (ord c))
      | AN.ANUNIT => AI.UIntData 0w0
      | AN.ANNULLPOINTER => AI.NullPointerData
      | AN.ANNULLBOXED => AI.NullBoxedData
      | AN.ANTOPSYMBOL {name=AN.TOP_EXTERN name, ...} =>
        AI.ExternLabelData name
      | AN.ANTOPSYMBOL {name=AN.TOP_EXPORT (AN.TOP_GLOBAL name), ...} =>
        AI.GlobalLabelData name
      | AN.ANTOPSYMBOL {name=AN.TOP_EXPORT (AN.TOP_LOCAL id), ...} =>
        AI.ConstData id
      | AN.ANVAR _ => raise Control.Bug "transformPrimData: ANVAR"
      | AN.ANLABEL id =>
        (
          case ID.Map.find (funIdMap, id) of
            SOME clusterId => AI.EntryData {clusterId=clusterId, entry=id}
          | NONE => raise Control.Bug ("transformPrimData: " ^ ID.toString id)
        )
      | AN.ANLOCALCODE _ =>
        raise Control.Bug "transformPrimData: ANLOCALCODE"

  fun transformArg context (env:environment) anvalue =
      case anvalue of
        AN.ANINT n => (context, AI.SInt (Target.toSInt n))
      | AN.ANWORD n => (context, AI.UInt (Target.toUInt n))
      | AN.ANBYTE n =>
        (context, AI.Byte (Target.toUInt (BasicTypes.UInt8ToUInt32 n)))
      | AN.ANCHAR c => (context, AI.Byte (Target.charToUInt c))
      | AN.ANUNIT => (context, AI.UInt 0w0)  (* assume UNIT is an integer. *)
      | AN.ANNULLPOINTER => (context, AI.Null)
      | AN.ANNULLBOXED => (context, AI.Empty)
      | AN.ANTOPSYMBOL {name,ty,...} =>
        (context, transformGlobalRef (name, ty))
      | AN.ANVAR (varInfo as {varKind = AN.ARG, id, ...}) =>
        let
          val value = case ID.Map.find (#paramMap env, id) of
                        SOME value => value
                      | NONE => raise Control.Bug ("transformArg: ARG "^
                                                   ID.toString id)
        in
          (context, value)
        end
      | AN.ANVAR (varInfo as {varKind = AN.LOCALARG, id, ...}) =>
        let
          val value = case ID.Map.find (#paramMap env, id) of
                        SOME value => value
                      | NONE => raise Control.Bug ("transformArg: LOCALARG "^
                                                   ID.toString id)
        in
          (context, value)
        end
      | AN.ANVAR (varInfo as {varKind = AN.LOCAL, id, ...}) =>
        (context, AI.Var (transformVarInfo varInfo))
      | AN.ANLABEL id =>
        (context, AI.Entry {clusterId = getClusterId context id, entry = id})
      | AN.ANLOCALCODE id =>
        (context, AI.Label (transformCodePoint context id))

  fun transformArgList context env (anvalue::anvalueList) =
      let
        val (context, value) = transformArg context env anvalue
        val (context, values) = transformArgList context env anvalueList
      in
        (context, value::values)
      end
    | transformArgList context env nil = (context, nil)

  fun makeMove context env code (var::anvarList) (value::valueList) loc =
      let
        val dst = transformVarInfo var
        val code =
            addInsn code
              [
                AI.Move {dst = dst,
                         ty = #ty dst,
                         value = value,
                         loc = loc}
              ]
      in
        makeMove context env code anvarList valueList loc
      end
    | makeMove context env code nil nil loc =
      (context, env, code)     (* return env for convenience *)
    | makeMove _ _ _ x y _ =
      raise Control.Bug ("makeMove "^
                         Int.toString (length x)^","^
                         Int.toString (length y))

  fun makeGet kindCon (varList, tyList, loc) =
      let
        fun mapi f l =
            let
              fun loop (i, h::t) = f (i, h) :: loop (i + 1, t)
                | loop (i, nil) = nil
            in
              loop (0, l)
            end

        val args =
            mapi (fn (n, ty) => newArg (ty, kindCon (n, tyList))) tyList

        fun make (n, var::vars, ty::tys) =
            let
              val arg = newArg (ty, kindCon (n, tyList))
              val (args, insns) = make (n + 1, vars, tys)
            in
              (arg::args,
               AI.Get {dst = var,
                       ty = ty,
                       src = arg,
                       loc = loc} :: insns)
            end
          | make (n, nil, nil) = (nil, nil)
          | make (n, _, _) = raise Control.Bug "makeSet"
      in
        make (0, varList, tyList)
      end

  fun makeSet kindCon (valueList, tyList, loc) =
      let
        fun make (n, value::values, ty::tys) =
            let
              val arg = newArg (ty, kindCon (n, tyList))
              val (args, insns) = make (n + 1, values, tys)
            in
              (arg::args,
               AI.Set {dst = arg,
                       ty = ty,
                       value = value,
                       loc = loc} :: insns)
            end
          | make (n, nil, nil) = (nil, nil)
          | make (n, _, _) = raise Control.Bug "makeSet"
      in
        make (0, valueList, tyList)
      end

  fun makeGetRet con argTys = makeGet (fn (n,t) => con {index = n, argTys = argTys, retTys = t})
  fun makeSetArg con retTys = makeSet (fn (n,t) => con {index = n, argTys = t, retTys = retTys})
  fun makeSetRet con argTys = makeSet (fn (n,t) => con {index = n, argTys = argTys, retTys = t})
  fun makeSetExtArg con attributes =
      makeSet (fn (n,t) => con {index = n, argTys = t, attributes = attributes})
  fun makeGetExtRet con attributes =
      makeGet (fn (n,t) => con {index = n, retTys = t, attributes = attributes})

  fun makeEmpty context env code varList loc =
      let
        val dst = transformVarInfo (onlyOne varList)
        val code = addInsn code
                     [
                       AI.Alloc {dst = dst,
                                 objectType = AI.Vector,
                                 bitmaps = [AI.UInt 0w0],
                                 payloadSize = AI.UInt 0w0,
                                 loc = loc}
                     ]
      in
        (context, env, code)
      end

  fun transformDecl context env code andecl =
      case andecl of
        AN.ANVAL {varList,
                  exp = AN.ANCONST const,
                  loc} =>
        let
          val dst = transformVarInfo (onlyOne varList)
          val (context, code) = transformConst context env code dst const loc
        in
          (context, env, code)
        end

      | AN.ANVAL {varList,
                  exp = AN.ANVALUE anvalue,
                  loc} =>
        let
          val (context, value) = transformArg context env anvalue
        in
          makeMove context env code varList [value] loc
        end

      | AN.ANVAL {varList,
                  exp = AN.ANRECORD {totalSize = AN.ANWORD 0w0,
                                     ...},
                  loc} =>
        makeEmpty context env code varList loc

      | AN.ANVAL {varList,
                  exp = AN.ANARRAY {totalSize = AN.ANWORD 0w0,
                                    isMutable = false,
                                    ...},
                  loc} =>
        makeEmpty context env code varList loc

      | AN.ANVAL {varList,
                  exp = AN.ANENVACC {nestLevel, offset, size, ty},
                  loc} =>
        let
          val dst = transformVarInfo (onlyOne varList)
          val (context, size) = transformArg context env size
          val nestLevel = AI.UInt (Target.toUInt nestLevel)
          val offset = AI.UInt (Target.toUInt offset)
          val ty = transformTy ty

          val (code, block) =
              unrollNestedBlock env code (currentClosureEnv context)
                                nestLevel loc
          val code = addInsn code
                       [
                         AI.Load {dst = dst,
                                  ty = ty,
                                  block = block,
                                  offset = offset,
                                  size = size,
                                  loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANVAL {varList,
                  exp = AN.ANSELECT {record, nestLevel, offset, size, ty},
                  loc} =>
        let
          val dst = transformVarInfo (onlyOne varList)
          val (context, record) = transformArg context env record
          val (context, nestLevel) = transformArg context env nestLevel
          val (context, offset) = transformArg context env offset
          val (context, size) = transformArg context env size
          val ty = transformTy ty

          val (code, block) =
              unrollNestedBlock env code record nestLevel loc
          val code = addInsn code
                       [
                         AI.Load {dst = dst,
                                  ty = ty,
                                  block = block,
                                  offset = offset,
                                  size = size,
                                  loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANVAL {varList,
                  exp = AN.ANGETFIELD {array, offset, size, ty,
                                       needBoundaryCheck},
                  loc} =>
        let
          val dst = transformVarInfo (onlyOne varList)
          val (context, array) = transformArg context env array
          val (context, offset) = transformArg context env offset
          val (context, size) = transformArg context env size
          val ty = transformTy ty

          val (context, code) =
              if needBoundaryCheck
              then boundaryCheck context env code array offset size loc
              else (context, code)

          val code = addInsn code
                       [
                         AI.Load {dst = dst,
                                  ty = ty,
                                  block = array,
                                  offset = offset,
                                  size = size,
                                  loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANSETFIELD {array, offset, value, valueTy, valueSize, valueTag,
                       setGlobal, needBoundaryCheck, loc} =>
        let
          val (context, array) = transformArg context env array
          val (context, offset) = transformArg context env offset
          val (context, value) = transformArg context env value
          val valueTy = transformTy valueTy
          val (context, valueSize) = transformArg context env valueSize
          val (context, valueTag) = transformArg context env valueTag
          val barrier = transformBarrier (valueTag, setGlobal)

          val (context, code) =
              if needBoundaryCheck
              then boundaryCheck context env code array offset valueSize loc
              else (context, code)

          val code = addInsn code
                       [
                         AI.Update {block = array,
                                    offset = offset,
                                    size = valueSize,
                                    ty = valueTy,
                                    value = value,
                                    barrier = barrier,
                                    loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANSETTAIL {record, nestLevel, offset, value, valueTy, valueSize,
                      valueTag, loc} =>
        let
          val (context, record) = transformArg context env record
          val (context, nestLevel) = transformArg context env nestLevel
          val (context, offset) = transformArg context env offset
          val (context, value) = transformArg context env value
          val valueTy = transformTy valueTy
          val (context, valueSize) = transformArg context env valueSize
          val (context, valueTag) = transformArg context env valueTag
          val barrier = transformBarrier (valueTag, false)

          val code = addInsn code
                       [
                         AI.Update {block = record,
                                    offset = offset,
                                    size = valueSize,
                                    ty = valueTy,
                                    value = value,
                                    barrier = barrier,
                                    loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANCOPYARRAY {src, srcOffset, dst, dstOffset, length, elementTy,
                        elementSize, elementTag, loc} =>
        let
          (* FIXME: what is the type of length and elementSize?
           *        UINT? OFFSET? SIZE?  *)
          val (context, src) = transformArg context env src
          val (context, srcOffset) = transformArg context env srcOffset
          val (context, dst) = transformArg context env dst
          val (context, dstOffset) = transformArg context env dstOffset
          val (context, length) = transformArg context env length
          val elemTy = transformTy elementTy
          val (context, elemSize) = transformArg context env elementSize
          val (context, elemTag) = transformArg context env elementTag
        in
          (* FIXME: need boundary check *)
          case elemSize of
            AI.UInt 0w1 =>
            let
              val code =
                  addInsn code
                    (
                      (* Memcpy primitive includes write barrier. *)
                      AIPrimitive.Memcpy {src = src,
                                          srcOffset = srcOffset,
                                          dst = dst,
                                          dstOffset = dstOffset,
                                          length = length,
                                          tag = elemTag,
                                          loc = loc}
                    )
            in
              (context, env, code)
            end
          | _ =>
            let
              val lenVar = newVar AI.UINT
              val code =
                  addInsn code
                    (
                      AI.PrimOp2    {dst = lenVar,
                                     op2 = (AI.Mul, AI.UINT, AI.UINT, AI.UINT),
                                     arg1 = length,
                                     arg2 = elemSize,
                                     loc = loc} ::
                      (* Memcpy primitive includes write barrier. *)
                      AIPrimitive.Memcpy {src = src,
                                          srcOffset = srcOffset,
                                          dst = dst,
                                          dstOffset = dstOffset,
                                          length = AI.Var lenVar,
                                          tag = elemTag,
                                          loc = loc}
                    )
            in
              (context, env, code)
            end
        end

      | AN.ANVAL {varList,
                  exp = AN.ANARRAY {bitmap, totalSize as anTotalSize,
                                    initialValue,
                                    elementTy,
                                    elementSize as anElementSize,
                                    isMutable},
                  loc} =>
        let
          val dst = transformVarInfo (onlyOne varList)
          val (context, bitmap) = transformArg context env bitmap
          val (context, totalSize) = transformArg context env totalSize
          val (context, initialValue) =
              case initialValue of
                NONE => (context, NONE)
              | SOME initialValue =>
                let val (context, v) = transformArg context env initialValue
                in (context, SOME v)
                end
          val elementTy = transformTy elementTy
          val (context, elementSize) = transformArg context env elementSize
          val objectType = if isMutable then AI.Array else AI.Vector

          val (elementSize, elementTy, initialValue) =
              case (bitmap, initialValue) of
                (AI.UInt 0w0, NONE) => (elementSize, elementTy, NONE)
              | (_, SOME _) => (elementSize, elementTy, initialValue)
              | _ =>
                (* no initial value but need initialization *)
                (AI.UInt 0w1, AI.BYTE, SOME (AI.UInt 0w0))
          fun toInt (AI.UInt v1) = SOME v1
            | toInt (AI.SInt v1) = SOME (Target.SIntToUInt v1)
            | toInt _ = NONE
          val isOneElement =
              toInt totalSize = toInt elementSize
              orelse (case (totalSize, elementSize) of
                        (AI.Var v1, AI.Var v2) => ID.eq (#id v1, #id v2)
                      | _ => false)
        in
          case (isOneElement, initialValue) of
            (true, SOME initialValue) =>
            (* one element array; this is frequently used for "ref." *)
            let
              val code =
                  addInsn code
                    [
                      AI.Alloc  {dst = dst,
                                 objectType = objectType,
                                 bitmaps = [bitmap],
                                 payloadSize = totalSize,
                                 loc = loc},
                      (* update for initialization. barrier is not needed. *)
                      AI.Update {block = AI.Var dst,
                                 offset = AI.UInt 0w0,
                                 size = elementSize,
                                 ty = elementTy,
                                 value = initialValue,
                                 barrier = AI.NoBarrier,
                                 loc = loc}
                    ]
            in
              (context, env, code)
            end
          | (_, NONE) =>
            (* alloc array without initialization. *)
            let
              val (context, code) =
                  arraySizeCheck context env code totalSize loc
              val code =
                  addInsn code
                    [
                      AI.Alloc  {dst = dst,
                                 objectType = objectType,
                                 bitmaps = [bitmap],
                                 payloadSize = totalSize,
                                 loc = loc}
                    ]
            in
              (context, env, code)
            end
          | (_, SOME initialValue) =>
            (* ordinary array. split ANARRAY into two parts; one is array
             * allocation, and another is initialization loop. *)
            let
              val (context, code) =
                  arraySizeCheck context env code totalSize loc

              val code =
                  addInsn code
                    [
                      (* dst = AllocArray(bitmap, totalSize); *)
                      AI.Alloc  {dst = dst,
                                 objectType = objectType,
                                 bitmaps = [bitmap],
                                 payloadSize = totalSize,
                                 loc = loc}
                    ]
              val code = initializeArray env code
                                         (dst, totalSize, initialValue,
                                          elementTy, elementSize, loc)
            in
              (context, env, code)
            end
        end

      | AN.ANVAL {varList,
                  exp = AN.ANMODIFY {record, nestLevel, offset,
                                     value, valueTy, valueSize, valueTag},
                  loc} =>
        let
          val dst = transformVarInfo (onlyOne varList)
          val (context, record) = transformArg context env record
          val (context, nestLevel) = transformArg context env nestLevel
          val (context, offset) = transformArg context env offset
          val (context, value) = transformArg context env value
          val valueTy = transformTy valueTy
          val (context, valueSize) = transformArg context env valueSize
          val (context, valueTag) = transformArg context env valueTag
          val barrier = transformBarrier (valueTag, false)

          fun copyNestedBlock code base nestedVar newcopyVar =
              addInsn code
                (
                  (* nested = base[NestedBlockIndex]; *)
                  AI.Load   {dst = nestedVar,
                             block = base,
                             offset = nestedBlockIndex,
                             size = AI.UInt (sizeOfBoxed ()),
                             ty = AI.BOXED,
                             loc = loc} ::
                  (* newcopy = CopyBlock(nested); *)
                  AIPrimitive.CopyBlock {dst = newcopyVar,
                                         block = AI.Var nestedVar,
                                         loc = loc} @
                  [
                    (* base[NestedBlockIndex] = newcopy; *)
                    AI.Update {block = base,
                               offset = nestedBlockIndex,
                               size = AI.UInt (sizeOfBoxed ()),
                               ty = AI.BOXED,
                               value = AI.Var newcopyVar,
                               barrier = AI.WriteBarrier,
                               loc = loc}
                  ]
                )
        in
          case nestLevel of
            AI.UInt n =>
            let
              val currentLabel = getCurrentLabel code

              fun copyBlock (env, code, base, 0w0 : Target.uint) =
                  (env, code, base)
                | copyBlock (env, code, base, n) =
                  let
                    val nested = newVar AI.BOXED
                    val newcopy = newVar AI.BOXED
                    val code = copyNestedBlock code base nested newcopy
                  in
                    (env, code, AI.Var newcopy)
                  end

              val code = addInsn code
                           (
                             (* dst = CopyBlock(record); *)
                             AIPrimitive.CopyBlock {dst = dst,
                                                    block = record,
                                                    loc = loc}
                           )
              val (env, code, copied) = copyBlock (env, code, AI.Var dst, n)
              val code = addInsn code
                           [
                             (* copied[offset] = newValue; *)
                             AI.Update {block = copied,
                                        offset = offset,
                                        size = valueSize,
                                        value = value,
                                        ty = valueTy,
                                        barrier = barrier,
                                        loc = loc}
                           ]
            in
              (context, env, code)
            end
          | _ =>
            let
              val currentLabel = getCurrentLabel code
              val loopLabel = newLabel ()
              val bodyLabel = newLabel ()
              val exitLabel = newLabel ()

              val copiedVar = newVar AI.BOXED
              val counterVar = newVar AI.UINT
              val code =
                  addInsn code
                    (
                      (* dst = CopyBlock(record); *)
                      AIPrimitive.CopyBlock {dst = dst,
                                             block = record,
                                             loc = loc} @
                      [
                        (* copied = dst; *)
                        AI.Move   {dst = copiedVar,
                                   ty = AI.BOXED,
                                   value = AI.Var dst,
                                   loc = loc},
                        (* counter = nestLevel; *)
                        AI.Move   {dst = counterVar,
                                   ty = AI.UINT,
                                   value = AI.UInt 0w0,
                                   loc = loc},
                        AI.Jump   {label = AI.Label loopLabel,
                                   knownDestinations = [loopLabel],
                                   loc = loc}
                      ]
                    )
              val code = closeBlock code

              val code = beginBlock code loopLabel AI.Loop env loc
              val code =
                  addInsn code
                    [
                      (* while (counter != 0) { *)
                      AI.If    {value1 = AI.Var counterVar,
                                value2 = AI.UInt 0w0,
                                op2 = (AI.MonoEqual, AI.UINT, AI.UINT, AI.UINT),
                                thenLabel = exitLabel,
                                elseLabel = bodyLabel,
                                loc = loc}
                      ]
              val code = closeBlock code

              val nestedVar = newVar AI.BOXED
              val newcopyVar = newVar AI.BOXED
              val code = beginBlock code bodyLabel AI.Branch env loc
              val code = copyNestedBlock
                             code (AI.Var copiedVar) nestedVar newcopyVar
              val code =
                  addInsn code
                    [
                      (*   copied = newcopy; *)
                      AI.Move    {dst = copiedVar,
                                  ty = AI.BOXED,
                                  value = AI.Var newcopyVar,
                                  loc = loc},
                      (*   counter = counter - 1; *)
                      AI.PrimOp2 {dst = counterVar,
                                  op2 = (AI.Sub, AI.UINT, AI.UINT, AI.UINT),
                                  arg1 = AI.Var counterVar,
                                  arg2 = AI.UInt 0w1,
                                  loc = loc},
                      (* } *)
                      AI.Jump    {label = AI.Label loopLabel,
                                  knownDestinations = [loopLabel],
                                  loc = loc}
                    ]
              val code = closeBlock code

              val code = beginBlock code exitLabel AI.Branch env loc
              val code =
                  addInsn code
                    [
                      (* copied[offset] = newValue; *)
                      AI.Update  {block = AI.Var copiedVar,
                                  offset = offset,
                                  size = valueSize,
                                  ty = valueTy,
                                  value = value,
                                  barrier = barrier,
                                  loc = loc}
                    ]
            in
              (context, env, code)
            end
        end

      | AN.ANVAL {varList,
                  exp = AN.ANRECORD {bitmaps, totalSize, fieldList,
                                     fieldSizeList,
                                     fieldIndexList,
                                     fieldTyList, isMutable, clearPad},
                  loc} =>
        let
          val dst = transformVarInfo (onlyOne varList)
          val (context, bitmaps) = transformArgList context env bitmaps
          val (context, totalSize) = transformArg context env totalSize
          val (context, fieldList) = transformArgList context env fieldList
          val (context, fieldSizeList) =
              transformArgList context env fieldSizeList
          val (context, fieldIndexList) =
              transformArgList context env fieldIndexList

          val code =
              yaMakeRecord context env code
                           {dst = dst,
                            bitmaps = bitmaps,
                            payloadSize = totalSize,
                            fieldTyList = fieldTyList,
                            fieldSizeList = fieldSizeList,
                            fieldIndexList = fieldIndexList,
                            clearPad = clearPad,
                            loc = loc}
                           fieldList
        in
          (context, env, code)
        end

      | AN.ANRAISE {value, loc} =>
        let
          val (context, exn) = transformArg context env value
          val exnArg = newArg (AI.BOXED, AI.Exn)
          val routine = getRoutineInfo context (#routineLabel env)
          val code = addInsn code
                       [
                         AI.Set   {dst = exnArg,
                                   ty = AI.BOXED,
                                   value = exn,
                                   loc = loc},
                         (* ToDo: not all "raise" go outside of ML.
                          * We should choose RaiseExt only for unhandled
                          * raise in toplevel functions. *)
                         case (#ffiAttributes routine, #handler env) of
                           (NONE, _) => AI.Raise {exn = exnArg, loc = loc}
                         | (SOME _, AI.StaticHandler _) =>
                           AI.Raise {exn = exnArg, loc = loc}
                         | (SOME _, AI.DynamicHandler {outside=false,...}) =>
                           AI.Raise {exn = exnArg, loc = loc}
                         | (SOME _, AI.DynamicHandler {outside=true,...}) =>
                           raise Control.Bug "ANRAISE"
                         | (SOME attributes, AI.NoHandler) =>
                           AI.RaiseExt {exn = exnArg,
                                        attributes = attributes,
                                        loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANRETURN {valueList, tyList, loc} =>
        let
          val (context, valueList) = transformArgList context env valueList
          val tyList = map transformTy tyList
          val routine = getRoutineInfo context (#routineLabel env)

          val argTys =
              map (transformTy o #ty) (#argVarList routine)

          val (args, insns) = makeSetRet AI.Result argTys
                                         (valueList, tyList, loc)

          val code = addInsn code
                       (
                         insns @
                         [
                           case #ffiAttributes routine of
                             NONE => AI.Return {varList = args,
                                                argTyList = argTys,
                                                retTyList = tyList,
                                                loc = loc}
                           | SOME attributes =>
                             AI.ReturnExt {varList = args,
                                           argTyList = argTys,
                                           retTyList = tyList,
                                           attributes = attributes,
                                           loc = loc}
                         ]
                       )
        in
          (context, env, code)
        end

      | AN.ANVAL {varList,
                  exp = AN.ANCLOSURE {funLabel, env = closEnv},
                  loc} =>
        let
          val dst = transformVarInfo (onlyOne varList)
          val (context, funLabel) = transformArg context env funLabel
          val (context, closEnv) = transformArg context env closEnv
          val code = makeClosure context env code dst funLabel closEnv loc
        in
          (context, env, code)
        end

      | AN.ANVAL {varList,
                  exp = AN.ANRECCLOSURE {funLabel},
                  loc} =>
        let
          val dst = transformVarInfo (onlyOne varList)
          val (context, funLabel) = transformArg context env funLabel
          val code = makeClosure context env code dst funLabel
                                 (currentClosureEnv context) loc
        in
          (context, env, code)
        end

      | AN.ANVAL {varList,
                  exp = AN.ANCALLBACKCLOSURE {funLabel, env=closEnv,
                                              argTyList, resultTyList,
                                              attributes},
                  loc} =>
        let
          (* FIXME: ExportCallback requires more accurate types. *)
          val dst = transformVarInfo (onlyOne varList)
          val (context, funLabel) = transformArg context env funLabel
          val (context, closEnv) = transformArg context env closEnv
          val argTys = map transformTy argTyList
          val retTys = map transformTy resultTyList

          val code = addInsn code
                       [
                         AI.CallbackClosure {dst = dst,
                                             entry = funLabel,
                                             env = closEnv,
                                             exportTy = (argTys, retTys),
                                             attributes = attributes,
                                             loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANVAL {varList,
                  exp = AN.ANFOREIGNAPPLY {function, argList, argTyList,
                                           resultTyList, attributes},
                  loc} =>
        let
          (* FIXME: ForeignApply requires more accurate types. *)
          val dsts = map transformVarInfo varList
          val (context, function) = transformArg context env function
          val (context, argList) = transformArgList context env argList
          val argTys = map transformTy argTyList
          val retTys = map transformTy resultTyList

          val (args, insnsArg) =
              makeSetExtArg AI.ExtArg attributes (argList, argTys, loc)
          val (rets, insnsRet) =
              makeGetExtRet AI.ExtRet attributes (dsts, retTys, loc)

          val code =
              addInsn code
                (
                  insnsArg @
                  [
                    AI.CallExt {dstVarList = rets,
                                entry = function,
                                attributes = attributes,
                                argList = args,
                                calleeTy = (argTys, retTys),
                                loc = loc}
                  ] @
                  insnsRet
                )
        in
          (context, env, code)
        end

      | AN.ANVAL {varList,
                  exp = AN.ANPRIMAPPLY {prim, argList,
                                        argTyList, resultTyList,
                                        instSizeList, instTagList},
                  loc} =>
        let
          val dsts = map transformVarInfo varList
          val (context, argList) = transformArgList context env argList
          val argTys = map transformTy argTyList
          val retTys = map transformTy resultTyList

          val (context, instSizeList) =
              transformArgList context env instSizeList
          val (context, instTagList) =
              transformArgList context env instTagList

          val (context, code) =
              case (AIPrimitive.needDivZeroCheck prim, argList) of
                (SOME ty, [_, v2]) =>
                divZeroCheck context env code v2 ty loc
              | (SOME ty, _) => raise Control.Bug "PRIMAPPLY: divZero"
              | _ => (context, code)

          val insn =
              AIPrimitive.transform
                  {prim = prim,
                   dstVarList = dsts,
                   dstTyList = retTys,
                   argList = argList,
                   argTyList = argTys,
                   instSizeList = instSizeList,
                   instTagList = instTagList,
                   loc = loc}

          val code = addInsn code insn
        in
          (context, env, code)
        end

      | AN.ANVAL {varList,
                  exp = AN.ANAPPLY {closure, argList, argTyList, resultTyList},
                  loc} =>
        let
          val dsts = map transformVarInfo varList
          val (context, closure) = transformArg context env closure
          val (context, argList) = transformArgList context env argList
          val argTys = map transformTy argTyList
          val retTys = map transformTy resultTyList

          val entryVar = newVar AI.ENTRY
          val envVar = newVar AI.BOXED
          val envArg = newArg (AI.BOXED, AI.Env)
          val code = expandClosure code closure entryVar envVar loc

          val (args, insnsArg) = makeSetArg AI.Arg retTys (argList, argTys, loc)
          val (rets, insnsRet) = makeGetRet AI.Ret argTys (dsts, retTys, loc)
          val code = addInsn code
                       (
                         AI.Set    {dst = envArg,
                                    ty = AI.BOXED,
                                    value = AI.Var envVar,
                                    loc = loc} ::
                         insnsArg @
                         [
                           AI.Call {dstVarList = rets,
                                    entry = AI.Var entryVar,
                                    env = envArg,
                                    argList = args,
                                    argTyList = argTys,
                                    resultTyList = retTys,
                                    loc = loc}
                         ] @
                         insnsRet
                       )
        in
          (context, env, code)
        end

      | AN.ANTAILAPPLY {closure, argList, argTyList, resultTyList, loc} =>
        let
          val (context, closure) = transformArg context env closure
          val (context, argList) = transformArgList context env argList
          val argTys = map transformTy argTyList
          val retTys = map transformTy resultTyList

          val entryVar = newVar AI.ENTRY
          val envVar = newVar AI.BOXED
          val envArg = newArg (AI.BOXED, AI.Env)
          val code = expandClosure code closure entryVar envVar loc

          val (args, insnsArg) =
              makeSetArg AI.Param retTys (argList, argTys, loc)

          val code = addInsn code
                       (
                         [
                           AI.Set      {dst = envArg,
                                        ty = AI.BOXED,
                                        value = AI.Var envVar,
                                        loc = loc}
                         ] @
                         insnsArg @
                         [
                           AI.TailCall {entry = AI.Var entryVar,
                                        env = envArg,
                                        argList = args,
                                        argTyList = argTys,
                                        resultTyList = retTys,
                                        loc = loc}
                         ]
                       )
        in
          (context, env, code)
        end

      | AN.ANVAL {varList,
                  exp = AN.ANCALL {funLabel, env = closEnv, argList,
                                   argTyList, resultTyList},
                  loc} =>
        let
          val dsts = map transformVarInfo varList
          val (context, funLabel) = transformArg context env funLabel
          val (context, closEnv) = transformArg context env closEnv
          val (context, argList) = transformArgList context env argList
          val argTys = map transformTy argTyList
          val retTys = map transformTy resultTyList

          val envArg = newArg (AI.BOXED, AI.Env)
          val (args, insnsArg) = makeSetArg AI.Arg retTys (argList, argTys, loc)
          val (rets, insnsRet) = makeGetRet AI.Ret argTys (dsts, retTys, loc)

          val code = addInsn code
                       (
                         insnsArg @
                         [
                           AI.Set  {dst = envArg,
                                    ty = AI.BOXED,
                                    value = closEnv,
                                    loc = loc},
                           AI.Call {dstVarList = rets,
                                    entry = funLabel,
                                    env = envArg,
                                    argList = args,
                                    argTyList = argTys,
                                    resultTyList = retTys,
                                    loc = loc}
                         ] @
                         insnsRet
                       )
        in
          (context, env, code)
        end

      | AN.ANTAILCALL {funLabel, env = closEnv, argList,
                       argTyList, resultTyList, loc} =>
        let
          val (context, funLabel) = transformArg context env funLabel
          val (context, closEnv) = transformArg context env closEnv
          val (context, argList) = transformArgList context env argList
          val argTys = map transformTy argTyList
          val retTys = map transformTy resultTyList

          val envArg = newArg (AI.BOXED, AI.Env)
          val (args, insnsArg) =
              makeSetArg AI.Param retTys (argList, argTys, loc)

          val code = addInsn code
                       (
                         insnsArg @
                         [
                           AI.Set      {dst = envArg,
                                        ty = AI.BOXED,
                                        value = closEnv,
                                        loc = loc},
                           AI.TailCall {entry = funLabel,
                                        env = envArg,
                                        argList = args,
                                        argTyList = argTys,
                                        resultTyList = retTys,
                                        loc = loc}
                         ]
                       )
        in
          (context, env, code)
        end

      | AN.ANVAL {varList,
                  exp = AN.ANRECCALL {funLabel, argList,
                                      argTyList, resultTyList},
                  loc} =>
        let
          val dsts = map transformVarInfo varList
          val (context, funLabel) = transformArg context env funLabel
          val (context, argList) = transformArgList context env argList
          val argTys = map transformTy argTyList
          val retTys = map transformTy resultTyList

          val envArg = newArg (AI.BOXED, AI.Env)
          val (args, insnsArg) = makeSetArg AI.Arg retTys (argList, argTys, loc)
          val (rets, insnsRet) = makeGetRet AI.Ret argTys (dsts, retTys, loc)

          val code = addInsn code
                       (
                         insnsArg @
                         [
                           AI.Set  {dst = envArg,
                                    ty = AI.BOXED,
                                    value = currentClosureEnv context,
                                    loc = loc},
                           AI.Call {dstVarList = rets,
                                    entry = funLabel,
                                    env = envArg,
                                    argList = args,
                                    argTyList = argTys,
                                    resultTyList = retTys,
                                    loc = loc}
                         ] @
                         insnsRet
                       )
        in
          (context, env, code)
        end

      | AN.ANTAILRECCALL {funLabel, argList, argTyList, resultTyList, loc} =>
        let
          val (context, funLabel) = transformArg context env funLabel
          val (context, argList) = transformArgList context env argList
          val argTys = map transformTy argTyList
          val retTys = map transformTy resultTyList

          val envArg = newArg (AI.BOXED, AI.Env)
          val (args, insnsArg) = makeSetArg AI.Arg retTys (argList, argTys, loc)

          val code = addInsn code
                       (
                         insnsArg @
                         [
                           AI.Set      {dst = envArg,
                                        ty = AI.BOXED,
                                        value = currentClosureEnv context,
                                        loc = loc},
                           AI.TailCall {entry = funLabel,
                                        env = envArg,
                                        argList = args,
                                        argTyList = argTys,
                                        resultTyList = retTys,
                                        loc = loc}
                         ]
                       )
        in
          (context, env, code)
        end

      | AN.ANVAL {varList,
                  exp = AN.ANLOCALCALL {codeLabel, argList,
                                        argTyList, resultTyList,
                                        knownDestinations, returnLabel},
                  loc} =>
        let
          val destinations =
              map (transformCodePoint context) (!knownDestinations)

          val (context, codeLabel) =
              case destinations of
                [l] => (context, AI.Label l)
              | _ => transformArg context env codeLabel

          val (context, argList) = transformArgList context env argList

          (* FIXME: type is always matches to callee? *)
          val passTys = AN.CODEPOINT :: argTyList
          val passVars = getPassVars context passTys
          val returnVars = getPassVars context resultTyList

          (* pass return address to callee *)
          val passValues = AI.Label returnLabel :: argList

          val (context, env, code) =
              makeMove context env code passVars passValues loc
          val code = addInsn code
                       [
                         AI.Jump {label = codeLabel,
                                  knownDestinations = destinations,
                                  loc = loc}
                       ]
          val code = closeBlock code

          val code = beginBlock code returnLabel AI.LocalCont env loc
          val (context, env, code) =
              makeMove context env code
                       varList
                       (map (AI.Var o transformVarInfo) returnVars)
                       loc
        in
          (context, env, code)
        end

      | AN.ANTAILLOCALCALL {codeLabel, argList, argTyList,
                            resultTyList, knownDestinations, loc} =>
        if (case !knownDestinations of
              [label] => ID.eq (label, #routineLabel env) | _ => false)
        then
          (* self recursive tail call *)
          let
            val {paramVars, selfLoopEntry, selfBackEntry, ...} =
                getRoutineInfo context (#routineLabel env)

            val destination =
                case (selfBackEntry, selfLoopEntry) of
                  (SOME x, _) => x
                | (NONE, SOME x) => x
                | _ => raise Control.Bug "transformDecl: ANTAILLOCALCALL"

            val (context, argList) = transformArgList context env argList

            val (context, env, code) =
                makeMove context env code paramVars argList loc
            val code = addInsn code
                         [
                           AI.Jump {label = AI.Label destination,
                                    knownDestinations = [destination],
                                    loc = loc}
                         ]
          in
            (context, env, code)
          end
        else
          (* tail call to other function *)
          let
            val destinations =
              map (transformCodePoint context) (!knownDestinations)

            val (context, codeLabel) =
                case destinations of
                  [l] => (context, AI.Label l)
                | _ => transformArg context env codeLabel

            val (context, argList) = transformArgList context env argList

            val {linkVar, ...} = getRoutineInfo context (#routineLabel env)

            (* FIXME: type is always matches to callee? *)
            val passTys = AN.CODEPOINT :: argTyList
            val passVars = getPassVars context passTys

            (* pass current link to callee. *)
            val passValues =
                case linkVar of
                  NONE => AI.Nowhere :: argList
                | SOME var => AI.Var (transformVarInfo var) :: argList

            val (context, env, code) =
                makeMove context env code passVars passValues loc
            val code = addInsn code
                         [
                           AI.Jump {label = codeLabel,
                                    knownDestinations = destinations,
                                    loc = loc}
                         ]
          in
            (context, env, code)
          end

      | AN.ANLOCALRETURN {valueList, tyList, loc, knownDestinations} =>
        let
          val (context, valueList) = transformArgList context env valueList

          (* tyList is always identical to resultTyList of this routine. *)
          val returnVars = getPassVars context tyList

          val linkVar =
              case #linkVar (getRoutineInfo context (#routineLabel env)) of
                SOME x => x
              | NONE => raise Control.Bug "transformDecl: LOCALRETURN"

          val (context, env, code) =
              makeMove context env code returnVars valueList loc

          (* knownDestinations only includes returnLabel of LOCALCALL,
           * so no need to call transformCodePoint here. *)
          val codeLabel =
              case !knownDestinations of
                [l] => AI.Label l
              | _ => AI.Var (transformVarInfo linkVar)

          val code = addInsn code
                       [
                         AI.Jump {label = codeLabel,
                                  knownDestinations = !knownDestinations,
                                  loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANVALCODE {codeList, loc} =>
        (*
         * codeDecls are already lifted to toplevel by CallAnalysis, but
         * we need to propagate current substitutions to child code.
         *)
        let
          val context =
              foldl (fn ({codeId, ...}, context) =>
                        addParamMap context codeId (#paramMap env))
                    context
                    codeList
        in
          (context, env, code)
        end

      | AN.ANSWITCH {value, valueTy, branches = nil, default, loc} =>
        transformDeclList context env code default

      | AN.ANSWITCH {value, valueTy, branches, default, loc} =>
        let
          val (context, value) = transformArg context env value

          val branchCases =
              map (fn {constant, branch} =>
                      (constant, newLabel (), branch))
                  branches
          val defaultLabel = newLabel ()

          val (context, code, envList) =
              case branchCases of
                (AN.ANCONST (CT.INT _), _, _)::_ =>
                transformIntSwitch AI.SINT setupSwitchInt
                    context env code value branchCases defaultLabel loc
              | (AN.ANCONST (CT.WORD _), _, _)::_ =>
                transformIntSwitch AI.UINT setupSwitchWord
                    context env code value branchCases defaultLabel loc
              | (AN.ANCONST (CT.CHAR _), _, _)::_ =>
                transformIntSwitch AI.BYTE setupSwitchChar
                    context env code value branchCases defaultLabel loc
              | (AN.ANCONST (CT.BYTE _), _, _)::_ =>
                transformIntSwitch AI.BYTE setupSwitchByte
                    context env code value branchCases defaultLabel loc
              | (AN.ANCONST (CT.STRING _), _, _)::_ =>
                transformStringSwitch
                    context env code value branchCases defaultLabel loc
              | (AN.ANCONST (CT.LARGEINT _), _, _)::_ =>
                transformLargeIntSwitch
                    context env code value branchCases defaultLabel loc
              | (AN.ANCONST (CT.REAL _), _, _)::_ =>
                raise Control.Bug "transformDecl: ANSWITCH REAL"
              | (AN.ANCONST (CT.FLOAT _), _, _)::_ =>
                raise Control.Bug "transformDecl: ANSWITCH FLOAT"
              | (AN.ANCONST CT.UNIT, _, _)::_ =>
                raise Control.Bug "transformDecl: ANSWITCH UNIT"
              | (AN.ANCONST CT.NULLBOXED, _, _)::_ =>
                transformExceptionSwitch
                    context env code value branchCases defaultLabel loc
(*
              | (AN.ANVALUE (AN.ANGLOBALSYMBOL _), _, _)::_ =>
                transformExceptionSwitch
                    context env code value branchCases defaultLabel loc
*)
              | _ =>
                raise Control.Bug "transformDecl: ANSWITCH invalid branches"

          val code = closeBlock code

          val (context, code, branchEnvList) =
              ListPair.foldl
                (fn ((_, label, statement), env, (context, code, envList)) =>
                    let
                      val code =
                          beginBlock code label AI.Branch env loc
                      val (context, env, code) =
                          transformDeclList context env code statement
                      val code = closeBlock code
                    in
                      (context, code, env::envList)
                    end)
                (context, code, nil)
                (branchCases, envList)

          val code = beginBlock code defaultLabel AI.Branch env loc
          val (context, defaultEnv, code) =
              transformDeclList context env code default
          val code = closeBlock code
        in
          (context, env, code)
        end

      | AN.ANHANDLE {try, exnVar, handler,
                     labels={tryLabel, handlerLabel, leaveLabel}, loc} =>
        let
          val exnVar = transformVarInfo exnVar

          val code =
              addInsn code
                [
                  AI.ChangeHandler
                    {change = AI.PushHandler {popHandlerLabel = leaveLabel},
                     previousHandler = #handler env,
                     newHandler = AI.StaticHandler handlerLabel,
                     tryBlock = tryLabel,
                     loc = loc}
                ]
          val tryEnv = setHandler env (AI.StaticHandler handlerLabel)
          val code = closeBlock code
          val code = beginBlock code tryLabel AI.Basic tryEnv loc
          val (context, tryEnv, code) =
              transformDeclList context tryEnv code try
          val code = closeBlock code

          val exnArg = newArg (AI.BOXED, AI.Exn)
          val code = beginBlock code handlerLabel (AI.Handler exnArg) env loc
          val code = addInsn code
                       [
                         AI.Get  {dst = exnVar,
                                  ty = #ty exnVar,
                                  src = exnArg,
                                  loc = loc}
                       ]
          val (context, handlerEnv, code) =
              transformDeclList context env code handler
          val code = closeBlock code
        in
          (context, env, code)
        end

      | AN.ANMERGE {label, varList, loc} =>
        let
          val code = addInsn code
                       [
                         AI.Jump {label = AI.Label label,
                                  knownDestinations = [label],
                                  loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANMERGEPOINT {label, varList, leaveHandler, loc} =>
        let
          val code = closeBlock code

          val code =
              case leaveHandler of
                NONE =>
                beginBlock code label AI.Merge env loc
              | SOME {tryLabel, handlerLabel} =>
                let
                  val tryEnv = setHandler env (AI.StaticHandler handlerLabel)
                  val label2 = newLabel ()
                  val code = beginBlock code label AI.Merge tryEnv loc
                  val code =
                      addInsn code
                        [
                         AI.ChangeHandler
                           {change = AI.PopHandler
                                         {pushHandlerLabel = tryLabel},
                            previousHandler = AI.StaticHandler handlerLabel,
                            newHandler = #handler env,
                            tryBlock = label2,
                            loc = loc}
                        ]

                  val code = closeBlock code
                  val code = beginBlock code label2 AI.Basic env loc
                in
                  code
                end
        in
          (context, env, code)
        end

  and transformDeclList context env code (andecl::declList) =
      let
        val (context, env, code) = transformDecl context env code andecl
      in
        transformDeclList context env code declList
      end
    | transformDeclList context env code nil = (context, env, code)


  (*********************************************************************)

  (* functionId -> clusterId to which the function belongs *)
  fun makeFunIdMap clusterCodeList =
      foldl
        (fn ({clusterId, entryFunctions, ...}:AN.clusterDecl, funIdMap) =>
            foldl (fn (label, funIdMap) =>
                      ID.Map.insert (funIdMap, label, clusterId))
                  funIdMap
                  (map #codeId entryFunctions))
        ID.Map.empty
        clusterCodeList

  fun makeParamMap (argVarList:AN.varInfo list) resultTyList =
      let
        val argTys = map (transformTy o #ty) argVarList
        val retTys = map transformTy resultTyList

        val (_, paramMap) =
            foldl (fn ({id,ty,...}, (n, paramMap)) =>
                      let
                        val ty = transformTy ty
                        val argKind = AI.Param {index = n, argTys = argTys,
                                                retTys = retTys}
                        val arg = {id = id, ty = ty, argKind = argKind}
                                  : AI.argInfo
                      in
                        (n + 1, ID.Map.insert (paramMap, id, arg))
                      end)
                 (0, ID.Map.empty)
                  argVarList
      in
        paramMap
      end

  fun makeFrameBitmap envArg paramMap
                      ({tyvars, bitmapFree, tagArgList}:AN.frameInfo) =
      let
        val bitmapFree =
            case (bitmapFree, envArg) of
              (AN.ANVALUE (AN.ANWORD 0w0), _) => NONE
            | (AN.ANENVACC {nestLevel = 0w0, offset,
                            size = AN.ANWORD size,
                            ty = AN.UINT}, SOME envArg) =>
              (* ASSERT: size must be equal to the size of a bitmap word. *)
              SOME (AI.EnvBitmap (envArg, BasicTypes.UInt32ToWord offset))
            | _ => raise Control.Bug "makeFrameBitmap: invalid bitmapFree"

        fun make (tid::tyvars, arg::tagArgList) =
            let
              val arg = case ID.Map.find (paramMap, #id (arg:AN.varInfo)) of
                          SOME arg => arg
(* {id, ty, argKind = AI.Param x} => x *)
                          | _ => raise Control.Bug "makeFrameBitmap"
            in
              {source = AI.BitParam arg, bits = [SOME tid]}
              :: make (tyvars, tagArgList)
            end
          | make (nil, arg::args) =
            raise Control.Bug "makeFreeBitmap"
          | make (nil, nil) = nil
          | make (tyvars, nil) =
            case bitmapFree of
              NONE => raise Control.Bug "makeFrameBitmap: freeBits"
            | SOME source =>
              [{source = source, bits = map SOME tyvars}]
      in
        make (tyvars, tagArgList)
      end

  (*********************************************************************)

  (*
   * Overview of the structure of cluster:
   *
   *     [ ENTER ]---------------------------------------+-- ...
   *         |                                           |
   *         v                                           v
   * FunEntry                                    FunEntry
   * +-----------------+                         +-----------------+
   * | localA1 = arg1  |                         | localB1 = arg1  |
   * | ...             |                         | ...             |
   * | localAN = argN  |                         | localBN = argN  |
   * +-----------------+                         +-----------------+
   *         |                                            |
   *         v                                            v
   * CodeEntry                                   CodeEntry
   * +-----------------+                         +-----------------+
   * | goto            |<---[from other]    +--->|                 |
   * +-----------------+    [ function ]    |    +-----------------+
   *  Aggregate backedges                   |             |
   *         |                              |             :
   *         v                              |
   * SelfLoopEntry                          |
   * +------------------+                   |
   * | ...              |<---+              |
   * +------------------+    |              |
   *         |               |              |
   *        ...              |              |
   *         v               |              |
   * +-------------------+   |   +----------------------+
   * | ...               |---|-->| ...                  |
   * | switch(v) { ... } |   |   | localB1 = value1     |
   * +-------------------+   |   | ...                  |
   *         |               |   | localBN = valueN     |
   *        ...              |   | goto CodeEntryB      |
   *         v               |   +----------------------+
   * +-------------------+   |            non-mutual tail call
   * | ...               |---|----------+
   * | switch(v) { ... } |   |          |
   * +-------------------+   |          v
   *         |               |   +-------------------+
   *        ...              |   | ...               |
   *         v               |   | localA1 = value1  |
   * +-------------------+   |   | ...               |
   * | ...               |   |   | localAN = valueN  |
   * | return ret1       |   |   | goto SelfBackEntry| self tail call
   * +-------------------+   |   +-------------------+
   *         |               |          |
   *         |               |          v
   *         |               |   SelfBackEntry
   *         |               |   +-------------------+
   *         |               +---| goto SelfRecEntry |
   *         |                   +-------------------+
   *         |                    Aggregate backedges
   *         |
   *         |
   *         v
   *      [ EXIT ] <------- ...
   *
   * FunEntry receives arguments by params.
   * CodeEntry receives arguments by passVars and copy them to paramVars.
   * SelfLoopEntry receives arguments by paramVars.
   *)
  fun transformRoutine context globalParamMap envArg code
                       ({codeId, body, argVarList, resultTyList,
                         ffiAttributes,
                         loc, paramVars, linkVar,
                         initialHandlers,
                         funEntry, codeEntry, selfLoopEntry,
                         selfBackEntry}:routineInfo) =
      let
        val paramValues =
            map (AI.Var o transformVarInfo) paramVars

        val argTyList = map #ty argVarList

        (* compose my paramMap parent's paramMap in order to deal with
         * parent's param occurring freely in the body.
         *)
        val parentParamMap =
            case ID.Map.find (#paramMapMap context, codeId) of
              SOME x => x
            | NONE => ID.Map.empty
        val paramMap =
            ListPair.foldl (fn ({id, ...}, value, paramMap) =>
                               ID.Map.insert (paramMap, id, value))
                           parentParamMap
                           (argVarList, paramValues)

        val initialHandler =
            case initialHandlers of
              nil => AI.NoHandler
            | [NONE] => AI.NoHandler
            | [SOME l] => AI.StaticHandler l
            | h::t =>
              AI.DynamicHandler
                  {outside = case h of NONE => true | _ => false,
                   handlers = map valOf (List.filter isSome initialHandlers)}
              handle Option =>
                     raise Control.Bug "transformRoutine: initialHandler"

        val env =
            {
              routineLabel = codeId,
              paramMap = paramMap,
              handler = AI.NoHandler
            } : environment

        (* function entry *)
        val (context, env, code) =
            case funEntry of
              NONE => (context, env, code)
            | SOME label =>
              (* load all parameters to local variables *)
              let
                val argTys = map transformTy argTyList
                val retTys = map transformTy resultTyList

                val params =
                    map (fn {id,...} =>
                            case ID.Map.find (globalParamMap, id) of
                              SOME param => param
                            | NONE => raise Control.Bug
                                                "transformRoutine: FunEntry")
                        argVarList

                val kind =
                    case ffiAttributes of
                      NONE => AI.FunEntry {argTyList = argTys,
                                           resultTyList = retTys,
                                           env = envArg,
                                           argVarList = params}
                    | SOME attributes =>
                      AI.ExtFunEntry {argTyList = argTys,
                                      resultTyList = retTys,
                                      env = envArg,
                                      argVarList = params,
                                      attributes = attributes}
(*
                val kind = AI.FunEntry (linkArg::envArg::params)
*)
                val code = beginBlock code label kind env loc

                fun load (var::varList) (param::paramList) =
                    let
                      val dst = transformVarInfo var
                    in
                      AI.Get {dst = dst,
                              ty = #ty dst,
                              src = param,
                              loc = loc}
                      :: load varList paramList
                    end
                  | load nil nil = nil
                  | load _ _ =
                    raise Control.Bug "transformRoutine: loadParam"

                (* load closure environment *)
                val code =
                    case (#envVar context, envArg) of
                      (NONE, NONE) => code
                    | (SOME envVar, SOME envArg) =>
                      addInsn code
                          [
                            AI.Get {dst = envVar,
                                    ty = AI.BOXED,
                                    src = envArg,
                                    loc = loc}
                          ]
                    | _ => raise Control.Bug "transformRoutine: envVar"

                (* load parameters to local variables *)
                val loadCode =
                    case codeEntry of
                      (* no CodeEntry; move args to paramVars directly *)
                      NONE => load paramVars params
                    | (* move args to passVars at first.
                       * CodeEntry will move them to paramVars. *)
                      SOME _ =>
                      let
                        val passTys = AN.CODEPOINT::argTyList
                        val vars = getPassVars context passTys
                      in
                        AI.Move {dst = transformVarInfo (hd vars),
                                 ty = AI.CODEPOINTER,
                                 value = AI.Nowhere,
                                 loc = loc}
                        :: load (tl vars) params
                      end

                val code = addInsn code loadCode
              in
                (context, env, code)
              end

        (* code entry *)
        val (context, env, code) =
            case codeEntry of
              NONE => (context, env, code)
            | SOME label =>
              let
                (* receive arguments and immediately move them to paramVars. *)
                val passTys = AN.CODEPOINT::argTyList
                val passVars = getPassVars context passTys

                val {dsts, argVars} =
                    case (passVars, linkVar) of
                      (lp::args, SOME lv) =>
                      {
                        dsts = lv::paramVars,
                        argVars = lp::args
                      }
                    | (lp::args, NONE) =>
                      {
                        dsts = paramVars,
                        argVars = args
                      }
                    | _ => raise Control.Bug "transformRoutine: CodeEntry"

                val argValues =
                    map (AI.Var o transformVarInfo) argVars

                (* enable initial handler temporally *)
                val env = setHandler env initialHandler

                val code =
                    forceBeginBlock code label AI.CodeEntry env loc
              in
                makeMove context env code dsts argValues loc
              end

        val env = setHandler env initialHandler

        (* self loop entry *)
        val code =
            case selfLoopEntry of
              SOME label =>
              forceBeginBlock code label AI.Basic env loc
            | NONE =>
              (* forcely begin new block in order to enable handler setting *)
              case #handler env of
                AI.NoHandler => code
              | _ => forceBeginBlock code (newLabel ()) AI.Basic env loc

        (* generate body *)
        val (context, env, code) = transformDeclList context env code body
        val code = closeBlock code

        (* self back entry *)
        val code =
            case selfBackEntry of
              NONE => code
            | SOME label =>
              let
                val selfLoopLabel =
                    case selfLoopEntry of
                      SOME x => x
                    | NONE => raise Control.Bug "transformRoutine:selfBackEntry"

                val code = beginBlock code label AI.Merge env loc
                val code = addInsn code
                             [
                               AI.Jump  {label = AI.Label selfLoopLabel,
                                         knownDestinations = [selfLoopLabel],
                                         loc = loc}
                             ]
                val code = closeBlock code
              in
                code
              end
      in
        (context, code)
      end

  fun prepareRoutineInfo {routineInfoMap, paramMap, passVars}
                         ({label, routine, callCount, tailCallCount,
                           selfCallCount, handlers}:CA.routineInfo) =
      let
        val {codeId, body, argVarList, resultTyList, ffiAttributes, loc, ...} =
            case routine of
              CA.EntryFunction x => x
            | CA.Code {codeId, argVarList, body, resultTyList, loc} =>
              {codeId = codeId,
               argVarList = argVarList,
               body = body,
               resultTyList = resultTyList,
               ffiAttributes = NONE,
               loc = loc}
            | CA.Continue _ => raise Control.Bug "prepareRoutineInfo: Continue"

        (* paramMap is a map from parameter variable IDs to AI.argInfo.
         *)
        val myParamMap = makeParamMap argVarList resultTyList

        (*
         * Some parameters may be shared among functions in a cluster.
         * We allow RBUTransformation introducing such shared parameters
         * to add extra parameters for polymorphic functions.
         * If a parameter is shared, then its index in the parameter
         * list of each function must be same.
         * (Currently, RBUTransformation doesn't generate such shared args.)
         *)
        val newParamMap =
            ID.Map.unionWith
              (fn (x as {id, ty=_, argKind=AI.Param {index=n1,...}},
                   {id=_, ty=_, argKind=AI.Param {index=n2,...}}) =>
                  if n1 = n2 then x
                  else raise Control.Bug ("prepareRoutineInfo: "
                                          ^ID.toString id)
                | _ => raise Control.Bug "prepareRoutineInfo")
              (paramMap, myParamMap)

        (* Local function have link variable, which holds return address
         * from this local function.
         *)
        val linkVar =
            case routine of
              CA.Code _ => SOME (newANVarInfo AN.CODEPOINT AN.LOCAL)
            | _ => NONE

        (* Entry function have a function entry. *)
        val funEntry =
            case routine of
              CA.EntryFunction {codeId, ...} => SOME codeId
            | _ => NONE

        (* Local function have a code entry, which is an internal entry
         * for calling the local function.
         * Entry function may have a code entry if the function may
         * call from other functions in the same cluster.
         *)
        val codeEntry =
            if callCount + tailCallCount > 0
               orelse (case funEntry of NONE => true | _ => false)
            then case routine of
                   CA.Code {codeId, ...} => SOME codeId
                 | _ => SOME (newLabel ())
            else NONE

        (* entry for self recursive tail local calls *)
        val selfLoopEntry =
            if selfCallCount > 0
            then SOME (newLabel ()) else NONE

        (* entry for aggregation of backedges of self loops *)
        val selfBackEntry =
            if selfCallCount >= 2
            then SOME (newLabel ()) else NONE

        (* Before entering function body, a function loads all parameters
         * to local variables. Entry functions do this at function entry,
         * and local functions do this at code entry.
         *)
        val paramVars =
            map (fn {ty,...} => newANVarInfo ty AN.LOCAL) argVarList

        (*
         * Internal entry of each routine receives arguments from
         * variables. Internal call is realized by JUMP and MOVEs.
         *
         * Note that if arbitrary two functions have same type, we
         * need to use same sequence of local variables for passing
         * arguments, because both of such two functions may be
         * destinations of one identical indirect JUMP.
         *
         * The same is true of variables for passing return values of
         * LOCALRETURN.
         *)
        val passVars =
            case (linkVar, codeEntry) of
              (NONE, NONE) => passVars
            | _ => ensureVars passVars (AN.CODEPOINT::map #ty argVarList)

        val passVars =
            case routine of
              CA.Code _ => ensureVars passVars resultTyList
            | _ => passVars

        val routine = {
           codeId = codeId,
           body = body,
           argVarList = argVarList,
           resultTyList = resultTyList,
           ffiAttributes = ffiAttributes,
           paramVars = paramVars,
           linkVar = linkVar,
           initialHandlers = handlers,
           funEntry = funEntry,
           codeEntry = codeEntry,
           selfLoopEntry = selfLoopEntry,
           selfBackEntry = selfBackEntry,
           loc = loc
         } : routineInfo
      in
	{
          paramMap = newParamMap,
          passVars = passVars,
          routineInfoMap = ID.Map.insert (routineInfoMap, label, routine)
        }
      end

  fun transformCluster funIdMap (clusterDecl as {clusterId, frameInfo,
                                                 entryFunctions=_,
                                                 hasClosureEnv,
                                                 loc, ...}:AN.clusterDecl) =
      let
        val clusterDecl = Simplify.reduceCluster clusterDecl
        val routines = CallAnalysis.analyze clusterDecl

        val {routineInfoMap, passVars, paramMap} =
            foldl (fn ({routine = CA.Continue _, ...}, z) => z
                    | (routineInfo, z) => prepareRoutineInfo z routineInfo)
                  {routineInfoMap = ID.Map.empty,
                   paramMap = ID.Map.empty,
                   passVars = nil}
                  routines

        val linkVar = newVar AI.CODEPOINTER
        val (envVar, envArg) =
            if hasClosureEnv
            then (SOME (newVar AI.BOXED), SOME (newArg (AI.BOXED, AI.Env)))
            else (NONE, NONE)

        val frameBitmap = makeFrameBitmap envArg paramMap frameInfo
(*
        val genTyMap = makeGenTyMap paramMap frameInfo
*)

        val context =
            {
              raiseDivLabel = NONE,
              raiseSizeLabel = NONE,
              boundaryCheckFailedLabel = NONE,
              envVar = envVar,
              linkVar = linkVar,
              funIdMap = funIdMap,
              routineInfoMap = routineInfoMap,
              paramMapMap = ID.Map.empty,
              passVars = passVars,
              constants = ID.Map.empty
            } : context

        val code =
            {
              blocks = nil,
              currentBlock = NONE,
              insns = nil
            } : code

        val (context, code) =
            foldl
              (fn ({routine = CA.Continue _, ...}, z) => z
                | ({label, ...}, (context, code)) =>
                  let
                    val routineInfo =
                        valOf (ID.Map.find (routineInfoMap, label))
                  in
                    transformRoutine context paramMap envArg code routineInfo
                  end)
              (context, code)
              routines
      in
        (#constants context,
         {
           frameBitmap = frameBitmap,
           name = clusterId,
           body = rev (#blocks code),
           loc = loc
         } : AI.cluster)
      end

(*
  fun transformClusterList funIdMap (cluster::clusters) =
      let
        val (constants, cluster) =
            transformCluster funIdMap cluster
        val (constants2, clusters) =
            transformClusterList funIdMap clusters
        val constants =
            ID.Map.unionWith (fn _ => raise Control.Bug "doubled")
                             (constants, constants2)
      in
        (constants, cluster::clusters)
      end
    | transformClusterList funIdMap nil =
      (ID.Map.empty, nil)
*)




  val emptyProgram =
      {
        toplevel = NONE,
        constants = ID.Map.empty,
        globals = SEnv.empty,
        clusters = nil
      } : AI.program

  fun programWithSingleGlobal (k,v) =
      {
        toplevel = NONE,
        constants = ID.Map.empty,
        globals = SEnv.singleton (k, v),
        clusters = nil
      } : AI.program

  fun programWithSingleConst (k,v) =
      {
        toplevel = NONE,
        constants = VarID.Map.singleton (k, v),
        globals = SEnv.empty,
        clusters = nil
      } : AI.program

  fun programWithSingleData (AN.TOP_GLOBAL name, v) =
      programWithSingleGlobal (name, AI.GlobalData v)
    | programWithSingleData (AN.TOP_LOCAL id, v) =
      programWithSingleConst (id, v)

  fun mergeProgram (p1:AI.program, p2:AI.program) =
      let
        fun fail _ = raise Control.Bug "mergeProgram"
        fun mergeopt (NONE, NONE) = NONE
          | mergeopt (SOME x, NONE) = SOME x
          | mergeopt (NONE, SOME x) = SOME x
          | mergeopt (SOME _, SOME _) = raise Control.Bug "mergeProgram"
      in
        {
          toplevel = mergeopt (#toplevel p1, #toplevel p2),
          constants = ID.Map.unionWith fail (#constants p1, #constants p2),
          globals = SEnv.unionWith fail (#globals p1, #globals p2),
          clusters = #clusters p1 @ #clusters p2
        } : AI.program
      end

  fun transformTopdecl funIdMap topdecl =
      case topdecl of
        AN.ANCLUSTER cluster =>
        let
          val (constants, cluster) = transformCluster funIdMap cluster
        in
          {
            toplevel = NONE,
            constants = constants,
            globals = SEnv.empty,
            clusters = [cluster]
          }
        end

      | AN.ANTOPCONST {globalName, constant} =>
        let
          val value =
              case constant of
                CT.STRING x => AI.StringData x
              | CT.LARGEINT x => AI.IntInfData x
              | CT.REAL x => AI.PrimData (AI.RealData x)
              | CT.FLOAT x => AI.PrimData (AI.FloatData x)
              | _ => raise Control.Bug "ANTOPCONST"
        in
          programWithSingleData (globalName, value)
        end

      | AN.ANTOPRECORD {globalName, bitmaps, totalSize, fieldList,
                        fieldTyList, fieldSizeList, isMutable} =>
        let
          fun makeFields (field::fields, size::sizes) =
              {value = transformPrimData funIdMap field,
               size = Target.toUInt size}
              :: makeFields (fields, sizes)
            | makeFields (nil, nil) = nil
            | makeFields _ = raise Control.Bug "ANTOPRECORD"

          val data =
              AI.ObjectData {objectType = AI.Record  {mutable=isMutable},
                             bitmaps = map Target.toUInt bitmaps,
                             payloadSize = Target.toUInt totalSize,
                             fields = makeFields (fieldList, fieldSizeList)}
        in
          programWithSingleData (globalName, data)
        end

      | AN.ANTOPARRAY {globalName,
                       bitmap, totalSize,
                       initialValues, elementTy, elementSize,
                       isMutable} =>
        let
          val size = Target.toUInt elementSize
          val data =
              AI.ObjectData
                {objectType = if isMutable then AI.Array else AI.Vector,
                 bitmaps = [Target.toUInt bitmap],
                 payloadSize = Target.toUInt totalSize,
                 fields = map (fn x => {value=transformPrimData funIdMap x,
                                        size=size})
                              initialValues}
        in
          programWithSingleData (globalName, data)
        end

      | AN.ANTOPVAR {globalName, initialValue, elementTy, elementSize} =>
        let
          val data =
              AI.VarSlot {size = Target.toUInt elementSize,
                          value = Option.map (transformPrimData funIdMap)
                                             initialValue}
        in
          programWithSingleData (globalName, data)
        end

      | AN.ANTOPCLOSURE {globalName, funLabel, closureEnv} =>
        let
          val {closureBitmap, closureFieldTys, closureFieldSizes, closureSize,
               closureFieldIndexes} = closureLayout ()
        in
          transformTopdecl funIdMap
            (AN.ANTOPRECORD {globalName = globalName,
                             bitmaps = [closureBitmap],
                             totalSize = closureSize,
                             fieldList = [closureEnv, AN.ANLABEL funLabel],
                             fieldTyList = closureFieldTys,
                             fieldSizeList = closureFieldSizes,
                             isMutable = false})
        end

      | AN.ANTOPALIAS {globalName, originalGlobalName} =>
        (
          case (globalName, originalGlobalName) of
            (AN.TOP_GLOBAL name, AN.TOP_GLOBAL origName) =>
            programWithSingleGlobal (name, AI.GlobalAlias origName)
          | _ => raise Control.Bug "ANTOPALIAS: EXTERNNAME"
        )

      | AN.ANENTERTOPLEVEL id =>
        let
          val clusterId =
              case ID.Map.find (funIdMap, id) of
                SOME x => x
              | NONE => raise Control.Bug "ANENTERTOPLEVEL"
        in
          {
            toplevel = SOME {clusterId = clusterId, entry = id},
            constants = ID.Map.empty,
            globals = SEnv.empty,
            clusters = nil
          }
        end

  fun transformTopdeclList funIdMap (topdecl::topdecls) =
      let
        val p1 = transformTopdecl funIdMap topdecl
        val p2 = transformTopdeclList funIdMap topdecls
      in
        mergeProgram (p1, p2)
      end
    | transformTopdeclList funIdMap nil = emptyProgram

  fun generate topdeclList =
      let

        val clusters =
            List.mapPartial (fn AN.ANCLUSTER x => SOME x | _ => NONE)
                            topdeclList

        val funIdMap = makeFunIdMap clusters
        val program = transformTopdeclList funIdMap topdeclList

(*
        val (constants, clusters) =
            transformClusterList funIdMap clusterList

        (* first entry of first cluster is the toplevel entry *)
        fun firstEntry (nil:AI.basicBlock list) = raise Control.Bug "firstEntry"
          | firstEntry ({blockKind=AI.FunEntry _,label,...}::_) = label
          | firstEntry (_::t) = firstEntry t
        val firstCluster = List.hd clusters
        val toplevel = SOME {clusterId = #name firstCluster,
                             entryLabel = firstEntry (#body firstCluster)}

        val program =
            {
              toplevel = toplevel,
              clusters = clusters,
              constants = constants,
              globals = globals
            } : AI.program
*)
      in
        program
      end
      handle exn => raise exn

end





(*
  fun transformTopdecl funIdMap topdecl =
      case topdecl of
        AN.ANCLUSTER cluster =>
        let
          val (contstants, cluster) = transformCluster funIdMap cluster
        in
          {
            constants = constants,
            globals = nil,
            clusters = clusters
          }
        end

      | AN.ANTOPCONST {globalName, export, constant} =>
        let
          val const =
              case constant of
                CT.STRING x => AI.ConstString x
              | CT.REAL x => AI.ConstReal x
              | CT.FLOAT x => AI.ConstFloat x
              | CT.BIGINT x => AI.ConstIntInf x
              | _ => raise Control.Bug "ANTOPCONST"
          val global =
              {
                export = export,
                value = const
              }
        in
          {
            constants = ID.Map.empty,
            globals = SEnv.singleton (globalName, global),
            clusters = nil
          }
        end

      | AN.ANTOPRECORD {globalName, export, bitmaps, totalSize, fieldList,
                        fieldTyList, fieldSizeList} =>
        let
          val const =
              AI.ConstObject {objectType = AI.Record,
                              bitmaps = bitmaps,
                              payloadSize = totalSize,
                              fields: {size =, value = }}
          val global =
              {
                export = export,
                value = const
              }
        in
          {
            constants = ID.Map.empty,
            globals = SEnv.singleton (globalName, global),
            clusters = nil
          }
        end

      | AN.ANTOPARRAY {globalName, export, externalVarID, bitmap, totalSize,
                       initialValues, elementTy, elementSize, isMutable} =>
        let
          val const =
              AI.ConstObject {objectType =
                              if isMutable then AI.Array else AI.Vector,
                              bitmaps = bitmaps,
                              payloadSize = totalSize,
                              fields: {size =, value = }}


        in


        end

      | AN.ANTOPCLOSURE {globalName, export, funLabel} =>

      | AN.ANTOPALIAS {globalName, export, originalGlobalName} =>

      | AN.ANENTERTOPLEVEL id =>






*)
