(**
 * allocate root set
 *
 * @copyright (C) 2021 SML# Development Team.
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
    val union : set * set -> set
    val first : (SlotID.id -> bool) -> set -> SlotID.id
    val member : set * SlotID.id -> bool
  end =
  struct
    type set = SlotID.id list

    val empty = nil : set

    fun generate numItems =
        (* assume that SlotID.generate generates sequential numbers *)
        List.tabulate (numItems, fn _ => SlotID.generate ())

    fun revAppend nil r = r : set
      | revAppend (h :: t) r = revAppend t (h :: r)

    fun union (set1, set2) =
        let
          fun loop nil set r = revAppend r set
            | loop set nil r = revAppend r set
            | loop (l1 as (h1 :: t1)) (l2 as (h2 :: t2)) r =
              case SlotID.compare (h1, h2) of
                EQUAL => loop t1 t2 (h1 :: r)
              | GREATER => loop l1 t2 (h2 :: r)
              | LESS => loop t1 l2 (h1 :: r)
        in
          loop set1 set2 nil
        end

    fun mergeStep nil r = r
      | mergeStep [x] r = x :: r
      | mergeStep (h1 :: h2 :: t) r = mergeStep t (union (h1, h2) :: r)

    fun merge nil = nil
      | merge [x] = x
      | merge l = merge (mergeStep l nil)

    fun fromList vars =
        let
          fun loop nil r = merge r
            | loop (id :: ids) r = loop ids ([id] :: r)
        in
          loop vars nil
        end

    fun first f (nil : set) = raise Bug.Bug "SlotSet.first"
      | first f (id :: ids) =
        if f id then id else first f ids

    fun member (set : set, id) =
        let
          fun loop nil _ = false
            | loop (h :: t) id = h = id orelse loop t id
        in
          loop set id
        end
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
    val setMinus : set * set -> set
    val isSubsetOf : set * set -> bool
    val toIdSet : set -> VarID.Set.set
    val intersect : set * VarID.Set.set -> set
  end =
  struct
    type set = M.varInfo list  (* sorted by id *)

    val empty = nil : set

    val numItems = length

    fun listItems (l:set) = l

    fun revAppend nil r = r : set
      | revAppend (h :: t) r = revAppend t (h :: r)

    fun singleton (v as {id, ty=(_, {tag = R.BOXED, ...})}) = [v]
      | singleton (_:M.varInfo) = empty

    fun union (set1, set2) =
        let
          fun loop nil set r = revAppend r set
            | loop set nil r = revAppend r set
            | loop (l1 as (h1 :: t1)) (l2 as (h2 :: t2)) r =
              case VarID.compare (#id h1, #id h2) of
                EQUAL => loop t1 t2 (h1 :: r)
              | GREATER => loop l1 t2 (h2 :: r)
              | LESS => loop t1 l2 (h1 :: r)
        in
          loop set1 set2 nil
        end

    fun mergeStep nil r = r
      | mergeStep [x] r = x :: r
      | mergeStep (h1 :: h2 :: t) r = mergeStep t (union (h1, h2) :: r)

    fun merge nil = nil
      | merge [x] = x
      | merge l = merge (mergeStep l nil)

    fun fromList vars =
        let
          fun loop nil r = merge r
            | loop (var :: vars) r =
              case singleton var of
                nil => loop vars r
              | set => loop vars (set :: r)
        in
          loop vars nil
        end

    fun setMinus (set1, set2) =
        let
          fun loop nil (set : set) r = revAppend r nil
            | loop set nil r = revAppend r set
            | loop (l1 as (h1::t1)) (l2 as (h2::t2)) r =
              case VarID.compare (#id h1, #id h2) of
                EQUAL => loop t1 t2 r
              | GREATER => loop l1 t2 r
              | LESS => loop t1 l2 (h1 :: r)
        in
          loop set1 set2 nil
        end

    fun isSubsetOf (nil, set) = true
      | isSubsetOf (set, nil) = false
      | isSubsetOf (l1 as (h1::t1) : set, l2 as (h2::t2) : set) =
        case VarID.compare (#id h1, #id h2) of
          EQUAL => isSubsetOf (t1, t2)
        | GREATER => isSubsetOf (l1, t2)
        | LESS => false

    fun toIdSet set =
        let
          fun loop (nil : set) r = r
            | loop (var :: vars) r =
              loop vars (VarID.Set.add (r, #id var))
        in
          loop set VarID.Set.empty
        end

    fun intersect (set : set, idset) =
        let
          fun loop nil r = revAppend r nil
            | loop (var :: vars) r =
              if VarID.Set.member (idset, #id var)
              then loop vars (var :: r)
              else loop vars r
        in
          loop set nil
        end
  end

  fun nullValue ty =
      M.ANCONST {const = M.NVNULLPOINTER, ty = ty}

  fun useValue value =
      case value of
        M.ANCONST _ => Set.empty
      | M.ANCAST {exp, expTy, targetTy} => useValue exp
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

  fun varsToSlots alloc vars =
      SlotSet.fromList
        (List.mapPartial
           (fn var => VarID.Map.find (alloc, #id var))
           (Set.listItems vars))

  datatype gc =
      NOGC
    | CAUSEGC of {defsBeforeGC : Set.set}

  datatype gc_slot =
      NOGC_SLOT
    | CAUSEGC_SLOT of {saveBeforeGC : SlotSet.set}

  fun updateGC (true, _) _ = CAUSEGC {defsBeforeGC = Set.empty}
    | updateGC (false, _) NOGC = NOGC
    | updateGC (false, defs) (CAUSEGC {defsBeforeGC}) =
      CAUSEGC {defsBeforeGC = Set.union (defsBeforeGC, defs)}

  fun updateGC_slot _ (true, _) _ = CAUSEGC_SLOT {saveBeforeGC = SlotSet.empty}
    | updateGC_slot _ (false, _) NOGC_SLOT = NOGC_SLOT
    | updateGC_slot alloc (false, defs) (CAUSEGC_SLOT {saveBeforeGC}) =
      CAUSEGC_SLOT
        {saveBeforeGC = SlotSet.union (saveBeforeGC, varsToSlots alloc defs)}

  fun isSmallerThanOrEqualToGC (NOGC, NOGC) = true
    | isSmallerThanOrEqualToGC (NOGC, CAUSEGC _) = true
    | isSmallerThanOrEqualToGC (CAUSEGC _, NOGC) = false
    | isSmallerThanOrEqualToGC (CAUSEGC {defsBeforeGC=s1},
                                CAUSEGC {defsBeforeGC=s2}) =
      Set.isSubsetOf (s1, s2)

  fun toGC_slot alloc NOGC = NOGC_SLOT
    | toGC_slot alloc (CAUSEGC {defsBeforeGC}) =
      CAUSEGC_SLOT {saveBeforeGC = varsToSlots alloc defsBeforeGC}

  datatype exp_mid =
      START
    | DEF of
      {
        def : Set.set,
        causeGC : bool,
        prev : exp_mid
      }
    | MID of
      {
        def : Set.set,
        use : Set.set,
        orig : M.mcexp_mid,
        causeGC : bool,
        prev : exp_mid
      }
    | LOCALCODE of
      {
        recursive : bool,
        binds : {id : FunLocalLabel.id, body : block} list,
        prev : exp_mid,
        loc : M.loc
      }
    | HANDLER of
      {
        exnVar : M.varInfo,
        id : HandlerLabel.id,
        handler : block,
        cleanup : HandlerLabel.id option,
        prev : exp_mid,
        loc : M.loc
      }

  and exp =
      CALL of
      {
        def : Set.set,
        use : Set.set,
        returnTo : block,
        causeGC : bool,
        orig : M.mcexp_mid,
        prev : exp_mid
      }
    | LAST of
      {
        def : Set.set,
        use : Set.set,
        args : (M.varInfo * M.mcvalue) list,
        orig : M.mcexp_last,
        prev : exp_mid
      }

  and block =
      BLOCK of
      {
        id : FunLocalLabel.id,
        done : bool ref,
        successors : block list,
        predecessors : block list,
        argVarList : M.varInfo list,
        bodyExp : exp,
        defuse : {defs : Set.set, uses : Set.set, gc : gc},
        liveIn : Set.set,
        liveOut : Set.set,
        gcIn : gc,
        gcOut : gc
      } ref

  val dummyExp =
      LAST {def = Set.empty,
            use = Set.empty,
            args = nil,
            orig = M.MCUNREACHABLE,
            prev = START}

  fun newBlock id argVarList =
      BLOCK (ref {id = id,
                  done = ref false,
                  successors = nil,
                  predecessors = nil,
                  argVarList = argVarList,
                  bodyExp = dummyExp,
                  defuse = {defs = Set.empty, uses = Set.empty, gc = NOGC},
                  liveIn = Set.empty,
                  liveOut = Set.empty,
                  gcIn = NOGC,
                  gcOut = NOGC})

  fun addEdge (fromBlock as BLOCK r1,
               toBlock as BLOCK (r2 as ref {argVarList, ...})) =
      (r1 := (!r1 # {successors = toBlock :: #successors (!r1)});
       r2 := (!r2 # {predecessors = fromBlock :: #predecessors (!r2)});
       argVarList)

  fun defuseMid (defuse as {defs, uses, gc}) mid =
      case mid of
        START => defuse
      | DEF {def, causeGC, prev} =>
        defuseMid
          {defs = Set.union (defs, def),
           uses = Set.setMinus (uses, def),
           gc = updateGC (causeGC, def) gc}
          prev
      | MID {def, use, orig, causeGC, prev} =>
        defuseMid
          {defs = Set.union (defs, def),
           uses = Set.union (Set.setMinus (uses, def), use),
           gc = updateGC (causeGC, def) gc}
          prev
      | LOCALCODE {recursive, binds, prev, loc} => defuseMid defuse prev
      | HANDLER {id, exnVar, handler, cleanup, prev, loc} =>
        defuseMid defuse prev

  fun defuseExp exp =
      case exp of
        CALL {def, use, returnTo, causeGC, orig, prev} =>
        defuseMid
          {defs = def,
           uses = use,
           gc = updateGC (causeGC, def) NOGC}
          prev
      | LAST {def, use, args, orig, prev} =>
        defuseMid
          {defs = def, uses = use, gc = NOGC}
          prev

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

  fun addHandlerEdge ({currentBlock, exitBlock, ...}:prepareEnv) NONE =
      addEdge (currentBlock, exitBlock)
    | addHandlerEdge {currentBlock, handlerEnv, ...} (SOME id) =
      case HandlerLabel.Map.find (handlerEnv, id) of
        NONE => raise Bug.Bug "addHandlerEdge"
      | SOME block => addEdge (currentBlock, block)

  fun prepareLast prev (env:prepareEnv) last =
      case last of
        M.MCRETURN {value, loc} =>
        (
          addEdge (#currentBlock env, #exitBlock env);
          LAST {def = Set.empty,
                use = useValue value,
                args = nil,
                orig = last,
                prev = prev}
        )
      | M.MCRAISE {argExp, cleanup, loc} =>
        (
          addEdge (#currentBlock env, #exitBlock env);
          addHandlerEdge env cleanup;
          LAST {def = Set.empty,
                use = useValues [argExp],
                args = nil,
                orig = last,
                prev = prev}
        )
      | M.MCHANDLER {nextExp, id, exnVar, handlerExp, cleanup, loc} =>
        let
          val handlerBlock = newBlock (FunLocalLabel.generate nil) nil
          val nextEnv =
              env # {handlerEnv = HandlerLabel.Map.insert
                                    (#handlerEnv env, id, handlerBlock)}
          val handlerEnv = env # {currentBlock = handlerBlock}
          val handlerPrev = DEF {def = Set.singleton exnVar,
                                 causeGC = true,
                                 prev = START}
          val handlerExp = prepareExp handlerPrev handlerEnv handlerExp
          val _ = setBody (handlerBlock, handlerExp)
        in
          prepareExp
            (HANDLER {id = id,
                      exnVar = exnVar,
                      handler = handlerBlock,
                      cleanup = cleanup,
                      loc = loc,
                      prev = prev})
            nextEnv
            nextExp
        end
      | M.MCLOCALCODE {recursive, binds, nextExp, loc} =>
        let
          val binds =
              map (fn {id, argVarList, bodyExp} =>
                      {id = id,
                       argVarList = argVarList,
                       bodyExp = bodyExp,
                       block = newBlock id argVarList})
                  binds
          val blockEnv =
              foldl (fn ({id, block, ...}, blockEnv) =>
                        FunLocalLabel.Map.insert (blockEnv, id, block))
                    (#blockEnv env)
                    binds
          val env2 = env # {blockEnv = blockEnv}
          val env3 = if recursive then env2 else env
          val binds =
              map (fn {id, argVarList, bodyExp, block} =>
                      let
                        val env4 = env3 # {currentBlock = block}
                      in
                        setBody (block, prepareExp START env4 bodyExp);
                        {id = id, body = block}
                      end)
                  binds
        in
          prepareExp
            (LOCALCODE {recursive = recursive,
                        binds = binds,
                        prev = prev,
                        loc = loc})
            env2
            nextExp
        end
      | M.MCGOTO {id, argList, loc} =>
        let
          val argVarList = jumpTo env id
        in
          LAST {def = Set.fromList argVarList,
                use = useValues argList,
                args = ListPair.zipEq (argVarList, argList),
                orig = last,
                prev = prev}
        end
      | M.MCSWITCH {switchExp, expTy, branches, default, loc} =>
        (
          app (fn (_, id) => (jumpTo env id; ())) branches;
          jumpTo env default;
          LAST {def = Set.empty,
                use = useValue switchExp,
                args = nil,
                orig = last,
                prev = prev}
        )
      | M.MCUNREACHABLE =>
        (
          addEdge (#currentBlock env, #exitBlock env);
          LAST {def = Set.empty,
                use = Set.empty,
                args = nil,
                orig = last,
                prev = prev}
        )

  and prepareCont (env as {currentBlock, ...}) (argVarList, nextExp) =
      let
        val nextBlock = newBlock (FunLocalLabel.generate nil) argVarList
        val nextEnv = env # {currentBlock = nextBlock}
        val nextExp = prepareExp START nextEnv nextExp
        val _ = setBody (nextBlock, nextExp)
        val _ = addEdge (currentBlock, nextBlock)
      in
        nextBlock
      end

  and prepareExp prev (env:prepareEnv) (nil, last) =
      prepareLast prev env last
    | prepareExp prev env (mid :: mids, last) =
      case mid of
        M.MCCALL {resultVar, resultTy, codeExp, closureEnvExp, instTyList,
                  argExpList, tail, handler, loc} =>
        let
          val returnTo = prepareCont env (optionToList resultVar, (mids, last))
        in
          addHandlerEdge env handler;
          CALL {def = Set.fromList (optionToList resultVar),
                use = useValues (codeExp :: optionToList closureEnvExp
                                 @ argExpList),
                returnTo = returnTo,
                causeGC = not tail,
                orig = mid,
                prev = prev}
        end
      | M.MCINTINF {resultVar, dataLabel, loc} =>
        prepareExp
          (MID {def = Set.singleton resultVar,
                use = Set.empty,
                orig = mid,
                causeGC = true,
                prev = prev})
          env
          (mids, last)
      | M.MCFOREIGNAPPLY {resultVar, funExp, attributes, argExpList,
                          handler, loc} =>
        let
          val {causeGC, fast, ...} = attributes
          val causeGC = causeGC orelse not fast
          val returnTo = prepareCont env (optionToList resultVar, (mids, last))
        in
          addHandlerEdge env handler;
          CALL {def = Set.fromList (optionToList resultVar),
                use = useValues (funExp :: argExpList),
                returnTo = returnTo,
                causeGC = causeGC,
                orig = mid,
                prev = prev}
        end
      | M.MCEXPORTCALLBACK {resultVar, codeExp, closureEnvExp, instTyvars,
                            loc} =>
        prepareExp
          (MID {def = Set.singleton resultVar,
                use = useValues [codeExp, closureEnvExp],
                orig = mid,
                causeGC = true,
                prev = prev})
          env
          (mids, last)
      | M.MCEXVAR {resultVar, id, loc} =>
        prepareExp
          (MID {def = Set.singleton resultVar,
                use = Set.empty,
                orig = mid,
                causeGC = false,
                prev = prev})
          env
          (mids, last)
      | M.MCMEMCPY_FIELD {dstAddr, srcAddr, copySize, loc} =>
        prepareExp
          (MID {def = Set.empty,
                use = Set.union (useAddrs [dstAddr, srcAddr],
                                 useValue copySize),
                orig = mid,
                causeGC = false,
                prev = prev})
          env
          (mids, last)
      | M.MCMEMMOVE_UNBOXED_ARRAY {dstAddr, srcAddr, numElems, elemSize, loc} =>
        prepareExp
          (MID {def = Set.empty,
                use = Set.union (useAddrs [dstAddr, srcAddr],
                                 useValues [numElems, elemSize]),
                orig = mid,
                causeGC = false,
                prev = prev})
          env
          (mids, last)
      | M.MCMEMMOVE_BOXED_ARRAY {srcArray, dstArray, srcIndex, dstIndex,
                                 numElems, loc} =>
        prepareExp
          (MID {def = Set.empty,
                use = useValues [srcArray, dstArray, srcIndex, dstIndex,
                                 numElems],
                orig = mid,
                causeGC = false,
                prev = prev})
          env
          (mids, last)
      | M.MCALLOC {resultVar, objType, payloadSize, allocSize, loc} =>
        prepareExp
          (MID {def = Set.singleton resultVar,
                use = Set.union (useObjtype objType,
                                 useValues [payloadSize, allocSize]),
                orig = mid,
                causeGC = true,
                prev = prev})
          env
          (mids, last)
      | M.MCALLOC_COMPLETED =>
        prepareExp
          (MID {def = Set.empty,
                use = Set.empty,
                orig = mid,
                causeGC = false,
                prev = prev})
          env
          (mids, last)
      | M.MCCHECK {handler} =>
        let
          val returnTo = prepareCont env (nil, (mids, last))
        in
          addHandlerEdge env handler;
          CALL {def = Set.empty,
                use = Set.empty,
                returnTo = returnTo,
                causeGC = true,
                orig = mid,
                prev = prev}
        end
      | M.MCRECORDDUP_ALLOC {resultVar, copySizeVar, recordExp, loc} =>
        prepareExp
          (MID {def = Set.fromList [resultVar, copySizeVar],
                use = useValue recordExp,
                orig = mid,
                causeGC = true,
                prev = prev})
          env
          (mids, last)
      | M.MCRECORDDUP_COPY {dstRecord, srcRecord, copySize, loc} =>
        prepareExp
          (MID {def = Set.empty,
                use = useValues [dstRecord, srcRecord, copySize],
                orig = mid,
                causeGC = false,
                prev = prev})
          env
          (mids, last)
      | M.MCBZERO {recordExp, recordSize, loc} =>
        prepareExp
          (MID {def = Set.empty,
                use = useValues [recordExp, recordSize],
                orig = mid,
                causeGC = false,
                prev = prev})
          env
          (mids, last)
      | M.MCSAVESLOT {slotId, value, loc} =>
        prepareExp
          (MID {def = Set.empty,
                use = useValue value,
                orig = mid,
                causeGC = false,
                prev = prev})
          env
          (mids, last)
      | M.MCLOADSLOT {resultVar, slotId, loc} =>
        prepareExp
          (MID {def = Set.singleton resultVar,
                use = Set.empty,
                orig = mid,
                causeGC = false,
                prev = prev})
          env
          (mids, last)
      | M.MCLOAD {resultVar, srcAddr, loc} =>
        prepareExp
          (MID {def = Set.singleton resultVar,
                use = useAddr srcAddr,
                orig = mid,
                causeGC = false,
                prev = prev})
          env
          (mids, last)
      | M.MCPRIMAPPLY {resultVar, primInfo, argExpList, argTyList, resultTy,
                       instTyList, instTagList, instSizeList, loc} =>
        prepareExp
          (MID {def = Set.singleton resultVar,
                use = useValues (argExpList @ instTagList @ instSizeList),
                orig = mid,
                causeGC = false,
                prev = prev})
          env
          (mids, last)
      | M.MCBITCAST {resultVar, exp, expTy, targetTy, loc} =>
        prepareExp
          (MID {def = Set.singleton resultVar,
                use = useValue exp,
                orig = mid,
                causeGC = false,
                prev = prev})
          env
          (mids, last)
      | M.MCSTORE {srcExp, srcTy, dstAddr, barrier, loc} =>
        prepareExp
          (MID {def = Set.empty,
                use = Set.union (useValue srcExp, useAddr dstAddr),
                orig = mid,
                causeGC = false,
                prev = prev})
          env
          (mids, last)
      | M.MCEXPORTVAR {id, ty, valueExp, loc} =>
        prepareExp
          (MID {def = Set.empty,
                use = useValue valueExp,
                orig = mid,
                causeGC = false,
                prev = prev})
          env
          (mids, last)
      | M.MCKEEPALIVE {value, loc} =>
        prepareExp
          (MID {def = Set.empty,
                use = useValue value,
                orig = mid,
                causeGC = false,
                prev = prev})
          env
          (mids, last)

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
        val prev = DEF {def = Set.fromList argVarList,
                        causeGC = false,
                        prev = START}
        val exp = prepareExp prev env mcexp
        val _ = setBody (startBlock, exp)
      in
        (startBlock, exitBlock)
      end

  val empty = fn x : M.mcexp => x
  fun mid insn = fn (mids, last) : M.mcexp => (insn::mids, last) : M.mcexp
  fun last insn = fn () => (nil, insn) : M.mcexp

  local
    fun insert f alloc nil = empty
      | insert f alloc (var::vars) =
        case VarID.Map.find (alloc, #id var) of
          NONE => insert f alloc vars
        | SOME slot => f (var, slot) o insert f alloc vars

    fun insertWithValue f alloc nil = empty
      | insertWithValue f alloc ((var, value)::args) =
        case VarID.Map.find (alloc, #id var) of
          NONE => insertWithValue f alloc args
        | SOME slot => f (value, slot) o insertWithValue f alloc args
  in

  fun save alloc vars =
      insert
        (fn (var, slot) =>
            mid (M.MCSAVESLOT
                   {slotId = slot, value = M.ANVAR var, loc = Loc.noloc}))
        alloc
        (Set.listItems vars)

  fun saveArgs alloc args =
      insertWithValue
        (fn (value, slot) =>
            mid (M.MCSAVESLOT
                   {slotId = slot, value = value, loc = Loc.noloc}))
        alloc
        args

  fun load alloc vars =
      insert
        (fn (var, slot) =>
            mid (M.MCLOADSLOT
                   {resultVar = var, slotId = slot, loc = Loc.noloc}))
        alloc
        (Set.listItems vars)

  fun kill alloc NOGC_SLOT vars = empty
    | kill alloc (CAUSEGC_SLOT {saveBeforeGC}) vars =
      insert
        (fn (var, slot) =>
            if SlotSet.member (saveBeforeGC, slot)
            then empty
            else mid (M.MCSAVESLOT
                        {slotId = slot,
                         value = nullValue (#ty var),
                         loc = Loc.noloc}))
        alloc
        (Set.listItems vars)

  end (* local *)

  fun reconstructMid alloc {liveOut, gcOut} next exp =
      case exp of
        START =>
        ({liveIn = liveOut, gcIn = gcOut}, next)
      | DEF {def, causeGC, prev} =>
        let
          val gcIn = updateGC_slot alloc (causeGC, def) gcOut
          val liveIn = Set.setMinus (liveOut, def)
        in
          reconstructMid
            alloc
            {liveOut = liveIn, gcOut = gcIn}
            (save alloc def o next)
            prev
        end
      | MID {def, use, orig, causeGC, prev} =>
        let
          val gcIn = updateGC_slot alloc (causeGC, def) gcOut
          val dead = Set.setMinus (use, liveOut)
          val liveIn = Set.union (Set.setMinus (liveOut, def), use)
        in
          reconstructMid
            alloc
            {liveOut = liveIn, gcOut = gcIn}
            (load alloc use
             o kill alloc gcIn dead
             o mid orig
             o save alloc def
             o next)
            prev
        end
      | LOCALCODE {recursive, binds, prev, loc} =>
        let
          val binds =
              map (fn {id, body} =>
                      let
                        val (argVarList, bodyExp) = reconstructBlock alloc body
                      in
                        {id = id,
                         argVarList = argVarList,
                         bodyExp = bodyExp ()}
                      end)
                  binds
        in
          reconstructMid
            alloc
            {liveOut = liveOut, gcOut = gcOut}
            (last (M.MCLOCALCODE {nextExp = next (),
                                  binds = binds,
                                  recursive = recursive,
                                  loc = loc}))
            prev
        end
      | HANDLER {id, exnVar, handler, cleanup, prev, loc} =>
        let
          val (_, handlerExp) = reconstructBlock alloc handler
        in
          reconstructMid
            alloc
            {liveOut = liveOut, gcOut = gcOut}
            (last (M.MCHANDLER {nextExp = next (),
                                id = id,
                                exnVar = exnVar,
                                handlerExp = handlerExp (),
                                cleanup = cleanup,
                                loc = loc}))
            prev
        end

  and reconstructExp alloc (out as {liveOut, gcOut}) exp =
      case exp of
        CALL {def, use, returnTo, causeGC, orig, prev} =>
        let
          val (_, exp) = reconstructBlock alloc returnTo
          val gcIn = updateGC_slot alloc (causeGC, def) gcOut
          val dead = Set.setMinus (use, liveOut)
          val liveIn = Set.union (Set.setMinus (liveOut, def), use)
        in
          reconstructMid
            alloc
            {liveOut = liveIn, gcOut = gcIn}
            (load alloc use
             o kill alloc gcIn dead
             o mid orig
             o save alloc def
             o exp)
            prev
        end
      | LAST {def, use, args, orig, prev} =>
        let
          val gcIn = gcOut
          val dead = Set.setMinus (use, liveOut)
          val liveIn = Set.union (Set.setMinus (liveOut, def), use)
        in
          reconstructMid
            alloc
            {liveOut = liveIn, gcOut = gcIn}
            (load alloc use
             o kill alloc gcOut dead
             o saveArgs alloc args
             o last orig)
            prev
        end

  and reconstructBlock alloc (BLOCK (ref {argVarList, bodyExp, predecessors,
                                          liveOut, gcOut, ...})) =
      let
        val output = {liveOut = liveOut, gcOut = toGC_slot alloc gcOut}
        val ({liveIn, gcIn}, body) = reconstructExp alloc output bodyExp
        val actualLiveIn =
            Set.merge
              (map (fn BLOCK (ref {liveOut, ...}) => liveOut) predecessors)
        val dead = Set.setMinus (actualLiveIn, liveIn)
      in
        (argVarList, kill alloc gcIn dead o body)
      end

  fun blocks (b as (BLOCK (ref {bodyExp, ...}))) r =
      blocksInExp bodyExp (b :: r)

  and blocksInMid exp r =
      case exp of
        START => r
      | DEF {def, causeGC, prev} => blocksInMid prev r
      | MID {def, use, orig, causeGC, prev} => blocksInMid prev r
      | LOCALCODE {recursive, binds, prev, loc} =>
        blocksInMid prev (foldl (fn (x, r) => blocks (#body x) r) r binds)
      | HANDLER {id, exnVar, handler, cleanup, prev, loc} =>
        blocksInMid prev (blocks handler r)

  and blocksInExp exp r =
      case exp of
        CALL {def, use, returnTo, causeGC, prev, orig} =>
        blocksInMid prev (blocks returnTo r)
      | LAST {def, use, args, orig, prev} =>
        blocksInMid prev r

  fun liveness nil = ()
    | liveness (BLOCK (r as ref {successors, predecessors, liveIn, gcIn,
                                 defuse = {defs, uses, gc}, done, ...})
                :: blocks) =
      let
        val _ = done := true
        val liveOut =
            Set.merge (map (fn BLOCK (ref {liveIn,...}) => liveIn) successors)
        val newLiveIn = Set.union (Set.setMinus (liveOut, defs), uses)
        val gcOut =
            case (List.mapPartial
                    (fn BLOCK (ref {gcIn, ...}) =>
                        case gcIn of
                          NOGC => NONE
                        | CAUSEGC {defsBeforeGC} => SOME defsBeforeGC)
                    successors) of
              nil => NOGC
            | defsBeforeGCs => CAUSEGC {defsBeforeGC = Set.merge defsBeforeGCs}
        val newGcIn =
            case (gc, gcOut) of
              (CAUSEGC {defsBeforeGC}, _) =>
              CAUSEGC {defsBeforeGC = Set.intersect (defsBeforeGC,
                                                     Set.toIdSet newLiveIn)}
            | (NOGC, NOGC) => NOGC
            | (NOGC, CAUSEGC {defsBeforeGC}) =>
              CAUSEGC {defsBeforeGC = Set.intersect
                                        (Set.union (defs, defsBeforeGC),
                                         Set.toIdSet newLiveIn)}
        val _ = r := (!r # {liveOut = liveOut, liveIn = newLiveIn,
                            gcOut = gcOut, gcIn = newGcIn})
        val blocks =
            if Set.isSubsetOf (newLiveIn, liveIn)
               andalso isSmallerThanOrEqualToGC (newGcIn, gcIn)
            then blocks
            else foldl
                   (fn (block as BLOCK (ref {done, ...}), z) =>
                       if !done then (done := false; block :: z) else z)
                   blocks
                   predecessors
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

  fun interferenceMid z exp =
      case exp of
        START => z
      | DEF {def, causeGC, prev} =>
        interferenceMid (interferenceStep z (def, Set.empty, causeGC)) prev
      | MID {def, use, orig, causeGC, prev} =>
        interferenceMid (interferenceStep z (def, use, causeGC)) prev
      | LOCALCODE {recursive, binds, prev, loc} =>
        interferenceMid z prev
      | HANDLER {id, exnVar, handler, cleanup, prev, loc} =>
        interferenceMid z prev

  fun interferenceExp z exp =
      case exp of
        CALL {def, use, returnTo, causeGC, orig, prev} =>
        interferenceMid (interferenceStep z (def, use, causeGC)) prev
      | LAST {def, use, args, orig, prev} =>
        interferenceMid (interferenceStep z (def, use, false)) prev

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

  fun varsToSlots alloc nil t = t : SlotID.Set.set
    | varsToSlots alloc ((h as {id, ...} : M.varInfo) :: slots) t =
      case VarID.Map.find (alloc, id) of
        SOME (ref (SOME id), _ : Set.set) =>
        varsToSlots alloc slots (SlotID.Set.add (t, id))
      | SOME (ref NONE, _) => varsToSlots alloc slots t
      | NONE => raise Bug.Bug "varsToSlots"

  fun allocSlot {interferences, gc} =
      let
        val gcset = Set.toIdSet gc
        val interferences = map (fn x => Set.intersect (x, gcset)) interferences
        val interferences = shrinkInterference interferences
        val interferences = foldl (fn (vars, z) => addInterferences z vars)
                                  VarID.Map.empty
                                  interferences
        val numSlots =
            VarID.Map.foldl (fn (x,z) => Int.max (Set.numItems x, z))
                            0 interferences
        val candidates = SlotSet.generate numSlots
        val alloc = VarID.Map.map (fn x => (ref NONE, x)) interferences
      in
        VarID.Map.map
          (fn (slot, adjVars) =>
              let
                val adjset = SlotID.Set.empty
                val adjset = varsToSlots alloc (Set.listItems adjVars) adjset
                val id = SlotSet.first
                           (fn id => not (SlotID.Set.member (adjset, id)))
                           candidates
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
        val blocks = blocks startBlock nil
        val () = liveness (exitBlock :: blocks)
      in
        case startBlock of
          BLOCK (ref {gcIn = NOGC, ...}) => (mcexp, SlotID.Map.empty)
        | BLOCK (ref {gcIn = CAUSEGC _, ...}) =>
          let
            val interference = interference blocks
            val alloc = allocSlot interference
(*
val _ =
(case startBlock of
   BLOCK (ref {id, ...}) => print ("start " ^ FunLocalLabel.toString id ^ "\n");
 case exitBlock of
   BLOCK (ref {id, ...}) => print ("exit " ^ FunLocalLabel.toString id ^ "\n");
 app (fn BLOCK (ref {id, gcIn, gcOut, ...}) =>
         (print (FunLocalLabel.toString id ^ " = ");
          case gcIn of
            NOGC => print "in:NOGC"
          | CAUSEGC {defsBeforeGC} =>
            (print "in:CAUSEGC ";
             app (fn id => print (SlotID.toString id ^ ","))
                 (List.mapPartial
                    (fn var => VarID.Map.find (alloc, #id var))
                    (Set.listItems defsBeforeGC)));
          print " ";
          case gcOut of
            NOGC => print "out:NOGC"
          | CAUSEGC {defsBeforeGC} =>
            (print "out:CAUSEGC ";
             app (fn id => print (SlotID.toString id ^ ","))
                 (List.mapPartial
                    (fn var => VarID.Map.find (alloc, #id var))
                    (Set.listItems defsBeforeGC)));
          print "\n"))
     blocks)
*)
            val (_, bodyExp) = reconstructBlock alloc startBlock
            val bodyExp = bodyExp ()

            val frameSlots =
                VarID.Map.foldli
                  (fn (_,id,z) => SlotID.Map.insert (z, id, R.boxedTy))
                  SlotID.Map.empty
                  alloc
          in
            (bodyExp, frameSlots)
          end
      end

  fun unionSlotMap (slots1, slots2) : R.ty SlotID.Map.map =
      SlotID.Map.unionWith
        (fn _ => raise Bug.Bug "unionSlotMap")
        (slots1, slots2)

  fun compileTopdec topdec =
      case topdec of
        M.MTFUNCTION {id, tyvarKindEnv, tyArgs, argVarList, closureEnvVar,
                      frameSlots, bodyExp, retTy, gcCheck, loc} =>
        let
          val params = optionToList closureEnvVar @ argVarList
(*
val _ = print (FunEntryLabel.toString id ^ ":\n")
*)
          val (bodyExp, slots) = compileFunc (params, bodyExp, NONE)
        in
          M.MTFUNCTION {id = id,
                        tyvarKindEnv = tyvarKindEnv,
                        tyArgs = tyArgs,
                        argVarList = argVarList,
                        closureEnvVar = closureEnvVar,
                        frameSlots = unionSlotMap (frameSlots, slots),
                        bodyExp = bodyExp,
                        retTy = retTy,
                        gcCheck = gcCheck,
                        loc = loc}
        end
      | M.MTCALLBACKFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
                              frameSlots, bodyExp, attributes, retTy,
                              cleanupHandler, loc} =>
        let
          val params = optionToList closureEnvVar @ argVarList
          val (bodyExp, slots) = compileFunc (params, bodyExp, cleanupHandler)
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

  fun compileToplevel {frameSlots, bodyExp, cleanupHandler} =
      let
        val (bodyExp, slots) = compileFunc (nil, bodyExp, cleanupHandler)
      in
        {frameSlots = unionSlotMap (frameSlots, slots),
         bodyExp = bodyExp,
         cleanupHandler = cleanupHandler} : M.toplevel
      end

  fun compile ({topdata, topdecs, toplevel}:M.program) =
      let
        val (topdecs, toplevel) = MachineCodeRename.rename (topdecs, toplevel)
      in
        {topdata = topdata,
         topdecs = map compileTopdec topdecs,
         toplevel = compileToplevel toplevel} : M.program
      end

end
