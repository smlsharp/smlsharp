(**
 * This module translates an expression represented by tree like structure
 * into a sequence of instructions.
 * <p>
 * References occurring in operands of instructions are represented by symbols.
 * </p>
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @author NGUYEN Huu-Duc
 * @version $Id: Linearizer.sml,v 1.80 2007/04/19 05:06:52 ducnh Exp $
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
  structure CT = ConstantTerm

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

  val ANVarInfoToVarInfo = CTX.ANVarInfoToVarInfo

  val ANExpToSize = CTX.ANExpToSize

  fun newANVarInfo ty =
      let 
        val id = ID.generate ()
      in
        {id = id, displayName = ID.toString id, ty = ty, varKind = AN.LOCAL} : AN.varInfo
      end

  fun constantToInstruction context (constant, destination) =
      case constant of
        CT.INT value => SI.LoadInt{value = value, destination = destination}
      | CT.WORD value => SI.LoadWord{value = value, destination = destination}
      | CT.STRING value =>
        let 
          val label = CTX.addStringConstant context value
        in
          SI.LoadString{string = label, destination = destination}
        end
      | CT.REAL value => SI.LoadReal{value = value, destination = destination}
      | CT.FLOAT value => SI.LoadFloat{value = value, destination = destination}
      | CT.CHAR value => SI.LoadChar{value = BT.IntToUInt32(Char.ord value), destination = destination}
      | CT.UNIT => SI.LoadInt{value = 0, destination = destination}

  fun addConstantBind context const =
      let
        val constTy = 
            case const of
              CT.INT _ => AN.ATOM
            | CT.WORD _ => AN.ATOM
            | CT.REAL _ => if !Control.enableUnboxedFloat then AN.DOUBLE else AN.BOXED
            | CT.FLOAT _ => AN.ATOM
            | CT.STRING _ => AN.BOXED 
            | CT.CHAR _ => AN.ATOM
            | CT.UNIT  => AN.ATOM
        val ANVarInfo = newANVarInfo constTy
        val varInfo = ANVarInfoToVarInfo ANVarInfo
        val _ = CTX.addVarBind context ANVarInfo
        val instruction = constantToInstruction context (const, varInfo)
      in
        ([instruction], varInfo)
      end

  fun sizeToVarInfo context (SI.SINGLE) = addConstantBind context (CT.WORD 0w1)
    | sizeToVarInfo context (SI.DOUBLE) = addConstantBind context (CT.WORD 0w2)
    | sizeToVarInfo context (SI.VARIANT varInfo) = ([],varInfo)

  fun sizesToVarInfos context sizeList =
      foldr
          (fn (size,(instructions, varInfoList)) =>
              let
                val (instruction,varInfo) = sizeToVarInfo context size
              in
                (instruction @ instructions, varInfo::varInfoList)
              end
          )
          ([],[])
          sizeList

  fun argToVarInfo context (AN.ANVAR{varInfo,...}) = ([],ANVarInfoToVarInfo varInfo)
    | argToVarInfo context (AN.ANCONSTANT {value,...}) = addConstantBind context value
    | argToVarInfo context (AN.ANEXCEPTIONTAG {tagValue,...}) = addConstantBind context (CT.WORD tagValue)
    | argToVarInfo context exp =
      let 
        val expString = ANormalFormatter.anexpToString exp
      in
        raise Control.Bug ("Atom(ANVAR, ANCONSTANT, ANEXCEPTIONTAG) is expected, but found " ^ expString)
      end

  fun argsToVarInfos context args = 
      foldr
          (fn (arg,(instructions, varInfoList)) =>
              let
                val (instruction,varInfo) = argToVarInfo context arg
              in
                (instruction @ instructions, varInfo::varInfoList)
              end
          )
          ([],[])
          args

  fun genReturn context variableEntries variableSizeEntries =
      let
        val popHandlers =
            List.map
                (fn label => SI.PopHandler {guardedStart = label})
                (CTX.getEnclosingHandlers context)
      in
        popHandlers @
        [
         SI.Return_MV{variableEntries = variableEntries, variableSizeEntries = variableSizeEntries}
        ]
      end


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

  and toInstruction context (AN.ANVAR{varInfo, loc}) =
      let
        val varInfo = ANVarInfoToVarInfo varInfo
      in
        case CTX.getPosition context of
          CTX.Tail => 
          let
            val (constBinds, [sizeVarInfo]) = sizesToVarInfos context (CTX.getResultSizeList context)
          in
            constBinds @ (genReturn context [varInfo] [sizeVarInfo])
          end
        | CTX.Result => 
          let
            val (constBinds, [sizeVarInfo]) = sizesToVarInfos context (CTX.getResultSizeList context)
          in
            constBinds @ (genReturn context [varInfo] [sizeVarInfo])
          end
        | CTX.Bound {boundVarInfoList as [boundVarInfo], variableSizeList as [variableSize],...} =>
          [
            SI.Access
                {
                  variableEntry = varInfo,
                  variableSize = variableSize,
                  destination = boundVarInfo
                }
          ]
        | _ => raise Control.Bug "variable binding should be single value binding"
      end

    | toInstruction context (AN.ANMVALUES {expList, tyList, sizeExpList, loc}) =
      (
       case CTX.getPosition context of 
         CTX.Tail =>
         let
           val (constBinds1, argEntries) = argsToVarInfos context expList
           val (constBinds2, sizeEntries) = sizesToVarInfos context (CTX.getResultSizeList context)
         in
           constBinds1 @ constBinds2 @ (genReturn context argEntries sizeEntries)
         end
       | CTX.Result =>
         let
           val (constBinds1, argEntries) = argsToVarInfos context expList
           val (constBinds2, sizeEntries) = sizesToVarInfos context (CTX.getResultSizeList context)
         in
           constBinds1 @ constBinds2 @ (genReturn context argEntries sizeEntries)
         end
       | CTX.Bound {boundVarInfoList, boundTyList, variableSizeList} =>
         List.concat
             (
              ListPair.map
                  (fn ((boundVarInfo, boundTy), (variableSize,exp)) =>
                      let
                        val newContext = CTX.setBoundPosition(context,[boundVarInfo], [boundTy], [variableSize])
                      in 
                        toInstruction newContext exp
                      end
                  )
                  (ListPair.zip(boundVarInfoList,boundTyList), ListPair.zip(variableSizeList, expList))
             )
      )

    | toInstruction
          context (AN.ANAPPLY{funExp, argExpList, argTyList, argSizeExpList, loc}) =
      let
        val (constBinds1,argsEntries) = argsToVarInfos context argExpList
        val (constBinds2,functionEntry::argsSizeEntries) = argsToVarInfos context (funExp::argSizeExpList)
      in
        case (!Control.doTailCallOptimize, CTX.getPosition context) of
          (true, CTX.Tail ) => 
          constBinds1 @ constBinds2 @
          [
           SI.TailApply_MV
                {
                 closureEntry = functionEntry,
                 argEntries = argsEntries,
                 argSizeEntries = argsSizeEntries
                }
          ]
        | (_, CTX.Bound {boundVarInfoList, ...}) =>
          constBinds1 @ constBinds2 @
          [
           SI.Apply_MV
                {
                 closureEntry = functionEntry,
                 argEntries = argsEntries,
                 argSizeEntries = argsSizeEntries,
                 destinations = boundVarInfoList
                }
          ]
        | _ => (* (_, CTX.Result) or (false, CTX.Tail) *)
          let
            val boundTyList = CTX.getResultTypeList context
            val boundANVarInfoList = map newANVarInfo boundTyList
            val boundVarInfoList = map ANVarInfoToVarInfo boundANVarInfoList
            val _ = List.app (CTX.addVarBind context) boundANVarInfoList
            val (constBinds3, resultSizeEntries) = sizesToVarInfos context (CTX.getResultSizeList context)
            val applyInstruction =
                SI.Apply_MV
                    {
                     closureEntry = functionEntry,
                     argEntries = argsEntries,
                     argSizeEntries = argsSizeEntries,
                     destinations = boundVarInfoList
                    }
            val returnInstruction = genReturn context boundVarInfoList resultSizeEntries
          in
            constBinds1 @ constBinds2 @ constBinds3 @ (applyInstruction :: returnInstruction)
          end
      end

    | toInstruction 
          context (AN.ANCALL{funLabel as AN.ANLABEL {codeId,...}, envExp, argExpList, argTyList, argSizeExpList, loc}) =
      let
        val (constBinds1,envEntry::argsEntries) = argsToVarInfos context (envExp::argExpList)
        val (constBinds2,argsSizeEntries) = argsToVarInfos context argSizeExpList
      in
        case (!Control.doTailCallOptimize, CTX.getPosition context) of
          (true, CTX.Tail) =>
          constBinds1 @ constBinds2 @
          [
           SI.TailCallStatic_MV
                {
                 entryPoint = codeId,
                 envEntry = envEntry,
                 argEntries = argsEntries,
                 argSizeEntries = argsSizeEntries
                }
          ]
        | (_, CTX.Bound {boundVarInfoList,...}) =>
          constBinds1 @ constBinds2 @
          [
           SI.CallStatic_MV
                {
                 entryPoint = codeId,
                 envEntry = envEntry,
                 argEntries = argsEntries,
                 argSizeEntries = argsSizeEntries,
                 destinations = boundVarInfoList
                }
          ]
        | _ => (* (_, CTX.Result) or (false, CTX.Tail) *)
          let
            val boundTyList = CTX.getResultTypeList context
            val boundANVarInfoList = map newANVarInfo boundTyList
            val boundVarInfoList = map ANVarInfoToVarInfo boundANVarInfoList
            val _ = List.app (CTX.addVarBind context) boundANVarInfoList
            val (constBinds3, resultSizeEntries) = sizesToVarInfos context (CTX.getResultSizeList context)
            val applyInstruction =
                SI.CallStatic_MV
                    {
                     entryPoint = codeId,
                     envEntry = envEntry,
                     argEntries = argsEntries,
                     argSizeEntries = argsSizeEntries,
                     destinations = boundVarInfoList
                    }
            val returnInstruction = genReturn context boundVarInfoList resultSizeEntries
          in
            constBinds1 @ constBinds2 @ constBinds3 @ (applyInstruction :: returnInstruction)
          end
      end

    | toInstruction context (AN.ANCALL _) = raise Control.Bug "invalid ANCALL"

    | toInstruction
          context (AN.ANRECCALL{codeExp as AN.ANLABEL {codeId,...}, argExpList, argSizeExpList, argTyList, loc}) =
      if !Control.doRecursiveCallOptimize
      then
        let
          val (constBinds1,argEntries) = argsToVarInfos context argExpList
          val (constBinds2,argSizeEntries) = argsToVarInfos context argSizeExpList
        in
          case CTX.getPosition context of
            CTX.Tail =>
            constBinds1 @ constBinds2 @
            [
             SI.RecursiveTailCallStatic_MV
                 {
                  entryPoint = codeId,
                  argEntries = argEntries,
                  argSizeEntries = argSizeEntries
                 }
            ]
          | CTX.Result =>
            let
              val boundTyList = CTX.getResultTypeList context
              val boundANVarInfoList = map newANVarInfo boundTyList
              val boundVarInfoList = map ANVarInfoToVarInfo boundANVarInfoList
              val _ = List.app (CTX.addVarBind context) boundANVarInfoList
              val callInstruction =
                  SI.RecursiveCallStatic_MV
                      {
                       entryPoint = codeId,
                       argEntries = argEntries,
                       argSizeEntries = argSizeEntries,
                       destinations = boundVarInfoList
                      }
              val (constBinds3, resultSizeEntries) = sizesToVarInfos context (CTX.getResultSizeList context)
              val returnCode = genReturn context boundVarInfoList resultSizeEntries
            in
              constBinds1 @ constBinds2 @ constBinds3 @ (callInstruction :: returnCode)
            end
          | CTX.Bound {boundVarInfoList, ...} =>
            constBinds1 @ constBinds2 @
            [
             SI.RecursiveCallStatic_MV
                 {
                  entryPoint = codeId,
                  argEntries = argEntries,
                  argSizeEntries = argSizeEntries,
                  destinations = boundVarInfoList
                 }
            ]
        end
      else (* non optimization *)
        let
          (* the environment of the current function is reused. *)
          val ENVANVarInfo = newANVarInfo AN.BOXED
          val ENVVarInfo = ANVarInfoToVarInfo ENVANVarInfo
          val _ = CTX.addVarBind context ENVANVarInfo
          val callExp =
              AN.ANCALL
                  {
                   funLabel = AN.ANLABEL{codeId = codeId, loc = loc}, 
                   envExp = AN.ANVAR {varInfo = ENVANVarInfo, loc = loc},
                   argExpList = argExpList,
                   argSizeExpList = argSizeExpList,
                   argTyList = argTyList,
                   loc = loc
                  }
          val callCode = linearizeExp context callExp
        in SI.GetEnv{destination = ENVVarInfo} :: callCode end

    | toInstruction context (AN.ANRECCALL _) = raise Control.Bug "invalid ANRECCALL"

    | toInstruction context (AN.ANINNERCALL _) = raise Control.Bug "not impelemented"

    | toInstruction context (AN.ANRAISE {argExp, loc}) =
      let
        val (constBinds,exceptionEntry) = argToVarInfo context argExp
      in 
        constBinds @ [SI.Raise{exceptionEntry = exceptionEntry}] 
      end

    | toInstruction context (AN.ANEXIT loc) = [SI.Exit]

    | toInstruction context (AN.ANLET {localDeclList, mainExp, loc}) =
      let
        val boundCode = linearizeDeclList context localDeclList
        val mainCode = linearizeExp context mainExp
      in boundCode @ mainCode end

    | toInstruction context (AN.ANHANDLE{exp, exnVar, handler, loc}) =
      let
        val startLabel = CTX.createLabel context
        val handlerLabel = CTX.createLabel context
        val tailLabel = CTX.createLabel context
        val exnVarInfo = ANVarInfoToVarInfo exnVar
        val mainCode =
            linearizeExp (CTX.enterGuardedCode (context, startLabel)) exp
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
          context (AN.ANSWITCH{switchExp, expTy, branches, defaultExp, loc}) =
      let
        val (constBinds,switchEntry) = argToVarInfo context switchExp
        val defaultLabel = CTX.createLabel context
        val defaultCode = linearizeExp context defaultExp

        fun linearizeCase ({constant, exp}, (cases, codes)) =
            let
              val label = CTX.createLabel context
              val code = linearizeExp context exp
              val cases' = {const = constant, destination = label} :: cases
              val codes' = (SI.Label label :: code) :: codes
            in (cases', codes') end

        (* NOTE: To arrange cases, constants in them are treated as unsigned
         *      integer. For instance, 1 < ~1.
         *)
        fun compareCaseExp ({constant = const1, exp = exp1}, {constant = const2, exp = exp2}) =
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
             of {constant = CT.INT _, exp} =>
                SI.SwitchInt
                {
                  targetEntry = switchEntry,
                  cases =
                  map
                      (fn {const = CT.INT const, destination} =>
                          {const = const, destination = destination})
                      cases,
                  default = defaultLabel
                 }
              | {constant = CT.WORD _, exp} =>
                SI.SwitchWord
                {
                  targetEntry = switchEntry,
                  cases =
                  map
                      (fn {const = CT.WORD const, destination} =>
                          {const = const, destination = destination})
                      cases,
                  default = defaultLabel
                 }
              | {constant = CT.CHAR _, exp} =>
                SI.SwitchChar
                {
                  targetEntry = switchEntry,
                  cases =
                  map
                      (fn {const = CT.CHAR const, destination} =>
                          {
                            const = BT.IntToUInt32 (Char.ord const),
                            destination = destination
                          })
                      cases,
                  default = defaultLabel
                 }
              | {constant = CT.STRING _, exp} =>
                SI.SwitchString
                {
                  targetEntry = switchEntry,
                  cases =
                  map
                      (fn {const = CT.STRING const, destination} =>
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
        constBinds
        @ (instruction :: (List.concat caseCodes))
        @ [SI.Label defaultLabel]
        @ defaultCode
        @ tailCode
      end

    | toInstruction context innermost =
      (* This branch handles an innermost expression. *)
      let
        val (destinationEntryList, destinationTyList, destinationSizeList, tailCode) =
            case CTX.getPosition context of
              CTX.Bound {boundVarInfoList,boundTyList, variableSizeList} => 
              (boundVarInfoList, boundTyList, variableSizeList, [])
            | _ =>
              let
                val resultTyList = CTX.getResultTypeList context
                val resultSizeList = CTX.getResultSizeList context
                val ANVarInfoList = map newANVarInfo resultTyList
                val varInfoList = map ANVarInfoToVarInfo ANVarInfoList
                val _ = map (CTX.addVarBind context) ANVarInfoList
                val (constBinds,resultSizeEntries) = sizesToVarInfos context resultSizeList 
                val instructions = constBinds @ (genReturn context varInfoList resultSizeEntries)
              in 
                (varInfoList, resultTyList, resultSizeList, instructions)
              end

        val code =
            case innermost of
              AN.ANCONSTANT {value,...} => 
              [constantToInstruction context (value, List.hd destinationEntryList)]

            | AN.ANEXCEPTIONTAG {tagValue,...} => 
              [SI.LoadWord{value = tagValue, destination = List.hd destinationEntryList}]

            | AN.ANLABEL _ => raise Control.Bug "not implemented"

            | AN.ANENVACC {nestLevel, offset, loc} =>
              [
                SI.AccessNestedEnv
                {
                  nestLevel = nestLevel,
                  offset = offset, 
                  variableSize = List.hd destinationSizeList,
                  destination = List.hd destinationEntryList
                }
              ]
              
            | AN.ANPRIMAPPLY{primName, argExpList, argTyList, argSizeExpList, loc} =>
              let
                val (constBinds, argEntries) = argsToVarInfos context argExpList
              in
                constBinds @
                [
                 SI.CallPrim
                     {
                      primitive = findPrimitive primName,
                      argEntries = argEntries,
                      destination = List.hd destinationEntryList
                     }
                ]
              end

            | AN.ANFOREIGNAPPLY{funExp, argExpList, argTyList, argSizeExpList, convention, loc} =>
              let
                val argSizes = map ANExpToSize argSizeExpList
                val resultSize = List.hd destinationSizeList
                val argsCount = BT.IntToUInt32(List.length argExpList)
                val switchTag = 
                    if !Control.LARGEFFISWITCH then
                      funTypeToCaseTag (argSizes, resultSize)
                    else argsCount
                val (constBinds, closureEntry::argEntries) = argsToVarInfos context (funExp::argExpList)
              in
                constBinds @
                [
                 SI.ForeignApply
                     {
                      (* Ohori: Dec 17, 2006.
                       * If LARGEFFISWITCH is enableed then the switchTag is set
                       * to a encoded type information otherwise it is same as
                       * the number of args.
                       *)
                      switchTag = switchTag,
                      convention = convention,
                      closureEntry = closureEntry,
                      argEntries = argEntries,
                      destination = List.hd destinationEntryList
                    }
                ]
              end

            | AN.ANEXPORTCALLBACK{funExp, argSizeExpList, resultSizeExpList, loc} =>
              let
                val argSizes = map ANExpToSize argSizeExpList
                val resultSizes = map ANExpToSize resultSizeExpList
                val (constBinds, closureEntry) = argToVarInfo context funExp
              in
                constBinds @
                [
                  SI.RegisterCallback
                      {
                        sizeTag = funTypeToCaseTag (argSizes, List.hd resultSizes),
                        closureEntry = closureEntry,
                        destination = List.hd destinationEntryList
                      }
                ]
              end

            | AN.ANRECORD {bitmapExp, totalSizeExp, fieldList, fieldTyList, fieldSizeExpList, loc} =>
              let
                val (constBinds1, bitmapEntry::sizeEntry::fieldEntries) =
                    argsToVarInfos context (bitmapExp::totalSizeExp::fieldList)
                val (constBinds2, fieldSizeEntries) =
                    argsToVarInfos context fieldSizeExpList
              in
                constBinds1 @ constBinds2 @
                [
                 SI.MakeBlock
                     {
                      bitmapEntry = bitmapEntry,
                      sizeEntry = sizeEntry,
                      fieldEntries = fieldEntries,
                      fieldSizeEntries = fieldSizeEntries,
                      destination = List.hd destinationEntryList
                     }
                ]
              end

            | AN.ANENVRECORD {bitmapExp, totalSize, fieldList, fieldTyList, fieldSizeExpList, fixedSizeList, loc} =>
              let
                val (constBinds, bitmapEntry::fieldEntries) =
                    argsToVarInfos context (bitmapExp::fieldList)
              in
                constBinds @
                [
                 SI.MakeFixedSizeBlock
                     {
                      bitmapEntry = bitmapEntry,
                      size = totalSize,
                      fieldEntries = fieldEntries,
                      fieldSizes = fixedSizeList,
                      destination = List.hd destinationEntryList
                     }
                ]
              end

            | AN.ANARRAY{bitmapExp, sizeExp, initialValue, elementTy, elementSizeExp, loc} =>
              let
                val (constBinds, [bitmapEntry,sizeEntry,initialValueEntry]) =
                    argsToVarInfos context [bitmapExp,sizeExp,initialValue]
              in
                constBinds @
                [
                 SI.MakeArray
                     {
                      bitmapEntry = bitmapEntry,
                      sizeEntry = sizeEntry,
                      initialValueEntry = initialValueEntry,
                      initialValueSize = ANExpToSize elementSizeExp,
                      destination = List.hd destinationEntryList
                     }
                ]
              end

            | AN.ANMODIFY{recordExp, nestLevelExp, offsetExp, valueExp, valueTy, valueSizeExp, loc} =>
              let
                val (constBinds, [blockEntry,nestLevelEntry,fieldOffsetEntry,newValueEntry]) =
                    argsToVarInfos context [recordExp,nestLevelExp,offsetExp,valueExp]
                val destinationEntry = List.hd destinationEntryList
              in
                constBinds @
                [
                 SI.CopyBlock
                     {
                      blockEntry = blockEntry,
                      nestLevelEntry = nestLevelEntry,
                      destination = destinationEntry
                     },
                 SI.SetNestedFieldIndirect
                    {
                      blockEntry = destinationEntry,
                      nestLevelEntry = nestLevelEntry,
                      fieldOffsetEntry = fieldOffsetEntry,
                      fieldSize = ANExpToSize valueSizeExp,
                      newValueEntry = newValueEntry
                    }
                ]
              end

            | AN.ANCLOSURE {codeExp = AN.ANLABEL {codeId,...}, envExp, loc} =>
              let
                val (constBinds, envEntry) = argToVarInfo context envExp
              in
                constBinds @
                [
                 SI.MakeClosure
                     {
                      entryPoint = codeId,
                      envEntry = envEntry,
                      destination = List.hd destinationEntryList
                     }
                ]
              end

            | AN.ANCLOSURE _ => raise Control.Bug "not implemented"

            | AN.ANRECCLOSURE {codeExp = AN.ANLABEL {codeId,...}, loc} =>
              let
                val ENVANVarInfo = newANVarInfo AN.BOXED
                val ENVVarInfo = ANVarInfoToVarInfo ENVANVarInfo
                val _ = CTX.addVarBind context ENVANVarInfo
              in
                [
                  SI.GetEnv{destination = ENVVarInfo},
                  SI.MakeClosure
                      {
                        entryPoint = codeId,
                        envEntry = ENVVarInfo,
                        destination = List.hd destinationEntryList
                      }
                ]
              end

            | AN.ANRECCLOSURE _ => raise Control.Bug "not implemented"

            | AN.ANGETGLOBAL {arrayIndex, valueOffset, loc} =>
              [
               SI.GetGlobal
                   {
                    globalArrayIndex = arrayIndex,
                    offset = valueOffset,
                    variableSize = List.hd destinationSizeList,
                    destination = List.hd destinationEntryList
                   }
              ]

            | AN.ANSETGLOBAL {arrayIndex, valueOffset, valueExp, valueTy, valueSize, loc} =>
              let
                val (constBinds, newValueEntry) = argToVarInfo context valueExp
              in
                constBinds @
                [
                 SI.SetGlobal
                     {
                      globalArrayIndex = arrayIndex,
                      offset = valueOffset,
                      variableSize = 
                      case valueSize of 
                        0w1 => SI.SINGLE
                      | 0w2 => SI.DOUBLE
                      | _ => raise Control.Bug "invalid size",
                      newValueEntry = newValueEntry
                     }
                ]
              end

            | AN.ANINITARRAY {arrayIndex, arraySize, elementTy = AN.ATOM, loc} =>
              [
               SI.InitGlobalArrayUnboxed
                   {
                    globalArrayIndex = arrayIndex,
                    arraySize = arraySize
                   }
              ]

            | AN.ANINITARRAY {arrayIndex, arraySize, elementTy = AN.BOXED, loc} =>
              [
               SI.InitGlobalArrayBoxed
                   {
                    globalArrayIndex = arrayIndex,
                    arraySize = arraySize
                   }
              ]

            | AN.ANINITARRAY {arrayIndex, arraySize, elementTy = AN.DOUBLE, loc} =>
              [
               SI.InitGlobalArrayDouble
                   {
                    globalArrayIndex = arrayIndex,
                    arraySize = arraySize
                   }
              ]

            | AN.ANINITARRAY _ => raise Control.Bug "invalid global array's element type"

            | AN.ANGETFIELD{arrayExp, offsetExp, loc} =>
              let
                val (constBinds, [blockEntry,fieldOffsetEntry]) =
                    argsToVarInfos context [arrayExp,offsetExp]
              in
                constBinds @
                [
                 SI.GetFieldIndirect
                     {
                      blockEntry = blockEntry,
                      fieldOffsetEntry = fieldOffsetEntry,
                      fieldSize = List.hd destinationSizeList,
                      destination = List.hd destinationEntryList
                     }
                ]
              end

            | AN.ANSELECT {recordExp, nestLevelExp, offsetExp, loc} =>
              let
                val (constBinds, [blockEntry,nestLevelEntry,fieldOffsetEntry]) =
                    argsToVarInfos context [recordExp,nestLevelExp,offsetExp]
              in
                constBinds @
                [
                 SI.GetNestedFieldIndirect
                     {
                      blockEntry = blockEntry,
                      nestLevelEntry = nestLevelEntry,
                      fieldOffsetEntry = fieldOffsetEntry,
                      fieldSize = List.hd destinationSizeList,
                      destination = List.hd destinationEntryList
                     }
                ]
              end

            | AN.ANSETFIELD{arrayExp, offsetExp, valueExp, valueTy, valueSizeExp, loc} =>
              let
                val (constBinds, [blockEntry,fieldOffsetEntry,newValueEntry]) =
                    argsToVarInfos context [arrayExp,offsetExp,valueExp]
              in
                constBinds @
                [
                 SI.SetFieldIndirect
                     {
                      blockEntry = blockEntry,
                      fieldOffsetEntry = fieldOffsetEntry,
                      fieldSize = ANExpToSize valueSizeExp,
                      newValueEntry = newValueEntry
                     },
                 SI.LoadInt{value = 0, destination = List.hd destinationEntryList}
                ]
              end

            | _ => raise Control.Bug "innermost expression is expected."

      in
        code @ tailCode
      end

  and linearizerDecl context (AN.ANVAL {boundVarList = ANBoundVarInfoList, sizeExpList, boundExp, loc}) =
      let
        val _ = map (CTX.addVarBind context) ANBoundVarInfoList
        val boundVarInfoList = map ANVarInfoToVarInfo ANBoundVarInfoList
        val boundTyList = map #ty ANBoundVarInfoList
        val variableSizeList = map ANExpToSize sizeExpList
        val newContext = CTX.setBoundPosition (context, boundVarInfoList, boundTyList, variableSizeList)
      in
        linearizeExp newContext boundExp
      end
    | linearizerDecl context (AN.ANCLUSTER _) = raise Control.Bug "clusters should be bound to top level"

  and linearizeDeclList context declList = List.concat (map (linearizerDecl context) declList)

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
  fun linearizeFunction enclosingContext loc (funDecl : AN.funDecl) =
      let
        val context = CTX.createContext enclosingContext (funDecl, loc)
        val bodyCode = linearizeExp context (#bodyExp funDecl)
        val constantCode = CTX.getConstantInstructions context
      in
        {
         name = {id = #codeId funDecl, displayName = ID.toString (#codeId funDecl)},
         loc = loc,
         args = map ANVarInfoToVarInfo (#argVarList funDecl),
         instructions = bodyCode @ constantCode
        }
      end

  fun linearizeCluster {frameInfo : AN.frameInfo, entryFunctions, innerFunctions, isRecursive, loc} =
      let
        val context = CTX.createInitialContext ()
        val functionCodes = map (linearizeFunction context loc) (entryFunctions @ innerFunctions)
        val tyvars = #tyvars frameInfo

        (* group local variables by their type*)
        fun groupByType
                (
                  (ANVarInfo : AN.varInfo),
                  (atoms, pointers, doubles, records, unboxedRecords)
                ) =
            let 
              val varInfo = ANVarInfoToVarInfo ANVarInfo
              fun insertRecord tyvarid records=
                  let
                    val varsOfTyVar =
                        case TMap.find (records, tyvarid) of
                          NONE => [varInfo]
                        | SOME vars => varInfo :: vars
                  in TMap.insert (records, tyvarid, varsOfTyVar) end
            in
              case #ty ANVarInfo of
                AN.BOXED => (atoms, varInfo :: pointers, doubles, records, unboxedRecords)
              | AN.ATOM => (varInfo :: atoms, pointers, doubles, records, unboxedRecords)
              | AN.DOUBLE => (atoms, pointers, varInfo :: doubles, records, unboxedRecords)
              | AN.GENERIC tyvarid => (atoms, pointers, doubles, insertRecord tyvarid records, unboxedRecords)
              | AN.SINGLE tyvarid => (atoms, pointers, doubles, insertRecord tyvarid records, unboxedRecords)
              | AN.UNBOXED tyvarid => (atoms, pointers, doubles, records, insertRecord tyvarid unboxedRecords)
            end
        val localVars = CTX.getVarBinds context
        val (atomVarIDs, pointerVarIDs, doubleVarIDs, recordVarIDsMap, unboxedRecordVarIDsMap) = 
            foldl groupByType ([], [], [], TMap.empty, TMap.empty) localVars

        val bitmapFrees = 
            case #bitmapFree frameInfo of
              AN.ANCONSTANT {value = CT.WORD 0w0,...} => []
            | AN.ANENVACC{nestLevel = 0w0, offset = i,...} => [i]
            | _ =>
              raise Control.Bug "constant(0w0) or envacc(0w0,i) is expected"

        val tagArgs =
            map 
                (fn (AN.ANVAR{varInfo,...}) => ANVarInfoToVarInfo varInfo)
                (#tagArgList frameInfo)

        val recordVarIDLists =
            map
            (fn tyvarid =>
                case TMap.find (recordVarIDsMap, tyvarid) of
                  SOME varids => varids
                | NONE => [])
            tyvars

        val unboxedRecordVarIDLists = TMap.listItems unboxedRecordVarIDsMap

        (* unboxed records are always located after other record to guarantee that their 
         * bit tags are zero.
         * This is just a temporary solution to minimizing the changes of the later phases
         *)
        val frameInfo = 
            {
              bitmapvals = {args = tagArgs, frees = bitmapFrees},
              atoms = atomVarIDs,
              pointers = pointerVarIDs,
              doubles = doubleVarIDs,
              records = recordVarIDLists @ unboxedRecordVarIDLists
            }
      in
        {
         frameInfo = frameInfo,
         functionCodes = functionCodes,
         loc = loc
        } : SI.clusterCode
      end

  (****************************************)

  fun linearize declList =
      let
        val clusterCodes =
            map 
                (fn (AN.ANCLUSTER arg) => linearizeCluster arg
                  | (AN.ANVAL _) => raise Control.Bug "invalid cluster"
                )
                (rev declList)
        fun convertMainCode {name, loc, args, instructions} =
            {
             name = name,
             loc = loc,
             args = args, 
             instructions = 
               map 
                   (fn SI.Return_MV _ => SI.Exit | instruction => instruction)
                   instructions
            }
        fun convertMainCluster {frameInfo, functionCodes = [mainFunction], loc} =
            {
             frameInfo = frameInfo,
             functionCodes = [convertMainCode mainFunction],
             loc = loc
            }
      in
        case clusterCodes of 
          [] => []
        | (mainCluster::rest) => (convertMainCluster mainCluster)::rest
      end

end
