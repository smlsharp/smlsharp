(**
 * @copyright (c) 2016, Tohoku University.
 * @author Atsushi Ohori
 *)
structure ReifiedTyData =
struct
  structure UP = UserLevelPrimitive
  structure BT = BuiltinTypes
  structure T = Types

  type ty = Types.ty
  type loc = Loc.loc

  val Int32Ty = T.CONSTRUCTty {tyCon = BT.int32TyCon, args = []}
  val Int64Ty = T.CONSTRUCTty {tyCon = BT.int64TyCon, args = []}
  val IntInfTy = T.CONSTRUCTty {tyCon = BT.intInfTyCon, args = []}
  val Word32Ty = T.CONSTRUCTty {tyCon = BT.word32TyCon, args = []}
  val Word64Ty = T.CONSTRUCTty {tyCon = BT.word64TyCon, args = []}
  val Word8Ty = T.CONSTRUCTty {tyCon = BT.word8TyCon, args = []}
  val CharTy = T.CONSTRUCTty {tyCon = BT.charTyCon, args = []}
  val StringTy = T.CONSTRUCTty {tyCon = BT.stringTyCon, args = []}
  val Real64Ty = T.CONSTRUCTty {tyCon = BT.real64TyCon, args = []}
  val Real32Ty = T.CONSTRUCTty {tyCon = BT.real32TyCon, args = []}
  val UnitTy = T.CONSTRUCTty {tyCon = BT.unitTyCon, args = []}
  val PtrTy = T.CONSTRUCTty {tyCon = BT.ptrTyCon, args = []}
  val CodeptrTy = T.CONSTRUCTty {tyCon = BT.codeptrTyCon, args = []}
  val ExnTy = T.CONSTRUCTty {tyCon = BT.exnTyCon, args = []}
  val BoolTy = T.CONSTRUCTty {tyCon = BT.boolTyCon, args = []}
  val BoxedTy = T.CONSTRUCTty {tyCon = BT.boxedTyCon, args = []}
  fun RefTy ty = T.CONSTRUCTty {tyCon = BT.refTyCon, args = [ty]}
  fun ListTy ty = T.CONSTRUCTty {tyCon = BT.listTyCon, args = [ty]}
  fun ArrayTy ty = T.CONSTRUCTty {tyCon = BT.arrayTyCon, args = [ty]}
  fun VectorTy ty = T.CONSTRUCTty {tyCon = BT.vectorTyCon, args = [ty]}
  fun OptionTy ty = T.CONSTRUCTty {tyCon = BT.optionTyCon, args = [ty]}
  fun TupleTy tyList = T.RECORDty (RecordLabel.tupleMap tyList)
  fun RecordTy stringTyList =
      T.RECORDty
        (foldr
          (fn ((s,v),map) =>
              RecordLabel.Map.insert(map, RecordLabel.fromString s,v))
          RecordLabel.Map.empty
          stringTyList)

  fun BtvIdTy loc = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_btvId loc, args = []}
  fun TypIdTy loc = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_typId loc, args = []}

  fun SENVMAPTY loc ty = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_SENVMAPty loc, args=[ty]}
  fun TypIDMapMapTy loc ty = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_TypIDMapMap loc, args = [ty]}
  fun BounTypeVarIDMapMapTy loc ty =
      T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_BoundTypeVarIDMapMap loc, args = [ty]}
  fun RecordLabelMapMapTy loc ty = 
      T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_RecordLabelMapMap loc, args = [ty]}
  fun LabelTy loc = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_label loc, args = []}
  fun IdstatusTy loc = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_idstatus loc, args = []}
  fun EnvTy loc = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_env loc, args = []}

  fun ReifiedTermTy loc = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_reifiedTerm loc, args = []}
  fun ReifiedTyTy loc = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_reifiedTy loc, args = []}
  fun ReifiedTyLabelMapTy loc = RecordLabelMapMapTy loc (ReifiedTyTy loc)
  fun ConSetTy loc =  SENVMAPTY loc (OptionTy (ReifiedTyTy loc))
  fun ConSetEnvTy loc = TypIDMapMapTy loc (ConSetTy loc)
  fun TyRepTy loc = RecordTy [("conSetEnv", ConSetEnvTy loc), ("reifiedTy", ReifiedTyTy loc)]

end
