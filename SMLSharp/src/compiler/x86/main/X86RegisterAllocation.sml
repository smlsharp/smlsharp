(**
 * x86 register allocation
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure X86RegisterAllocation : X86REGISTERALLOCATION =
struct

  structure I = X86Mnemonic
  structure F = FrameLayout

  structure RegOrd =
  struct
    type ord_key = I.r32
    fun toInt I.EAX = 0
      | toInt I.EBX = 1
      | toInt I.ECX = 2
      | toInt I.EDX = 3
      | toInt I.ESI = 4
      | toInt I.EDI = 5
      | toInt I.EBP = 6
      | toInt I.ESP = 7
      | toInt (I.ANY _) = 8
    fun compare (I.ANY {id=id1,...}, I.ANY {id=id2,...}) =
        VarID.compare (id1, id2)
      | compare (reg1, reg2) = Int.compare (toInt reg1, toInt reg2)
  end
  structure RegMap = BinaryMapMaker(RegOrd)
  structure RegSet = BinarySetMaker(RegOrd)


  datatype var =
      REG of I.r32
    | VAR of I.varInfo
    | POSTFRAME of {offset: int, size: word}
    | PREFRAME of {offset: int, size: word}
    | EXTERN of string
    | GLOBAL of string
    | EXTFUN of string

  local

    fun useImm imm =
        case imm of
          I.INT _ => nil
        | I.WORD _ => nil
        | I.LABEL _ => nil
        | I.ENTRYLABEL _ => nil
        | I.CONSTSUB (imm1, imm2) => useImm imm1 @ useImm imm2
        | I.CONSTADD (imm1, imm2) => useImm imm1 @ useImm imm2
        | I.CONSTAND (imm1, imm2) => useImm imm1 @ useImm imm2
        | I.EXTSTUBLABEL label => [EXTFUN label]
        | I.GLOBALLABEL label => [GLOBAL label]
        | I.EXTERNLABEL label => [EXTERN label]

    fun useMem mem =
        case mem of
          I.ABSADDR imm => useImm imm
        | I.VAR varInfo => [VAR varInfo]
        | I.BASE reg => [REG reg]
        | I.MEM (reg, scale, reg2) => [REG reg, REG reg2]
        | I.POSTFRAME x => [POSTFRAME x]
        | I.PREFRAME x => [PREFRAME x]
        | I.DISP (imm, mem) => useImm imm @ useMem mem

    fun useR8 (I.XL reg) = [REG reg]
      | useR8 (I.XH reg) = [REG reg]
    fun useR16 (I.X reg) = [REG reg]

    fun useRM8 (I.R8 reg) = useR8 reg
      | useRM8 (I.M8 mem) = useMem mem
    fun useRMI8 (I.R_8 reg) = useR8 reg
      | useRMI8 (I.M_8 mem) = useMem mem
      | useRMI8 (I.I_8 imm) = useImm imm
    fun useRM16 (I.R16 reg) = useR16 reg
      | useRM16 (I.M16 mem) = useMem mem
    fun useRMI16 (I.R_16 reg) = useR16 reg
      | useRMI16 (I.M_16 mem) = useMem mem
      | useRMI16 (I.I_16 imm) = useImm imm
    fun useRM32 (I.R reg) = [REG reg]
      | useRM32 (I.M mem) = useMem mem
    fun useRMI32 (I.R_ reg) = [REG reg]
      | useRMI32 (I.M_ mem) = useMem mem
      | useRMI32 (I.I_ imm) = useImm imm
    fun useJumpTo (I.ABS x) = useRMI32 x
      | useJumpTo (I.REL x) = useImm x

    fun dstRM8 (I.R8 reg) = {defs = useR8 reg, uses = nil}
      | dstRM8 (I.M8 mem) = {defs = nil, uses = useMem mem}
    fun dstRM16 (I.R16 reg) = {defs = useR16 reg, uses = nil}
      | dstRM16 (I.M16 mem) = {defs = nil, uses = useMem mem}
    fun dstRM32 (I.R reg) = {defs = [REG reg], uses = nil}
      | dstRM32 (I.M mem) = {defs = nil, uses = useMem mem}

    (* dst = src *)
    fun move ({defs:var list, uses:var list}, uses2) =
        {defs = defs, uses = uses @ uses2, clobs = nil:var list}
    (* dst = op(dst) *)
    fun unary {defs:var list, uses:var list} =
        {defs = nil:var list, uses = defs @ uses, clobs = defs}
    (* dst = dst op src *)
    fun arith ({defs:var list, uses:var list}, uses2) =
        {defs = nil:var list, uses = defs @ uses @ uses2, clobs = defs}

  in

  fun defUse insn =
      case insn of
        I.NOP => {defs=nil, uses=nil, clobs=nil}
      | I.MOVB (dst, src) => move (dstRM8 dst, useRMI8 src)
      | I.MOVW (dst, src) => move (dstRM16 dst, useRMI16 src)
      | I.MOVL (dst, src) => move (dstRM32 dst, useRMI32 src)
      | I.LEAL (dst, mem) => {defs = [REG dst], uses = useMem mem, clobs=nil}
      | I.CBW => {defs=[REG I.EAX], uses=[REG I.EAX], clobs=nil}
      | I.CWDE => {defs=[REG I.EAX], uses=[REG I.EAX], clobs=nil}
      | I.CDQ => {defs=[REG I.EAX,REG I.EDX], uses=[REG I.EAX], clobs=nil}
      | I.MOVZBW (I.X dst, src) => {defs = [REG dst], uses = useRM8 src,
                                    clobs=nil}
      | I.MOVZBL (dst, src) => {defs = [REG dst], uses = useRM8 src, clobs=nil}
      | I.MOVZWL (dst, src) => {defs = [REG dst], uses = useRM16 src, clobs=nil}
      | I.CLD => {defs=nil, uses=nil, clobs=nil}
      | I.REP_MOVSB => {defs=nil, uses=[REG I.ESI,REG I.EDI,REG I.ECX],
                        clobs=[REG I.ESI,REG I.EDI,REG I.ECX]}
      | I.REP_STOSD => {defs=nil, uses=[REG I.EAX,REG I.EDI,REG I.ECX],
                        clobs=[REG I.EDI,REG I.ECX]}
      | I.ADDL (dst, src) => arith (dstRM32 dst, useRMI32 src)
      | I.SUBL (dst, src) => arith (dstRM32 dst, useRMI32 src)
      | I.IMULL arg => {defs = [REG I.EDX], uses = REG I.EAX::useRM32 arg,
                        clobs=[REG I.EAX]}
      | I.MULL arg => {defs = [REG I.EDX], uses = REG I.EAX::useRM32 arg,
                       clobs=[REG I.EAX]}
      | I.IDIVL arg =>{defs = nil, uses = REG I.EDX::REG I.EAX::useRM32 arg,
                       clobs=[REG I.EAX,REG I.EDX]}
      | I.DIVL arg => {defs = nil, uses = REG I.EDX::REG I.EAX::useRM32 arg,
                       clobs=[REG I.EAX,REG I.EDX]}
      | I.ANDB (dst, src) => arith (dstRM8 dst, useRMI8 src)
      | I.ANDL (dst, src) => arith (dstRM32 dst, useRMI32 src)
      | I.ORB (dst, src) => arith (dstRM8 dst, useRMI8 src)
      | I.ORL (dst, src) => arith (dstRM32 dst, useRMI32 src)
      | I.XORL (dst, src) => arith (dstRM32 dst, useRMI32 src)
      | I.SHLL (dst, c) => unary (dstRM32 dst)
      | I.SHLL_CL dst => arith (dstRM32 dst, [REG I.ECX])
      | I.SHRL (dst, c) => unary (dstRM32 dst)
      | I.SHRL_CL dst => arith (dstRM32 dst, [REG I.ECX])
      | I.SARL (dst, c) => unary (dstRM32 dst)
      | I.SARL_CL dst => arith (dstRM32 dst, [REG I.ECX])
      | I.NOTL dst => unary (dstRM32 dst)
      | I.NEGL dst => unary (dstRM32 dst)
      | I.CMPB (dst, src) => {defs=nil, uses = useRM8 dst @ useRMI8 src,
                              clobs=nil}
      | I.CMPL (dst, src) => {defs=nil, uses = useRM32 dst @ useRMI32 src,
                              clobs=nil}
      | I.TESTB (dst, src) => {defs=nil, uses = useRM8 dst @ useRMI8 src,
                               clobs=nil}
      | I.TESTL (dst, src) => {defs=nil, uses = useRM32 dst @ useRMI32 src,
                               clobs=nil}
      | I.SET (cc, dst) => {defs = useRM8 dst, uses = nil, clobs=nil}
      | I.J (cc, label, _) => {defs=nil, uses=nil, clobs=nil}
      | I.JMP (l, _) => {defs=nil, uses = useJumpTo l, clobs=nil}
      | I.CALL l => {defs=nil, uses = useJumpTo l, clobs=nil}
      | I.RET x => {defs=nil, uses=nil, clobs=nil}
      | I.LEAVE => {defs=nil, uses=nil, clobs=nil}
      | I.PUSHL arg => {defs = nil, uses = useRMI32 arg, clobs=nil}
      | I.POPL dst => {defs = useRM32 dst, uses = nil, clobs=nil}
      | I.FLDS mem => {defs=nil, uses=useMem mem, clobs=nil}
      | I.FLDL mem => {defs=nil, uses=useMem mem, clobs=nil}
      | I.FLDT mem => {defs=nil, uses=useMem mem, clobs=nil}
      | I.FLD sti => {defs=nil, uses=nil, clobs=nil}
      | I.FILDL mem => {defs=nil, uses=useMem mem, clobs=nil}
      | I.FILDQ mem => {defs=nil, uses=useMem mem, clobs=nil}
      | I.FSTPS mem => {defs=nil, uses=useMem mem, clobs=nil}
      | I.FSTPL mem => {defs=nil, uses=useMem mem, clobs=nil}
      | I.FISTPL mem => {defs=nil, uses=useMem mem, clobs=nil}
      | I.FISTPQ mem => {defs=nil, uses=useMem mem, clobs=nil}
      | I.FADDP sti => {defs=nil, uses=nil, clobs=nil}
      | I.FSUBP sti => {defs=nil, uses=nil, clobs=nil}
      | I.FMULP sti => {defs=nil, uses=nil, clobs=nil}
      | I.FDIVP sti => {defs=nil, uses=nil, clobs=nil}
      | I.FABS => {defs=nil, uses=nil, clobs=nil}
      | I.FCHS => {defs=nil, uses=nil, clobs=nil}
      | I.FUCOMPP => {defs=nil, uses=nil, clobs=nil}
      | I.FSTSW_AX => {defs=[REG I.EAX], uses=nil, clobs=nil}
      | I.FLDCW mem => {defs=nil, uses=useMem mem, clobs=nil}
      | I.FNSTCW mem => {defs=nil, uses=useMem mem, clobs=nil}
      | I.Label label => {defs=nil, uses=nil, clobs=nil}
      | I.Loc loc => {defs=nil, uses=nil, clobs=nil}
      | I.GlobalCodeLabel label => {defs=nil, uses=nil, clobs=nil}
      | I.GlobalDataLabel label => {defs=nil, uses=nil, clobs=nil}
      | I.Align {align, filler} => {defs=nil, uses=nil, clobs=nil}
      | I.Prologue _ => {defs=nil, uses=nil, clobs=nil}
      | I.Epilogue _ => {defs=nil, uses=nil, clobs=nil}
      | I.Use regs => {defs = nil, uses = map REG regs, clobs=nil}
      | I.Def regs => {defs = map REG regs, uses = nil, clobs=nil}
      | I.Data _ => {defs = nil, uses = nil, clobs = nil}
      | I.Section _ => {defs = nil, uses = nil, clobs = nil}

  end


  type subst =
      {
        registers: I.r32 VarID.Map.map,
        variables: I.rm32 VarID.Map.map,
        postFrameStart: int option,
        preFrameEnd: int option,
        prologueCode: int -> I.instruction list,
        epilogueCode: int -> I.instruction list
      }

  (*
   * register may be substituted only with register.
   * variable may be substituted with both register and variable.
   *)
  fun substReg subst (reg as I.ANY {id,...}) =
      (
        case VarID.Map.find (subst, id) of
          SOME x => x
        | NONE => reg
      )
    | substReg subst reg = reg

  local

    val toWord = BasicTypes.SInt32ToUInt32

    fun substReg8 ({registers,...}:subst) (I.XH reg) =
        I.XH (substReg registers reg)
      | substReg8 ({registers,...}:subst) (I.XL reg) =
        I.XL (substReg registers reg)
    fun substReg16 ({registers,...}:subst) (I.X reg) =
        I.X (substReg registers reg)
    fun substReg32 ({registers,...}:subst) reg =
        substReg registers reg

    fun substMem (subst as {registers,variables,...}:subst) mem =
        case mem of
          I.DISP (m, mem) =>
          (
            case substMem subst mem of
              I.R reg => I.M (I.DISP (m, I.BASE reg))
            | I.M mem => I.M (I.DISP (m, mem))
          )
        | I.ABSADDR imm => I.M mem
        | I.VAR {id,...} =>
          (
            case VarID.Map.find (variables, id) of
              SOME x => x
            | NONE => I.M mem
          )
        | I.BASE reg => I.M (I.BASE (substReg registers reg))
        | I.MEM (reg, scale, reg2) =>
          I.M (I.MEM (substReg registers reg, scale, substReg registers reg2))
        | I.POSTFRAME {offset, size} =>
          (
            case #postFrameStart subst of
              SOME start => I.M (I.DISP (I.INT (Int32.fromInt (start + offset)),
                                         I.BASE I.EBP))
            | _ => I.M mem
          )
        | I.PREFRAME {offset, size} =>
          (
            case #preFrameEnd subst of
              SOME last => I.M (I.DISP (I.INT (Int32.fromInt (last - offset)),
                                        I.BASE I.EBP))
            | NONE => I.M mem
          )

    fun substMem' subst mem =
        case substMem subst mem of
          I.R _ => raise Control.Bug "substMem'"
        | I.M mem => mem

    fun toRM8 (I.R reg) = I.R8 (I.XL reg)
      | toRM8 (I.M mem) = I.M8 mem
    fun toRM16 (I.R reg) = I.R16 (I.X reg)
      | toRM16 (I.M mem) = I.M16 mem
    fun toRMI8 (I.R reg) = I.R_8 (I.XL reg)
      | toRMI8 (I.M mem) = I.M_8 mem
    fun toRMI16 (I.R reg) = I.R_16 (I.X reg)
      | toRMI16 (I.M mem) = I.M_16 mem
    fun toRMI32 (I.R reg) = I.R_ reg
      | toRMI32 (I.M mem) = I.M_ mem

    fun substRM8 subst (I.R8 reg) = I.R8 (substReg8 subst reg)
      | substRM8 subst (I.M8 mem) = toRM8 (substMem subst mem)
    fun substRMI8 subst (I.R_8 reg) = I.R_8 (substReg8 subst reg)
      | substRMI8 subst (I.M_8 mem) = toRMI8 (substMem subst mem)
      | substRMI8 subst (x as I.I_8 imm) = x
    fun substRM16 subst (I.R16 reg) = I.R16 (substReg16 subst reg)
      | substRM16 subst (I.M16 mem) = toRM16 (substMem subst mem)
    fun substRMI16 subst (I.R_16 reg) = I.R_16 (substReg16 subst reg)
      | substRMI16 subst (I.M_16 mem) = toRMI16 (substMem subst mem)
      | substRMI16 subst (x as I.I_16 imm) = x
    fun substRM32 subst (I.R reg) = I.R (substReg32 subst reg)
      | substRM32 subst (I.M mem) = substMem subst mem
    fun substRMI32 subst (I.R_ reg) = I.R_ (substReg32 subst reg)
      | substRMI32 subst (I.M_ mem) = toRMI32 (substMem subst mem)
      | substRMI32 subst (x as I.I_ imm) = x
    fun substJumpTo subst (I.ABS x) = I.ABS (substRMI32 subst x)
      | substJumpTo subst (x as I.REL _) = x

  in

  fun substInsn subst insn =
      case insn of
        I.NOP => I.NOP
      | I.MOVB (dst, src) => I.MOVB (substRM8 subst dst, substRMI8 subst src)
      | I.MOVW (dst, src) => I.MOVW (substRM16 subst dst, substRMI16 subst src)
      | I.MOVL (dst, src) => I.MOVL (substRM32 subst dst, substRMI32 subst src)
      | I.LEAL (dst, mem) => I.LEAL (substReg32 subst dst, substMem' subst mem)
      | I.CBW => insn
      | I.CWDE => insn
      | I.CDQ => insn
      | I.MOVZBW (dst, src) =>
        I.MOVZBW (substReg16 subst dst, substRM8 subst src)
      | I.MOVZBL (dst, src) =>
        I.MOVZBL (substReg32 subst dst, substRM8 subst src)
      | I.MOVZWL (dst, src) =>
        I.MOVZWL (substReg32 subst dst, substRM16 subst src)
      | I.CLD => insn
      | I.REP_MOVSB => insn
      | I.REP_STOSD => insn
      | I.ADDL (dst, src) => I.ADDL (substRM32 subst dst, substRMI32 subst src)
      | I.SUBL (dst, src) => I.SUBL (substRM32 subst dst, substRMI32 subst src)
      | I.IMULL arg => I.IMULL (substRM32 subst arg)
      | I.MULL arg => I.MULL (substRM32 subst arg)
      | I.IDIVL arg => I.IDIVL (substRM32 subst arg)
      | I.DIVL arg => I.DIVL (substRM32 subst arg)
      | I.ANDB (dst, src) => I.ANDB (substRM8 subst dst, substRMI8 subst src)
      | I.ANDL (dst, src) => I.ANDL (substRM32 subst dst, substRMI32 subst src)
      | I.ORB (dst, src) => I.ORB (substRM8 subst dst, substRMI8 subst src)
      | I.ORL (dst, src) => I.ORL (substRM32 subst dst, substRMI32 subst src)
      | I.XORL (dst, src) => I.XORL (substRM32 subst dst, substRMI32 subst src)
      | I.SHLL (dst, c) => I.SHLL (substRM32 subst dst, c)
      | I.SHLL_CL dst => I.SHLL_CL (substRM32 subst dst)
      | I.SHRL (dst, c) => I.SHRL (substRM32 subst dst, c)
      | I.SHRL_CL dst => I.SHRL_CL (substRM32 subst dst)
      | I.SARL (dst, c) => I.SARL (substRM32 subst dst, c)
      | I.SARL_CL dst => I.SARL_CL (substRM32 subst dst)
      | I.NOTL dst => I.NOTL (substRM32 subst dst)
      | I.NEGL dst => I.NEGL (substRM32 subst dst)
      | I.CMPB (dst, src) => I.CMPB (substRM8 subst dst, substRMI8 subst src)
      | I.CMPL (dst, src) => I.CMPL (substRM32 subst dst, substRMI32 subst src)
      | I.TESTB (dst, src) => I.TESTB (substRM8 subst dst, substRMI8 subst src)
      | I.TESTL (dst, src) =>
        I.TESTL (substRM32 subst dst, substRMI32 subst src)
      | I.SET (cc, dst) => I.SET (cc, substRM8 subst dst)
      | I.J (cc, label, _) => insn
      | I.JMP (l, succs) => I.JMP (substJumpTo subst l, succs)
      | I.CALL l => I.CALL (substJumpTo subst l)
      | I.RET x => insn
      | I.LEAVE => insn
      | I.PUSHL arg => I.PUSHL (substRMI32 subst arg)
      | I.POPL dst => I.POPL (substRM32 subst dst)
      | I.FLDS mem => I.FLDS (substMem' subst mem)
      | I.FLDL mem => I.FLDL (substMem' subst mem)
      | I.FLDT mem => I.FLDT (substMem' subst mem)
      | I.FLD sti => insn
      | I.FILDL mem => I.FILDL (substMem' subst mem)
      | I.FILDQ mem => I.FILDQ (substMem' subst mem)
      | I.FSTPS mem => I.FSTPS (substMem' subst mem)
      | I.FSTPL mem => I.FSTPL (substMem' subst mem)
      | I.FISTPL mem => I.FISTPL (substMem' subst mem)
      | I.FISTPQ mem => I.FISTPQ (substMem' subst mem)
      | I.FADDP sti => insn
      | I.FSUBP sti => insn
      | I.FMULP sti => insn
      | I.FDIVP sti => insn
      | I.FABS => insn
      | I.FCHS => insn
      | I.FUCOMPP => insn
      | I.FSTSW_AX => insn
      | I.FLDCW mem => I.FLDCW (substMem' subst mem)
      | I.FNSTCW mem => I.FNSTCW (substMem' subst mem)
      | I.Label label => insn
      | I.Loc loc => insn
      | I.GlobalCodeLabel label => insn
      | I.GlobalDataLabel label => insn
      | I.Align {align, filler} => insn
      | I.Prologue {preFrameSize, instructions} =>
        I.Prologue {preFrameSize = preFrameSize,
                    instructions = map (substInsn subst)
                                       (#prologueCode subst preFrameSize)}
      | I.Epilogue {preFrameSize, instructions} =>
        I.Epilogue {preFrameSize = preFrameSize,
                    instructions = map (substInsn subst)
                                       (#epilogueCode subst preFrameSize)}
      (*
      | I.LoadGlobalOffset => insn
*)
      | I.Use regs => I.Use (map (substReg32 subst) regs)
      | I.Def regs => I.Def (map (substReg32 subst) regs)
      | I.Data _ => insn
      | I.Section _ => insn

  end












































































(*


  fun substReg subst (reg as I.ANY {id,...}) =
      (
VarID.Map.appi (fn (k,v) => print (Control.prettyPrint (I.format_id k) ^ "->" ^ Control.prettyPrint (I.format_r32 v) ^ ", ")) subst;
print (" : "^Control.prettyPrint (I.format_r32 reg)^"\n");
       case VarID.Map.find (subst, id) of
        SOME (REG x) => x
      | SOME _ => raise Control.Bug "substReg: intend to subst reg to mem"
        SOME x => x
      | NONE => reg (*raise Control.Bug "substReg"*)
                                  )
    | substReg subst reg = reg
  local
    fun substReg8 subst (I.XH reg) = I.XH (substReg subst reg)
      | substReg8 subst (I.XL reg) = I.XL (substReg subst reg)
    fun substReg16 subst (I.X reg) = I.X (substReg subst reg)

    fun substVar subst id default =
        case VarID.Map.find (subst, id) of
          SOME (REG x) => I.R x
        | SOME (VAR x) => I.M (I.VAR x)
        | SOME (TMP (POSTFRAME x)) => I.M (I.POSTFRAME








    fun substMem subst mem =
        case mem of
          I.ABSADDR imm => mem
        | I.LABELADDR label => mem
        | I.LABELREL (imm, label) => mem
        | I.VAR {id,...} =>
          (
            case VarID.Map.find (subst, id) of
              SOME (REG x) => I.R x
            | SOME (VAR x) => I.M (I.VAR x)
            | SOME (TMP (POSTFRAME x)) => I.M (I.POSTFRAME x)
            | SOME (TMP (PREFRAME x)) => I.M (I.PREFRAME x)
            | NONE => mem
          )
        | I.VARREL (imm, varInfo) =>
          (
            case VarID.Map.find (subst, id) of
              SOME (REG x) => I.R x
            | SOME (VAR x) => I.M (I.VAR x)
            |


          )
        | I.BASE reg => I.BASE (substReg subst reg)
        | I.OFF (imm, reg) => I.OFF (imm, substReg subst reg)
        | I.ARY (imm, scale, reg) => I.ARY (imm, scale, substReg subst reg)
        | I.MEM (imm, reg, scale, reg2) =>
          I.MEM (imm, substReg subst reg, scale, substReg subst reg2)
        | I.POSTFRAME {offset, size} => mem (* FIXME *)
        | I.PREFRAME {offset, size} => mem (* FIXME *)
        | I.LINK => mem (* FIXME *)

    fun substRM8 subst (I.R8 reg) = I.R8 (substReg8 subst reg)
      | substRM8 subst (I.M8 mem) = substMem subst mem
    fun substRMI8 subst (I.R_8 reg) = I.R_8 (substReg8 subst reg)
      | substRMI8 subst (I.M_8 mem) = substMem subst mem
      | substRMI8 subst (x as I.I_8 imm) = x
    fun substRM16 subst (I.R16 reg) = I.R16 (substReg16 subst reg)
      | substRM16 subst (I.M16 mem) = substMem subst mem
    fun substRMI16 subst (I.R_16 reg) = I.R_16 (substReg16 subst reg)
      | substRMI16 subst (I.M_16 mem) = substMem subst mem
      | substRMI16 subst (x as I.I_16 imm) = x
    fun substRM32 subst (I.R reg) = I.R (substReg subst reg)
      | substRM32 subst (I.M mem) = substMem subst mem
    fun substRMI32 subst (I.R_ reg) = I.R_ (substReg subst reg)
      | substRMI32 subst (I.M_ mem) = substMem subst mem
      | substRMI32 subst (x as I.I_ imm) = x
  in

  fun substInsn subst insn =
      case insn of
        I.NOP => I.NOP
      | I.MOVB (dst, src) => I.MOVB (substRM8 subst dst, substRMI8 subst src)
      | I.MOVW (dst, src) => I.MOVW (substRM16 subst dst, substRMI16 subst src)
      | I.MOVL (dst, src) => I.MOVL (substRM32 subst dst, substRMI32 subst src)
      | I.LEAL (dst, mem) => I.LEAL (substReg subst dst, substMem subst mem)
      | I.CBW => insn
      | I.CWDE => insn
      | I.CDQ => insn
      | I.MOVZBW (dst, src) =>
        I.MOVZBW (substReg16 subst dst, substRM8 subst src)
      | I.MOVZBL (dst, src) =>
        I.MOVZBL (substReg subst dst, substRM8 subst src)
      | I.MOVZWL (dst, src) =>
        I.MOVZWL (substReg subst dst, substRM16 subst src)
      | I.CLD => insn
      | I.REP_MOVSB => insn
      | I.ADDL (dst, src) => I.ADDL (substRM32 subst dst, substRMI32 subst src)
      | I.SUBL (dst, src) => I.SUBL (substRM32 subst dst, substRMI32 subst src)
      | I.IMULL arg => I.IMULL (substRM32 subst arg)
      | I.MULL arg => I.MULL (substRM32 subst arg)
      | I.IDIVL arg => I.IDIVL (substRM32 subst arg)
      | I.DIVL arg => I.DIVL (substRM32 subst arg)
      | I.ANDB (dst, src) => I.ANDB (substRM8 subst dst, substRMI8 subst src)
      | I.ANDL (dst, src) => I.ANDL (substRM32 subst dst, substRMI32 subst src)
      | I.ORB (dst, src) => I.ORB (substRM8 subst dst, substRMI8 subst src)
      | I.ORL (dst, src) => I.ORL (substRM32 subst dst, substRMI32 subst src)
      | I.XORL (dst, src) => I.XORL (substRM32 subst dst, substRMI32 subst src)
      | I.SHLL (dst, c) => I.SHLL (substRM32 subst dst, c)
      | I.SHLL_CL dst => I.SHLL_CL (substRM32 subst dst)
      | I.SHRL (dst, c) => I.SHRL (substRM32 subst dst, c)
      | I.SHRL_CL dst => I.SHRL_CL (substRM32 subst dst)
      | I.SARL (dst, c) => I.SARL (substRM32 subst dst, c)
      | I.SARL_CL dst => I.SARL_CL (substRM32 subst dst)
      | I.NOTL dst => I.NOTL (substRM32 subst dst)
      | I.NEGL dst => I.NEGL (substRM32 subst dst)
      | I.CMPB (dst, src) => I.CMPB (substRM8 subst dst, substRMI8 subst src)
      | I.CMPL (dst, src) => I.CMPL (substRM32 subst dst, substRMI32 subst src)
      | I.TESTB (dst, src) => I.TESTB (substRM8 subst dst, substRMI8 subst src)
      | I.TESTL (dst, src) =>
        I.TESTL (substRM32 subst dst, substRMI32 subst src)
      | I.SET (cc, dst) => I.SET (cc, substRM8 subst dst)
      | I.J (cc, label) => insn
      | I.JMP l => I.JMP (substRMI32 subst l)
      | I.CALL l => I.CALL (substRMI32 subst l)
      | I.RET x => insn
      | I.LEAVE => insn
      | I.PUSHL arg => I.PUSHL (substRMI32 subst arg)
      | I.POPL dst => I.POPL (substRM32 subst dst)
      | I.FLDS mem => I.FLDS (substMem subst mem)
      | I.FLDL mem => I.FLDL (substMem subst mem)
      | I.FLDT mem => I.FLDT (substMem subst mem)
      | I.FLD sti => insn
      | I.FILDL mem => I.FILDL (substMem subst mem)
      | I.FILDQ mem => I.FILDQ (substMem subst mem)
      | I.FSTPS mem => I.FSTPS (substMem subst mem)
      | I.FSTPL mem => I.FSTPL (substMem subst mem)
      | I.FISTPL mem => I.FISTPL (substMem subst mem)
      | I.FISTPQ mem => I.FISTPQ (substMem subst mem)
      | I.FADDP sti => insn
      | I.FSUBP sti => insn
      | I.FMULP sti => insn
      | I.FDIVP sti => insn
      | I.FABS => insn
      | I.FCHS => insn
      | I.FUCOMPP => insn
      | I.FSTSW_AX => insn
      | I.Global label => insn
      | I.Label label => insn
      | I.Align {align, filler} => insn
      | I.Prologue => insn
      | I.Epilogue => insn
      | I.Use regs => I.Use (map (substReg subst) regs)
      | I.Def regs => I.Def (map (substReg subst) regs)

  end

*)







(*
  val callerSaveRegs = [I.EAX, I.EDX, I.ECX]
  val calleeSaveRegs = [I.ESI, I.EDI, I.EBX]
  val anyRegs = callerSaveRegs @ calleeSaveRegs
*)

  val emptyLabelRef =
      {globalRefs = SSet.empty,
       extDataRefs = SSet.empty,
       extCodeRefs = SSet.empty}

  fun gatherLabelRefs vars =
      let
        fun makeSet f l = SSet.fromList (List.mapPartial f l)
      in
        {globalRefs = makeSet (fn GLOBAL x => SOME x | _ => NONE) vars,
         extDataRefs = makeSet (fn EXTERN x => SOME x | _ => NONE) vars,
         extCodeRefs = makeSet (fn EXTFUN x => SOME x | _ => NONE) vars}
      end

  fun unionLabelRefs ({globalRefs=g1, extDataRefs=e1, extCodeRefs=f1},
                      {globalRefs=g2, extDataRefs=e2, extCodeRefs=f2}) =
      {globalRefs = SSet.union (g1, g2),
       extDataRefs = SSet.union (e1, e2),
       extCodeRefs = SSet.union (f1, f2)}

  local
    fun domain regmap =
        RegSet.fromList (RegMap.listKeys regmap)

    fun addInterference (interference, reg, regset) =
        case RegMap.find (interference, reg) of
          SOME x => RegMap.insert (interference, reg, RegSet.union (x, regset))
        | NONE => RegMap.insert (interference, reg, regset)

    exception UnusedRegister of I.r32

    fun isPrefix (nil, l) = true
      | isPrefix (h::t, h2::t2) =
        RegOrd.compare (h, h2) = EQUAL andalso isPrefix (t, t2)
      | isPrefix (h::t, nil) = false

    fun setRegisterCandidate (candidateMap, regs) =
        foldl (fn (REG (I.ANY {id, candidates}), candidateMap) =>
                  let
                    val cand =
                        case VarID.Map.find (candidateMap, id) of
                          SOME prevCand =>
                          if isPrefix (candidates, prevCand)
                          then candidates
                          else raise Control.Bug ("%"^VarID.toString id^
                                                  "has different candidates.")
                        | NONE => candidates
                  in
                    VarID.Map.insert (candidateMap, id, cand)
                  end
                | (_, candidateMap) => candidateMap)
              candidateMap
              regs

    fun liveMinus (live, regs, interference) =
        foldr (fn (reg, (live, interference)) =>
                  let
                    val (live, regset) = RegMap.remove (live, reg)
                                         handle NotFound =>
                                                raise UnusedRegister reg
                  in
                    (live, addInterference (interference, reg, regset))
                  end)
              (live, interference)
              regs

    fun livePlus (live, regs) =
        let
          val live =
              foldl (fn (reg, live) =>
                        case RegMap.find (live, reg) of
                          SOME _ => live
                        | NONE => RegMap.insert (live, reg, RegSet.empty))
                    live
                    regs

          val liveRegs = domain live
        in
          RegMap.map (fn interference => RegSet.union (liveRegs, interference))
                     live
        end


(*
    fun livePlus (I live, regs) =
        let
          val live =
              foldl (fn (reg, live) =>
                        case RegMap.find (live, reg) of
                          SOME x => live
                        | NONE => RegMap.insert (live, reg, I RegMap.empty))
                    live regs
          val live =
              RegMap.map (fn I interference =>
                             I (RegMap.unionWith #1 (live, interference)))
                         live
        in
          I live
        end
*)

(*
    (* interference is a map from register to a set of registers.
     * We use the same data type (interference RegMap.map) for both
     * the interference map and the set of registers.
     *)
    datatype interference =
             I of interference RegMap.map

    fun liveMinus (live, regs) =
        foldr (fn (reg, (I live, regs)) =>
                  let
                    val (live, I interference) = RegMap.remove (live, reg)



    fun liveMinus (live, regs) =
        foldr (fn (reg, (I live, regs)) =>
                  let
                    val (live, I interference) = RegMap.remove (live, reg)
                  in
                    (I live, (reg,interference)::regs)
                  end)
              (live, nil)
              regs
        handle NotFound => raise Control.Bug "liveMinus: unused def"

    fun livePlus (I live, regs) =
        let
          val live =
              foldl (fn (reg, live) =>
                        case RegMap.find (live, reg) of
                          SOME x => live
                        | NONE => RegMap.insert (live, reg, I RegMap.empty))
                    live regs
          val live =
              RegMap.map (fn I interference =>
                             I (RegMap.unionWith #1 (live, interference)))
                         live
        in
          I live
        end
*)

(*
    fun alloc (subst, regId, interference, candidates) =
        let
          val interference =
              RegMap.foldli
                  (fn (k,v,z) => RegMap.insert (z, substReg subst k, v))
                  interference
                  interference
          val alloc =
              case List.find
                       (fn x => case RegMap.find (interference, x) of
                                  SOME x => false
                                | NONE => true)
                       candidates of
                SOME reg => reg
              | NONE =>
                raise Control.Bug "allocReg: no register available"
        in
          VarID.Map.insert (subst, regId, alloc)
        end
*)

(*
    fun allocReg ((I.ANY id,i)::interferences, subst) =
        let
(*
          val candidates = case class of
                             I.ANY32 => anyRegs
                           | I.SAVE32 => calleeSaveRegs
*)
          val candidates = anyRegs

(*
          val _ = print "interference1: "
          val _ = RegMap.appi (fn (k,v) => print (Control.prettyPrint (I.debug_r32 k)^",")) i
          val _ = print "\n"
*)

          val interference =
              RegMap.foldli
                  (fn (k,v,z) => RegMap.insert (z, substReg subst k, v))
                  RegMap.empty i

(*
          val _ = print "interference2: "
          val _ = RegMap.appi (fn (k,v) => print (Control.prettyPrint (I.debug_r32 k)^",")) interference
          val _ = print "\n"
*)

          val alloc =
              case List.find
                     (fn x => case RegMap.find (interference, x) of
                                SOME x => false
                              | NONE => true)
                     candidates of
                SOME reg => reg
              | NONE =>
                raise Control.Bug ("allocReg: no register available for "^
                                   VarID.toString id)

          val subst = VarID.Map.insert (subst, id, alloc)
        in
          allocReg (interferences, subst)
        end
      | allocReg (_::interferences, subst) =
        allocReg (interferences, subst)
      | allocReg (nil, subst) = subst
*)

    val emptyResult =
        {
          live = RegMap.empty,
          interference = RegMap.empty,
          candidates = VarID.Map.empty,
          vars = VarID.Map.empty,
          tmpFrameSize = (0, 0),   (* pre, post *)
          labelRefs = emptyLabelRef
        }

    fun analyzeInsn (insn, result) =
        let
          val {live, interference, candidates, vars,
               tmpFrameSize, labelRefs} = result
          val {defs, uses, clobs} = defUse insn

          val all = defs @ uses
          val defs = List.mapPartial (fn REG x => SOME x | _ => NONE) defs
          val uses = List.mapPartial (fn REG x => SOME x | _ => NONE) uses

          val vars =
              foldl (fn (VAR {id, format, candidates}, vars) =>
                        (
                          case VarID.Map.find (vars, id) of
                            SOME x =>
                            if x = format then vars
                            else raise Control.Bug ("v"^VarID.toString id
                                                    ^" has different format")
                          | NONE => VarID.Map.insert (vars, id, format)
                        )
                      | (_, vars) => vars)
                    vars
                    all

          val tmpFrameSize =
              foldl (fn (POSTFRAME {size, offset}, (pre, post)) =>
                        (pre, Int.max (post, offset + Word.toInt size))
                      | (PREFRAME {size, offset}, (pre, post)) =>
                        (Int.max (pre, offset), post)
                      | (_, z) => z)
                    tmpFrameSize
                    all

          val labelRefs = unionLabelRefs (labelRefs, gatherLabelRefs all)
          val candidates = setRegisterCandidate (candidates, all)

(*
          fun pr x = print (Control.prettyPrint (I.debug_r32 x))
          fun prl x = app (fn x => (pr x;print ",")) x
          fun ps x = SSet.app (fn v=>(print v;print",")) x
          fun lvm f x = VarID.Map.appi (fn (k,v)=>(print (Control.prettyPrint (I.debug_id k));print ": ";f v;print "\n")) x
          fun pii (k,v) = (pr k;print ": ";prl (RegSet.listItems v);print "\n")
          fun pi x = RegMap.appi (fn (k,v) => pii(k,v)) x
          val _ = print "live:\n"
          val _ = pi live
          (*
           val _ = print "subst:\n"
           val _ = lvm pr subst
           *)
          val _ = print "=== "
          val _ = print (Control.prettyPrint (I.debug_instruction insn))
          val _ = print "\nuse: "
          val _ = prl uses
          val _ = print "\ndef: "
          val _ = prl defs
          val _ = print "\nglobals: "
          val _ = ps (#1 labelRefs)
          val _ = print "\nexterns: "
          val _ = ps (#2 labelRefs)
          val _ = print "\nextfuns: "
          val _ = ps (#3 labelRefs)
          val _ = print "\n"
*)

          (* all defined registers are live *)
          (*
           val live = livePlus (live, defs)
           *)

          (*
           val _ = print "----- live2:\n"
           val _ = pi live
           val _ = print "-----\n\n"
           *)

          val (live, interference) =
              liveMinus (live, defs, interference)
              handle UnusedRegister r =>
                     raise Control.Bug
                               ("found unused definition of "^
                                Control.prettyPrint (I.debug_r32 r)^
                                " at "^
                                Control.prettyPrint (I.debug_instruction insn))
          val live = livePlus (live, uses)
        in
          {
            live = live,
            interference = interference,
            candidates = candidates,
            vars = vars,
            tmpFrameSize = tmpFrameSize,
            labelRefs = labelRefs
          }
        end

  in

  fun analyze insns =
      foldr analyzeInsn emptyResult insns

  end

(*
        val subst = allocReg (interferences, subst)
                    handle e =>
(
print "interference:\n";
app (fn (reg,i) =>
         (print (Control.prettyPrint (I.debug_r32 reg) ^ " => ");
          RegMap.appi (fn (k,v) =>
                          print (Control.prettyPrint (I.debug_r32 k)^",")) i;
          print "\n"))
     interferences;
print "\ninsn:\n";
print (Control.prettyPrint (I.debug_instruction insn));
print "\n";
raise e
)
*)
(*
      in
        {
          live = live,
(*
          subst = subst,
*)
          interference = interference,
          vars = vars,
          tmps = tmps,
          labelRefs = labelRefs
        }
      end

  end
*)


(*
  (* Assume that any register doesn't live beyond basic blocks. *)
  fun allocInsn nil =
      {subst=VarID.Map.empty, live=RegSet.empty,
       vars=VarID.Map.empty, tmps=nil}
    | allocInsn (insn::insnList) =
      let
        val {subst, live, vars, tmps} = allocInsn insnList
        val {defs, uses, ...} = defUse insn

        val newVars =
            foldl (fn (VAR varInfo, vars) =>
                      VarID.Map.insert (vars, #id varInfo, varInfo)
                    | (_, vars) => vars)
                  vars
                  (defs @ uses)

        val newTmps = List.mapPartial (fn TMP x => SOME x | _ => NONE)
                                      (defs @ uses)
        val defs = List.mapPartial (fn REG x => SOME x | _ => NONE) defs
        val uses = List.mapPartial (fn REG x => SOME x | _ => NONE) uses

        val _ = print "live: "
        val _ = RegSet.app (fn v => print (Control.prettyPrint (I.format_r32 v) ^ ", ")) live
        val _ = print "\ninsn: "
        val _ = print (Control.prettyPrint (I.format_instruction insn))
        val _ = print "\ndefs: "
        val _ = app (fn x => print (Control.prettyPrint (I.format_r32 x) ^ ", ")) defs
        val _ = print "\nuses: "
        val _ = app (fn x => print (Control.prettyPrint (I.format_r32 x) ^ ", ")) uses
        val _ = print "\n"

        val newLive =
            foldl (fn (reg, live) => RegSet.delete (live, reg)) live defs
            handle NotFound =>
                   raise Control.Bug "allocInsn: defined unused register"
        val newLive =
            foldl (fn (reg, live) => RegSet.add (live, substReg subst reg))
                  newLive uses

        fun alloc ((reg as I.ANY {id, class})::regs, saveRegs, anyRegs, subst) =
            let
              val (newReg, saveRegs, anyRegs) =
                    case (class, saveRegs, anyRegs) of
                      (I.SAVE32, reg::saveRegs, anyRegs) =>
                      (reg, saveRegs, anyRegs)
                    | (I.ANY32, saveRegs, reg::anyRegs) =>
                      (reg, saveRegs, anyRegs)
                    | (I.ANY32, reg::saveRegs, nil) =>
                      (reg, saveRegs, nil)
                    | _ => raise Control.Bug "alloc"
            in
              if RegSet.member (live, newReg)
              then alloc (reg::regs, saveRegs, anyRegs, subst)
              else alloc (regs, saveRegs, anyRegs,
                          VarID.Map.insert (subst, id, newReg))
            end
          | alloc (reg::regs, saveRegs, anyRegs, subst) =
            if RegSet.member (live, reg)
            then raise Control.Bug "alloc: doubly allocated"
            else alloc (regs, saveRegs, anyRegs, subst)
          | alloc (nil, saveRegs, anyRegs, subst) = subst

        val newSubst = alloc (uses,
                              [I.EDI,I.ESI,I.EBX],
                              [I.EAX,I.ECX,I.EDX],
                              subst)
(*
        val newLive = RegSet.map (substReg newSubst) newLive
*)

        val _ = print "\nsubst: "
         val _ = VarID.Map.appi (fn (k,v) => print (Control.prettyPrint (VarID.format_id k) ^ "->" ^ Control.prettyPrint (I.format_r32 v) ^ ", ")) subst

(*
        val insn = substInsn newSubst insn

        val _ = print "\nnewInsn: "
        val _ = print (Control.prettyPrint (I.format_instruction insn))
        val _ = print "\n"
*)
      in
        {
(*
          insns = insn :: insns,
*)
          subst = newSubst,
          live = newLive,
          vars = newVars,
          tmps = newTmps @ tmps
        }
      end
*)

  fun allocReg (interferences, candidateMap) =
      RegMap.foldli
        (fn (I.ANY {id,...}, regset, subst) =>
            let
              val candidates =
                  case VarID.Map.find (candidateMap, id) of
                    SOME x => x
                  | NONE => raise Control.Bug ("allocReg: "
                                               ^VarID.toString id)

              val regset =
                  RegSet.foldl (fn (k,z) => RegSet.add (z, substReg subst k))
                               RegSet.empty
                               regset

              val alloc =
                  case List.find (fn x => not (RegSet.member (regset, x)))
                                 candidates of
                    SOME reg => reg
                  | NONE =>
                    raise Control.Bug ("allocReg: no register available for "^
                                       VarID.toString id)
            in
              (VarID.Map.insert (subst, id, alloc))
            end
          | (_, _, z) => z)
        VarID.Map.empty
        interferences


  fun translateComposition offsetBase headerComposition =
      let
        fun mem x = I.DISP (I.INT (Int32.fromInt (offsetBase + Word.toInt x)),
                            I.BASE I.EBP)
      in
        case headerComposition of
          F.LSHIFT (reg, sh) => [I.SHLL (I.R reg, Word.toInt sh)]
        | F.ORBIT (dst, reg) => [I.ORL (I.R dst, I.R_ reg)]
        | F.ANDBIT (dst, imm) => [I.ANDL (I.R dst, I.I_ (I.WORD imm))]
        | F.MOVEREG (dst, reg) => [I.MOVL (I.R dst, I.R_ reg)]
        | F.MOVEIMM (dst, imm) => [I.MOVL (I.R dst, I.I_ (I.WORD imm))]
        | F.LOAD (dst, mem) => [I.MOVL (I.R dst, I.M_ mem)]
        | F.SAVEREG (off, reg) => [I.MOVL (I.M (mem off), I.R_ reg)]
        | F.SAVEIMM (off, imm) => [I.MOVL (I.M (mem off), I.I_ (I.WORD imm))]
        | F.SETNULL [off] => [I.MOVL (I.M (mem off), I.I_ (I.WORD 0w0))]
        | F.SETNULL offs =>
          I.MOVL (I.R I.EDX, I.I_ (I.INT 0)) ::
          map (fn off => I.MOVL (I.M (mem off), I.R_ I.EDX)) offs
      end

  fun ceil (m, n) =
      (m + n - 1) - (m + n - 1) mod n

  fun allocCluster ({frameBitmap, body, preFrameAligned,
                     loc}:I.cluster) =
      let
        val {interference, candidates, vars, tmpFrameSize, labelRefs, ...} =
            analyze body
        val (preFrameSize, postFrameSize) = tmpFrameSize
        val subst = allocReg (interference, candidates)

(*
        fun pr x = Control.prettyPrint (I.debug_r32 x)
        val _ = print "interference:\n"
        val _ = RegMap.appi (fn (r,rs) => (print (pr r^": ");RegSet.app(fn x => print (pr x^","))rs;print"\n")) interference
        val _ = print "subst:\n"
        val _ = VarID.Map.appi (fn (i,r) => (print (pr (I.ANY i)^" -> "^pr r^"\n"))) subst
        val _ = print "-------------------------------------------------\n"
        val _ = app (fn x => print (Control.prettyPrint (X86Mnemonic.debug_instruction x) ^"\n")) body
        val _ = print "-------------------------------------------------\n"
        val _ = print "usedRegs:\n"
        val _ = RegSet.app (fn x => print (pr x^",")) usedRegs
        val _ = print "\n"
*)

(*
        val _ = print "vars:\n"
        val _ = VarID.Map.appi (fn (i,f) => (print (VarID.toString i^": "^Control.prettyPrint (FrameLayout.format_format f)^"\n"))) vars
*)

        (*
         * If pre-frame is aligned, then its size must be 16n.
         * Otherwise, we need to insert a pad dynamically so that
         * the beginning of the pre-frame is aligned in 16n.
         *)
        val _ =
            if preFrameAligned then
              if preFrameSize mod 16 = 0 then ()
              else raise Control.Bug "assertion failed: preFrameSize"
            else
              raise Control.Bug "FIXME: not implemented preFrameAligned = false"

        val postFrameSize = ceil(postFrameSize, 16)

(*
        val _ = print ("preFrameSize:"^Int.toString preFrameSize^"\n")
        val _ = print ("postFrameSize:"^Int.toString postFrameSize^"\n")

        fun lvm f x = VarID.Map.appi (fn (k,v)=>(print (Control.prettyPrint (I.debug_id k));print ": ";f v;print "\n")) x
        val _ = lvm (fn v => print (Control.prettyPrint (FrameLayout.format_format v))) vars
*)

        (*
         * addr
         *  | :          :
         *  | +----------+ [align 16]  -----------------------------
         *  | :PostFrame : (need to allocate)                  ^
         *  | |          |                                     |
         *  | +==========+ [align 16]  preOffset = 0           |
         *  | | Frame    | (need to allocate)                  | need to alloc
         *  | |          |                                     |
         *  | +==========+ [align 12/16] postOffset = 12       |
         *  | | headaddr |                                     v
         *  | +----------+ 8/16 <---- ebp --------------------------
         *  | | push ebp |
         *  | +----------+ 4/16
         *  | | ret addr |
         *  | +==========+ [align 16]
         *  | | PreFrame | (allocated by caller)
         *  | :          :
         *  | +----------+ [align 16]
         *  | :          :
         *  v
         *)
        val headerAddrSize = 4

        val frameLayout as
            {frameSize, variableOffsets, headerCode, headerOffset} =
            FrameAllocation.allocate
                {preOffset = 0w0,
                 postOffset = 0w12,
                 maxAlign = 0w16,
                 wordSize = 0w4,
                 tmpReg1 = I.EDX,
                 tmpReg2 = I.ECX,
                 frameBitmap = frameBitmap,
                 variables = vars}

(*
        val _ = app (fn x => print (Control.prettyPrint (F.format_headerComposition (I.debug_r32, I.debug_mem) x)^"\n")) headerCode
        val _ = print (Control.prettyPrint (FrameLayout.format_frameLayout (I.debug_r32,I.debug_mem) frameLayout)^"\n")
*)

        val frameSize = Word.toInt frameSize
        val frameOffsetBase = ~(headerAddrSize + frameSize)

        (* make substitution from varId to frame offset.
         * Note that the top of frame is [%ebp - headerAddrSize - framesize]. *)
        val varSubst =
            VarID.Map.map
              (fn offset =>
                  let
                    val offset = frameOffsetBase + Word.toInt offset
                  in
                    I.M (I.DISP (I.INT (Int32.fromInt offset), I.BASE I.EBP))
                  end)
              variableOffsets

        (* caller have to allocate header + frame + post frame. *)
        val allocSize = headerAddrSize + frameSize + postFrameSize

        fun subSP size =
            if size = 0 then nil
            else [I.SUBL (I.R I.ESP, I.I_ (I.INT (Int32.fromInt size)))] @
                 (if !Control.debugCodeGen then
                    [
                      I.PUSHL (I.R_ I.EDI),
                      I.PUSHL (I.R_ I.ECX),
                      I.PUSHL (I.R_ I.EAX),
                      I.LEAL  (I.EDI, I.DISP (I.INT 12, I.BASE I.ESP)),
                      I.MOVL  (I.R I.ECX,
                               I.I_ (I.INT (Int32.fromInt size div 4))),
                      I.MOVL  (I.R I.EAX, I.I_ (I.WORD 0wx55555555)),
                      I.CLD,
                      I.REP_STOSD,
                      I.POPL  (I.R I.EAX),
                      I.POPL  (I.R I.ECX),
                      I.POPL  (I.R I.EDI)
                    ]
                  else nil)

        fun subSPWithLink size =
            (* move return address w.r.t. move of stack pointer so that
             * debugger can trace call traces. *)
            if size = 0 then nil
            else [I.MOVL (I.R I.EDX, I.M_ (I.BASE I.ESP)),
                  I.SUBL (I.R I.ESP, I.I_ (I.INT (Int32.fromInt size))),
                  I.MOVL (I.M (I.BASE I.ESP), I.R_ I.EDX)] @
                 (if !Control.debugCodeGen then
                    [
                      I.PUSHL (I.R_ I.EDI),
                      I.PUSHL (I.R_ I.ECX),
                      I.PUSHL (I.R_ I.EAX),
                      I.LEAL  (I.EDI, I.DISP (I.INT (12 + 4), I.BASE I.ESP)),
                      I.MOVL  (I.R I.ECX,
                               I.I_ (I.INT (Int32.fromInt size div 4))),
                      I.MOVL  (I.R I.EAX, I.I_ (I.WORD 0wx55555555)),
                      I.CLD,
                      I.REP_STOSD,
                      I.POPL  (I.R I.EAX),
                      I.POPL  (I.R I.ECX),
                      I.POPL  (I.R I.EDI)
                    ]
                  else nil)

        fun addSPWithLink size =
            (* move return address w.r.t. move of stack pointer so that
             * debugger can trace call traces. *)
            if size = 0 then nil
            else [I.POPL (I.M (I.DISP (I.INT (Int32.fromInt size - 4),
                                       I.BASE I.ESP))),
                  I.ADDL (I.R I.ESP, I.I_ (I.INT (Int32.fromInt size - 4)))]

        fun prologueCode allocedPreFrameSize =
            let
              val padSize = preFrameSize - allocedPreFrameSize
              val headerAddrCode =
                  case headerOffset of
                    NONE =>
                    [ I.MOVL (I.M (I.DISP (I.INT ~4, I.BASE I.EBP)),
                              I.I_ (I.INT 0)) ]
                  | SOME offset =>
                    let
                      val offset = frameOffsetBase + Word.toInt offset
                    in
                      [ I.MOVL (I.M (I.DISP (I.INT ~4, I.BASE I.EBP)),
                                I.I_ (I.INT (Int32.fromInt offset))) ]
                    end
            in
              subSPWithLink padSize @
              [
                I.PUSHL (I.R_ I.EBP),
                I.MOVL (I.R I.EBP, I.R_ I.ESP)
              ] @
              subSP allocSize @
              headerAddrCode @
              List.concat (map (translateComposition frameOffsetBase)
                               headerCode)
            end

        fun epilogueCode preFrameSizeLeft =
            let
              val padSize = preFrameSize - preFrameSizeLeft
            in
              [
                I.MOVL (I.R I.ESP, I.R_ I.EBP),
                I.POPL (I.R I.EBP)
              ] @
              addSPWithLink padSize
            end

        val subst =
            {
              registers = subst,
              variables = varSubst,
              preFrameEnd = SOME (8 + preFrameSize),
              postFrameStart = SOME (~allocSize),
              prologueCode = prologueCode,
              epilogueCode = epilogueCode
            } : subst

        val newBody = map (substInsn subst) body

      in
        ({
           frameBitmap = frameBitmap,
(*
           entries = entries,
*)
           body = newBody,
           preFrameAligned = preFrameAligned,
           loc = loc
         } : I.cluster,
         labelRefs)
      end

  fun allocClusterList (cluster::clusterList) =
      let
        val (cluster, labelRefs) = allocCluster cluster
        val (clusters, labelRefs2) = allocClusterList clusterList
      in
        (cluster::clusters, unionLabelRefs (labelRefs, labelRefs2))
      end
    | allocClusterList nil =
      (nil, emptyLabelRef)

  fun allocate ({entryCode, clusters, data, toplevelStubCode,
                       ...}:I.program) =
      let

        val (clusters, labelRefs) = allocClusterList clusters

        val labelRefs =
            foldl (fn (insn, labelRefs) =>
                      let
                        val {defs, uses, ...} = defUse insn
                      in
                        unionLabelRefs (labelRefs, gatherLabelRefs uses)
                      end)
                  labelRefs
                  entryCode

        val globalRefs = SSet.listItems (#globalRefs labelRefs)
        val externRefs = SSet.listItems (#extDataRefs labelRefs)
        val extFunStubs = SSet.listItems (#extCodeRefs labelRefs)


(*

        val entry =
            [
              I.Data,
              I.Align {align = 4, filler = 0wx90},
              I.Label "require"
            ] @
            map (fn x => I.EntryLabel (x^"$require")) globalRefs @
            [



              I.JMP  (I.M_
              I.CALL (I.I_ (I.LABEL "entry")),






              I.Text,
              I.Align {align = 4, filler = 0wx90},
              I.Label "entry",
              I.PUSHL (I.R_ I.EBP),
              I.MOVL (I.R I.EBP, I.R_ I.ESP),
              I.ANDL (I.R I.ESP, I.I_ (I.WORD 0wxfffffff0)),
              I.CALL (I.I_ (I.LABEL toplevelEntry)),
              I.MOVB (I.M (I.ABSADDR ()), I.I_ (I.WORD 0xc3))



              I.MOVL (I.R I.ESP, I.R_ I.EBP),
              I.POPL (I.R I.EBP),
              I.RET NONE



            ]


              I.EntryLabel

              .data
              .align 4, 0x90
              require:
              A.x$require:
              A.y$require:
                   jmp evalTopLevel

              .text
              .align 4, 0x90
              evalTopLevel:
                   align stack
                   call toplevel
                   movb 0xc3, (require)
                   ret





              I.Align {align = 4, filler = 0wx90},


        val extVarRefs = SSet.listItems externRefs





              I.Align {align = 4, filler = 0wx90},
              I.Label entryLabel,





              I.PUSHL (I.R_ I.EBP),
              I.MOVL (I.R I.EBP, I.R_ I.ESP),




            ]





        val entry =
            [
              I.Align {align = 4, filler = 0wx90},
              I.EntryLabel smlMainLabel,
              I.PUSHL (I.R_ I.EBP),
              I.MOVL (I.R I.EBP, I.R_ I.ESP),
              I.ANDL (I.R I.ESP, I.I_ (I.WORD 0wxfffffff0)),
              I.CALL (I.I_ (I.LABEL toplevelEntry)),
              I.MOVL (I.R I.ESP, I.R_ I.EBP),
              I.POPL (I.R I.EBP),
              I.RET NONE
            ]






*)



        val program =
            {
              entryCode = entryCode,
(*
              toplevel = toplevel,
*)
              clusters = clusters,
              data = data,
              globalReferences = globalRefs,
              externReferences = externRefs,
              externCodeStubs = extFunStubs,
              toplevelStubCode = toplevelStubCode
            } : I.program
      in
        program
      end

end
