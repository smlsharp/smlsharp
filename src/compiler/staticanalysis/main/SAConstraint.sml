(**
 * SAConstraint
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure SAConstraint : SACONSTRAINT = struct
  structure T = Types
  structure AT = AnnotatedTypes

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

  val ftvInfo = ref (IEnv.empty : AT.tvKind IEnv.map)

  fun btvEq (btvKind1 : AT.btvKind, btvKind2 : AT.btvKind) =
      case (btvKind1, btvKind2) of
        ({recKind = AT.UNIV,...}, {recKind = AT.UNIV,...}) => true
      | ({recKind = AT.REC flty1,...}, {recKind = AT.REC flty2,...}) => 
        (List.all
            (fn l => case SEnv.find(flty2,l) of SOME _ => true | _ => false)
            (SEnv.listKeys flty1)) andalso
        (List.all
            (fn l => case SEnv.find(flty1,l) of SOME _ => true | _ => false)
            (SEnv.listKeys flty2))
      | ({recKind = AT.OVERLOADED _,...}, {recKind = AT.OVERLOADED _,...}) => true
      | _ => false

             
  fun genericTyVar tid = genericTyVars := ISet.add(!genericTyVars, tid)

  fun recordEquivalence (annotationRef1,annotationRef2) = 
      constraintsRef := (RECORD_EQUIV(annotationRef1, annotationRef2)) :: (!constraintsRef)

  fun functionEquivalence (annotationRef1,annotationRef2) = 
      constraintsRef := (FUNCTION_EQUIV(annotationRef1, annotationRef2)) :: (!constraintsRef)

  fun globalType ty =
      case ty of
        AT.BOUNDVARty tid => genericTyVar tid
      | AT.TYVARty (ref {recKind, ...}) => 
        (case recKind of
           AT.UNIV => ()
         | AT.REC flty => SEnv.app globalType flty
         | AT.OVERLOADED tyList => List.app globalType tyList
        )
      | AT.FUNMty {argTyList, bodyTy, annotation} =>
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
      | AT.CONty {tyCon, args} => List.app globalType args
      | AT.POLYty {boundtvars, body} => 
        (
         IEnv.appi 
             (fn (tid,{recKind, representationRef,...}) => 
                 (
                  genericTyVar tid;
                  case recKind of
                    AT.UNIV => representationRef := AT.GENERIC_REP
                  | AT.REC flty =>
                    (
                     representationRef := AT.BOXED_REP;
                     SEnv.app globalType flty
                    )
                  | AT.OVERLOADED tyList =>
                    (
                     representationRef := AT.GENERIC_REP;
                     List.app globalType tyList
                    )
                 )
             )
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
      | T.TYVARty (ref (T.TVAR tvKind)) => convertGlobalFtvKind tvKind
      | T.BOUNDVARty tid => AT.BOUNDVARty tid
      | T.FUNMty (argTyList, bodyTy) =>
        AT.FUNMty
            {
             argTyList = map convertGlobalType argTyList,
             bodyTy = convertGlobalType bodyTy,
             annotation = ref {labels = AT.LE_GENERIC, boxed = true}
            }
      | T.RECORDty flty =>
        AT.RECORDty 
            {
             fieldTypes = SEnv.map convertGlobalType flty,
             annotation = ref {labels = AT.LE_GENERIC, boxed = true, align = true}
            }
      | T.CONty {tyCon, args} =>
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
      | T.BOXEDty => AT.BOXEDty
      | T.ATOMty => AT.ATOMty 
      | T.DOUBLEty => AT.DOUBLEty
      | T.ALIASty (_, realTy) => convertGlobalType realTy
      | T.ABSSPECty (_, realTy) => convertGlobalType realTy
      | _ => 
        let
          val s = Control.prettyPrint (Types.format_ty [] ty)
        in
          raise Control.Bug ("invalid type:" ^ s )
        end

  and convertGlobalBtvKind (id, btvKind as {index, recKind, eqKind} : Types.btvKind) =
      let
        val _ = genericTyVar id
        val newRecKind = convertGlobalRecKind recKind
        val representationRef =
            case newRecKind of
              AT.REC _ => ref AT.BOXED_REP
            | _ => ref AT.GENERIC_REP
        val newBtvKind = 
            {
             id = id,
             eqKind = eqKind,
             recKind = newRecKind,
             instancesRef = ref [],
             representationRef = representationRef
            }
      in
        newBtvKind
      end

  and convertGlobalBtvEnv (btvEnv : Types.btvEnv) =
      IEnv.mapi convertGlobalBtvKind btvEnv

  and convertGlobalRecKind recKind =
      case recKind of
        T.UNIV => AT.UNIV
      | T.REC flty => AT.REC (SEnv.map convertGlobalType flty)
      | T.OVERLOADED tyList => AT.OVERLOADED (map convertGlobalType tyList)

  and convertGlobalFtvKind ({id, eqKind, recKind, tyvarName,...} : T.tvKind) =
      case IEnv.find(!ftvInfo, id) of
        SOME tvKind => AT.TYVARty (ref tvKind)
      | NONE =>
        let
          val tvKind =
              {
               id = id,
               eqKind = eqKind,
               recKind = convertGlobalRecKind recKind,
               tyvarName = tyvarName
              }
          val _ = ftvInfo:= IEnv.insert(!ftvInfo, id, tvKind)
        in
          AT.TYVARty (ref tvKind)
        end

  fun convertLocalType ty =
      case ty of
        T.ERRORty => AT.ERRORty
      | T.DUMMYty i => AT.DUMMYty i                  
      | T.TYVARty (ref (T.SUBSTITUTED ty)) => convertLocalType ty
      | T.TYVARty (ref (T.TVAR tvKind)) => convertLocalFtvKind tvKind
      | T.BOUNDVARty tid => AT.BOUNDVARty tid
      | T.FUNMty (argTyList, bodyTy) =>
        AT.FUNMty
            {
             argTyList = map convertLocalType argTyList,
             bodyTy = convertLocalType bodyTy,
             annotation = ref {labels = AT.LE_UNKNOWN, boxed = false}
            }
      | T.RECORDty flty =>
        AT.RECORDty 
            {
             fieldTypes = SEnv.map convertLocalType flty,
             annotation = ref {labels = AT.LE_UNKNOWN, boxed = false, align = false}
            }
      | T.CONty {tyCon, args} =>
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
      | T.BOXEDty => AT.BOXEDty
      | T.ATOMty => AT.ATOMty 
      | T.DOUBLEty => AT.DOUBLEty
      | T.ALIASty (_, realTy) => convertLocalType realTy
      | T.ABSSPECty (_, realTy) => convertLocalType realTy
      | _ => raise Control.Bug "invalid type"

  and convertSingleValueType ty =
      let 
        val newTy = convertLocalType ty
        val _ = singleValueType newTy
      in
        newTy
      end

  and convertLocalBtvKind (id, btvKind as {index, recKind, eqKind} : Types.btvKind) =
      (
       case IEnv.find(!btvInfo, id) of
         SOME newBtvKind => newBtvKind
       | NONE =>
         let
           val newRecKind = convertLocalRecKind recKind
           val representationRef =
               case newRecKind of
                 AT.REC _ => ref AT.BOXED_REP
               | _ => ref AT.UNKNOWN_REP
           val newBtvKind = 
               {
                id = id,
                eqKind = eqKind,
                recKind = newRecKind,
                instancesRef = ref [],
                representationRef = representationRef
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

  and convertLocalRecKind recKind =
      case recKind of
        T.UNIV => AT.UNIV
      | T.REC flty => AT.REC (SEnv.map convertLocalType flty)
      | T.OVERLOADED tyList => AT.OVERLOADED (map convertSingleValueType tyList)

  and convertLocalFtvKind ({id, eqKind, recKind, tyvarName,...} : T.tvKind) =
      case IEnv.find(!ftvInfo, id) of
        SOME tvKind => AT.TYVARty (ref tvKind)
      | NONE =>
        let
          val tvKind =
              {
               id = id,
               eqKind = eqKind,
               recKind = convertLocalRecKind recKind, (*temporary*)
               tyvarName = tyvarName
              }
          val _ = ftvInfo:= IEnv.insert(!ftvInfo, id, tvKind)
        in
          AT.TYVARty (ref tvKind)
        end

  fun unify (ty1,ty2) =
      case (ty1,ty2) of
        (AT.ERRORty, AT.ERRORty) => ()
      | (AT.DUMMYty _, AT.DUMMYty _) => ()
      | (AT.TYVARty (ref {id = id1,...}), AT.TYVARty (ref {id = id2,...})) => 
        if id1 = id2 then () else raise Control.Bug "Unification fails"
      | (AT.BOUNDVARty tid1, AT.BOUNDVARty tid2) =>
        if tid1 = tid2 
        then () 
        else
          let
            val s1 = Control.prettyPrint (AT.format_ty ty1)
            val s2 = Control.prettyPrint (AT.format_ty ty2)
          in
            raise Control.Bug ("Unification fails " ^ s1 ^ "," ^ s2)
          end
      | (AT.FUNMty {argTyList=argTyList1, bodyTy=bodyTy1, annotation = annotation1},
         AT.FUNMty {argTyList=argTyList2, bodyTy=bodyTy2, annotation = annotation2}
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
      | (AT.CONty {tyCon=tyCon1, args = args1},AT.CONty {tyCon=tyCon2, args = args2}) => 
        ListPair.app unify (args1,args2)
      | (AT.POLYty {boundtvars = boundtvars1, body=body1}, AT.POLYty {boundtvars = boundtvars2, body=body2}) => 
        (
         ListPair.app unifyBtvKind (IEnv.listItems boundtvars1, IEnv.listItems boundtvars2);
         unify(body1,body2) 
        )
      | (AT.BOXEDty,AT.BOXEDty) => ()
      | (AT.ATOMty,AT.ATOMty) => ()
      | (AT.DOUBLEty,AT.DOUBLEty) => ()
      | _ => raise Control.Bug "unification fails"

  and unifyRecKind (recKind1 : AT.recKind, recKind2 : AT.recKind) =
      case (recKind1, recKind2) 
       of (AT.UNIV, AT.UNIV) => ()
        | (AT.REC flty1, AT.REC flty2) => 
          ListPair.app unify (SEnv.listItems flty1, SEnv.listItems flty2)
        | (AT.OVERLOADED tyList1, AT.OVERLOADED tyList2) => 
          ListPair.app unify (tyList1,tyList2)

  and unifyBtvKind (btvKind1 : AT.btvKind, btvKind2 : AT.btvKind) =
      (
       unifyRecKind (#recKind btvKind1, #recKind btvKind2);
       case !(#representationRef btvKind1) of
         AT.UNKNOWN_REP => (#representationRef btvKind1) := !(#representationRef btvKind2)
       | _ => (#representationRef btvKind2) := !(#representationRef btvKind1)
      )
          

  (* is a polymorphic type is instanciated with a list of instance types, we may need 
   * to perform unification if some instance type refer to the same type
   * E.g. 
   *    polymorphic type :          \forall{t1#{a:t2},t2}.\sigma 
   *    instance argument types :   {{a:\tau1,b:int},\tau1}
   * we need to unify the conversion of \tau1 in the two above place
   *)

  fun addInstances (btvEnv : AT.btvEnv, tyList) =
      let
        val instanceMap = ref (IEnv.empty : AT.ty IEnv.map)
        fun instanceUnify (generalTy,instanceTy) =
            case (generalTy,instanceTy) of
              (AT.ERRORty, AT.ERRORty) => ()
            | (AT.DUMMYty _, AT.DUMMYty _) => ()
            | (AT.TYVARty _, AT.TYVARty _) => ()
            | (AT.BOUNDVARty tid1, _) =>
              (
               case IEnv.find(btvEnv,tid1) of
                 SOME {recKind, ...} => 
                 (
                  case IEnv.find(!instanceMap, tid1) of 
                    SOME ty => unify(ty,instanceTy)
                  | _ => instanceMap := IEnv.insert(!instanceMap, tid1, instanceTy);
                  case recKind of
                    AT.REC flty1 =>
                    let
                      val flty2 =
                          case instanceTy of
                            AT.RECORDty {fieldTypes, ...} => fieldTypes
                          | AT.BOUNDVARty tid2 =>
                            (
                             case IEnv.find(!btvInfo, tid2) of
                               SOME {recKind = AT.REC fieldTypes,...} => fieldTypes
                             | _ => raise Control.Bug "invalid instance"
                            )
                          | AT.TYVARty (ref {recKind = AT.REC fieldTypes,...}) => fieldTypes
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
              
            | (AT.FUNMty {argTyList=argTyList1, bodyTy=bodyTy1, annotation = annotation1},
               AT.FUNMty {argTyList=argTyList2, bodyTy=bodyTy2, annotation = annotation2}
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
            | (AT.CONty {tyCon=tyCon1, args = args1},AT.CONty {tyCon=tyCon2, args = args2}) => 
              ListPair.app instanceUnify (args1, args2)
            | (AT.POLYty {body=body1,...}, AT.POLYty {body=body2,...}) =>
              raise Control.Bug "never unifying second order type"
            | (AT.BOXEDty,AT.BOXEDty) => ()
            | (AT.ATOMty,AT.ATOMty) => ()
            | (AT.DOUBLEty,AT.DOUBLEty) => ()
            | _ => raise Control.Bug "instance unification fails"

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


  fun antiUnify (rep1,rep2) =
      case (rep1,rep2) of
        (AT.UNKNOWN_REP, _) => rep2
      | (_, AT.UNKNOWN_REP) => rep1
      | (AT.GENERIC_REP, _) => AT.GENERIC_REP
      | (_,AT.GENERIC_REP) => AT.GENERIC_REP
      | (AT.ATOM_REP,AT.ATOM_REP) => AT.ATOM_REP
      | (AT.ATOM_REP,AT.BOXED_REP) => AT.SINGLE_REP
      | (AT.ATOM_REP,AT.DOUBLE_REP) => AT.UNBOXED_REP
      | (AT.ATOM_REP,AT.SINGLE_REP) => AT.SINGLE_REP
      | (AT.ATOM_REP,AT.UNBOXED_REP) => AT.UNBOXED_REP

      | (AT.BOXED_REP,AT.ATOM_REP) => AT.SINGLE_REP
      | (AT.BOXED_REP,AT.BOXED_REP) => AT.BOXED_REP
      | (AT.BOXED_REP,AT.DOUBLE_REP) => AT.GENERIC_REP
      | (AT.BOXED_REP,AT.SINGLE_REP) => AT.SINGLE_REP
      | (AT.BOXED_REP,AT.UNBOXED_REP) => AT.GENERIC_REP

      | (AT.DOUBLE_REP,AT.ATOM_REP) => AT.UNBOXED_REP
      | (AT.DOUBLE_REP,AT.BOXED_REP) => AT.GENERIC_REP
      | (AT.DOUBLE_REP,AT.DOUBLE_REP) => AT.DOUBLE_REP
      | (AT.DOUBLE_REP,AT.SINGLE_REP) => AT.GENERIC_REP
      | (AT.DOUBLE_REP,AT.UNBOXED_REP) => AT.UNBOXED_REP

      | (AT.SINGLE_REP,AT.ATOM_REP) => AT.SINGLE_REP
      | (AT.SINGLE_REP,AT.BOXED_REP) => AT.SINGLE_REP
      | (AT.SINGLE_REP,AT.DOUBLE_REP) => AT.GENERIC_REP
      | (AT.SINGLE_REP,AT.SINGLE_REP) => AT.SINGLE_REP
      | (AT.SINGLE_REP,AT.UNBOXED_REP) => AT.GENERIC_REP

      | (AT.UNBOXED_REP,AT.ATOM_REP) => AT.UNBOXED_REP
      | (AT.UNBOXED_REP,AT.BOXED_REP) => AT.GENERIC_REP
      | (AT.UNBOXED_REP,AT.DOUBLE_REP) => AT.UNBOXED_REP
      | (AT.UNBOXED_REP,AT.SINGLE_REP) => AT.GENERIC_REP
      | (AT.UNBOXED_REP,AT.UNBOXED_REP) => AT.UNBOXED_REP

  fun repOf ty =
      case ty of
        AT.ERRORty => AT.ATOM_REP
      | AT.DUMMYty _ => AT.ATOM_REP
      | AT.TYVARty (ref {recKind = AT.REC _,...}) => AT.BOXED_REP
      | AT.TYVARty _ => AT.ATOM_REP
      | AT.BOUNDVARty tid =>
        (
         case IEnv.find(!btvInfo,tid) of 
           SOME btvKind => computeRep btvKind
         | NONE => raise Control.Bug "type variable not found"
        )
      | AT.FUNMty _ => AT.BOXED_REP
      | AT.RECORDty _ => AT.BOXED_REP
      | AT.CONty {tyCon as {boxedKind,...}, args} =>
        (
         case !boxedKind of
           T.ATOMty => AT.ATOM_REP
         | T.BOXEDty => AT.BOXED_REP
         | T.DOUBLEty => if !Control.enableUnboxedFloat then AT.DOUBLE_REP else AT.BOXED_REP
         | _ => AT.BOXED_REP
        )
      | AT.POLYty {boundtvars, body} =>
        (
         case body of
           AT.BOUNDVARty tid =>
           (
            case IEnv.find(boundtvars,tid) of
              SOME _ => AT.BOXED_REP
            | _ => repOf (AT.BOUNDVARty tid)
           )
         | _ => repOf body
        )
      | AT.ATOMty => AT.ATOM_REP
      | AT.BOXEDty => AT.BOXED_REP
      | AT.DOUBLEty => AT.DOUBLE_REP
      | _ => raise Control.Bug "invalid type"

  and computeRep ({instancesRef, representationRef, recKind,...} : AT.btvKind) =
      case !representationRef of
        AT.UNKNOWN_REP =>
        (
         case recKind of
           AT.REC _ => (representationRef := AT.BOXED_REP; AT.BOXED_REP)
         | _ =>
           if !Control.doRepresentationAnalysis
           then
             case !instancesRef of
               [] => AT.UNKNOWN_REP
             | L =>
               let
                 val rep =
                     foldl
                         (fn (ty,rep) => antiUnify(repOf ty,rep))
                         AT.UNKNOWN_REP
                         L
               in
                 (representationRef := rep;rep)
               end
           else (representationRef := AT.GENERIC_REP; AT.GENERIC_REP)
        )
      | rep => rep

  fun solveRepresentation () =
      (
(*        ISet.app  *)
(*            (fn tid => *)
(*                case IEnv.find(!btvInfo, tid) of *)
(*                  SOME {recKind = AT.REC _, representationRef,...} =>  *)
(*                  representationRef  := AT.BOXED_REP *)
(*                | SOME {representationRef,...} => representationRef := AT.GENERIC_REP *)
(*                | _ => raise Control.Bug "type variable not found" *)
(*            ) *)
(*            (!genericTyVars); *)
       IEnv.app (fn btvKind => (computeRep btvKind; ())) (!btvInfo)
      )

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

  fun solve () = (solveRepresentation (); solveAnnotation ())

  fun initialize () =
      (
       constraintsRef := ([] : constraint list);
       btvInfo := (IEnv.empty : AT.btvEnv);
       ftvInfo := (IEnv.empty : AT.tvKind IEnv.map);
       genericTyVars := ISet.empty
      )

end
