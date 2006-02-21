(**
 * This module abstracts a session with a VM emulator written in SML.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: SessionMaker_ML.sml,v 1.4 2005/10/24 07:28:26 kiyoshiy Exp $
 *)
structure SessionMaker_ML : SESSION_MAKER =
struct

  (***************************************************************************)

  fun openSession {STDIN, STDOUT, STDERR} =
      let
        (* initialize virtual machine *)
        val heapSize = 0w100000 : BasicTypes.UInt32
        val frameStackSize = 0w10000 : BasicTypes.UInt32
        val handlerStackSize = 0w10000 : BasicTypes.UInt32
        val globalCount = 0w10000 : BasicTypes.UInt32
        val VM =
            VM.initialize
            {
              name = "VMEmulatorTestDriver",
              arguments = [],
              heapSize = heapSize,
              frameStackSize = frameStackSize,
              handlerStackSize = handlerStackSize,
              globalCount = globalCount,
              standardInput = STDIN,
              standardOutput = STDOUT,
              standardError = STDOUT,
              primitives = PrimitiveTable.map,
              debuggerOpt = NONE
            }
        val session = VMSession.openSession {VM = VM}
      in
        session
      end

  (***************************************************************************)

end;
