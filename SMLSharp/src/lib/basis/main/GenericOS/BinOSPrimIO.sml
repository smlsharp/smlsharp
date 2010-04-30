(* posix-bin-prim-io.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * This implements the UNIX version of the OS specific binary primitive
 * IO structure.  The Text IO version is implemented by a trivial translation
 * of these operations (see posix-text-prim-io.sml).
 *
 *)
structure BinOSPrimIO : OS_PRIM_IO = 
struct

  structure PrimIO = BinPrimIO
  structure Vec = Word8Vector
  structure PIO = OSPrimIOBase

  type file_desc = PIO.file_desc

  val bufferSzB = 4096

  val mkReader = PIO.mkBinReader
  val mkWriter = PIO.mkBinWriter

  fun openRd name =
      mkReader {fd = PIO.fileOpen(name, "rb"), initBlkMode = true, name = name}

  fun openWr name =
      mkWriter
          {
            fd = PIO.fileOpen(name, "wb"),
            name = name,
            initBlkMode = true,
            appendMode = false,
            chunkSize = bufferSzB
          }

  fun openApp name =
      mkWriter
          {
            fd = PIO.fileOpen(name, "ab"),
            name = name,
            initBlkMode = true,
            appendMode = true,
            chunkSize = bufferSzB
          }

end 

