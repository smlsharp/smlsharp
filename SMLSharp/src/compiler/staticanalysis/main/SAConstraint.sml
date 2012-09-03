(**
 * SAConstraint
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure SAConstraint : SACONSTRAINT = struct
  structure T = Types
  structure AT = AnnotatedTypes
  structure ATU = AnnotatedTypesUtils

  datatype constraint =
           RECORD_EQUIV of (AT.recordAnnotation ref) * (AT.recordAnnotation ref)
         | FUNCTION_EQUIV of (AT.functionAnnotation ref) * (AT.functionAnnotation ref)

  (* StaticAnalysis keeps a set of annotation equivalent for resolving later*)
  val constraintsRef = ref ([] : constraint list)

  (* StaticAnalysis keeps a set of generic bound type variable for 
   * resolve later
   *)
  val genericTyVars = ref (ISet.empty)

  val btvInfo = ref (IEnv.empty : AT.btvEnv)

  fun btvEq (btvKind1 : AT.btvKind, btvKind2 : AT.btvKind) =
      case (btvKind1, btvKind2) of
        ({recordKind = AT.UNIV,...}, {recordKind = AT.UNIV,...}) => true
      | ({recordKind = AT.REC flty1,...}, {recordKind = AT.REC flty2,...}) => 
        (List.all
            (fn l => case SEnv.find(flty2,l) of SOME _ => true | _ => false)
            (SEnv.listKeys flty1)) andalso
        (List.all
            (fn l => case SEnv.find(flty1,l) of SOME _ => true | _ => false)
            (SEnv.listKeys flty2))
      | _ => false

             
  fun genericTyVar tid = genericTyVars := ISet.add(!genericTyVars, tid)

  fun recordEquivalence (annotationRef1,annotationRef2) = 
      constraintsRef := (RECORD_EQUIV(annotationRef1, annotationRef2)) :: (!constraintsRef)

  fun functionEquivalence (annotationRef1,annotationRef2) = 
      constraintsRef := (FUNCTION_EQUIV(annotationRef1, annotationRef2)) :: (!constraintsRef)

  fun globalType ty =
      case ty of
        AT.BOUNDVARty tid => genericTyVar tid
      | AT.FUNMty {argTyList, bodyTy, annotation, funStatus} =>
        (
         annotation := {labels = AT.LE_GENERIC, boxed = true};
         List.app globalType argTyList;
         globalType bodyTy
        )
      | AT.RECORDty {fieldTypes, annotation} =>
        (
         annotation := {labels = AT.LE_GENERIC, boxed = true, align = true};
         SEnv.app globalType fieldTypes
        )
      | AT.RAWty {tyCon, args} => List.app globalType args
      | AT.POLYty {boundtvars, body} => 
        (
         IEnv.appi 
             (fn (tid,{recordKind, ...}) => genericTyVar tid)
             boundtvars;
         globalType body
        )
      | _ => ()

  fun singleValueType ty =
      case ty of 
        AT.FUNMty {annotation as ref {labels, ...},...} => 
        annotation := {labels = labels, boxed = true}
      | AT.RECORDty {annotation as ref {labels, align,...},...} => 
        annotation := {labels = labels, boxed = true, align = align}
      | _ => ()

  fun convertGlobalType ty =
      case ty of
        T.ERRORty => AT.ERRORty
      | T.DUMMYty i => AT.DUMMYty i                  
      | T.TYVARty (ref (T.SUBSTITUTED ty)) => convertGlobalType ty
      | T.TYVARty (ref (T.TVAR {id,...})) =>
        raise 
          Control.Bug
          ("convertGlobalType: free type variable: " ^
           FreeTypeVarID.toString id)
      | T.BOUNDVARty tid => AT.BOUNDVARty tid
      | T.FUNMty (argTyList, bodyTy) =>
        AT.FUNMty
            {
             argTyList = map convertGlobalType argTyList,
             bodyTy = convertGlobalType bodyTy,
             funStatus = ATU.newClosureFunStatus(),
             annotation = ref {labels = AT.LE_GENERIC, boxed = true}
            }
      | T.RECORDty flty =>
        AT.RECORDty 
            {
             fieldTypes = SEnv.map convertGlobalType flty,
             annotation = ref {labels = AT.LE_GENERIC, boxed = true, align = true}
            }
      | T.RAWty {tyCon, args} =>
        AT.RAWty
            {
             tyCon = tyCon,
             args = map convertGlobalType args
            }
      | T.POLYty {boundtvars, body} =>
        AT.POLYty 
            {
             boundtvars = convertGlobalBtvEnv boundtvars,
             body = convertGlobalType body
            }
      | T.ALIASty (_, realTy) => convertGlobalType realTy
      | T.OPAQUEty {implTy,...} => convertGlobalType implTy
      | T.SPECty {tyCon, args} =>
(* FIXME: is this correct? *)
        AT.SPECty
            {
              tyCon = tyCon,
              args = map convertGlobalType args
            }
(*
      | T.SPECty abstractTy => 
        let
            val s = Control.prettyPrint (Types.format_ty [] ty)
        in
            if !Control.doCompileObj orelse !Control.doFunctorCompile then 
                convertGlobalType abstractTy
            else
                raise Control.Bug ("invalid type 3:" ^ s )
        end
*)

  and convertGlobalBtvKind (id, btvKind as {index, recordKind, eqKind} : Types.btvKind) =
      let
        val _ = genericTyVar id
        val newRecordKind = convertGlobalRecKind recordKind
        val newBtvKind = 
            {
             id = id,
             eqKind = eqKind,
             recordKind = newRecordKind,
             instancesRef = ref []
            }
      in
        newBtvKind
      end

  and convertGlobalBtvEnv (btvEnv : Types.btvEnv) =
      IEnv.mapi convertGlobalBtvKind btvEnv

  and convertGlobalRecKind recordKind =
      case recordKind of
        T.UNIV => AT.UNIV
      | T.REC flty => AT.REC (SEnv.map convertGlobalType flty)
      | T.OVERLOADED tyList =>
        raise Control.Bug "convertGlobalRecKind: OVERLOADED"

  fun convertLocalType ty =
      case ty of
        T.ERRORty => AT.ERRORty
      | T.DUMMYty i => AT.DUMMYty i                  
      | T.TYVARty (ref (T.SUBSTITUTED ty)) => convertLocalType ty
      | T.TYVARty (ref (T.TVAR {id,...})) =>
        raise
          Control.Bug 
          ("convertLocalType: free type variable" ^
           FreeTypeVarID.toString id)
      | T.BOUNDVARty tid => AT.BOUNDVARty tid
      | T.FUNMty (argTyList, bodyTy) =>
        AT.FUNMty
            {
             argTyList = map convertLocalType argTyList,
             bodyTy = convertLocalType bodyTy,
             funStatus = ATU.newClosureFunStatus(),
             annotation = ATU.freshFunctionAnnotation ()
            }
      | T.RECORDty flty =>
        AT.RECORDty 
            {
             fieldTypes = SEnv.map convertLocalType flty,
             annotation = ref {labels = AT.LE_UNKNOWN, boxed = false, align = false}
            }
      | T.RAWty {tyCon, args} =>
        AT.RAWty
            {
             tyCon = tyCon,
             args = map convertSingleValueType args
            }
      | T.POLYty {boundtvars, body} =>
        (* only for the polymorphic handle generated by PrinterGenerator*)
        AT.POLYty 
            {
             boundtvars = convertLocalBtvEnv boundtvars,
             body = convertLocalType body
            }
      | T.ALIASty (_, realTy) => convertLocalType realTy
      | T.OPAQUEty {implTy,...} => convertLocalType implTy
      | T.SPECty {tyCon, args} =>
(* FIXME: is this correct? *)
        AT.SPECty
            {
              tyCon = tyCon,
              args = map convertLocalType args
            }
(*
      | T.SPECty ty => convertLocalType ty
*)
(*
            (print "SPECty\n";
             let
                 val s = Control.prettyPrint (Types.format_ty [] ty)
             in
               raise Control.Bug ("invalid type 1:" ^ s )
             end)
*)

  and convertSingleValueType ty =
      let 
        val newTy = convertLocalType ty
        val _ = singleValueType newTy
      in
        newTy
      end

  and convertLocalBtvKind (id, btvKind as {index, recordKind, eqKind} : Types.btvKind) =
      (
       case IEnv.find(!btvInfo, id) of
         SOME newBtvKind => newBtvKind
       | NONE =>
         let
           val newRecordKind = convertLocalRecKind recordKind
           val newBtvKind = 
               {
                id = id,
                eqKind = eqKind,
                recordKind = newRecordKind,
                instancesRef = ref []
               }
         in
           (
            btvInfo := (IEnv.insert(!btvInfo,id,newBtvKind));
            newBtvKind
           )
         end
      )

  and convertLocalBtvEnv (btvEnv : Types.btvEnv) =
      IEnv.mapi convertLocalBtvKind btvEnv

  and convertLocalRecKind recordKind =
      case recordKind of
        T.UNIV => AT.UNIV
      | T.REC flty => AT.REC (SEnv.map convertLocalType flty)
      | T.OVERLOADED tyList =>
        raise Control.Bug "convertLocalRecKind: OVERLOADED"

  and convertTyBindInfo tyBindInfo =
      case tyBindInfo of
        T.TYCON {tyCon, datacon} => AT.TYCON tyCon
      | T.TYSPEC spec => AT.TYSPEC spec 
      | T.TYFUN {name, strpath, tyargs, body} =>
        AT.TYFUN {tyargs = convertGlobalBtvEnv tyargs,
                  body = convertGlobalType body}
      | T.TYOPAQUE {spec, impl} => convertTyBindInfo impl

  fun unify (ty1,ty2) =
      case (ty1,ty2) of
        (AT.ERRORty, AT.ERRORty) => ()
      | (AT.DUMMYty _, AT.DUMMYty _) => ()
      | (AT.BOUNDVARty tid1, AT.BOUNDVARty tid2) =>
        if tid1 = tid2 
        then () 
        else
          let
            val s1 = Control.prettyPrint (AT.format_ty ty1)
            val s2 = Control.prettyPrint (AT.format_ty ty2)
          in
            raise Control.Bug ("Unification fails (2) " ^ s1 ^ "," ^ s2)
          end
      | (AT.FUNMty {argTyList=argTyList1, bodyTy=bodyTy1, annotation = annotation1,...},
         AT.FUNMty {argTyList=argTyList2, bodyTy=bodyTy2, annotation = annotation2,...}
        ) =>
        (
         ListPair.app unify (argTyList1,argTyList2);
         unify (bodyTy1,bodyTy2);
         functionEquivalence (annotation1,annotation2)
        )
      | (AT.RECORDty {fieldTypes = fieldTypes1, annotation = annotation1},
         AT.RECORDty {fieldTypes = fieldTypes2, annotation = annotation2}
        ) =>
        (
         ListPair.app unify (SEnv.listItems fieldTypes1, SEnv.listItems fieldTypes2);
         recordEquivalence (annotation1,annotation2)
        )
      | (AT.RAWty {tyCon=tyCon1, args = args1},AT.RAWty {tyCon=tyCon2, args = args2}) => 
        ListPair.app unify (args1,args2)
      | (AT.POLYty {boundtvars = boundtvars1, body=body1}, AT.POLYty {boundtvars = boundtvars2, body=body2}) => 
        (
         ListPair.app unifyBtvKind (IEnv.listItems boundtvars1, IEnv.listItems boundtvars2);
         unify(body1,body2) 
        )
      | (AT.SPECty {args = args1,...}, AT.SPECty {args = args2, ...}) => 
        ListPair.app unify (args1,args2)
      | (AT.SPECty {args = args1,...}, AT.RAWty {args = args2,...}) => 
        (* Liu: this case and the following case between SPECty and CONty are 
         * due to the sharing specification. For example,
         * sig datatype t = foo
               type s 
	       sharing type s = t
               val x : s 
               val y : t
         * end
         * Here "s" for "x" is represented as "SPECty(s)", while "t" for "y" as "CONty(t)" 
         * with the same tyConId of "s".
         *)
        ListPair.app unify (args1,args2)
      | (AT.RAWty {args = args1,...}, AT.SPECty {args = args2,...}) => 
        ListPair.app unify (args1,args2)
      | _ => 
          let
            val s1 = Control.prettyPrint (AT.format_ty ty1)
            val s2 = Control.prettyPrint (AT.format_ty ty2)
          in
            raise Control.Bug ("Unification fails (3)  " ^ s1 ^ "," ^ s2)
          end

  and unifyRecKind (recordKind1 : AT.recordKind, recordKind2 : AT.recordKind) =
      case (recordKind1, recordKind2) 
       of (AT.UNIV, AT.UNIV) => ()
        | (AT.REC flty1, AT.REC flty2) => 
          ListPair.app unify (SEnv.listItems flty1, SEnv.listItems flty2)
        | _ => raise Control.Bug "inconsistent reckind to unifyRecKind (staticanalysis/main/SAConstraint.sml)"

  and unifyBtvKind (btvKind1 : AT.btvKind, btvKind2 : AT.btvKind) =
      unifyRecKind (#recordKind btvKind1, #recordKind btvKind2)
          

  (* is a polymorphic type is instanciated with a list of instance types, we may need 
   * to perform unification if some instance type refer to the same type
   * E.g. 
   *    polymorphic type :          \forall{t1#{a:t2},t2}.\sigma 
   *    instance argument types :   {{a:\tau1,b:int},\tau2}
   * we need to unify the conversion of \tau1 and \tau2
   *)

  fun addInstances (btvEnv : AT.btvEnv, tyList) =
      let
        val instanceMap = ref (IEnv.empty : AT.ty IEnv.map)
        fun instanceUnify (generalTy,instanceTy) =
            case (generalTy,instanceTy) of
              (AT.ERRORty, AT.ERRORty) => ()
            | (AT.DUMMYty _, AT.DUMMYty _) => ()
            | (AT.BOUNDVARty tid1, _) =>
              (
               case IEnv.find(btvEnv,tid1) of
                 SOME {recordKind, ...} => 
                 (
                  case IEnv.find(!instanceMap, tid1) of 
                    SOME ty => unify(ty,instanceTy)
                  | _ => instanceMap := IEnv.insert(!instanceMap, tid1, instanceTy);
                  case recordKind of
                    AT.REC flty1 =>
                    let
                      val flty2 =
                          case instanceTy of
                            AT.RECORDty {fieldTypes, ...} => fieldTypes
                          | AT.BOUNDVARty tid2 =>
                            (
                             case IEnv.find(!btvInfo, tid2) of
                               SOME {recordKind = AT.REC fieldTypes,...} => fieldTypes
                             | _ => raise Control.Bug "invalid instance"
                            )
                          | _ => 
                            let
                              val s1 = Control.prettyPrint (AT.format_ty generalTy)
                              val s2 = Control.prettyPrint (AT.format_ty instanceTy)
                            in
                              raise Control.Bug ("invalid instance:" ^ s1 ^ "," ^ s2)
                            end
                    in
                      instanceUnifyFieldTypes (flty1,flty2)
                    end
                  | _ => ()
                 )
               | _ => ()
              )
              
            | (AT.FUNMty {argTyList=argTyList1, bodyTy=bodyTy1, annotation = annotation1,...},
               AT.FUNMty {argTyList=argTyList2, bodyTy=bodyTy2, annotation = annotation2,...}
              ) =>
              (
               ListPair.app instanceUnify (argTyList1,argTyList2);
               instanceUnify (bodyTy1,bodyTy2);
               functionEquivalence (annotation1,annotation2)
              )
            | (AT.RECORDty {fieldTypes = fieldTypes1, annotation = annotation1},
               AT.RECORDty {fieldTypes = fieldTypes2, annotation = annotation2}
              ) =>
              (
               ListPair.app instanceUnify (SEnv.listItems fieldTypes1, SEnv.listItems fieldTypes2);
               recordEquivalence (annotation1,annotation2)
              )
            | (AT.RAWty {args = args1,...},AT.RAWty {args = args2,...}) =>
              ListPair.app instanceUnify (args1, args2)
            | (AT.POLYty {body=body1,...}, AT.POLYty {body=body2,...}) =>
              raise Control.Bug "never unifying second order type"
            | _ => 
                let
                  val s1 = Control.prettyPrint (AT.format_ty generalTy)
                  val s2 = Control.prettyPrint (AT.format_ty instanceTy)
                in
                  raise Control.Bug ("Unification fails (4)  " ^ s1 ^ "," ^ s2)
                end

        and instanceUnifyFieldTypes (flty1,flty2) =
            SEnv.appi
                (fn (label,ty1) =>
                    case SEnv.find(flty2,label) of
                      SOME ty2 => instanceUnify (ty1,ty2)
                    | NONE => raise Control.Bug "record field not found"
                )
                flty1
                
        fun addInstance (tid, ty) = 
            (
             singleValueType ty;
             instanceUnify (AT.BOUNDVARty tid, ty);
             case IEnv.find(!btvInfo, tid) of
               SOME {instancesRef,...} => instancesRef := ty::(!instancesRef)
             | _ => () (*global type variables always have generic representation*)
            )        
      in
        ListPair.app addInstance (IEnv.listKeys btvEnv, tyList)
      end 

  fun solveAnnotation () = 
      let
        val flag = ref true
        fun labelsDiff (AT.LE_GENERIC, AT.LE_GENERIC) = false
          | labelsDiff (AT.LE_UNKNOWN, AT.LE_UNKNOWN) = false
          | labelsDiff (AT.LE_LABELS S1, AT.LE_LABELS S2) = not (ISet.equal(S1,S2))
          | labelsDiff _ = true

        fun unifyLabels (labels1,labels2) =
            case (labels1,labels2) of
              (AT.LE_GENERIC,_) => AT.LE_GENERIC
            | (_,AT.LE_GENERIC) => AT.LE_GENERIC
            | (AT.LE_UNKNOWN,_) => labels2
            | (_,AT.LE_UNKNOWN) => labels1
            | (AT.LE_LABELS lset1,AT.LE_LABELS lset2) => 
              AT.LE_LABELS (ISet.union(lset1,lset2))
                    
        fun loop () =
            if !flag 
            then
              (
(*               print "aaaaa\n"; *)
               flag := false;
               List.app
                   (fn (RECORD_EQUIV
                            (ann1 as ref {labels=labels1, boxed=boxed1, align=align1},
                             ann2 as ref {labels=labels2, boxed=boxed2, align=align2})) =>
                       let
                         val ann = 
                             {
                              labels = unifyLabels (labels1, labels2), 
                              boxed = boxed1 orelse boxed2, 
                              align = align1 orelse align2
                             }
                         val _ = 
                             if labelsDiff(labels1,labels2) orelse (boxed1 <> boxed2) orelse (align1 <> align2) 
                             then flag := true 
                             else ()
                       in
                         (ann1 := ann; ann2 := ann)
                       end
                     | (FUNCTION_EQUIV
                            (ann1 as ref {labels=labels1, boxed=boxed1},
                             ann2 as ref {labels=labels2, boxed=boxed2})) =>
                       let
                         val ann = 
                             {
                              labels = unifyLabels (labels1, labels2), 
                              boxed = boxed1 orelse boxed2
                             }
                         val _ = 
                             if labelsDiff(labels1,labels2) orelse (boxed1 <> boxed2)
                             then flag := true
                             else ()
                       in
                         (ann1 := ann; ann2 := ann)
                       end)
                   (!constraintsRef);
               loop ()
              )
            else ()
      in
        loop ()
      end

  fun solve () = solveAnnotation ()

  fun initialize () =
      (
       constraintsRef := ([] : constraint list);
       btvInfo := (IEnv.empty : AT.btvEnv);
       genericTyVars := ISet.empty
      )

end
