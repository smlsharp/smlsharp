(**
 *  This structure defines constants and operators on terms in the language
 * which is the target of compilation.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ObjectCode.sml,v 1.10 2006/02/28 16:11:03 kiyoshiy Exp $
 *)
structure ObjectCode =
struct

  (***************************************************************************)

  structure FE = SMLFormat.FormatExpression
  structure IT = InitialTypeContext
  structure P = Path
  structure PP = SMLFormat
  structure SE = StaticEnv
  structure TP = TypedCalc
  structure TPU = TypedCalcUtils
  structure TU = TypesUtils
  structure TY = Types

  structure U = Utility

  (***************************************************************************)

  val stringTy = StaticEnv.stringty
  val intTy = StaticEnv.intty
  val realTy = StaticEnv.realty
  val unitTy = StaticEnv.unitty
  val exnTy = StaticEnv.exnty
  val stringPairTy = TY.RECORDty(U.listToTupleSEnv [stringTy, stringTy])
  val trueCon = IT.trueCon
  val falseCon = IT.falseCon
  val refCon = IT.refCon
  val refTyCon = SE.refTyCon

  val nameOfConcatString = "String_concat2"
  val primInfoOfConcatString =
      {name = nameOfConcatString, ty = TY.FUNMty ([stringPairTy], stringTy)}

  val nameOfPrintString = "print"
  val primInfoOfPrintString =
      {name = nameOfPrintString, ty = TY.FUNMty ([stringTy], unitTy)}

  val nameOfUpdateRef = ":="
  val typeOfUpdateRef =
      let
        val btvKind =
            {index = 0, recKind = TY.UNIV, eqKind = TY.NONEQ}
        val argTy = TY.BOUNDVARty 0
        val argRefTy = TY.CONty{tyCon = refTyCon, args = [argTy]}
      in
        TY.POLYty
        {
          boundtvars = IEnv.insert (IEnv.empty, 0, btvKind),
          body =
          TY.FUNMty ([TY.RECORDty(U.listToTupleSEnv [argRefTy, argTy])], unitTy)
        }
      end
  val primInfoOfUpdateRef = {name = nameOfUpdateRef, ty = typeOfUpdateRef}

  fun failException (message, loc) =
      TP.TPCONSTRUCT
          {
            con=IT.FormatterExnConpath,
            instTyList=[],
            argExpOpt=SOME(TP.TPCONSTANT(TY.STRING message, loc)),
            loc=loc
          }
  val formatExpressionTy = stringTy
  val formatterResultTy = formatExpressionTy

  val nameOfFormatExnRef = "format_exnRef"
  val pathOfFormatExnRef = P.topStrPath

  fun applyTy (TY.FUNMty(_, resultTy), argTy) = resultTy
    | applyTy (ty, _) =
      raise
        Control.Bug ("expected FUNMty, but " ^ TypeFormatter.tyToString ty)

  fun formatterOfTyTy ty = TY.FUNMty([ty], formatterResultTy)

  fun makeTyVarList number =
      List.tabulate (number, fn _ => TY.newty TY.univKind)

  (**
   * Get the type of formatter of a type constructor.
   * The type this function returns is mono type.
   * It should be polytyped by using TU.generalizer if needed.
   *)
  fun formatterOfTyConTy (tyCon as {name, tyvars, ...} : TY.tyCon) =
      let
        (* type ('a1,...'an) name *)
        (* ['X1,...,'Xn.('X1->r)->...->('Xn->r)->('X1,...,'Xn) name->r] *)
        (* for each argument tyvar, generate ID *)
        val tyVars = makeTyVarList (List.length tyvars)
        (* ('X1,...,'Xn) name *)
        val formatTargetTy = TY.CONty {tyCon = tyCon, args = tyVars}
        (* ('X1,...,'Xn) name -> r *)
        val actualFormatterTy = formatterOfTyTy formatTargetTy
        (* ('X1->r) -> ... ('Xn->r) -> ('X1,...,'Xn) name -> r *)
        val formatterMonoTy =
            foldr
                (fn (tyVar, resultTy) =>
                    let
                      val formatterTy = formatterOfTyTy tyVar
                      val newResultTy = TY.FUNMty([formatterTy], resultTy)
                    in newResultTy end)
                actualFormatterTy
                tyVars
      in
        formatterMonoTy
      end

  (**
   * Get the type of formatter of a tyFun. 
   * The type this function returns is mono type.
   * It should be polytyped by using TU.generalizer if needed.
   *)
  fun formatterOfTyFunTy (tyFun as {name, ...} : TY.tyFun) =
      let
        val (bodyTy, argTys) = 
            TU.instantiate
                {body = TU.derefTy (#body tyFun), boundtvars = #tyargs tyFun}
      in
        case IEnv.numItems argTys of
          0 => TY.FUNMty([bodyTy], formatExpressionTy)
        | arity =>
          let
            (* type ('a1,...'an) name *)
            (*['X1,...,'Xn.('X1->r)->...->('Xn->r)->('X1,...,'Xn) name->r] *)
            val tyVars = IEnv.listItems argTys
            (* ('X1,...,'Xn) name -> r *)
            val actualFormatterTy = formatterOfTyTy bodyTy
            (* ('X1->r) -> ... ('Xn->r) -> ('X1,...,'Xn) name -> r *)
            val formatterMonoTy =
                foldr
                    (fn (tyVar, resultTy) =>
                        let
                          val formatterTy = formatterOfTyTy tyVar
                          val newResultTy = TY.FUNMty([formatterTy], resultTy)
                        in newResultTy end)
                    actualFormatterTy
                    tyVars
          in
            formatterMonoTy
          end
      end

  fun formatterOfTySpecTy (tySpec : TY.tySpec) =
      formatterOfTyConTy (U.tySpecToTyCon tySpec)
      
  fun FEToString formatExpressions =
      PP.prettyPrint
          {newlineString = "\n", spaceString = " ", columns = 80}
          formatExpressions

  fun concatStrings [] = raise Control.Bug "[] is passed to concatStrings."
    | concatStrings [expression] = expression
    | concatStrings (headExpression :: tailExpressions) =
      let
        fun append (right, left) =
            let
              val loc = TPU.getLocOfExp right
              val fields = U.listToTupleSEnv [left, right]
              val tupleExp = TP.TPRECORD {fields=fields, recordTy=stringPairTy, loc=loc}
            in
              TP.TPPRIMAPPLY {primOp=primInfoOfConcatString, instTyList=[], argExpOpt=SOME tupleExp, loc=loc}
            end
      in
        foldl append headExpression tailExpressions
      end

  fun printString expression =
      let val loc = TPU.getLocOfExp expression
      in TP.TPPRIMAPPLY{primOp=primInfoOfPrintString, instTyList=[], argExpOpt=SOME expression, loc=loc}
      end

  fun printFormat expression =
      let val loc = TPU.getLocOfExp expression
      in TP.TPPRIMAPPLY{primOp=primInfoOfPrintString, instTyList=[], argExpOpt=SOME expression, loc=loc}
      end

  fun concatFormatExpressions [] =
      raise Control.Bug "[] is passed to concatFormatExpressions"
    | concatFormatExpressions [expression] = expression
    | concatFormatExpressions expressions = concatStrings expressions

  local
    fun removeIndents (FE.Guard (guard, expressions)) =
        FE.Guard (guard, map removeIndents expressions)
      | removeIndents (FE.StartOfIndent _) = FE.Term(0, "")
      | removeIndents FE.EndOfIndent = FE.Term(0, "")
      | removeIndents expression = expression
  in
  fun translateFormatExpression expression =
      let
        val string = FEToString [removeIndents expression]
        val loc = Loc.noloc
      in TP.TPCONSTANT(TY.STRING string, loc) end
        handle PP.Fail message => raise Control.Bug message

  fun translateFormatExpressions (expressions as expression :: _) =
      (let
         val loc = Loc.noloc
         val string = FEToString (map removeIndents expressions)
       in [TP.TPCONSTANT(TY.STRING string, loc)] end
         handle PP.Fail message => raise Control.Bug message)
    | translateFormatExpressions [] =
      raise Control.Bug "ObjectCode.translateFormatExpressions found null."
  end

(*
    fun translateFormatExpression (FE.Term (_, string)) =
        TP.TPCONSTANT(TY.STRING string)
      | translateFormatExpression (FE.Guard (_, expressions)) =
        concatFormatExpressions (map translateFormatExpression expressions)
      | translateFormatExpression (FE.Indicator{space, ...}) =
        TP.TPCONSTANT(TY.STRING(if space then " " else ""))
      | translateFormatExpression (FE.StartOfIndent _) =
        TP.TPCONSTANT(TY.STRING(""))
      | translateFormatExpression FE.EndOfIndent =
        TP.TPCONSTANT(TY.STRING(""))

    fun translateFormatExpressions exps = map translateFormatExpression exps
*)

  fun makeTerm stringExp = stringExp
  fun makeGuard (guard, expressions) = concatFormatExpressions expressions

  (***************************************************************************)

end
