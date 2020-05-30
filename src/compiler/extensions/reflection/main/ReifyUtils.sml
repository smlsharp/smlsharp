structure ReifyUtils =
struct
  structure TC = TypedCalc
  structure BT = BuiltinTypes
  structure A = Absyn
  structure T = Types
  structure TB = TypesBasics
  structure U = UserLevelPrimitive
  open ReifiedTyData

  type loc = Loc.loc
  type ty = Types.ty
  type varInfo = Types.varInfo
  type exVarInfo = Types.exVarInfo
  type conInfo = Types.conInfo
  type exnCon = TC.exnCon
  type exp = TC.tpexp
  type decl = TC.tpdecl
  type label = RecordLabel.label

  exception TyConNotDefined of string
  exception TypeMismatch

  fun eqTy arg = Unify.eqTy BoundTypeVarID.Map.empty arg
  fun printTy ty = Bug.printError (Bug.prettyPrint (T.format_ty ty))
  fun printTpexp tpexp = Bug.printError (Bug.prettyPrint (TC.format_tpexp tpexp) ^ "\n")

  fun --> (argTy, retTy) = T.FUNMty ([argTy], retTy)
  fun ** (ty1, ty2) = T.RECORDty (RecordLabel.tupleMap [ty1, ty2])
  infixr 4 -->
  infix 5 **

  fun isArrayTy ty =
      case TB.derefTy ty of
        T.CONSTRUCTty {tyCon, args = [ty]} =>TypID.eq (#id tyCon, #id BT.arrayTyCon)
      | _ => false
  fun isListTy ty =
      case TB.derefTy ty of
        T.CONSTRUCTty {tyCon, args = [ty]} =>TypID.eq (#id tyCon, #id BT.listTyCon)
      | _ => false
  fun isPartialDynTy ty =
      case TB.derefTy ty of
        T.CONSTRUCTty {tyCon, args = [ty]} =>
        TypID.eq (#id tyCon, #id (U.REIFY_tyCon_dyn()))
      | _ => false
  fun partialDynElemTy ty =
      case TB.derefTy ty of
        T.CONSTRUCTty {tyCon, args = [ty]} =>
        if TypID.eq (#id tyCon, #id (U.REIFY_tyCon_dyn())) then SOME ty 
        else NONE
      | _ => NONE
  fun isBottomTy ty =
      case TB.derefTy ty of
        T.CONSTRUCTty {tyCon, args = [ty]} =>
        TypID.eq (#id tyCon, #id (U.REIFY_tyCon_void()))
      | _ => false
  fun ArrayElemTy ty = 
      case TB.derefTy ty of 
        T.CONSTRUCTty {tyCon, args = [ty]} =>
        if TypID.eq (#id tyCon, #id BT.arrayTyCon) then ty
        else raise TypeMismatch
      | _ => raise TypeMismatch
  fun FunArgBodyTy ty =
      case TB.derefTy ty of 
        T.FUNMty ([argTy], bodyTy) => {argTy = argTy, bodyTy = bodyTy}
      | _ => (Bug.printError "FunArgBodyTy\n";
             printTy ty;
             raise TypeMismatch)
  fun ListElemTy ty = 
      case TB.derefTy ty of 
        T.CONSTRUCTty {tyCon, args = [elemTy]} =>
        if TypID.eq (#id tyCon, #id BT.listTyCon) then elemTy
        else (Bug.printError "ListElemTy\n";
              printTy ty;
              raise TypeMismatch)
      | _ => 
        (Bug.printError "ListElemTy\n";
         printTy ty;
         raise TypeMismatch)
  fun RecordTyFields ty =
      case TB.derefTy ty of 
        T.RECORDty rmap => 
        map (fn (l,ty) => (RecordLabel.toString l, ty))
            (RecordLabel.Map.listItemsi rmap)
      | _ => 
        (Bug.printError "RecordTyFileds\n";
         printTy ty;
         raise TypeMismatch)

  fun newVar ty =
      {path = [Symbol.generate ()], ty = ty, id = VarID.generate (), opaque = false} : Types.varInfo

  fun newVarWithString loc string ty =
      {path = [Symbol.mkSymbol string loc], ty = ty, id = VarID.generate (), opaque = false} : Types.varInfo

  fun newVarWithSymbol symbol ty =
      {path = [symbol], ty = ty, id = VarID.generate (), opaque = false} : Types.varInfo

  fun Int loc int =
      {exp = TC.TPCONSTANT
               {const = A.INT (Int.toLarge int),
                loc = loc,
                ty = BT.int32Ty},
       ty = Int32Ty}
  fun Word loc word =
      {exp = TC.TPCONSTANT
               {const = A.WORD (Word.toLargeInt word),
                loc = loc,
                ty = BT.word32Ty},
       ty = Word32Ty}
  fun String loc str =
      {exp = TC.TPCONSTANT {const = A.STRING (str),
                            loc = loc,
                            ty = BT.stringTy},
       ty = StringTy}
  fun Real loc real =
      {exp = TC.TPCONSTANT
               {const = A.REAL (Real.toString real),
                loc = loc,
                ty = BT.real64Ty},
       ty = Real64Ty}
  fun Bool loc bool =
      let
        val conInfo = if bool then BT.trueTPConInfo else BT.falseTPConInfo
        val boolExp = 
            TC.TPDATACONSTRUCT
              {con = conInfo,
               instTyList = NONE,
               argExpOpt = NONE,
               loc = loc}
      in              
        {exp = boolExp, ty = BoolTy}
      end

  fun Option loc ty NONE = 
      {exp = TC.TPDATACONSTRUCT
               {con = BT.NONETPConInfo,
                instTyList = SOME [ty],
                argExpOpt = NONE,
                loc = loc},
       ty = OptionTy ty}
    | Option loc ty (SOME {exp=argExp, ty=_}) = 
      {exp = TC.TPDATACONSTRUCT
               {con = BT.SOMETPConInfo,
                instTyList = SOME [ty],
                argExpOpt = SOME argExp,
                loc = loc},
       ty = OptionTy ty}

  fun MonoVar (exVarInfo as {path:Symbol.longsymbol, ty:T.ty}) =
      {ty = ty, exp = TC.TPEXVAR exVarInfo}

  fun Var (varInfo as {ty,path,id,opaque}) =
      {exp = TC.TPVAR varInfo, ty = ty}

  fun InstVar {exVarInfo as {path:Symbol.longsymbol, ty:T.ty}, instTy} =
      TypedCalcUtils.toplevelInstWithInstTy
        {ty = ty, exp = TC.TPEXVAR exVarInfo, instTy = instTy}

  fun InstListVar {exVarInfo as {path:Symbol.longsymbol, ty:T.ty}, instTyList} =
      TypedCalcUtils.toplevelInstWithInstTyList
        {ty = ty, exp = TC.TPEXVAR exVarInfo, instTyList = instTyList}

  fun Pair loc {exp=exp1, ty=ty1} {exp=exp2, ty=ty2} =
      {exp = TC.TPRECORD
               {fields = RecordLabel.tupleMap [exp1, exp2],
                loc = loc,
                recordTy = ty1 ** ty2},
       ty = ty1 ** ty2}

  fun Fn loc {expFn, argTy, bodyTy} =
      let
        val v = newVar argTy
      in
        {exp = TC.TPFNM ({argVarList = [v], bodyExp = expFn v, bodyTy = bodyTy, loc = loc}),
         ty = argTy --> bodyTy}
      end
  fun FunExp loc expFn argTy =
      let
        val v = newVar argTy
        val Body = expFn {exp = TC.TPVAR v, ty = argTy}
      in
        {exp = TC.TPFNM {argVarList = [v], bodyExp = #exp Body, bodyTy = #ty Body, loc = loc},
         ty = argTy --> #ty Body}
      end

  fun Apply loc {exp=funExp, ty=funTy}  {exp=argExp, ty=argTy} =
      let
        val bodyTy = case TB.derefTy funTy of
                       T.FUNMty ([domTy], bodyTy) => 
                       if eqTy (domTy, argTy) then bodyTy
                       else 
                         (
                          Bug.printError "ApplyFail\n";
                          Bug.printError "funExp:\n";
                          printTpexp funExp;
                          Bug.printError "argExp:\n";
                          printTpexp argExp;
                          Bug.printError "funTy:\n";
                          printTy funTy;
                          Bug.printError "domTy:\n";
                          printTy domTy;
                          Bug.printError "argTy:\n";
                          printTy argTy;
                          raise TypeMismatch)
                     | _ => 
                       (Bug.printError "ApplyFail not fun\n";
                        Bug.printError "funTy:\n";
                        printTy funTy;
                        Bug.printError "argTy:\n";
                        printTy argTy;
                        raise TypeMismatch)
      in
        {exp = TC.TPAPPM {funExp=funExp, funTy=funTy, argExpList=[argExp], loc = loc},
         ty = bodyTy} 
      end

  fun ApplyList loc funexp nil = funexp
    | ApplyList loc funexp (h::t) = ApplyList loc (Apply loc funexp h) t

  fun Val loc varInfo {exp,ty}  = 
      TC.TPVAL ((varInfo, exp), loc)

  fun Con loc conInfo argOpt = 
      let
        val (resultTy, argExpOpt) =
            case (TB.derefTy (#ty conInfo), argOpt) of
              (T.FUNMty ([domTy], bodyTy), SOME {exp,ty}) =>
              if eqTy (domTy, ty) then (bodyTy, SOME exp)
              else raise TypeMismatch
            | (T.POLYty _, _) => raise TypeMismatch
            | (T.TYVARty _, _) => raise TypeMismatch
            | (T.BOUNDVARty _, _) => raise TypeMismatch
            | (ty, SOME _) => raise TypeMismatch
            | (ty, NONE) => (ty, NONE)
      in
        {exp = TC.TPDATACONSTRUCT
                 {con = conInfo,
                  instTyList = NONE,
                  argExpOpt = argExpOpt,
                  loc = loc},
         ty =resultTy}
      end
      

  fun Cons loc {hd, tl} =
      let
        val listTy = if eqTy (#ty tl, ListTy (#ty hd)) then #ty tl 
                     else raise TypeMismatch
        val {exp,ty} = Pair loc hd tl
      in
        {exp=TC.TPDATACONSTRUCT
               {con = BT.consTPConInfo,
                argExpOpt = SOME exp,
                instTyList = SOME [#ty hd],
                loc = loc},
         ty = listTy}
      end

  fun Nil loc instTy = 
      {exp=TC.TPDATACONSTRUCT
             {argExpOpt = NONE,
              con = BT.nilTPConInfo,
              instTyList = SOME [instTy],
              loc = loc},
       ty=ListTy instTy}

  fun List loc instTy expTyList =
      foldr (fn (hdExp, tlExp) => 
                Cons loc {hd = hdExp, tl = tlExp})
            (Nil loc instTy) 
            expTyList

  fun TypeCast loc {ty, exp} ty2 =
      {ty = ty2,
       exp = TC.TPPRIMAPPLY
               {primOp = {primitive = BuiltinPrimitive.Cast
                                        BuiltinPrimitive.TypeCast,
                          ty = ty --> ty2},
                instTyList = NONE,
                argExp = exp,
                loc = loc}}

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
        val MakePos = MonoVar (U.REIFY_exInfo_makePos ())
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
        val mkLongsymbolExp = MonoVar (U.REIFY_exInfo_SymbolMkLongSymbol())
      in
        ApplyList loc mkLongsymbolExp [stringListExp, Loc loc]
      end
  fun RecordLabelFromString loc string =
      Apply
        loc
        (MonoVar (U.REIFY_exInfo_RecordLabelFromString()))
        (String loc string)

end
