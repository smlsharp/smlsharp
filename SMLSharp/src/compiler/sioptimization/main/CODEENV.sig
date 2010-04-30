(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: CODEENV.sig,v 1.4 2007/09/24 10:35:30 matsu Exp $
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
