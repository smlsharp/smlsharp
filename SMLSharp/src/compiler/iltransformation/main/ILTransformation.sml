(**
 * @copyright (c) 2006, Tohoku niversity.
 * @author YAMATODANI Kiyoshi
 * @author Nguyen Huu-Duc
 * @version $Id: ILTransformation.sml,v 1.11 2008/01/22 06:31:35 bochao Exp $
 *)
structure ILTransformation : ILTRANSFORMATION = struct
  structure BT = BasicTypes
  structure AN = ANormal
  structure ANU = ANormalUtils
  structure CT = ConstantTerm
  structure IL = IntermediateLanguage
  structure ILU = ILUtils

   fun newVar varKind ty = 
       let
         val id = VarID.generate ()
       in
         {varId = Types.INTERNAL id,
          displayName = "$" ^ (VarID.toString id),
          ty = ty,
          varKind = varKind}
       end

  datatype position =
           Tail of
           {
            resultSizeExpList : IL.expression list,
            resultTyList : AN.ty list
           }
         | Bound of 
           {
            boundVarList : IL.varInfo list,
            boundSizeExpList : IL.expression list
           }
         | Result of
           {
            resultSizeExpList : IL.expression list,
            resultTyList : AN.ty list
           }

  fun wordToConstant w = IL.Constant (CT.WORD w)

  fun intToConstant i = IL.Constant (CT.INT i)

  fun transformVarKind AN.LOCAL = IL.LOCAL
    | transformVarKind AN.ARG = IL.ARG
    | transformVarKind AN.EXTERNAL = IL.GLOBAL

  fun transformVarInfo {varId, displayName, ty, varKind} =
      {varId = varId, displayName = displayName, ty = ty, varKind = transformVarKind varKind}

  fun transformArg (AN.ANVAR {varInfo as {varKind = AN.EXTERNAL,...}, loc}) = 
      raise Control.Bug "global in argument position"
    | transformArg (AN.ANVAR {varInfo, loc}) = IL.Variable (transformVarInfo varInfo)
    | transformArg (AN.ANCONSTANT {value, loc}) = IL.Constant value 
    | transformArg (AN.ANLABEL {codeId, loc}) = IL.Label codeId 
    | transformArg (AN.ANEXCEPTIONTAG {tagValue, loc}) = IL.ExceptionTag tagValue
    | transformArg _ = raise Control.Bug "invalid argument"

  fun generateUnitReturnCode position loc =
      case position of
        Tail {resultTyList,...} =>
        IL.Return
            {
             valueExpList = [intToConstant 0],
             valueSizeExpList = [wordToConstant 0w1],
             valueTyList = resultTyList,
             loc = loc
            }
      | Result {resultTyList,...} =>
        IL.Return
            {
             valueExpList = [intToConstant 0],
             valueSizeExpList = [wordToConstant 0w1],
             valueTyList = resultTyList,
             loc = loc
            }
      | Bound {boundVarList, boundSizeExpList} =>
        IL.Assign
            {
             variableList = boundVarList,
             variableSizeExpList = boundSizeExpList,
             valueExp = intToConstant 0,
             loc = loc
            }

  fun generateInnerTailCode position loc =
      case position of
        Tail {resultSizeExpList, resultTyList} =>
        let
          val boundVarList = map (newVar IL.LOCAL) resultTyList
          val tailCode =
              IL.Return
                  {
                   valueExpList = map IL.Variable boundVarList,
                   valueSizeExpList = resultSizeExpList,
                   valueTyList = resultTyList,
                   loc = loc
                  }
        in
          (boundVarList, resultSizeExpList, [tailCode])
        end
      | Result {resultSizeExpList, resultTyList} =>
        let
          val boundVarList = map (newVar IL.LOCAL) resultTyList
          val tailCode =
              IL.Return
                  {
                   valueExpList = map IL.Variable boundVarList,
                   valueSizeExpList = resultSizeExpList,
                   valueTyList = resultTyList,
                   loc = loc
                  }
        in
          (boundVarList, resultSizeExpList, [tailCode])
        end
      | Bound {boundVarList, boundSizeExpList} =>
        (boundVarList, boundSizeExpList, [])
        

  fun transformExp position (anexp as AN.ANVAR {varInfo as {varKind as AN.EXTERNAL,...}, loc}) =
      let
        val (boundVarList, boundSizeExpList, tailCode) = generateInnerTailCode position loc
        val code =
            IL.Assign
                {
                 variableList = boundVarList,
                 variableSizeExpList = boundSizeExpList,
                 valueExp = IL.Variable (transformVarInfo varInfo),
                 loc = loc
                }
      in
        IL.Sequence {statements = code::tailCode, loc = loc}
      end

    | transformExp position (anexp as AN.ANVAR {varInfo, loc}) =
      (
       case position of
         Tail {resultSizeExpList as [resultSizeExp], resultTyList} =>
         IL.Return 
             {
              valueExpList = [transformArg anexp],
              valueSizeExpList = [resultSizeExp],
              valueTyList = resultTyList, 
              loc = loc
             }
       | Result {resultSizeExpList as [resultSizeExp], resultTyList} =>
         IL.Return 
             {
              valueExpList = [transformArg anexp],
              valueSizeExpList = [resultSizeExp],
              valueTyList = resultTyList, 
              loc = loc
             }
       | Bound {boundVarList = [boundVar], boundSizeExpList = [boundSizeExp]} =>
         IL.Assign
             {
              variableList = [boundVar] , 
              variableSizeExpList = [boundSizeExp],
              valueExp = transformArg anexp,
              loc = loc
             }
       | _ => raise Control.Bug "position and exp do not match"
      )

    | transformExp position (AN.ANMVALUES {expList, tyList, sizeExpList, loc}) =
      (
       case position of
         Tail {resultSizeExpList, resultTyList} =>
         IL.Return
             {
              valueExpList = map transformArg expList,
              valueSizeExpList = resultSizeExpList,
              valueTyList = resultTyList,
              loc = loc
             }
       | Result {resultSizeExpList, resultTyList} =>
         IL.Return
             {
              valueExpList = map transformArg expList,
              valueSizeExpList = resultSizeExpList,
              valueTyList = resultTyList,
              loc = loc
             }
       | Bound {boundVarList, boundSizeExpList} =>
         IL.Sequence
             {
              statements = 
              ListPair.map
                  (fn ((boundVar, boundSizeExp), valueExp) =>
                      IL.Assign 
                          {
                           variableList = [boundVar], 
                           variableSizeExpList =  [boundSizeExp],
                           valueExp = transformArg valueExp,
                           loc = loc
                          }
                  )
                  (ListPair.zip(boundVarList,boundSizeExpList),expList),
              loc = loc
             }
      )      

    | transformExp position (AN.ANSETFIELD {arrayExp, offsetExp, valueExp, valueTy, valueSizeExp, loc}) =
      let
        val statement = 
            IL.ArrayUpdate
                {
                 arrayExp = transformArg arrayExp,
                 offsetExp = transformArg offsetExp,
                 newValueExp = transformArg valueExp,
                 newValueSizeExp = transformArg valueSizeExp,
                 newValueTy = valueTy,
                 loc = loc
                }
      in
        IL.Sequence {statements = [statement, generateUnitReturnCode position loc], loc = loc}
      end

    | transformExp position (AN.ANCOPYARRAY {srcExp, srcOffsetExp, dstExp, dstOffsetExp, lengthExp, elementTy, elementSizeExp, loc}) =
      let
        val statement = 
            IL.CopyArray
                {
                 srcExp = transformArg srcExp,
                 srcOffsetExp = transformArg srcOffsetExp,
                 dstExp = transformArg dstExp,
                 dstOffsetExp = transformArg dstOffsetExp,
                 lengthExp = transformArg lengthExp,
                 elementTy = elementTy,
                 elementSizeExp = transformArg elementSizeExp,
                 loc = loc
                }
      in
        IL.Sequence {statements = [statement, generateUnitReturnCode position loc], loc = loc}
      end

    | transformExp position (AN.ANAPPLY {funExp, argExpList, argTyList, argSizeExpList, loc}) =
      (
       case position of
         Tail {resultSizeExpList, resultTyList} =>
         if !Control.doTailCallOptimize 
         then
           IL.TailApply
               {
                funExp = transformArg funExp,
                argExpList = map transformArg argExpList,
                argSizeExpList = map transformArg argSizeExpList,
                argTyList = argTyList,
                loc = loc
               }
         else
           let
             val (boundVarList, boundSizeExpList, tailCode) = generateInnerTailCode position loc
             val callStatement =
                 IL.Assign
                     {
                      variableList = boundVarList,
                      variableSizeExpList = boundSizeExpList,
                      valueExp = 
                      IL.Apply
                          {
                           funExp = transformArg funExp,
                           argExpList = map transformArg argExpList,
                           argSizeExpList = map transformArg argSizeExpList,
                           argTyList = argTyList
                          },
                      loc = loc
                     }
           in
             IL.Sequence {statements = callStatement::tailCode, loc = loc}
           end
       | Result {resultSizeExpList, resultTyList} =>
         let
           val (boundVarList, boundSizeExpList, tailCode) = generateInnerTailCode position loc
           val callStatement =
               IL.Assign
                   {
                    variableList = boundVarList,
                    variableSizeExpList = boundSizeExpList,
                    valueExp = 
                    IL.Apply
                        {
                         funExp = transformArg funExp,
                         argExpList = map transformArg argExpList,
                         argSizeExpList = map transformArg argSizeExpList,
                         argTyList = argTyList
                        },
                    loc = loc
                   }
         in
           IL.Sequence {statements = callStatement::tailCode, loc = loc}
         end
       | Bound {boundVarList, boundSizeExpList} =>
         IL.Assign
             {
              variableList = boundVarList,
              variableSizeExpList = boundSizeExpList,
              valueExp = 
              IL.Apply
                  {
                   funExp = transformArg funExp,
                   argExpList = map transformArg argExpList,
                   argSizeExpList = map transformArg argSizeExpList,
                   argTyList = argTyList
                  },
              loc = loc
             }
      )

    | transformExp position (AN.ANCALL {funLabel, envExp, argExpList, argTyList, argSizeExpList, loc}) =
      raise Control.Bug "not implemented"

    | transformExp position (AN.ANRECCALL {codeExp, argExpList, argTyList, argSizeExpList, loc}) =
      (
       case position of
         Tail {resultSizeExpList, resultTyList} =>
         if !Control.doTailCallOptimize 
         then
           IL.RecursiveTailCall
               {
                funLabelExp = transformArg codeExp,
                argExpList = map transformArg argExpList,
                argSizeExpList = map transformArg argSizeExpList,
                argTyList = argTyList,
                loc = loc
               }
         else
           let
             val (boundVarList, boundSizeExpList, tailCode) = generateInnerTailCode position loc
             val callStatement =
                 IL.Assign
                     {
                      variableList = boundVarList,
                      variableSizeExpList = boundSizeExpList,
                      valueExp = 
                      IL.RecursiveCall
                          {
                           funLabelExp = transformArg codeExp,
                           argExpList = map transformArg argExpList,
                           argSizeExpList = map transformArg argSizeExpList,
                           argTyList = argTyList
                          },
                      loc = loc
                     }
           in
             IL.Sequence {statements = callStatement::tailCode, loc = loc}
           end
       | Result {resultSizeExpList, resultTyList} =>
         let
           val (boundVarList, boundSizeExpList, tailCode) = generateInnerTailCode position loc
           val callStatement =
               IL.Assign
                   {
                    variableList = boundVarList,
                    variableSizeExpList = boundSizeExpList,
                    valueExp = 
                    IL.RecursiveCall
                        {
                         funLabelExp = transformArg codeExp,
                         argExpList = map transformArg argExpList,
                         argSizeExpList = map transformArg argSizeExpList,
                         argTyList = argTyList
                        },
                    loc = loc
                   }
         in
           IL.Sequence {statements = callStatement::tailCode, loc = loc}
         end
       | Bound {boundVarList, boundSizeExpList} =>
         IL.Assign
             {
              variableList = boundVarList,
              variableSizeExpList = boundSizeExpList,
              valueExp = 
              IL.RecursiveCall
                  {
                   funLabelExp = transformArg codeExp,
                   argExpList = map transformArg argExpList,
                   argSizeExpList = map transformArg argSizeExpList,
                   argTyList = argTyList
                  },
              loc = loc
             }
      )

    | transformExp position (AN.ANINNERCALL {codeExp, argExpList, argTyList, argSizeExpList, loc}) =
      (
       case position of
         Tail {resultSizeExpList, resultTyList} =>
         if !Control.doTailCallOptimize 
         then
           IL.InnerTailCall
               {
                funLabelExp = transformArg codeExp,
                argExpList = map transformArg argExpList,
                argSizeExpList = map transformArg argSizeExpList,
                argTyList = argTyList,
                loc = loc
               }
         else
           let
             val (boundVarList, boundSizeExpList, tailCode) = generateInnerTailCode position loc
             val callStatement =
                 IL.Assign
                     {
                      variableList = boundVarList,
                      variableSizeExpList = resultSizeExpList,
                      valueExp = 
                      IL.InnerCall
                          {
                           funLabelExp = transformArg codeExp,
                           argExpList = map transformArg argExpList,
                           argSizeExpList = map transformArg argSizeExpList,
                           argTyList = argTyList
                          },
                      loc = loc
                     }
           in
             IL.Sequence {statements = callStatement::tailCode, loc = loc}
           end
       | Result {resultSizeExpList, resultTyList} =>
         let
           val (boundVarList, boundSizeExpList, tailCode) = generateInnerTailCode position loc
           val callStatement =
               IL.Assign
                   {
                    variableList = boundVarList,
                    variableSizeExpList = resultSizeExpList,
                    valueExp = 
                    IL.InnerCall
                        {
                         funLabelExp = transformArg codeExp,
                         argExpList = map transformArg argExpList,
                         argSizeExpList = map transformArg argSizeExpList,
                         argTyList = argTyList
                        },
                    loc = loc
                   }
         in
           IL.Sequence {statements = callStatement::tailCode, loc = loc}
         end
       | Bound {boundVarList, boundSizeExpList} =>
         IL.Assign
             {
              variableList = boundVarList,
              variableSizeExpList = boundSizeExpList,
              valueExp = 
              IL.InnerCall
                  {
                   funLabelExp = transformArg codeExp,
                   argExpList = map transformArg argExpList,
                   argSizeExpList = map transformArg argSizeExpList,
                   argTyList = argTyList
                  },
              loc = loc
             }
      )

    | transformExp position (AN.ANRAISE {argExp, loc}) =
      let
        val statement =
            IL.Raise
                {
                 exnExp = transformArg argExp,
                 loc = loc
                }
        val code = 
            case position of
              Tail {resultTyList,...} => statement
            | Result {resultTyList,...} => statement
            | Bound {boundVarList,boundSizeExpList} =>
              IL.Sequence
                  {
                   statements =
                   statement ::
                   (ListPair.map 
                        (fn (v,s) =>
                            IL.Assign
                                {
                                 variableList = [v],
                                 variableSizeExpList = [s],
                                 valueExp = intToConstant 0,
                                 loc = loc
                                 }
                        )
                        (boundVarList,boundSizeExpList)
                   ),
                   loc = loc
                  }
      in
        code
      end

    | transformExp position (AN.ANEXIT loc) = 
      IL.Exit loc

    | transformExp position (AN.ANLET {localDeclList, mainExp, loc}) =
      let
        val boundCode = map transformDecl localDeclList
        val mainCode = transformExp position mainExp
      in 
        IL.Sequence {statements = boundCode @ [mainCode], loc = loc} 
      end

    | transformExp position (AN.ANHANDLE{exp, exnVar, handler, loc}) =
      let
        val mainCodePosition =
            case position of 
              Tail {resultSizeExpList, resultTyList} =>
              Result {resultSizeExpList = resultSizeExpList, resultTyList = resultTyList}
            | _ => position
      in
        IL.Handle
            {
             mainCode = transformExp mainCodePosition exp,
             exnVar = transformVarInfo exnVar,
             handlerCode = transformExp position handler,
             loc = loc
            }
      end

    | transformExp position (AN.ANSWITCH{switchExp, expTy, branches, defaultExp, loc}) =
      IL.Switch
          {
           switchExp = transformArg switchExp,
           expTy = expTy,
           defaultBranch = transformExp position defaultExp,
           branches =
           map
               (fn {constant, exp} =>
                   {
                    constant = constant,
                    statement = transformExp position exp
                   }
               )
               branches,
           loc = loc
          }

    | transformExp position (AN.ANRECCLOSURE {codeExp, loc}) =
      let
        val envVar = newVar IL.LOCAL AN.BOXED
        val getEnvCode =
            IL.Assign
                {
                 variableList = [envVar],
                 variableSizeExpList = [wordToConstant 0w1],
                 valueExp = IL.GetEnv,
                 loc = loc
                }
        val (boundVarList, boundSizeExpList, tailCode) = generateInnerTailCode position loc
        val mainCode =
            IL.Assign
                {
                 variableList = boundVarList,
                 variableSizeExpList = boundSizeExpList,
                 valueExp = 
                 IL.MakeClosure 
                     {
                      funLabelExp = transformArg codeExp,
                      envExp = IL.Variable envVar
                     },
                 loc = loc
                }
      in
        IL.Sequence {statements = getEnvCode::mainCode::tailCode, loc = loc}
      end

    | transformExp position (AN.ANMODIFY {recordExp, nestLevelExp, offsetExp, valueExp, valueSizeExp, valueTy, loc}) =
      let
        val (boundVarList, boundSizeExpList, tailCode) = generateInnerTailCode position loc
        val copyCode =
            IL.Assign
                {
                 variableList = boundVarList,
                 variableSizeExpList = boundSizeExpList,
                 valueExp = 
                 IL.CopyBlock
                     {
                      recordExp = transformArg recordExp,
                      nestLevelExp = transformArg nestLevelExp
                     },
                 loc = loc
                }
        val recordUpdateCode =
            IL.RecordUpdate
                {
                 recordExp = IL.Variable (List.hd boundVarList),
                 nestLevelExp = transformArg nestLevelExp,
                 fieldOffsetExp = transformArg offsetExp,
                 fieldSizeExp = transformArg valueSizeExp,
                 fieldTy = valueTy,
                 newValueExp = transformArg valueExp,
                 loc = loc
                }
      in
        IL.Sequence {statements = copyCode::recordUpdateCode::tailCode, loc = loc}
      end

    | transformExp position (AN.ANSETTAIL {consExp, offsetExp, newTailExp, nestLevelExp, loc}) =
      let
        val statement =
            IL.SetTail
                {
                 consExp = transformArg consExp,
                 offsetExp = transformArg offsetExp,
                 nestLevelExp = transformArg nestLevelExp,
                 newTailExp = transformArg newTailExp,
                 loc = loc
                }
      in
        IL.Sequence {statements = [statement, generateUnitReturnCode position loc], loc = loc}
      end

    | transformExp position innermost =
      let
        val loc = ANU.getLocOfExp innermost
        val (boundVarList, boundSizeExpList, tailCode) = generateInnerTailCode position loc
        val boundExp = 
            case innermost of
              AN.ANFOREIGNAPPLY {funExp, argExpList, argTyList, argSizeExpList, attributes, loc} =>
              IL.ForeignApply
                  {
                   funExp = transformArg funExp,
                   argExpList = map transformArg argExpList,
                   argSizeExpList = map transformArg argSizeExpList,
                   argTyList = argTyList,
                   attributes = attributes
                  }
            | AN.ANEXPORTCALLBACK {funExp, argSizeExpList, resultSizeExpList, loc} =>
              IL.ExportCallback
                  {
                   funExp = transformArg funExp,
                   argSizeExpList = map transformArg argSizeExpList,
                   resultSizeExpList = map transformArg resultSizeExpList
                  }
            | AN.ANCONSTANT {value, loc} => IL.Constant value
            | AN.ANEXCEPTIONTAG {tagValue, loc} => IL.ExceptionTag tagValue
            | AN.ANENVACC {nestLevel, offset, loc} =>
              IL.AccessEnv
                  {
                   nestLevelExp = wordToConstant nestLevel,
                   offsetExp = wordToConstant offset
                  }
            | AN.ANLABEL {codeId, loc} => IL.Label codeId
            | AN.ANGETFIELD {arrayExp, offsetExp, loc} =>
              IL.ArraySub
                  {
                   arrayExp = transformArg arrayExp,
                   offsetExp = transformArg offsetExp
                  }
            | AN.ANARRAY {bitmapExp, sizeExp, initialValue, elementTy, elementSizeExp, isMutable, loc} =>
              IL.MakeArray
                  {
                   bitmapExp = transformArg bitmapExp,
                   sizeExp = transformArg sizeExp,
                   initialValueExp = transformArg initialValue,
                   elementSizeExp = transformArg elementSizeExp,
                   elementTy = elementTy,
                   isMutable = isMutable
                  }
            | AN.ANPRIMAPPLY {primName, argExpList, argTyList, argSizeExpList, loc} =>
              IL.CallPrim
                  {
                   primName = primName,
                   argExpList = map transformArg argExpList,
                   argSizeExpList = map transformArg argSizeExpList,
                   argTyList = argTyList
                  }
            | AN.ANRECORD {bitmapExp, totalSizeExp, fieldList, fieldSizeExpList, fieldTyList, isMutable, loc} =>
              IL.MakeBlock
                  {
                   bitmapExp = transformArg bitmapExp,
                   sizeExp = transformArg totalSizeExp,
                   fieldExpList = map transformArg fieldList,
                   fieldSizeExpList = map transformArg fieldSizeExpList,
                   fieldTyList = fieldTyList
                  }
            | AN.ANENVRECORD {bitmapExp, totalSize, fieldList, fieldSizeExpList, fixedSizeList, fieldTyList, loc} =>
              IL.MakeFixedSizeBlock
                  {
                   bitmapExp = transformArg bitmapExp,
                   sizeExp = wordToConstant totalSize,
                   fieldExpList = map transformArg fieldList,
                   fieldSizeExpList = map transformArg fieldSizeExpList,
                   fixedSizeExpList = map wordToConstant fixedSizeList,
                   fieldTyList = fieldTyList
                  }
            | AN.ANSELECT {recordExp, nestLevelExp, offsetExp, loc} =>
              IL.RecordSelect
                  {
                   recordExp = transformArg recordExp,
                   nestLevelExp = transformArg nestLevelExp,
                   fieldOffsetExp = transformArg offsetExp
                  }
            | AN.ANCLOSURE {codeExp, envExp, loc} =>
              IL.MakeClosure
                  {
                   funLabelExp = transformArg codeExp,
                   envExp = transformArg envExp
                  }
            | _ => raise Control.Bug "invalid inner expression"

        val statement = 
            IL.Assign
                {
                 variableList = boundVarList,
                 variableSizeExpList = boundSizeExpList,
                 valueExp = boundExp,
                 loc = loc
                }

      in
        IL.Sequence {statements = statement::tailCode, loc = loc}
      end
        
  and transformDecl (AN.ANVAL {boundVarList, sizeExpList, boundExp, loc}) =
      let
        val position = 
            Bound 
                {
                 boundVarList = map transformVarInfo boundVarList,
                 boundSizeExpList = map transformArg sizeExpList
                }
      in
        transformExp position boundExp
      end

    | transformDecl _ = raise Control.Bug "cluster should be bound to the top level"


  fun transformFunDecl (funDecl : AN.funDecl, loc) =
      let
        val resultSizeExpList = map transformArg (#resultSizeExpList funDecl)
        val resultTyList = #resultTyList funDecl
        val position =
            Tail
                {
                 resultSizeExpList = resultSizeExpList,
                 resultTyList = resultTyList
                }
      in
        {
         functionLabel = #codeId funDecl,
         argVarList = map transformVarInfo (#argVarList funDecl),
         bodyCode = transformExp position (#bodyExp funDecl),
         resultSizeExpList = resultSizeExpList,
         resultTyList = resultTyList,
         loc = loc
        } : IL.functionCode
      end

  fun transformCluster (AN.ANCLUSTER {frameInfo, entryFunctions, innerFunctions, isRecursive, loc}) =
      let
        fun transformFun funDecl = transformFunDecl (funDecl, loc)
        val ILEntryFunctions = map transformFun entryFunctions
        val ILInnerFunctions = map transformFun innerFunctions
        val ILFrameInfo =
            {
             tyvars = #tyvars frameInfo,
             bitmapFree = 
             (
              case #bitmapFree frameInfo of
                AN.ANCONSTANT {value as CT.WORD 0w0,...} => NONE
              | AN.ANENVACC {nestLevel = 0w0, offset,...} => SOME offset
              | _ => raise Control.Bug "invalid bitmapFree"
             ),
             tagArgs =
             map
                 (fn (AN.ANVAR {varInfo,...}) => transformVarInfo varInfo
                   | _ => raise Control.Bug "invalid tagArg"
                 )
                 (#tagArgList frameInfo)
            } : IL.frameInfo
      in
        {
         clusterLabel = VarID.generate(),
         frameInfo = ILFrameInfo,
         entryFunctions = ILEntryFunctions,
         innerFunctions = ILInnerFunctions,
         isRecursive = isRecursive,
         loc = loc
        } : IL.clusterCode
      end
    | transformCluster _ = raise Control.Bug "invalid cluster"

  fun transform clusterList =
      let
        val clusterCodes = map transformCluster clusterList
        val (mainCluster, functionLabel) = 
          case (rev clusterCodes) of
            (mainCluster as {entryFunctions = [{functionLabel,...}],...}) :: _ =>
              (mainCluster, functionLabel)
          | _ => raise Control.Bug "illeagal main clasuter: (iltransformation/main/ILTransformation.sml)"
      in
          {
            clusterCodes = clusterCodes,
            initFunctionLabel = functionLabel
           } : IL.moduleCode
      end

end
