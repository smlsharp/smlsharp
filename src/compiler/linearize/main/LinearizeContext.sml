(**
 * @author YAMATODANI Kiyoshi
 * @author Nguyen Huu Duc
 * @version $Id: LinearizeContext.sml,v 1.15 2007/01/21 13:41:32 kiyoshiy Exp $
 *)
structure LinearizeContext : LINEARIZE_CONTEXT =
struct

  (***************************************************************************)

  structure BT = BasicTypes
  structure SI = SymbolicInstructions
  structure AN = ANormal
  structure TMap = IEnv
  structure T = Types

  (***************************************************************************)

  datatype position =
           Tail
         | Result
         | Bound of SI.varInfo * AN.ty

  type label = SymbolicInstructions.address

  (**
   * the context allocated for each invocation of the linearize function
   *)
  type linearizeContext =
       {
         functionCodesRef : SI.functionCode list ref
       }

  (**
   * the context allocated for each translation of a function body
   *)
  type functionContext =
       {
         (** an ID used as a prefix to rename local variable names *)
         functionID : SI.varid,
         (** a map from type variables to size variables *)
         sizeMap : SI.size TMap.map,
         (** the position of expression within the function. *)
         position : position,
         (** varInfo list of local variables bound in the function *)
         localBindingsRef : AN.varInfo list ref,
         (** the bitmap type of result of the function *)
         resultType : AN.ty,
         (** the location of the expression enclosing the current expression.
          *)
         locOfEnclosingExp : Loc.loc,
         (** instructions for holding constants *)
         constantInstructions : SI.instruction list ref,
         (** the shared context for this translation *)
         linearizeContext : linearizeContext,
         (** start labels of enclosing codes guarded by 'handle'. *)
         enclosingGuardedCodes : label list
       }

  type context = functionContext

  (***************************************************************************)

  (* ToDO : this function is duplicated in Linearizer. They should be moved
     to another structure. *)
  fun ANVarInfoToVarInfo ({id, displayName, ...} : AN.varInfo) =
      {id = id, displayName = displayName} : SI.varInfo

  fun createLabel functionContext = T.newVarId()

  fun createLocalVarID functionContext = T.newVarId()

  fun addVarBind ({localBindingsRef, ...} : functionContext) varInfo =
      localBindingsRef := (varInfo :: (!localBindingsRef))

  fun getVarBinds ({localBindingsRef, ...} : functionContext) =
      !localBindingsRef

  fun getPosition ({position, ...} : functionContext) = position

  local
    fun changePosition (functionContext : functionContext, newPosition) =
        {
          functionID = #functionID functionContext,
          sizeMap = #sizeMap functionContext,
          position = newPosition,
          linearizeContext = #linearizeContext functionContext,
          resultType = #resultType functionContext,
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

  fun setBoundPosition (functionContext : functionContext, varid, ty) =
      changePosition (functionContext, Bound (varid, ty))

  (**
   * add enclosingGuardedCodes, and changes position to non-tail.
   *)
  fun enterGuardedCode (functionContext : functionContext, label) =
      let
        val ctx = 
            {
              functionID = #functionID functionContext,
              sizeMap = #sizeMap functionContext,
              position = #position functionContext,
              linearizeContext = #linearizeContext functionContext,
              resultType = #resultType functionContext,
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
          sizeMap = #sizeMap functionContext,
          position = #position functionContext,
          linearizeContext = #linearizeContext functionContext,
          resultType = #resultType functionContext,
          locOfEnclosingExp = loc,
          constantInstructions = #constantInstructions functionContext,
          localBindingsRef = #localBindingsRef functionContext,
          enclosingGuardedCodes = #enclosingGuardedCodes functionContext
        }
        : functionContext
  fun getLocOfEnclosingExp (functionContext : functionContext) =
      #locOfEnclosingExp functionContext

  fun getResultType ({resultType, ...} : functionContext) = resultType

  fun getSize ({sizeMap, ...} : functionContext) ty =
      case ty of 
        AN.ATOM => SI.SINGLE
      | AN.BOXED => SI.SINGLE
      | AN.DOUBLE => SI.DOUBLE
      | AN.TYVAR tyvar =>
        if !Control.enableUnboxedFloat
        then
          case TMap.find(sizeMap,tyvar) of
            SOME size => size
          | _ => raise Control.Bug ("tyvar not found" ^ (Int.toString tyvar))
        else SI.SINGLE
                      
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

  fun addFunctionCode
          ({linearizeContext = {functionCodesRef, ...}, ...} : functionContext)
          functionCode =
      functionCodesRef := functionCode :: (!functionCodesRef)

  fun getFunctionCodes
      ({linearizeContext = {functionCodesRef, ...}, ...} : functionContext) =
      !functionCodesRef

  fun createInitialContext () =
      let
        val linearizeContext =
            {
              functionCodesRef = ref []
            }
            : linearizeContext
      in
        {
          functionID = T.newVarId(),
          sizeMap = TMap.empty,
          localBindingsRef = ref [],
          position = Tail,
          resultType = AN.ATOM, (* ToDo : UNBOXED ? *)
          locOfEnclosingExp = Loc.noloc,
          constantInstructions = ref [],
          linearizeContext = linearizeContext,
          enclosingGuardedCodes = []
        }
        : functionContext
      end

  fun createContext
          ({linearizeContext, ...} : functionContext)
          (functionID : SI.varid, funInfo : AN.funInfo, loc) =
      let
        val sizeMap =
            ListPair.foldl
                (fn (tyvar, AN.ANVAR {varInfo = ANVarInfo,...}, map) =>
                    let val varInfo = ANVarInfoToVarInfo ANVarInfo
                    in TMap.insert (map, tyvar, SI.VARIANT varInfo) end)
                TMap.empty
                (#tyvars funInfo, #sizevals funInfo)
        val context =
            {
              functionID = functionID,
              sizeMap = sizeMap,
              localBindingsRef = ref [],
              position = Tail,
              resultType = #resultTy funInfo,
              locOfEnclosingExp = loc,
              constantInstructions = ref [],
              linearizeContext = linearizeContext,
              enclosingGuardedCodes = []
            }
        val _ = app (fn varInfo => addVarBind context varInfo) (#args funInfo)
      in
        context
      end


end

