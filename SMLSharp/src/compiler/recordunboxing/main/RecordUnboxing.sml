(**
 * record unboxing
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure RecordUnboxing : RECORDUNBOXING = struct 
  structure AT = AnnotatedTypes
  structure AC = AnnotatedCalc
  structure ATU = AnnotatedTypesUtils
  structure MVU = MultipleValueCalcUtils
  structure VEnv = VarID.Map
  structure T = Types
  open MultipleValueCalc

   fun newVar ty = 
       let
           val id = VarID.generate ()
       in
           {displayName = "$" ^ VarID.toString id,
            ty = ty,
            varId = Types.INTERNAL id}
       end

  (*====================================================================*)
  (* utilities *)
  fun genLabels (label,1) = [ATU.convertLabel label]
    | genLabels (label,n) = 
      let
        val label = ATU.convertLabel label
      in
        List.tabulate
            (
             n,
             (fn i => label ^ (ATU.convertNumericalLabel (i + 1)))
            )
      end

  fun flatTyList ty = 
      case ty
       of AT.MVALty tyList => tyList
        | _ => [ty]

  fun mvTy [ty] = ty
    | mvTy tyList = AT.MVALty tyList
          
  fun transformType ty =
      case ty of
        AT.INSTCODEty {oprimId, oprimPolyTy, name, keyTyList, instTyList} =>
        AT.INSTCODEty {oprimId = oprimId,
                       oprimPolyTy = oprimPolyTy,
                       name = name,
                       keyTyList =  map transformType keyTyList,
                       instTyList = map transformType instTyList
                      }
      | AT.ERRORty => ty
      | AT.DUMMYty _ => ty
      | AT.BOUNDVARty _ => ty
      | AT.FUNMty {argTyList, bodyTy, annotation, funStatus} =>
        AT.FUNMty
            {
             argTyList = List.concat (map (flatTyList o transformType) argTyList),
             bodyTy = transformType bodyTy,
             annotation = annotation,
             funStatus = funStatus
            }
      | AT.MVALty tyList =>
        mvTy (List.concat (map (flatTyList o transformType) tyList))
      | AT.RECORDty {fieldTypes, annotation as ref {boxed = false,...}} =>
        if !Control.doRecordUnboxing
        then mvTy (List.concat (map (flatTyList o transformType) (SEnv.listItems fieldTypes)))
        else AT.RECORDty {fieldTypes = transformFieldTypes fieldTypes, annotation = annotation}
      | AT.RECORDty {fieldTypes, annotation} =>
        AT.RECORDty {fieldTypes = transformFieldTypes fieldTypes, annotation = annotation}
      | AT.RAWty {tyCon, args} => 
        AT.RAWty {tyCon = tyCon, args = map transformType args}
      | AT.POLYty {boundtvars, body} =>
        AT.POLYty {boundtvars = IEnv.map transformBtvKind boundtvars, body = transformType body}
      | AT.SPECty _ => ty

  and transformBtvKind {id, recordKind, eqKind, instancesRef} =
        {
         id = id,
         recordKind = transformRecKind recordKind,
         eqKind = eqKind,
         instancesRef = instancesRef
        }

  and transformRecKind recordKind =
      case recordKind
       of AT.UNIV => AT.UNIV
        | AT.REC flty => AT.REC (transformFieldTypes flty)
        | AT.OPRIMkind {instances, operators} 
          =>
          AT.OPRIMkind
          {instances = map transformType instances,
           operators = 
             map
               (fn {oprimId, oprimPolyTy, name, keyTyList, instTyList} =>
                {oprimId = oprimId,
                 oprimPolyTy = oprimPolyTy,
                 name = name,
                 keyTyList =  map transformType keyTyList,
                 instTyList = map transformType instTyList}
                )
             operators
            }

  and transformFieldTypes flty =
      SEnv.foldli
          (fn (label,ty,S) =>
              case transformType ty of
                AT.MVALty tyList =>
                ListPair.foldl
                    (fn (label,ty,S) => SEnv.insert(S,label,ty))
                    S
                    (genLabels (label, List.length tyList),tyList)
              | newTy => SEnv.insert(S,ATU.convertLabel label,newTy)
          )
          SEnv.empty
          flty
  
  fun transformVar {displayName, ty, varId} =
      case flatTyList (transformType ty)
       of [ty] => [{displayName = displayName, ty = transformType ty, varId = varId}]
        | tyList => map newVar tyList

  fun indexesOf (label, recordTy) =
      case recordTy of
        AT.RECORDty {fieldTypes,...} =>
        let
          fun computeFirstIndex (n, []) = raise Control.Bug "label not found"
            | computeFirstIndex (n, (l,ty)::rest) =
              if l = label 
              then (n,ty) 
              else computeFirstIndex(n + ATU.cardinality (transformType ty),rest)
 
          val (firstIndex, fieldType) = computeFirstIndex(0,SEnv.listItemsi fieldTypes)
        in
          (firstIndex, ATU.cardinality(transformType fieldType))
        end
      | _ => raise Control.Bug "record type is expected" 
        
  fun labelsOf (label, recordTy) =
      case recordTy of
        AT.RECORDty {fieldTypes,...} =>
        let
          val fieldType =
              case SEnv.find(fieldTypes, label) of
                SOME ty => transformType ty
              | _ => raise Control.Bug "label not found"
        in
          genLabels(label, ATU.cardinality fieldType)
        end
      | _ => raise Control.Bug "record type is expected"

  fun makeLetExp(decls,exp,loc) =
      case decls
       of [] => exp
        | _ => MVLET{localDeclList = decls, mainExp = exp, loc = loc}

  (*====================================================================*)
  (* context *)

  structure CTX =
  struct

  type context = {varEnv : (AC.varInfo list) VarID.Map.map, tyEnv : AT.btvKind IEnv.map}

  val empty = {varEnv = VarID.Map.empty, tyEnv = IEnv.empty} : context

  fun insertVariable ({varEnv, tyEnv}:context) (id, varList) = 
      {
       varEnv = VarID.Map.insert(varEnv,id,varList),
       tyEnv = tyEnv
      } : context

  fun extendBtvEnv ({varEnv, tyEnv}:context) btvEnv =
      let
        val newBtvEnv = IEnv.map transformBtvKind btvEnv
        val tyEnv =
            IEnv.foldli
                (fn (id,btvKind,S) => IEnv.insert(S,id,btvKind))
                tyEnv
                newBtvEnv
      in
        (newBtvEnv, {varEnv = varEnv, tyEnv = tyEnv} : context)
      end

  fun fieldType ({varEnv, tyEnv}:context) (label, recordTy) =
      case recordTy
       of AT.RECORDty {fieldTypes,...} => valOf(SEnv.find(fieldTypes,label))
        | AT.BOUNDVARty tid =>
          (case IEnv.find(tyEnv,tid)
            of SOME {recordKind = AT.REC flty,...} => valOf(SEnv.find(flty,label))
             | _ => raise Control.Bug "invalid record bound type variable"
          )
        | _ => raise Control.Bug "invalid record type"

  fun findVariable ({varEnv, tyEnv}:context, id) = VarID.Map.find(varEnv,id)

  end

  (*====================================================================*)

  fun transformArg context exp =
      let
        val (decls, newExp, newTy) = transformExp context exp
      in
        case newTy of
          AT.MVALty tyList =>
          (case newExp of
             MVMVALUES {expList, tyList, loc} => (decls, expList, tyList)
           | _ =>
             let
               val varInfoList = map newVar tyList
               val loc = MVU.getLocOfExp newExp
               val decls = decls @ [MVVAL {boundVars = varInfoList, boundExp = newExp, loc = loc}]
               val expList = map (fn v => MVVAR {varInfo = v, loc = loc}) varInfoList
             in
               (decls, expList, tyList)
             end
          )
        | _ =>
          (
           case newExp of
             MVCONSTANT _ => (decls, [newExp], [newTy])
           | MVGLOBALSYMBOL _ => (decls, [newExp], [newTy])
           | MVEXCEPTIONTAG _ => (decls, [newExp], [newTy])
           | MVVAR _ => (decls, [newExp], [newTy])
           | MVCAST {exp = MVCONSTANT _,...} => (decls, [newExp], [newTy])
           | MVCAST {exp = MVEXCEPTIONTAG _,...} => (decls, [newExp], [newTy])
           | MVCAST {exp = MVVAR _,...} => (decls, [newExp], [newTy])
           | MVCAST {exp, expTy, targetTy, loc} => 
             let
               val varInfo = newVar expTy
               val decls = decls @ [MVVAL {boundVars = [varInfo], boundExp = exp, loc = loc}]
               val newExp = MVCAST {exp = MVVAR {varInfo = varInfo, loc = loc}, expTy = expTy, targetTy = targetTy, loc = loc}
             in
               (decls, [newExp], [newTy])
             end
           | _ =>
             let
               val varInfo = newVar newTy
               val loc = MVU.getLocOfExp newExp
               val decls = decls @ [MVVAL {boundVars = [varInfo], boundExp = newExp, loc = loc}]
             in
               (decls, [MVVAR {varInfo = varInfo, loc = loc}], [newTy])
             end
          )
      end

 and transformArgSingle context exp =
     case transformArg context exp of
       (decls, [newSwitchExp], [newExpTy]) => (decls, newSwitchExp, newExpTy)
     | _ => 
       raise 
         Control.Bug
         "multiple value expression in single value context: (recordunboxing/main/RecordUnboxing.sml)"
       

  and transformArgList context [] = ([],[],[])
    | transformArgList context (exp::expList) =
      let
        val (declList1, argList1, tyList1) = transformArg context exp
        val (declList2, argList2, tyList2) = transformArgList context expList
      in
        (declList1 @ declList2, argList1 @ argList2, tyList1 @ tyList2)
      end

  and transformExp context exp =
      case exp of
        AC.ACFOREIGNAPPLY {funExp, funTy, argExpList, attributes, loc} =>
        let
          val (funDecls, newFunExp, _) = transformArgSingle context funExp
          val {argTyList, bodyTy, annotation, funStatus} = ATU.expandFunTy funTy
          val (argDecls, newArgExpList, newArgTyList) = transformArgList context argExpList
          val newBodyTy = transformType bodyTy
          val newFunTy = AT.FUNMty {argTyList = newArgTyList, 
                                    bodyTy = newBodyTy, 
                                    annotation = annotation,
                                    funStatus = funStatus
                                    }
          val newExp =
              MVFOREIGNAPPLY
                  {
                   funExp = newFunExp,
                   funTy = newFunTy,
                   argExpList = newArgExpList,
                   attributes = attributes,
                   loc = loc
                  }
        in
          (funDecls @ argDecls, newExp, newBodyTy)
        end
      | AC.ACEXPORTCALLBACK {funExp as AC.ACFNM _, funTy, attributes, loc} =>
        let
          val (decls, newFunExp, newFunTy) = transformExp context funExp
          val newExp = 
              MVEXPORTCALLBACK
                  {
                   funExp = newFunExp,
                   funTy = newFunTy,
                   attributes = attributes,
                   loc = loc
                  }
        in
          (decls, newExp, AT.foreignfunty)
        end
      | AC.ACEXPORTCALLBACK {funExp, funTy, attributes, loc} =>
        raise Control.Bug "transformExp: ACEXPORTCALLBACK"
      | AC.ACSIZEOF {ty, loc} =>
        (nil,
         MVSIZEOF
             {
              ty = transformType ty,
              loc = loc
             },
         AT.sizeofty)
      | AC.ACEXCEPTIONTAG v => ([], MVEXCEPTIONTAG v, AT.exntagty)
      | AC.ACCONSTANT (v as {value, loc}) => ([], MVCONSTANT v, ATU.constDefaultTy value)
      | AC.ACGLOBALSYMBOL (v as {ty,...}) => ([], MVGLOBALSYMBOL v, ty)
      | AC.ACVAR {varInfo as {displayName, ty, varId as T.EXTERNAL _}, loc} =>
        let
          val newTy = transformType ty
          val newVarInfo = {displayName = displayName, ty = newTy, varId = varId}
        in 
          ([], MVVAR {varInfo = newVarInfo, loc = loc}, newTy)
        end
      | AC.ACVAR {varInfo as {displayName, ty,varId = T.INTERNAL id}, loc} =>
        (
         case CTX.findVariable(context, id) of 
           SOME [v] => ([], MVVAR {varInfo = v, loc = loc}, #ty v)
         | SOME varList => 
           let
             val tyList = map #ty varList
             val newExp = 
                 MVMVALUES 
                     {
                      expList = map (fn v => MVVAR {varInfo = v, loc = loc}) varList,
                      tyList = tyList,
                      loc = loc
                     }
           in ([], newExp, AT.MVALty tyList) end
         | NONE => raise Control.Bug "internal variable not found"
        )
      | AC.ACGETFIELD {arrayExp, indexExp, elementTy, loc} =>
        let
          val (arrayDecls, newArrayExp, newArrayTy) = transformArgSingle context arrayExp
          val (indexDecls, newIndexExp, _) = transformArgSingle context indexExp
          val newElementTy = AT.arrayelemty newArrayTy
          val newExp =
              MVGETFIELD
                  {
                   arrayExp = newArrayExp,
                   indexExp = newIndexExp,
                   elementTy = newElementTy,
                   loc = loc
                  }
        in
          (arrayDecls @ indexDecls, newExp, newElementTy)
        end
      | AC.ACSETFIELD {valueExp, arrayExp, indexExp, elementTy, loc} =>
        let
          val (valueDecls, newValueExp, newElementTy) = transformArgSingle context valueExp
          val (arrayDecls, newArrayExp, _) = transformArgSingle context arrayExp
          val (indexDecls, newIndexExp, _) = transformArgSingle context indexExp
          val newExp =
              MVSETFIELD
                  {
                   valueExp = newValueExp,
                   arrayExp = newArrayExp,
                   indexExp = newIndexExp,
                   elementTy = newElementTy,
                   loc = loc
                  }
        in
          (valueDecls @ arrayDecls @ indexDecls, newExp, AT.unitty)
        end
      | AC.ACSETTAIL {consExp, newTailExp, listTy, consRecordTy, tailLabel, loc} =>
        let
          val (consDecls, newConsExp, newConsTy) = transformArgSingle context consExp
          val (newTailDecls, newNewTailExp, _) = transformArgSingle context newTailExp
          val newExp =
              MVSETTAIL
                  {
                   consExp = newConsExp,
                   newTailExp = newNewTailExp,
                   consRecordTy = transformType consRecordTy,
                   tailLabel = ATU.convertLabel tailLabel,
                   listTy = newConsTy,
                   loc = loc
                  }
        in
          (consDecls @ newTailDecls, newExp, AT.unitty)
        end
      | AC.ACARRAY {sizeExp, initialValue, elementTy, isMutable, loc} =>
        let
          val (sizeDecls, newSizeExp, _) = transformArgSingle context sizeExp
          val (valueDecls, newInitialValue, newElementTy) = transformArgSingle context initialValue
          val newExp =
              MVARRAY
                  {
                   sizeExp = newSizeExp,
                   initialValue = newInitialValue,
                   elementTy = newElementTy,
                   isMutable = isMutable,
                   loc = loc
                  }
        in
          (sizeDecls @ valueDecls, newExp, AT.arrayty newElementTy)
        end
      | AC.ACCOPYARRAY
        {srcExp, srcIndexExp, dstExp, dstIndexExp, lengthExp, elementTy, loc} =>
        let
          val (srcDecls, newSrcExp, newSrcTy) =
              transformArgSingle context srcExp
          val (srcIndexDecls, newSrcIndexExp, _) =
              transformArgSingle context srcIndexExp
          val (dstDecls, newDstExp, _) =
              transformArgSingle context dstExp
          val (dstIndexDecls, newDstIndexExp, _) =
              transformArgSingle context dstIndexExp
          val (lengthDecls, newLengthExp, _) =
              transformArgSingle context lengthExp
          (* ToDo : We should obtain newElementTy from elementTy ? *)
(*
          val newElementTy = elementTy
*)
          val newElementTy = AT.arrayelemty newSrcTy
          val newExp =
              MVCOPYARRAY
                  {
                   srcExp = newSrcExp,
                   srcIndexExp = newSrcIndexExp,
                   dstExp = newDstExp,
                   dstIndexExp = newDstIndexExp,
                   lengthExp = newLengthExp,
                   elementTy = newElementTy,
                   loc = loc
                  }
        in
          (srcDecls @ srcIndexDecls @ dstDecls @ dstIndexDecls @ lengthDecls, newExp, AT.unitty)
        end
      | AC.ACPRIMAPPLY {primInfo, argExpList, instTyList, loc} =>
        let
          val {argTyList, bodyTy, annotation, funStatus} = ATU.expandFunTy (#ty primInfo)
          val (decls, newArgExpList, newArgTyList) = transformArgList context argExpList
          val newBodyTy = transformType bodyTy
          val newPrimInfo =
              {
               name = #name primInfo,
               ty = AT.FUNMty {argTyList = newArgTyList, 
                               bodyTy = newBodyTy, 
                               annotation = annotation,
                               funStatus = funStatus
                               }
              }
          val newExp =
              MVPRIMAPPLY
                  {
                   primInfo = newPrimInfo,
                   argExpList = newArgExpList,
                   instTyList = instTyList,
                   loc = loc
                  }
        in
          (decls, newExp, newBodyTy)
        end
      | AC.ACAPPM {funExp as AC.ACTAPP{exp, expTy, instTyList, loc = polyLoc}, funTy, argExpList, loc} =>
        let
          val (polyDecls, newPolyExp, newPolyTy) = transformArgSingle context exp
          val newInstTyList = map transformType instTyList
          val (newFunTy, bodyTy) = 
            case ATU.tpappTy (newPolyTy, newInstTyList) of
              newFunTy as AT.FUNMty {bodyTy,...} => (newFunTy, bodyTy)
            | _ => 
                raise 
                  Control.Bug
                  "FUNMty expected in CAPPM : (recordunboxing/main/RecordUnboxing.sml)"
          val (argDecls, newArgExpList, _) = transformArgList context argExpList
          val newExp =
              MVAPPM
                  {
                   funExp = MVTAPP{exp = newPolyExp, expTy = newPolyTy, instTyList = newInstTyList, loc = polyLoc},
                   funTy = newFunTy,
                   argExpList = newArgExpList,
                   loc = loc
                  }
        in
          (polyDecls @ argDecls, newExp, bodyTy)
        end
      | AC.ACAPPM {funExp, funTy, argExpList, loc} =>
        let
          val (funDecls, newFunExp, newFunTy) = transformArgSingle context funExp
          val (argDecls, newArgExpList, _) = transformArgList context argExpList
          val {bodyTy,...} = ATU.expandFunTy newFunTy
          val newExp =
              MVAPPM
                  {
                   funExp = newFunExp,
                   funTy = newFunTy,
                   argExpList = newArgExpList,
                   loc = loc
                  }
        in
          (funDecls @ argDecls, newExp, bodyTy)
        end
      | AC.ACLET {localDeclList, mainExp, loc} =>
        let
          val (localDecls, newContext) = transformDeclList context localDeclList
          val (mainDecls, newMainExp, newTy) = transformExp newContext mainExp
        in
          (localDecls @ mainDecls, newMainExp, newTy)
        end
      | AC.ACRECORD {expList, recordTy, annotation = expAnnotation, isMutable, loc} =>
        if !Control.doRecordUnboxing
        then
          case recordTy
           of AT.RECORDty {annotation as ref {boxed = false,...},...} =>
              let
                val (decls, args, tys) = transformArgList context expList 
              in
                case (args,tys)
                 of ([arg],[ty]) => (decls, arg, ty)
                  | _ => 
                    (decls, MVMVALUES {expList = args, tyList = tys, loc = loc}, AT.MVALty tys)
              end
            | AT.RECORDty {fieldTypes, annotation} => 
              let
                val (decls, args, flty)=
                    ListPair.foldl
                        (fn (label,(decls,args,tys),(L1,L2,S)) =>
                            let
                              val labels = genLabels(label,List.length tys)
                              val S =
                                  ListPair.foldl
                                      (fn (l,ty,S) => SEnv.insert(S,l,ty))
                                      S
                                      (labels,tys)
                            in
                              (L1 @ decls, L2 @ args, S)
                            end
                        )
                        ([],[],SEnv.empty)
                        (SEnv.listKeys fieldTypes, map (transformArg context) expList)
                val newRecordTy = AT.RECORDty {fieldTypes = flty, annotation = annotation}
                val newExp =
                    MVRECORD {expList = args, 
                              recordTy = newRecordTy, 
                              annotation = expAnnotation, 
                              isMutable = isMutable,
                              loc = loc}
              in
                (decls, newExp, newRecordTy)
              end
            | _ => raise Control.Bug "invalid record type"
        else
          let 
            val (decls, newExpList, _) = transformArgList context expList
            val newRecordTy = transformType recordTy
            val newExp =
                MVRECORD
                    {
                     expList = newExpList,
                     recordTy = newRecordTy,
                     annotation = expAnnotation,
                     isMutable = isMutable,
                     loc = loc
                    }
          in 
            (decls, newExp, newRecordTy)
          end
      | AC.ACSELECT {recordExp, label, recordTy, resultTy, loc} =>
        if !Control.doRecordUnboxing 
        then
          case recordTy
           of AT.RECORDty {annotation = ref {boxed=false,...},...} => 
              let
                val (decls, args, tys) = transformArg context recordExp
                val (firstIndex, count) = indexesOf (label, recordTy)
                val fields = List.take(List.drop(args,firstIndex),count)
                val fieldTys = List.take(List.drop(tys,firstIndex),count)
                val (exp,ty) =
                    case (fields, fieldTys) of
                      ([exp],[ty]) => (exp, ty)
                    | _ => (MVMVALUES {expList = fields, tyList = fieldTys, loc = loc}, AT.MVALty fieldTys)
              in
                (decls, exp, ty)
              end
            | AT.RECORDty _ => 
              let
                val (decls, newRecordExp, newRecordTy, fieldTypes) = 
                  case transformArgSingle context recordExp of
                    (decls, newRecordExp, newRecordTy as AT.RECORDty {fieldTypes,...}) =>
                      (decls, newRecordExp, newRecordTy, fieldTypes)
                  | _ => 
                      raise 
                        Control.Bug 
                        "RECORDty expected : (recordunboxing/main/RecordUnboxing.sml)"
                fun fieldTy label = valOf(SEnv.find(fieldTypes,label))
                fun fieldExp label = MVSELECT {recordExp = newRecordExp, 
                                               recordTy = newRecordTy, 
                                               label = label, 
                                               resultTy = fieldTy label,
                                               loc = loc}
                val labels = labelsOf (label, recordTy)
                val (decls,newExp, newTy) =
                    case labels of
                      [label] => (decls, fieldExp label, fieldTy label)
                    | _ =>
                      let
                        val tyList = map fieldTy labels
                        val varInfoList = map newVar tyList
                        val fieldDecls =
                            ListPair.map 
                                (fn (varInfo, exp) => MVVAL {boundVars = [varInfo], boundExp = exp, loc = loc})
                                (varInfoList, map fieldExp labels)
                        val expList = map (fn v => MVVAR {varInfo = v, loc = loc}) varInfoList
                      in
                        (decls @ fieldDecls, 
                         MVMVALUES {expList = expList, tyList = tyList, loc = loc}, 
                         AT.MVALty tyList)
                      end
              in
                (decls, newExp, newTy)
              end
            | _ => 
              let
                val (decls, newRecordExp, newRecordTy) = transformArgSingle context recordExp
                val newLabel = ATU.convertLabel label
                val newFieldTy = CTX.fieldType context (newLabel, newRecordTy)
                val newExp = 
                    MVSELECT
                        {
                         recordExp = newRecordExp,
                         label = newLabel,
                         recordTy = newRecordTy,
                         resultTy = newFieldTy,
                         loc = loc
                        }
              in
                (decls, newExp, newFieldTy)
              end
        else
          let
            val (decls, newRecordExp, newRecordTy) = transformArgSingle context recordExp
            val newLabel = ATU.convertLabel label
            val newFieldTy = CTX.fieldType context (newLabel, newRecordTy)
            val newExp = 
                MVSELECT
                    {
                     recordExp = newRecordExp,
                     label = newLabel,
                     recordTy = newRecordTy,
                     resultTy = newFieldTy,
                     loc = loc
                    }
          in
            (decls, newExp, newFieldTy)
          end

      | AC.ACMODIFY {recordExp, recordTy, label, valueExp, valueTy, loc} =>
        let
          val (decls1, newRecordExp, newRecordTy) = transformArgSingle context recordExp
          val (decls2, newValueExp, newValueTy) = transformArgSingle context valueExp
          val newExp =
              MVMODIFY
                  {
                   recordExp = newRecordExp,
                   recordTy = newRecordTy,
                   label = ATU.convertLabel label,
                   valueExp = newValueExp,
                   valueTy = newValueTy,
                   loc = loc
                  }
        in 
          (decls1 @ decls2, newExp, newRecordTy)
        end
        
      | AC.ACRAISE {argExp, resultTy, loc} =>
        let
          val (decls, newArgExp, _) = transformArgSingle context argExp
          val newResultTy = transformType resultTy
          val newExp = MVRAISE {argExp = newArgExp, resultTy = newResultTy, loc = loc}
        in 
          (decls, newExp, newResultTy)
        end

      | AC.ACHANDLE {exp, exnVar as {varId = T.INTERNAL id,...}, handler, loc} =>
        let
          val (mainDecls, newMainExp, newTy) = transformExp context exp
          val newExnVar = 
            case transformVar exnVar of 
              [newExnVar] => newExnVar
            | _ => raise Control.Bug "single value expected : (recordunboxing/main/RecordUnboxing.sml)"
          val (handlerDecls, newHandler, _) = transformExp (CTX.insertVariable context (id, [newExnVar])) handler
          val newExp = 
              MVHANDLE
                  {
                   exp = makeLetExp (mainDecls, newMainExp, loc),
                   exnVar = newExnVar,
                   handler = makeLetExp (handlerDecls, newHandler, loc),
                   loc = loc
                  }
        in
          ([],newExp,newTy)
        end
      | AC.ACHANDLE {exp, exnVar as {varId = T.EXTERNAL _,...}, handler, loc} =>        
        raise Control.Bug "expect local variable in handler"
      | AC.ACFNM {argVarList, funTy as AT.FUNMty {funStatus, annotation,...}, 
                  bodyExp, 
                  annotation = funAnnotation, 
                  loc} =>
        let
          val (newArgVarList,newContext) = 
              foldr
                  (fn (v as {varId = T.INTERNAL id,...}, (L,C)) =>
                      let
                        val varList = transformVar v
                      in
                        (varList @ L, CTX.insertVariable C (id,varList))
                      end
                    | (v as {varId = T.EXTERNAL _,...}, (L,C)) =>
                      raise Control.Bug "expect local variable in function argument"
                  )
                  ([],context)
                  argVarList
          val (decls, newBodyExp, newBodyTy) = transformExp newContext bodyExp
          val newFunTy = AT.FUNMty {argTyList = map #ty newArgVarList, 
                                    bodyTy = newBodyTy, 
                                    annotation = annotation,
                                    funStatus = funStatus
                                    }
          val newExp =
              MVFNM
                  {
                   argVarList = newArgVarList,
                   funTy = newFunTy,
                   bodyExp = makeLetExp (decls,newBodyExp, loc),
                   annotation = funAnnotation,
                   loc = loc
                  }
        in
          ([],newExp,newFunTy)
        end
        
      | AC.ACFNM _ =>
        raise Control.Bug "non FUNMty in ACFNM (recordunboxing/main/RecordUnboxing.sml)"

      | AC.ACPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        let
          val (newBtvEnv, newContext) = CTX.extendBtvEnv context btvEnv
          val (decls,newExp,newExpTyWithoutTAbs) = transformExp newContext exp
          val newExp =
              MVPOLY
                  {
                   btvEnv = newBtvEnv,
                   expTyWithoutTAbs = newExpTyWithoutTAbs,
                   exp = makeLetExp(decls,newExp,loc),
                   loc = loc
                  }
        in
          ([],newExp,AT.POLYty{boundtvars = newBtvEnv, body = newExpTyWithoutTAbs})
        end
        
      | AC.ACTAPP {exp, expTy, instTyList, loc} =>
        let
          val (decls, newExp, newExpTy) = transformArgSingle context exp
          val newInstTyList = map transformType instTyList
          val newExp = 
              MVTAPP
                  {
                   exp = newExp,
                   expTy = newExpTy,
                   instTyList = newInstTyList,
                   loc = loc
                  }
        in
          (decls, newExp, ATU.tpappTy (newExpTy,newInstTyList))
        end
        
      | AC.ACSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        let
          val  (decls, newSwitchExp, newExpTy) = transformArgSingle context switchExp

          val (defaultDecls, newDefaultExp, newDefaultTy) = transformExp context defaultExp

          fun transformBranch {constant, exp} =
              let
                val (_, newConstant, _) = transformExp context constant
                val (decls, newExp, _) = transformExp context exp
              in 
                {constant = newConstant, exp = makeLetExp (decls, newExp, loc)}
              end
          val newExp = 
              MVSWITCH
                  {
                   switchExp = newSwitchExp,
                   expTy = newExpTy,
                   branches = map transformBranch branches,
                   defaultExp = makeLetExp(defaultDecls, newDefaultExp, loc),
                   loc = loc
                  }
        in
          (decls, newExp, newDefaultTy)
        end
        
      | AC.ACCAST {exp, expTy, targetTy, loc} =>
        let
          val (decls, newExp, newExpTy) = transformExp context exp
          val newTargetTy = transformType targetTy
          val newExp =
              MVCAST
                  {
                   exp = newExp,
                   expTy = newExpTy,
                   targetTy = newTargetTy,
                   loc = loc
                  }
        in
          (decls, newExp, newTargetTy)
        end

  and transformDecl context decl =
      case decl of 
        AC.ACVAL {boundVar as {displayName, ty, varId = T.INTERNAL id}, boundExp , loc} =>
        let
          val (decls1, args, tyList) = transformArg context boundExp
          val (varList, decls2) =
              ListPair.foldr
                  (fn (arg,ty,(L1,L2)) =>
                      case arg of
                        MVVAR {varInfo, loc} => (varInfo :: L1,L2)
                      | _ =>
                        let
                          val varInfo = newVar ty
                          val decl = MVVAL {boundVars = [varInfo], boundExp = arg, loc = loc}
                        in
                          (varInfo :: L1, decl :: L2)
                        end
                  )
                  ([],[])
                  (args,tyList)
        in
          (decls1 @ decls2, CTX.insertVariable context (id,varList))
        end

      | AC.ACVAL {boundVar as {displayName, ty, varId as T.EXTERNAL _}, boundExp , loc} =>
        let
          val (decls1, newBoundExp, newBoundTy) = transformExp context boundExp
          val newBoundVar = {displayName = displayName, ty = newBoundTy, varId = varId}
          val newDecl = MVVAL {boundVars = [newBoundVar], boundExp = newBoundExp, loc = loc}
        in
          (decls1 @ [newDecl], context)
        end

      | AC.ACVALREC {recbindList, loc} =>
        let
          val newBoundVarList = 
              map
                  (fn {boundVar as {displayName, ty, varId},...} => 
                      {displayName = displayName, ty = transformType ty, varId = varId})
                  recbindList
          val newContext = 
              foldl
                  (fn (v as {varId = T.INTERNAL id,...},C) => CTX.insertVariable C (id,[v])
                    | (v as {varId = T.EXTERNAL _,...},C) => C)
                  context
                  newBoundVarList
          val newRecbindList =
              ListPair.map
                  (fn ({boundExp,...}, boundVar) =>
                      let
                        val (_, newBoundExp, _) = transformExp newContext boundExp
                      in
                        {boundVar = boundVar, boundExp = newBoundExp}
                      end
                  )
                  (recbindList,newBoundVarList)
        in
          ([MVVALREC{recbindList = newRecbindList, loc = loc}], newContext)
        end

      | AC.ACVALPOLYREC {btvEnv, recbindList, loc} =>
        let
          val newBoundVarList = 
              map
                  (fn {boundVar as {displayName, ty, varId},...} => 
                      {displayName = displayName, ty = transformType ty, varId = varId})
                  recbindList
          val newContext = 
              foldl
                  (fn (v as {varId = T.INTERNAL id,...},C) => CTX.insertVariable C (id,[v])
                    | (v as {varId = T.EXTERNAL _,...},C) => C)
                  context
                  newBoundVarList
          val (newBtvEnv, newContext) = CTX.extendBtvEnv newContext btvEnv
          val newRecbindList =
              ListPair.map
                  (fn ({boundExp,...}, boundVar) =>
                      let
                        val ( _, newBoundExp, _) = transformExp newContext boundExp
                      in
                        {boundVar = boundVar, boundExp = newBoundExp}
                      end
                  )
                  (recbindList,newBoundVarList)
          val newContext =
              foldl
                  (fn ({displayName, ty, varId = varId as (T.INTERNAL internalID)},C) =>
                      let
                        val v = {
                                 displayName = displayName, 
                                 ty = AT.POLYty {boundtvars = newBtvEnv, body = ty}, 
                                 varId = varId}
                      in 
                        CTX.insertVariable C (internalID,[v])
                      end
                    | ({displayName, ty, varId = T.EXTERNAL _},C) => C
                  )
                  context
                  newBoundVarList
        in
          ([MVVALPOLYREC{btvEnv = newBtvEnv, recbindList = newRecbindList, loc = loc}], newContext)
        end
        
  and transformDeclList context ([]) = ([],context)
    | transformDeclList context (decl::rest) =
      let
        val (decls1, newContext) = transformDecl context decl
        val (decls2, newContext) = transformDeclList newContext rest
      in
        (decls1 @ decls2,newContext)
      end

  fun transformBasicBlock context basicBlock =
      case basicBlock of
          AC.ACVALBLOCK {code, exnIDSet} =>
          let
              val (newCode, context) = 
                  transformDeclList context code
          in
              (MVVALBLOCK {code = newCode, exnIDSet = exnIDSet}, context)
          end
        | AC.ACLINKFUNCTORBLOCK x => (MVLINKFUNCTORBLOCK x, context)

  fun transformBasicBlocks context nil = ([], context)
    | transformBasicBlocks context (basicBlock :: rest) = 
      let
          val (basicBlock1, newContext) = transformBasicBlock context basicBlock
          val (basicBlocks2, newContext) = transformBasicBlocks newContext rest
      in
          (basicBlock1 :: basicBlocks2, newContext)
      end
                             
  fun transfromTopBlock context topBlock =
      case topBlock of
          AC.ACBASICBLOCK basicBlock =>
          let
              val (newBasicBlock, context) = transformBasicBlock context basicBlock
          in
              (MVBASICBLOCK newBasicBlock, context)
          end
        | AC.ACFUNCTORBLOCK {name, formalAbstractTypeIDSet, formalVarIDSet, formalExnIDSet,
                             generativeExnIDSet, generativeVarIDSet, bodyCode} =>
          let
              val (bodyCode, _) = transformBasicBlocks CTX.empty bodyCode
          in
              (MVFUNCTORBLOCK {name = name, 
                               formalAbstractTypeIDSet = formalAbstractTypeIDSet, 
                               formalVarIDSet = formalVarIDSet,
                               formalExnIDSet = formalExnIDSet,
                               generativeExnIDSet = generativeExnIDSet, 
                               generativeVarIDSet = generativeVarIDSet, 
                               bodyCode = bodyCode}, 
               context)
          end

  fun transformTopBlocks context nil = ([], context)
    | transformTopBlocks context (block :: rest) = 
      let
          val (block1, newContext) = transfromTopBlock context block
          val (blocks2, newContext) = transformTopBlocks newContext rest
      in
          (block1 :: blocks2, newContext)
      end
      
  fun transform  blockList = 
      let
        val (newBlockList, _) = transformTopBlocks CTX.empty blockList
      in
        newBlockList
      end


end
