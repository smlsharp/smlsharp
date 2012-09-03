(**
 * AnnotatedCalc utilities
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)

structure AnnotatedTypesUtils : ANNOTATEDTYPESUTILS = struct

  structure T = Types
  structure AT = AnnotatedTypes
  structure CT = ConstantTerm
  structure BV = BuiltinEnv

(*
  (* Types utilities*)

  fun flatTyList (AT.MVALty tyList) = tyList
    | flatTyList ty = [ty]

*)
  fun constDefaultTy const = 
      case const of
        CT.INT _ => AT.intty
      | CT.LARGEINT _ => AT.largeIntty
      | CT.WORD _ => AT.wordty
      | CT.BYTE _ => AT.bytety
      | CT.REAL _ => AT.realty
      | CT.FLOAT _ => AT.floatty
      | CT.STRING _ => AT.stringty
      | CT.CHAR _ => AT.charty
      | CT.UNIT => AT.unitty
      | CT.NULLPOINTER => AT.CONty {tyCon = BV.PTRtyCon,
                                    args = [AT.unitty]}
      | CT.NULLBOXED => AT.CONty {tyCon = BV.BOXEDtyCon, args = []}

(*
  fun fieldTypes (AT.RECORDty{fieldTypes,...}) = fieldTypes
    | fieldTypes _ = raise Control.Bug "record type is expected"

  fun recordFieldTy (AT.RECORDty{fieldTypes,...}, label) =
      (
       case SEnv.find(fieldTypes, label) of
         SOME ty => ty
       | _ => raise Control.Bug "label not found"
      )
    | recordFieldTy _ = raise Control.Bug "record type is expected"

  fun arrayElementTy (AT.RAWty{args=[ty],...}) = ty
    | arrayElementTy _ = raise Control.Bug "array type is expected"

  fun argTyList (AT.FUNMty {argTyList,...}) = argTyList
    | argTyList _ = raise Control.Bug "function type is expected"
*)
  fun expandFunTy (AT.FUNMty arg) = arg
    | expandFunTy ty =
      raise Control.Bug "function type is expected"
before print (Control.prettyPrint (AT.format_ty ty))
(*
  fun expandRecordTy (AT.RECORDty arg) = arg
    | expandRecordTy _ = raise Control.Bug "record type is expected"
 
*)
  fun substitute subst ty =
      case ty of
        AT.SINGLETONty sty =>
        AT.SINGLETONty (substituteSingletonTy subst sty)
      | AT.BOUNDVARty tid =>
        (case BoundTypeVarID.Map.find(subst,tid) of
           SOME ty => ty
         | NONE => ty
        )
      | AT.FUNMty {argTyList, bodyTy, annotation, funStatus} =>
        AT.FUNMty
            {
             argTyList = map (substitute subst) argTyList,
             bodyTy = substitute subst bodyTy,
             annotation = annotation,
             funStatus = funStatus
            }
      | AT.MVALty tyList => AT.MVALty (map (substitute subst) tyList)
      | AT.RECORDty {fieldTypes, annotation} =>
        AT.RECORDty
            {
             fieldTypes = LabelEnv.map (substitute subst) fieldTypes,
             annotation = annotation
            }
      | AT.CONty {tyCon, args} =>
        AT.CONty {tyCon = tyCon, args = map (substitute subst) args}
      | AT.POLYty {boundtvars, body} =>
        let
          val subst =
              BoundTypeVarID.Map.foldli
                (fn (tid, _, subst) =>
                    if BoundTypeVarID.Map.inDomain (subst, tid)
                    then #1 (BoundTypeVarID.Map.remove (subst, tid))
                    else subst)
                subst
                boundtvars
        in
           AT.POLYty
              {
               boundtvars = substituteBtvEnv subst boundtvars,
               body = substitute subst body
              }
        end
      | _ => ty

  and substituteSingletonTy subst singletonTy =
      case singletonTy of
        AT.INSTCODEty {oprimId,path,keyTyList} =>
        AT.INSTCODEty
          {
           oprimId = oprimId,
           path = path,
           keyTyList =  map (substitute subst) keyTyList
          }
      | AT.INDEXty (label, ty) =>
        AT.INDEXty (label, substitute subst ty)
      | AT.TAGty ty =>
        AT.TAGty (substitute subst ty)
      | AT.SIZEty ty =>
        AT.SIZEty (substitute subst ty)
      | AT.RECORDSIZEty ty =>
        AT.RECORDSIZEty (substitute subst ty)
      | AT.RECORDBITMAPty (index, ty) =>
        AT.RECORDBITMAPty (index, substitute subst ty)

  and substituteBtvEnv subst btvEnv =
      BoundTypeVarID.Map.map (substituteBtvKind subst) btvEnv

  and substituteBtvKind subst {id, tvarKind, eqKind} =
      {
       id = id,
       tvarKind = substituteRecordKind subst tvarKind,
       eqKind = eqKind
      } : AT.btvKind

  and substituteRecordKind subst recordKind =
      case recordKind of 
        AT.UNIV => AT.UNIV
      | AT.REC flty => AT.REC (LabelEnv.map (substitute subst) flty)
      | AT.OPRIMkind instances
        => 
        AT.OPRIMkind (map (substitute subst) instances)

  fun makeSubst (btvEnv, tyList) =
      ListPair.foldr
          (fn ((i, _), ty, S) => BoundTypeVarID.Map.insert(S, i, ty))
          BoundTypeVarID.Map.empty
          (BoundTypeVarID.Map.listItemsi btvEnv, tyList)
      
  fun tpappTy (ty, nil) = ty
    | tpappTy (AT.POLYty{boundtvars, body, ...}, tyl) = 
      substitute (makeSubst (boundtvars, tyl)) body
    | tpappTy _ = raise Control.Bug "tpappTy" 

  fun cardinality ty =
      case ty of 
        AT.MVALty tyList => List.length tyList
      | _ => 1

(*
  val numericalLabelLength = 2
  bug 175_bigrecord.sml
*)
  val numericalLabelLength = 5

  fun convertNumericalLabel i =
      let
        fun pad 0 = ""
          | pad n = "0" ^ (pad (n - 1))
        val s = Int.toString i
        val n = String.size s
      in
        if n > numericalLabelLength
        then raise Control.Bug "record index is too big"
        else "$" ^ (pad (numericalLabelLength - n)) ^ s
      end

  fun convertLabel label = 
      case Int.fromString label of
        SOME i => convertNumericalLabel i
      | _ => label 

(*
(*
  fun newVar ty = 
      let
        val id = ID.generate()
      in
        {id = id, displayName = "$" ^ ID.toString id, ty = ty, kind = Types.INTERNAL}
      end
*)

  fun isGlobal {displayName, ty, varId = T.INTERNAL _} = false
    | isGlobal _ = true

  fun listCompare f (argList1, argList2) = 
      let
        fun compare ([],[]) = EQUAL 
          | compare (arg1::rest1, arg2::rest2) = 
            (
             case f(arg1,arg2) of
               EQUAL => compare(rest1,rest2)
             | d => d
            )
          | compare _ = raise Control.Bug "argsCompare"
        val n1 = List.length argList1
        val n2 = List.length argList2
      in
        if n1 < n2 
        then LESS 
        else if n1 = n2 then compare(argList1, argList2) else GREATER
      end
      
  fun wordPairCompare ((x1,y1),(x2,y2)) =
      case Word32.compare (x1,x2) of
        GREATER => GREATER
      | EQUAL => Word32.compare(y1,y2)
      | LESS => LESS

  fun newFunctionId () = FunctionAnnotationID.generate ()

  fun freshAnnotationLabel () = AnnotationLabelID.generate ()
  (* by default, all records are unboxed and not aligned,
   * these properties will be constrainted by unification
   *)
  fun freshRecordAnnotation () = {labels = AT.LE_UNKNOWN, boxed = false, align = false}
*)
  fun freshFunctionAnnotation () = ref {labels = AT.LE_UNKNOWN, boxed = false}
(*
  fun newLocalFunStatus ({functionId, owners, codeStatus}:AT.funStatus) = 
    {
     functionId = newFunctionId (),
     owners = 
       case codeStatus of
         ref AT.CLOSURE => [{ownerId = functionId , ownerCode = codeStatus}]
       | ref AT.GLOBAL_FUNSTATUS => nil
       | ref AT.LOCAL => {ownerId = functionId, ownerCode = codeStatus} :: owners,
    codeStatus = 
       case codeStatus of
         ref AT.CLOSURE => ref AT.LOCAL
       | ref AT.LOCAL => ref AT.LOCAL
       | ref AT.GLOBAL_FUNSTATUS => ref AT.CLOSURE
     }

  fun globalFunStatus () = 
    {
     functionId = newFunctionId (),
     owners = nil,
     codeStatus = ref AT.GLOBAL_FUNSTATUS
     } : AT.funStatus
*)
  fun newClosureFunStatus () = 
    {
     functionId = FunctionAnnotationID.generate (),
     owners = nil,
     codeStatus = ref AT.CLOSURE
     } : AT.funStatus
(*
  fun coerceClosure ty =
    case ty of 
      AT.FUNMty {funStatus = {codeStatus, ...}, ...} =>
        codeStatus := AT.CLOSURE
    | AT.POLYty {body,...} => coerceClosure body
    | _ => ()
*)
  fun makeClosureFunTy (argTyList, bodyTy) =
      AT.FUNMty {argTyList = argTyList,
                 bodyTy = bodyTy,
                 funStatus = newClosureFunStatus (),
                 annotation = ref {labels = AT.LE_GENERIC, boxed = true}}
(*
  fun makeLocalFunTy (argTyList, bodyTy) =
      AT.FUNMty {argTyList = argTyList,
                 bodyTy = bodyTy,
                 funStatus = {functionId = newFunctionId (),
                              owners = nil,
                              codeStatus = ref AT.LOCAL},
                 annotation = ref {labels = AT.LE_GENERIC, boxed = true}}
*)
  fun isLocalFunTy ty =
    case ty of
      AT.FUNMty {funStatus = {codeStatus = ref AT.LOCAL,...},...} => true
    | _ => false
(*
(*
  fun generateExtraList {tagTyCon, sizeTyCon, indexTyCon} (btvEnv : AT.btvEnv) =
      let
        fun generate {id,recordKind,eqKind,instancesRef,representationRef} =
            case recordKind of
              AT.REC flty =>
              map (fn label => indexTyCon (id, label)) (SEnv.listKeys flty)
            | _ =>
              (
               case !representationRef of
                 AT.ATOM_REP => []
               | AT.BOXED_REP => []
               | AT.DOUBLE_REP => []
               | AT.SINGLE_REP => [tagTyCon id]
               | AT.UNBOXED_REP => [sizeTyCon id]
               | _ => 
                 if !Control.enableUnboxedFloat
                 then [tagTyCon id, sizeTyCon id]
                 else [tagTyCon id]
              )
      in
        IEnv.foldr (fn (btvKind, L) => (generate btvKind) @ L) [] btvEnv
      end
*)
*)

end
