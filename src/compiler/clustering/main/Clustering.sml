(**
 * clustering
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure Clustering : CLUSTERING = struct
  structure MV = MultipleValueCalc
  structure AT = AnnotatedTypes
  structure ATU = AnnotatedTypesUtils
  open ClusterCalc

  fun transformExp exp =
      case exp of
        MV.MVFOREIGNAPPLY {funExp, funTy, argExpList, convention, loc} =>
        CCFOREIGNAPPLY
            {
             funExp = transformExp funExp, 
             funTy = funTy,
             argExpList = map transformExp argExpList,
             convention = convention,
             loc = loc
            }
      | MV.MVEXPORTCALLBACK {funExp, funTy, loc} =>
        CCEXPORTCALLBACK
            {
             funExp = transformExp funExp,
             funTy = funTy,
             loc = loc
            }
      | MV.MVSIZEOF {ty, loc} => CCSIZEOF {ty = ty, loc = loc}
      | MV.MVCONSTANT v => CCCONSTANT v
      | MV.MVEXCEPTIONTAG v => CCEXCEPTIONTAG v
      | MV.MVVAR v => CCVAR v
      | MV.MVGETGLOBAL v => CCGETGLOBAL v 
      | MV.MVSETGLOBAL {arrayIndex, valueIndex, valueExp, valueTy, loc} =>
        CCSETGLOBAL
            {
             arrayIndex = arrayIndex,
             valueIndex = valueIndex,
             valueExp = transformExp valueExp, 
             valueTy = valueTy,
             loc = loc
            }
      | MV.MVINITARRAY v => CCINITARRAY v
      | MV.MVGETFIELD {arrayExp, indexExp, elementTy, loc} =>
        CCGETFIELD
            {
             arrayExp = transformExp arrayExp,
             indexExp = transformExp indexExp,
             elementTy = elementTy,
             loc = loc
            }
      | MV.MVSETFIELD {valueExp, arrayExp, indexExp, elementTy, loc} =>
        CCSETFIELD
            {
             valueExp = transformExp valueExp,
             arrayExp = transformExp arrayExp,
             indexExp = transformExp indexExp,
             elementTy = elementTy,
             loc = loc
            }
      | MV.MVSETTAIL {consExp, newTailExp, listTy, consRecordTy, tailLabel, loc} =>
        CCSETTAIL
            {
             consExp = transformExp consExp,
             newTailExp = transformExp newTailExp,
             tailLabel = tailLabel,
             listTy = listTy, 
             consRecordTy = consRecordTy, 
             loc = loc
            }
      | MV.MVARRAY {sizeExp, initialValue, elementTy, loc} =>
        CCARRAY
            {
             sizeExp = transformExp sizeExp,
             initialValue = transformExp initialValue,
             elementTy = elementTy,
             loc = loc
            }
      | MV.MVPRIMAPPLY {primInfo as {ty,...}, argExpList, loc} =>
        CCPRIMAPPLY
            {
             primInfo = primInfo,
             argExpList = map transformExp argExpList,
             loc = loc
            }
      | MV.MVAPPM {funExp, funTy, argExpList, loc} =>
        CCAPPM
            {
             funExp = transformExp funExp,
             funTy = funTy,
             argExpList = map transformExp argExpList,
             loc = loc
            }
      | MV.MVLET {localDeclList, mainExp, loc} =>
        CCLET
            {
             localDeclList = map transformDecl localDeclList,
             mainExp = transformExp mainExp,
             loc = loc
            }
      | MV.MVMVALUES {expList, tyList, loc} =>
        CCMVALUES
            {
             expList = map transformExp expList,
             tyList = tyList,
             loc = loc
            }
      | MV.MVRECORD {expList, recordTy, annotation, isMutable, loc} =>
        CCRECORD
            {
             expList = map transformExp expList,
             recordTy = recordTy,
             annotation = annotation,
             isMutable = isMutable,
             loc = loc
            }
      | MV.MVSELECT {recordExp, label, recordTy, loc} =>
        CCSELECT
            {
             recordExp = transformExp recordExp,
             label = label,
             recordTy = recordTy,
             loc = loc
            }
      | MV.MVMODIFY {recordExp, recordTy, label, valueExp, valueTy, loc} =>
        CCMODIFY
            {
             recordExp = transformExp recordExp,
             recordTy = recordTy,
             label = label,
             valueExp = transformExp valueExp,
             valueTy = valueTy,
             loc = loc
            }
      | MV.MVRAISE {argExp, resultTy, loc} =>
        CCRAISE
            {
             argExp = transformExp argExp,
             resultTy = resultTy,
             loc = loc
            }
      | MV.MVHANDLE {exp, exnVar, handler, loc} =>
        CCHANDLE
            {
             exp = transformExp exp,
             exnVar = exnVar,
             handler = transformExp handler,
             loc = loc
            }
      | MV.MVFNM {argVarList, funTy, bodyExp, annotation, loc} => 
        let
          val boundVar = ATU.newVar funTy
          val newExp = 
              MV.MVLET
                  {
                   localDeclList =
                   [MV.MVVAL {boundVars = [boundVar], boundExp = exp, loc = loc}],
                   mainExp = MV.MVVAR {varInfo = boundVar, loc = loc},
                   loc = loc
                  }
        in
          transformExp newExp
        end
      | MV.MVPOLY {btvEnv, expTyWithoutTAbs, exp = bodyExp, loc} =>
        let
          val polyTy = AT.POLYty{boundtvars = btvEnv, body = expTyWithoutTAbs}
          val boundVar = ATU.newVar polyTy
          val newExp = 
              MV.MVLET
                  {
                   localDeclList =
                   [MV.MVVAL {boundVars = [boundVar], boundExp = exp, loc = loc}],
                   mainExp = MV.MVVAR {varInfo = boundVar, loc = loc},
                   loc = loc
                  }
        in
          transformExp newExp
        end
      | MV.MVTAPP {exp, expTy, instTyList, loc} =>
        CCTAPP
            {
             exp = transformExp exp,
             expTy = expTy,
             instTyList = instTyList,
             loc = loc
            }
      | MV.MVSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        CCSWITCH
            {
             switchExp = transformExp switchExp,
             expTy = expTy,
             branches = 
             map 
                 (fn {constant, exp} => 
                     {constant = transformExp constant, exp = transformExp exp}
                 )
                 branches,
             defaultExp = transformExp defaultExp,
             loc = loc
            }
      | MV.MVCAST {exp, expTy, targetTy, loc} =>
        CCCAST
            {
             exp = transformExp exp,
             expTy = expTy,
             targetTy = targetTy,
             loc = loc
            }

  and transformRecBind {boundVar, boundExp = MV.MVFNM {argVarList, funTy, bodyExp, annotation, loc}} =
      {funVar = boundVar, argVarList = argVarList, bodyExp = transformExp bodyExp, annotation = annotation}
    | transformRecBind {boundVar, boundExp} = 
      let
        val s = MultipleValueCalcFormatter.mvexpToString boundExp
      in
        raise Control.Bug ("invalid recbind:" ^ s)
      end

  and transformDecl decl = 
      case decl of
        MV.MVVAL 
            {
             boundVars = [boundVar], 
             boundExp = MV.MVFNM {argVarList, funTy, bodyExp, loc = funLoc, annotation}, 
             loc
            } =>
        CCCLUSTER
            {
             entryFunctions = 
             [
              {
               funVar = boundVar,
               argVarList = argVarList,
               bodyExp = transformExp bodyExp,
               annotation = annotation
              }
             ],
             innerFunctions = [],
             isRecursive = false,
             loc = funLoc
            }
      | MV.MVVAL 
            {
             boundVars = [{id, displayName, ty = AT.POLYty {boundtvars, body}}], 
             boundExp = MV.MVPOLY 
                            {
                             btvEnv, 
                             expTyWithoutTAbs, 
                             exp = MV.MVFNM {argVarList, funTy, bodyExp, annotation, loc = funLoc}, 
                             loc = polyLoc
                            }, 
             loc = valLoc 
            } =>
        CCPOLYCLUSTER
            {
             btvEnv = btvEnv,
             entryFunctions = 
             [
              {
               funVar = {id = id, displayName = displayName, ty = body},
               argVarList = argVarList,
               bodyExp = transformExp bodyExp,
               annotation = annotation
              }
             ],
             innerFunctions = [],
             isRecursive = false,
             loc = funLoc
            }
      | MV.MVVAL 
            {
             boundVars = [{id, displayName, ty = AT.POLYty {boundtvars, body}}],
             boundExp = MV.MVPOLY {btvEnv, expTyWithoutTAbs, exp, loc = polyLoc}, 
             loc = valLoc 
            } =>
        CCPOLYVAL
            {
             btvEnv = btvEnv,
             boundVar = {id = id, displayName = displayName, ty = body},
             boundExp = transformExp exp,
             loc = polyLoc
            }
      | MV.MVVAL {boundVars, boundExp, loc} =>
        CCVAL
            {
             boundVars = boundVars,
             boundExp = transformExp boundExp,
             loc = loc
            }
      | MV.MVVALREC {recbindList, loc} =>
        CCCLUSTER
            {
             entryFunctions = map transformRecBind recbindList,
             innerFunctions = [],
             isRecursive = true,
             loc = loc
            }
      | MV.MVVALPOLYREC {btvEnv, recbindList, loc} =>
        CCPOLYCLUSTER
            {
             btvEnv = btvEnv,
             entryFunctions = map transformRecBind recbindList,
             innerFunctions = [],
             isRecursive = true,
             loc = loc
            }
        
  fun transform declList = 
      map transformDecl declList

end
