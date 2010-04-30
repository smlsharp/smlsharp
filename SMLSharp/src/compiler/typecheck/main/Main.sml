(*
 * run the VM simulator
 * @copyright (c) 2006, Tohoku University.
 *)
structure Main =
struct

  (***************************************************************************)

  val _ = Top.printBinds := true;
  val _ = Top.switchTrace := true;

  (* initialize virtual machine *)
  val heapSize = 0w10000 : BasicTypes.UInt32
  val frameStackSize = 0w10000 : BasicTypes.UInt32
  val handlerStackSize = 0w10000 : BasicTypes.UInt32
  val globalCount = 0w10000 : BasicTypes.UInt32
  val VM =
      VM.initialize
          {
            heapSize = heapSize,
            frameStackSize = frameStackSize,
            handlerStackSize = handlerStackSize,
            globalCount = globalCount,
            standardInput = TextIOChannel.openIn{inStream = TextIO.stdIn},
            standardOutput =
            TextIOChannel.openOut{outStream = TextIO.stdOut},
            standardError =
            TextIOChannel.openOut{outStream = TextIO.stdErr}
          }

  fun main () =
      Top.run
      {
        session = VMSession.openSession {VM = VM},
        isInteractive = true,
        initialSource = TextIOChannel.openIn {inStream = TextIO.stdIn},
        initialSourceName = "stdIn",
        standardOutput =  TextIOChannel.openOut {outStream = TextIO.stdOut},
        standardError =  TextIOChannel.openOut {outStream = TextIO.stdErr}
      }

  val _ = main();
  (***************************************************************************)

end;
