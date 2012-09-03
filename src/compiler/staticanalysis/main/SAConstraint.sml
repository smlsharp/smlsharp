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

  fun printTy ty = print (Control.prettyPrint (AT.format_ty ty) ^ "\n")
  fun printBtvEnv env =
      print (Control.prettyPrint (AT.format_btvEnv env) ^ "\n")

  exception Unify

  datatype constraint =
    RECORD_EQUIV of (AT.recordAnnotation ref) * (AT.recordAnnotation ref)
  | FUNCTION_EQUIV of
    (AT.functionAnnotation ref) * (AT.functionAnnotation ref)

 (* StaticAnalysis keeps a set of annotation equivalent for resolving later*)
  val constraintsRef = ref ([] : constraint list)

  (* StaticAnalysis keeps a set of generic bound type variable for 
   * resolve later
   *)
  val genericTyVars = ref (BoundTypeVarID.Set.empty)

(*
  val btvInfo = ref (BoundTypeVarID.Map.empty : AT.btvEnv)
*)

(*
  fun btvEq (btvKind1 : AT.btvKind, btvKind2 : AT.btvKind) =
      case (btvKind1, btvKind2) of
        ({recordKind = AT.UNIV,...}, {recordKind = AT.UNIV,...}) => true
      | ({recordKind = AT.REC flty1,...},
         {recordKind = AT.REC flty2,...}) => 
        (List.all
           (fn l => case SEnv.find(flty2,l) of SOME _ => true | _ => false)
           (SEnv.listKeys flty1)) andalso
        (List.all
           (fn l => case SEnv.find(flty1,l) of SOME _ => true | _ => false)
           (SEnv.listKeys flty2))
      | _ => false
*)
             
  fun genericTyVar tid =
      genericTyVars := BoundTypeVarID.Set.add(!genericTyVars, tid)

  fun recordEquivalence (annotationRef1,annotationRef2) = 
      constraintsRef := (RECORD_EQUIV(annotationRef1, annotationRef2))
                        :: (!constraintsRef)

  fun functionEquivalence (annotationRef1,annotationRef2) = 
      constraintsRef := (FUNCTION_EQUIV(annotationRef1, annotationRef2))
                        :: (!constraintsRef)

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
         LabelEnv.app globalType fieldTypes
        )
      | AT.CONty {tyCon, args} => List.app globalType args
      | AT.POLYty {boundtvars, body} => 
        (
         BoundTypeVarID.Map.appi 
             (fn (tid,{tvarKind, ...}) =>
                 (
                  genericTyVar tid;
                  globalKind tvarKind
                 )
             )
             boundtvars;
         globalType body
        )
      | _ => ()

  and globalKind kind = 
      case kind of
        AT.UNIV => ()
      | AT.OPRIMkind instances => app globalType instances
      | AT.REC tySEnvMap => LabelEnv.app globalType tySEnvMap


  fun singleValueType ty =
      case ty of 
        AT.FUNMty {annotation as ref {labels, ...},...} => 
        annotation := {labels = labels, boxed = true}
      | AT.RECORDty {annotation as ref {labels, align,...},...} => 
        annotation := {labels = labels, boxed = true, align = align}
      | _ => ()

  fun convertGlobalType ty =
      case ReduceTy.reduceTy ty of
        T.SINGLETONty sty =>
        AT.SINGLETONty (convertGlobalSingletonTy sty)
      | T.ERRORty => AT.ERRORty
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
             fieldTypes = LabelEnv.map convertGlobalType flty,
             annotation =
               ref {labels = AT.LE_GENERIC, boxed = true, align = true}
            }
      | T.CONSTRUCTty {tyCon, args} =>
        AT.CONty
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

  and convertGlobalSingletonTy singletonTy =
      case singletonTy of
        T.INSTCODEty {oprimId, path, keyTyList, match, instMap} =>
        AT.INSTCODEty
          {oprimId = oprimId,
           path = path,
           keyTyList =  map convertGlobalType keyTyList
          }
      | T.INDEXty (label, ty) =>
        AT.INDEXty (label, convertGlobalType ty)
      | T.TAGty ty =>
        AT.TAGty (convertGlobalType ty)
      | T.SIZEty ty =>
        AT.SIZEty (convertGlobalType ty)

  and convertGlobalBtvKind
        (id, btvKind as {tvarKind, eqKind} : Types.btvKind) =
      let
        val _ = genericTyVar id
        val newTvarKind = convertGlobalRecKind tvarKind
        val newBtvKind = 
            {
             id = id,
             eqKind = eqKind,
             tvarKind = newTvarKind
            }
      in
        newBtvKind
      end

  and convertGlobalBtvEnv (btvEnv : Types.btvEnv) =
      BoundTypeVarID.Map.mapi convertGlobalBtvKind btvEnv

  and convertGlobalRecKind tvarKind =
      case tvarKind of
        T.UNIV => AT.UNIV
      | T.REC flty => AT.REC (LabelEnv.map convertGlobalType flty)
      | T.OPRIMkind {instances, operators} =>
        AT.OPRIMkind (map convertGlobalType instances)
      | T.OCONSTkind tyList =>
        raise Control.Bug "convertGlobalRecKind: OVERLOADED"

  fun convertLocalType ty =
      case ReduceTy.reduceTy ty of
        T.SINGLETONty sty =>
        AT.SINGLETONty (convertLocalSingletonTy sty)
      | T.ERRORty => AT.ERRORty
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
             fieldTypes = LabelEnv.map convertLocalType flty,
             annotation = ref {labels = AT.LE_UNKNOWN,
                               boxed = false,
                               align = false}
            }
      | T.CONSTRUCTty {tyCon, args} =>
        AT.CONty
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

  and convertSingleValueType ty =
      let 
        val newTy = convertLocalType ty
        val _ = singleValueType newTy
      in
        newTy
      end

  and convertLocalSingletonTy ty =
      case ty of
        T.INSTCODEty {oprimId, path, keyTyList, match, instMap} =>
        AT.INSTCODEty
          {
           oprimId = oprimId,
           path = path,
           keyTyList = map convertLocalType keyTyList
          }
      | T.INDEXty (label, ty) =>
        AT.INDEXty (label, convertLocalType ty)
      | T.TAGty ty =>
        AT.TAGty (convertLocalType ty)
      | T.SIZEty ty =>
        AT.SIZEty (convertLocalType ty)

  and convertLocalBtvKind
        (id, btvKind as {tvarKind, eqKind} : Types.btvKind) =
      (
(*
       case BoundTypeVarID.Map.find(!btvInfo, id) of
         SOME newBtvKind => newBtvKind
       | NONE =>
*)
         let
           val newTvarKind = convertLocalRecKind tvarKind
           val newBtvKind = 
               {
                id = id,
                eqKind = eqKind,
                tvarKind = newTvarKind
               }
         in
           (
(*
            btvInfo := (BoundTypeVarID.Map.insert(!btvInfo,id,newBtvKind));
*)
            newBtvKind
           )
         end
      )

  and convertLocalBtvEnv (btvEnv : Types.btvEnv) =
      BoundTypeVarID.Map.mapi convertLocalBtvKind btvEnv

  and convertLocalRecKind tvarKind =
      case tvarKind of
        T.UNIV => AT.UNIV
      | T.REC flty => AT.REC (LabelEnv.map convertLocalType flty)
      | T.OPRIMkind {instances, operators} =>
        AT.OPRIMkind (map convertLocalType instances)
      | T.OCONSTkind tyList =>
        raise Control.Bug "convertLocalRecKind: OVERLOADED"

  datatype tvState =
      SUBSTITUTED of BoundTypeVarID.id
    | TVAR of AT.btvKind

  fun unify btvSubst (ty1,ty2) =
      case (ty1,ty2) of
        (AT.SINGLETONty sty1, AT.SINGLETONty sty2) =>
        unifySingletonTy btvSubst (sty1, sty2)
      | (AT.ERRORty, AT.ERRORty) => ()
      | (AT.DUMMYty _, AT.DUMMYty _) => ()
      | (AT.BOUNDVARty tid1, AT.BOUNDVARty tid2) =>
        (
          case (BoundTypeVarID.Map.find (#1 btvSubst, tid1),
                BoundTypeVarID.Map.find (#2 btvSubst, tid2)) of
            (SOME (ref (SUBSTITUTED id1)), SOME (ref (SUBSTITUTED id2))) =>
            if BoundTypeVarID.eq (id1, id2) then () else raise Unify
          | (SOME (r1 as ref (TVAR kind1)), SOME (r2 as ref (TVAR kind2))) =>
            (unifyBtvKind btvSubst (kind1, kind2);
             r1 := SUBSTITUTED tid1; r2 := SUBSTITUTED tid1)
          | (NONE, NONE) =>
            if BoundTypeVarID.eq (tid1, tid2) then () else raise Unify
          | (t1, t2) =>
            let
              val s1 = Control.prettyPrint (AT.format_ty ty1)
              val s2 = Control.prettyPrint (AT.format_ty ty2)
            in
              raise Unify 
              before print ("Unification fails (2) " ^ s1 ^ "," ^ s2)
            end
        )
      | (AT.FUNMty {argTyList=argTyList1,
                    bodyTy=bodyTy1,
                    annotation = annotation1,...},
         AT.FUNMty {argTyList=argTyList2,
                    bodyTy=bodyTy2,
                    annotation = annotation2,...}
        ) =>
        (
         ListPair.app (unify btvSubst) (argTyList1,argTyList2);
         unify btvSubst (bodyTy1,bodyTy2);
         functionEquivalence (annotation1,annotation2)
        )
      | (AT.RECORDty {fieldTypes = fieldTypes1, annotation = annotation1},
         AT.RECORDty {fieldTypes = fieldTypes2, annotation = annotation2}
        ) =>
        (
         ListPair.app (unify btvSubst) (LabelEnv.listItems fieldTypes1,
                                        LabelEnv.listItems fieldTypes2);
         recordEquivalence (annotation1,annotation2)
        )
      | (AT.CONty {tyCon=tyCon1, args = args1},
         AT.CONty {tyCon=tyCon2, args = args2}) => 
        ListPair.app (unify btvSubst) (args1,args2)
      | (AT.POLYty {boundtvars = boundtvars1, body=body1},
         AT.POLYty {boundtvars = boundtvars2, body=body2}) => 
        let
          val toBtvSubst = BoundTypeVarID.Map.map (fn kind => ref (TVAR kind))
          val btv1 = toBtvSubst boundtvars1
          val btv2 = toBtvSubst boundtvars2
          val btvSubst =
              (BoundTypeVarID.Map.unionWith #2 (#1 btvSubst, btv1),
               BoundTypeVarID.Map.unionWith #2 (#2 btvSubst, btv2))
        in
          unify btvSubst (body1, body2)
        end
      | _ => 
          let
            val s1 = Control.prettyPrint (AT.format_ty ty1)
            val s2 = Control.prettyPrint (AT.format_ty ty2)
          in
            raise Unify 
            before 
            (print "Unification fails (3)\n";
             print s1;
             print "\n";
             print s2;
             print "\n"
            )
          end

  and unifySingletonTy btvSubst (ty1,ty2) =
      case (ty1,ty2) of
        (AT.INSTCODEty {oprimId=id1, path=_, keyTyList=tys1},
         AT.INSTCODEty {oprimId=id2, path=_, keyTyList=tys2}) =>
        (if OPrimID.eq (id1, id2) then () else raise Unify;
         ListPair.appEq (unify btvSubst) (tys1, tys2)
         handle ListPair.UnequalLengths => raise Unify)
      | (AT.INDEXty (l1, ty1), AT.INDEXty (l2, ty2)) =>
        (if l1 = l2 then () else raise Unify;
         unify btvSubst (ty1, ty2))
      | (AT.SIZEty ty1, AT.SIZEty ty2) =>
        unify btvSubst (ty1, ty2)
      | (AT.TAGty ty1, AT.TAGty ty2) =>
        unify btvSubst (ty1, ty2)
      | (AT.RECORDSIZEty ty1, AT.RECORDSIZEty ty2) =>
        unify btvSubst (ty1, ty2)
      | (AT.RECORDBITMAPty (i1,ty1), AT.RECORDBITMAPty (i2,ty2)) =>
        (if i1 = i2 then () else raise Unify;
         unify btvSubst (ty1, ty2))
      | (AT.INSTCODEty _, _) => raise Unify
      | (AT.INDEXty _, _) => raise Unify
      | (AT.SIZEty _, _) => raise Unify
      | (AT.TAGty _, _) => raise Unify
      | (AT.RECORDSIZEty _, _) => raise Unify
      | (AT.RECORDBITMAPty _, _) => raise Unify

  and unifyRecKind btvSubst (tvarKind1 : AT.tvarKind,
                             tvarKind2 : AT.tvarKind) =
      case (tvarKind1, tvarKind2) 
       of (AT.UNIV, AT.UNIV) => ()
        | (AT.REC flty1, AT.REC flty2) => 
          ListPair.app (unify btvSubst)
                       (LabelEnv.listItems flty1, LabelEnv.listItems flty2)
        | (AT.OPRIMkind I1,
           AT.OPRIMkind I2) => ()
        | _ =>
          raise
            Control.Bug
              "inconsistent reckind to unifyRecKind\
              \ (staticanalysis/main/SAConstraint.sml)"

  and unifyBtvKind btvSubst (btvKind1 : AT.btvKind, btvKind2 : AT.btvKind) =
      unifyRecKind btvSubst (#tvarKind btvKind1, #tvarKind btvKind2)

  val unify =
      fn tys => unify (BoundTypeVarID.Map.empty, BoundTypeVarID.Map.empty) tys

(*
  (* is a polymorphic type is instanciated with a list of instance types,
   * we may need  to perform unification if some instance type refer to
   * the same type
   * E.g. 
   *    polymorphic type :          \forall{t1#{a:t2},t2}.\sigma 
   *    instance argument types :   {{a:\tau1,b:int},\tau2}
   * we need to unify the conversion of \tau1 and \tau2
   *)

  fun addInstances (btvEnv : AT.btvEnv, tyList) =
      let
        val instanceMap =
            ref (BoundTypeVarID.Map.empty : AT.ty BoundTypeVarID.Map.map)
        fun instanceUnify (generalTy,instanceTy) =
            case (generalTy,instanceTy) of
              (AT.ERRORty, AT.ERRORty) => ()
            | (AT.DUMMYty _, AT.DUMMYty _) => ()
            | (AT.BOUNDVARty tid1, _) =>
              (
               case BoundTypeVarID.Map.find(btvEnv,tid1) of
                 SOME {tvarKind, ...} => 
                 (
                  case BoundTypeVarID.Map.find(!instanceMap, tid1) of 
                    SOME ty => unify(ty,instanceTy)
                  | _ => instanceMap := BoundTypeVarID.Map.insert(!instanceMap,
                                                                  tid1,
                                                                  instanceTy);
                  case tvarKind of
                    AT.REC flty1 =>
                    let
                      val flty2 =
                          case instanceTy of
                            AT.RECORDty {fieldTypes, ...} => fieldTypes
                          | AT.BOUNDVARty tid2 =>
                            (
                             case BoundTypeVarID.Map.find(!btvInfo, tid2) of
                               SOME {tvarKind = AT.REC fieldTypes,...} =>
                               fieldTypes
                             | _ =>
                               (print "outr btvenv\n";
                                printBtvEnv (!btvInfo);
                                print "instTylist\n";
                                map printTy tyList;
                                print "btvEnv\n";
                                printBtvEnv btvEnv;
                                print "instTy\n";
                                printTy instanceTy;
                                raise Control.Bug "invalid instance"
                               )
                            )
                          | _ => 
                            let
                              val s1 = Control.prettyPrint
                                         (AT.format_ty generalTy)
                              val s2 = Control.prettyPrint
                                         (AT.format_ty instanceTy)
                            in
                              raise
                                Control.Bug
                                  ("invalid instance:" ^ s1 ^ "," ^ s2)
                            end
                    in
                      instanceUnifyFieldTypes (flty1,flty2)
                    end
                  | _ => ()
                 )
               | _ => ()
              )
              
            | (AT.FUNMty {argTyList=argTyList1,
                          bodyTy=bodyTy1, annotation = annotation1,...},
               AT.FUNMty {argTyList=argTyList2,
                          bodyTy=bodyTy2, annotation = annotation2,...}
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
               ListPair.app
                 instanceUnify
                 (SEnv.listItems fieldTypes1, SEnv.listItems fieldTypes2);
               recordEquivalence (annotation1,annotation2)
              )
            | (AT.CONty {args = args1,...},AT.CONty {args = args2,...}) =>
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
             case BoundTypeVarID.Map.find(!btvInfo, tid) of
               SOME {instancesRef,...} => instancesRef := ty::(!instancesRef)
             | _ => () (*global type variables always have generic
                                               representation *)
            )        
      in
        ListPair.app addInstance (BoundTypeVarID.Map.listKeys btvEnv, tyList)
      end 
*)

  fun solveAnnotation () = 
      let
        val flag = ref true
        fun labelsDiff (AT.LE_GENERIC, AT.LE_GENERIC) = false
          | labelsDiff (AT.LE_UNKNOWN, AT.LE_UNKNOWN) = false
          | labelsDiff (AT.LE_LABELS S1, AT.LE_LABELS S2) =
            not (AnnotationLabelID.Set.equal(S1,S2))
          | labelsDiff _ = true

        fun unifyLabels (labels1,labels2) =
            case (labels1,labels2) of
              (AT.LE_GENERIC,_) => AT.LE_GENERIC
            | (_,AT.LE_GENERIC) => AT.LE_GENERIC
            | (AT.LE_UNKNOWN,_) => labels2
            | (_,AT.LE_UNKNOWN) => labels1
            | (AT.LE_LABELS lset1,AT.LE_LABELS lset2) => 
              AT.LE_LABELS (AnnotationLabelID.Set.union(lset1,lset2))
                    
        fun loop () =
            if !flag 
            then
              (
(*               print "aaaaa\n"; *)
               flag := false;
               List.app
                 (fn (RECORD_EQUIV
                        (ann1
                           as
                           ref {labels=labels1, boxed=boxed1, align=align1},
                         ann2
                           as
                           ref {labels=labels2, boxed=boxed2, align=align2}))
                     =>
                       let
                         val ann = 
                             {
                              labels = unifyLabels (labels1, labels2), 
                              boxed = boxed1 orelse boxed2, 
                              align = align1 orelse align2
                             }
                         val _ = 
                             if labelsDiff(labels1,labels2)
                                orelse (boxed1 <> boxed2)
                                orelse (align1 <> align2) 
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
                             if labelsDiff(labels1,labels2)
                                orelse (boxed1 <> boxed2)
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
(*
       btvInfo := (BoundTypeVarID.Map.empty : AT.btvEnv);
*)
       genericTyVars := BoundTypeVarID.Set.empty
      )

end
