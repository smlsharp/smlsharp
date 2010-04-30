structure ELFConst =
struct

  (* EI_CLASS *)
  val ELFCLASS32      = 0w1 : Word8.word
  val ELFCLASS64      = 0w2 : Word8.word

  (* EI_DATA *)
  val ELFDATA2LSB     = 0w1 : Word8.word
  val ELFDATA2MSB     = 0w2 : Word8.word

  (* version *)
  val EV_CURRENT      = 0w1 : Word8.word

  (* file type *)
  val ET_NONE         = 0w0 : word
  val ET_REL          = 0w1 : word
  val ET_EXEC         = 0w2 : word
  val ET_DYN          = 0w3 : word

  (* machine *)
  val EM_NONE         = 0w0 : word
  val EM_SPARC        = 0w2 : word
  val EM_386          = 0w3 : word
  val EM_SPARCV8      = 0w18 : word
  val EM_PPC          = 0w20 : word
  val EM_PPC64        = 0w21 : word
  val EM_SPARCV9      = 0w43 : word

  (* section index *)
  val SHN_UNDEF       = 0w0 : Word32.word

  (* section types *)
  val SHT_NULL        = 0w0 : Word32.word
  val SHT_PROGBITS    = 0w1 : Word32.word
  val SHT_SYMTAB      = 0w2 : Word32.word
  val SHT_STRTAB      = 0w3 : Word32.word
  val SHT_NOTE        = 0w7 : Word32.word
  val SHT_NOBITS      = 0w8 : Word32.word
  val SHT_REL         = 0w9 : Word32.word
  val SHT_LOUSER      = 0wx80000000 : Word32.word

  (* section flags *)
  val SHF_WRITE       = 0wx1 : Word32.word
  val SHF_ALLOC       = 0wx2 : Word32.word
  val SHF_EXECINSTR   = 0wx4 : Word32.word

  (* symbol bindings *)
  val STB_LOCAL       = 0w0 : Word8.word
  val STB_GLOBAL      = 0w1 : Word8.word
  val STB_LOPROC      = 0w13 : Word8.word

  (* symbol types *)
  val STT_NOTYPE      = 0w0 : Word8.word

  (* relocation types *)
  val R_NONE          = 0w0 : Word32.word
  val R_32            = 0w1 : Word32.word

end
