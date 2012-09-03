(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: CODEENV.sig,v 1.2 2007/04/19 05:06:52 ducnh Exp $
 *)

signature CODEENV = sig

  datatype constant =
           Int of BasicTypes.SInt32
         | Word of BasicTypes.UInt32
         | Real of string
         | Float of string
         | Char of BasicTypes.UInt32

  type codeEnv

  val empty : codeEnv

  val constToInstruction : constant * SymbolicInstructions.entry -> SymbolicInstructions.instruction

  val entryToString : SymbolicInstructions.entry -> string

  val addConstant : codeEnv * SymbolicInstructions.entry * constant -> codeEnv

  val wordOf : codeEnv * SymbolicInstructions.entry -> BasicTypes.UInt32 option

  val intOf : codeEnv * SymbolicInstructions.entry -> BasicTypes.SInt32 option

  val realOf : codeEnv * SymbolicInstructions.entry -> string option

  val floatOf : codeEnv * SymbolicInstructions.entry -> string option

  val charOf : codeEnv * SymbolicInstructions.entry -> BasicTypes.UInt32 option

end
