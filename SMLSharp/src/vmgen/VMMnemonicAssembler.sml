structure VMAsmLabelEnv =
struct
  type map = int list * int list * int SEnv.map

  fun find ((_, _, map):map, key) = SEnv.find (map, key)

  fun nth (l, n) =
      let
        fun f (h::t, 1) = SOME h
          | f (h::t, n) = f (t, n - 1)
          | f (nil, n) = NONE
      in
        if n < 1 then NONE else f (l, n)
      end

  fun findLocal ((fwd, bwd, _):map, key) =
      if key > 0 then nth (fwd, key) else nth (bwd, ~key)
end

structure VMAsmError =
struct
  exception LabelNotFound of VMMnemonic.label
  exception LabelDoubled of string
  exception Assemble of VMMnemonic.instruction
end


functor VMMnemonicAssemblerFn
(
  Asm : VM_MNEMONIC_ASSEMBLER_FN
        where type labelEnv = VMAsmLabelEnv.map
          and type buf = Word8Array.array
) : sig

  exception LabelNotFound of VMMnemonic.label
  exception LabelDoubled of string
  exception Assemble of VMMnemonic.instruction
  val assemble
      : VMMnemonic.instruction list ->
        Word8Array.array
        * int SEnv.map
        * {offset: int, size: word, extern: VMMnemonic.extern} list
        * (int * string) list

end =
struct

  structure I = VMMnemonic

  open VMAsmError

  local

    fun pass1 pc bwdLocals labels nil =
        (pc, nil, labels, nil, nil, nil)
      | pass1 pc bwdLocals labels (insn::insns) =
        case insn of
          I.Loc loc =>
          let
            val (size, fwdLocals, labels, exts, locs, insns) =
                pass1 pc (pc::bwdLocals) labels insns
          in
            (size, fwdLocals, labels, exts, (pc, loc)::locs, insns)
          end
        | I.Label l =>
          (case SEnv.find (labels, l) of
             SOME x => raise LabelDoubled l
           | NONE =>
             pass1 pc bwdLocals (SEnv.insert (labels, l, pc)) insns)
        | I.LocalLabel =>
          let
            val (size, fwdLocals, labels, exts, locs, insns) =
                pass1 pc (pc::bwdLocals) labels insns
          in
            (size, pc::fwdLocals, labels, exts, locs, insns)
          end
        | x =>
          let
            val {next, externs} = Asm.property (pc, insn)
            val (size, fwdLocals, labels, exts, locs, insns) =
                pass1 next bwdLocals labels insns
          in
            (size, fwdLocals, labels, externs @ exts, locs,
             ((fwdLocals, bwdLocals, labels), insn)::insns)
          end

    fun pass2 buf pc nil = buf
      | pass2 buf pc ((labelEnv, insn)::insns) =
        pass2 buf (Asm.assemble (labelEnv, buf, pc, insn)) insns

  in

  fun assemble insnList =
      let
        val (size, _, labels, exts, locs, insns) =
            pass1 0 nil SEnv.empty insnList
        val buf =
            pass2 (Word8Array.array (size, 0w0)) 0 insns
      in
        (buf, labels, exts, locs)
      end

  end
end

structure VMMnemonicAssembler32LE =
    VMMnemonicAssemblerFn(
        VMMnemonicAssemblerFn32(structure LabelEnv = VMAsmLabelEnv
                                structure Dump = SerializeLE
                                structure Error = VMAsmError))
structure VMMnemonicAssembler32BE =
    VMMnemonicAssemblerFn(
        VMMnemonicAssemblerFn32(structure LabelEnv = VMAsmLabelEnv
                                structure Dump = SerializeBE
                                structure Error = VMAsmError))
structure VMMnemonicAssembler64LE =
    VMMnemonicAssemblerFn(
        VMMnemonicAssemblerFn64(structure LabelEnv = VMAsmLabelEnv
                                structure Dump = SerializeLE
                                structure Error = VMAsmError))
structure VMMnemonicAssembler64BE =
    VMMnemonicAssemblerFn(
        VMMnemonicAssemblerFn64(structure LabelEnv = VMAsmLabelEnv
                                structure Dump = SerializeBE
                                structure Error = VMAsmError))
