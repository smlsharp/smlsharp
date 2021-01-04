(**
 * @copyright (c) 2020, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure DynamicExistInstance =
struct

  structure T = Types
  structure L = TypedLambda

  fun TLEXVAR var =
      (fn loc => L.TLEXVAR (var, loc), #ty var)

  fun TLAPPM (funExp, funTy) (argExp, argTy) =
      (fn loc => L.TLAPPM {funExp = funExp loc,
                           funTy = funTy,
                           argExpList = [argExp loc],
                           loc = loc},
       case TypesBasics.derefTy funTy of
         T.FUNMty (_, retTy) => retTy
       | _ => raise Bug.Bug "TLAPPM")

  fun TLSELECT label (recordExp, recordTy) =
      case TypesBasics.derefTy recordTy of
        T.RECORDty fieldTys =>
        (case RecordLabel.Map.find (fieldTys, label) of
           SOME resultTy =>
           (fn loc => L.TLSELECT {label = label,
                                  recordExp = recordExp loc,
                                  recordTy = recordTy,
                                  resultTy = resultTy,
                                  loc = loc},
            resultTy)
         | NONE => raise Bug.Bug "TLSELECT")
      | _ => raise Bug.Bug "TLSELECT"

  fun TLCAST (exp, expTy) targetTy =
      (fn loc => L.TLCAST {exp = exp loc,
                           expTy = expTy,
                           targetTy = targetTy,
                           cast = TypedLambda.TypeCast,
                           loc = loc},
       targetTy)

  fun Int n =
      (fn loc => L.TLINT (L.INT32 n, loc), BuiltinTypes.int32Ty)

  fun dynamicExistInstance loc existInstMap id =
      TLAPPM
        (TLAPPM
           (TLEXVAR (UserLevelPrimitive.REIFY_exInfo_dynamicExistInstance loc))
           (fn _ => existInstMap,
            T.CONSTRUCTty
              {tyCon = UserLevelPrimitive.REIFY_tyCon_existInstMap loc,
               args = []}))
        (Int id)

  (* ToDo: inefficient.
   * generated code calls dynamicExistInstance several times *)
  fun generateExtraArgs loc existInstMap extraTys =
      map
        (fn ty as T.SINGLETONty (T.REIFYty (T.EXISTty (id, _))) =>
            #1 (TLCAST
                  (TLSELECT
                     (RecordLabel.fromString "reify")
                     (dynamicExistInstance
                        loc existInstMap (ExistTyID.toInt id)))
                  ty)
               loc
          | ty as T.SINGLETONty (T.TAGty (T.EXISTty (id, _))) =>
            #1 (TLCAST
                  (TLSELECT
                     (RecordLabel.fromString "tag")
                     (dynamicExistInstance
                        loc existInstMap (ExistTyID.toInt id)))
                  ty)
               loc
          | ty as T.SINGLETONty (T.SIZEty (T.EXISTty (id, _))) =>
            #1 (TLCAST
                  (TLSELECT
                     (RecordLabel.fromString "size")
                     (dynamicExistInstance
                        loc existInstMap (ExistTyID.toInt id)))
                  ty)
               loc
          | _ =>
            raise Bug.Bug "DynamicExistInstance.generateExtraArgs")
        extraTys

end
