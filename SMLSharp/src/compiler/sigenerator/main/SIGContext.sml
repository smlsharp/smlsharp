structure SIGContext : SIGCONTEXT = struct

  structure IL = IntermediateLanguage
  structure SI = SymbolicInstructions
  structure ILU = ILUtils
  structure CT = ConstantTerm

  structure Entry_ord:ORD_KEY = struct 
  type ord_key = SI.entry

  fun compare ({id = id1, displayName = displayName1},{id = id2, displayName = displayName2}) =
      VarID.compare(id1,id2)
  end

  structure VarInfo_ord:ORD_KEY = struct 
  type ord_key = IL.varInfo

  fun compare ({varId = varId1, ...} : IL.varInfo, {varId = varId2, ...} : IL.varInfo) =
      VarIdEnv.Key.compare(varId1,varId2)
  end

  structure Const_ord:ORD_KEY = struct 
  type ord_key = CT.constant

  val compare = CT.compare
  end

  structure ConstMap = BinaryMapMaker(Const_ord)
  structure EntryMap = BinaryMapMaker(Entry_ord)
  structure VarInfoSet = BinarySetMaker(VarInfo_ord)

  datatype varRoot = 
           CONST of ConstantTerm.constant
         | VAR of SymbolicInstructions.entry
         | CLOSURE of SymbolicInstructions.address * SymbolicInstructions.entry

  datatype position = Tail | NonTail


  (* a context contains three part:
   *  - constEnv, varEnv serve the transformation along each computation path
   *    ( for example, each branch of switch )
   *  - instructions serves the transformation of a function
   *  - localVars serves the transformation of entire cluster
   *)
  type context = 
       {
        (* map from a constant to the first entry assigned to this constant*)
        firstConstBinds : SI.entry ConstMap.map, 
        (* specify the status of an entry : constant, closure, ...*)
        varRoots : varRoot EntryMap.map,
        (* list of accummulated local variables *)
        localVarsRef : VarInfoSet.set ref,
        (** the position of expression within the function. *)
        position : position,
        (** the location of the current statement.*)
        loc : Loc.loc,
        (** instructions for holding constants *)
        constantInstructions : SI.instruction list ref,
        (** start labels of enclosing codes guarded by 'handle'. *)
        enclosingGuardedCodes : SI.address list
       }

  fun createInitialContext loc =
      {
       firstConstBinds = ConstMap.empty,
       varRoots = EntryMap.empty,
       localVarsRef = ref (VarInfoSet.empty),
       position = Tail,
       loc = loc,
       constantInstructions = ref [],
       enclosingGuardedCodes = []
      } : context

  fun createContext (enclosingContext : context) (functionCode : IL.functionCode) =
      let
        val localVarsRef = #localVarsRef enclosingContext
        val localVars = 
            foldl 
                (fn (v,S) => VarInfoSet.add (S,v))
                (!localVarsRef)
                (#argVarList functionCode)

        val _ = localVarsRef := localVars
      in
        {
         firstConstBinds = ConstMap.empty,
         varRoots = EntryMap.empty,
         localVarsRef = localVarsRef,
         position = Tail,
         loc = #loc functionCode,
         constantInstructions = ref [],
         enclosingGuardedCodes = []
        } : context
      end


  fun rootOf ({varRoots,...} : context) entry = EntryMap.find(varRoots, entry)

  fun rootEntry ({varRoots,...} : context) entry =
      case EntryMap.find(varRoots, entry) of
        SOME (VAR entry') => entry'
      | _ => entry

  fun varOf ({varRoots,...} : context) entry =
      case EntryMap.find(varRoots, entry) of
        SOME (VAR entry') => SOME entry'
      | _ => NONE

  fun constOf ({varRoots,...} : context) entry =
      case EntryMap.find(varRoots, entry) of
        SOME (CONST const) => SOME const
      | _ => NONE

  fun closureOf ({varRoots,...} : context) entry =
      case EntryMap.find(varRoots, entry) of
        SOME (CLOSURE (entryPoint, envEntry)) => SOME (entryPoint, envEntry)
      | _ => NONE

  fun wordOf ({varRoots,...} : context) entry =
      case EntryMap.find(varRoots, entry) of
        SOME (CONST (CT.WORD value)) => SOME value
      | _ => NONE

  fun intOf ({varRoots,...} : context) entry =
      case EntryMap.find(varRoots, entry) of
        SOME (CONST (CT.INT value)) => SOME value
      | _ => NONE

  fun largeIntOf ({varRoots,...} : context) entry =
      case EntryMap.find(varRoots, entry) of
        SOME (CONST (CT.LARGEINT value)) => SOME value
      | _ => NONE

  fun realOf ({varRoots,...} : context) entry =
      case EntryMap.find(varRoots, entry) of
        SOME (CONST (CT.REAL value)) => SOME value
      | _ => NONE

  fun floatOf ({varRoots,...} : context) entry =
      case EntryMap.find(varRoots, entry) of
        SOME (CONST (CT.FLOAT value)) => SOME value
      | _ => NONE

  fun stringOf ({varRoots,...} : context) entry =
      case EntryMap.find(varRoots, entry) of
        SOME (CONST (CT.STRING value)) => SOME value
      | _ => NONE

  fun charOf ({varRoots,...} : context) entry =
      case EntryMap.find(varRoots, entry) of
        SOME (CONST (CT.CHAR value)) => SOME value
      | _ => NONE

  fun findFirstConstantBind ({firstConstBinds,...} : context) constant =
      ConstMap.find(firstConstBinds, constant)

  fun addStringConstant
          (context as {constantInstructions, ...} : context) string =
      let val label = VarID.generate ()
      in
        constantInstructions :=
        ([SI.Label label, SI.ConstString {string = string}]
         @ (!constantInstructions));
        label
      end

  fun getConstantInstructions ({constantInstructions, ...} : context) =
      !constantInstructions


  fun addLocalVariable ({localVarsRef, ...} : context) (varInfo as {varId, displayName, ty, varKind}) =
      case varId of
          Types.INTERNAL id =>
          (
           localVarsRef := (VarInfoSet.add(!localVarsRef, varInfo));
           {id = id, displayName = displayName}
          )
        | Types.EXTERNAL _ =>
          raise Control.Bug "expect internal variable"

  fun getLocalVariables ({localVarsRef, ...} : context) = VarInfoSet.listItems (!localVarsRef)

  fun addConstantBind (context : context) (constant, destination) =
      let
        val firstConstBinds = #firstConstBinds context
      in
        {
         firstConstBinds = case ConstMap.find(firstConstBinds, constant) of 
                           SOME _ => firstConstBinds
                         | NONE => ConstMap.insert(firstConstBinds, constant, destination),
         varRoots = EntryMap.insert(#varRoots context, destination, CONST constant),
         localVarsRef = #localVarsRef context,
         position = #position context,
         loc = #loc context,
         constantInstructions = #constantInstructions context,
         enclosingGuardedCodes = #enclosingGuardedCodes context
        } : context
      end      

  fun addVariableBind (context : context) (varEntry, destination) =
      {
       firstConstBinds = #firstConstBinds context,
       varRoots = EntryMap.insert(#varRoots context, destination, VAR varEntry),
       localVarsRef = #localVarsRef context,
       position = #position context,
       loc = #loc context,
       constantInstructions = #constantInstructions context,
       enclosingGuardedCodes = #enclosingGuardedCodes context
      } : context

  fun addClosureBind (context : context) (entryPoint, envEntry, destination) =
      {
       firstConstBinds = #firstConstBinds context,
       varRoots = EntryMap.insert(#varRoots context, destination, CLOSURE (entryPoint, envEntry)),
       localVarsRef = #localVarsRef context,
       position = #position context,
       loc = #loc context,
       constantInstructions = #constantInstructions context,
       enclosingGuardedCodes = #enclosingGuardedCodes context
      } : context

  fun setLocation (context : context) loc =
      {
       firstConstBinds = #firstConstBinds context,
       varRoots = #varRoots context,
       localVarsRef = #localVarsRef context,
       position = #position context,
       loc = loc,
       constantInstructions = #constantInstructions context,
       enclosingGuardedCodes = #enclosingGuardedCodes context
      } : context

  fun getLocation ({loc,...} : context) = loc

  fun setPosition (context : context) position =
      {
       firstConstBinds = #firstConstBinds context,
       varRoots = #varRoots context,
       localVarsRef = #localVarsRef context,
       position = position,
       loc = #loc context,
       constantInstructions = #constantInstructions context,
       enclosingGuardedCodes = #enclosingGuardedCodes context
      } : context

  fun getPosition ({position,...} : context) = position

  fun enterGuardedCode (context : context) label =
      {
       firstConstBinds = #firstConstBinds context,
       varRoots = #varRoots context,
       localVarsRef = #localVarsRef context,
       position = #position context,
       loc = #loc context,
       constantInstructions = #constantInstructions context,
       enclosingGuardedCodes = label :: (#enclosingGuardedCodes context)
      } : context

  fun getEnclosingHandlers (context : context) =
      #enclosingGuardedCodes context



end
