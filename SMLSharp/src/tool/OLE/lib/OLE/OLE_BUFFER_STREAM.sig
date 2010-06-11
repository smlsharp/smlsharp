(**
 * abstraction of accessors on Word8Array and UnmanagedMemory.
 * @copyright (c) 2010, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OLE.sml,v 1.27.22.2 2010/05/09 03:58:29 kiyoshiy Exp $
 *)
signature OLE_BUFFER_STREAM =
sig

  type instream
  type outstream
  val openArrayIn : Word8Array.array -> instream
  val openUnmanagedMemoryIn : (UnmanagedMemory.address * int) -> instream
  val openArrayOut : Word8Array.array -> outstream
  val openUnmanagedMemoryOut : (UnmanagedMemory.address * int) -> outstream
  val input : instream -> (Word8.word * instream)
  val output : (outstream * Word8.word) -> outstream
  val inputWord32 : instream -> (Word32.word * instream)
  val outputWord32 : (outstream * Word32.word) -> outstream
  val skipIn : (instream * int) -> instream
  val skipOut : (outstream * int) -> outstream
  val getPosIn : instream -> int
  val getPosOut : outstream -> int

end;
