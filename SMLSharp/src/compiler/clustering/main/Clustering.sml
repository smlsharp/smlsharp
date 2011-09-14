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


   val newLocalId = VarID.generate

   fun newVar ty = 
      let
          val id = newLocalId()
      in
        {displayName = "$" ^ VarID.toString id,
         ty = ty,
         varId = Types.INTERNAL id}
      end


  fun isLocalFunTy ty =
    case ty of
      AT.FUNMty {funStatus = {codeStatus = ref AT.LOCAL,...},...} => true
    | _ => false

  fun isLocalFunVar {displayName, ty, varId} =
    isLocalFunTy ty

  fun transformExp exp =
      case exp of
        MV.MVFOREIGNAPPLY {funExp, funTy, argExpList, attributes, loc} =>
        CCFOREIGNAPPLY
            {
             funExp = transformExp funExp, 
             funTy = funTy,
             argExpList = map transformExp argExpList,
             attributes = attributes,
             loc = loc
            }
      | MV.MVEXPORTCALLBACK {funExp as MV.MVFNM {funTy=_, argVarList, bodyExp,
                                                 loc=funLoc, annotation},
                             funTy as AT.FUNMty {funStatus=
                                                 {codeStatus=ref AT.CLOSURE,
                                                  ...},...},
                             attributes, loc} =>
        let
          val entryName = newVar funTy
        in
          CCLET {localDeclList =
                   [CCCALLBACKCLUSTER
                      {funDecl = {funVar = entryName,
                                  argVarList = argVarList,
                                  bodyExp = transformExp bodyExp,
                                  loc = funLoc},
                       attributes = attributes,
                       loc = funLoc}],
                 mainExp = CCVAR {varInfo = entryName, loc = loc},
                 loc = loc}
        end
      | MV.MVEXPORTCALLBACK {funExp, funTy, attributes, loc} =>
        raise Control.Bug "transformExp: MVEXPORTCALLBACK"
      | MV.MVTAGOF {ty, loc} => CCTAGOF {ty = ty, loc = loc}
      | MV.MVSIZEOF {ty, loc} => CCSIZEOF {ty = ty, loc = loc}
      | MV.MVINDEXOF {label, recordTy, loc} =>
        CCINDEXOF {label=label, recordTy=recordTy, loc=loc}
      | MV.MVCONSTANT v => CCCONSTANT v
      | MV.MVGLOBALSYMBOL v => CCGLOBALSYMBOL v
      | MV.MVEXCEPTIONTAG v => CCEXCEPTIONTAG v
      | MV.MVVAR v => CCVAR v
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
      | MV.MVARRAY {sizeExp, initialValue, elementTy, isMutable, loc} =>
        CCARRAY
            {
             sizeExp = transformExp sizeExp,
             initialValue = transformExp initialValue,
             elementTy = elementTy,
             isMutable = isMutable,
             loc = loc
            }
      | MV.MVCOPYARRAY {srcExp, srcIndexExp, dstExp, dstIndexExp, lengthExp, elementTy, loc} =>
        CCCOPYARRAY
            {
             srcExp = transformExp srcExp,
             srcIndexExp = transformExp srcIndexExp,
             dstExp = transformExp dstExp,
             dstIndexExp = transformExp dstIndexExp,
             lengthExp = transformExp lengthExp,
             elementTy = elementTy,
             loc = loc
            }
      | MV.MVPRIMAPPLY {primInfo, argExpList, instTyList, loc} =>
        CCPRIMAPPLY
            {
             primInfo = primInfo,
             argExpList = map transformExp argExpList,
             instTyList = instTyList,
             loc = loc
            }
      | MV.MVAPPM {funExp, funTy, argExpList, loc} =>
         if isLocalFunTy funTy then
           CCLOCALAPPM
            {
             funExp = transformExp funExp,
             funTy = funTy,
             argExpList = map transformExp argExpList,
             loc = loc
             }
         else
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
             localDeclList = transformTop localDeclList,
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
      | MV.MVSELECT {recordExp, indexExp, label, recordTy, resultTy, loc} =>
        CCSELECT
            {
             recordExp = transformExp recordExp,
             indexExp = transformExp indexExp,
             label = label,
             recordTy = recordTy,
             resultTy = resultTy,
             loc = loc
            }
      | MV.MVMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy,
                     loc} =>
        CCMODIFY
            {
             recordExp = transformExp recordExp,
             recordTy = recordTy,
             indexExp = transformExp indexExp,
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
      | MV.MVFNM 
          {
           argVarList, 
           funTy, 
           bodyExp, 
           annotation, 
           loc} => 
        let
          val boundVar = newVar funTy
          val newExp = 
              MV.MVLET
                  {
                   localDeclList =
                   [
                    MV.MVVAL {boundVars = [boundVar], 
                              boundExp = exp, loc = loc}
                    ],
                   mainExp = MV.MVVAR {varInfo = boundVar, loc = loc},
                   loc = loc
                  }
        in
          transformExp newExp
        end
       | MV.MVPOLY {btvEnv, expTyWithoutTAbs, exp = bodyExp, loc} =>
        let
          val polyTy = AT.POLYty{boundtvars = btvEnv, body = expTyWithoutTAbs}
          val boundVar = newVar polyTy
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
      {funVar = boundVar, argVarList = argVarList, bodyExp = transformExp bodyExp, loc = loc}
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
          boundExp = 
            MV.MVFNM 
            {
             funTy = AT.FUNMty {funStatus = {codeStatus = ref AT.CLOSURE,...},...} , 
             argVarList, 
             bodyExp, 
             loc = funLoc, 
             annotation
             }, 
          loc
          }
        =>
         [CCCLUSTER
          {
           entryFunctions = 
           [
            {
             funVar = boundVar,
             argVarList = argVarList,
             bodyExp = transformExp bodyExp,
             loc = funLoc
             }
            ],
           innerFunctions = [],
           isRecursive = false,
           loc = funLoc
           }]
      | MV.MVVAL 
         {
          boundVars = [boundVar], 
          boundExp = 
            MV.MVFNM 
            {
             funTy = AT.FUNMty {funStatus = {codeStatus = ref AT.LOCAL,...},...} , 
             argVarList, 
             bodyExp, 
             loc = codeLoc, 
             annotation
             }, 
          loc
          } 
        =>
         [CCVALCODE
            {
             code = 
             [
              {
               funVar = boundVar,
               argVarList = argVarList, 
               bodyExp = transformExp bodyExp,
               loc = codeLoc
               }
              ],
             isRecursive = false,
             loc = loc
             }
         ]
      | MV.MVVAL 
         {
          boundVars = [{displayName, ty = AT.POLYty {boundtvars, body}, varId}], 
          boundExp = 
            MV.MVPOLY 
            {
             btvEnv, 
             expTyWithoutTAbs, 
             exp = MV.MVFNM 
                    {
                     argVarList, 
                     funTy = AT.FUNMty {funStatus = {codeStatus = ref AT.CLOSURE,...},...},
                     bodyExp, 
                     annotation, 
                     loc = funLoc
                     }, 
             loc = polyLoc
             }, 
            loc = valLoc 
            } 
         =>
         [CCPOLYCLUSTER
          {
           btvEnv = btvEnv,
           entryFunctions = 
           [
            {
             funVar = {displayName = displayName, ty = body, varId = varId},
             argVarList = argVarList,
             bodyExp = transformExp bodyExp,
             loc = funLoc
             }
            ],
           innerFunctions = [],
           isRecursive = false,
           loc = funLoc
           }]
      | MV.MVVAL
          {
           boundVars = [boundVar as {displayName, ty = AT.POLYty {boundtvars, body}, varId}], 
           boundExp = 
             MV.MVPOLY 
             {
              btvEnv, 
              expTyWithoutTAbs, 
              exp = MV.MVFNM 
                      {
                       argVarList, 
                       funTy = AT.FUNMty {funStatus = {codeStatus = ref AT.LOCAL,...},...}, 
                       bodyExp, 
                       annotation,
                       loc = codeLoc
                       }, 
              loc = polyLoc
              }, 
             loc 
            } 
          =>
          [CCPOLYVALCODE
           {
            btvEnv = btvEnv,
            code = 
            [
             {
              funVar = {displayName = displayName, ty = body, varId = varId},
              argVarList = argVarList,
              bodyExp = transformExp bodyExp,
              loc = codeLoc
              }
             ],
            isRecursive = false,
            loc = loc
            }]
      | MV.MVVAL 
         {
          boundVars = 
           [
            {
             displayName, 
             ty = AT.POLYty {boundtvars, body}, 
             varId
             }
            ],
          boundExp = MV.MVPOLY {btvEnv, expTyWithoutTAbs, exp, loc = polyLoc}, 
          loc = valLoc 
          } =>
         [CCPOLYVAL
          {
           btvEnv = btvEnv,
           boundVar = {displayName = displayName, ty = body, varId = varId},
           boundExp = transformExp exp,
           loc = polyLoc
           }]
        | MV.MVVAL {boundVars, boundExp, loc} =>
         [CCVAL
          {
           boundVars = boundVars,
           boundExp = transformExp boundExp,
           loc = loc
           }]
      | MV.MVVALREC {recbindList, loc} =>
         if List.all (fn x => isLocalFunVar (#boundVar x)) recbindList then
           [CCVALCODE
            {
             code = map transformRecBind recbindList,
             isRecursive = true,
             loc = loc
             }]
         else 
           [CCCLUSTER
            {
             entryFunctions = map transformRecBind recbindList,
             innerFunctions = [],
             isRecursive = true,
             loc = loc
            }]

  and transformTop declList =
      foldr (fn (x,z) => transformDecl x @ z) nil declList

  fun transform declList = 
      let
        val newDecList = transformTop declList
      in
          newDecList
      end
      handle exn => raise exn

end
