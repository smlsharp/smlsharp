(** symbolic code generator context
 * @copyright (c) 2006, Tohoku University.
 * @author Nguyen Huu-Duc
 * @version $Id: SIGCONTEXT.sig,v 1.3 2007/08/08 14:23:59 kiyoshiy Exp $
 *)
signature SIGCONTEXT = sig

  type context

  datatype varRoot = 
           CONST of ConstantTerm.constant
         | VAR of SymbolicInstructions.entry
         | CLOSURE of SymbolicInstructions.address * SymbolicInstructions.entry

  datatype position = Tail | NonTail

  val createInitialContext : Loc.loc -> context

  val createContext : context -> IntermediateLanguage.functionCode -> context

  val rootEntry : context -> SymbolicInstructions.entry -> SymbolicInstructions.entry 

  val rootOf : context -> SymbolicInstructions.entry -> varRoot option

  val varOf : context -> SymbolicInstructions.entry -> SymbolicInstructions.entry option

  val constOf : context -> SymbolicInstructions.entry -> ConstantTerm.constant option

  val closureOf : context -> SymbolicInstructions.entry -> 
                  (SymbolicInstructions.address * SymbolicInstructions.entry) option

  val wordOf : context -> SymbolicInstructions.entry -> BasicTypes.UInt32 option

  val intOf : context -> SymbolicInstructions.entry -> BasicTypes.SInt32 option

  val largeIntOf : context -> SymbolicInstructions.entry -> BigInt.int option

  val realOf : context -> SymbolicInstructions.entry -> string option

  val floatOf : context -> SymbolicInstructions.entry -> string option

  val charOf : context -> SymbolicInstructions.entry -> char option

  val stringOf : context -> SymbolicInstructions.entry -> string option

  val findFirstConstantBind : context -> ConstantTerm.constant -> SymbolicInstructions.entry option

  val addStringConstant : context -> string -> SymbolicInstructions.address

  val addLocalVariable : context -> IntermediateLanguage.varInfo -> SymbolicInstructions.entry

  val addConstantBind : context -> (ConstantTerm.constant * SymbolicInstructions.entry) -> context

  val addVariableBind : context -> (SymbolicInstructions.entry * SymbolicInstructions.entry) -> context

  val addClosureBind : context -> 
                       (SymbolicInstructions.address * SymbolicInstructions.entry * SymbolicInstructions.entry) -> 
                       context

  val setLocation : context -> Loc.loc -> context

  val getLocation : context -> Loc.loc

  val setPosition : context -> position -> context

  val getPosition : context -> position

  val enterGuardedCode : context -> SymbolicInstructions.address -> context

  val getEnclosingHandlers : context -> SymbolicInstructions.address list

  val getLocalVariables : context -> IntermediateLanguage.varInfo list

  val getConstantInstructions : context -> SymbolicInstructions.instruction list

end
