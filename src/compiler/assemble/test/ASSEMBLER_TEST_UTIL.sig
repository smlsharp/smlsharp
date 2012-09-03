(**
 * utility functions for assembler unit test.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ASSEMBLER_TEST_UTIL.sig,v 1.5 2006/02/20 06:52:03 kiyoshiy Exp $
 *)
signature ASSEMBLER_TEST_UTIL =
sig

  (***************************************************************************)

  val assertEqualInstruction
      : Instructions.instruction
        -> Instructions.instruction
        -> Instructions.instruction

  val assertEqualInstructionList
      : Instructions.instruction list
        -> Instructions.instruction list
        -> Instructions.instruction list

  val assembledFunInfo
      : SymbolicInstructions.funInfo
        -> SymbolicInstructions.instruction list
        -> Instructions.instruction
  
  val makeMonoFunInfo
      : {
          atoms : string list,
          pointers : string list
        }
        -> SymbolicInstructions.funInfo

  val funEntrySize : SymbolicInstructions.funInfo -> Word32.word

  val makeVarInfo : string -> SymbolicInstructions.varInfo

  val nameToAddress : string -> SymbolicInstructions.address

  val nameToVarID : string -> SymbolicInstructions.varid

  val getEntry
      : SymbolicInstructions.funInfo
        -> SymbolicInstructions.instruction list
        -> string
        -> SlotMap.index

  (***************************************************************************)

end
