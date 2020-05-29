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

  fun BtvIdTy () = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_btvId(), args = []}
  fun TypIdTy () = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_typId(), args = []}

(*
  fun PosTy () = 
      RecordTy [("fileName", StringTy), ("line", IntTy), ("col", IntTy)]
  fun LocTy () = 
      RecordTy [("1", PosTy()), ("2", PosTy())]
  fun SymbolTy () =
      RecordTy [("string", StringTy), ("loc", LocTy())]
  fun LongsymbolTy () = ListTy (SymbolTy())

  fun SymbolTy () = 
      T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_symbol(), args = []}
  fun PosTy () = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_pos(), args = []}
*)
  fun SENVMAPTY ty = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_SENVMAPty(), args=[ty]}
  fun TypIDMapMapTy ty = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_TypIDMapMap(), args = [ty]}
  fun BounTypeVarIDMapMapTy ty =
      T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_BoundTypeVarIDMapMap(), args = [ty]}
  fun RecordLabelMapMapTy ty = 
      T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_RecordLabelMapMap(), args = [ty]}
  fun LabelTy () = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_label(), args = []}
  fun IdstatusTy () = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_idstatus(), args = []}
  fun EnvTy () = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_env(), args = []}

  fun ReifiedTermTy () = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_reifiedTerm(), args = []}
  fun ReifiedTyTy () = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_reifiedTy(), args = []}
  fun ReifiedTyLabelMapTy () = RecordLabelMapMapTy (ReifiedTyTy())
  fun ConSetTy () =  SENVMAPTY (OptionTy (ReifiedTyTy()))
  fun ConSetEnvTy () = TypIDMapMapTy (ConSetTy())
  fun TyRepTy () = RecordTy [("conSetEnv", ConSetEnvTy()), ("reifiedTy", ReifiedTyTy())]

end
