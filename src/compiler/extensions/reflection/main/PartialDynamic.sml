(**
 * @copyright (c) 2018, Tohoku University.
 * @author Atsushi Ohori
 *)
structure PartialDynamic =
struct

  exception RuntimeTypeError

  structure RTy = ReifiedTy
  structure RTm = ReifiedTerm
  (* structure RyU = ReifyUtils *)
  (* structure RTU = ReifiedUtils *)
  structure RTML = ReifiedTermToML
  fun printTy ty = print (ReifiedTy.reifiedTyToString ty)
  fun printTerm ty = print (ReifiedTerm.reifiedTermToString ty)

  fun matchTy (ty1, ty2) = 
      case (ty1, ty2) of
        (RTy.RECORDty fl1, RTy.RECORDty fl2) => 
        let
          exception Fail
        in
          (RecordLabel.Map.appi
             (fn (label, ty2) =>
                 case RecordLabel.Map.find(fl1, label) of
                   SOME ty1 => if matchTy (ty1, ty2) then ()
                               else raise Fail
                 | NONE => raise Fail
             )
             fl2;
           true)
          handle Fail => false
        end
      | (RTy.LISTty elemTy1, RTy.LISTty elemTy2) => matchTy (elemTy1, elemTy2)
      | (RTy.DYNAMICty ty1, RTy.DYNAMICty ty2) => matchTy (ty1,ty2)
      | (_, RTy.DYNAMICty ty2) => matchTy (ty1,ty2)
      | (_, RTy.BOXEDty) => RTML.isBoxed ty1
      | (_, RTy.VOIDty) => true
      | _ => RTy.reifiedTyEq (ty1,ty2)

  fun subsumeTy (ty1, ty2) =
      case (ty1, ty2) of
        (RTy.RECORDty fl1, RTy.RECORDty fl2) =>
        let
          exception Fail
        in
          (RecordLabel.Map.mergeWith 
             (fn (SOME ty1, SOME ty2) => (if subsumeTy (ty1, ty2) then ()
                                          else raise Fail; NONE)
               | (NONE, NONE) => NONE
               | _ => (raise Fail; NONE)
             )
             (fl1, fl2);
           true)
          handle Fail => false
        end
      | (RTy.LISTty elemTy1, RTy.LISTty elemTy2) => subsumeTy (elemTy1, elemTy2)
      | (RTy.FUNMty([domTy1], ranty1), RTy.FUNMty([domTy2], ranty2)) => 
        subsumeTy (domTy1, domTy2) andalso subsumeTy (ranty1, ranty2) 
      | (RTy.DYNAMICty ty1, RTy.DYNAMICty ty2) => subsumeTy (ty1,ty2)
      | (_, RTy.DYNAMICty ty2) => matchTy (ty1,ty2)
      | _ => RTy.reifiedTyEq (ty1,ty2)

  fun glbTy (ty1, ty2) = 
      if RTy.reifiedTyEq (ty1,ty2) then ty1
      else
        case (ty1, ty2) of
          (_, RTy.BOTTOMty) => RTy.BOTTOMty
        | (RTy.BOTTOMty, _) => RTy.BOTTOMty
        | (RTy.OPTIONty argTy1, RTy.OPTIONty argTy2) => RTy.OPTIONty (glbTy (argTy1, argTy2))
        | (RTy.RECORDty fl1, RTy.RECORDty fl2) => RTy.RECORDty (glbFieldTys (fl1, fl2))
        | (RTy.LISTty elemTy1, RTy.LISTty elemTy2) => RTy.LISTty (glbTy (elemTy1, elemTy2))
        | _ => RTy.BOTTOMty

  and glbFieldTys (fl1, fl2) =
      RecordLabel.Map.mergeWith 
      (fn (NONE, _) => NONE
        | (_, NONE) => NONE
        | (SOME ty1, SOME ty2) => SOME (glbTy (ty1, ty2)))
      (fl1, fl2)

  fun lubTy (ty1, ty2) = 
      if RTy.reifiedTyEq (ty1,ty2) then ty1
      else 
        case (ty1, ty2) of
          (_, RTy.BOTTOMty) => ty1
        | (RTy.BOTTOMty, _) => ty2
        | (RTy.OPTIONty argTy1, RTy.OPTIONty argTy2) => RTy.OPTIONty (lubTy (argTy1, argTy2))
        | (RTy.RECORDty fl1, RTy.RECORDty fl2) => RTy.RECORDty (lubFieldTys (fl1, fl2))
        | (RTy.LISTty elemTy1, RTy.LISTty elemTy2) => RTy.LISTty (lubTy (elemTy1, elemTy2))
        | _ => RTy.VOIDty

  and lubFieldTys (fl1, fl2) =
      RecordLabel.Map.mergeWith 
      (fn (NONE, x as SOME _) => x
        | (x as SOME _, NONE) => x
        | (SOME ty1, SOME ty2) => SOME (lubTy (ty1, ty2))
        | (NONE, NONE) => NONE)
      (fl1, fl2)

  fun glbTyList nil = RTy.VOIDty
    | glbTyList (ty::tyList) = List.foldl (fn (ty, res) => glbTy (ty, res)) ty tyList

  fun inferTy reifiedTerm =
    case reifiedTerm of
      RTm.ARRAY (elemTy, boxed) => RTy.ARRAYty elemTy
    | RTm.ARRAY_PRINT _ => 
      (print  (RTm.reifiedTermToString reifiedTerm ^ "\n");
      raise Bug.Bug "ARRAY_PRINT to inferTy")
    | RTm.BOOL bool => RTy.BOOLty
    | RTm.BOXED _ => RTy.BOXEDty
    | RTm.BOUNDVAR => RTy.VOIDty
    | RTm.BUILTIN => RTy.VOIDty
    | RTm.CHAR char => RTy.CHARty
    | RTm.CODEPTR word64 => RTy.CODEPTRty
    | RTm.DATATYPE (string, reifiedTermOption, ty) => ty
    | RTm.DYNAMIC (elemTy, boxed) => RTy.DYNAMICty elemTy
    | RTm.EXN _ => RTy.EXNty
    | RTm.EXNTAG => RTy.EXNTAGty
    | RTm.FUN {closure:boxed, ty:ReifiedTy.reifiedTy} => ty
    | RTm.IENVMAP _ => raise Bug.Bug "IENVMAP to inferTy"
    | RTm.INT32 int => RTy.INT32ty
    | RTm.INT16 int16  => RTy.INT16ty
    | RTm.INT64 int64 => RTy.INT64ty
    | RTm.INT8 int8  => RTy.INT8ty
    | RTm.INTERNAL  => RTy.INTERNALty
    | RTm.INTINF IntInf => RTy.INTINFty
    | RTm.LIST reifiedTremList => RTy.LISTty (glbTyList (map inferTy reifiedTremList))
    | RTm.NULL => RTy.BOTTOMty
    | RTm.NULL_WITHTy ty => ty
    | RTm.OPAQUE => RTy.VOIDty
    | RTm.OPTION (reifiedTermOption, ty) => RTy.OPTIONty ty
    | RTm.PTR word64 => RTy.PTRty RTy.WORD64ty
    | RTm.REAL64 real => RTy.REAL64ty
    | RTm.REAL32 real32 => RTy.REAL32ty
    | RTm.RECORD fields => RTy.RECORDty (RecordLabel.Map.map inferTy fields)
    | RTm.RECORDLABEL l => RTy.RECORDLABELty
    | RTm.RECORDLABELMAP map => raise Bug.Bug "RECORDLABELMAP to inferTy"
    | RTm.REF (elemTy, boxed) => RTy.REFty elemTy
    | RTm.REF_PRINT _ => raise Bug.Bug "REF_PRINT to inferTy"
    | RTm.SENVMAP _ => raise Bug.Bug "SENVMAP to inferTy"
    | RTm.STRING string => RTy.STRINGty
    | RTm.VOID => RTy.VOIDty
    | RTm.VOID_WITHTy ty => ty
    | RTm.UNIT => RTy.UNITty
    | RTm.UNPRINTABLE => RTy.VOIDty
    | RTm.ELLIPSIS => raise Bug.Bug "ELLIPSIS to inferTy"
    | RTm.VECTOR (elemTy, boxed) => RTy.VECTORty elemTy
    | RTm.VECTOR_PRINT _ => raise Bug.Bug "VECTOR_PRINT to inferTy"
    | RTm.WORD32 word => RTy.WORD32ty
    | RTm.WORD16 word16 => RTy.WORD16ty
    | RTm.WORD64 word64 => RTy.WORD64ty
    | RTm.WORD8 word8 => RTy.WORD8ty

  fun projectTerm (term, ty) =
      case (term, ty) of
        (RTm.RECORD fields, RTy.RECORDty tyFields) =>
        RTm.RECORD
          (RecordLabel.Map.mergeWith
             (fn (SOME term, SOME ty) => SOME (projectTerm (term, ty))
               | (SOME term, NONE) => NONE
               | (NONE, SOME _) =>  raise Bug.Bug "projectTerm impossible (1)"
               | (NONE, NONE) =>  NONE)
             (fields, tyFields)
          )
        | (RTm.RECORD fields, _) => raise RuntimeTypeError
        | (RTm.LIST termList, RTy.LISTty elemTy) => 
          RTm.LIST (map (fn term => projectTerm(term, elemTy)) termList)
        | (RTm.LIST termList, _) => raise RuntimeTypeError
        | (RTm.NULL, _) => term
        | (_, RTy.VOIDty) => raise RuntimeTypeError
        | _ =>
          if subsumeTy (inferTy term, ty) then term
          else raise RuntimeTypeError

  fun coerceTermGeneric (dynamic, tyRep:ReifiedTy.tyRep) =
      let
        val reifiedTerm = RTm.toReifiedTerm dynamic
        val reifiedTy = inferTy reifiedTerm
        val {reifiedTy = coerceTy, conSetEnv} = ReifiedTy.getConstructTy tyRep
        val _ = if subsumeTy (reifiedTy, coerceTy) then ()
                else raise RuntimeTypeError
      in
        RTML.reifiedTermToMLWithTy 
          reifiedTerm
          {conSetEnv = conSetEnv, reifiedTy = coerceTy}
(*
        RTML.reifiedTermToMLWithTy 
          reifiedTerm
          {conSetEnv = conSetEnv, reifiedTy = reifiedTy}
*)
      end

  fun checkTermGeneric (dynamic, tyRep:ReifiedTy.tyRep) =
      let
        val reifiedTerm = RTm.toReifiedTerm dynamic
        val reifiedTy = inferTy reifiedTerm
        val {reifiedTy = coerceTy,...} = ReifiedTy.getConstructTy tyRep
      in
        subsumeTy (reifiedTy, coerceTy)
      end

  fun ('a#reify) viewDynamic (dynamic:'a RTm.dyn) = 
      let
        val reifiedTerm = RTm.toReifiedTerm dynamic
        val actualTy = inferTy reifiedTerm
        val targetTyRep = _reifyTy('a)
        val {reifiedTy=targetTy, conSetEnv} = ReifiedTy.getConstructTy targetTyRep
        val projectedTerm = projectTerm (reifiedTerm, targetTy)
        val projectedTermTy = inferTy projectedTerm
      in
        RTML.reifiedTermToMLWithTy 
          projectedTerm 
          {conSetEnv = conSetEnv, reifiedTy = projectedTermTy}
      end        

  fun viewTermGeneric (dynamic, tyRep:ReifiedTy.tyRep) =
      let
        val reifiedTerm = RTm.toReifiedTerm dynamic
        val reifiedTy = inferTy reifiedTerm
        val {conSetEnv, reifiedTy = viewTy} = ReifiedTy.getConstructTy tyRep
        val _ = if matchTy (reifiedTy, viewTy) then ()
                else raise Bug.Bug "viewTermGeneric matchTy fail"
        val projectedTerm = projectTerm (reifiedTerm, viewTy)
        val projectedTermTy = inferTy projectedTerm
      in
        RTML.reifiedTermToMLWithTy
          projectedTerm
          {conSetEnv = conSetEnv, reifiedTy = projectedTermTy}
      end

  type existInstMap =
      {conSetEnv : ReifiedTy.conSetEnv,
       instances : ReifiedTy.reifiedTy IEnv.map}

  fun dynamicExistInstance {conSetEnv, instances} id =
      case IEnv.find (instances, id) of
        NONE => raise Bug.Bug "dynamicExistInstance"
      | SOME ty =>
        {reify = {conSetEnv = conSetEnv, reifiedTy = ty},
         size = RTy.sizeOf ty,
         tag = ReifiedTermToML.tagToWord (ReifiedTermToML.constTag ty)}

  fun ('a, 'b) dynamicTypeCase
               (dynamic: 'a RTm.dyn) 
               (groupListTerm : (ReifiedTy.tyRep * (existInstMap -> 'a RTm.dyn -> 'b)) list)
    =
      let
        val reifiedTerm = RTm.toReifiedTerm dynamic
        val reifiedTy = inferTy reifiedTerm
        fun selectCase nil = raise RuntimeTypeError
          | selectCase ((tyRep, caseFn)::rest) = 
            let
              val {reifiedTy=coerceTy, conSetEnv} = ReifiedTy.getConstructTy tyRep
            in
(*
              if matchTy (reifiedTy, coerceTy) then caseFn
              else selectCase rest
*)
              case RTy.reifiedTyEq' (reifiedTy, coerceTy) of
                NONE => selectCase rest
              | SOME instances =>
                caseFn {conSetEnv = conSetEnv, instances = instances}
            end
        val caseFn = selectCase groupListTerm
      in
        caseFn dynamic
      end
      
  fun genNull ty =
      case ty of
        RTy.RECORDty tyFields => 
        RTm.RECORD (RecordLabel.Map.map genNull tyFields)
      | RTy.LISTty elemTy  => RTm.LIST [genNull elemTy]
      | _ => RTm.NULL_WITHTy ty

  fun genVoid ty =
      case ty of
        RTy.RECORDty tyFields => 
        RTm.RECORD (RecordLabel.Map.map genVoid tyFields)
      | RTy.LISTty elemTy  => RTm.LIST []
      | _ => RTm.VOID_WITHTy ty

  fun ('a#reify) null (tyRep:ReifiedTy.tyRep) = 
      let
        val targetTyRep as {reifiedTy=targetTy, ...} = ReifiedTy.getConstructTy tyRep
      in
        RTm.toDynamic  (genNull targetTy)
      end
  fun ('a#reify) void (tyRep:ReifiedTy.tyRep) = 
      let
        val targetTyRep as {reifiedTy=targetTy, ...} = ReifiedTy.getConstructTy tyRep
      in
        RTm.toDynamic  (genVoid targetTy)
      end
end
