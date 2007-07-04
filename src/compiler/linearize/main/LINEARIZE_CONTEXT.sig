(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @author NGUYEN Huu-Duc
 * @version $Id: LINEARIZE_CONTEXT.sig,v 1.15 2007/04/19 05:06:52 ducnh Exp $
 *)
signature LINEARIZE_CONTEXT =
sig

  (***************************************************************************)

  (**
   * the context allocated for each linearization of a function.
   *)
  type context

  type label = SymbolicInstructions.address

  (** indicates position within the function of the expression
   * which is the current target of linearization *)
  datatype position =
           (** no more computation in function. *) Tail
         | (** value is returned to the caller. *) Result
         | (** value is bound to a variable. *)
           Bound of 
             {
              boundVarInfoList : SymbolicInstructions.varInfo list,
              boundTyList : ANormal.ty list,
              variableSizeList : SymbolicInstructions.size list
             }

  (***************************************************************************)

  (** create initial context *)
  val createInitialContext : unit -> context

  (**
   * creates a new context for a function.
   * @params context (functionId, functionInfo, functionLoc)
   * @param context a current context
   * @param functionId id of the function.
   * @param functionInfo funinfo of the function.
   * @param functionLoc the location of the function.
   * @return a new context which is used to linearize the the function.
   *)
  val createContext
      : context
        -> (ANormal.funDecl * Loc.loc)
        -> context

  (** create a label unique within this linearization
   * @params context
   * @param context the context
   * @return a label id which can be used as a unique label
   *)
  val createLabel : context -> label

  (** create a variable name unique within this linearization
   * @params context
   * @param context the context
   * @return a string which can be used as a unique variable name
   *)
  val createLocalVarID : context -> SymbolicInstructions.varid

  (** register a binding information of a local variable. *)
  val addVarBind : context -> ANormal.varInfo -> unit

  (** get the list of all local bindings in the current function *)
  val getVarBinds : context -> ANormal.varInfo list

  val getPosition : context -> position
  val notTailPosition : context -> context
  val setBoundPosition
      : (context * SymbolicInstructions.varInfo list * ANormal.ty list * SymbolicInstructions.size list)
        -> context
  (**
   *  creates a new context for linearization of an expression guarded by
   * 'handle' clause.
   * <pre>
   *   e1 handle pat => e2
   * </pre>
   * To linearize e1, use a new context obtained by enterGuardedCode.
   *)
  val enterGuardedCode : (context * label) -> context

  (**
   *  store the location of the enclosing expression into the context.
   * <p>
   * <code>if e1 then e2 else e3</code>
   * </p>
   * <p>
   *  The 'if' expression is the enclosing expression of e1, e2 and e3.
   * We should set the location of the 'if' expression in the context
   * before linearize e1, e2 and e3.
   * </p>
   *)
  val setLocOfEnclosingExp : (context * Loc.loc) -> context

  (**
   * get the location of the enclosing expression.
   *)
  val getLocOfEnclosingExp : context -> Loc.loc

  (** get the type of the result of the function which is now linearized. *)
  val getResultTypeList : context -> ANormal.ty list

  val getResultSizeList : context -> SymbolicInstructions.size list

  (** add constant and returns its label. *)
  val addStringConstant : context -> string -> label

  val getConstantInstructions
      : context -> SymbolicInstructions.instruction list

  val getEnclosingHandlers : context -> label list


  val ANVarInfoToVarInfo : ANormal.varInfo -> SymbolicInstructions.varInfo

  val ANExpToSize : ANormal.anexp -> SymbolicInstructions.size

  (***************************************************************************)
                                    
end
