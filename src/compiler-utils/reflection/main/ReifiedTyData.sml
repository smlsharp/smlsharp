(**
 * @copyright (c) 2016, Tohoku University.
 * @author Atsushi Ohori
 *)
structure ReifiedTyData =
struct
  structure UP = UserLevelPrimitive
  structure RC = RecordCalc
  structure T = Types

  open ReifyUtils
  type loc = Loc.loc
  type ty = Types.ty
  type btvId = BoundTypeVarID.id
  type typId = TypID.id
  type varInfo = RC.varInfo
  type exVarInfo = RC.exVarInfo
  type conInfo = RC.conInfo
  type exnCon = RC.exnCon
  type exp = RC.rcexp
  type label = RecordLabel.label
  type expTy = {exp:exp, ty:ty}

  infixr 4 -->
  infix 5 **

  fun BtvIdTy () = T.CONSTRUCTty {tyCon = UP.REIFY_btvId_tyCon(), args = []}
  fun TypIdTy () = T.CONSTRUCTty {tyCon = UP.REIFY_typId_tyCon(), args = []}
  fun SymbolTy () = 
      T.CONSTRUCTty {tyCon = UP.REIFY_symbol_tyCon(), args = []}
  fun LongsymbolTy () = ListTy (SymbolTy())
  fun PosTy () = T.CONSTRUCTty {tyCon = UP.REIFY_pos_tyCon(), args = []}
  fun SEnvMapTy ty = T.CONSTRUCTty {tyCon = UP.REIFY_SEnvMap_tyCon(), args=[ty]}
  fun TypIDMapMapTy ty = T.CONSTRUCTty {tyCon = UP.REIFY_TypIDMapMap_tyCon(), args = [ty]}
  fun BounTypeVarIDMapMapTy ty =
      T.CONSTRUCTty {tyCon = UP.REIFY_BoundTypeVarIDMapMap_tyCon(), args = [ty]}
  fun RecordLabelMapMapTy ty = 
      T.CONSTRUCTty {tyCon = UP.REIFY_RecordLabelMapMap_tyCon(), args = [ty]}
  fun LabelTy () = T.CONSTRUCTty {tyCon = UP.REIFY_label_tyCon(), args = []}
  fun IdstatusTy () = T.CONSTRUCTty {tyCon = UP.REIFY_idstatus_tyCon(), args = []}
  fun EnvTy () = T.CONSTRUCTty {tyCon = UP.REIFY_env_tyCon(), args = []}

  fun ReifiedTermTy () = T.CONSTRUCTty {tyCon = UP.REIFY_reifiedTerm_tyCon(), args = []}
  fun ReifiedTyTy () = T.CONSTRUCTty {tyCon = UP.REIFY_reifiedTy_tyCon(), args = []}
  fun ReifiedTyLabelMapTy () = RecordLabelMapMapTy (ReifiedTyTy())
  fun ConSetTy () =  SEnvMapTy (OptionTy (ReifiedTyTy()))
  fun ConSetEnvTy () = TypIDMapMapTy (ConSetTy())
  fun TyRepTy () = RecordTy [("conSetEnv", ConSetEnvTy()), ("reifiedTy", ReifiedTyTy())]

  fun LabelAsString loc label =
      String loc (RecordLabel.toString label)

  fun SymbolAsString loc symbol =
      String loc (Symbol.symbolToString symbol)

  fun Loc (loc as (pos1,pos2)) = 
      let
        val FileName1 = String loc (Loc.fileNameOfPos pos1)
        val Line1 = Int loc (Loc.lineOfPos pos1)
        val Col1 = Int loc (Loc.colOfPos pos1)
        val FileName2 = String loc (Loc.fileNameOfPos pos2)
        val Line2 = Int loc (Loc.lineOfPos pos2)
        val Col2 = Int loc (Loc.colOfPos pos2)
        val MakePos = MonoVar (UP.REIFY_makePos_exInfo())
        val posExp1 = ApplyList loc MakePos [FileName1, Line1, Col1]
        val posExp2 = ApplyList loc MakePos [FileName2, Line2, Col2]
      in
        Pair loc posExp1 posExp2
      end

  fun BtvId loc btvid =
      TypeCast loc (Int loc (BoundTypeVarID.toInt btvid)) (BtvIdTy())
  fun TypId loc typid =
      TypeCast loc (Int loc (TypID.toInt typid)) (TypIdTy())
  fun Longsymbol loc longsymbol = 
      let
        val stringList = Symbol.longsymbolToLongid longsymbol
        val stringListExp = List loc StringTy (map (String loc) stringList)
        val mkLongsymbolExp = MonoVar (UP.REIFY_SymbolMkLongSymbol_exInfo())
      in
        ApplyList loc mkLongsymbolExp [stringListExp, Loc loc]
      end
  fun RecordLabelFromString loc string =
      Apply 
        loc
        (MonoVar (UP.REIFY_RecordLabelFromString_exInfo()))
        (String loc string)
end
