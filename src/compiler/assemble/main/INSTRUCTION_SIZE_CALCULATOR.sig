(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: INSTRUCTION_SIZE_CALCULATOR.sig,v 1.3 2006/02/18 04:59:16 ohori Exp $
 *)
signature INSTRUCTION_SIZE_CALCULATOR =
sig

  (***************************************************************************)

  val wordsOfFunEntry : SymbolicInstructions.funInfo -> BasicTypes.UInt32

  val wordsOfInstruction
      : SymbolicInstructions.instruction -> BasicTypes.UInt32

  (***************************************************************************)

end
