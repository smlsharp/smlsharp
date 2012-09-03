signature VM_MNEMONIC_ASSEMBLER_FN =
sig

  type labelEnv
  type buf

  val property
      : int * VMMnemonic.instruction ->
        {next: int,
         externs: {offset: int, size: word,
                   extern: VMMnemonic.extern} list}
  val assemble
      : labelEnv * buf * int * VMMnemonic.instruction -> int

end
