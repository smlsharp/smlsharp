(* -*- sml -*- *)

signature SMLSHARP_CONFIGURATION =
sig

  val Version : string
  val BinaryVersion : {major: word, minor: word}
  val ReleaseDate : string
  val BuildRoot : string
  val SourceRoot : string
  val RuntimeFileName : string
  val RuntimePath : string
  val RuntimeDLLPath : string
  val LibDirectory : string
  val PreludeFileName : string
  val CompiledPreludeFileName : string
  val PreludePath : string
  val MinimumPreludeFileName : string
  val MinimumPreludePath : string
  val Platform : string
  val NativeTarget : string
  val CC : string
  val LD : string
  val AR : string
  val RANLIB : string
  val LDFLAGS : string
  val LIBS : string
  val DLEXT : string
  datatype byteOrder = BigEndian | LittleEndian
  val NativeByteOrder : byteOrder

end
