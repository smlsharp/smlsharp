(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
signature RBUCONTEXT = sig

  type context

  val isBoundTypeVariable : context * int -> bool

  val findVariable : context * ID.id -> RBUCalc.varInfo option

  val insertVariable : context -> RBUCalc.varInfo -> context 
   
  val insertVariables : context -> (RBUCalc.varInfo list) -> context 

  val insertVariableWithId : context -> (ID.id * RBUCalc.varInfo) -> context 
   

  val insertVariablesWithId : context -> (ID.id * RBUCalc.varInfo) list -> context 

  val mergeVariable : context -> RBUCalc.varInfo -> (RBUCalc.varInfo * context)

  val mergeVariables : context -> (RBUCalc.varInfo list) -> (RBUCalc.varInfo list * context)

  val lookupTag : context -> (int * Loc.loc) -> (RBUCalc.rbuexp * context)

  val lookupSize : context -> (int * Loc.loc) -> (RBUCalc.rbuexp * context)

  val lookupIndex : context -> (string * int * Loc.loc) -> (RBUCalc.rbuexp * context) 

  val representationOf : context * int -> AnnotatedTypes.btvRep

  val listFreeVariables : context -> RBUCalc.varInfo list

  val listExtraLocalVariables : context -> RBUCalc.varInfo list

  val getFrameBitmapIDs : context -> ID.Set.set

  val registerFrameBitmapID : context -> ID.id -> unit

  (**************************************************************)

  val createEmptyContext : unit -> context

  val createContext : context -> AnnotatedTypes.btvEnv -> context

  val extendBtvEnv : context -> AnnotatedTypes.btvEnv -> context
  val fullyExtendBtvEnv : context -> AnnotatedTypes.btvEnv -> context

end
