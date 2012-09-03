(**
 * record unboxing
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure RecordUnboxing : sig

  val transform : AnnotatedCalc.acdecl list ->  MultipleValueCalc.mvdecl list

end =
struct

  structure AT = AnnotatedTypes
  structure AC = AnnotatedCalc
  structure ATU = AnnotatedTypesUtils
  structure MVU = MultipleValueCalcUtils
  structure VEnv = VarID.Map
  structure T = Types
  open MultipleValueCalc

  fun printTy ty = 
      (print (Control.prettyPrint (AT.format_ty ty));
       print "\n")

  fun printKind kind = 
      (print (Control.prettyPrint (AT.format_tvarKind kind));
       print "\n")

   fun newVar ty = 
       let
           val id = VarID.generate ()
       in
           {path = ["$" ^ VarID.toString id],
            ty = ty,
            id = id} : varInfo
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
        AT.SINGLETONty sty =>
        AT.SINGLETONty (transformSingletonTy sty)
      | AT.ERRORty => ty
      | AT.DUMMYty _ => ty
      | AT.BOUNDVARty _ => ty
      | AT.FUNMty {argTyList, bodyTy, annotation, funStatus} =>
        AT.FUNMty
            {
             argTyList =
               List.concat (map (flatTyList o transformType) argTyList),
             bodyTy = transformType bodyTy,
             annotation = annotation,
             funStatus = funStatus
            }
      | AT.MVALty tyList =>
        mvTy (List.concat (map (flatTyList o transformType) tyList))
      | AT.RECORDty {fieldTypes, annotation as ref {boxed = false,...}} =>
        if !Control.doRecordUnboxing
        then mvTy (List.concat (map (flatTyList o transformType)
                                    (LabelEnv.listItems fieldTypes)))
        else AT.RECORDty {fieldTypes = transformFieldTypes fieldTypes,
                          annotation = annotation}
      | AT.RECORDty {fieldTypes, annotation} =>
        AT.RECORDty {fieldTypes = transformFieldTypes fieldTypes,
                     annotation = annotation}
      | AT.CONty {tyCon, args} => 
        AT.CONty {tyCon = tyCon, args = map transformType args}
      | AT.POLYty {boundtvars, body} =>
        AT.POLYty {boundtvars = BoundTypeVarID.Map.map
                                  transformBtvKind boundtvars,
                   body = transformType body}

  and transformSingletonTy singletonTy =
      case singletonTy of
        AT.INSTCODEty {oprimId, path, keyTyList} =>
        AT.INSTCODEty {oprimId = oprimId,
                       path = path,
                       keyTyList =  map transformType keyTyList
                      }
      | AT.INDEXty (label, ty) =>
        AT.INDEXty (transformIndexTy (label, ty))
      | AT.TAGty ty =>
        AT.TAGty (transformType ty)
      | AT.SIZEty ty =>
        AT.SIZEty (transformType ty)
      | AT.RECORDSIZEty ty =>
        AT.RECORDSIZEty (transformType ty)
      | AT.RECORDBITMAPty (index, ty) =>
        AT.RECORDBITMAPty (index, transformType ty)

  and transformBtvKind {id, tvarKind, eqKind} =
        {
         id = id,
         tvarKind = transformRecKind tvarKind,
         eqKind = eqKind
        }

  and transformRecKind tvarKind =
      case tvarKind
       of AT.UNIV => AT.UNIV
        | AT.REC flty => AT.REC (transformFieldTypes flty)
        | AT.OPRIMkind instances
          =>
          AT.OPRIMkind (map transformType instances)

  and transformFieldTypes flty =
      LabelEnv.foldli
          (fn (label,ty,S) =>
              case transformType ty of
                AT.MVALty tyList =>
                ListPair.foldl
                    (fn (label,ty,S) => LabelEnv.insert(S,label,ty))
                    S
                    (genLabels (label, List.length tyList),tyList)
              | newTy => LabelEnv.insert(S,ATU.convertLabel label,newTy)
          )
          LabelEnv.empty
          flty

  and transformIndexTy (label, recordTy) =
      let
        val newRecordTy = transformType recordTy
      in
        case newRecordTy of
          AT.MVALty _ =>
          (* The record is unboxed. Any variables and expressions of
           * this type should be discarded. To keep consistency of
           * INDEXty (the recordTy field of INDEXty must be a record type),
           * we do not apply any transformation to this INDEXty. *)
          (label, recordTy)
        | AT.RECORDty _ =>
          (* Note that some nested records may be unboxed. The label may
           * be not found in the recordTy after unboxing. *)
          let
            val fieldTypes =
                case recordTy of
                  AT.RECORDty {fieldTypes,...} => fieldTypes
                | _ => raise Control.Bug "transformIndexTy: fieldTypes"
            val fieldTy =
                case LabelEnv.find (fieldTypes, label) of
                  SOME ty => ty
                | NONE => raise Control.Bug "transformIndexTy: fieldTy"
          in
            case transformType fieldTy of
              AT.MVALty _ =>
              (* The selected record is unboxed. *)
              (label, recordTy)
            | _ =>
              (ATU.convertLabel label, newRecordTy)
          end
        | _ => (ATU.convertLabel label, newRecordTy)
      end
  
  fun transformVar {path, ty, id} =
      case flatTyList (transformType ty)
       of [ty] => [{path = path,
                    ty = transformType ty,
                    id = id}]
        | tyList => map newVar tyList

  fun indexesOf (label, recordTy) =
      case recordTy of
        AT.RECORDty {fieldTypes,...} =>
        let
          fun computeFirstIndex (n, []) = raise Control.Bug ("label not found " ^ label)
            | computeFirstIndex (n, (l,ty)::rest) =
              if l = label 
              then (n,ty) 
              else computeFirstIndex(n + ATU.cardinality (transformType ty),
                                     rest)
 
          val (firstIndex, fieldType) =
              computeFirstIndex(0,LabelEnv.listItemsi fieldTypes)
        in
          (firstIndex, ATU.cardinality(transformType fieldType))
        end
      | _ => raise Control.Bug "record type is expected" 
        
  fun labelsOf (label, recordTy) =
      case recordTy of
        AT.RECORDty {fieldTypes,...} =>
        let
          val fieldType =
              case LabelEnv.find(fieldTypes, label) of
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

  type context = {varEnv : (AC.varInfo list) VarID.Map.map,
                  tyEnv : AT.btvKind BoundTypeVarID.Map.map}

  val empty =
      {varEnv = VarID.Map.empty, tyEnv = BoundTypeVarID.Map.empty} : context

  fun insertVariable ({varEnv, tyEnv}:context) (id, varList) = 
      {
       varEnv = VarID.Map.insert(varEnv,id,varList),
       tyEnv = tyEnv
      } : context

  fun extendBtvEnv ({varEnv, tyEnv}:context) btvEnv =
      let
        val newBtvEnv = BoundTypeVarID.Map.map transformBtvKind btvEnv
        val tyEnv =
            BoundTypeVarID.Map.foldli
                (fn (id,btvKind,S) => BoundTypeVarID.Map.insert(S,id,btvKind))
                tyEnv
                newBtvEnv
      in
        (newBtvEnv, {varEnv = varEnv, tyEnv = tyEnv} : context)
      end

  exception FieldType
  fun fieldType ({varEnv, tyEnv}:context) (label, recordTy) =
      case recordTy
       of AT.RECORDty {fieldTypes,...} =>
          (case LabelEnv.find(fieldTypes,label) of
             SOME x => x
           | NONE => (print "option inb filedType (1)";
                      raise FieldType)
          )
        | AT.BOUNDVARty tid =>
          (case BoundTypeVarID.Map.find(tyEnv,tid)
            of SOME {tvarKind = AT.REC flty,...} =>
               (case LabelEnv.find(flty,label) of
                  SOME x => x
                | NONE =>
                  (printTy recordTy;
                   printKind (AT.REC flty);
                   print label;
                   print "\n";
                   print "option in filedType (2)";
                   raise FieldType
                  )
               )
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
               val decls =
                   decls
                   @ [MVVAL {boundVars = varInfoList,
                             boundExp = newExp,
                             loc = loc}]
               val expList =
                   map (fn v => MVVAR {varInfo = v, loc = loc}) varInfoList
             in
               (decls, expList, tyList)
             end
          )
        | _ =>
          (
           case newExp of
             MVCONSTANT _ => (decls, [newExp], [newTy])
           | MVGLOBALSYMBOL _ => (decls, [newExp], [newTy])
           | MVVAR _ => (decls, [newExp], [newTy])
           | MVCAST {exp = MVCONSTANT _,...} => (decls, [newExp], [newTy])
           | MVCAST {exp = MVVAR _,...} => (decls, [newExp], [newTy])
           | MVCAST {exp, expTy, targetTy, loc} => 
             let
               val varInfo = newVar expTy
               val decls = decls @ [MVVAL {boundVars = [varInfo],
                                           boundExp = exp, loc = loc}]
               val newExp = MVCAST {exp = MVVAR {varInfo = varInfo, loc = loc},
                                    expTy = expTy,
                                    targetTy = targetTy,
                                    loc = loc}
             in
               (decls, [newExp], [newTy])
             end
           | _ =>
             let
               val varInfo = newVar newTy
               val loc = MVU.getLocOfExp newExp
               val decls = decls @ [MVVAL {boundVars = [varInfo],
                                           boundExp = newExp,
                                           loc = loc}]
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
         "multiple value expression in single value context:\
         \ (recordunboxing/main/RecordUnboxing.sml)"
       

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
        AC.ACFOREIGNAPPLY {funExp, foreignFunTy, argExpList, loc} =>
        let
          val (funDecls, newFunExp, _) = transformArgSingle context funExp
          val {argTyList, resultTy=bodyTy, attributes} = foreignFunTy
          val (argDecls, newArgExpList, newArgTyList) =
              transformArgList context argExpList
          val newBodyTy = transformType bodyTy
          val newForeignFunTy = {argTyList = newArgTyList,
                                 resultTy = newBodyTy,
                                 attributes = attributes}
          val newExp =
              MVFOREIGNAPPLY
                  {
                   funExp = newFunExp,
                   foreignFunTy = newForeignFunTy,
                   argExpList = newArgExpList,
                   loc = loc
                  }
        in
          (funDecls @ argDecls, newExp, newBodyTy)
        end
      | AC.ACEXPORTCALLBACK {funExp as AC.ACFNM _, foreignFunTy, loc} =>
        let
          val (decls, newFunExp, newFunTy) = transformExp context funExp
          val {argTyList, bodyTy, ...} = ATU.expandFunTy newFunTy
          val newExp = 
              MVEXPORTCALLBACK
                  {
                   funExp = newFunExp,
                   foreignFunTy = {argTyList = argTyList,
                                   resultTy = bodyTy,
                                   attributes = #attributes foreignFunTy},
                   loc = loc
                  }
        in
          (decls, newExp, AT.foreignfunty)
        end
      | AC.ACEXPORTCALLBACK {funExp, foreignFunTy, loc} =>
        raise Control.Bug "transformExp: ACEXPORTCALLBACK"
      | AC.ACTAGOF {ty, loc} =>
        let
          val ty = transformType ty
        in
          (nil, MVTAGOF {ty = ty, loc = loc}, AT.SINGLETONty (AT.TAGty ty))
        end
      | AC.ACSIZEOF {ty, loc} =>
        let
          val ty = transformType ty
        in
          (nil, MVSIZEOF {ty = ty, loc = loc}, AT.SINGLETONty (AT.SIZEty ty))
        end
      | AC.ACINDEXOF {label, recordTy, loc} =>
        let
          val (newLabel, newRecordTy) = transformIndexTy (label, recordTy)
        in
          (nil,
           MVINDEXOF {label = newLabel, recordTy = newRecordTy, loc = loc},
           AT.SINGLETONty (AT.INDEXty (newLabel, newRecordTy)))
        end
      | AC.ACCONSTANT (v as {value, loc}) =>
        ([], MVCONSTANT v, ATU.constDefaultTy value)
      | AC.ACGLOBALSYMBOL (v as {ty,...}) => ([], MVGLOBALSYMBOL v, ty)
      | AC.ACEXVAR {exVarInfo as {path, ty}, loc} =>
        let
          val newTy = transformType ty
          val newVarInfo = {path = path, ty = newTy}
        in 
          ([], MVEXVAR {exVarInfo = newVarInfo, loc = loc}, newTy)
        end
      | AC.ACVAR {varInfo as {path, ty, id}, loc} =>
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
(*
      | AC.ACGETFIELD {arrayExp, indexExp, elementTy, loc} =>
        let
          val (arrayDecls, newArrayExp, newArrayTy) =
              transformArgSingle context arrayExp
          val (indexDecls, newIndexExp, _) =
              transformArgSingle context indexExp
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
          val (valueDecls, newValueExp, newElementTy) =
              transformArgSingle context valueExp
          val (arrayDecls, newArrayExp, _) =
              transformArgSingle context arrayExp
          val (indexDecls, newIndexExp, _) =
              transformArgSingle context indexExp
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
      | AC.ACSETTAIL {consExp,
                      newTailExp, listTy, consRecordTy, tailLabel, loc} =>
        let
          val (consDecls, newConsExp, newConsTy) =
              transformArgSingle context consExp
          val (newTailDecls, newNewTailExp, _) =
              transformArgSingle context newTailExp
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
          val (valueDecls, newInitialValue, newElementTy) =
              transformArgSingle context initialValue
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
        {srcExp,
         srcIndexExp, dstExp, dstIndexExp, lengthExp, elementTy, loc} =>
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
          (srcDecls @ srcIndexDecls @ dstDecls @ dstIndexDecls @ lengthDecls,
           newExp,
           AT.unitty)
        end
*)
      | AC.ACPRIMAPPLY {primInfo, argExpList, instTyList, loc} =>
        let
          val monoTy = ATU.tpappTy (#ty primInfo, instTyList)
          val {argTyList, bodyTy, annotation, funStatus} =
              ATU.expandFunTy monoTy
          val (decls, newArgExpList, newArgTyList) =
              transformArgList context argExpList
          val newBodyTy = transformType bodyTy
          val newPrimInfo =
              {
               primitive = #primitive primInfo,
               ty = transformType (#ty primInfo)
              }
          val newInstTyList = map transformType instTyList
          val newExp =
              MVPRIMAPPLY
                  {
                   primInfo = newPrimInfo,
                   argExpList = newArgExpList,
                   instTyList = newInstTyList,
                   loc = loc
                  }
        in
          (decls, newExp, newBodyTy)
        end
      | AC.ACAPPM {funExp as AC.ACTAPP{exp, expTy, instTyList, loc = polyLoc},
                   funTy, argExpList, loc} =>
        let
          val (polyDecls, newPolyExp, newPolyTy) =
              transformArgSingle context exp
          val newInstTyList = map transformType instTyList
          val (newFunTy, bodyTy) = 
            case ATU.tpappTy (newPolyTy, newInstTyList) of
              newFunTy as AT.FUNMty {bodyTy,...} => (newFunTy, bodyTy)
            | _ => 
                raise 
                  Control.Bug
                  "FUNMty expected in CAPPM :\
                  \ (recordunboxing/main/RecordUnboxing.sml)"
          val (argDecls, newArgExpList, _) =
              transformArgList context argExpList
          val newExp =
              MVAPPM
                {
                 funExp = MVTAPP{exp = newPolyExp,
                                 expTy = newPolyTy,
                                 instTyList = newInstTyList, loc = polyLoc},
                   funTy = newFunTy,
                   argExpList = newArgExpList,
                   loc = loc
                  }
        in
          (polyDecls @ argDecls, newExp, bodyTy)
        end
      | AC.ACAPPM {funExp, funTy, argExpList, loc} =>
        let
          val (funDecls, newFunExp, newFunTy) =
              transformArgSingle context funExp
          val (argDecls, newArgExpList, _) =
              transformArgList context argExpList
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
          val (localDecls, newContext) =
              transformDeclList context localDeclList
          val (mainDecls, newMainExp, newTy) = transformExp newContext mainExp
        in
          (localDecls @ mainDecls, newMainExp, newTy)
        end
      | AC.ACRECORD {fields,
                     recordTy, annotation = expAnnotation, isMutable, loc} =>
        if !Control.doRecordUnboxing
        then
          case recordTy
           of AT.RECORDty {annotation as ref {boxed = false,...},...} =>
              let
                val expList = map #fieldExp fields
                val (decls, args, tys) = transformArgList context expList 
              in
                case (args,tys)
                 of ([arg],[ty]) => (decls, arg, ty)
                  | _ => 
                    (decls,
                     MVMVALUES {expList = args, tyList = tys, loc = loc},
                     AT.MVALty tys)
              end
            | AT.RECORDty {fieldTypes, annotation} => 
              let
                val (decls, newFields, flty) =
                    foldl
                      (fn ({label, fieldExp}, (decls, fields, flty)) =>
                          let
                            val (decls2, args, tys) =
                                transformArg context fieldExp
                            val labels = genLabels (label, List.length tys)
                            val fields2 =
                                ListPair.mapEq
                                  (fn (l, arg) => {label=l, fieldExp=arg})
                                  (labels, args)
                            val flty =
                                ListPair.foldl
                                  (fn (l, ty, z) => LabelEnv.insert (z, l, ty))
                                  flty
                                  (labels, tys)
                          in
                            (decls @ decls2, fields @ fields2, flty)
                          end)
                      (nil, nil, LabelEnv.empty)
                      fields
                val newRecordTy =
                    AT.RECORDty {fieldTypes = flty, annotation = annotation}
                val newExp =
                    MVRECORD {fields = newFields,
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
            val (labelList, expList) =
                ListPair.unzip
                  (map (fn {label, fieldExp} => (label, exp)) fields)
            val (decls, newExpList, _) = transformArgList context expList
            val newRecordTy = transformType recordTy
            val newLabels = map ATU.convertLabel labelList
            val newFields =
                ListPair.mapEq
                  (fn (label, exp) => {label=label, fieldExp=exp})
                  (labelList, newExpList)
            val newExp =
                MVRECORD
                    {
                     fields = newFields,
                     recordTy = newRecordTy,
                     annotation = expAnnotation,
                     isMutable = isMutable,
                     loc = loc
                    }
          in 
            (decls, newExp, newRecordTy)
          end
      | AC.ACSELECT {recordExp, indexExp, label, recordTy, resultTy, loc} =>
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
                    | _ =>
                      (MVMVALUES{expList = fields,
                                 tyList = fieldTys,
                                 loc = loc},
                       AT.MVALty fieldTys)
              in
                (decls, exp, ty)
              end
            | AT.RECORDty _ => 
              let
                val (decls, newRecordExp, newRecordTy, fieldTypes) = 
                  case transformArgSingle context recordExp of
                    (decls,
                     newRecordExp,
                     newRecordTy
                       as AT.RECORDty {fieldTypes,...}) =>
                    (decls, newRecordExp, newRecordTy, fieldTypes)
                  | _ => 
                    raise 
                      Control.Bug 
                        "RECORDty expected :\
                        \ (recordunboxing/main/RecordUnboxing.sml)"
                val (decls2, indexExp, indexTy) =
                    transformArgSingle context indexExp
                val decls = decls @ decls2
                fun fieldTy label =
                    case LabelEnv.find(fieldTypes,label) of
                         SOME x => x
                       | NONE => raise Control.Bug "option inb filedType (3)"
                fun fieldExp (label, indexExp) =
                    MVSELECT {recordExp = newRecordExp,
                              recordTy = newRecordTy, 
                              indexExp = indexExp,
                              label = label,
                              resultTy = fieldTy label,
                              loc = loc}
                val newLabel = ATU.convertLabel label
                val labels = labelsOf (label, recordTy)
                val fieldIndexes =
                    foldr
                      (fn (l, indexes) =>
                          if l = newLabel
                          then (l, indexExp)::indexes else
                          let
                            val exp = MVINDEXOF {label=l,
                                                 recordTy=newRecordTy,
                                                 loc=loc}
                          in
                            (l, exp)::indexes
                          end)
                      nil
                      labels
                val (decls,newExp, newTy) =
                    case fieldIndexes of
                      [(label, indexExp)] =>
                      (decls, fieldExp (label, indexExp), fieldTy label)
                    | _ =>
                      let
                        val tyList = map fieldTy labels
                        val varInfoList = map newVar tyList
                        val fieldDecls =
                            ListPair.map 
                              (fn (varInfo, exp) =>
                                  MVVAL {boundVars = [varInfo],
                                         boundExp = exp, loc = loc})
                                (varInfoList, map fieldExp fieldIndexes)
                        val expList =
                            map (fn v => MVVAR {varInfo = v, loc = loc})
                                varInfoList
                      in
                        (decls @ fieldDecls, 
                         MVMVALUES
                           {expList = expList, tyList = tyList, loc = loc}, 
                         AT.MVALty tyList)
                      end
              in
                (decls, newExp, newTy)
              end
            | _ => 
              let
                val (decls, newRecordExp, newRecordTy) =
                    transformArgSingle context recordExp
                val (decls2, newIndexExp, indexTy) =
                    transformArgSingle context indexExp
                val decls = decls @ decls2
                val newLabel = ATU.convertLabel label
                val newFieldTy =
                    CTX.fieldType context (newLabel, newRecordTy)
                    handle CTX.FieldType =>
                     (
                      print "recordTy\n";
                      printTy recordTy;
                      print "newRecordTy\n";
                      printTy newRecordTy;
                      print newLabel;
                      raise Control.Bug "CTX filedType"
                     )
                val newExp = 
                    MVSELECT
                        {
                         recordExp = newRecordExp,
                         indexExp = newIndexExp,
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
            val (decls, newRecordExp, newRecordTy) =
                transformArgSingle context recordExp
            val (decls2, newIndexExp, indexTy) =
                transformArgSingle context indexExp
            val decls = decls @ decls2
            val newLabel = ATU.convertLabel label
            val newFieldTy =
                CTX.fieldType context (newLabel, newRecordTy)
                handle CTX.FieldType =>
                 (
                  printTy newRecordTy;
                  print newLabel;
                  raise Control.Bug "CTX filedType"
                 )
                
            val newExp = 
                MVSELECT
                    {
                     recordExp = newRecordExp,
                     indexExp = newIndexExp,
                     label = newLabel,
                     recordTy = newRecordTy,
                     resultTy = newFieldTy,
                     loc = loc
                    }
          in
            (decls, newExp, newFieldTy)
          end

      | AC.ACMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy,
                     loc} =>
        let
          val (decls1, newRecordExp, newRecordTy) =
              transformArgSingle context recordExp
          val (decls2, newIndexExp, _) =
              transformArgSingle context indexExp
          val (decls3, newValueExp, newValueTy) =
              transformArgSingle context valueExp
          val newExp =
              MVMODIFY
                  {
                   recordExp = newRecordExp,
                   recordTy = newRecordTy,
                   indexExp = newIndexExp,
                   label = ATU.convertLabel label,
                   valueExp = newValueExp,
                   valueTy = newValueTy,
                   loc = loc
                  }
        in 
          (decls1 @ decls2 @ decls3, newExp, newRecordTy)
        end
        
      | AC.ACRAISE {argExp, resultTy, loc} =>
        let
          val (decls, newArgExp, _) = transformArgSingle context argExp
          val newResultTy = transformType resultTy
          val newExp =
              MVRAISE {argExp = newArgExp, resultTy = newResultTy, loc = loc}
        in 
          (decls, newExp, newResultTy)
        end

      | AC.ACHANDLE {exp,
                     exnVar as {id,...}, handler, loc} =>
        let
          val (mainDecls, newMainExp, newTy) = transformExp context exp
          val newExnVar = 
            case transformVar exnVar of 
              [newExnVar] => newExnVar
            | _ =>
              raise
                Control.Bug
                  "single value expected :\
                  \ (recordunboxing/main/RecordUnboxing.sml)"
          val (handlerDecls, newHandler, _) =
              transformExp
                (CTX.insertVariable context (id, [newExnVar]))
                handler
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
      | AC.ACFNM {argVarList, funTy as AT.FUNMty {funStatus, annotation,...}, 
                  bodyExp, 
                  annotation = funAnnotation, 
                  loc} =>
        let
          val (newArgVarList,newContext) = 
              foldr
                  (fn (v as {id,...}, (L,C)) =>
                      let
                        val varList = transformVar v
                      in
                        (varList @ L, CTX.insertVariable C (id,varList))
                      end
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
        raise
          Control.Bug
            "non FUNMty in ACFNM (recordunboxing/main/RecordUnboxing.sml)"
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
          ([],
           newExp,
           AT.POLYty{boundtvars = newBtvEnv, body = newExpTyWithoutTAbs})
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
          val (decls, newSwitchExp, newExpTy) =
              transformArgSingle context switchExp
          val (defaultDecls, newDefaultExp, newDefaultTy) =
              transformExp context defaultExp
          fun transformBranch {constant, exp} =
              let
                val (decls, newExp, _) = transformExp context exp
              in 
                {constant = constant, exp = makeLetExp (decls, newExp, loc)}
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
        AC.ACVAL {boundVar as {path, ty, id},
                  boundExp , loc} =>
        let
          val (decls1, args, tyList) = transformArg context boundExp
          val (varList, decls2) =
              case (args, tyList) of
                ([arg], [ty]) =>
                let
                  val varInfo = {path = path, ty = ty, id = id}
                  val decl = MVVAL {boundVars = [varInfo],
                                    boundExp = arg,
                                    loc = loc}
                in
                  ([varInfo], [decl])
                end
              | _ =>
                ListPair.foldr
                  (fn (arg,ty,(L1,L2)) =>
                      case arg of
                        MVVAR {varInfo, loc} => (varInfo :: L1,L2)
                      | _ =>
                        let
                          val varInfo = newVar ty
                          val decl = MVVAL {boundVars = [varInfo],
                                            boundExp = arg,
                                            loc = loc}
                        in
                          (varInfo :: L1, decl :: L2)
                        end
                  )
                  ([],[])
                  (args,tyList)
        in
          (decls1 @ decls2, CTX.insertVariable context (id,varList))
        end

      | AC.ACEXPORTVAR {varInfo={path, ty, id}, loc} =>
        let
          val newVarInfo =
              case CTX.findVariable (context, id) of
                SOME [v as {id,ty,...}] => {path = path, ty = ty, id = id}
              | _ => raise Control.Bug "ACEXPORTVAR"
          val newDecl = MVEXPORTVAR {varInfo = newVarInfo, loc = loc}
        in
          ([newDecl], context)
        end

      | AC.ACEXTERNVAR {exVarInfo={path, ty}, loc} =>
        let
          val newTy = transformType ty
          val newVar = {path = path, ty = newTy}
          val newDecl = MVEXTERNVAR {exVarInfo = newVar, loc = loc}
        in
          ([newDecl], context)
        end

      | AC.ACVALREC {recbindList, loc} =>
        let
          val newBoundVarList = 
              map
                  (fn {boundVar as {path, ty, id},...} => 
                      {path = path, ty = transformType ty, id = id})
                  recbindList
          val newContext = 
              foldl
                  (fn (v as {id,...},C) =>
                      CTX.insertVariable C (id,[v]))
                  context
                  newBoundVarList
          val newRecbindList =
              ListPair.map
                (fn ({boundExp,...}, boundVar) =>
                    let
                      val (_, newBoundExp, _) =
                          transformExp newContext boundExp
                    in
                      {boundVar = boundVar, boundExp = newBoundExp}
                    end
                )
                (recbindList,newBoundVarList)
        in
          ([MVVALREC{recbindList = newRecbindList, loc = loc}], newContext)
        end

  and transformDeclList context ([]) = ([],context)
    | transformDeclList context (decl::rest) =
      let
        val (decls1, newContext) = transformDecl context decl
        val (decls2, newContext) = transformDeclList newContext rest
      in
        (decls1 @ decls2,newContext)
      end

  fun transform declList = 
      let
        val (newDeclList, _) = transformDeclList CTX.empty declList
      in
        newDeclList
      end

end
