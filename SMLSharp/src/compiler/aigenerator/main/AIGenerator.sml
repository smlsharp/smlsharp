(**
 * abstract instruction generator
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: AIGenerator.sml,v 1.27 2008/12/10 11:37:21 katsu Exp $
 *)
structure AIGenerator : AIGENERATOR =
struct

  structure ID = VarID
  structure CT = ConstantTerm
  structure AN = YAANormal
  structure AI = AbstractInstruction
  structure Target = AI.Target
  structure CA = CallAnalysis

  fun newLocalId () = ID.generate ()

  (* FIXME: nested block; adjust with RBUTransformation *)
  val nestedBlockIndex = AI.UInt 0w0

  (* FIXME: platform dependent *)
  fun sizeOfExnTag () = AI.UInt (if Control.nativeGen() then 0w4 else 0w1)
  fun sizeOfBoxed () = AI.UInt (if Control.nativeGen() then 0w4 else 0w1)
  fun sizeOfEntry () = AI.UInt (if Control.nativeGen() then 0w4 else 0w1)

  (* for YASIGenerator *)
  fun toSISize value =
      case value of
        AI.UInt 0w1 => AI.SISINGLE
      | AI.UInt 0w2 => AI.SIDOUBLE
      | AI.Var varInfo => AI.SIVARIANT varInfo
      | AI.Param paramInfo => AI.SIPARAMVARIANT paramInfo
      | _ => AI.SIIGNORE

  val SubscriptExceptionTag =
      let
        val tag = #tag PredefinedTypes.SubscriptExnPathInfo
        val tag = ExnTagID.toInt tag
        val tag = BasicTypes.UInt32.fromInt tag
      in
        AI.Extern {ty = AI.BOXED,
                   label = {label = "__Exn_Subscript__",
                            value = SOME (AI.GLOBAL_TAG tag)}}
      end

  val CopyBlock = AIPrimitive.CopyBlock

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
  (* global index allocation is just for YASIGenerator. *)

  type globalIndexAllocator =
      {
        find: ExVarID.id -> AI.globalIndex option,
        alloc: ExVarID.id * ANormal.ty -> unit
      }

  val globalIndexAllocatorRef = ref NONE : globalIndexAllocator option ref

  fun findGlobalIndex extId =
      case !globalIndexAllocatorRef of
        NONE => NONE
      | SOME globalIndexAllocator =>
        case #find globalIndexAllocator extId of
          NONE => raise Control.Bug ("findGlobalIndex: undefined external ID"
                                     ^ExVarID.toString extId)
        | SOME index => SOME (AI.GLOBAL_VAR index)

  fun allocGlobalIndex extId ty =
      case !globalIndexAllocatorRef of
        NONE => ()
      | SOME globalIndexAllocator =>
        let
          val ilty =
              case ty of
                AI.BOXED => ANormal.BOXED
              | AI.ATOMty => ANormal.ATOM
              | AI.DOUBLEty => ANormal.DOUBLE
              | _ => ANormal.ATOM
        in
          #alloc globalIndexAllocator (extId, ilty)
        end

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
         params: AI.paramInfo list,
         argTyList: AN.ty list,
         argSizeList: AN.siexp list,
         resultTyList: AN.ty list,
         ffiAttributes: AN.ffiAttributes option,
         loc: AI.loc,
         (* variables for holding arguments *)
         paramVars: AN.varInfo list,
         (* variable which holds a return address of LOCALRETURN *)
         linkVar: AN.varInfo option,
         (* variable which holds initial handler address *)
         handlerVar: AN.varInfo option,
         (* informations of entry blocks *)
         initialHandlers: AI.label option list,
         funEntry: AI.label option,
         codeEntry: AI.label option,
         selfLoopEntry: AI.label option,
         selfBackEntry: AI.label option
       }

  type context =
       {
         boundaryCheckFailedLabel: AI.label option,
         funIdMap: AI.clusterId ID.Map.map,      (* functionId -> clusterId *)
         tagMap: AI.tag IEnv.map,                (* tid -> AI.tag *)
         routineInfoMap: routineInfo ID.Map.map, (* routineInfo table *)
         (* paramMap for each routine *)
         paramMapMap: AI.value ID.Map.map ID.Map.map,
         passVars: AN.varInfo list,              (* vars for passing values *)
         constants: AI.const ID.Map.map          (* constant table *)
       }

  type environment =
       {
         routineLabel: AI.label,                 (* current code label *)
         paramMap: AI.value ID.Map.map,          (* param -> value *)
         exnVarMap: AI.value ID.Map.map,         (* variable -> Exn value *)
         handler: AI.handler                     (* exception handler *)
       }

  fun addConst (context as {constants, ...}:context) const =
      let
        val constid = newLocalId ()
      in
        ({
           boundaryCheckFailedLabel = #boundaryCheckFailedLabel context,
           funIdMap = #funIdMap context,
           tagMap = #tagMap context,
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
        boundaryCheckFailedLabel = #boundaryCheckFailedLabel context,
        funIdMap = #funIdMap context,
        tagMap = #tagMap context,
        routineInfoMap = #routineInfoMap context,
        paramMapMap = ID.Map.insert (paramMapMap, label, paramMap),
        passVars = #passVars context,
        constants = #constants context
      } : context

  fun setBoundaryCheckFailedLabel (context:context) label =
      {
        boundaryCheckFailedLabel = SOME label,
        funIdMap = #funIdMap context,
        tagMap = #tagMap context,
        routineInfoMap = #routineInfoMap context,
        paramMapMap = #paramMapMap context,
        passVars = #passVars context,
        constants = #constants context
      } : context

  (* for debug *)
  fun currentLoc context ({routineLabel, ...}:environment) =
      Control.prettyPrint
          (Loc.format_loc (#loc (getRoutineInfo context routineLabel)))

  fun setHandler (env:environment) handler =
      {
        routineLabel = #routineLabel env,
        paramMap = #paramMap env,
        exnVarMap = #exnVarMap env,
        handler = handler
      } : environment

  fun addExnVar (env as {exnVarMap, ...}:environment) (param:AI.paramInfo) =
      {
        routineLabel = #routineLabel env,
        paramMap = #paramMap env,
        exnVarMap = ID.Map.insert (exnVarMap, #id param, AI.Exn param),
        handler = #handler env
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

  fun addBlock (code:code) label blockKind (env:environment) insns loc =
      let
        val block =
            {
              label = label,
              blockKind = blockKind,
              handler = #handler env,
              loc = loc,
              instructionList = insns
            } : AI.basicBlock
      in
        {
          blocks = block :: #blocks code,
          currentBlock = #currentBlock code,
          insns = #insns code
        } : code
      end

  (*********************************************************************)

  fun getTag tagMap tid =
      case IEnv.find (tagMap, tid) of
        SOME tag => tag
      | NONE => raise (Control.Bug ("getTag: tid " ^ Int.toString tid))

  fun transformTy' tagMap anty =
      case anty of
        AN.UINT => AI.UINT
      | AN.SINT => AI.SINT
      | AN.BYTE => AI.BYTE
      | AN.CHAR => AI.CHAR
      | AN.BOXED => AI.BOXED
      | AN.POINTER => AI.CPOINTER
      | AN.CODEPOINT => AI.CODEPOINTER
      | AN.FUNENTRY => AI.ENTRY
      | AN.FOREIGNFUN => AI.CPOINTER
      | AN.FLOAT => AI.FLOAT
      | AN.DOUBLE => AI.DOUBLE
      | AN.PAD => raise Control.Bug "transformTy': PAD"
      | AN.SIZE => AI.SIZE
      | AN.INDEX => AI.INDEX
      | AN.BITMAP => AI.BITMAP
      | AN.OFFSET => AI.OFFSET
      | AN.TAG => AI.TAG
      | AN.ATOMty => AI.ATOMty
      | AN.DOUBLEty => AI.DOUBLEty
      | AN.SINGLEty tid =>
        AI.UNION {variants = [AI.ATOMty, AI.BOXED], tag = getTag tagMap tid}
      | AN.UNBOXEDty tid =>
        AI.UNION {variants = [AI.ATOMty, AI.DOUBLEty], tag = AI.Unboxed}
      | AN.GENERIC tid =>
        AI.UNION {variants = AI.allTys, tag = getTag tagMap tid}

  fun transformTy (context:context) anty =
      transformTy' (#tagMap context) anty

  fun transformTyList (context:context) antyList =
      map (transformTy' (#tagMap context)) antyList

  (*
   * MEMO: Every parameter and local variable should have a fixed size type.
   *)
  fun transformParamInfo tagMap (anvarInfo as {id,...}:AN.varInfo) =
      case #varKind anvarInfo of
        AN.ARG =>
        {
          id = id,
          displayName = #displayName anvarInfo,
          ty = transformTy' tagMap (#ty anvarInfo)
        } : AI.paramInfo
      | AN.LOCALARG =>
        {
          id = id,
          displayName = #displayName anvarInfo,
          ty = transformTy' tagMap (#ty anvarInfo)
        } : AI.paramInfo
      | AN.LOCAL =>
        raise Control.Bug ("transformParamInfo: LOCAL " ^ ID.toString id)

  fun transformVarInfo (context:context) (anvarInfo as {id,...}:AN.varInfo) =
      case #varKind anvarInfo of
        AN.LOCAL =>
        {
          id = id,
          displayName = #displayName anvarInfo,
          ty = transformTy' (#tagMap context) (#ty anvarInfo)
        } : AI.varInfo
      | AN.ARG =>
        raise Control.Bug ("transformVarInfo: ARG " ^ ID.toString id)
      | AN.LOCALARG =>
        raise Control.Bug ("transformVarInfo: LOCALARG " ^ ID.toString id)

  fun transformConst context constTerm =
      case constTerm of
        CT.INT n =>
        (context, AI.SInt (Target.toSInt n))
      | CT.WORD n =>
        (context, AI.UInt (Target.toUInt n))
      | CT.BYTE n =>
        (context, AI.UInt (Target.toUInt n))
      | CT.FLOAT r =>
        (context, AI.Float r)
      | CT.CHAR c =>
        (context, AI.UInt (Target.charToUInt c))
      | CT.UNIT =>   (* assume UNIT is an integer. *)
        (context, AI.UInt 0w0)
      | CT.NULL =>
        (context, AI.Null)
      | CT.LARGEINT x =>
        (* LARGEINT is not a first-class value. *)
        raise Control.Bug "transformConst: LARGEINT"
      | CT.STRING s =>
        let
          val (context, constId) = addConst context (AI.ConstString s)
        in
          (context, AI.Const constId)
        end
      | CT.REAL r =>
        if !Control.enableUnboxedFloat
        then (context, AI.Real r)
        else let val (context, constId) = addConst context (AI.ConstReal r)
             in (context, AI.Const constId)
             end

  fun transformBarrier value =
      case value of
        AI.UInt 0w0 => AI.NoBarrier
      | AI.UInt 0w1 => AI.WriteBarrier
      | _ => AI.BarrierTag value

  fun transformExceptionTag ((name, symkind), tag) =
      let
        val tagInt = ExnTagID.toInt tag
(*
            case ExnTagID.getExportNameInID tag of
                         SOME name =>
                         (case (PredefinedTypes.exnTagNameToInt name) of
                              SOME (int: int) => int
                            | NONE => raise Control.Bug "exception tag is not predefined"
                         )
                       | NONE =>
                         case ExnTagID.getNonExportIDInID tag of
                             SOME int => int
                           | NONE => raise Control.Bug "exception tag is not string"
*)
        val tag = BasicTypes.UInt32.fromInt tagInt

        val _ = case symkind of 
                  AN.EXTERNSYMBOL => ()
                | AN.GLOBALSYMBOL => ()
                | _ => raise Control.Bug "transformExceptionTag: symbolKind"
      in
        AI.Extern {label = {label = name, value = SOME (AI.GLOBAL_TAG tag)},
                   ty = AI.BOXED}
      end


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
                                size = sizeOfBoxed (),
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
                            loc = loc,
                            size = AI.SISINGLE},
                (* block = record; *)
                AI.Move    {dst = blockVar,
                            ty = AI.BOXED,
                            value = record,
                            loc = loc,
                            size = AI.SISINGLE},
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
                            size = sizeOfBoxed (),
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

  fun allocRecord context code {dst, bitmap, payloadSize,
                                fieldTyList, fieldSizeList, loc} =
      let
        val tagOf = AbstractInstructionUtils.tagOf

        (* for YASIGenerator *)
        val fieldInfo =
            ListPair.map
              (fn (AN.PAD, size) => {size = toSISize size, tag = AI.Unboxed}
                | (anty, size) =>
                  {size = toSISize size,
                   tag = tagOf (transformTy context anty)})
              (fieldTyList, fieldSizeList)

        (* optimization: use Vector if every field has same tag. *)
        val (objectType, bitmaps) =
            if Control.nativeGen() then
            case bitmap of
              AI.UInt 0w0 => (AI.Vector, [bitmap])
            | AI.UInt _ =>
              if List.all (fn {tag=AI.Boxed, ...} => true | _ => false)
                          fieldInfo
              then (AI.Vector, [AI.UInt 0w1])
              else (AI.Record, [bitmap])
            | _ => (AI.Record, [bitmap])
            (* workaround for YASIGenerator *)
            else (AI.Record, [bitmap])

        val code = addInsn code
                     [
                       AI.Alloc {dst = dst,
                                 objectType = objectType,
                                 bitmaps = bitmaps,
                                 payloadSize = payloadSize,
                                 fieldInfo = fieldInfo,
                                 loc = loc}
                     ]
      in
        code
      end

  fun initializeBlock (context:context) code block
                      antyList sizeList valueList fieldSizeList loc =
      let
        fun initField (code, index, nil, nil, nil, nil) =
            code
          | initField (code, index, [AN.PAD], [_], [_], [_]) =
            (* last field is padding. need to do nothing. *)
            code
          | initField (code, index, [anty], [size], [value], [_]) =
            (* last field; no need to generate next index *)
            let
              val ty = transformTy context anty
              val code = addInsn code
                           [
                             (* FIXME: write barrier is always disabled. OK? *)
                             AI.Update {block = block,
                                        offset = index,
                                        size = size,
                                        ty = ty,
                                        value = value,
                                        barrier = AI.NoBarrier,
                                        loc = loc}
                           ]
            in
              code
            end
          | initField (code, index, anty::antys, size::sizes,
                       value::values, fieldSize::fieldSizes) =
            let
              val code =
                  case anty of
                    AN.PAD => code
                  | _ =>
                    addInsn code
                      [
                       (* FIXME: write barrier is always disabled. OK? *)
                        AI.Update {block = block,
                                   offset = index,
                                   size = size,
                                   ty = transformTy context anty,
                                   value = value,
                                   barrier = AI.NoBarrier,
                                   loc = loc}
                      ]

              val (newIndex, code) =
                  case (index, fieldSize) of
                    (AI.UInt x, AI.UInt y) => (AI.UInt (x + y), code)
                  | _ =>
                    let
                      val newIndex = newVar AI.UINT
                      val code =
                          addInsn code
                            [
                              AI.PrimOp2
                                  {dst = newIndex,
                                   op2 = (AI.Add, AI.UINT, AI.UINT, AI.UINT),
                                   arg1 = index,
                                   arg2 = fieldSize,
                                   loc = loc}
                            ]
                    in
                      (AI.Var newIndex, code)
                    end
            in
              initField (code, newIndex, antys, sizes, values, fieldSizes)
            end
          | initField _ =
            raise Control.Bug "initField"
      in
        initField (code, AI.UInt 0w0,
                   antyList, sizeList, valueList, fieldSizeList)
      end

  fun makeRecord context code
                 (args as {dst, fieldTyList, fieldSizeList, loc, ...})
                 fieldList nextOffsetList =
      let
        val code = allocRecord context code args
        val code = initializeBlock
                       context code (AI.Var dst)
                       fieldTyList fieldSizeList fieldList nextOffsetList
                       loc
      in
        code
      end

  fun makeClosure context code dst funEntry closureEnv loc =
      let
        val closureBitmap = AI.UInt 0w1        (* |BOXED, ENTRY| *)
        val closureFieldTys = [AN.BOXED, AN.FUNENTRY]
        val closureFieldSizes = [sizeOfBoxed(), sizeOfEntry()]
        val closureSize =
            case (sizeOfBoxed(), sizeOfEntry()) of
              (AI.UInt x, AI.UInt y) => AI.UInt (x + y)
            | _ => raise Control.Bug "makeClosure"
      in
        makeRecord context code
                   {dst = dst,
                    bitmap = closureBitmap,
                    payloadSize = closureSize,
                    fieldTyList = closureFieldTys,
                    fieldSizeList = closureFieldSizes,
                    loc = loc}
                   [closureEnv, funEntry]
                   closureFieldSizes
      end

  fun expandClosure code closure entry env loc =
      addInsn code
        [
          AI.Load {dst = env,
                   ty = AI.BOXED,
                   block = closure,
                   offset = AI.UInt 0w0,
                   size = sizeOfBoxed (),
                   loc = loc},
          AI.Load {dst = entry,
                   ty = AI.ENTRY,
                   block = closure,
                   offset = sizeOfBoxed (),
                   size = sizeOfEntry (),
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
        map (fn (x, l) => (AI.UInt x, l)) cases
      end

  fun setupSwitchByte branchCases =
      let
        val cases =
            map (fn (AN.ANCONST (CT.BYTE n), label, _) =>
                    (Target.toUInt n, label)
                  | _ => raise Control.Bug "setupSwitchByte")
                branchCases
        val cases =
            ListSorter.sort
                (fn ((n1, _), (n2, _)) => Target.UInt.compare (n1, n2))
                cases
      in
        map (fn (x, l) => (AI.UInt x, l)) cases
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
                    [
                      (* cmp = cmpOp(strVar, string); *)
                      cmpOp {dst = cmp,
                             arg1 = switchValue,
                             arg2 = caseConst,
                             loc = loc},
                      (* if (cmp == 0) then goto label; *)
                      AI.If {value1 = AI.Var cmp,
                             value2 = AI.SInt 0,
                             op2 = (AI.MonoEqual, AI.SINT, AI.SINT, AI.UINT),
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
              val (context, constId) = addConst context (AI.ConstString x)
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
              val (context, constId) = addConst context (AI.ConstIntInf x)
              val var = newVar AI.BOXED
              val loadInsn =
                  [
                    AIPrimitive.LoadIntInf {dst = var,
                                            arg = AI.Init constId,
                                            loc = loc}
                  ]
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
        val branchCases =
            map (fn (AN.ANVALUE (AN.ANGLOBALSYMBOL {name,
                                                    ann=AN.EXCEPTIONTAG tag,
                                                    ...}),
                     label, _) =>
                    (transformExceptionTag (name, tag), label)
                  | _ => raise Control.Bug "transformExceptionTag")
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
                                    AI.EXNTAG, AI.EXNTAG, AI.UINT),
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
                                    AI.EXNTAG, AI.EXNTAG, AI.UINT),
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

  fun boundaryCheckFailedLabel context env code loc =
      case #boundaryCheckFailedLabel context of
        SOME label => (context, code, label)
      | NONE =>
        let
          val label = newLabel ()
          val context = setBoundaryCheckFailedLabel context label
          val exnValue = newVar AI.EXNTAG
          val code = addBlock code label AI.BoundaryCheckFailed env
                       [
                         AI.Alloc  {dst = exnValue,
                                    objectType = AI.Vector,
                                    bitmaps = [AI.UInt 0w0],
                                    payloadSize = sizeOfExnTag (),
                                    fieldInfo = [{size = toSISize (sizeOfExnTag ()),
                                                  tag = AbstractInstructionUtils.tagOf AI.EXNTAG}],
                                    loc = loc},
                         AI.Update {block = AI.Var exnValue,
                                    offset = AI.UInt 0w0,
                                    size = sizeOfExnTag (),
                                    ty = AI.EXNTAG,
                                    value = SubscriptExceptionTag,
                                    barrier = AI.NoBarrier,
                                    loc = loc},
                         AI.Raise {exn = AI.Var exnValue, loc = loc}
                       ]
                       loc
        in
          (context, code, label)
        end

  (*********************************************************************)

  fun transformCodePoint context label =
      case #codeEntry (getRoutineInfo context label) of
        SOME x => x
      | NONE => raise Control.Bug ("transformCodePoint: no entry point of "^
                                   ID.toString label)

  fun transformArg context (env:environment) anvalue =
      case anvalue of
        AN.ANINT n => (context, AI.SInt (Target.toSInt n))
      | AN.ANWORD n => (context, AI.UInt (Target.toUInt n))
      | AN.ANBYTE n => (context, AI.UInt (Target.toUInt n))
      | AN.ANCHAR c => (context, AI.UInt (Target.charToUInt c))
      | AN.ANUNIT => (context, AI.UInt 0w0)  (* assume UNIT is an integer. *)
      | AN.ANGLOBALSYMBOL {name = (_, AN.UNDECIDED), ...} =>
        raise Control.Bug "transformArg: UNDECIDED"
      | AN.ANGLOBALSYMBOL {name, ann = AN.EXCEPTIONTAG tag, ...} =>
        (context, transformExceptionTag (name, tag))
      | AN.ANGLOBALSYMBOL {name=(name,symkind), ann=AN.GLOBALVAR id, ty} =>
        let
          val ty = transformTy context ty
          val con = case symkind of
                      AN.EXTERNSYMBOL => AI.Extern
                    | AN.GLOBALSYMBOL => AI.Global
                    | AN.UNDECIDED => raise Control.Bug "UNDECIDED"
        in
          (context, con {label = {label = name, value = findGlobalIndex id},
                         ty = ty})
        end
      | AN.ANGLOBALSYMBOL {name=(name,AN.EXTERNSYMBOL),
                           ann = AN.GLOBALOTHER,
                           ty = AN.FOREIGNFUN} =>
        (context,
         AI.Extern {ty = AI.CPOINTER, label = {label = name, value = NONE}})
      | AN.ANGLOBALSYMBOL {ann = AN.GLOBALOTHER, ...} =>
        raise Control.Bug "transformArg: GLOBALOTHER: not implemented"
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
        (case ID.Map.find (#exnVarMap env, id) of
           SOME value => (context, value)
         | NONE => (context, AI.Var (transformVarInfo context varInfo)))
      | AN.ANLABEL codeId =>
        (context, AI.Entry {clusterId = getClusterId context codeId,
                            entry = codeId})
      | AN.ANLOCALCODE codeId =>
        (context, AI.Label (transformCodePoint context codeId))

  fun transformArgList context env (anvalue::anvalueList) =
      let
        val (context, value) = transformArg context env anvalue
        val (context, values) = transformArgList context env anvalueList
      in
        (context, value::values)
      end
    | transformArgList context env nil = (context, nil)

  (* for YASIGenerator *)
  fun transformSISize context env size =
      case size of
        AN.SIIGNORE => (context, AI.SIIGNORE)
      | AN.SISINGLE => (context, AI.SISINGLE)
      | AN.SIDOUBLE => (context, AI.SIDOUBLE)
      | AN.SIVARIANT varInfo =>
        case transformArg context env (AN.ANVAR varInfo) of
          (context, AI.Var v) => (context, AI.SIVARIANT v)
        | (context, AI.Param v) => (context, AI.SIPARAMVARIANT v)
        | _ => (context, AI.SIIGNORE)

  fun transformSISizeList context env (size::sizeList) =
      let
        val (context, size) = transformSISize context env size
        val (context, sizes) = transformSISizeList context env sizeList
      in
        (context, size::sizes)
      end
    | transformSISizeList context env nil = (context, nil)

  (* FIXME: size information is needed only for YASIGeneration. *)
  fun makeMove context env code
               (var::anvarList) (size::sisizeList) (value::valueList) loc =
      let
        val (context, size) = transformSISize context env size
        val dst = transformVarInfo context var
        val code =
            addInsn code
              [
                AI.Move {dst = dst,
                         ty = #ty dst,
                         value = value,
                         loc = loc,
                         size = size}
              ]
      in
        makeMove context env code anvarList sisizeList valueList loc
      end
    | makeMove context env code nil nil nil loc =
      (context, env, code)     (* return env for convenience *)
    | makeMove _ _ _ x y z _ =
      raise Control.Bug ("makeMove "^
                         Int.toString (length x)^","^
                         Int.toString (length y)^","^
                         Int.toString (length z))

  fun transformDecl context env code andecl =
      case andecl of
        AN.ANVAL {varList, sizeList,
                  exp = AN.ANCONST (CT.LARGEINT n),
                  loc} =>
        let
          val dst = transformVarInfo context (onlyOne varList)
          val (context, constId) = addConst context (AI.ConstIntInf n)
          val code =
              addInsn code
                [
                  AIPrimitive.LoadIntInf {dst = dst,
                                          arg = AI.Init constId,
                                          loc = loc}
                ]
        in
          (context, env, code)
        end

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANCONST const,
                  loc} =>
        let
          val (context, value) = transformConst context const
        in
          makeMove context env code varList sizeList [value] loc
        end

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANVALUE anvalue,
                  loc} =>
        let
          val (context, value) = transformArg context env anvalue
        in
          makeMove context env code varList sizeList [value] loc
        end

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANRECORD {totalSize = AN.ANWORD 0w0,
                                     ...},
                  loc} =>
        makeMove context env code varList sizeList [AI.Empty] loc

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANENVRECORD {totalSize = 0w0, ...},
                  loc} =>
        makeMove context env code varList sizeList [AI.Empty] loc

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANARRAY {totalSize = AN.ANWORD 0w0,
                                    isMutable = false,
                                    ...},
                  loc} =>
        makeMove context env code varList sizeList [AI.Empty] loc

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANENVACC {nestLevel, offset, size, ty},
                  loc} =>
        let
          val dst = transformVarInfo context (onlyOne varList)
          val (context, size) = transformArg context env size
          val nestLevel = AI.UInt (Target.toUInt nestLevel)
          val offset = AI.UInt (Target.toUInt offset)
          val ty = transformTy context ty

          val (code, block) =
              unrollNestedBlock env code AI.Env nestLevel loc
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

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANSELECT {record, nestLevel, offset, size, ty},
                  loc} =>
        let
          val dst = transformVarInfo context (onlyOne varList)
          val (context, record) = transformArg context env record
          val (context, nestLevel) = transformArg context env nestLevel
          val (context, offset) = transformArg context env offset
          val (context, size) = transformArg context env size
          val ty = transformTy context ty

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

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANGETFIELD {array, offset, size, ty,
                                       needBoundaryCheck},
                  loc} =>
        let
          val dst = transformVarInfo context (onlyOne varList)
          val (context, array) = transformArg context env array
          val (context, offset) = transformArg context env offset
          val (context, size) = transformArg context env size
          val ty = transformTy context ty

          val (context, code) =
              case needBoundaryCheck of
                false => (context, code)
              | true =>
                let
                  val passLabel = newLabel ()
                  val (context, code, failLabel) =
                      boundaryCheckFailedLabel context env code loc

                  val code = addInsn code
                               [
                                 AI.CheckBoundary {block = array,
                                                   offset = offset,
                                                   passLabel = passLabel,
                                                   failLabel = failLabel,
                                                   loc = loc}
                               ]
                  val code = closeBlock code
                  val code = beginBlock code passLabel AI.Branch env loc
                in
                  (context, code)
                end

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
                       needBoundaryCheck, loc} =>
        let
          (* alloc global *)
          val (context, array) = transformArg context env array
          val (context, offset) = transformArg context env offset
          val (context, value) = transformArg context env value
          val valueTy = transformTy context valueTy
          val (context, valueSize) = transformArg context env valueSize
          val (context, valueTag) = transformArg context env valueTag
          val barrier = transformBarrier valueTag

          val (context, code) =
              case needBoundaryCheck of
                false => (context, code)
              | true =>
                let
                  val passLabel = newLabel ()
                  val (context, code, failLabel) =
                      boundaryCheckFailedLabel context env code loc

                  val code = addInsn code
                               [
                                 AI.CheckBoundary {block = array,
                                                   offset = offset,
                                                   passLabel = passLabel,
                                                   failLabel = failLabel,
                                                   loc = loc}
                               ]
                  val code = closeBlock code
                  val code = beginBlock code passLabel AI.Branch env loc
                in
                  (context, code)
                end

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
          val valueTy = transformTy context valueTy
          val (context, valueSize) = transformArg context env valueSize
          val (context, valueTag) = transformArg context env valueTag
          val barrier = transformBarrier valueTag

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
          val elemTy = transformTy context elementTy
          val (context, elemSize) = transformArg context env elementSize
          val (context, elemTag) = transformArg context env elementTag
        in
          case elemSize of
            AI.UInt 0w1 =>
            let
              val code =
                  addInsn code
                    [
                      AIPrimitive.Memcpy {src = src,
                                          srcOffset = srcOffset,
                                          dst = dst,
                                          dstOffset = dstOffset,
                                          length = length,
                                          tag = elemTag,
                                          loc = loc}
                    ]
            in
              (context, env, code)
            end
          | _ =>
            let
              val lenVar = newVar AI.OFFSET
              val code =
                  addInsn code
                    [
                      AI.PrimOp2    {dst = lenVar,
                                     op2 = (AI.Mul, AI.UINT, AI.UINT, AI.UINT),
                                     arg1 = length,
                                     arg2 = elemSize,
                                     loc = loc},
                      AIPrimitive.Memcpy {src = src,
                                          srcOffset = srcOffset,
                                          dst = dst,
                                          dstOffset = dstOffset,
                                          length = AI.Var lenVar,
                                          tag = elemTag,
                                          loc = loc}
                    ]
            in
              (context, env, code)
            end
        end

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANARRAY {bitmap, totalSize as anTotalSize,
                                    initialValue,
                                    elementTy,
                                    elementSize as anElementSize,
                                    isMutable},
                  loc} =>
        let
          val dst = transformVarInfo context (onlyOne varList)
          val (context, bitmap) = transformArg context env bitmap
          val (context, totalSize) = transformArg context env totalSize
          val (context, initialValue) = transformArg context env initialValue
          val elementTy = transformTy context elementTy
          val (context, elementSize) = transformArg context env elementSize

          val objectType = if isMutable then AI.Array else AI.Vector
          val fieldInfo = {size = toSISize elementSize,
                           tag = AbstractInstructionUtils.tagOf elementTy}
        in
          if (case (anTotalSize, anElementSize) of
                (AN.ANWORD v1, AN.ANWORD v2) => v1 = v2
              | (AN.ANVAR v1, AN.ANVAR v2) => ID.eq (#id v1, #id v2)
              | _ => false)
          then
            (* one element array; this is frequently used for "ref." *)
            let
              val code =
                  addInsn code
                    [
                      AI.Alloc  {dst = dst,
                                 objectType = objectType,
                                 bitmaps = [bitmap],
                                 payloadSize = totalSize,
                                 fieldInfo = [fieldInfo],
                                 loc = loc},
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
          else
            (* ordinary array. split ANARRAY into two parts; one is array
             * allocation, and another is initialization loop. *)
            let
              val currentLabel = getCurrentLabel code
              val loopLabel = newLabel ()
              val bodyLabel = newLabel ()
              val exitLabel = newLabel ()

              val counterVar = newVar AI.UINT
              val code =
                  addInsn code
                    [
                      (* dst = AllocArray(bitmap, totalSize); *)
                      AI.Alloc  {dst = dst,
                                 objectType = objectType,
                                 bitmaps = [bitmap],
                                 payloadSize = totalSize,
                                 fieldInfo = [fieldInfo],
                                 loc = loc},
                      (* counter = 0; *)
                      AI.Move   {dst = counterVar,
                                 ty = AI.UINT,
                                 value = AI.UInt 0w0,
                                 loc = loc,
                                 size = AI.SISINGLE},
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
              (context, env, code)
            end
        end

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANMODIFY {record, nestLevel, offset,
                                     value, valueTy, valueSize, valueTag},
                  loc} =>
        let
          val dst = transformVarInfo context (onlyOne varList)
          val (context, record) = transformArg context env record
          val (context, nestLevel) = transformArg context env nestLevel
          val (context, offset) = transformArg context env offset
          val (context, value) = transformArg context env value
          val valueTy = transformTy context valueTy
          val (context, valueSize) = transformArg context env valueSize
          val (context, valueTag) = transformArg context env valueTag
          val barrier = transformBarrier valueTag

          fun copyNestedBlock code base nestedVar newcopyVar =
              addInsn code
                [
                  (* nested = base[NestedBlockIndex]; *)
                  AI.Load   {dst = nestedVar,
                             block = base,
                             offset = nestedBlockIndex,
                             size = sizeOfBoxed (),
                             ty = AI.BOXED,
                             loc = loc},
                  (* newcopy = CopyBlock(nested); *)
                  CopyBlock {dst = newcopyVar,
                             block = AI.Var nestedVar,
                             loc = loc},
                  (* base[NestedBlockIndex] = newcopy; *)
                  AI.Update {block = base,
                             offset = nestedBlockIndex,
                             size = sizeOfBoxed (),
                             ty = AI.BOXED,
                             value = AI.Var newcopyVar,
                             barrier = AI.WriteBarrier,
                             loc = loc}
                ]
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
                           [
                             (* dst = CopyBlock(record); *)
                             CopyBlock {dst = dst,
                                        block = record,
                                        loc = loc}
                           ]
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
                    [
                      (* dst = CopyBlock(record); *)
                      CopyBlock {dst = dst,
                                 block = record,
                                 loc = loc},
                      (* copied = dst; *)
                      AI.Move   {dst = copiedVar,
                                 ty = AI.BOXED,
                                 value = AI.Var dst,
                                 loc = loc,
                                 size = AI.SISINGLE},
                      (* counter = nestLevel; *)
                      AI.Move   {dst = counterVar,
                                 ty = AI.UINT,
                                 value = AI.UInt 0w0,
                                 loc = loc,
                                 size = AI.SISINGLE},
                      AI.Jump   {label = AI.Label loopLabel,
                                 knownDestinations = [loopLabel],
                                 loc = loc}
                    ]
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
                                  loc = loc,
                                  size = AI.SISINGLE},
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

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANRECORD {bitmap, totalSize, fieldList,
                                     fieldSizeList, fieldTyList},
                  loc} =>
        let
          val dst = transformVarInfo context (onlyOne varList)
          val (context, bitmap) = transformArg context env bitmap
          val (context, totalSize) = transformArg context env totalSize
          val (context, fieldList) = transformArgList context env fieldList
          val (context, fieldSizeList) =
              transformArgList context env fieldSizeList

          val code =
              makeRecord context code {dst = dst,
                                       bitmap = bitmap,
                                       payloadSize = totalSize,
                                       fieldTyList = fieldTyList,
                                       fieldSizeList = fieldSizeList,
                                       loc = loc}
                         fieldList
                         fieldSizeList
        in
          (context, env, code)
        end

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANENVRECORD {bitmap, totalSize, fieldList,
                                        fieldSizeList, fieldTyList,
                                        fixedSizeList},
                  loc} =>
        let
          val dst = transformVarInfo context (onlyOne varList)
          val (context, bitmap) = transformArg context env bitmap
          val totalSize = AI.UInt (Target.toUInt totalSize)
          val (context, fieldList) = transformArgList context env fieldList
          val (context, fieldSizeList) =
              transformArgList context env fieldSizeList
          val fixedSizeList = map (AI.UInt o Target.toUInt) fixedSizeList

          val code =
              makeRecord context code {dst = dst,
                                       bitmap = bitmap,
                                       payloadSize = totalSize,
                                       fieldTyList = fieldTyList,
                                       fieldSizeList = fieldSizeList,
                                       loc = loc}
                         fieldList
                         fixedSizeList
        in
          (context, env, code)
        end

      | AN.ANRAISE {value, loc} =>
        let
          val (context, exn) = transformArg context env value
          val code = addInsn code
                       [
                         AI.Raise {exn = exn, loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANRETURN {valueList, tyList, sizeList, loc} =>
        let
          val (context, valueList) = transformArgList context env valueList
          val (context, sizeList) = transformSISizeList context env sizeList
          val tyList = transformTyList context tyList

          val code = addInsn code
                       [
                         AI.Return {valueList = valueList,
                                    valueSizeList = sizeList,
                                    tyList = tyList,
                                    loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANCLOSURE {funLabel, env = closEnv},
                  loc} =>
        let
          val dst = transformVarInfo context (onlyOne varList)
          val (context, funLabel) = transformArg context env funLabel
          val (context, closEnv) = transformArg context env closEnv
          val code = makeClosure context code dst funLabel closEnv loc
        in
          (context, env, code)
        end

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANRECCLOSURE {funLabel},
                  loc} =>
        let
          val dst = transformVarInfo context (onlyOne varList)
          val (context, funLabel) = transformArg context env funLabel
          val code = makeClosure context code dst funLabel AI.Env loc
        in
          (context, env, code)
        end

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANCALLBACKCLOSURE {funLabel, env=closEnv,
                                              argTyList, resultTyList,
                                              attributes},
                  loc} =>
        let
          (* FIXME: ExportCallback requires more accurate types. *)
          val dst = transformVarInfo context (onlyOne varList)
          val (context, funLabel) = transformArg context env funLabel
          val (context, closEnv) = transformArg context env closEnv
          val argTys = transformTyList context argTyList
          val retTys = transformTyList context resultTyList

          val code = addInsn code
                       [
                         AI.ExportClosure {dst = dst,
                                           entry = funLabel,
                                           env = closEnv,
                                           exportTy = (argTys, retTys),
                                           loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANFOREIGNAPPLY {function, argList, argTyList,
                                           resultTyList, attributes},
                  loc} =>
        let
          (* FIXME: ForeignApply requires more accurate types. *)
          val dsts = map (transformVarInfo context) varList
          val (context, function) = transformArg context env function
          val (context, argList) = transformArgList context env argList
          val argTys = transformTyList context argTyList
          val retTys = transformTyList context resultTyList

          val code =
              addInsn code
                [
                  AI.CallExt {dstVarList = dsts,
                              callee = AI.Foreign {function = function,
                                                   attributes = attributes},
                              argList = argList,
                              calleeTy = (argTys, retTys),
                              loc = loc}
                ]
        in
          (context, env, code)
        end

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANPRIMAPPLY {prim, argList,
                                        argTyList, resultTyList,
                                        instSizeList, instTagList},
                  loc} =>
        let
          val dsts = map (transformVarInfo context) varList
          val (context, argList) = transformArgList context env argList
          val argTys = transformTyList context argTyList
          val retTys = transformTyList context resultTyList

          val (context, instSizeList) =
              transformArgList context env instSizeList
          val (context, instTagList) =
              transformArgList context env instTagList

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

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANAPPLY {closure, argList, argTyList, resultTyList,
                                    argSizeList},
                  loc} =>
        let
          val dsts = map (transformVarInfo context) varList
          val (context, closure) = transformArg context env closure
          val (context, argList) = transformArgList context env argList
          val (context, argSizeList) =
              transformSISizeList context env argSizeList
          val argTys = transformTyList context argTyList
          val retTys = transformTyList context resultTyList

          val entryVar = newVar AI.ENTRY
          val envVar = newVar AI.BOXED
          val code = expandClosure code closure entryVar envVar loc
          val code = addInsn code
                        [
                          AI.Call {dstVarList = dsts,
                                   entry = AI.Var entryVar,
                                   env = AI.Var envVar,
                                   argList = argList,
                                   argSizeList = argSizeList,
                                   argTyList = argTys,
                                   resultTyList = retTys,
                                   loc = loc}
                        ]
        in
          (context, env, code)
        end

      | AN.ANTAILAPPLY {closure, argList, argTyList, resultTyList,
                        argSizeList, loc} =>
        let
          val (context, closure) = transformArg context env closure
          val (context, argList) = transformArgList context env argList
          val (context, argSizeList) =
              transformSISizeList context env argSizeList
          val argTys = transformTyList context argTyList
          val retTys = transformTyList context resultTyList

          val entryVar = newVar AI.ENTRY
          val envVar = newVar AI.BOXED
          val code = expandClosure code closure entryVar envVar loc
          val code = addInsn code
                        [
                          AI.TailCall {entry = AI.Var entryVar,
                                       env = AI.Var envVar,
                                       argList = argList,
                                       argTyList = argTys,
                                       resultTyList = retTys,
                                       argSizeList = argSizeList,
                                       loc = loc}
                        ]
        in
          (context, env, code)
        end

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANCALL {funLabel, env = closEnv, argList,
                                   argSizeList, argTyList, resultTyList},
                  loc} =>
        let
          val dsts = map (transformVarInfo context) varList
          val (context, funLabel) = transformArg context env funLabel
          val (context, closEnv) = transformArg context env closEnv
          val (context, argList) = transformArgList context env argList
          val (context, argSizeList) =
              transformSISizeList context env argSizeList
          val argTys = transformTyList context argTyList
          val retTys = transformTyList context resultTyList

          val code = addInsn code
                       [
                         AI.Call {dstVarList = dsts,
                                  entry = funLabel,
                                  env = closEnv,
                                  argList = argList,
                                  argSizeList = argSizeList,
                                  argTyList = argTys,
                                  resultTyList = retTys,
                                  loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANTAILCALL {funLabel, env = closEnv, argList, argSizeList,
                       argTyList, resultTyList, loc} =>
        let
          val (context, funLabel) = transformArg context env funLabel
          val (context, closEnv) = transformArg context env closEnv
          val (context, argList) = transformArgList context env argList
          val (context, argSizeList) =
              transformSISizeList context env argSizeList
          val argTys = transformTyList context argTyList
          val retTys = transformTyList context resultTyList

          val code = addInsn code
                       [
                         AI.TailCall {entry = funLabel,
                                      env = closEnv,
                                      argList = argList,
                                      argSizeList = argSizeList,
                                      argTyList = argTys,
                                      resultTyList = retTys,
                                      loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANRECCALL {funLabel, argList,
                                      argSizeList, argTyList, resultTyList},
                  loc} =>
        let
          val dsts = map (transformVarInfo context) varList
          val (context, funLabel) = transformArg context env funLabel
          val (context, argList) = transformArgList context env argList
          val (context, argSizeList) =
              transformSISizeList context env argSizeList
          val argTys = transformTyList context argTyList
          val retTys = transformTyList context resultTyList

          val code = addInsn code
                       [
                         AI.Call {dstVarList = dsts,
                                  entry = funLabel,
                                  env = AI.Env,
                                  argList = argList,
                                  argSizeList = argSizeList,
                                  argTyList = argTys,
                                  resultTyList = retTys,
                                  loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANTAILRECCALL {funLabel, argList, argSizeList, argTyList,
                          resultTyList, loc} =>
        let
          val (context, funLabel) = transformArg context env funLabel
          val (context, argList) = transformArgList context env argList
          val (context, argSizeList) =
              transformSISizeList context env argSizeList
          val argTys = transformTyList context argTyList
          val retTys = transformTyList context resultTyList

          val code = addInsn code
                       [
                         AI.TailCall {entry = funLabel,
                                      env = AI.Env,
                                      argList = argList,
                                      argSizeList = argSizeList,
                                      argTyList = argTys,
                                      resultTyList = retTys,
                                      loc = loc}
                       ]
        in
          (context, env, code)
        end

      | AN.ANVAL {varList, sizeList,
                  exp = AN.ANLOCALCALL {codeLabel, argList, argSizeList,
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
          val passTys = AN.CODEPOINT :: AN.CODEPOINT :: argTyList
          val passSizes = AN.SISINGLE :: AN.SISINGLE :: argSizeList
          val passVars = getPassVars context passTys
          val returnVars = getPassVars context resultTyList

          (* pass return address and current handler to callee *)
          val passValues =
              case #handler env of
                AI.NoHandler => AI.Nowhere :: argList
              | AI.StaticHandler l => AI.Label l :: argList
              | AI.DynamicHandler {current, ...} => AI.Var current :: argList
          val passValues = AI.Label returnLabel :: passValues

          val (context, env, code) =
              makeMove context env code passVars passSizes passValues loc
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
                       varList sizeList
                       (map (AI.Var o transformVarInfo context) returnVars)
                       loc
        in
          (context, env, code)
        end

      | AN.ANTAILLOCALCALL {codeLabel, argList, argSizeList, argTyList,
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
                makeMove context env code paramVars argSizeList argList loc
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
            val passTys = AN.CODEPOINT :: AN.CODEPOINT :: argTyList
            val passSizes = AN.SISINGLE :: AN.SISINGLE :: argSizeList
            val passVars = getPassVars context passTys

            (* pass current link to callee.
             * no need to pass current handler to callee. *)
            val passValues =
                case linkVar of
                  NONE => AI.Nowhere :: AI.Nowhere :: argList
                | SOME var => AI.Var (transformVarInfo context var)
                              :: AI.Nowhere :: argList

            val (context, env, code) =
                makeMove context env code passVars passSizes passValues loc
            val code = addInsn code
                         [
                           AI.Jump {label = codeLabel,
                                    knownDestinations = destinations,
                                    loc = loc}
                         ]
          in
            (context, env, code)
          end

      | AN.ANLOCALRETURN {valueList, tyList, sizeList, loc,
                          knownDestinations} =>
        let
          val (context, valueList) = transformArgList context env valueList

          (* tyList is always identical to resultTyList of this routine. *)
          val returnVars = getPassVars context tyList

          val linkVar =
              case #linkVar (getRoutineInfo context (#routineLabel env)) of
                SOME x => x
              | NONE => raise Control.Bug "transformDecl: LOCALRETURN"

          val (context, env, code) =
              makeMove context env code returnVars sizeList valueList loc

          (* knownDestinations only includes returnLabel of LOCALCALL,
           * so no need to call transformCodePoint here. *)
          val codeLabel =
              case !knownDestinations of
                [l] => AI.Label l
              | _ => AI.Var (transformVarInfo context linkVar)

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
                transformIntSwitch AI.CHAR setupSwitchChar
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
              | (AN.ANVALUE (AN.ANGLOBALSYMBOL {ann=AN.EXCEPTIONTAG _,...}),
                 _, _)::_ =>
                transformExceptionSwitch
                    context env code value branchCases defaultLabel loc
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
          val exnVar = transformVarInfo context exnVar : AI.paramInfo

          val tryEnv = setHandler env (AI.StaticHandler handlerLabel)
          val tryKind =
              AI.ChangeHandler
                {change = SOME (AI.PushHandler {popHandlerLabel = leaveLabel}),
                 previousHandler = #handler env}
          val code = forceBeginBlock code tryLabel tryKind tryEnv loc
          val (context, tryEnv, code) =
              transformDeclList context tryEnv code try
          val code = closeBlock code

          val handlerEnv = addExnVar env exnVar
          val code = beginBlock code handlerLabel (AI.Handler exnVar)
                                handlerEnv loc
          val (context, handlerEnv, code) =
              transformDeclList context handlerEnv code handler
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
          val kind =
              case leaveHandler of
                NONE => AI.Merge
              | SOME {tryLabel, handlerLabel} =>
                AI.ChangeHandler
                  {change = SOME (AI.PopHandler {pushHandlerLabel = tryLabel}),
                   previousHandler = AI.StaticHandler handlerLabel}

          val code = closeBlock code
          val code = beginBlock code label kind env loc
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

  (*
   * FIXME: for YASIGenerator
   *   this is just for backward compatibility with symbolic instruction.
   *   Abstract instruction does not require concrete size of arguments
   *   of functions.
   *)
  fun loadFreeValueList context env code siexpList loc =
      let
        val (sizes, andecls) =
            foldr
              (fn (AN.SISIZE x, (sizes, decls)) => (x::sizes, decls)
                | (AN.SIENVACC {nestLevel, offset, size, ty}, (sizes, decls)) =>
                  let
                    val var = newANVarInfo AN.SIZE AN.LOCAL
                  in
                    (AN.SIVARIANT var :: sizes,
                     AN.ANVAL {varList = [var],
                               sizeList = [AN.SISINGLE],
                               exp = AN.ANENVACC {nestLevel = nestLevel,
                                                  offset = offset,
                                                  size = AN.ANWORD size,
                                                  ty = ty},
                               loc = loc} :: decls)
                  end)
              (nil, nil)
              siexpList

        val (context, env, code) =
            transformDeclList context env code andecls
      in
        (context, env, code, sizes)
      end

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

  (* AN.tid -> AI.tag *)
  fun makeTagMap ({tyvars, bitmapFree, tagArgList}:AN.frameInfo) =
      let
        val bitmapFree =
            case bitmapFree of
              AN.ANVALUE (AN.ANWORD 0w0) =>
              NONE
            | AN.ANENVACC {nestLevel = 0w0, offset,
                           size = AN.ANWORD size,
                           ty = AN.BITMAP} =>
              (* ASSERT: size must be equal to the size of a bitmap word. *)
              SOME (Target.toUInt offset)
            | _ => raise Control.Bug "makeTagMap: invalid bitmapFree"

        fun makeMap (tagMap, tid::tyvars, arg::tagArgList, n, bitmapFree) =
            let
              val param = transformParamInfo IEnv.empty arg
              val tag = AI.ParamTag param
              val tagMap = IEnv.insert (tagMap, tid, tag)
            in
              makeMap (tagMap, tyvars, tagArgList, n, bitmapFree)
            end
          | makeMap (tagMap, tid::tyvars, nil, n, bitmapFree as SOME offset) =
            let
              val bit = BasicTypes.UInt32ToWord n
              val tag = AI.IndirectTag {offset = offset, bit = bit}
              val tagMap = IEnv.insert (tagMap, tid, tag)
            in
              makeMap (tagMap, tyvars, nil, n + 0w1, bitmapFree)
            end
          | makeMap (tagMap, tid::tyvars, nil, n, NONE) =
            raise Control.Bug "makeTagMap"
          | makeMap (tagMap, nil, _, _, _) =
            tagMap
      in
        makeMap (IEnv.empty, tyvars, tagArgList, 0w0, bitmapFree)
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
  fun transformRoutine context code
                       ({codeId, body, argTyList, argSizeList, resultTyList,
                         ffiAttributes,
                         loc, params, paramVars, linkVar, handlerVar,
                         initialHandlers,
                         funEntry, codeEntry, selfLoopEntry,
                         selfBackEntry}:routineInfo) =
      let
        val paramValues =
            case paramVars of
              _::_ => map (AI.Var o transformVarInfo context) paramVars
            | nil => map AI.Param params

        (* compose paramMap from paramValues and parent's paramMap *)
        val parentParamMap =
            case ID.Map.find (#paramMapMap context, codeId) of
              SOME x => x
            | NONE => ID.Map.empty
        val paramMap =
            ListPair.foldl (fn ({id, ...}, value, paramMap) =>
                               ID.Map.insert (paramMap, id, value))
                           parentParamMap
                           (params, paramValues)

        val initialHandler =
            case initialHandlers of
              nil => AI.NoHandler
            | [NONE] => AI.NoHandler
            | [SOME l] => AI.StaticHandler l
            | h::t =>
              AI.DynamicHandler
                  {current = transformVarInfo context (valOf handlerVar),
                   outside = case h of NONE => true | _ => false,
                   handlers = map valOf (List.filter isSome initialHandlers)}
              handle Option =>
                     raise Control.Bug "transformRoutine: initialHandler"

        val env =
            {
              routineLabel = codeId,
              paramMap = paramMap,
              exnVarMap = ID.Map.empty,
              handler = AI.NoHandler
            } : environment

        (* function entry *)
        val (context, env, code) =
            case funEntry of
              NONE => (context, env, code)
            | SOME label =>
              let
                val kind = AI.FunEntry params
                val code = beginBlock code label kind env loc
              in
                (* bind all parameters to local variables, if needed. *)
                case paramVars of
                  nil => (context, env, code)
                | _ =>
                  let
                    val params = map AI.Param params

                    (* FIXME: only for symbolic instruction *)
                    val (context, env, code, argSizes) =
                        loadFreeValueList context env code argSizeList loc
                  in
                    case codeEntry of
                      (* no CodeEntry; move args to paramVars directly *)
                      NONE =>
                      makeMove context env code paramVars argSizes params loc
                    | (* move args to passVars at first.
                       * CodeEntry will move them to paramVars. *)
                      SOME _ =>
                      let
                        val passTys = AN.CODEPOINT::AN.CODEPOINT::argTyList
                        val sizes = AN.SISINGLE::AN.SISINGLE::argSizes
                        val vars = getPassVars context passTys
                        val params = AI.Nowhere::AI.Nowhere::params
                      in
                        makeMove context env code vars sizes params loc
                      end
                  end
              end

        (* code entry *)
        val (context, env, code) =
            case codeEntry of
              NONE => (context, env, code)
            | SOME label =>
              let
                (* receive arguments and immediately move them to paramVars. *)
                val passTys = AN.CODEPOINT::AN.CODEPOINT::argTyList
                val passVars = getPassVars context passTys

                val {dsts, extraArgSizes, argVars, passedHandler} =
                    case (passVars, handlerVar, linkVar) of
                      (lp::hp::args, SOME hv, SOME lv) =>
                      {
                        dsts = lv::hv::paramVars,
                        extraArgSizes = AN.SISINGLE::AN.SISINGLE::nil,
                        argVars = lp::hp::args,
                        passedHandler = SOME hp
                      }
                    | (lp::hp::args, SOME hv, NONE) =>
                      {
                        dsts = hv::paramVars,
                        extraArgSizes = AN.SISINGLE::nil,
                        argVars = hp::args,
                        passedHandler = SOME hp
                      }
                    | (lp::hp::args, NONE, SOME lv) =>
                      {
                        dsts = lv::paramVars,
                        extraArgSizes = AN.SISINGLE::nil,
                        argVars = lp::args,
                        passedHandler = NONE
                      }
                    | (lp::hp::args, NONE, NONE) =>
                      {
                        dsts = paramVars,
                        extraArgSizes = nil,
                        argVars = args,
                        passedHandler = NONE
                      }
                    | _ => raise Control.Bug "transformRoutine: CodeEntry"

                val argValues =
                    map (AI.Var o transformVarInfo context) argVars

                (* enable initial handler temporally *)
                val env =
                    case initialHandler of
                      AI.NoHandler => env
                    | AI.StaticHandler _ => setHandler env initialHandler
                    | AI.DynamicHandler {current, outside, handlers} =>
                      let
                        val var = transformVarInfo context (valOf passedHandler)
                      in
                        setHandler env
                                   (AI.DynamicHandler {current = var,
                                                       outside = outside,
                                                       handlers = handlers})
                      end
                      handle Option =>
                             raise Control.Bug "transformRoutine: Option"

                val code =
                    forceBeginBlock code label AI.CodeEntry env loc

                (* FIXME: only for symbolic instruction *)
                val (context, env, code, argSizes) =
                    loadFreeValueList context env code argSizeList loc

                val argSizes = extraArgSizes @ argSizes
              in
                makeMove context env code dsts argSizes argValues loc
              end

        val env = setHandler env initialHandler

        (* self loop entry *)
        val code =
            case selfLoopEntry of
              SOME label =>
              forceBeginBlock code label AI.Loop env loc
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

  fun prepareRoutineInfo tagMap passVars
                         ({label, routine, callCount, tailCallCount,
                           selfCallCount, handlers}:CA.routineInfo) =
      let
        val {codeId, body, argVarList, argSizeList, resultTyList,
             ffiAttributes, loc, ...} =
            case routine of
              CA.EntryFunction x => x
            | CA.Code {codeId, argVarList, argSizeList, body, resultTyList,
                       loc} =>
              {codeId = codeId,
               argVarList = argVarList,
               argSizeList = argSizeList,
               body = body,
               resultTyList = resultTyList,
               ffiAttributes = NONE,
               loc = loc}
            | CA.Continue _ => raise Control.Bug "prepareRoutineInfo: Continue"

        val argTyList = map #ty argVarList
        val params = map (transformParamInfo tagMap) argVarList

        val linkVar =
            case routine of
              CA.Code _ => SOME (newANVarInfo AN.CODEPOINT AN.LOCAL)
            | _ => NONE

        val handlerVar =
            case handlers of
              _::_::_ => SOME (newANVarInfo AN.CODEPOINT AN.LOCAL)
            | _ => NONE

        (* function entry *)
        val funEntry =
            case routine of
              CA.EntryFunction {codeId, ...} => SOME codeId
            | _ => NONE

        (* code entry *)
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

        (*
         * If control may enter to this routine by JUMP, we need to
         * assign fresh local variables for all arguments of this
         * routine so that we can emulate CALL by JUMP with MOVEs.
         *
         * Note that if arbitrary two functions have same type, we
         * need to use same sequence of local variables for passing
         * arguments, because both of such two functions may coincidentally
         * be destinations of one identical indirect JUMP.
         *
         * The same is true of varaibles for passing return values of
         * LOCALRETURN.
         *)
        val paramVars =
            case (linkVar, handlerVar, codeEntry, selfLoopEntry) of
              (NONE, NONE, NONE, NONE) => nil
            | _ => map (fn anty => newANVarInfo anty AN.LOCAL) argTyList

        val passVars =
            case (linkVar, handlerVar, codeEntry) of
              (NONE, NONE, NONE) => passVars
            | _ => ensureVars passVars (AN.CODEPOINT::AN.CODEPOINT::argTyList)

        val passVars =
            case routine of
              CA.Code _ => ensureVars passVars resultTyList
            | _ => passVars

      in
        (passVars,
         {
           codeId = codeId,
           body = body,
           argTyList = argTyList,
           argSizeList = argSizeList,
           resultTyList = resultTyList,
           ffiAttributes = ffiAttributes,
           params = params,
           paramVars = paramVars,
           linkVar = linkVar,
           handlerVar = handlerVar,
           initialHandlers = handlers,
           funEntry = funEntry,
           codeEntry = codeEntry,
           selfLoopEntry = selfLoopEntry,
           selfBackEntry = selfBackEntry,
           loc = loc
         } : routineInfo)
      end

  fun transformCluster funIdMap (clusterDecl as {clusterId, frameInfo,
                                                 hasClosureEnv,
                                                 entryFunctions=_, loc}
                                 :AN.clusterDecl) =
      let
        val tagMap = makeTagMap frameInfo
        val clusterDecl = Simplify.reduceCluster clusterDecl
        val routines = CallAnalysis.analyze clusterDecl

        val (routineInfoMap, passVars) =
            foldl
              (fn ({routine = CA.Continue _, ...}, z) => z
                | (routineInfo as {label, ...}, (map, vars)) =>
                  let
                    val (vars, routine) =
                        prepareRoutineInfo tagMap vars routineInfo
                  in
                    (ID.Map.insert (map, label, routine), vars)
                  end)
              (ID.Map.empty, nil)
              routines

        val context =
            {
              boundaryCheckFailedLabel = NONE,
              funIdMap = funIdMap,
              tagMap = tagMap,
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
                    transformRoutine context code routineInfo
                  end)
              (context, code)
              routines
      in
        (#constants context,
         {
           name = clusterId,
           body = rev (#blocks code),
           loc = loc
         } : AI.cluster)
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
            aliases = SEnv.empty,
            clusters = [cluster]
          }
        end

      | AN.ANTOPCONST {globalName, export = false, constant = CT.STRING _} =>
        (* ToDo: used for exception description *)
        {
          toplevel = NONE,
          constants = ID.Map.empty,
          globals = SEnv.empty,
          aliases = SEnv.empty,
          clusters = nil
        }

      | AN.ANTOPCONST _ =>
        raise Control.Bug "FIXME: ANTOPCONST: not implemented"

      | AN.ANTOPRECORD {globalName, export, bitmaps, totalSize, fieldList,
                        fieldTyList, fieldSizeList} =>
        (* ToDo: used for exception *)
        { 
          toplevel = NONE,
          constants = ID.Map.empty,
          globals = SEnv.empty,
          aliases = SEnv.empty,
          clusters = nil
        }

      | AN.ANTOPARRAY {globalName, export,
                       externalVarID = SOME id,
                       bitmap, totalSize,
                       initialValues = nil, elementTy, elementSize,
                       isMutable = true} =>
        (* ToDo: used for global variable *)
        {
          toplevel = NONE,
          constants = ID.Map.empty,
          globals = SEnv.singleton (globalName, 
                                    transformTy' IEnv.empty elementTy),
          aliases = SEnv.empty,
          clusters = nil
        }

      | AN.ANTOPARRAY _ =>
        raise Control.Bug "FIXME: ANTOPARRAY: not implemented"

      | AN.ANTOPCLOSURE {globalName, export, funLabel} =>
        raise Control.Bug "FIXME: ANTOPCLOSURE: not implemented"

      | AN.ANTOPALIAS {globalName, export,
                       originalGlobalName = (origName, AN.GLOBALSYMBOL)} =>
        {
          toplevel = NONE,
          constants = ID.Map.empty,
          globals = SEnv.empty,
          aliases = SEnv.singleton (origName, [globalName]),
          clusters = nil
        }

      | AN.ANTOPALIAS _ =>
        raise Control.Bug "ANTOPALIAS"

      | AN.ANENTERTOPLEVEL id =>
        let
          val clusterId =
              case ID.Map.find (funIdMap, id) of
                SOME x => x
              | NONE => raise Control.Bug "ANENTERTOPLEVEL"
        in
          {
            toplevel = SOME {clusterId = clusterId, funLabel = id},
            constants = ID.Map.empty,
            globals = SEnv.empty,
            aliases = SEnv.empty,
            clusters = nil
          }
        end

  fun transformTopdeclList funIdMap (topdecl::topdecls) =
      let
        fun fail _ = raise Control.Bug "transfromTopdeclList"
        fun mergeopt (NONE, NONE) = NONE
          | mergeopt (SOME x, NONE) = SOME x
          | mergeopt (NONE, SOME x) = SOME x
          | mergeopt (SOME _, SOME _) = raise Control.Bug "transformTopdeclList"

        val p1 = transformTopdecl funIdMap topdecl
        val p2 = transformTopdeclList funIdMap topdecls
      in
        {
          toplevel = mergeopt (#toplevel p1, #toplevel p2),
          constants = ID.Map.unionWith fail (#constants p1, #constants p2),
          globals = SEnv.unionWith fail (#globals p1, #globals p2),
          aliases = SEnv.unionWith (op @) (#aliases p1, #aliases p2),
          clusters = #clusters p1 @ #clusters p2
        } : AI.program
      end
    | transformTopdeclList funIdMap nil =
      {
        toplevel = NONE,
        constants = ID.Map.empty,
        globals = SEnv.empty,
        aliases = SEnv.empty,
        clusters = nil
      }

  fun generate globalIndexAllocator topdeclList =
      let
        val _ = globalIndexAllocatorRef := globalIndexAllocator

        val clusters =
            List.mapPartial (fn AN.ANCLUSTER x => SOME x | _ => NONE)
                            topdeclList

        val funIdMap = makeFunIdMap clusters
        val program =  transformTopdeclList funIdMap topdeclList
      in
        program
      end
      handle exp => raise exp

end
