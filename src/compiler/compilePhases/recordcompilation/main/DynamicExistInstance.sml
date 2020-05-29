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

  fun TLCAST (exp, expTy) targetTy =
      (fn loc => L.TLCAST {exp = exp loc,
                           expTy = expTy,
                           targetTy = targetTy,
                           cast = TypedLambda.TypeCast,
                           loc = loc},
       targetTy)

  fun Int n =
      (fn loc => L.TLCONSTANT (L.INT32 n, loc), BuiltinTypes.int32Ty)

  fun dynamicExistInstance loc existInstMap id =
      TLAPPM
        (TLAPPM
           (TLEXVAR (UserLevelPrimitive.REIFY_exInfo_dynamicExistInstance ()))
           (fn _ => existInstMap,
            T.CONSTRUCTty
              {tyCon = UserLevelPrimitive.REIFY_tyCon_existInstMap (),
               args = []}))
        (Int id)

  fun generateExtraArgs loc existInstMap extraTys =
      map
        (fn ty as T.SINGLETONty (T.REIFYty (T.EXISTty (id, _))) =>
            #1 (TLCAST
                  (dynamicExistInstance loc existInstMap (ExistTyID.toInt id))
                  ty)
               loc
          | _ =>
            raise Bug.Bug "DynamicExistInstance.generateInstance")
        extraTys

end
