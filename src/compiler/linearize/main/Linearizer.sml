(**
 * This module translates an expression represented by tree like structure
 * into a sequence of instructions.
 * <p>
 * References occurring in operands of instructions are represented by symbols.
 * </p>
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Linearizer.sml,v 1.79 2007/02/11 16:39:51 kiyoshiy Exp $
 *)
structure Linearizer : LINEARIZER =
struct

  (***************************************************************************)

  structure BT = BasicTypes
  structure CT = ConstantTerm
  structure CTX = LinearizeContext
  structure SI = SymbolicInstructions
  structure AN = ANormal
  structure ANU = ANormalUtils
  structure TMap = IEnv

  (***************************************************************************)

  fun sizeToCaseTag SI.SINGLE = 0w1 : BT.UInt32
    | sizeToCaseTag SI.DOUBLE = 0w2
    | sizeToCaseTag (SI.VARIANT _) = raise Control.Bug "sizeToCaseTag"
                                           
  fun funTypeToCaseTag (argTys, resultTy) =
      let
        fun tag (h::t) = sizeToCaseTag h + 0w2 * tag t
          | tag nil = 0w0 : BT.UInt32
      in
        tag (rev (resultTy::argTys))
      end

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

  fun sizeOfExp context (AN.ANVAR{varInfo = {ty, ...},...}) =
      CTX.getSize context ty
    | sizeOfExp context _ = raise Control.Bug "sizeOfExp: ANVAR expects" 

  fun intConstToSInt32 (CT.INT i) = i
  fun wordConstToUInt32 (CT.WORD w) = w
  fun realConstToString (CT.REAL s) = s
  fun charConstToUInt32 (CT.CHAR c) = BT.IntToUInt32(Char.ord c)

  fun genPrim1_i opcode (CT.INT argValue1,argEntry2,destination) =
      opcode
          {
           argValue1 = argValue1,
           argEntry2 = argEntry2,
           destination = destination
          }

  fun genPrim2_i opcode (argEntry1, CT.INT argValue2,destination) =
      opcode
          {
           argEntry1 = argEntry1,
           argValue2 = argValue2,
           destination = destination
          }

  fun genPrim1_w opcode (CT.WORD argValue1,argEntry2,destination) =
      opcode
          {
           argValue1 = argValue1,
           argEntry2 = argEntry2,
           destination = destination
          }

  fun genPrim2_w opcode (argEntry1, CT.WORD argValue2,destination) =
      opcode
          {
           argEntry1 = argEntry1,
           argValue2 = argValue2,
           destination = destination
          }

  fun genPrim1_r opcode (CT.REAL argValue1,argEntry2,destination) =
      opcode
          {
           argValue1 = argValue1,
           argEntry2 = argEntry2,
           destination = destination
          }

  fun genPrim2_r opcode (argEntry1, CT.REAL argValue2,destination) =
      opcode
          {
           argEntry1 = argEntry1,
           argValue2 = argValue2,
           destination = destination
          }

  fun genPrim1_c opcode (CT.CHAR argValue1,argEntry2,destination) =
      opcode
          {
           argValue1 = BT.IntToUInt32(Char.ord argValue1),
           argEntry2 = argEntry2,
           destination = destination
          }

  fun genPrim2_c opcode (argEntry1, CT.CHAR argValue2,destination) =
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
      | _ =>
        raise
          Control.Bug ("The primitive " ^ name ^ " has not beed implemented")

  fun makePrimApply2 (prim as {name,ty},argEntry1,argValue2,destination) =
      case SEnv.find(prims,name) of
        SOME (leftOp,rightOp) => rightOp(argEntry1,argValue2,destination)
      | _ =>
        raise
          Control.Bug ("The primitive " ^ name ^ " has not beed implemented")
      
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

  fun genReturn context varInfo varSize =
      List.map
          (fn label => SI.PopHandler {guardedStart = label})
          (CTX.getEnclosingHandlers context)
      @ [SI.Return{variableEntry = varInfo, variableSize = varSize}]

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
          CTX.Tail => genReturn context varInfo variableSize
        | CTX.Result => genReturn context varInfo variableSize
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

    | toInstruction
          context (AN.ANAPPLY{funExp, argExpList, argSizeList, loc}) =
      let
        val argsEntries = linearizeArgs context argExpList
        val functionEntry = linearizeAtom context funExp
        val argsSizes = linearizeArgs context argSizeList
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
            val returnInstruction = genReturn context boundVarInfo variableSize
          in
            applyInstruction :: returnInstruction
          end
      end

    | toInstruction 
          context (AN.ANCALL{funLabel, envExp, argExpList, argSizeList, loc}) =
      let
        val argsEntries = linearizeArgs context argExpList
        val envEntry = linearizeAtom context envExp
        val argsSizes = linearizeArgs context argSizeList
        val argsCount = BT.IntToUInt32(List.length argsEntries)
      in
        case (!Control.doTailCallOptimize, CTX.getPosition context) of
          (true, CTX.Tail) =>
          [
           SI.TailCallStatic_M
                {
                 argsCount = argsCount,
                 entryPoint = funLabel,
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
                 entryPoint = funLabel,
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
                     entryPoint = funLabel,
                     envEntry = envEntry,
                     argEntries = argsEntries,
                     argSizeEntries = argsSizes,
                     destination = boundVarInfo
                    }
            val returnInstruction = genReturn context boundVarInfo variableSize
          in
            applyInstruction :: returnInstruction
          end
      end

    | toInstruction
          context (AN.ANRECCALL{funLabel, argExpList, argSizeList, loc}) =
      if !Control.doRecursiveCallOptimize
      then
        let
          val argEntries = map (linearizeAtom context) argExpList
          val currentFunctionLabel = #functionID context
          val argSizes = linearizeArgs context argSizeList
          val argsCount = BT.IntToUInt32(List.length argEntries)
          val doSelfRecursiveCallOptimize =
              !Control.doSelfRecursiveCallOptimize
              andalso ID.eq(currentFunctionLabel, funLabel)
        in
          case CTX.getPosition context of
            CTX.Tail =>
            if doSelfRecursiveCallOptimize
            then
              [
               SI.SelfRecursiveTailCallStatic_M
                   {
                    argsCount = argsCount,
                    entryPoint = funLabel,
                    argEntries = argEntries,
                    argSizeEntries = argSizes
                   }
              ]
            else
              [
               SI.RecursiveTailCallStatic_M
                   {
                    argsCount = argsCount,
                    entryPoint = funLabel,
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
                         entryPoint = funLabel,
                         argEntries = argEntries,
                         argSizeEntries = argSizes,
                         destination = boundVarInfo
                        }
                  else
                    SI.RecursiveCallStatic_M
                        {
                         argsCount = argsCount,
                         entryPoint = funLabel,
                         argEntries = argEntries,
                         argSizeEntries = argSizes,
                         destination = boundVarInfo
                        }
            in
              callInstruction :: (genReturn context boundVarInfo variableSize)
            end
          | CTX.Bound (boundVarInfo, _) =>
            if doSelfRecursiveCallOptimize
            then
              [
               SI.SelfRecursiveCallStatic_M
                   {
                    argsCount = argsCount,
                    entryPoint = funLabel,
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
                    entryPoint = funLabel,
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
                   funLabel = funLabel, 
                   envExp = AN.ANVAR {varInfo = ENVANVarInfo, loc = loc},
                   argExpList = argExpList,
                   argSizeList = argSizeList,
                   loc = loc
                  }
          val callCode = linearizeExp context callExp
        in SI.GetEnv{destination = ENVVarInfo} :: callCode end

    | toInstruction context (AN.ANRAISE {exceptionExp, loc}) =
      let val exceptionEntry = linearizeAtom context exceptionExp
      in [SI.Raise{exceptionEntry = exceptionEntry}] end

    | toInstruction context (AN.ANEXIT loc) = [SI.Exit]

    | toInstruction context (AN.ANLET {boundVar, boundExp, mainExp, loc}) =
      let
        val varInfo = ANVarInfoToVarInfo boundVar
        val boundCode =
            linearizeExp
                (CTX.setBoundPosition (context, varInfo, #ty boundVar))
                boundExp
        val mainCode = linearizeExp context mainExp
        val _ = CTX.addVarBind context boundVar
      in boundCode @ mainCode end

    | toInstruction context (AN.ANHANDLE{mainExp, exnVar, handler, loc}) =
      let
        val startLabel = CTX.createLabel context
        val handlerLabel = CTX.createLabel context
        val tailLabel = CTX.createLabel context
        val exnVarInfo = ANVarInfoToVarInfo exnVar
        val mainCode =
            linearizeExp (CTX.enterGuardedCode (context, startLabel)) mainExp
        val _ = CTX.addVarBind context exnVar
        val handlerCode = linearizeExp context handler
      in
        SI.Label startLabel
        :: (SI.PushHandler
                {
                  handlerStart = handlerLabel,
                  handlerEnd = tailLabel,
                  exceptionEntry = exnVarInfo
                })
        :: mainCode
        @ [
            SI.PopHandler {guardedStart = startLabel},
            SI.Jump{destination = tailLabel},
            SI.Label handlerLabel
          ]
        @ handlerCode
        @ [SI.Label tailLabel]
      end

    | toInstruction
          context (AN.ANSWITCH{switchExp, branches, defaultExp, loc}) =
      let
        val switchEntry = linearizeAtom context switchExp
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

        val sortedCaseExps = ListSorter.sort compareCaseExp branches
        val (cases, caseCodes) = foldl linearizeCase ([], []) sortedCaseExps
        val cases = List.rev cases
        val caseCodes = List.rev caseCodes

        val instruction =
            case hd branches 
             of (AN.INT _, _) =>
                SI.SwitchInt
                {
                  targetEntry = switchEntry,
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
                  targetEntry = switchEntry,
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
                  targetEntry = switchEntry,
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
                  targetEntry = switchEntry,
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
          context (AN.ANLETLABEL{funLabel, funInfo, funBody, mainExp, loc}) =
      let
        val _ = linearizeFunction context (funLabel, loc, funInfo, funBody)
        val mainCode = linearizeExp context mainExp
      in mainCode end

    | toInstruction context (AN.ANVALREC{recbindList, mainExp, loc}) =
      let
        fun linearizeBind {funLabel, funInfo, body} =
            linearizeFunction context (funLabel, loc, funInfo, body)
        val _ = app linearizeBind recbindList
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
                val instructions = genReturn context varInfo resultSize
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
               | AN.FLOAT value =>
                 [SI.LoadFloat{value = value, destination = destinationEntry}]
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

            | AN.ANFOREIGNAPPLY
                  {funExp, argExpList, argTyList, convention, loc} =>
              [
                SI.ForeignApply
(*
 Ohori: Dec 17, 2006.
 Set the switchTag filed for dispatching C FFI function.
 *)
                let
                  val argSizes = map (sizeOfExp context) argExpList
                  val resultSize = destinationSize
                  val argsCount = BT.IntToUInt32(List.length argExpList)
                in
                  {
                   (*
                    Ohori: Dec 17, 2006.
                    If LARGEFFISWITCH is enableed then the switchTag is set
                    to a encoded type information otherwise it is same as
                    the number of args.
                    *)
                      switchTag = 
                        if !Control.LARGEFFISWITCH then
                          funTypeToCaseTag (argSizes, resultSize)
                        else argsCount,
                      convention = convention,
                      argsCount = argsCount,
                      closureEntry = linearizeAtom context funExp,
                      argEntries = linearizeArgs context argExpList,
                      argSizes = argSizes,
                      resultSize = resultSize,
                      destination = destinationEntry
                    }
                end
              ]

            | AN.ANEXPORTCALLBACK{funExp = function, argTyList = argTys, resultTy, loc} =>
              let
                val argSizes = map (sizeOfTy context) argTys
                val resultSize = sizeOfTy context resultTy
              in
                [
                  SI.RegisterCallback
                      {
                        sizeTag = funTypeToCaseTag (argSizes, resultSize),
                        closureEntry = linearizeAtom context function,
                        destination = destinationEntry
                      }
                ]
              end

            | AN.ANRECORD
                  {bitmapExp, totalSizeExp, fieldList, fieldSizeList, loc} =>
              [
                SI.MakeBlock
                    {
                      fieldsCount = BT.IntToUInt32(List.length fieldList),
                      bitmapEntry = linearizeAtom context bitmapExp,
                      sizeEntry = linearizeAtom context totalSizeExp,
                      fieldEntries = linearizeArgs context fieldList,
                      fieldSizeEntries = linearizeArgs context fieldSizeList,
                      destination = destinationEntry
                    }
              ]

            | AN.ANARRAY{bitmapExp, sizeExp, initialValue, loc} =>
              [
                SI.MakeArray
                    {
                      bitmapEntry = linearizeAtom context bitmapExp,
                      sizeEntry = linearizeAtom context sizeExp,
                      initialValueEntry =
                      linearizeAtom context initialValue,
                      initialValueSize = sizeOfExp context initialValue,
                      destination = destinationEntry
                    }
              ]

            | AN.ANMODIFY{recordExp, nestLevel, offset, elementExp, loc} =>
              [
                SI.CopyBlock
                    {
                      blockEntry = linearizeAtom context recordExp,
                      nestLevelEntry = linearizeAtom context nestLevel,
                      destination = destinationEntry
                    },
                SI.SetNestedFieldIndirect
                    {
                      blockEntry = destinationEntry,
                      nestLevelEntry = linearizeAtom context nestLevel,
                      offsetEntry = linearizeAtom context offset,
                      fieldSize = sizeOfExp context elementExp,
                      newValueEntry = linearizeAtom context elementExp
                    }
              ]

            | AN.ANCLOSURE{funLabel, env, loc} =>
              [
                SI.MakeClosure
                    {
                      entryPoint = funLabel,
                      ENVEntry = linearizeAtom context env,
                      destination = destinationEntry
                    }
              ]

            | AN.ANRECCLOSURE {funLabel, loc} =>
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
                        entryPoint = funLabel,
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

            | AN.ANGETFIELD{blockExp, nestLevel, offset, loc} =>
              [
                SI.GetNestedFieldIndirect
                    {
                      blockEntry = linearizeAtom context blockExp,
                      nestLevelEntry = linearizeAtom context nestLevel,
                      offsetEntry = linearizeAtom context offset,
                      fieldSize = destinationSize,
                      destination = destinationEntry
                    }
              ]

            | AN.ANSETFIELD{blockExp, nestLevel, offset, valueExp, loc} =>
              let
                val blockEntry = linearizeAtom context blockExp
              in
                [
                  SI.SetNestedFieldIndirect
                      {
                        blockEntry = blockEntry,
                        nestLevelEntry = linearizeAtom context nestLevel,
                        offsetEntry = linearizeAtom context offset,
                        fieldSize = sizeOfExp context valueExp,
                        newValueEntry = linearizeAtom context valueExp
                      },
                 SI.LoadInt{value = 0, destination = destinationEntry}
(*
                  SI.Access
                      {
                        variableEntry = blockEntry,
                        variableSize = SI.SINGLE,
                        destination = destinationEntry
                      }
*)
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
              AN.ANCONSTANT {value = CT.WORD 0w0,...} => []
            | AN.ANENVACC{nestLevel = 0w0, offset = i,...} => [i]
            | _ =>
              raise Control.Bug "constant(0w0) or envacc(0w0,i) is expected"

        val tagArgs =
            map 
                (fn (AN.ANVAR{varInfo,...}) => ANVarInfoToVarInfo varInfo)
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
              bitmapFree =
              AN.ANCONSTANT{value = CT.WORD 0w0, loc = mainFunctionLoc},
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
