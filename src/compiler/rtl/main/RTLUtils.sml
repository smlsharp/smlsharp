(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure RTLUtils :> sig

  structure Var : sig
    type set
    type defuseSet = {defs: set, uses: set}
    val format_set : set SMLFormat.BasicFormatters.formatter
    val setUnion : set * set -> set
    val setMinus : set * set -> set
    val setIsSubset : set * set -> bool
    val emptySet : set
    val fold : (RTL.var * 'a -> 'a) -> 'a -> set -> 'a
    val app : (RTL.var -> unit) -> set -> unit
    val filter : (RTL.var -> bool) -> set -> set
    val inDomain : set * RTL.id -> bool
    val find : set * RTL.id -> RTL.var option
    val isEmpty : set -> bool
    val fromList : RTL.var list -> set
    val toVarIDSet : set -> VarID.Set.set
    val singleton : RTL.var -> set
    val defuseFirst : RTL.first -> defuseSet
    val defuseInsn : RTL.instruction -> defuseSet
    val defuseLast : RTL.last -> defuseSet
    val defuse : RTLEdit.node -> defuseSet
    val clobsFirst : RTL.first -> set
    val clobsInsn : RTL.instruction -> set
    val clobsLast : RTL.last -> set
    val clobs : RTLEdit.node -> set
  end

  structure Slot : sig
    type set
    type defuseSet = {defs: set, uses: set}
    val format_set : set SMLFormat.BasicFormatters.formatter
    val setUnion : set * set -> set
    val setMinus : set * set -> set
    val setIsSubset : set * set -> bool
    val emptySet : set
    val fold : (RTL.slot * 'a -> 'a) -> 'a -> set -> 'a
    val app : (RTL.slot -> unit) -> set -> unit
    val filter : (RTL.slot -> bool) -> set -> set
    val inDomain : set * RTL.id -> bool
    val find : set * RTL.id -> RTL.slot option
    val isEmpty : set -> bool
    val fromList : RTL.slot list -> set
    val toVarIDSet : set -> VarID.Set.set
    val singleton : RTL.slot -> set
    val defuseFirst : RTL.first -> defuseSet
    val defuseInsn : RTL.instruction -> defuseSet
    val defuseLast : RTL.last -> defuseSet
    val defuse : RTLEdit.node -> defuseSet
  end

  val labelPtrTy : RTL.labelReference -> RTL.ptrTy
  val labelTy : RTL.labelReference -> RTL.ty
  val constTy : RTL.const -> RTL.ty
  val addrTy : RTL.addr -> RTL.ptrTy
  val dstTy : RTL.dst -> RTL.ty
  val operandTy : RTL.operand -> RTL.ty

  val handlerLabels : RTL.handler -> RTL.label list
  (* nil means exit *)
  val successors : RTL.last -> RTL.label list

  val edges : RTL.graph
              -> {succs: RTL.label list, preds: RTL.label list}
                 RTLEdit.annotatedGraph
  val preorder : RTL.graph -> RTL.label list
  val postorder : RTL.graph -> RTL.label list

  type 'a analysis =
      {
        init: 'a,
        join: 'a * 'a -> 'a,
        pass: RTLEdit.node * 'a -> 'a,
        filterIn: RTL.label * 'a -> 'a,
        filterOut: RTL.label * 'a -> 'a,
        changed: {old:'a, new:'a} -> bool
      }

  type 'a answer =
      {
        answerIn: 'a,
        answerOut: 'a,
        succs: RTL.label list,
        preds: RTL.label list
      }

  val format_answer : 'a SMLFormat.BasicFormatters.formatter
                      -> 'a answer SMLFormat.BasicFormatters.formatter

  val analyzeFlowBackward :
      'a analysis -> RTL.graph -> 'a answer RTLEdit.annotatedGraph
  val analyzeFlowForward :
      'a analysis -> RTL.graph -> 'a answer RTLEdit.annotatedGraph

  val mapCluster : (RTL.graph -> RTL.graph)
                   -> RTL.program -> RTL.program

end =
struct
fun puts s = print (s ^ "\n")
fun putfs s = print (Control.prettyPrint s ^ "\n")

  structure I = RTL
  open RTL

  infix ++

  type 'a set = 'a VarID.Map.map
  type 'a defuseSet = {defs: 'a set, uses: 'a set}
  val emptySet = VarID.Map.empty : 'a set

  local
    open SMLFormat.BasicFormatters
  in
  fun format_set fmt set =
      format_string "{" @
      format_list
        (fn (x,y) => VarID.format_id x @ format_string ":" @ fmt y,
         format_string ",")
        (VarID.Map.listItemsi set) @
      format_string "}"
  end

  fun setUnion (set1:''a set, set2:''a set) : ''a set =
      VarID.Map.unionWith
        (fn (x,y) => if x = y then x else raise Control.Bug "union")
        (set1, set2)

  fun setMinus (set1:'a set, set2:'a set) : 'a set =
      VarID.Map.filteri
        (fn (id, _) => not (VarID.Map.inDomain (set2, id)))
        set1

  fun setIsSubset (set1:'a set, set2:'a set) =
      VarID.Map.foldli
        (fn (id, _, b) => b andalso VarID.Map.inDomain (set2, id))
        true
        set1

  fun singleton f (v:'a) =
      VarID.Map.singleton (f v, v) : 'a set

  fun varSet vars =
      foldl (fn (var as {id,...}:I.var, set) =>
                VarID.Map.insert (set, id, var))
            emptySet vars

  fun slotSet slots =
      foldl (fn (slot as {id,...}:I.slot, set) =>
                VarID.Map.insert (set, id, slot))
            emptySet slots

  fun idSet set =
      VarID.Map.foldli (fn (i,_,z) => VarID.Set.add (z, i)) VarID.Set.empty set

  fun ({defs=d1, uses=u1}:''a defuseSet) ++ ({defs=d2, uses=u2}:''a defuseSet) =
      {defs = setUnion (d1, d2), uses = setUnion (u1, u2)} : ''a defuseSet

  val duEmpty =
      {defs = emptySet, uses = emptySet} : 'a defuseSet
  fun useSet set =
      {defs = emptySet, uses = set} : 'a defuseSet
  fun defSet set =
      {defs = set, uses = emptySet} : 'a defuseSet
  fun useAll ({defs, uses}:''a defuseSet) =
      {defs = emptySet, uses = setUnion (defs, uses)} : ''a defuseSet

  fun duAddr varSet addr =
      case addr of
        I.ADDRCAST (_, addr) => duAddr varSet addr
      | I.ABSADDR _ => duEmpty
      | I.DISP (const, addr) => duAddr varSet addr
      | I.BASE var => useSet (varSet [var])
      | I.ABSINDEX {base, scale, index} => useSet (varSet [index])
      | I.BASEINDEX {base, scale, index} => (useSet (varSet [base, index]))
      | I.POSTFRAME {offset, size} => duEmpty
      | I.PREFRAME {offset, size} => duEmpty
      | I.WORKFRAME slot => duEmpty
      | I.FRAMEINFO offset => duEmpty

  fun duMem varSet (I.ADDR addr) = duAddr varSet addr
    | duMem varSet (I.SLOT _) = duEmpty

  fun duDstVar (I.REG var) = defSet (singleton #id var)
    | duDstVar (I.COUPLE (_, {hi,lo})) = duDstVar hi ++ duDstVar lo
    | duDstVar (I.MEM (_, mem)) = duMem varSet mem

  fun duDstSlot (I.REG var) = duEmpty
    | duDstSlot (I.COUPLE (_, {hi,lo})) = duDstSlot hi ++ duDstSlot lo
    | duDstSlot (I.MEM (_, I.SLOT slot)) = defSet (singleton #id slot)
    | duDstSlot (I.MEM (_, I.ADDR addr)) = duEmpty

  fun duOp duDst (I.CONST _) = duEmpty
    | duOp duDst (I.REF (_, dst)) = useAll (duDst dst)

  fun defuseInsn (func as {varSet, slotSet, duDst}) insn =
      let
        val duOp = duOp duDst
        val duAddr = duAddr varSet
      in
        case insn of
          I.NOP => duEmpty
        | I.STABILIZE => duEmpty
        | I.REQUEST_SLOT slot => defSet (slotSet [slot])
        | I.REQUIRE_SLOT slot => useSet (slotSet [slot])
        | I.USE ops => foldr (fn (x,z) => duOp x ++ z) duEmpty ops
        | I.COMPUTE_FRAME {uses, clobs} =>
          useSet (varSet (VarID.Map.listItems uses))
        | I.MOVE (ty, dst, op1) => duDst dst ++ duOp op1
        | I.MOVEADDR (ty, dst, addr) => duDst dst ++ duAddr addr
        | I.COPY {ty, dst:I.dst, src:I.operand, clobs} => duDst dst ++ duOp src
        | I.MLOAD {ty, dst:I.slot, srcAddr, size, defs, clobs} =>
          defSet (slotSet [dst]) ++ defSet (varSet defs)
          ++ duAddr srcAddr ++ duOp size
        | I.MSTORE {ty, dstAddr, src:I.slot, size, defs, clobs, global} =>
          useSet (slotSet [src]) ++ defSet (varSet defs)
          ++ duAddr dstAddr ++ duOp size
        | I.EXT8TO32 (_, dst, op1) => duDst dst ++ duOp op1
        | I.EXT16TO32 (_, dst, op1) => duDst dst ++ duOp op1
        | I.EXT32TO64 (_, dst, op1) => duDst dst ++ duOp op1
        | I.DOWN32TO8 (_, dst, op1) => duDst dst ++ duOp op1
        | I.DOWN32TO16 (_, dst, op1) => duDst dst ++ duOp op1
        | I.ADD (ty, dst, op1, op2) => duDst dst ++ duOp op1 ++ duOp op2
        | I.SUB (ty, dst, op1, op2) => duDst dst ++ duOp op1 ++ duOp op2
        | I.MUL ((_,dst), (_,op1), (_,op2)) => duDst dst ++ duOp op1 ++ duOp op2
        | I.DIVMOD ({div=(_,ddiv), mod=(_,dmod)}, (_,op1), (_,op2)) =>
          duDst ddiv ++ duDst dmod ++ duOp op1 ++ duOp op2
        | I.AND (ty, dst, op1, op2) => duDst dst ++ duOp op1 ++ duOp op2
        | I.OR (ty, dst, op1, op2) => duDst dst ++ duOp op1 ++ duOp op2
        | I.XOR (ty, dst, op1, op2) => duDst dst ++ duOp op1 ++ duOp op2
        | I.LSHIFT (ty, dst, op1, op2) => duDst dst ++ duOp op1 ++ duOp op2
        | I.RSHIFT (ty, dst, op1, op2) => duDst dst ++ duOp op1 ++ duOp op2
        | I.ARSHIFT (ty, dst, op1, op2) => duDst dst ++ duOp op1 ++ duOp op2
        | I.TEST_SUB (_, op1, op2) => duOp op1 ++ duOp op2
        | I.TEST_AND (_, op1, op2) => duOp op1 ++ duOp op2
        | I.TEST_LABEL (_, op1, l) => duOp op1
        | I.NOT (ty, dst, op1) => duDst dst ++ duOp op1
        | I.NEG (ty, dst, op1) => duDst dst ++ duOp op1
        | I.SET (cc1, ty, dst, {test}) =>
          duDst dst ++ defuseInsn func test
        | I.LOAD_FP dst => duDst dst
        | I.LOAD_SP dst => duDst dst
        | I.LOAD_PREV_FP dst => duDst dst
        | I.LOAD_RETADDR dst => duDst dst
(*
        | I.SAVE_FP op1 => duOp op1
        | I.SAVE_SP op1 => duOp op1
*)
        | I.LOADABSADDR {ty, dst, symbol, thunk} => duDst dst
        | I.X86 (I.X86LEAINT (ty, dst, {base, shift, offset, disp})) =>
          duDst dst ++ useSet (varSet [base, offset])
(*
        | I.X86 (I.X86HI8OF16 (_, dst, op1)) => duDst dst ++ duOp op1
*)
        | I.X86 (I.X86FLD (ty, mem)) => duOp (I.REF_ (I.MEM (ty, mem)))
        | I.X86 (I.X86FLD_ST st) => duEmpty
        | I.X86 (I.X86FST (ty, mem)) => duDst (I.MEM (ty, mem))
        | I.X86 (I.X86FSTP (ty, mem)) => duDst (I.MEM (ty, mem))
        | I.X86 (I.X86FSTP_ST st) => duEmpty
        | I.X86 (I.X86FADD (ty, mem)) => duOp (I.REF_ (I.MEM (ty, mem)))
        | I.X86 (I.X86FADD_ST (st1, st2)) => duEmpty
        | I.X86 (I.X86FADDP st1) => duEmpty
        | I.X86 (I.X86FSUB (ty, mem)) => duOp (I.REF_ (I.MEM (ty, mem)))
        | I.X86 (I.X86FSUB_ST (st1, st2)) => duEmpty
        | I.X86 (I.X86FSUBP st1) => duEmpty
        | I.X86 (I.X86FSUBR (ty, mem)) => duOp (I.REF_ (I.MEM (ty, mem)))
        | I.X86 (I.X86FSUBR_ST (st1, st2)) => duEmpty
        | I.X86 (I.X86FSUBRP st1) => duEmpty
        | I.X86 (I.X86FMUL (ty, mem)) => duOp (I.REF_ (I.MEM (ty, mem)))
        | I.X86 (I.X86FMUL_ST (st1, st2)) => duEmpty
        | I.X86 (I.X86FMULP st1) => duEmpty
        | I.X86 (I.X86FDIV (ty, mem)) => duOp (I.REF_ (I.MEM (ty, mem)))
        | I.X86 (I.X86FDIV_ST (st1, st2)) => duEmpty
        | I.X86 (I.X86FDIVP st1) => duEmpty
        | I.X86 (I.X86FDIVR (ty, mem)) => duOp (I.REF_ (I.MEM (ty, mem)))
        | I.X86 (I.X86FDIVR_ST (st1, st2)) => duEmpty
        | I.X86 (I.X86FDIVRP st1) => duEmpty
        | I.X86 (I.X86FPREM) => duEmpty
        | I.X86 (I.X86FABS) => duEmpty
        | I.X86 (I.X86FCHS) => duEmpty
        | I.X86 I.X86FINCSTP => duEmpty
        | I.X86 (I.X86FFREE st) => duEmpty
        | I.X86 (I.X86FXCH st) => duEmpty
        | I.X86 (I.X86FUCOM st) => duEmpty
        | I.X86 (I.X86FUCOMP st) => duEmpty
        | I.X86 I.X86FUCOMPP => duEmpty
(*
        | I.X86 (I.X86FSTSW (dst, insn)) =>
          defuseInsn varSet duDst insn ++ duDst dst
*)
        | I.X86 (I.X86FSW_TESTH {clob,mask}) => duEmpty
        | I.X86 (I.X86FSW_MASKCMPH {clob,mask,compare}) => duEmpty
        | I.X86 (I.X86FLDCW mem) => duOp (I.REF_ (I.MEM (I.Int16 I.U, mem)))
        | I.X86 (I.X86FNSTCW mem) => duDst (I.MEM (I.Int16 I.U, mem))
        | I.X86 I.X86FWAIT => duEmpty
        | I.X86 I.X86FNCLEX => duEmpty
      end

  fun defuseLast (func as {varSet, slotSet, duDst}) insn =
      let
        val defuseInsn = defuseInsn func
        val duOp = duOp duDst
        val duAddr = duAddr varSet
      in
        case insn of
          I.HANDLE (insn, _) => defuseInsn insn
        | I.CJUMP {test, cc, thenLabel, elseLabel} => defuseInsn test
        | I.CALL {callTo, returnTo, handler, defs, uses,
                  needStabilize, postFrameAdjust} =>
          {defs = varSet defs, uses = varSet uses} ++ duAddr callTo
        | I.JUMP {jumpTo, destinations} => duAddr jumpTo
        | I.UNWIND_JUMP {jumpTo, sp, fp, uses, handler} =>
          useSet (varSet uses) ++ duOp sp ++ duOp fp ++ duAddr jumpTo
        | I.TAILCALL_JUMP {preFrameSize, jumpTo, uses} =>
          useSet (varSet uses) ++ duAddr jumpTo
        | I.RETURN {preFrameSize, stubOptions, uses} =>
          useSet (varSet uses)
        | I.EXIT => duEmpty
      end

  fun defuseFirst varSet insn =
      case insn of
        I.BEGIN {label, align, loc} => duEmpty
      | I.CODEENTRY {label, symbol, scope, align, preFrameSize,
                     stubOptions, defs, loc} =>
        defSet (varSet defs)
      | I.HANDLERENTRY {label, align, defs, loc} => defSet (varSet defs)
      | I.ENTER => duEmpty

  fun clobsInsn insn =
      case insn of
        I.NOP => emptySet
      | I.STABILIZE => emptySet
      | I.REQUEST_SLOT slot => emptySet
      | I.REQUIRE_SLOT slot => emptySet
      | I.USE ops => emptySet
      | I.COMPUTE_FRAME {uses, clobs} => varSet clobs
      | I.MOVE (ty, dst, op1) => emptySet
      | I.MOVEADDR (ty, dst, addr) => emptySet
      | I.COPY {ty, dst:I.dst, src:I.operand, clobs} => varSet clobs
      | I.MLOAD {ty, dst:I.slot, srcAddr, size, defs, clobs} => varSet clobs
      | I.MSTORE {ty, dstAddr, src:I.slot, size, defs, clobs, global} =>
        varSet clobs
      | I.EXT8TO32 (_, dst, op1) => emptySet
      | I.EXT16TO32 (_, dst, op1) => emptySet
      | I.EXT32TO64 (_, dst, op1) => emptySet
      | I.DOWN32TO8 (_, dst, op1) => emptySet
      | I.DOWN32TO16 (_, dst, op1) => emptySet
      | I.ADD (ty, dst, op1, op2) => emptySet
      | I.SUB (ty, dst, op1, op2) => emptySet
      | I.MUL ((_,dst), (_,op1), (_,op2)) => emptySet
      | I.DIVMOD ({div=(_,ddiv), mod=(_,dmod)}, (_,op1), (_,op2)) => emptySet
      | I.AND (ty, dst, op1, op2) => emptySet
      | I.OR (ty, dst, op1, op2) => emptySet
      | I.XOR (ty, dst, op1, op2) => emptySet
      | I.LSHIFT (ty, dst, op1, op2) => emptySet
      | I.RSHIFT (ty, dst, op1, op2) => emptySet
      | I.ARSHIFT (ty, dst, op1, op2) => emptySet
      | I.TEST_SUB (_, op1, op2) => emptySet
      | I.TEST_AND (_, op1, op2) => emptySet
      | I.TEST_LABEL (_, op1, l) => emptySet
      | I.NOT (ty, dst, op1) => emptySet
      | I.NEG (ty, dst, op1) => emptySet
      | I.SET (cc1, ty, dst, {test}) => clobsInsn test
      | I.LOAD_FP dst => emptySet
      | I.LOAD_SP dst => emptySet
      | I.LOAD_PREV_FP dst => emptySet
      | I.LOAD_RETADDR dst => emptySet
      | I.LOADABSADDR {ty, dst, symbol, thunk} => emptySet
      | I.X86 (I.X86LEAINT (ty, dst, {base, shift, offset, disp})) => emptySet
      | I.X86 (I.X86FLD (ty, mem)) => emptySet
      | I.X86 (I.X86FLD_ST st) => emptySet
      | I.X86 (I.X86FST (ty, mem)) => emptySet
      | I.X86 (I.X86FSTP (ty, mem)) => emptySet
      | I.X86 (I.X86FSTP_ST st) => emptySet
      | I.X86 (I.X86FADD (ty, mem)) => emptySet
      | I.X86 (I.X86FADD_ST (st1, st2)) => emptySet
      | I.X86 (I.X86FADDP st1) => emptySet
      | I.X86 (I.X86FSUB (ty, mem)) => emptySet
      | I.X86 (I.X86FSUB_ST (st1, st2)) => emptySet
      | I.X86 (I.X86FSUBP st1) => emptySet
      | I.X86 (I.X86FSUBR (ty, mem)) => emptySet
      | I.X86 (I.X86FSUBR_ST (st1, st2)) => emptySet
      | I.X86 (I.X86FSUBRP st1) => emptySet
      | I.X86 (I.X86FMUL (ty, mem)) => emptySet
      | I.X86 (I.X86FMUL_ST (st1, st2)) => emptySet
      | I.X86 (I.X86FMULP st1) => emptySet
      | I.X86 (I.X86FDIV (ty, mem)) => emptySet
      | I.X86 (I.X86FDIV_ST (st1, st2)) => emptySet
      | I.X86 (I.X86FDIVP st1) => emptySet
      | I.X86 (I.X86FDIVR (ty, mem)) => emptySet
      | I.X86 (I.X86FDIVR_ST (st1, st2)) => emptySet
      | I.X86 (I.X86FDIVRP st1) => emptySet
      | I.X86 (I.X86FPREM) => emptySet
      | I.X86 (I.X86FABS) => emptySet
      | I.X86 (I.X86FCHS) => emptySet
      | I.X86 I.X86FINCSTP => emptySet
      | I.X86 (I.X86FFREE st) => emptySet
      | I.X86 (I.X86FXCH st) => emptySet
      | I.X86 (I.X86FUCOM st) => emptySet
      | I.X86 (I.X86FUCOMP st) => emptySet
      | I.X86 I.X86FUCOMPP => emptySet
      | I.X86 (I.X86FSW_TESTH {clob,mask}) => varSet [clob]
      | I.X86 (I.X86FSW_MASKCMPH {clob,mask,compare}) => varSet [clob]
      | I.X86 (I.X86FLDCW mem) => emptySet
      | I.X86 (I.X86FNSTCW mem) => emptySet
      | I.X86 I.X86FWAIT => emptySet
      | I.X86 I.X86FNCLEX => emptySet

  fun clobsLast insn =
      case insn of
        I.HANDLE (insn, _) => clobsInsn insn
      | I.CJUMP {test, cc, thenLabel, elseLabel} => clobsInsn test
      | I.CALL {callTo, returnTo, handler, defs, uses,
                needStabilize, postFrameAdjust} => emptySet
      | I.JUMP {jumpTo, destinations} => emptySet
      | I.UNWIND_JUMP {jumpTo, sp, fp, uses, handler} => emptySet
      | I.TAILCALL_JUMP {preFrameSize, jumpTo, uses} => emptySet
      | I.RETURN {preFrameSize, stubOptions, uses} => emptySet
      | I.EXIT => emptySet

  fun clobsFirst insn =
      case insn of
        I.BEGIN {label, align, loc} => emptySet
      | I.CODEENTRY {label, symbol, scope, align, preFrameSize,
                     stubOptions, defs, loc} => emptySet
      | I.HANDLERENTRY {label, align, defs, loc} => emptySet
      | I.ENTER => emptySet

  structure Var =
  struct
    type set = I.var set
    type defuseSet = I.var defuseSet
    val format_set = format_set I.format_var
    val setUnion = setUnion : set * set -> set
    val setMinus = setMinus : set * set -> set
    val setIsSubset = setIsSubset : set * set -> bool
    val fold = VarID.Map.foldl
    val app = VarID.Map.app
    val filter = VarID.Map.filter
    val inDomain = VarID.Map.inDomain
    val find = VarID.Map.find
    val isEmpty = VarID.Map.isEmpty
    val emptySet = emptySet : set
    val singleton = fn x => singleton #id x : set
    val fromList = varSet
    val toVarIDSet = idSet
    fun slotSet (v:I.slot list) = emptySet
    val func = {varSet=varSet, slotSet=slotSet, duDst=duDstVar}
    val defuseFirst = fn x => defuseFirst varSet x
    val defuseInsn = fn x => defuseInsn func x
    val defuseLast = fn x => defuseLast func x
    fun defuse (RTLEdit.FIRST first) = defuseFirst first
      | defuse (RTLEdit.MIDDLE insn) = defuseInsn insn
      | defuse (RTLEdit.LAST last) = defuseLast last
    val clobsFirst = clobsFirst
    val clobsInsn = clobsInsn
    val clobsLast = clobsLast
    fun clobs (RTLEdit.FIRST first) = clobsFirst first
      | clobs (RTLEdit.MIDDLE insn) = clobsInsn insn
      | clobs (RTLEdit.LAST last) = clobsLast last
  end

  structure Slot =
  struct
    type set = I.slot set
    type defuseSet = I.slot defuseSet
    val format_set = format_set I.format_slot
    val setUnion = setUnion : set * set -> set
    val setMinus = setMinus : set * set -> set
    val setIsSubset = setIsSubset : set * set -> bool
    val fold = VarID.Map.foldl
    val app = VarID.Map.app
    val filter = VarID.Map.filter
    val inDomain = VarID.Map.inDomain
    val find = VarID.Map.find
    val isEmpty = VarID.Map.isEmpty
    val emptySet = emptySet : set
    val singleton = fn x => singleton #id x : set
    val fromList = slotSet
    val toVarIDSet = idSet
    fun varSet (v:I.var list) = emptySet
    val func = {varSet=varSet, slotSet=slotSet, duDst=duDstSlot}
    val defuseFirst = fn x => defuseFirst varSet x
    val defuseInsn = fn x => defuseInsn func x
    val defuseLast = fn x => defuseLast func x
    fun defuse (RTLEdit.FIRST first) = defuseFirst first
      | defuse (RTLEdit.MIDDLE insn) = defuseInsn insn
      | defuse (RTLEdit.LAST last) = defuseLast last
  end

  (********************************)


  fun labelPtrTy label =
      case label of
        I.LABEL _ => I.Code
      | I.SYMBOL (ptrTy,_,_) => ptrTy
      | I.CURRENT_POSITION => I.Code
      | I.LINK_ENTRY _ => I.Void
      | I.LINK_STUB _ => I.Code
      | I.ELF_GOT => I.Void
      | I.NULL ptrTy => ptrTy
      | I.LABELCAST (ptrTy, _) => ptrTy

  fun labelTy label =
      I.Ptr (labelPtrTy label)

  fun constTy const =
      case const of
        I.SYMOFFSET {base, label} => I.PtrDiff (labelPtrTy label)
(*
      | I.INT64 _ => I.Int64 I.S
      | I.UINT64 _ => I.Int64 I.U
*)
      | I.INT32 _ => I.Int32 I.S
      | I.UINT32 _ => I.Int32 I.U
      | I.INT16 _ => I.Int16 I.S
      | I.UINT16 _ => I.Int16 I.U
      | I.INT8 _ => I.Int8 I.S
      | I.UINT8 _ => I.Int8 I.U
      | I.REAL32 _ => I.Real32
      | I.REAL64 _ => I.Real64
      | I.REAL64HI _ => I.NoType
      | I.REAL64LO _ => I.NoType

  fun addrTy addr =
      case addr of
        I.ADDRCAST (ptrTy, _) => ptrTy
      | I.ABSADDR label => labelPtrTy label
      | I.DISP (_, addr) =>
        (
          case addrTy addr of
            I.Data => I.Void
          | I.Code => I.Code
          | I.Void => I.Void
        )
      | I.BASE {id, ty=I.Ptr ptrTy} => ptrTy
      | I.BASE _ => raise Control.Bug "addrTy: BASE"
      | ABSINDEX {base, index, scale} =>
        (
          case labelPtrTy base of
            I.Data => I.Void
          | I.Code => I.Code
          | I.Void => I.Void
        )
      | BASEINDEX {base={id,ty=I.Ptr ptrTy}, index, scale} =>
        (
          case ptrTy of
            I.Data => I.Void
          | I.Code => I.Code
          | I.Void => I.Void
        )
      | BASEINDEX {base, index, scale} => raise Control.Bug "addrTy: BASEINDEX"
      | POSTFRAME {offset, size} => I.Void
      | PREFRAME {offset, size} => I.Void
      | WORKFRAME _ => I.Void
      | FRAMEINFO _ => I.Void

  fun dstTy dst =
      case dst of
        I.REG {id, ty} => ty
      | I.MEM (ty, _) => ty
      | I.COUPLE (ty, _) => ty

  fun operandTy operand =
      case operand of
        I.CONST c => constTy c
      | I.REF (I.N, dst) => dstTy dst
      | I.REF (I.CAST ty, _) => ty

  (********************************)

  fun handlerLabels I.NO_HANDLER = nil
    | handlerLabels (I.HANDLER {handlers, ...}) = handlers

  fun successors last =
      case last of
        I.HANDLE (_, {nextLabel, handler}) =>
        nextLabel :: handlerLabels handler
      | I.CJUMP {test, cc, thenLabel, elseLabel} => [thenLabel, elseLabel]
      | I.CALL {callTo, returnTo, handler, defs, uses, needStabilize,
                postFrameAdjust} =>
        returnTo :: handlerLabels handler
      | I.JUMP {jumpTo, destinations} => destinations
      | I.UNWIND_JUMP {jumpTo, fp, sp, uses, handler} => handlerLabels handler
      | I.TAILCALL_JUMP {preFrameSize, jumpTo, uses} => nil
      | I.RETURN {preFrameSize, stubOptions, uses} => nil
      | I.EXIT => nil

  fun format_labelList labels =
      SMLFormat.BasicFormatters.format_list
        (I.format_label, SMLFormat.BasicFormatters.format_string ",")
        labels

  fun format_edges {succs, preds} =
      SMLFormat.BasicFormatters.format_string "succs: " @
      format_labelList succs @
      [SMLFormat.FormatExpression.Newline] @
      SMLFormat.BasicFormatters.format_string "preds: " @
      format_labelList preds

  fun edges graph =
      I.LabelMap.foldli
        (fn (label, (_, _, last), graph) =>
            case successors last of
              nil => graph
            | succs =>
              let
                val focus = RTLEdit.focusBlock (graph, label)
                val {preds, ...} = RTLEdit.annotation focus
                val ann = {succs = succs, preds = preds}
                val focus = RTLEdit.setAnnotation (focus, ann)
                val graph = RTLEdit.unfocusBlock focus
              in
                foldl (fn (to, graph) =>
                          let
                            val focus = RTLEdit.focusBlock (graph, to)
                            val {preds, succs} = RTLEdit.annotation focus
                            val ann = {succs = succs, preds = label::preds}
                            val focus = RTLEdit.setAnnotation (focus, ann)
                          in
                            RTLEdit.unfocusBlock focus
                          end)
                      graph
                      succs
              end)
        (RTLEdit.annotate (graph, {succs=nil, preds=nil}))
        graph

  local
    fun entries (graph:I.graph) =
        I.LabelMap.foldri
          (fn (l, (I.CODEENTRY _, _, _), z) => l::z
            | (l, (I.ENTER, _, _), z) => l::z
            | (l, (I.HANDLERENTRY _, _, _), z) => z
            | (l, (I.BEGIN _, _, _), z) => z)
          nil
          graph

    fun succ (graph:I.graph, label) =
        case I.LabelMap.find (graph, label) of
          SOME (_,_,l) => successors l
        | NONE => raise Control.Bug ("preorder: "
                                     ^ Control.prettyPrint (I.format_label label))
  in

  fun postorder graph =
      let
        fun visit (visited, nil, l) = l
          | visit (visited, h::t, l) =
            if I.LabelSet.member (visited, h)
            then visit (visited, t, l)
            else visit (I.LabelSet.add (visited, h), succ (graph, h) @ t, h::l)
      in
        visit (I.LabelSet.empty, entries graph, nil)
      end

  fun preorder graph =
      rev (postorder graph)

  end (* local *)

  (********************************)

  type 'a analysis =
      {
        init: 'a,
        join: 'a * 'a -> 'a,
        pass: RTLEdit.node * 'a -> 'a,
        filterIn: RTL.label * 'a -> 'a,
        filterOut: RTL.label * 'a -> 'a,
        changed: {old:'a, new:'a} -> bool
      }

  type 'a answer =
      {
        succs: RTL.label list,
        preds: RTL.label list,
        answerIn: 'a,
        answerOut: 'a
      }

  local
    open SMLFormat.BasicFormatters
    open SMLFormat.FormatExpression
    fun format_labelList labels =
        format_list (I.format_label, format_string ",") labels
  in
  fun format_answer fmt {succs, preds, answerIn, answerOut} =
      format_string "succs: " @ format_labelList succs @ [Newline] @
      format_string "preds: " @ format_labelList preds @ [Newline] @
      format_string "answerIn: " @ [Guard (NONE, fmt answerIn)] @ [Newline] @
      format_string "answerOut: " @ [Guard (NONE, fmt answerOut)]
  end

  fun answerInOf (graph:'a answer RTLEdit.annotatedGraph, label) =
      #answerIn (RTLEdit.annotation (RTLEdit.focusBlock (graph, label)))
  fun answerOutOf (graph:'a answer RTLEdit.annotatedGraph, label) =
      #answerOut (RTLEdit.annotation (RTLEdit.focusBlock (graph, label)))

  local
    type set = I.label list * I.LabelSet.set

    fun initSet l = (l, I.LabelSet.fromList l) : set
    fun enqueue (q, l2) =
        foldl (fn (l,(l1,set)) =>
                  if I.LabelSet.member (set, l) then (l1,set)
                  else (l::l1, I.LabelSet.add (set, l)))
              q
              l2
    fun dequeue ((h::t, set):set) =
        SOME (h, (t, I.LabelSet.delete (set, h)):set)
      | dequeue (nil, set) =
            case I.LabelSet.listItems set of
              nil => NONE
            | h::t => SOME (h, (t, I.LabelSet.delete (set, h)):set)
  in

  fun analyzeFlowBackward ({init, join, pass, filterIn, filterOut,
                            changed}:'a analysis)
                          graph =
      let
        val workSet = initSet (postorder graph)
        val graph = edges graph
        val graph = RTLEdit.map (fn {succs, preds} =>
                                    {succs = succs,
                                     preds = preds,
                                     answerIn = init,
                                     answerOut = init})
                                graph

        fun loop (workSet, graph) =
            case dequeue workSet of
              NONE => graph
            | SOME (label, workSet) =>
              let
              val focus = RTLEdit.focusBlock (graph, label)
              val {preds, succs, answerIn, answerOut} = RTLEdit.annotation focus
              val newOut =
                  foldl (fn (l, out) => join (out, answerInOf (graph, l)))
                        answerOut succs
              val newOut = filterOut (label, newOut)
              val newIn = RTLEdit.foldBackward pass newOut focus
              val newIn = filterIn (label, newIn)
              val workSet =
                  if changed {old=answerIn, new=newIn}
                  then enqueue (workSet, preds)
                  else workSet
              val focus = RTLEdit.setAnnotation (focus, {preds = preds,
                                                         succs = succs,
                                                         answerIn = newIn,
                                                         answerOut = newOut})
            in
              loop (workSet, RTLEdit.unfocusBlock focus)
            end
      in
        loop (workSet, graph)
      end
        
  fun analyzeFlowForward ({init, join, pass, filterIn, filterOut,
                           changed}:'a analysis)
                         graph =
      let
        val workSet = initSet (preorder graph)
        val graph = edges graph
        val graph = RTLEdit.map (fn {succs, preds} =>
                                    {succs = succs,
                                     preds = preds,
                                     answerIn = init,
                                     answerOut = init})
                                graph

        fun loop (workSet, graph) =
            case dequeue workSet of
              NONE => graph
            | SOME (label, workSet) =>
              let
              val focus = RTLEdit.focusBlock (graph, label)
              val {preds, succs, answerIn, answerOut} = RTLEdit.annotation focus
              val newIn =
                  foldl (fn (l, ansIn) => join (ansIn, answerOutOf (graph, l)))
                        answerIn preds
              val newIn = filterIn (label, newIn)
              val newOut = RTLEdit.foldForward pass newIn focus
              val newOut = filterOut (label, newOut)

              val workSet =
                  if changed {old=answerOut, new=newOut}
                  then enqueue (workSet, succs)
                  else workSet
              val focus = RTLEdit.setAnnotation (focus, {preds = preds,
                                                         succs = succs,
                                                         answerIn = newIn,
                                                         answerOut = newOut})
            in
              loop (workSet, RTLEdit.unfocusBlock focus)
            end
      in
        loop (workSet, graph)
      end

  end (* local *)

  fun mapCluster f topdecls =
      map (fn I.CLUSTER {clusterId, frameBitmap, baseLabel, body,
                         preFrameSize, postFrameSize, numHeaderWords, loc} =>
              I.CLUSTER {clusterId = clusterId,
                         frameBitmap = frameBitmap,
                         baseLabel = baseLabel,
                         body = f body,
                         preFrameSize = preFrameSize,
                         postFrameSize = postFrameSize,
                         numHeaderWords = numHeaderWords,
                         loc = loc}
            | x as I.TOPLEVEL _ => x
            | x as I.DATA _ => x
            | x as I.BSS _ => x
            | x as I.X86GET_PC_THUNK_BX _ => x
            | x as I.EXTERN _ => x)
      topdecls
                                 
end
