(**
 * @copyright (C) 2024 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure RecordCalcType =
struct

  structure R = RecordCalc
  structure T = Types
  structure B = BuiltinTypes

  fun typeOfInt int =
      case int of
        R.INT8 _ => B.int8Ty
      | R.INT16 _ => B.int16Ty
      | R.INT32 _ => B.int32Ty
      | R.INT64 _ => B.int64Ty
      | R.WORD8 _ => B.word8Ty
      | R.WORD16 _ => B.word16Ty
      | R.WORD32 _ => B.word32Ty
      | R.WORD64 _ => B.word64Ty
      | R.CONTAG _ => B.contagTy
      | R.CHAR _ => B.charTy

  fun typeOfTlconst const =
      case const of
        R.REAL64 _ => B.real64Ty
      | R.REAL32 _ => B.real32Ty
      | R.UNIT => B.unitTy
      | R.NULLPOINTER => T.CONSTRUCTty {tyCon = B.ptrTyCon, args = [B.unitTy]}
      | R.NULLBOXED => B.boxedTy
      | R.FOREIGNSYMBOL {name, ty} => ty

  fun typeOfConst const =
      case const of
        R.INT int => typeOfInt int
      | R.CONST const => typeOfTlconst const
      | R.SIZE (_, ty) => T.SINGLETONty (T.SIZEty ty)
      | R.TAG (_, ty) => T.SINGLETONty (T.TAGty ty)

  fun typeOfString string =
      case string of
        R.STRING _ => B.stringTy
      | R.INTINF _ => B.intInfTy

  fun typeOfValue value =
      case value of
        R.RCCONSTANT const => typeOfConst const
      | R.RCVAR {ty, ...} => ty

  fun typeOfExp exp =
      case exp of
        R.RCVALUE (value, _) => typeOfValue value
      | R.RCSTRING (string, _) => typeOfString string
      | R.RCEXVAR (var, _) => #ty var
      | R.RCFNM {btvEnv, constraints, argVarList, bodyTy, bodyExp, loc} =>
        if BoundTypeVarID.Map.isEmpty btvEnv andalso null constraints
        then T.FUNMty (map #ty argVarList, bodyTy)
        else T.POLYty {boundtvars = btvEnv,
                       constraints = constraints,
                       body = T.FUNMty (map #ty argVarList, bodyTy)}
      | R.RCAPPM {funTy, instTyList = nil, ...} =>
        (case TypesBasics.revealTy funTy of
           T.FUNMty (_, retTy) => retTy
         | _ => raise Bug.Bug "typeOfExp: RCAPPM")
      | R.RCAPPM {funTy, instTyList as _ :: _, ...} =>
        (case TypesBasics.revealTy (TypesBasics.tpappTy (funTy, instTyList)) of
           T.FUNMty (_, retTy) => retTy
         | _ => raise Bug.Bug "typeOfExp: RCAPPM")
      | R.RCSWITCH {resultTy, ...} => resultTy
      | R.RCPRIMAPPLY {primOp = {ty, ...}, instTyList, ...} =>
        #resultTy (TypesBasics.tpappPrimTy (ty, instTyList))
      | R.RCRECORD {fields, ...} =>
        T.RECORDty (RecordLabel.Map.map #ty fields)
      | R.RCSELECT {resultTy, ...} => resultTy
      | R.RCMODIFY {recordTy, ...} => recordTy
      | R.RCLET {decl, body, loc} => typeOfExp body
      | R.RCRAISE {resultTy, ...} => resultTy
      | R.RCHANDLE {resultTy, ...} => resultTy
      | R.RCTHROW {resultTy, ...} => resultTy
      | R.RCCATCH {resultTy, ...} => resultTy
      | R.RCFOREIGNAPPLY {resultTy = SOME ty, ...} => ty
      | R.RCFOREIGNAPPLY {resultTy = NONE, ...} => B.unitTy
      | R.RCCALLBACKFN {attributes, argVarList, resultTy, ...} =>
        T.BACKENDty
          (T.FOREIGNFUNPTRty
             {argTyList = map #ty argVarList,
              varArgTyList = NONE,
              resultTy = resultTy,
              attributes = attributes})
      | R.RCCAST {targetTy, ...} => targetTy
      | R.RCINDEXOF {fields, label, ...} =>
        T.SINGLETONty
          (T.INDEXty (label, T.RECORDty (RecordLabel.Map.map #ty fields)))

end
