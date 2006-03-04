(**
 * This module translates an expression represented by tree like structure
 * into a sequence of instructions.
 * <p>
 * References occurring in operands of instructions are represented by symbols.
 * </p>
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Linearizer.sml,v 1.69 2006/02/28 16:11:02 kiyoshiy Exp $
 *)
structure Linearizer : LINEARIZER =
struct

  (***************************************************************************)

  structure BT = BasicTypes
  structure CTX = LinearizeContext
  structure SI = SymbolicInstructions
  structure AN = ANormal
  structure ANU = ANormalUtils
  structure TMap = IEnv

  (***************************************************************************)

  fun newVarInfo (id, ty, varKind) =
      {
        id = id,
        displayName = ID.toString id,
        ty = ty,
        varKind = varKind
      } : AN.varInfo

  fun ANVarInfoToVarInfo ({id, displayName, ...} : AN.varInfo) =
      {id = id, displayName = displayName} : SI.varInfo

  fun last [] = raise Control.Bug "last: empty list"
    | last [x] = x
    | last (x :: L) = last L

  fun sizeOfTy context ty = CTX.getSize context ty

  fun sizeOfExp context (AN.ANVAR{varInfo = {ty, ...},...}) = CTX.getSize context ty
    | sizeOfExp context _ = raise Control.Bug "sizeOfExp: ANVAR expects" 

  fun intConstToSInt32 (Types.INT i) = i
  fun wordConstToUInt32 (Types.WORD w) = w
  fun realConstToString (Types.REAL s) = s
  fun charConstToUInt32 (Types.CHAR c) = BT.IntToUInt32(Char.ord c)

  fun genPrim1_i opcode (Types.INT argValue1,argEntry2,destination) =
      opcode
          {
           argValue1 = argValue1,
           argEntry2 = argEntry2,
           destination = destination
          }

  fun genPrim2_i opcode (argEntry1, Types.INT argValue2,destination) =
      opcode
          {
           argEntry1 = argEntry1,
           argValue2 = argValue2,
           destination = destination
          }

  fun genPrim1_w opcode (Types.WORD argValue1,argEntry2,destination) =
      opcode
          {
           argValue1 = argValue1,
           argEntry2 = argEntry2,
           destination = destination
          }

  fun genPrim2_w opcode (argEntry1, Types.WORD argValue2,destination) =
      opcode
          {
           argEntry1 = argEntry1,
           argValue2 = argValue2,
           destination = destination
          }

  fun genPrim1_r opcode (Types.REAL argValue1,argEntry2,destination) =
      opcode
          {
           argValue1 = argValue1,
           argEntry2 = argEntry2,
           destination = destination
          }

  fun genPrim2_r opcode (argEntry1, Types.REAL argValue2,destination) =
      opcode
          {
           argEntry1 = argEntry1,
           argValue2 = argValue2,
           destination = destination
          }

  fun genPrim1_c opcode (Types.CHAR argValue1,argEntry2,destination) =
      opcode
          {
           argValue1 = BT.IntToUInt32(Char.ord argValue1),
           argEntry2 = argEntry2,
           destination = destination
          }

  fun genPrim2_c opcode (argEntry1, Types.CHAR argValue2,destination) =
      opcode
          {
           argEntry1 = argEntry1,
           argValue2 = BT.IntToUInt32(Char.ord argValue2),
           destination = destination
          }

  val genPrim1_b = genPrim1_w
  val genPrim2_b = genPrim2_w

  val prims =
      SEnv.fromList 
      [
       ("addInt",(genPrim1_i SI.AddInt_Const_1,genPrim2_i SI.AddInt_Const_2)),
       ("addWord",(genPrim1_w SI.AddWord_Const_1,genPrim2_w SI.AddWord_Const_2)),
       ("addReal",(genPrim1_r SI.AddReal_Const_1,genPrim2_r SI.AddReal_Const_2)),
       ("addByte",(genPrim1_b SI.AddByte_Const_1,genPrim2_b SI.AddByte_Const_2)),

       ("subInt",(genPrim1_i SI.SubInt_Const_1,genPrim2_i SI.SubInt_Const_2)),
       ("subWord",(genPrim1_w SI.SubWord_Const_1,genPrim2_w SI.SubWord_Const_2)),
       ("subReal",(genPrim1_r SI.SubReal_Const_1,genPrim2_r SI.SubReal_Const_2)),
       ("subByte",(genPrim1_b SI.SubByte_Const_1,genPrim2_b SI.SubByte_Const_2)),

       ("mulInt",(genPrim1_i SI.MulInt_Const_1,genPrim2_i SI.MulInt_Const_2)),
       ("mulWord",(genPrim1_w SI.MulWord_Const_1,genPrim2_w SI.MulWord_Const_2)),
       ("mulReal",(genPrim1_r SI.MulReal_Const_1,genPrim2_r SI.MulReal_Const_2)),
       ("mulByte",(genPrim1_b SI.MulByte_Const_1,genPrim2_b SI.MulByte_Const_2)),

       ("divInt",(genPrim1_i SI.DivInt_Const_1,genPrim2_i SI.DivInt_Const_2)),
       ("divWord",(genPrim1_w SI.DivWord_Const_1,genPrim2_w SI.DivWord_Const_2)),
       ("/",(genPrim1_r SI.DivReal_Const_1,genPrim2_r SI.DivReal_Const_2)),
       ("divByte",(genPrim1_b SI.DivByte_Const_1,genPrim2_b SI.DivByte_Const_2)),

       ("modInt",(genPrim1_i SI.ModInt_Const_1,genPrim2_i SI.ModInt_Const_2)),
       ("modWord",(genPrim1_w SI.ModWord_Const_1,genPrim2_w SI.ModWord_Const_2)),
       ("modByte",(genPrim1_b SI.ModByte_Const_1,genPrim2_b SI.ModByte_Const_2)),

       ("quotInt",(genPrim1_i SI.QuotInt_Const_1,genPrim2_i SI.QuotInt_Const_2)),
       ("remInt",(genPrim1_i SI.RemInt_Const_1,genPrim2_i SI.RemInt_Const_2)),

       ("Word_andb",(genPrim1_w SI.Word_andb_Const_1,genPrim2_w SI.Word_andb_Const_2)),
       ("Word_orb",(genPrim1_w SI.Word_orb_Const_1,genPrim2_w SI.Word_orb_Const_2)),
       ("Word_xorb",(genPrim1_w SI.Word_xorb_Const_1,genPrim2_w SI.Word_xorb_Const_2)),
       ("Word_leftShift",(genPrim1_w SI.Word_leftShift_Const_1,genPrim2_w SI.Word_leftShift_Const_2)),
       ("Word_logicalRightShift",
        (genPrim1_w SI.Word_logicalRightShift_Const_1,genPrim2_w SI.Word_logicalRightShift_Const_2)),
       ("Word_arithmeticRightShift",
        (genPrim1_w SI.Word_arithmeticRightShift_Const_1,genPrim2_w SI.Word_arithmeticRightShift_Const_2))
      ]

  fun makePrimApply1 (prim as {name,ty},argValue1,argEntry2,destination) =
      case SEnv.find(prims,name) of
        SOME (leftOp,rightOp) => leftOp(argValue1,argEntry2,destination)
      | _ => raise Control.Bug ("The primitive " ^ name ^ " has not beed implemented")

  fun makePrimApply2 (prim as {name,ty},argEntry1,argValue2,destination) =
      case SEnv.find(prims,name) of
        SOME (leftOp,rightOp) => rightOp(argEntry1,argValue2,destination)
      | _ => raise Control.Bug ("The primitive " ^ name ^ " has not beed implemented")
      


  (** get an instruction which implements the specified primitive.
   * @params name
   * @param the name of primitive
   *)
  fun findPrimitive name =
      case
        List.find (fn {bindName, ...} => bindName = name) Primitives.primitives
       of
        NONE => raise Control.Bug ("primitive " ^ name ^ " is not found.")
      | SOME primitive => primitive

  (**
   * translate an atom expression to an operand of an instruction.
   * <p>
   * In the current version, every operand is a local variable reference.
   * </p>
   * @params atom context
   * @param atom the atom expression
   * @param context the context
   * @return an entry translated from the atom expression.
   *)
  fun linearizeAtom context (AN.ANVAR{varInfo,...}) =
      ANVarInfoToVarInfo varInfo
    | linearizeAtom context exp =
      let val expString = ANormalFormatter.anexpToString exp
      in
        raise Control.Bug ("Atom(ANVAR) is expected, but found " ^ expString)
      end

  (**
   * linearizeExp a list of arguments of application and block allocation.
   * <p>
   * linearizeExp the last argument as a general expression,
   * and linearizeExp other arguments as atoms into local variable entries.
   * </p>
   *)
  fun linearizeArgs context args = map (linearizeAtom context) args

  (**
   * linearize an expression.
   * 
   * @return an instruction sequence generated from the expression.
   *)
  fun linearizeExp context exp =
      if !Control.generateExnHistory orelse !Control.generateDebugInfo
      then
        (* insert a Location instruction.
         * We should take care not to insert the same locations.
         *)
        let
          val loc = ANU.getLocOfExp exp
          val locOfEnclosingExp = CTX.getLocOfEnclosingExp context
          val innerContext = CTX.setLocOfEnclosingExp (context, loc)
          val instructions = toInstruction innerContext exp
        in
          if (loc = Loc.noloc) orelse (loc = locOfEnclosingExp)
          then instructions
          else SI.Location loc :: instructions
        end
      else toInstruction context exp

  and toInstruction context (AN.ANVAR{varInfo as {ty, ...}, loc}) =
      let
        val variableSize = sizeOfTy context ty
        val varInfo = ANVarInfoToVarInfo varInfo
      in
        case CTX.getPosition context of
          CTX.Tail =>
          [SI.Return{variableEntry = varInfo, variableSize = variableSize}]
        | CTX.Result =>
          [SI.Return{variableEntry = varInfo, variableSize = variableSize}]
        | CTX.Bound (boundVarInfo, _) =>
          [
            SI.Access
                {
                  variableEntry = varInfo,
                  variableSize = variableSize,
                  destination = boundVarInfo
                }
          ]
      end

    | toInstruction context (AN.ANAPPLY{funExp = function, argExpList = args, argSizeList = argSizes, loc}) =
      let
        val argsEntries = linearizeArgs context args
        val functionEntry = linearizeAtom context function
        val argsSizes = linearizeArgs context argSizes
        val argsCount = BT.IntToUInt32(List.length argsEntries)
      in
        case (!Control.doTailCallOptimize, CTX.getPosition context) of
          (true, CTX.Tail) => 
          [
           SI.TailApply_M
                {
                 argsCount = argsCount,
                 closureEntry = functionEntry,
                 argEntries = argsEntries,
                 argSizeEntries = argsSizes
                }
          ]
        | (_, CTX.Bound (boundVarInfo, _)) =>
          [
           SI.Apply_M
                {
                 argsCount = argsCount,
                 closureEntry = functionEntry,
                 argEntries = argsEntries,
                 argSizeEntries = argsSizes,
                 destination = boundVarInfo
                }
          ]
        | _ => (* (_, CTX.Result) or (false, CTX.Tail) *)
          let
            val boundVarID = CTX.createLocalVarID context
            val boundType = CTX.getResultType context
            val boundANVarInfo = newVarInfo(boundVarID, boundType, AN.LOCAL)
            val boundVarInfo = ANVarInfoToVarInfo boundANVarInfo
            val _ = CTX.addVarBind context boundANVarInfo
            val variableSize = sizeOfTy context boundType
            val applyInstruction =
                SI.Apply_M
                    {
                     argsCount = argsCount,
                     closureEntry = functionEntry,
                     argEntries = argsEntries,
                     argSizeEntries = argsSizes,
                     destination = boundVarInfo
                    }
            val returnInstruction =
                SI.Return
                    {variableEntry = boundVarInfo, variableSize = variableSize}
          in
            [applyInstruction,returnInstruction]
          end
      end

    | toInstruction 
          context 
          (AN.ANCALL{funLabel = functionLabel, envExp, argExpList = args, argSizeList = argSizes, loc}) =
      let
        val argsEntries = linearizeArgs context args
        val envEntry = linearizeAtom context envExp
        val argsSizes = linearizeArgs context argSizes
        val argsCount = BT.IntToUInt32(List.length argsEntries)
      in
        case (!Control.doTailCallOptimize, CTX.getPosition context) of
          (true, CTX.Tail) =>
          [
           SI.TailCallStatic_M
                {
                 argsCount = argsCount,
                 entryPoint = functionLabel,
                 envEntry = envEntry,
                 argEntries = argsEntries,
                 argSizeEntries = argsSizes
                }
          ]
        | (_, CTX.Bound (boundVarInfo, _)) =>
          [
           SI.CallStatic_M
                {
                 argsCount = argsCount,
                 entryPoint = functionLabel,
                 envEntry = envEntry,
                 argEntries = argsEntries,
                 argSizeEntries = argsSizes,
                 destination = boundVarInfo
                }
          ]
        | _ => (* (_, CTX.Result) or (false, CTX.Tail) *)
          let
            val boundVarID = CTX.createLocalVarID context
            val boundType = CTX.getResultType context
            val boundANVarInfo = newVarInfo(boundVarID, boundType, AN.LOCAL)
            val boundVarInfo = ANVarInfoToVarInfo boundANVarInfo
            val _ = CTX.addVarBind context boundANVarInfo
            val variableSize = sizeOfTy context boundType
            val applyInstruction =
                SI.CallStatic_M
                    {
                     argsCount = argsCount,
                     entryPoint = functionLabel,
                     envEntry = envEntry,
                     argEntries = argsEntries,
                     argSizeEntries = argsSizes,
                     destination = boundVarInfo
                    }
            val returnInstruction =
                SI.Return
                    {variableEntry = boundVarInfo, variableSize = variableSize}
          in
            [applyInstruction,returnInstruction]
          end
      end

    | toInstruction context (AN.ANRECCALL{funLabel = functionLabel, argExpList = args, argSizeList = argSizes, loc}) =
      if !Control.doRecursiveCallOptimize
      then
        let
          val argEntries = map (linearizeAtom context) args
          val currentFunctionLabel = #functionID context
          val argSizes = linearizeArgs context argSizes
          val argsCount = BT.IntToUInt32(List.length argEntries)
          val doSelfRecursiveCallOptimize =
              !Control.doSelfRecursiveCallOptimize andalso (currentFunctionLabel = functionLabel)
        in
          case CTX.getPosition context of
            CTX.Tail =>
            if doSelfRecursiveCallOptimize
            then
              [
               SI.SelfRecursiveTailCallStatic_M
                   {
                    argsCount = argsCount,
                    entryPoint = functionLabel,
                    argEntries = argEntries,
                    argSizeEntries = argSizes
                   }
              ]
            else
              [
               SI.RecursiveTailCallStatic_M
                   {
                    argsCount = argsCount,
                    entryPoint = functionLabel,
                    argEntries = argEntries,
                    argSizeEntries = argSizes
                   }
              ]
          | CTX.Result =>
            let
              val boundVarID = CTX.createLocalVarID context
              val boundType = CTX.getResultType context
              val boundANVarInfo =
                  newVarInfo(boundVarID, boundType, AN.LOCAL)
              val boundVarInfo = ANVarInfoToVarInfo boundANVarInfo
              val _ = CTX.addVarBind context boundANVarInfo
              val variableSize = sizeOfTy context boundType
              val callInstruction =
                  if doSelfRecursiveCallOptimize
                  then
                    SI.SelfRecursiveCallStatic_M
                        {
                         argsCount = argsCount,
                         entryPoint = functionLabel,
                         argEntries = argEntries,
                         argSizeEntries = argSizes,
                         destination = boundVarInfo
                        }
                  else
                    SI.RecursiveCallStatic_M
                        {
                         argsCount = argsCount,
                         entryPoint = functionLabel,
                         argEntries = argEntries,
                         argSizeEntries = argSizes,
                         destination = boundVarInfo
                        }
            in
              [
               callInstruction,
               SI.Return
                   {variableEntry = boundVarInfo, variableSize = variableSize}
              ]
            end
          | CTX.Bound (boundVarInfo, _) =>
            if doSelfRecursiveCallOptimize
            then
              [
               SI.SelfRecursiveCallStatic_M
                   {
                    argsCount = argsCount,
                    entryPoint = functionLabel,
                    argEntries = argEntries,
                    argSizeEntries = argSizes,
                    destination = boundVarInfo
                   }
              ]
            else
              [
               SI.RecursiveCallStatic_M
                   {
                    argsCount = argsCount,
                    entryPoint = functionLabel,
                    argEntries = argEntries,
                    argSizeEntries = argSizes,
                    destination = boundVarInfo
                   }
              ]
        end
      else (* non optimization *)
        let
          (* the environment of the current function is reused. *)
          val ENVVarID = CTX.createLocalVarID context
          val ENVANVarInfo = newVarInfo(ENVVarID, AN.BOXED, AN.LOCAL)
          val ENVVarInfo = ANVarInfoToVarInfo ENVANVarInfo
          val _ = CTX.addVarBind context ENVANVarInfo
          val callExp =
              AN.ANCALL
                  {
                   funLabel = functionLabel, 
                   envExp = AN.ANVAR {varInfo = ENVANVarInfo, loc = loc},
                   argExpList =  args, 
                   argSizeList = argSizes,
                   loc = loc
                  }
          val callCode = linearizeExp context callExp
        in SI.GetEnv{destination = ENVVarInfo} :: callCode end

    | toInstruction context (AN.ANRAISE {exceptionExp, loc}) =
      let val exceptionEntry = linearizeAtom context exceptionExp
      in [SI.Raise{exceptionEntry = exceptionEntry}] end

    | toInstruction context (AN.ANEXIT loc) = [SI.Exit]

    | toInstruction context (AN.ANLET {boundVar = ANVarInfo, boundExp, mainExp, loc}) =
      let
        val varInfo = ANVarInfoToVarInfo ANVarInfo
        val boundCode =
            linearizeExp
                (CTX.setBoundPosition (context, varInfo, #ty ANVarInfo))
                boundExp
        val mainCode = linearizeExp context mainExp
        val _ = CTX.addVarBind context ANVarInfo
      in boundCode @ mainCode end

    | toInstruction
          context (AN.ANHANDLE{mainExp = bodyExp, exnVar = exceptionInfo, handler = handlerExp, loc}) =
      let
        val exceptionVarInfo = ANVarInfoToVarInfo exceptionInfo
        val bodyCode = linearizeExp (CTX.notTailPosition context) bodyExp
        val _ = CTX.addVarBind context exceptionInfo
        val handlerLabel = CTX.createLabel context
        val tailLabel = CTX.createLabel context
        val handlerCode = linearizeExp context handlerExp
      in
        (SI.PushHandler
         {handler = handlerLabel, exceptionEntry = exceptionVarInfo})
        :: bodyCode
        @ [
            SI.PopHandler,
            SI.Jump{destination = tailLabel},
            SI.Label handlerLabel
          ]
        @ handlerCode
        @ [SI.Label tailLabel]
      end

    | toInstruction
          context (AN.ANSWITCH{switchExp = targetExp, branches = caseExps, defaultExp, loc}) =
      let
        val targetEntry = linearizeAtom context targetExp
        val defaultLabel = CTX.createLabel context
        val defaultCode = linearizeExp context defaultExp

        fun linearizeCase ((const, exp), (cases, codes)) =
            let
              val label = CTX.createLabel context
              val code = linearizeExp context exp
              val cases' = {const = const, destination = label} :: cases
              val codes' = (SI.Label label :: code) :: codes
            in (cases', codes') end

        (* NOTE: To arrange cases, constants in them are treated as unsigned
         *      integer. For instance, 1 < ~1.
         *)
        fun compareCaseExp ((const1, _), (const2, _)) =
            case (const1, const2) of
              (AN.INT int1, AN.INT int2) =>
              UInt32.compare (BT.SInt32ToUInt32 int1, BT.SInt32ToUInt32 int2)
            | (AN.WORD word1, AN.WORD word2) => UInt32.compare (word1, word2)
            | (AN.CHAR char1, AN.CHAR char2) => Char.compare (char1, char2)
            | (AN.STRING string1, AN.STRING string2) =>
              String.compare (string1, string2)
            | _ => raise Control.Bug "compare different type constant. "

        val sortedCaseExps = ListSorter.sort compareCaseExp caseExps
        val (cases, caseCodes) = foldl linearizeCase ([], []) sortedCaseExps
        val cases = List.rev cases
        val caseCodes = List.rev caseCodes

        val instruction =
            case hd caseExps 
             of (AN.INT _, _) =>
                SI.SwitchInt
                {
                  targetEntry = targetEntry,
                  casesCount = BT.IntToUInt32(List.length cases),
                  cases =
                  map
                      (fn {const = AN.INT const, destination} =>
                          {const = const, destination = destination})
                      cases,
                   default = defaultLabel
                 }
              | (AN.WORD _, _) =>
                SI.SwitchWord
                {
                  targetEntry = targetEntry,
                  casesCount = BT.IntToUInt32(List.length cases),
                  cases =
                  map
                      (fn {const = AN.WORD const, destination} =>
                          {const = const, destination = destination})
                      cases,
                   default = defaultLabel
                 }
              | (AN.CHAR _, _) =>
                SI.SwitchChar
                {
                  targetEntry = targetEntry,
                  casesCount = BT.IntToUInt32(List.length cases),
                  cases =
                  map
                      (fn {const = AN.CHAR const, destination} =>
                          {
                            const = BT.IntToUInt32 (Char.ord const),
                            destination = destination
                          })
                      cases,
                   default = defaultLabel
                 }
              | (AN.STRING _, _) =>
                SI.SwitchString
                {
                  targetEntry = targetEntry,
                  casesCount = BT.IntToUInt32(List.length cases),
                  cases =
                  map
                      (fn {const = AN.STRING const, destination} =>
                          let val label = CTX.addStringConstant context const
                          in {const = label, destination = destination} end)
                      cases,
                   default = defaultLabel
                 }
              | _ =>
                raise
                  Control.Bug
                      "linearizeCase expects INT,WORD,CHAR as the pattern of \
                      \ branches."

        val (caseCodes, tailCode) =
            case CTX.getPosition context of
              CTX.Bound _ =>
              (* insert jumps to the instruction sequence which follows this
               * Switch instruction. *)
              let
                val tailLabel = CTX.createLabel context
                fun appendJump code = code @ [SI.Jump{destination = tailLabel}]
              in
                (map appendJump caseCodes, [SI.Label tailLabel])
              end
            | _ =>
              (* No instruction sequence follows. *)
              (caseCodes, [])
      in
        instruction
        :: (List.concat caseCodes)
        @ [SI.Label defaultLabel]
        @ defaultCode
        @ tailCode
      end

    | toInstruction
          context (AN.ANLETLABEL{funLabel = funName, funInfo = funInfo, funBody = bodyExp, mainExp, loc}) =
      let
        val _ = linearizeFunction context (funName, loc, funInfo, bodyExp)
        val mainCode = linearizeExp context mainExp
      in mainCode end

    | toInstruction context (AN.ANVALREC{recbindList = binds, mainExp, loc}) =
      let
        fun linearizeBind {funLabel = funName, funInfo, body = bodyExp} =
            linearizeFunction context (funName, loc, funInfo, bodyExp)
        val _ = app linearizeBind binds
        val mainCode = linearizeExp context mainExp
      in mainCode end

    | toInstruction context innermost =
      (* This branch handles an innermost expression. *)
      let
        val (destinationEntry, destinationType, destinationSize, tailCode) =
            case CTX.getPosition context of
              CTX.Bound (boundVarInfo,boundType) => 
              (boundVarInfo, boundType, sizeOfTy context boundType, [])
            | _ =>
              let
                val varID = CTX.createLocalVarID context
                val resultType = CTX.getResultType context
                val resultSize = sizeOfTy context resultType
                val ANVarInfo = newVarInfo(varID, resultType, AN.LOCAL)
                val varInfo = ANVarInfoToVarInfo ANVarInfo
                val instructions =
                    [SI.Return
                         {variableEntry = varInfo, variableSize = resultSize}]
                val _ = CTX.addVarBind context ANVarInfo
              in 
                (varInfo, resultType, resultSize, instructions)
              end

        val code =
            case innermost of
              AN.ANCONSTANT {value=constant,...} =>
              (case constant of
                 AN.INT value =>
                 [SI.LoadInt{value = value, destination = destinationEntry}]
               | AN.WORD value =>
                 [SI.LoadWord{value = value, destination = destinationEntry}]
               | AN.STRING value =>
                 let 
                   val label = CTX.addStringConstant context value
                 in
                   [SI.LoadString
                        {string = label, destination = destinationEntry}]
                 end
               | AN.REAL value =>
                 [SI.LoadReal{value = value, destination = destinationEntry}]
               | AN.CHAR value =>
                 [SI.LoadChar
                      {
                        value = BT.IntToUInt32(Char.ord value),
                        destination = destinationEntry
                      }])

            | AN.ANENVACC {nestLevel, offset, loc} =>
              [
                SI.AccessNestedEnv
                {
                  nestLevel = nestLevel,
                  offset = offset, 
                  variableSize = destinationSize,
                  destination = destinationEntry
                }
              ]

            | AN.ANENVACCINDIRECT {nestLevel, indirectOffset, loc} =>
              [
                SI.AccessNestedEnvIndirect
                {
                  nestLevel = nestLevel,
                  offset = indirectOffset, 
                  variableSize = destinationSize,
                  destination = destinationEntry
                }
              ]
              
            | AN.ANPRIMAPPLY{primOp = {name, ty}, argExpList = args, loc} =>
              [
                SI.CallPrim
                    {
                      argsCount = BT.IntToUInt32(List.length args),
                      primitive = findPrimitive name,
                      argEntries = linearizeArgs context args,
                      argSizes = map (sizeOfExp context) args,
                      resultSize = destinationSize,
                      destination = destinationEntry
                    }
              ]

            | AN.ANPRIMAPPLY_1{primOp,argValue1,argExp2,loc} => 
              [
               makePrimApply1
                  (
                   primOp,
                   argValue1,
                   linearizeAtom context argExp2,
                   destinationEntry
                  )
              ]

            | AN.ANPRIMAPPLY_2{primOp,argExp1,argValue2,loc} => 
              [
               makePrimApply2
                  (
                   primOp,
                   linearizeAtom context argExp1,
                   argValue2,
                   destinationEntry
                  )
              ]

            | AN.ANFOREIGNAPPLY{funExp = function, argExpList = args, argTyList = argTys, loc} =>
              [
                SI.ForeignApply
                    {
                      argsCount = BT.IntToUInt32(List.length args),
                      closureEntry = linearizeAtom context function,
                      argEntries = linearizeArgs context args,
                      argSizes = map (sizeOfExp context) args,
                      resultSize = destinationSize,
                      destination = destinationEntry
                    }
              ]

            | AN.ANRECORD{bitmapExp, totalSizeExp = sizeExp, fieldList = args, fieldSizeList = argSizes, loc} =>
              [
                SI.MakeBlock
                    {
                      fieldsCount = BT.IntToUInt32(List.length args),
                      bitmapEntry = linearizeAtom context bitmapExp,
                      sizeEntry = linearizeAtom context sizeExp,
                      fieldEntries = linearizeArgs context args,
                      fieldSizeEntries = linearizeArgs context argSizes,
                      destination = destinationEntry
                    }
              ]

            | AN.ANARRAY{bitmapExp, sizeExp, initialValue = initialValueExp, loc} =>
              [
                SI.MakeArray
                    {
                      bitmapEntry = linearizeAtom context bitmapExp,
                      sizeEntry = linearizeAtom context sizeExp,
                      initialValueEntry =
                      linearizeAtom context initialValueExp,
                      initialValueSize = sizeOfExp context initialValueExp,
                      destination = destinationEntry
                    }
              ]

            | AN.ANMODIFY{recordExp = blockExp, nestLevel = nestLevelExp, offset = offsetExp, elementExp = valueExp, loc} =>
              [
                SI.CopyBlock
                    {
                      blockEntry = linearizeAtom context blockExp,
                      destination = destinationEntry
                    },
                SI.SetNestedFieldIndirect
                    {
                      blockEntry = destinationEntry,
                      nestLevelEntry = linearizeAtom context nestLevelExp,
                      offsetEntry = linearizeAtom context offsetExp,
                      fieldSize = sizeOfExp context valueExp,
                      newValueEntry = linearizeAtom context valueExp
                    }
              ]

            | AN.ANCLOSURE{funLabel = functionLabel, env = ENVExp, loc} =>
              [
                SI.MakeClosure
                    {
                      entryPoint = functionLabel,
                      ENVEntry = linearizeAtom context ENVExp,
                      destination = destinationEntry
                    }
              ]

            | AN.ANRECCLOSURE {funLabel = functionLabel, loc} =>
              let
                val ENVVarID = CTX.createLocalVarID context
                val ENVANVarInfo = newVarInfo(ENVVarID, AN.BOXED, AN.LOCAL)
                val ENVVarInfo = ANVarInfoToVarInfo ENVANVarInfo
                val _ = CTX.addVarBind context ENVANVarInfo
              in
                [
                  SI.GetEnv{destination = ENVVarInfo},
                  SI.MakeClosure
                      {
                        entryPoint = functionLabel,
                        ENVEntry = ENVVarInfo,
                        destination = destinationEntry
                      }
                ]
              end

            | AN.ANGETGLOBALVALUE {arrayIndex, offset, loc} =>
              [
               SI.GetGlobal
                   {
                    globalArrayIndex = arrayIndex,
                    offset = offset,
                    variableSize = destinationSize,
                    destination = destinationEntry
                   }
              ]

            | AN.ANSETGLOBALVALUE {arrayIndex, offset, valueExp, loc} =>
              [
               SI.SetGlobal
                   {
                    globalArrayIndex = arrayIndex,
                    offset = offset,
                    variableSize = sizeOfExp context valueExp,
                    newValueEntry = linearizeAtom context valueExp
                   }
              ]

            | AN.ANINITARRAYUNBOXED {arrayIndex, size, loc} =>
              [
               SI.InitGlobalArrayUnboxed
                   {
                    globalArrayIndex = arrayIndex,
                    arraySize = size
                   }
              ]

            | AN.ANINITARRAYBOXED {arrayIndex, size, loc} =>
              [
               SI.InitGlobalArrayBoxed
                   {
                    globalArrayIndex = arrayIndex,
                    arraySize = size
                   }
              ]

            | AN.ANINITARRAYDOUBLE {arrayIndex, size, loc} =>
              [
               SI.InitGlobalArrayDouble
                   {
                    globalArrayIndex = arrayIndex,
                    arraySize = size
                   }
              ]

            | AN.ANFFIVAL {funExp, libExp, argTyList = argTys, resultTy, funTy = ty, loc} =>
              let
                val funNameEntry = linearizeAtom context funExp
                val libNameEntry = linearizeAtom context libExp
              in
                [
                  SI.FFIVal
                      {
                        funNameEntry = funNameEntry,
                        libNameEntry = libNameEntry,
                        destination = destinationEntry
                      }
                ]
              end

            | AN.ANGETFIELD{blockExp, nestLevel = nestLevelExp, offset = offsetExp, loc} =>
              [
                SI.GetNestedFieldIndirect
                    {
                      blockEntry = linearizeAtom context blockExp,
                      nestLevelEntry = linearizeAtom context nestLevelExp,
                      offsetEntry = linearizeAtom context offsetExp,
                      fieldSize = destinationSize,
                      destination = destinationEntry
                    }
              ]

            | AN.ANSETFIELD
                  {blockExp, nestLevel = nestLevelExp, offset = offsetExp, valueExp, loc} =>
              let
                val blockEntry = linearizeAtom context blockExp
              in
                [
                  SI.SetNestedFieldIndirect
                      {
                        blockEntry = blockEntry,
                        nestLevelEntry = linearizeAtom context nestLevelExp,
                        offsetEntry = linearizeAtom context offsetExp,
                        fieldSize = sizeOfExp context valueExp,
                        newValueEntry = linearizeAtom context valueExp
                      },
                  SI.Access
                      {
                        variableEntry = blockEntry,
                        variableSize = SI.SINGLE,
                        destination = destinationEntry
                      }
                ]
              end
              
            | _ => raise Control.Bug "innermost expression is expected."

      in
        code @ tailCode
      end

  (**
   * generate a code sequence for a function
   * <p>
   * In addition to generation of code of function body, this function
   * collects information necessary for function prologue.
   * </p>
   * <p>
   * The code sequence this function returns is as follows:
   * <pre>
   *   Label funName
   *   FunEntry ...
   *   instruction1
   *     :
   *   instructionN
   * </pre>
   * <code>instruction1, ..., instructionN</code> are a code sequence generated
   * for the function body.
   * </p>
   * @params (funName, funInfo, bodyExp) enclosingContext
   * @param funName the name of the function
   * @param funInfo the funInfo of the function
   * @param bodyExp a expression of the function body
   * @param enclosingContext a context used to translate the enclosing
   *        expression
   * @return a code sequence for the function. 
   *)
  and linearizeFunction
          enclosingContext (funName, loc, funInfo : AN.funInfo, bodyExp) =
      let
        val args =
            map (fn ANVarInfo => ANVarInfoToVarInfo ANVarInfo) (#args funInfo)
        val tyvars = #tyvars funInfo

        (* linealize the body*)
        val context =
            CTX.createContext enclosingContext (funName, funInfo, loc)
        val bodyCode = linearizeExp context bodyExp
        val constantCode = CTX.getConstantInstructions context

        (* group local variables by their type*)
        fun groupByType
                (
                  (ANVarInfo : AN.varInfo),
                  (atoms, pointers, doubles, records)
                ) =
            let val varInfo = ANVarInfoToVarInfo ANVarInfo
            in
              case #ty ANVarInfo of
                AN.BOXED => (atoms, varInfo :: pointers, doubles, records)
              | AN.ATOM => (varInfo :: atoms, pointers, doubles, records)
              | AN.DOUBLE => (atoms, pointers, varInfo :: doubles, records)
              | AN.TYVAR tyvarid =>
                let
                  val varsOfTyVar =
                      case TMap.find (records, tyvarid) of
                        NONE => [varInfo]
                      | SOME vars => varInfo :: vars
                  val records' = TMap.insert (records, tyvarid, varsOfTyVar)
                in 
                  (atoms, pointers, doubles, records') 
                end
            end
        val localVars = CTX.getVarBinds context
        val (atomVarIDs, pointerVarIDs, doubleVarIDs, recordVarIDsMap) = 
            foldl groupByType ([], [], [], TMap.empty) localVars

        val bitmapFrees = 
            case #bitmapFree funInfo of
              AN.ANCONSTANT {value = Types.WORD 0w0,...} => []
            | AN.ANENVACC{nestLevel = 0w0, offset = i,...} => [i]
            | _ =>
              raise Control.Bug "constant(0w0) or envacc(0w0,i) is expected"

        val tagArgs =
            map 
                (fn (AN.ANVAR{varInfo = ANVarInfo,...}) => ANVarInfoToVarInfo ANVarInfo)
                (#tagArgs funInfo)

        val recordVarIDLists =
            map
            (fn tyvarid =>
                case TMap.find (recordVarIDsMap, tyvarid) of
                  SOME varids => varids
                | NONE => [])
            tyvars

        val funInfo = 
            {
              args = args,
              bitmapvals = {args = tagArgs, frees = bitmapFrees},
              atoms = atomVarIDs,
              pointers = pointerVarIDs,
              doubles = doubleVarIDs,
              records = recordVarIDLists
            }
      in
        CTX.addFunctionCode
            enclosingContext
            {
              name = {id = funName, displayName = ID.toString funName},
              loc = loc,
              funInfo = funInfo,
              instructions = bodyCode @ constantCode
            }
      end

  (****************************************)

  fun linearize exp =
      let
        val context = CTX.createInitialContext ()
        val dummyArgID = CTX.createLocalVarID context
        val mainFunctionID = CTX.createLabel context
        val mainFunctionLoc = ANU.getLocOfExp exp
(*
val _ = print ("loc: " ^ AbsynFormatter.locToString mainFunctionLoc ^ "\n")
*)
        val mainFunInfo : AN.funInfo =
            {
              tyvars = [],
              bitmapFree = AN.ANCONSTANT{value = Types.WORD 0w0, loc = mainFunctionLoc},
              tagArgs = [],
              sizevals = [],
              args = [],
              resultTy = AN.ATOM
            }
        val _ =
            linearizeFunction
                context (mainFunctionID, mainFunctionLoc, mainFunInfo, exp)
        val (mainFunction :: otherFunctions) = CTX.getFunctionCodes context
      in
        {
          mainFunctionName = mainFunctionID,
          functions =
          {
            name = #name mainFunction,
            loc = #loc mainFunction,
            funInfo = #funInfo mainFunction,
            instructions =
            map
                (fn SI.Return _ => SI.Exit | instruction => instruction)
                (#instructions mainFunction)
          } :: otherFunctions
        }
      end

  (***************************************************************************)

end
