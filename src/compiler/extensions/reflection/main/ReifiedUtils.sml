structure ReifiedUtils =
struct
  structure RTy = ReifiedTy
  structure U = UserLevelPrimitive
        
  fun isBottomTy reifiedTy =
      case reifiedTy of
        RTy.CONSTRUCTty {id,...} => TypID.eq(id, #id (U.REIFY_tyCon_void()))
      | RTy.DATATYPEty {id,...} => TypID.eq(id, #id (U.REIFY_tyCon_void()))
      | RTy.OPAQUEty {id,...} => TypID.eq(id, #id (U.REIFY_tyCon_void()))
      | _ => false

  fun isPartialDynTy  (RTy.DYNAMICty elemTy) = true
    | isPartialDynTy _ = false

  fun partialDynElemTy (RTy.DYNAMICty elemTy) = SOME elemTy
    | partialDynElemTy _ = NONE

end
