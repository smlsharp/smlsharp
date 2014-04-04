(**
 * allocate root set
 *
 * @copyright (c) 2013 Tohoku University.
 * @author UENO Katsuhiro
 *)
structure StackAllocation : sig

  val compile : MachineCode.program -> MachineCode.program

end =
struct

  structure M = MachineCode
  structure R = RuntimeTypes

  fun optionToList NONE = nil
    | optionToList (SOME x) = [x]

  structure SlotSet :> sig
    type set
    val empty : set
    val generate : int -> set
    val fromList : SlotID.id list -> set
    val setMinus : set * set -> set
    val choose : set -> SlotID.id
  end =
  struct
    type set = SlotID.id list

    val empty = nil : set

    fun generate numItems =
        (* assume that SlotID.generate generates sequential numbers *)
        List.tabulate (numItems, fn _ => SlotID.generate ())

    fun union (nil, set) = set
      | union (set, nil) = set
      | union (l1 as h1::t1, l2 as h2::t2) =
        case SlotID.compare (h1, h2) of
          EQUAL => h1 :: union (t1, t2)
        | GREATER => h2 :: union (l1, t2)
        | LESS => h1 :: union (t1, l2)
    fun mergeStep z nil = z
      | mergeStep z [x] = x::z
      | mergeStep z (h1::h2::t) = mergeStep (union (h1, h2) :: z) t
    fun merge nil = nil
      | merge [x] = x
      | merge l = merge (mergeStep nil l)
    fun sort' z nil = merge z
      | sort' z (h::t) = sort' ([h]::z) t
    fun fromList l = sort' nil l

    fun setMinus (nil, set) = nil
      | setMinus (set, nil) = set
      | setMinus (l1 as h1::t1, l2 as h2::t2) =
        case SlotID.compare (h1, h2) of
          EQUAL => setMinus (t1, t2)
        | GREATER => setMinus (l1, t2)
        | LESS => h1 :: setMinus (t1, l2)

    fun choose nil = raise Bug.Bug "SlotSet.choose"
      | choose (h::_) = h : SlotID.id
  end

  structure Set :> sig
    type set
    val empty : set
    val singleton : M.varInfo -> set
    val union : set * set -> set
    val merge : set list -> set
    val fromList : M.varInfo list -> set
    val listItems : set -> M.varInfo list
    val numItems : set -> int
    val intersect : set * set -> set
    val setMinus : set * set -> set
    val isSubsetOf : set * set -> bool
  end =
  struct
    type set = M.varInfo list  (* sorted by id *)

    val empty = nil : set

    val numItems = length

    fun listItems (l:set) = l

    fun singleton (v as {id, ty=(_, R.BOXEDty)} : M.varInfo) = [v]
      | singleton _ = empty

    fun union (nil, set) = set
      | union (set, nil) = set
      | union (l1 as (h1::t1) : set, l2 as (h2::t2) : set) =
        case VarID.compare (#id h1, #id h2) of
          EQUAL => h1 :: union (t1, t2)
        | GREATER => h2 :: union (l1, t2)
        | LESS => h1 :: union (t1, l2)

    fun mergeStep z nil = z
      | mergeStep z [x] = x::z
      | mergeStep z (h1::h2::t) = mergeStep (union (h1, h2) :: z) t

    fun merge nil = nil
      | merge [x] = x
      | merge l = merge (mergeStep nil l)

    fun fromList' z nil = merge z
      | fromList' z ((v as {id, ty=(_,R.BOXEDty)})::t) = fromList' ([v]::z) t
      | fromList' z (_::t) = fromList' z t

    fun fromList l = fromList' nil l

    fun intersect (nil, set) = nil
      | intersect (set, nil) = nil
      | intersect (l1 as (h1::t1) : set, l2 as (h2::t2) : set) =
        case VarID.compare (#id h1, #id h2) of
          EQUAL => h1 :: intersect (t1, t2)
        | GREATER => intersect (l1, t2)
        | LESS => intersect (t1, l2)

    fun setMinus (nil:set, set:set) = nil
      | setMinus (set, nil) = set
      | setMinus (l1 as (h1::t1) : set, l2 as (h2::t2) : set) =
        case VarID.compare (#id h1, #id h2) of
          EQUAL => setMinus (t1, t2)
        | GREATER => setMinus (l1, t2)
        | LESS => h1 :: setMinus (t1, l2)

    fun isSubsetOf (nil, set) = true
      | isSubsetOf (set, nil) = false
      | isSubsetOf (l1 as (h1::t1) : set, l2 as (h2::t2) : set) =
        case VarID.compare (#id h1, #id h2) of
          EQUAL => isSubsetOf (t1, t2)
        | GREATER => isSubsetOf (l1, t2)
        | LESS => false
  end

  fun useValue value =
      case value of
        M.ANCONST _ => Set.empty
      | M.ANCAST {exp, expTy, targetTy, runtimeTyCast} => useValue exp
      | M.ANBOTTOM => Set.empty
      | M.ANVAR v => Set.singleton v

  fun useObjtype objtype =
      case objtype of
        M.OBJTYPE_VECTOR v => useValue v
      | M.OBJTYPE_ARRAY v => useValue v
      | M.OBJTYPE_UNBOXED_VECTOR => Set.empty
      | M.OBJTYPE_RECORD => Set.empty
      | M.OBJTYPE_INTINF => Set.empty

  fun useAddr addr =
      case addr of
        M.MAPTR v => useValue v
      | M.MAPACKED v => useValue v
      | M.MAOFFSET {base, offset} =>
        Set.union (useValue base, useValue offset)
      | M.MARECORDFIELD {recordExp, fieldIndex} =>
        Set.union (useValue recordExp, useValue fieldIndex)
      | M.MAARRAYELEM {arrayExp, elemSize, elemIndex} =>
        Set.union (Set.union (useValue arrayExp, useValue elemSize),
                  useValue elemIndex)

  fun useValues l =
      foldl (fn (x,z) => Set.union (useValue x, z)) Set.empty l

  fun useAddrs l =
      foldl (fn (x,z) => Set.union (useAddr x, z)) Set.empty l

  datatype exp =
      DEF of
      {
        def : Set.set,
        causeGC : bool,
        next : exp
      }
    | MID of
      {
        def : Set.set,
        use : Set.set,
        orig : M.mcexp_mid,
        causeGC : bool,
        next : exp
      }
    | CALL of
      {
        def : Set.set,
        use : Set.set,
        returnTo : block,
        unwindTo : block,
        causeGC : bool,
        orig : M.mcexp_mid
      }
    | LAST of
      {
        def : Set.set,
        use : Set.set,
        args : (M.varInfo * M.mcvalue) list,
        orig : M.mcexp_last
      }
    | LOCALCODE of
      {
        id : FunLocalLabel.id,
        recursive : bool,
        body : block,
        next : exp,
        loc : M.loc
      }
    | HANDLER of
      {
        nextExp : exp,
        exnVar : M.varInfo,
        id : HandlerLabel.id,
        handler : block,
        loc : M.loc
      }

  and block =
      BLOCK of
      {
        id : FunLocalLabel.id,
        successors : block list,
        predecessors : block list,
        argVarList : M.varInfo list,
        bodyExp : exp,
        defuse : {defs : Set.set, uses : Set.set},
        liveIn : Set.set,
        liveOut : Set.set
      } ref

  val dummyExp =
      LAST {def = Set.empty,
            use = Set.empty,
            args = nil,
            orig = M.MCUNREACHABLE}

  fun newBlock id argVarList =
      BLOCK (ref {id = id,
                  successors = nil,
                  predecessors = nil,
                  argVarList = argVarList,
                  bodyExp = dummyExp,
                  defuse = {defs = Set.empty, uses = Set.empty},
                  liveIn = Set.empty,
                  liveOut = Set.empty})

  fun addEdge (fromBlock as BLOCK r1,
               toBlock as BLOCK (r2 as ref {argVarList, ...})) =
      (r1 := (!r1 # {successors = toBlock :: #successors (!r1)});
       r2 := (!r2 # {predecessors = fromBlock :: #predecessors (!r2)});
       argVarList)

  fun defuseExp exp =
      case exp of
        DEF {def, causeGC, next} =>
        let
          val {defs, uses} = defuseExp next
        in
          {defs = Set.union (defs, def),
           uses = Set.setMinus (uses, def)}
        end
      | MID {def, use, orig, causeGC, next} =>
        let
          val {defs, uses} = defuseExp next
        in
          {defs = Set.union (defs, def),
           uses = Set.union (Set.setMinus (uses, def), use)}
        end
      | CALL {def, use, returnTo, unwindTo, causeGC, orig} =>
        {defs = def, uses = use}
      | LAST {def, use, args, orig} =>
        {defs = def, uses = use}
      | LOCALCODE {id, recursive, body, next, loc} => defuseExp next
      | HANDLER {nextExp, id, exnVar, handler, loc} => defuseExp nextExp

  fun setBody (BLOCK r, bodyExp) =
      r := (!r # {bodyExp = bodyExp, defuse = defuseExp bodyExp})

  type prepareEnv =
      {
        currentBlock : block,
        exitBlock : block,
        handlerEnv : block HandlerLabel.Map.map,
        blockEnv : block FunLocalLabel.Map.map
      }

  fun jumpTo ({currentBlock, blockEnv, ...}:prepareEnv) id =
      case FunLocalLabel.Map.find (blockEnv, id) of
        NONE => raise Bug.Bug "jumpTo"
      | SOME block => addEdge (currentBlock, block)

  fun unwindTo ({currentBlock, exitBlock, ...}:prepareEnv) NONE =
      (addEdge (currentBlock, exitBlock); exitBlock)
    | unwindTo {currentBlock, handlerEnv, ...} (SOME id) =
      case HandlerLabel.Map.find (handlerEnv, id) of
        NONE => raise Bug.Bug "unwindTo"
      | SOME block => (addEdge (currentBlock, block); block)

  fun prepareLast (env:prepareEnv) last =
      case last of
        M.MCRETURN {value, loc} =>
        (
          addEdge (#currentBlock env, #exitBlock env);
          LAST {def = Set.empty, use = useValue value, args = nil, orig = last}
        )
      | M.MCRAISE {argExp, loc} =>
        (
          addEdge (#currentBlock env, #exitBlock env);
          LAST {def = Set.empty, use = useValue argExp, args = nil, orig = last}
        )
      | M.MCHANDLER {nextExp, id, exnVar, handlerExp, loc} =>
        let
          val handlerBlock = newBlock (FunLocalLabel.generate nil) nil
          val nextEnv =
              env # {handlerEnv = HandlerLabel.Map.insert
                                    (#handlerEnv env, id, handlerBlock)}
          val nextExp = prepareExp nextEnv nextExp
          val handlerEnv = env # {currentBlock = handlerBlock}
          val handlerExp = DEF {def = Set.singleton exnVar,
                                causeGC = true,
                                next = prepareExp handlerEnv handlerExp}
          val _ = setBody (handlerBlock, handlerExp)
        in
          HANDLER {nextExp = nextExp,
                   id = id,
                   exnVar = exnVar,
                   handler = handlerBlock,
                   loc = loc}
        end
      | M.MCLOCALCODE {id, recursive, argVarList, bodyExp, nextExp, loc} =>
        let
          val block = newBlock id argVarList
          val env = env # {blockEnv = FunLocalLabel.Map.insert
                                        (#blockEnv env, id, block)}
          val bodyExp = prepareExp (env # {currentBlock = block}) bodyExp
          val _ = setBody (block, bodyExp)
          val nextExp = prepareExp env nextExp
        in
          LOCALCODE {id = id,
                     recursive = recursive,
                     body = block,
                     next = nextExp,
                     loc = loc}
        end
      | M.MCGOTO {id, argList, loc} =>
        let
          val argVarList = jumpTo env id
        in
          LAST {def = Set.fromList argVarList,
                use = useValues argList,
                args = ListPair.zipEq (argVarList, argList),
                orig = last}
        end
      | M.MCSWITCH {switchExp, expTy, branches, default, loc} =>
        (
          app (fn (_, id) => (jumpTo env id; ())) branches;
          jumpTo env default;
          LAST {def = Set.empty,
                use = useValue switchExp,
                args = nil,
                orig = last}
        )
      | M.MCUNREACHABLE =>
        (
          addEdge (#currentBlock env, #exitBlock env);
          LAST {def = Set.empty, use = Set.empty, args = nil, orig = last}
        )

  and prepareCont (env as {currentBlock, ...}) (argVarList, nextExp) =
      let
        val nextBlock = newBlock (FunLocalLabel.generate nil) argVarList
        val nextEnv = env # {currentBlock = nextBlock}
        val nextExp = prepareExp nextEnv nextExp
        val _ = setBody (nextBlock, nextExp)
        val _ = addEdge (currentBlock, nextBlock)
      in
        nextBlock
      end

  and prepareExp (env:prepareEnv) (nil, last) =
      prepareLast env last
    | prepareExp env (mid::mids, last) =
      case mid of
        M.MCCALL {resultVar, codeExp, closureEnvExp, argExpList, tail,
                  handler, loc} =>
        CALL {def = Set.singleton resultVar,
              use = useValues (codeExp :: optionToList closureEnvExp
                               @ argExpList),
              returnTo = prepareCont env ([resultVar], (mids, last)),
              unwindTo = unwindTo env handler,
              causeGC = true,
              orig = mid}
      | M.MCLARGEINT {resultVar, dataLabel, loc} =>
        MID {def = Set.singleton resultVar,
             use = Set.empty,
             orig = mid,
             causeGC = true,
             next = prepareExp env (mids, last)}
      | M.MCFOREIGNAPPLY {resultVar, funExp, attributes, argExpList,
                          handler, loc} =>
        let
          val {noCallback, allocMLValue, suspendThread, ...} = attributes
          val causeGC = not noCallback orelse allocMLValue orelse suspendThread
          val returnTo = prepareCont env (optionToList resultVar, (mids, last))
        in
          CALL {def = Set.fromList (optionToList resultVar),
                use = useValues (funExp :: argExpList),
                returnTo = returnTo,
                unwindTo = unwindTo env handler,
                causeGC = causeGC,
                orig = mid}
        end
      | M.MCEXPORTCALLBACK {resultVar, codeExp, closureEnvExp, instTyvars,
                            loc} =>
        MID {def = Set.singleton resultVar,
             use = useValues [codeExp, closureEnvExp],
             orig = mid,
             causeGC = true,
             next = prepareExp env (mids, last)}
      | M.MCEXVAR {resultVar, id, loc} =>
        MID {def = Set.singleton resultVar,
             use = Set.empty,
             orig = mid,
             causeGC = false,
             next = prepareExp env (mids, last)}
      | M.MCMEMCPY_FIELD {dstAddr, srcAddr, copySize, loc} =>
        MID {def = Set.empty,
             use = Set.union (useAddrs [dstAddr, srcAddr], useValue copySize),
             orig = mid,
             causeGC = false,
             next = prepareExp env (mids, last)}
      | M.MCMEMMOVE_UNBOXED_ARRAY {dstAddr, srcAddr, numElems, elemSize, loc} =>
        MID {def = Set.empty,
             use = Set.union (useAddrs [dstAddr, srcAddr],
                           useValues [numElems, elemSize]),
             orig = mid,
             causeGC = false,
             next = prepareExp env (mids, last)}
      | M.MCMEMMOVE_BOXED_ARRAY {srcArray, dstArray, srcIndex, dstIndex,
                                 numElems, loc} =>
        MID {def = Set.empty,
             use = useValues [srcArray, dstArray, srcIndex, dstIndex,
                               numElems],
             orig = mid,
             causeGC = false,
             next = prepareExp env (mids, last)}
      | M.MCALLOC {resultVar, objType, payloadSize, allocSize, loc} =>
        MID {def = Set.singleton resultVar,
             use = Set.union (useObjtype objType,
                           useValues [payloadSize, allocSize]),
             orig = mid,
             causeGC = true,
             next = prepareExp env (mids, last)}
      | M.MCDISABLEGC =>
        MID {def = Set.empty,
             use = Set.empty,
             orig = mid,
             causeGC = false,
             next = prepareExp env (mids, last)}
      | M.MCENABLEGC =>
        MID {def = Set.empty,
             use = Set.empty,
             orig = mid,
             causeGC = false,
             next = prepareExp env (mids, last)}
      | M.MCCHECKGC =>
        MID {def = Set.empty,
             use = Set.empty,
             orig = mid,
             causeGC = true,
             next = prepareExp env (mids, last)}
      | M.MCRECORDDUP {resultVar, recordExp, loc} =>
        MID {def = Set.singleton resultVar,
             use = useValue recordExp,
             orig = mid,
             causeGC = true,
             next = prepareExp env (mids, last)}
      | M.MCBZERO {recordExp, recordSize, loc} =>
        MID {def = Set.empty,
             use = useValues [recordExp, recordSize],
             orig = mid,
             causeGC = false,
             next = prepareExp env (mids, last)}
      | M.MCSAVESLOT {slotId, value, loc} =>
        MID {def = Set.empty,
             use = useValue value,
             orig = mid,
             causeGC = false,
             next = prepareExp env (mids, last)}
      | M.MCLOADSLOT {resultVar, slotId, loc} =>
        MID {def = Set.singleton resultVar,
             use = Set.empty,
             orig = mid,
             causeGC = false,
             next = prepareExp env (mids, last)}
      | M.MCLOAD {resultVar, srcAddr, loc} =>
        MID {def = Set.singleton resultVar,
             use = useAddr srcAddr,
             orig = mid,
             causeGC = false,
             next = prepareExp env (mids, last)}
      | M.MCPRIMAPPLY {resultVar, primInfo, argExpList, argTyList, resultTy,
                       instTyList, instTagList, instSizeList, loc} =>
        MID {def = Set.singleton resultVar,
             use = useValues (argExpList @ instTagList @ instSizeList),
             orig = mid,
             causeGC = false,
             next = prepareExp env (mids, last)}
      | M.MCBITCAST {resultVar, exp, expTy, targetTy, loc} =>
        MID {def = Set.singleton resultVar,
             use = useValue exp,
             orig = mid,
             causeGC = false,
             next = prepareExp env (mids, last)}
      | M.MCSTORE {srcExp, srcTy, dstAddr, barrier, loc} =>
        MID {def = Set.empty,
             use = Set.union (useValue srcExp, useAddr dstAddr),
             orig = mid,
             causeGC = false,
             next = prepareExp env (mids, last)}
      | M.MCEXPORTVAR {id, ty, valueExp, loc} =>
        MID {def = Set.empty,
             use = useValue valueExp,
             orig = mid,
             causeGC = false,
             next = prepareExp env (mids, last)}

  fun prepare (argVarList, mcexp, cleanupHandler) =
      let
        val startBlock = newBlock (FunLocalLabel.generate nil) nil
        val exitBlock = newBlock (FunLocalLabel.generate nil) nil
        val handlerEnv =
            case cleanupHandler of
              NONE => HandlerLabel.Map.empty
            | SOME id => HandlerLabel.Map.singleton (id, exitBlock)
        val env = {currentBlock = startBlock,
                   exitBlock = exitBlock,
                   handlerEnv = handlerEnv,
                   blockEnv = FunLocalLabel.Map.empty} : prepareEnv
        val exp = DEF {def = Set.fromList argVarList,
                       causeGC = false,
                       next = prepareExp env mcexp}
        val _ = setBody (startBlock, exp)
      in
        (startBlock, exitBlock)
      end

  local
    fun insert f alloc nil next = next
      | insert f alloc (var::vars) next =
        case VarID.Map.find (alloc, #id var) of
          NONE => insert f alloc vars next
        | SOME slot => f (var, slot) :: insert f alloc vars next
  in

  fun save alloc vars next =
      insert
        (fn (var, slot) =>
            M.MCSAVESLOT {slotId = slot, value = M.ANVAR var, loc = Loc.noloc})
        alloc
        (Set.listItems vars)
        next

  fun load alloc vars next =
      insert
        (fn (var, slot) =>
            M.MCLOADSLOT {resultVar = var, slotId = slot, loc = Loc.noloc})
        alloc
        (Set.listItems vars)
        next

  end (* local *)

  fun reconstructExp alloc exp =
      case exp of
        DEF {def, causeGC, next} =>
        let
          val (mids, last) = reconstructExp alloc next
        in
          (save alloc def mids, last)
        end
      | MID {def, use, orig, causeGC, next} =>
        let
          val (mids, last) = reconstructExp alloc next
        in
          (load alloc use (orig :: save alloc def mids), last)
        end
      | CALL {def, use, returnTo, unwindTo, causeGC, orig} =>
        let
          val (_, (mids, last)) = reconstructBlock alloc returnTo
        in
          (load alloc use (orig :: save alloc def mids), last)
        end
      | LAST {def, use, args, orig} =>
        ((load alloc use)
           (List.mapPartial
              (fn (var, value) =>
                  case VarID.Map.find (alloc, #id var) of
                    NONE => NONE
                  | SOME slot =>
                    SOME (M.MCSAVESLOT
                            {slotId = slot, value = value, loc = Loc.noloc}))
              args),
         orig)
      | LOCALCODE {id, recursive, body, next, loc} =>
        let
          val (argVarList, (mids, last)) = reconstructBlock alloc body
        in
          (nil, M.MCLOCALCODE {id = id,
                               recursive = recursive,
                               argVarList = argVarList,
                               bodyExp = (mids, last),
                               nextExp = reconstructExp alloc next,
                               loc = loc})
        end
      | HANDLER {nextExp, id, exnVar, handler, loc} =>
        let
          val nextExp = reconstructExp alloc nextExp
          val (_, handlerExp) = reconstructBlock alloc handler
        in
          (nil, M.MCHANDLER {nextExp = nextExp,
                             id = id,
                             exnVar = exnVar,
                             handlerExp = handlerExp,
                             loc = loc})
        end

  and reconstructBlock alloc (BLOCK (ref {argVarList, bodyExp, ...})) =
      (argVarList, reconstructExp alloc bodyExp)

  fun blocks (b as (BLOCK (ref {bodyExp, ...}))) =
      b :: blocksInExp bodyExp

  and blocksInExp exp =
      case exp of
        DEF {def, causeGC, next} => blocksInExp next
      | MID {def, use, orig, causeGC, next} => blocksInExp next
      | CALL {def, use, returnTo, unwindTo, causeGC, orig} => blocks returnTo
      | LAST {def, use, args, orig} => nil
      | LOCALCODE {id, recursive, body, next, loc} =>
        blocksInExp next @ blocks body
      | HANDLER {nextExp, id, exnVar, handler, loc} =>
        blocksInExp nextExp @ blocks handler

  fun liveness nil = ()
    | liveness (BLOCK (r as ref {successors, predecessors, liveIn,
                                 defuse = {defs, uses}, ...}) :: blocks) =
      let
        val liveOut =
            Set.merge (map (fn BLOCK (ref {liveIn,...}) => liveIn) successors)
        val newLiveIn = Set.union (Set.setMinus (liveOut, defs), uses)
        val _ = r := (!r # {liveOut = liveOut, liveIn = newLiveIn})
        val blocks =
            if Set.isSubsetOf (newLiveIn, liveIn)
            then blocks
            else predecessors @ blocks
      in
        liveness blocks
      end

  fun addInterferences interferences vars =
      foldl
        (fn ({id,...}, z) =>
            case VarID.Map.find (z, id) of
              NONE => VarID.Map.insert (z, id, vars)
            | SOME v => VarID.Map.insert (z, id, Set.union (v, vars)))
        interferences
        (Set.listItems vars)

  fun interferenceStep (liveOut, {interferences, gc}) (def, use, causeGC) =
      let
        val interfere = Set.union (def, liveOut)
        val alive = Set.setMinus (liveOut, def)
        val liveIn = Set.union (alive, use)
        val gc = if causeGC then Set.union (gc, alive) else gc
      in
        (liveIn, {interferences = interfere::interferences, gc = gc})
      end

  fun interferenceExp z exp =
      case exp of
        DEF {def, causeGC, next} =>
        interferenceStep (interferenceExp z next) (def, Set.empty, causeGC)
      | MID {def, use, orig, causeGC, next} =>
        interferenceStep (interferenceExp z next) (def, use, causeGC)
      | CALL {def, use, returnTo, unwindTo, causeGC, orig} =>
        interferenceStep z (def, use, causeGC)
      | LAST {def, use, args, orig} =>
        interferenceStep z (def, use, false)
      | LOCALCODE {id, recursive, body, next, loc} =>
        interferenceExp z next
      | HANDLER {nextExp, id, exnVar, handler, loc} =>
        interferenceExp z nextExp

  fun interferenceBlock i (BLOCK (ref (r as {bodyExp, liveOut, ...}))) =
      #2 (interferenceExp (liveOut, i) bodyExp)

  fun interference nil = {interferences = nil, gc = Set.empty}
    | interference (block::blocks) =
      interferenceBlock (interference blocks) block

  fun shrinkInterference nil = nil
    | shrinkInterference [x] = [x]
    | shrinkInterference (vars1::(t as vars2::t2)) =
      if Set.isSubsetOf (vars1, vars2)
      then shrinkInterference t
      else if Set.isSubsetOf (vars2, vars1)
      then shrinkInterference (vars1::t2)
      else vars1 :: shrinkInterference t

  (* assume that both list is sorted by VarID.id *)
  fun varsToSlots (nil, nil) = nil
    | varsToSlots (nil, _::_) = raise Bug.Bug "varsToSlots"
    | varsToSlots (alloc, nil) = nil : SlotID.id option ref list
    | varsToSlots ((id1,r)::alloc, (h as {id,...}:M.varInfo)::slots) =
      case VarID.compare (id1, id) of
        EQUAL => r :: varsToSlots (alloc, slots)
      | GREATER => raise Bug.Bug "varsToSlots"
      | LESS => varsToSlots (alloc, h::slots)

  fun allocSlot {interferences, gc} =
      let
        val interferences = map (fn x => Set.intersect (x, gc)) interferences
        val interferences = shrinkInterference interferences
        val interferences = foldl (fn (vars, z) => addInterferences z vars)
                                  VarID.Map.empty
                                  interferences
        val numSlots =
            VarID.Map.foldl (fn (x,z) => Int.max (Set.numItems x, z))
                            0 interferences
        val candidates = SlotSet.generate numSlots
        val alloc = VarID.Map.map (fn x => (ref NONE, x)) interferences
        val refs = VarID.Map.foldri (fn (i,(s,_),z) => (i,s)::z) nil alloc
      in
        VarID.Map.map
          (fn (slot, adjVars) =>
              let
                val adj = varsToSlots (refs, Set.listItems adjVars)
                val adjset = SlotSet.fromList (List.mapPartial (op !) adj)
                val unalloced = SlotSet.setMinus (candidates, adjset)
                val id = SlotSet.choose unalloced
              in
                slot := SOME id;
                id
              end)
          alloc
      end

  fun compileFunc (argVarList, mcexp, cleanupHandler) =
      let
        val (startBlock, exitBlock) =
            prepare (argVarList, mcexp, cleanupHandler)
        val blocks = rev (blocks startBlock)
        val () = liveness (exitBlock :: blocks)
        val alloc = allocSlot (interference blocks)
        val (_, bodyExp) = reconstructBlock alloc startBlock
        val frameSlots =
            VarID.Map.foldli
              (fn (_,id,z) => SlotID.Map.insert (z, id, R.BOXEDty))
              SlotID.Map.empty
              alloc
      in
        (bodyExp, frameSlots)
      end

  fun unionSlotMap (slots1, slots2) : R.ty SlotID.Map.map =
      SlotID.Map.unionWith
        (fn _ => raise Bug.Bug "unionSlotMap")
        (slots1, slots2)

  fun compileTopdec topdec =
      case topdec of
        M.MTTOPLEVEL {symbol, frameSlots, bodyExp, loc} =>
        let
          val (bodyExp, slots) = compileFunc (nil, bodyExp, NONE)
        in
          M.MTTOPLEVEL {symbol = symbol,
                        frameSlots = unionSlotMap (frameSlots, slots),
                        bodyExp = bodyExp,
                        loc = loc}
        end
      | M.MTFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
                      frameSlots, bodyExp, retTy, loc} =>
        let
          val params = optionToList closureEnvVar @ argVarList
          val (bodyExp, slots) = compileFunc (params, bodyExp, NONE)
        in
          M.MTFUNCTION {id = id,
                        tyvarKindEnv = tyvarKindEnv,
                        argVarList = argVarList,
                        closureEnvVar = closureEnvVar,
                        frameSlots = unionSlotMap (frameSlots, slots),
                        bodyExp = bodyExp,
                        retTy = retTy,
                        loc = loc}
        end
      | M.MTCALLBACKFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
                              frameSlots, bodyExp, attributes, retTy,
                              cleanupHandler, loc} =>
        let
          val params = optionToList closureEnvVar @ argVarList
          val (bodyExp, slots) =
              compileFunc (params, bodyExp, SOME cleanupHandler)
        in
          M.MTCALLBACKFUNCTION {id = id,
                                tyvarKindEnv = tyvarKindEnv,
                                argVarList = argVarList,
                                closureEnvVar = closureEnvVar,
                                frameSlots = unionSlotMap (frameSlots, slots),
                                bodyExp = bodyExp,
                                attributes = attributes,
                                retTy = retTy,
                                cleanupHandler = cleanupHandler,
                                loc = loc}
        end

  fun compile ({topdata, topdecs}:M.program) =
      let
        val topdecs = MachineCodeRename.rename topdecs
      in
        {topdata = topdata, topdecs = map compileTopdec topdecs} : M.program
      end

end
