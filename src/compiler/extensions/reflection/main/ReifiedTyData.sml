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

  fun LabelAsString loc label =
      String loc (RecordLabel.toString label)

  fun SymbolAsString loc symbol =
      String loc (Symbol.symbolToString symbol)

  fun Pos loc pos =
      let
        val (isNoPos, isStdPath, name, line, col, pos, gap) =
            case pos of
              Loc.POS {source = Loc.FILE (Loc.STDPATH,name), line, col,
                       pos, gap} =>
              (false, true, SOME (Filename.toString name), line, col, pos, gap)
            | Loc.POS {source = Loc.FILE (Loc.USERPATH,name), line, col,
                       pos, gap} =>
              (false, false, SOME (Filename.toString name), line, col, pos, gap)
            | Loc.POS {source = Loc.INTERACTIVE, line, col, pos, gap} =>
              (false, false, NONE, line, col, pos, gap)
            | Loc.NOPOS =>
              (true, false, NONE, 0, 0, 0, 0)
        val IsNoPos = Bool loc isNoPos
        val IsStdPath = Bool loc isStdPath
        val Name = Option loc StringTy (Option.map (String loc) name)
        val Line = Int loc line
        val Col = Int loc col
        val Pos = Int loc pos
        val Gap = Int loc gap
        val MakePos = MonoVar (UP.REIFY_exInfo_makePos ())
      in
        ApplyList loc MakePos [IsNoPos, IsStdPath, Name, Line, Col, Pos, Gap]
      end

  fun Loc (loc as (pos1, pos2)) =
      Pair loc (Pos loc pos1) (Pos loc pos2)

  fun BtvId loc btvid =
      TypeCast loc (Int loc (BoundTypeVarID.toInt btvid)) (BtvIdTy())
  fun TypId loc typid =
      TypeCast loc (Int loc (TypID.toInt typid)) (TypIdTy())
  fun Longsymbol loc longsymbol = 
      let
        val stringList = Symbol.longsymbolToLongid longsymbol
        val stringListExp = List loc StringTy (map (String loc) stringList)
        val mkLongsymbolExp = MonoVar (UP.REIFY_exInfo_SymbolMkLongSymbol())
      in
        ApplyList loc mkLongsymbolExp [stringListExp, Loc loc]
      end
  fun RecordLabelFromString loc string =
      Apply 
        loc
        (MonoVar (UP.REIFY_exInfo_RecordLabelFromString()))
        (String loc string)
end
