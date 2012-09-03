(**
 * Function Localization
 * @copyright (c) 2006 - 2007, Tohoku University.
 * @author Atsushi Ohori
 * @version $$
 *
 *
 *)
structure FunctionLocalize : FUNCTION_LOCALIZE = struct
local
  structure T = Types
  structure AT = AnnotatedTypes
  structure ATU = AnnotatedTypesUtils
  structure FID = FunIDMap
  datatype position = datatype FunIDMap.position 
  open MultipleValueCalc
in

  fun insertVariable varEnv (varInfo as {displayName, ty, varId}) = 
    VarIdEnv.insert(varEnv, varId, varInfo)

  fun insertVariables varEnv [] = varEnv
    | insertVariables varEnv (var::rest) =
      insertVariables (insertVariable varEnv var) rest

  fun convertTy ty =
    case ty of
      AT.SINGLETONty sty =>
      AT.SINGLETONty (convertSingletonTy sty)
    | AT.ERRORty => ty
    | AT.DUMMYty int => ty
    | AT.BOUNDVARty int => ty
    | AT.FUNMty 
        {
         argTyList = argTyListtyList, 
         bodyTy = bodyTyty, 
         annotation = annotation,
         funStatus = funStatus 
         }
        =>
          AT.FUNMty
          {
           argTyList = map convertTy argTyListtyList, 
           bodyTy = convertTy bodyTyty,
           annotation = annotation,
           funStatus = funStatus
           }

    | AT.MVALty tyList => AT.MVALty (map convertTy tyList)

    | AT.RECORDty 
        {
         fieldTypes = tySEnvMap, 
         annotation = recordAnnotationRef 
         }
        =>
        AT.RECORDty
        {
         fieldTypes = SEnv.map convertTy tySEnvMap, 
         annotation = recordAnnotationRef 
         }

    | AT.RAWty
        {
         tyCon = tyCon,
         args = tyList
         }
        =>
        AT.RAWty 
        {
         tyCon = tyCon,
         args = map convertTy tyList
         }

    | AT.SPECty 
        {
         tyCon = tyCon,
         args = tyList
         }
        =>
        AT.SPECty 
        {
         tyCon = tyCon,
         args = map convertTy tyList
         }

    | AT.POLYty 
        {
         boundtvars = btvKindIEnvMap, 
         body = ty
         }
        =>
        AT.POLYty 
        {
         boundtvars = convertBtvEnv btvKindIEnvMap, 
         body = convertTy ty
         }
(*
    | AT.SPECty ty => AT.SPECty (convertTy ty)
*)

  and convertSingletonTy singletonTy =
    case singletonTy of
      AT.INSTCODEty {oprimId, oprimPolyTy, name, keyTyList, instTyList} =>
      AT.INSTCODEty
        {
         oprimId = oprimId,
         oprimPolyTy = convertTy oprimPolyTy,
         name = name,
         keyTyList = map convertTy keyTyList,
         instTyList = map convertTy instTyList
        }
    | AT.INDEXty (label, ty) =>
      AT.INDEXty (label, convertTy ty)
    | AT.TAGty ty =>
      AT.TAGty (convertTy ty)
    | AT.SIZEty ty =>
      AT.SIZEty (convertTy ty)
    | AT.RECORDSIZEty ty =>
      AT.RECORDSIZEty (convertTy ty)
    | AT.RECORDBITMAPty (index, ty) =>
      AT.RECORDBITMAPty (index, convertTy ty)

   and convertRecKind recordKind =
     case recordKind of
       AT.UNIV => AT.UNIV
     | AT.REC tySEnvMap => AT.REC (SEnv.map convertTy tySEnvMap)
     | AT.OPRIMkind {instances, operators} => 
       AT.OPRIMkind
         {instances = map convertTy instances,
          operators =
          map
          (fn {oprimId,oprimPolyTy,name,keyTyList,instTyList} =>
              {oprimId = oprimId,
               oprimPolyTy = convertTy oprimPolyTy,
               name = name,
               keyTyList = map convertTy keyTyList,
               instTyList = map convertTy instTyList
               }
          )
          operators
         }

  and convertBtvKind 
    {
     id = int, 
     recordKind = recordKind, 
     eqKind = eqKind, 
     instancesRef = tyListRef as (ref tyList)
     } 
    =
    {
     id = int, 
     recordKind = convertRecKind recordKind, 
     eqKind = eqKind, 
     instancesRef = (tyListRef := map convertTy tyList; tyListRef)
     } 
  and convertTvKind 
    {
     id = int,
     recordKind = recordKind,
     eqKind = eqKind,
     tyvarName = stringOption
     } 
    =
    {
     id = int,
     recordKind = convertRecKind recordKind,
     eqKind = eqKind,
     tyvarName = stringOption
     }
  and convertBtvEnv btvEnv = BoundTypeVarID.Map.map convertBtvKind btvEnv

  fun convertPrimInfo {name, ty} = {name = name, ty = convertTy ty}

  fun convertVarInfo {displayName = string, ty = ty, varId = varId} =
    {displayName = string, ty = convertTy ty, varId = varId}

  (* FIXME: how to determine whether it is static poly? *)
(*
  fun isStaticPoly (btvEnv : AT.btvEnv) =
      let
        val param = 
          {
           tagTyCon = fn id => (),
           sizeTyCon =  fn id => (),
           indexTyCon = fn (id,label) => ()
           }
      in
        case ATU.generateExtraList param btvEnv of
          nil => true
        | _ => false
      end
*)
  fun isStaticPoly btvEnv = false


  fun analyze varEnv position currentFunStatus mvexp =
    case mvexp of
      MVFOREIGNAPPLY 
      {
       funExp = funExpMvexp,
       funTy = funTyTy, 
       argExpList = argExpListMvexpList, 
       attributes,
       loc
       }
       =>
      let
        val funExpMvexp = analyze varEnv MIDDLE currentFunStatus funExpMvexp
        val funTyTy = convertTy funTyTy
        val argExpListMvexpList = map (analyze varEnv MIDDLE currentFunStatus) argExpListMvexpList
      in
        MVFOREIGNAPPLY 
        {
         funExp = funExpMvexp,
         funTy = funTyTy, 
         argExpList = argExpListMvexpList, 
         attributes = attributes,
         loc = loc
         }
      end
    | MVEXPORTCALLBACK 
      {
       funExp = funExpMvexp,
       funTy = funTyTy,
       attributes = attributes,
       loc
       }
       =>
      let
        val funExpMvexp = analyze varEnv MIDDLE currentFunStatus funExpMvexp
        val funTyTy = convertTy funTyTy
        val _ = ATU.coerceClosure funTyTy
      in
        MVEXPORTCALLBACK 
        {
         funExp = funExpMvexp,
         funTy = funTyTy,
         attributes = attributes,
         loc = loc
         }
      end
    | MVTAGOF 
      {
       ty, 
       loc
       }
       =>
        MVTAGOF 
        {
         ty = convertTy ty, 
         loc = loc
         }
    | MVSIZEOF 
      {
       ty, 
       loc
       }
       =>
        MVSIZEOF 
        {
         ty = convertTy ty, 
         loc = loc
         }
    | MVINDEXOF
      {
       label,
       recordTy, 
       loc
       }
       =>
        MVINDEXOF 
        {
         label = label,
         recordTy = convertTy recordTy,
         loc = loc
         }
    | MVCONSTANT 
      {
       value = valueConstant, 
       loc = loc
       }
       =>
        MVCONSTANT 
        {
         value = valueConstant, 
         loc = loc
         }
    | MVGLOBALSYMBOL _ => mvexp
    | MVEXCEPTIONTAG 
      {
       tagValue = tagValueInt, 
       displayName,
       loc
       }
       =>
        MVEXCEPTIONTAG 
        {
         tagValue = tagValueInt, 
         displayName = displayName,
         loc = loc
         }
    | MVVAR 
      {
       varInfo, 
       loc
       }
       =>
      let
        (* Here, var is used as a value.
         * So if it is a stauc funcvar then we coerce it to closure. 
         *)
        val newVarInfo = 
          case VarIdEnv.find (varEnv, #varId varInfo) of
            SOME (varInfo as {displayName, ty, varId}) => 
              (ATU.coerceClosure ty; varInfo)
          | NONE => convertVarInfo varInfo
      in
        MVVAR 
        {
         varInfo = newVarInfo, 
         loc = loc
         }
      end
    | MVGETFIELD 
      {
       arrayExp = arrayExpMvexp, 
       indexExp = indexExpMvexp, 
       elementTy = elementTyTy, 
       loc
       }
       =>
      let
        val arrayExpMvexp = analyze varEnv MIDDLE currentFunStatus arrayExpMvexp
        val indexExpMvexp = analyze varEnv MIDDLE currentFunStatus indexExpMvexp
        val elementTyTy = convertTy elementTyTy
      in
        MVGETFIELD 
        {
         arrayExp = arrayExpMvexp, 
         indexExp = indexExpMvexp, 
         elementTy = elementTyTy, 
         loc = loc
         }
      end
    | MVSETFIELD 
      {
       valueExp = valueExpMvexp, 
       arrayExp = arrayExpMvexp, 
       indexExp = indexExpMvexp, 
       elementTy = elementTyTy, 
       loc = loc
       }
       =>
      let
        val valueExpMvexp = analyze varEnv MIDDLE currentFunStatus valueExpMvexp
        val arrayExpMvexp = analyze varEnv MIDDLE currentFunStatus arrayExpMvexp
        val indexExpMvexp = analyze varEnv MIDDLE currentFunStatus indexExpMvexp
        val elementTyTy = convertTy elementTyTy
      in
        MVSETFIELD 
        {
         valueExp = valueExpMvexp, 
         arrayExp = arrayExpMvexp, 
         indexExp = indexExpMvexp, 
         elementTy = elementTyTy, 
         loc = loc
         }
      end
    | MVSETTAIL
      {
       consExp = consExpMvexp, 
       newTailExp = newTailExpMvexp, 
       tailLabel = tailLabelString,
       listTy = listTyTy,
       consRecordTy = consRecordTyTy,
       loc
       }
       =>
      let
        val consExpMvexp = analyze varEnv MIDDLE currentFunStatus consExpMvexp
        val newTailExpMvexp = analyze varEnv MIDDLE currentFunStatus newTailExpMvexp
        val listTyTy = convertTy listTyTy
        val consRecordTyTy = convertTy consRecordTyTy
      in
        MVSETTAIL
        {
         consExp = consExpMvexp, 
         newTailExp = newTailExpMvexp, 
         tailLabel = tailLabelString,
         listTy = listTyTy,
         consRecordTy = consRecordTyTy,
         loc = loc
         }
      end
    | MVARRAY
      {
       sizeExp = sizeExpMvexp, 
       initialValue = initialValueMvexp, 
       elementTy = elementTyTy,
       isMutable = isMutable,
       loc
       }
       =>
      let
        val sizeExpMvexp = analyze varEnv MIDDLE currentFunStatus sizeExpMvexp
        val initialValueMvexp =analyze varEnv MIDDLE currentFunStatus initialValueMvexp
        val elementTyTy = convertTy elementTyTy
      in
        MVARRAY
        {
         sizeExp = sizeExpMvexp, 
         initialValue = initialValueMvexp, 
         elementTy = elementTyTy,
         isMutable = isMutable,
         loc = loc
         }
      end
    | MVCOPYARRAY
      {
       srcExp = srcExpMvexp,
       srcIndexExp = srcIndexExpMvexp,
       dstExp = dstExpMvexp,
       dstIndexExp = dstIndexExpMvexp,
       lengthExp = lengthExpMvexp, 
       elementTy = elementTyTy, 
       loc
       }
       =>
      let
        val srcExpMvexp = analyze varEnv MIDDLE currentFunStatus srcExpMvexp
        val srcIndexExpMvexp = analyze varEnv MIDDLE currentFunStatus srcIndexExpMvexp
        val dstExpMvexp = analyze varEnv MIDDLE currentFunStatus dstExpMvexp
        val dstIndexExpMvexp = analyze varEnv MIDDLE currentFunStatus dstIndexExpMvexp
        val lengthExpMvexp = analyze varEnv MIDDLE currentFunStatus lengthExpMvexp
        val elementTyTy = convertTy elementTyTy
      in
        MVCOPYARRAY
        {
         srcExp = srcExpMvexp,
         srcIndexExp = srcIndexExpMvexp,
         dstExp = dstExpMvexp,
         dstIndexExp = dstIndexExpMvexp,
         lengthExp = lengthExpMvexp, 
         elementTy = elementTyTy, 
         loc = loc
         }
      end
    | MVPRIMAPPLY
      {
       primInfo = primInfoPriminfo, 
       argExpList = argExpListMvexplist,
       instTyList,
       loc
       }
       =>
      let
        val primInfoPriminfo = convertPrimInfo primInfoPriminfo
        val argExpListMvexplist = map (analyze varEnv MIDDLE currentFunStatus) argExpListMvexplist
      in
        MVPRIMAPPLY
        {
         primInfo = primInfoPriminfo, 
         argExpList = argExpListMvexplist,
         instTyList = instTyList,
         loc = loc
         }
      end
    | MVAPPM
      {
       funExp = funExpMvexp, 
       funTy = funTyTy, 
       argExpList = argExpListMvexplist,
       loc
       }
       =>
      let
        (*
         Here, we catch the staic function application by manually 
         analyze the function term. The possible static cases are
         (1) monomorphic variable
         (2) type application of a polymorphic variable
         *)
        val (funExpMvexp, funTyTy) = 
          case funExpMvexp of 
            MVVAR {varInfo, loc} => 
              (
               case VarIdEnv.find (varEnv, #varId varInfo) of
                 SOME (newVarInfo as {displayName, ty, varId}) => 
                   (
                    case ty of 
                      AT.FUNMty {funStatus, ...}
                      => FID.call (currentFunStatus, position, funStatus)
                    | _ => ();
                      (MVVAR {varInfo = newVarInfo, loc = loc}, ty)
                  )
               | NONE => 
                   let
                     val newVarInfo = convertVarInfo varInfo
                   in
                     (MVVAR{varInfo = newVarInfo, loc = loc}, #ty newVarInfo)
                   end
             )
           | MVTAPP 
              {
               exp = MVVAR {varInfo, loc =loc1}, 
               expTy, 
               instTyList, 
               loc = loc2
               } 
              =>
              (
               case VarIdEnv.find (varEnv, #varId varInfo) of
                 NONE => 
                   let
                     val newVarInfo = convertVarInfo varInfo
                     val newExpTy = convertTy expTy
                     val newInstTyList = map convertTy instTyList
                     val resultTy = ATU.tpappTy(newExpTy, newInstTyList)
                   in
                     (
                      MVTAPP 
                      {
                       exp = MVVAR {varInfo = newVarInfo, loc =loc1}, 
                       expTy = newExpTy, 
                       instTyList = newInstTyList, 
                       loc = loc2
                       },
                      resultTy
                     )
                   end
               | SOME (newVarInfo as {displayName, ty = polyFunTy, varId}) => 
                   let
                     val newInstTyList = map convertTy instTyList
                     val _ =
                       case polyFunTy of 
                         AT.POLYty{body = AT.FUNMty {funStatus,...},...}  => 
                           FID.call (currentFunStatus, position, funStatus)
                       | _ => ()
                     val newExp = MVVAR{varInfo = newVarInfo, loc = loc1}
                     val resultTy = ATU.tpappTy(polyFunTy, newInstTyList)
                   in
                     (
                      MVTAPP
                      {
                       exp = newExp,
                       expTy = polyFunTy,
                       instTyList = newInstTyList,
                       loc = loc2
                       },
                      resultTy
                      )
                   end
              )
           | _ => (analyze varEnv MIDDLE currentFunStatus funExpMvexp, convertTy funTyTy)
        val argExpListMvexplist = map (analyze varEnv MIDDLE currentFunStatus) argExpListMvexplist
      in
        MVAPPM
        {
         funExp = funExpMvexp, 
         funTy = funTyTy , 
         argExpList = argExpListMvexplist,
         loc = loc
         }
      end
    | MVLET
      {
       localDeclList = localDeclListMvdecllist,
       mainExp = mainExpMvexp,
       loc = loc
       }
       =>
      let
        val (localDeclListMvdecllist,newVarEnv) = analyzeDeclList varEnv currentFunStatus localDeclListMvdecllist
        val mainExpMvexp = analyze newVarEnv position currentFunStatus mainExpMvexp
      in
        MVLET
        {
         localDeclList = localDeclListMvdecllist,
         mainExp = mainExpMvexp,
         loc = loc
         }
      end
    | MVMVALUES 
      {
       expList = expListMvexplist, 
       tyList = tyListTylist, 
       loc
       }
       =>
      let
        val expListMvexplist = map (analyze  varEnv MIDDLE currentFunStatus) expListMvexplist
        val tyListTylist = map convertTy tyListTylist
      in
        MVMVALUES 
        {
         expList = expListMvexplist, 
         tyList = tyListTylist, 
         loc = loc
         }
      end
    | MVRECORD
      {
       expList = expListMvexplist,
       recordTy = recordTyTy,
       annotation = annotationAnnotationlabel,
       isMutable = isMutableBool,
       loc
       }
       =>
      let
        val expListMvexplist = map (analyze varEnv MIDDLE currentFunStatus) expListMvexplist
        val recordTyTy = convertTy recordTyTy
      in
        MVRECORD
        {
         expList = expListMvexplist,
         recordTy = recordTyTy,
         annotation = annotationAnnotationlabel,
         isMutable = isMutableBool,
         loc = loc
         }
      end
    | MVSELECT
      {
       recordExp = recordExpMvexp, 
       indexExp = indexMvexp,
       label = labelString,
       recordTy = recordTyTy, 
       resultTy = resultTyTy,
       loc
       }
       =>
      let
        val recordExpMvexp = analyze varEnv MIDDLE currentFunStatus recordExpMvexp
        val indexMvexp = analyze varEnv MIDDLE currentFunStatus indexMvexp
        val recordTyTy = convertTy recordTyTy
      in
        MVSELECT
        {
         recordExp = recordExpMvexp, 
         indexExp = indexMvexp,
         label = labelString,
         recordTy = recordTyTy, 
         resultTy = resultTyTy,
         loc = loc
         }
      end
    | MVMODIFY
      {
       recordExp = recordExpMvexp, 
       recordTy = recordTyTy, 
       indexExp = indexMvexp,
       label = labelString,
       valueExp = valueExpMvexp,
       valueTy = valueTyTy,
       loc
       }
       =>
      let
        val recordExpMvexp = analyze varEnv MIDDLE currentFunStatus recordExpMvexp
        val recordTyTy =  convertTy recordTyTy
        val indexMvexp = analyze varEnv MIDDLE currentFunStatus indexMvexp
        val valueExpMvexp = analyze varEnv MIDDLE currentFunStatus valueExpMvexp
        val valueTyTy =convertTy valueTyTy
      in
        MVMODIFY
        {
         recordExp = recordExpMvexp, 
         recordTy = recordTyTy, 
         indexExp = indexMvexp,
         label = labelString,
         valueExp = valueExpMvexp,
         valueTy = valueTyTy,
         loc = loc
         }
      end
    | MVRAISE
      {
       argExp = argExpMvexp, 
       resultTy = resultTyTy, 
       loc
       }
       =>
      let
        val argExpMvexp = analyze varEnv MIDDLE currentFunStatus argExpMvexp
        val resultTyTy = convertTy resultTyTy
      in
        MVRAISE
        {
         argExp = argExpMvexp, 
         resultTy = resultTyTy, 
         loc = loc
         }
      end
    | MVHANDLE
      {
       exp = expMvexp,
       exnVar = exnVarVarinfo,
       handler = handlerMvexp,
       loc
       }
       =>
      let
        val expMvexp = analyze varEnv MIDDLE currentFunStatus expMvexp
        val exnVarVarinfo = convertVarInfo exnVarVarinfo
        val handlerMvexp = 
          let
            val newFunStatus = ATU.newClosureFunStatus ()
          in
            analyze varEnv MIDDLE newFunStatus handlerMvexp
          end
      in
        MVHANDLE
        {
         exp = expMvexp,
         exnVar = exnVarVarinfo,
         handler = handlerMvexp,
         loc = loc
         }
      end
    | MVFNM arg =>
        let
          val newFunStatus = ATU.newClosureFunStatus()
        in
          analyzeFnm varEnv newFunStatus arg
        end

    | MVPOLY arg =>
        let
          val newFunStatus = ATU.newClosureFunStatus()
        in
          analyzePoly varEnv position newFunStatus arg
        end

    | MVTAPP
      {
       exp = expMvexp, 
       expTy = expTyTy, 
       instTyList = instTyListTylist, 
       loc
       }
       =>
      let
        val expMvexp = analyze varEnv MIDDLE currentFunStatus expMvexp
        val expTyTy = convertTy expTyTy
        val instTyListTylist = map convertTy instTyListTylist
      in
        MVTAPP
        {
         exp = expMvexp, 
         expTy = expTyTy, 
         instTyList = instTyListTylist, 
         loc = loc
         }
      end
    | MVSWITCH
      {
       switchExp = switchExpMvexp, 
       expTy = expTyTy, 
       branches = branchesConstantMvexpExpMvexpRecordlist,  
       defaultExp = defaultExpMvexp, 
       loc
       }
       =>
      let
        val switchExpMvexp = analyze varEnv MIDDLE currentFunStatus switchExpMvexp
        val expTyTy = convertTy expTyTy
        val branchesConstantMvexpExpMvexpRecordlist = 
          map 
          (fn {constant,exp} => {constant = constant, exp = analyze varEnv position currentFunStatus exp})
          branchesConstantMvexpExpMvexpRecordlist
        val defaultExpMvexp = analyze varEnv position currentFunStatus defaultExpMvexp
      in
        MVSWITCH
        {
         switchExp = switchExpMvexp, 
         expTy = expTyTy, 
         branches = branchesConstantMvexpExpMvexpRecordlist, 
         defaultExp = defaultExpMvexp, 
         loc = loc
         }
      end
    | MVCAST 
      {
       exp = expMvexp, 
       expTy = expTyTy, 
       targetTy = targetTyTy, 
       loc
       }
       =>
      let
        val expMvexp = analyze varEnv position currentFunStatus expMvexp
        val expTyTy = convertTy expTyTy
        val targetTyTy = convertTy targetTyTy
      in
        MVCAST 
        {
         exp = expMvexp, 
         expTy = expTyTy, 
         targetTy = targetTyTy, 
         loc = loc
         }
      end

  and analyzeFnm varEnv newFunStatus 
      {
       argVarList = argVarListVarinfolist, 
       funTy = funTyTy, 
       bodyExp = bodyExpMvexp,
       annotation = annotationAnnotationlabel,
       loc 
       }
       =
    let
      val argVarListVarinfolist = map convertVarInfo argVarListVarinfolist
      val bodyExpMvexp = analyze varEnv TAIL newFunStatus bodyExpMvexp
      val funTyTy = 
        case funTyTy of
          AT.FUNMty 
          {
           argTyList = argTyListtyList, 
           bodyTy= bodyTyty, 
           funStatus,
           annotation = functionAnnotationRef
           }
          => AT.FUNMty 
              {
               argTyList = map convertTy argTyListtyList, 
               bodyTy = convertTy bodyTyty,
               annotation = functionAnnotationRef,
               funStatus = newFunStatus
               }
        | _ => convertTy funTyTy
    in
       MVFNM
       {
        argVarList = argVarListVarinfolist,
        funTy = funTyTy,
        bodyExp = bodyExpMvexp,
        annotation = ATU.freshAnnotationLabel(),
        loc = loc
        }
    end
  
  and analyzePoly varEnv position newFunStatus 
    {
     btvEnv = btvEnvBtvenv,
     expTyWithoutTAbs = expTyWithoutTAbsTy, 
     exp = expMvexp, 
     loc
     }
    =
    let
      val btvEnvBtvenv = convertBtvEnv btvEnvBtvenv
      val expTyWithoutTAbsTy = 
        case expTyWithoutTAbsTy of 
          AT.FUNMty 
          {
           argTyList = argTyListtyList, 
           bodyTy= bodyTyty, 
           funStatus,
           annotation = functionAnnotationRef
           }
          => AT.FUNMty 
              {
               argTyList = map convertTy argTyListtyList, 
               bodyTy = convertTy bodyTyty,
               annotation = functionAnnotationRef,
               funStatus = newFunStatus
               }
        | _ => convertTy expTyWithoutTAbsTy
      val expMvexp = 
            case expMvexp of 
              MVFNM fnmArg => analyzeFnm varEnv newFunStatus fnmArg
            | _ => analyze varEnv position newFunStatus expMvexp
    in
      MVPOLY
      {
       btvEnv = btvEnvBtvenv,
       expTyWithoutTAbs = expTyWithoutTAbsTy, 
       exp = expMvexp, 
       loc = loc
       }
    end

  and analyzeDecl varEnv currentFunStatus mvdecl =
     case mvdecl of 
     MVVAL
        {
         boundVars = [boundVarInfo as {displayName, ty = funTy, varId}],
         boundExp = MVFNM fnmArg,
         loc
         }
         =>
      let
        val newFunStatus = ATU.newLocalFunStatus currentFunStatus
        val funTy = 
          case funTy of
            AT.FUNMty 
            {
             argTyList = argTyListtyList, 
             bodyTy= bodyTyty, 
             funStatus,
             annotation = functionAnnotationRef
             }
            => AT.FUNMty 
            {
             argTyList = map convertTy argTyListtyList, 
             bodyTy = convertTy bodyTyty,
             annotation = functionAnnotationRef,
             funStatus = newFunStatus
             }
          | _ => convertTy funTy
        val newBoundExp = analyzeFnm varEnv newFunStatus fnmArg
        val newBoundVar = {displayName = displayName, ty = funTy, varId = varId}
        val newVarEnv = insertVariable varEnv newBoundVar
      in
        (
         MVVAL
         {
          boundVars = [newBoundVar],
          boundExp = newBoundExp,
          loc = loc
          },
         newVarEnv
        )
      end
    | MVVAL
        {
         boundVars = [boundVarInfo as {displayName, ty = funTy, varId}],
         boundExp = MVPOLY (polyArg as {btvEnv, exp, ...}),
         loc
         }
         =>
      let
        val newFunStatus = 
          case exp of 
            MVFNM _ =>
              if isStaticPoly btvEnv then
                ATU.newLocalFunStatus currentFunStatus
              else ATU.newClosureFunStatus()
          | _ => ATU.newClosureFunStatus()
        val funTy = 
          case funTy of
            AT.POLYty 
            {
             boundtvars = btvKind,
             body =
             AT.FUNMty 
               {
                argTyList = argTyListtyList, 
                bodyTy= bodyTyty,
                funStatus,
                annotation = functionAnnotationRef
                }
            }
            =>
            AT.POLYty 
            {
             boundtvars = btvKind,
             body = 
             AT.FUNMty 
               {
                argTyList = map convertTy argTyListtyList, 
                bodyTy = convertTy bodyTyty,
                annotation = functionAnnotationRef,
                funStatus = newFunStatus
                }
             }
          | _ => convertTy funTy
        val newBoundExp = analyzePoly varEnv MIDDLE newFunStatus polyArg
        val newBoundVar = {displayName = displayName, ty = funTy, varId = varId}
        val newVarEnv = insertVariable varEnv newBoundVar
      in
        (
         MVVAL
         {
          boundVars = [newBoundVar],
          boundExp = newBoundExp,
          loc = loc
          },
         newVarEnv
        )
      end
    | MVVAL
        {
         boundVars = boundVarsVarInfoList,
         boundExp = boundExpMvexp,
         loc
         }
         =>
        let
          val boundVarsVarInfoList = map convertVarInfo boundVarsVarInfoList
          val boundExpMvexp = analyze varEnv MIDDLE currentFunStatus boundExpMvexp
        in
          (
           MVVAL
           {
            boundVars = boundVarsVarInfoList,
            boundExp = boundExpMvexp,
            loc = loc
            },
           varEnv
           )
        end
    | MVVALREC {recbindList, loc} =>
        let
          val newLocalFunStatus = ATU.newLocalFunStatus currentFunStatus
          val (newBoudVarList, newRecbindList) = analyzeRecBind varEnv newLocalFunStatus currentFunStatus recbindList
          val newVarEnv = insertVariables varEnv newBoudVarList
        in
          (
           MVVALREC
           {
            recbindList = newRecbindList,
            loc = loc
            },
           newVarEnv
          )
        end

  and analyzeRecBind varEnv newLocalFunStatus currentFunStatus recbindList =
    let
      val newFunStatusNewBoundVarRecBindList =
        map 
        (fn (recBind as {boundVar = boundVar as {ty, varId, displayName},...})  =>
           let
             val newFunStatus = 
               case varId of  
                 T.INTERNAL _ =>  newLocalFunStatus
               | T.EXTERNAL _  => ATU.newClosureFunStatus()
             val newTy = 
               case ty of 
                 AT.FUNMty {argTyList, annotation, bodyTy, ...} =>
                   AT.FUNMty {
                                argTyList = map convertTy argTyList,
                                bodyTy = convertTy bodyTy,
                                annotation = annotation,
                                funStatus = newFunStatus
                                }
               | _ => convertTy ty
             val newBoundVar = 
               {
                displayName = displayName,
                ty = newTy,
                varId = varId
                }
           in
             {
              newFunStatus = newFunStatus,
              newBoundVar = newBoundVar,
              recBind = recBind
              }
           end)
        recbindList
      val newVarEnv = 
        insertVariables 
        varEnv 
        (map (fn {newBoundVar,...}=> newBoundVar) newFunStatusNewBoundVarRecBindList)
      fun analyzeBind {
                       newFunStatus, 
                       newBoundVar, 
                       recBind = {boundVar, boundExp}
                       } =
        let
          val (argVarList, funTy, bodyExp, bodyLoc) =
            case boundExp of
              MVFNM {argVarList, funTy, bodyExp, loc, ...} =>
                (argVarList, funTy, bodyExp, loc)
            | _ => raise Control.Bug "Non fn in val rec"
          val (annotation, bodyTy) = 
            case funTy of
              AT.FUNMty {annotation, bodyTy,...} => (annotation, bodyTy)
            | _ => raise Control.Bug "Non fn in val rec"
          val newBoundExp = 
            let
              val newArgVarList =
                map 
                convertVarInfo
                argVarList
              val newBodyExp  = analyze newVarEnv TAIL newFunStatus bodyExp
              val newFunTy = 
                AT.FUNMty
                {
                 argTyList = map #ty newArgVarList,
                 bodyTy = convertTy bodyTy,
                 annotation = annotation,
                 funStatus = newFunStatus
                 }
            in
               MVFNM
               {
                argVarList = newArgVarList,
                funTy = newFunTy,
                bodyExp = newBodyExp,
                annotation = ATU.freshAnnotationLabel(),
                loc = bodyLoc
                }
            end
        in
          {boundVar = newBoundVar, boundExp = newBoundExp}
        end
    in
      (
       map (fn {newBoundVar,...}=> newBoundVar) newFunStatusNewBoundVarRecBindList,
       map analyzeBind newFunStatusNewBoundVarRecBindList
       )
    end
    
  and analyzeDeclList varEnv currentFunStatus ([]) = ([],varEnv)
    | analyzeDeclList varEnv currentFunStatus (decl::rest) =
      let
        val (newDecl, newVarEnv) = analyzeDecl varEnv currentFunStatus decl
        val (newRest, newVarEnv) = analyzeDeclList newVarEnv currentFunStatus rest
      in
        (newDecl::newRest, newVarEnv)
      end

  fun analyzeBasicBlock varEnv currentFunStatus basicBlock =
      case basicBlock of
          MVVALBLOCK {code, exnIDSet} =>
          let
              val (newCode, newVarEnv) = 
                  analyzeDeclList varEnv currentFunStatus code
          in
              (MVVALBLOCK {code = newCode, exnIDSet = exnIDSet},
               newVarEnv)
          end
        | MVLINKFUNCTORBLOCK x => (MVLINKFUNCTORBLOCK x,  varEnv)

  fun analyzeBasicBlockList varEnv currentFunStatus ([]) = ([],varEnv)
    | analyzeBasicBlockList varEnv currentFunStatus (block::rest) =
      let
          val (newBlock, newVarEnv) = analyzeBasicBlock varEnv currentFunStatus block
          val (newRest, newVarEnv) = analyzeBasicBlockList newVarEnv currentFunStatus rest
      in
          (newBlock::newRest, newVarEnv)
      end

  fun analyzeTopBlock varEnv currentFunStatus block =
      case block of
          MVBASICBLOCK basicBlock =>
          let
              val (newBasicBlock, newVarEnv) = 
                   analyzeBasicBlock varEnv currentFunStatus basicBlock
          in
              (MVBASICBLOCK newBasicBlock, newVarEnv)
          end
        | MVFUNCTORBLOCK {name, bodyCode, formalAbstractTypeIDSet, formalVarIDSet, formalExnIDSet,
                          generativeExnIDSet, generativeVarIDSet} => 
          (* MVFUNCTOR & MVLINKFUNCTOR are in the top level.
           *)
          let
              val (newBodyCode, _) = 
                  analyzeBasicBlockList VarIdEnv.empty (ATU.globalFunStatus()) bodyCode
          in
              (MVFUNCTORBLOCK {name = name, 
                               formalAbstractTypeIDSet = formalAbstractTypeIDSet, 
                               formalVarIDSet = formalVarIDSet,
                               formalExnIDSet = formalExnIDSet,
                               generativeExnIDSet = generativeExnIDSet, 
                               generativeVarIDSet = generativeVarIDSet,
                               bodyCode = newBodyCode}, varEnv)
          end
          
  and analyzeTopBlockList varEnv currentFunStatus ([]) = ([],varEnv)
    | analyzeTopBlockList varEnv currentFunStatus (block::rest) =
      let
          val (newBlock, newVarEnv) = analyzeTopBlock varEnv currentFunStatus block
          val (newRest, newVarEnv) = analyzeTopBlockList newVarEnv currentFunStatus rest
      in
          (newBlock::newRest, newVarEnv)
      end

  fun localize blockList =
      let
        val _ = FID.initialize ()
        val newFunStatus = ATU.globalFunStatus()
        val (newBlockList, _) = analyzeTopBlockList VarIdEnv.empty newFunStatus blockList
        val _ = FID.solve ()
      in
          newBlockList
      end
      handle exn => raise exn

end
end
