(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @author Nguyen Huu-Duc
 * @version $Id: LinearizeContext.sml,v 1.16 2007/04/19 05:06:52 ducnh Exp $
 *)
structure LinearizeContext : LINEARIZE_CONTEXT =
struct

  (***************************************************************************)

  structure BT = BasicTypes
  structure SI = SymbolicInstructions
  structure AN = ANormal
  structure TMap = IEnv
  structure CT = ConstantTerm

  (***************************************************************************)

  structure const_ord:ordsig = struct

    type ord_key = CT.constant

    val compare = CT.compare

  end

  structure ConstEnv = BinaryMapFn(const_ord)


  datatype position =
           Tail
         | Result
         | Bound of 
           {
            boundVarInfoList : SI.varInfo list,
            variableSizeList : SI.size list,
            boundTyList : AN.ty list
           }

  type label = SymbolicInstructions.address


  (**
   * the context allocated for each translation of a function body
   *)
  type functionContext =
       {
         (** an ID used as a prefix to rename local variable names *)
         functionID : SI.varid,
         (** varInfo list of local variables bound in the function *)
         localBindingsRef : AN.varInfo list ref,
         (** the position of expression within the function. *)
         position : position,
         (** the bitmap type of result of the function *)
         resultTypeList : AN.ty list,
         resultSizeList : SI.size list,
         (** the location of the expression enclosing the current expression.*)
         locOfEnclosingExp : Loc.loc,
         (** instructions for holding constants *)
         constantInstructions : SI.instruction list ref,
         (** start labels of enclosing codes guarded by 'handle'. *)
         enclosingGuardedCodes : label list
       }

  type context = functionContext

  (***************************************************************************)

  (* ToDO : this function is duplicated in Linearizer. They should be moved
     to another structure. *)
  fun ANVarInfoToVarInfo ({id, displayName, ...} : AN.varInfo) =
      {id = id, displayName = displayName} : SI.varInfo

  fun ANExpToSize (AN.ANCONSTANT {value = CT.WORD 0w1,...}) = SI.SINGLE
    | ANExpToSize (AN.ANCONSTANT {value = CT.WORD 0w2,...}) = SI.DOUBLE
    | ANExpToSize (AN.ANVAR {varInfo,...}) = SI.VARIANT (ANVarInfoToVarInfo varInfo)
    | ANExpToSize _ = raise Control.Bug "invalid size"


  fun createLabel functionContext = ID.generate()

  fun createLocalVarID functionContext = ID.generate()


  fun addVarBind ({localBindingsRef, ...} : functionContext) varInfo =
      localBindingsRef := (varInfo :: (!localBindingsRef))

  fun getVarBinds ({localBindingsRef, ...} : functionContext) =
      !localBindingsRef


  fun getPosition ({position, ...} : functionContext) = position

  local
    fun changePosition (functionContext : functionContext, newPosition) =

        {
          functionID = #functionID functionContext,
          position = newPosition,
          resultTypeList = #resultTypeList functionContext,
          resultSizeList = #resultSizeList functionContext,
          locOfEnclosingExp = #locOfEnclosingExp functionContext,
          constantInstructions = #constantInstructions functionContext,
          localBindingsRef = #localBindingsRef functionContext,
          enclosingGuardedCodes = #enclosingGuardedCodes functionContext
        }
        : functionContext
  in

  (** get new context indicating that it is not at tail position in the
   * function. *)
  fun notTailPosition (functionContext : functionContext) =
      let
        val currentPosition = #position functionContext
        val newPosition =
          case currentPosition of
            Tail => Result 
          | _ => currentPosition
      in changePosition (functionContext, newPosition) end

  fun setBoundPosition (functionContext : functionContext, boundVarInfoList, boundTyList, variableSizeList) =
      changePosition 
          (
           functionContext, 
           Bound 
               {
                boundVarInfoList = boundVarInfoList,
                boundTyList = boundTyList,
                variableSizeList = variableSizeList
               }
          )

  (**
   * add enclosingGuardedCodes, and changes position to non-tail.
   *)
  fun enterGuardedCode (functionContext : functionContext, label) =
      let
        val ctx = 
            {
              functionID = #functionID functionContext,
              position = #position functionContext,
              resultTypeList = #resultTypeList functionContext,
              resultSizeList = #resultSizeList functionContext,
              locOfEnclosingExp = #locOfEnclosingExp functionContext,
              constantInstructions = #constantInstructions functionContext,
              localBindingsRef = #localBindingsRef functionContext,
              enclosingGuardedCodes =
              label :: #enclosingGuardedCodes functionContext
            } : functionContext
      in
        notTailPosition ctx
      end

  fun getEnclosingHandlers (functionContext : functionContext) =
      #enclosingGuardedCodes functionContext

  end

  fun setLocOfEnclosingExp (functionContext : functionContext, loc) =
        {
          functionID = #functionID functionContext,
          position = #position functionContext,
          resultTypeList = #resultTypeList functionContext,
          resultSizeList = #resultSizeList functionContext,
          locOfEnclosingExp = loc,
          constantInstructions = #constantInstructions functionContext,
          localBindingsRef = #localBindingsRef functionContext,
          enclosingGuardedCodes = #enclosingGuardedCodes functionContext
        }
        : functionContext
  fun getLocOfEnclosingExp (functionContext : functionContext) =
      #locOfEnclosingExp functionContext

  fun getResultTypeList ({resultTypeList, ...} : functionContext) = resultTypeList

  fun getResultSizeList ({resultSizeList, ...} : functionContext) = resultSizeList
                      
  fun addStringConstant
          (context as {constantInstructions, ...} : functionContext) string =
      let val label = createLabel context
      in
        constantInstructions :=
        ([SI.Label label, SI.ConstString {string = string}]
         @ (!constantInstructions));
        label
      end

  fun getConstantInstructions ({constantInstructions, ...} : functionContext) =
      !constantInstructions

  fun createInitialContext () =
      {
       functionID = ID.generate(),
       localBindingsRef = ref [],
       position = Tail,
       resultTypeList = [AN.ATOM], (* ToDo : UNBOXED ? *)
       resultSizeList = [SI.SINGLE],
       locOfEnclosingExp = Loc.noloc,
       constantInstructions = ref [],
       enclosingGuardedCodes = []
      } : functionContext

  fun createContext (enclosingContext : functionContext) (funDecl : AN.funDecl, loc) =
      let
        val context =
            {
              functionID = #codeId funDecl,
              localBindingsRef = #localBindingsRef enclosingContext,
              position = Tail,
              resultTypeList = #resultTyList funDecl,
              resultSizeList = map ANExpToSize (#resultSizeExpList funDecl),
              locOfEnclosingExp = loc,
              constantInstructions = ref [],
              enclosingGuardedCodes = []
            }
        val _ = app (addVarBind context) (#argVarList funDecl)
      in
        context
      end


end

