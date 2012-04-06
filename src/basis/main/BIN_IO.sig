include "Word8Vector.smi"
include "../../smlnj/Basis/IO/prim-io-bin.smi"
include "IMPERATIVE_IO.sig"

signature BIN_IO =
sig
  include IMPERATIVE_IO
    where type StreamIO.vector = Word8Vector.vector
    where type StreamIO.elem = SMLSharp.Word8.word
    where type StreamIO.reader = BinPrimIO.reader
    where type StreamIO.writer = BinPrimIO.writer
    where type StreamIO.pos = BinPrimIO.pos
  val openIn : string -> instream
  val openOut : string -> outstream
  val openAppend : string -> outstream
end
