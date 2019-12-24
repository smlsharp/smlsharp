structure ReifyUtils =
struct
  structure RC = RecordCalc
  structure BT = BuiltinTypes
  structure A = Absyn
  structure T = Types
  structure TB = TypesBasics
  structure U = UserLevelPrimitive

  type loc = Loc.loc
  type ty = Types.ty
  type varInfo = RecordCalc.varInfo
  type exVarInfo = RecordCalc.exVarInfo
  type exExnInfo = RecordCalc.exExnInfo
  type conInfo = RecordCalc.conInfo
  type exnCon = RC.exnCon
  type exp = RC.rcexp
  type decl = RC.rcdecl
  type label = RecordLabel.label

  exception TyConNotDefined of string
  exception TypeMismatch

  fun eqTy arg = Unify.eqTy BoundTypeVarID.Map.empty arg
  fun printTy ty = Bug.printError (Bug.prettyPrint (T.format_ty ty))
  fun printRcexp rcexp = Bug.printError (RC.rcexpToString rcexp ^ "\n")

  fun --> (argTy, retTy) = T.FUNMty ([argTy], retTy)
  fun ** (ty1, ty2) = T.RECORDty (RecordLabel.tupleMap [ty1, ty2])
  infixr 4 -->
  infix 5 **

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

  fun newVar ty =
      {path = [Symbol.generate ()], ty = ty, id = VarID.generate ()} : RC.varInfo

  fun newVarWithString loc string ty =
      {path = [Symbol.mkSymbol string loc], ty = ty, id = VarID.generate ()} : RC.varInfo

  fun newVarWithSymbol symbol ty =
      {path = [symbol], ty = ty, id = VarID.generate ()} : RC.varInfo

  fun Int loc int =
      {exp = RC.RCCONSTANT
               {const = RC.CONST (A.INT (Int.toLarge int)),
                loc = loc,
                ty = BT.int32Ty},
       ty = Int32Ty}
  fun Word loc word =
      {exp = RC.RCCONSTANT
               {const = RC.CONST (A.WORD (Word.toLargeInt word)),
                loc = loc,
                ty = BT.word32Ty},
       ty = Word32Ty}
  fun String loc str =
      {exp = RC.RCCONSTANT {const = RC.CONST (A.STRING (str)),
                            loc = loc,
                            ty = BT.stringTy},
       ty = StringTy}
  fun Real loc real =
      {exp = RC.RCCONSTANT
               {const = RC.CONST (A.REAL (Real.toString real)),
                loc = loc,
                ty = BT.real64Ty},
       ty = Real64Ty}
  fun Bool loc bool =
      let
        val conInfo = if bool then BT.trueTPConInfo else BT.falseTPConInfo
        val boolExp = 
            RC.RCDATACONSTRUCT
              {con = conInfo,
               instTyList = nil,
               argExpOpt = NONE,
               argTyOpt = NONE,
               loc = loc}
      in              
        {exp = boolExp, ty = BoolTy}
      end
  fun Exn loc exExnInfo =
      {exp = RC.RCEXNCONSTRUCT 
               {exn = RC.EXEXN exExnInfo,
                instTyList = nil,
                argExpOpt = NONE,
                loc = loc},
       ty = ExnTy}

  fun Option loc ty NONE = 
      {exp = RC.RCDATACONSTRUCT
               {con = BT.NONETPConInfo,
                instTyList = [ty],
                argExpOpt = NONE,
                argTyOpt = NONE,
                loc = loc},
       ty = OptionTy ty}
    | Option loc ty (SOME {exp=argExp, ty=_}) = 
      {exp = RC.RCDATACONSTRUCT
               {con = BT.SOMETPConInfo,
                instTyList = [ty],
                argExpOpt = SOME argExp,
                argTyOpt = SOME ty,
                loc = loc},
       ty = OptionTy ty}

  fun Raise loc {exp, ty} newTy =
      if eqTy (ty, ExnTy) then 
        {exp = RC.RCRAISE {exp = exp, ty = ty, loc=loc},
         ty = newTy}
      else raise TypeMismatch

  fun MonoVar (exVarInfo as {path:Symbol.longsymbol, ty:T.ty}) =
      {ty = ty, exp = RC.RCEXVAR exVarInfo}

  fun Var (varInfo as {ty,path,id}) =
      {exp = RC.RCVAR varInfo, ty = ty}

  fun InstVar {exVarInfo as {path:Symbol.longsymbol, ty:T.ty}, instTy} =
      RecordCalcUtils.toplevelInstWithInstTy
        {ty = ty, exp = RC.RCEXVAR exVarInfo, instTy = instTy}

  fun InstListVar {exVarInfo as {path:Symbol.longsymbol, ty:T.ty}, instTyList} =
      RecordCalcUtils.toplevelInstWithInstTyList
        {ty = ty, exp = RC.RCEXVAR exVarInfo, instTyList = instTyList}

  fun Pair loc {exp=exp1, ty=ty1} {exp=exp2, ty=ty2} =
      {exp = RC.RCRECORD
               {fields = RecordLabel.tupleMap [exp1, exp2],
                loc = loc,
                recordTy = ty1 ** ty2},
       ty = ty1 ** ty2}

  fun Seq loc expList = 
      {exp = RC.RCSEQ
               {expList = map #exp expList,
                expTyList = map #ty expList,
                loc = loc},
       ty = #ty (List.last expList)}

  fun Fn loc {expFn, argTy, bodyTy} =
      let
        val v = newVar argTy
      in
        {exp = RC.RCFNM ({argVarList = [v], bodyExp = expFn v, bodyTy = bodyTy, loc = loc}),
         ty = argTy --> bodyTy}
      end
  fun FunExp loc expFn argTy =
      let
        val v = newVar argTy
        val Body = expFn {exp = RC.RCVAR v, ty = argTy}
      in
        {exp = RC.RCFNM {argVarList = [v], bodyExp = #exp Body, bodyTy = #ty Body, loc = loc},
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
                          printRcexp funExp;
                          Bug.printError "argExp:\n";
                          printRcexp argExp;
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
        {exp = RC.RCAPPM {funExp=funExp, funTy=funTy, argExpList=[argExp], loc = loc},
         ty = bodyTy} 
      end

  fun ApplyList loc funexp nil = funexp
    | ApplyList loc funexp (h::t) = ApplyList loc (Apply loc funexp h) t

  fun Val loc varInfo {exp,ty}  = 
      RC.RCVAL ([(varInfo, exp)], loc)

  fun Let loc Decls ExpList = 
      RC.RCLET {decls=Decls, body = map #exp ExpList, tys = map #ty ExpList, loc =loc}

  fun Con loc conInfo argOpt = 
      let
        val (resultTy, argExpOpt, argTyOpt) = 
            case (TB.derefTy (#ty conInfo), argOpt) of
              (T.FUNMty ([domTy], bodyTy), SOME {exp,ty}) =>
              if eqTy (domTy, ty) then (bodyTy, SOME exp, SOME ty)
              else raise TypeMismatch
            | (T.POLYty _, _) => raise TypeMismatch
            | (T.TYVARty _, _) => raise TypeMismatch
            | (T.BOUNDVARty _, _) => raise TypeMismatch
            | (ty, SOME _) => raise TypeMismatch
            | (ty, NONE) => (ty, NONE, NONE)
      in
        {exp = RC.RCDATACONSTRUCT
                 {con = conInfo,
                  instTyList = nil,
                  argExpOpt = argExpOpt,
                  argTyOpt = argTyOpt,
                  loc = loc},
         ty =resultTy}
      end
      

  fun Cons loc {hd, tl} =
      let
        val listTy = if eqTy (#ty tl, ListTy (#ty hd)) then #ty tl 
                     else raise TypeMismatch
        val {exp,ty} = Pair loc hd tl
      in
        {exp=RC.RCDATACONSTRUCT
               {con = BT.consTPConInfo,
                argExpOpt = SOME exp,
                argTyOpt = SOME ty,
                instTyList = [#ty hd],
                loc = loc},
         ty = listTy}
      end

  fun Nil loc instTy = 
      {exp=RC.RCDATACONSTRUCT 
             {argExpOpt = NONE,
              con = BT.nilTPConInfo,
              argTyOpt = NONE,
              instTyList = [instTy],
              loc = loc},
       ty=ListTy instTy}

  fun List loc instTy expTyList =
      foldr (fn (hdExp, tlExp) => 
                Cons loc {hd = hdExp, tl = tlExp})
            (Nil loc instTy) 
            expTyList

  fun TypeCast loc {ty, exp} ty2 =
      {ty = ty2,
       exp = RC.RCPRIMAPPLY
               {primOp = {primitive = BuiltinPrimitive.Cast
                                        BuiltinPrimitive.TypeCast,
                          ty = ty --> ty2},
                instTyList = nil,
                argExp = exp,
                loc = loc}}
  fun HandleAndReRaise loc exExnInfo {exp, ty} =
      let
        val exnVar = newVar ExnTy
        val {exp=raiseExp, ty} = Raise loc (Exn loc exExnInfo)  ty
        val exnCaseExp =
            RC.RCEXNCASE
              {exp = RC.RCVAR exnVar,
               defaultExp = #exp (Raise loc (Var exnVar) ty),
               expTy = ExnTy, 
               loc = loc,
               ruleList = [(RC.EXEXN exExnInfo, NONE, raiseExp)],
               resultTy = ty}
      in
        RC.RCHANDLE
          {exp = exp,
           exnVar = exnVar,
           handler = exnCaseExp,
           resultTy = ty,
           loc = loc}
      end

end
