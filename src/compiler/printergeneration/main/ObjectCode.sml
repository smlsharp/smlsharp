(**
 *  This structure defines constants and operators on terms in the language
 * which is the target of compilation.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ObjectCode.sml,v 1.24 2007/06/01 01:25:11 kiyoshiy Exp $
 *)
structure ObjectCode =
struct

  (***************************************************************************)

  structure CT = ConstantTerm
  structure FE = SMLFormat.FormatExpression
  structure IT = InitialTypeContext
  structure P = Path
  structure PP = SMLFormat
  structure PR = Primitives
  structure PT = PredefinedTypes
  structure TP = TypedCalc
  structure TPU = TypedCalcUtils
  structure TU = TypesUtils
  structure TY = Types

  structure U = Utility

  (***************************************************************************)

  val primInfoOfPrintString = PR.printPrimInfo
  val primInfoOfUpdateRef = PR.assignPrimInfo

  fun failException (message, loc) =
      TP.TPCONSTRUCT
          {
            con = PT.FormatterCon,
            instTyList = [],
            argExpOpt =
            SOME(TP.TPCONSTANT(CT.STRING message, PT.stringty, loc)),
            loc = loc
          }

  fun constIntExp int =
      TP.TPCONSTANT(CT.INT (Int32.fromInt int), PT.intty, Loc.noloc)
  fun constStringExp string =
      TP.TPCONSTANT(CT.STRING string, PT.stringty, Loc.noloc)
  fun constructExp con instTyList argExpOpt loc =
      TP.TPCONSTRUCT
          {
            con = con,
            instTyList = instTyList,
            argExpOpt = argExpOpt,
            loc = loc
          }
  fun constBoolExp bool =
      constructExp (if bool then PT.trueCon else PT.falseCon) [] NONE Loc.noloc
  fun optionExp NONE ty loc = constructExp PT.NONECon [ty] NONE loc
    | optionExp (SOME arg) ty loc = constructExp PT.SOMECon [ty] (SOME arg) loc
  (**
   * convert a sequence of expressions of which types are "elementTy"
   * to an expression of which type is "elementTy list".
   *)
  fun expsToListExp elementTy TPExpressions =
      let
        val listTy = TY.CONty{tyCon = PT.listTyCon, args = [elementTy]}
        fun append (left, right) =
            let
              val loc = TPU.getLocOfExp left
              val tupleExp =
                  U.listToTupleExp [(left, elementTy), (right, listTy)] loc
            in
              constructExp PT.consCon [elementTy] (SOME tupleExp) loc
            end
        val nilExp = constructExp PT.nilCon [elementTy] NONE Loc.noloc
      in
        foldr append nilExp TPExpressions
      end

  val formatExpressionTy = PT.expressionty
  val formatterResultTy = formatExpressionTy

  val nameOfFormatExnRef = "_format_exnRef"
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
      
  fun FEToString formatExpressions = Control.prettyPrint formatExpressions

  fun printString expression =
      let val loc = TPU.getLocOfExp expression
      in
        TP.TPPRIMAPPLY
            {
              primOp = primInfoOfPrintString,
              instTyList = [],
              argExpOpt = SOME expression,
              loc = loc
            }
      end

  val printFormatName = "printFormat"
  val printFormatTy = TY.FUNMty([formatExpressionTy], PT.unitty)
  val printFormatVarPathInfo =
      {name = printFormatName, strpath = P.topStrPath, ty = printFormatTy}
  val printFormatExp = TP.TPVAR(printFormatVarPathInfo, Loc.noloc)
  fun printFormat expression =
      let val loc = TPU.getLocOfExp expression
      in
        TP.TPAPPM
            {
              funExp = printFormatExp,
              funTy = printFormatTy,
              argExpList = [expression],
              loc = loc
            }
      end

  (* fun printFormatOfValBinding (name, valExp, typeExp) = ... *)
  val printFormatOfValBindingName = "printFormatOfValBinding"
  val printFormatOfValBindingTy =
      TY.FUNMty
          (
            [U.listToTupleTy
                 [PT.stringty, formatExpressionTy, formatExpressionTy]],
            PT.unitty
          )
  val printFormatOfValBindingVarPathInfo =
      {
        name = printFormatOfValBindingName,
        strpath = P.topStrPath,
        ty = printFormatOfValBindingTy
      }
  val printFormatOfValBindingExp =
      TP.TPVAR(printFormatOfValBindingVarPathInfo, Loc.noloc)
  fun printFormatOfValBinding (name, valueExp, typeExp, loc) =
      let
        val argExp =
            U.listToTupleExp
                [
                  (constStringExp name, PT.stringty),
                  (valueExp, formatExpressionTy),
                  (typeExp, formatExpressionTy)
                ]
                loc
      in
        TP.TPAPPM
            {
              funExp = printFormatOfValBindingExp,
              funTy = printFormatOfValBindingTy,
              argExpList = [argExp],
              loc = loc
            }
      end

  fun printFormatStatic expressions =
      printString (constStringExp (FEToString expressions))

  local
    val expListTy = TY.CONty{tyCon = PT.listTyCon, args = [formatExpressionTy]}

    val assocTy =
        U.listToRecordTy
            [
              ("cut", PT.boolty),
              ("strength", PT.intty),
              ("direction", PT.assocDirectionty)
            ]
    val assocOptTy = TY.CONty{tyCon = PT.optionTyCon, args = [assocTy]}
    fun translateAssocDirection direction =
        case direction
         of FE.Left => constructExp PT.LeftCon [] NONE Loc.noloc
          | FE.Right => constructExp PT.RightCon [] NONE Loc.noloc
          | FE.Neutral => constructExp PT.NeutralCon [] NONE Loc.noloc
    fun translateAssoc {cut, strength, direction} =
        U.listToRecordExp
            [
              ("cut", constBoolExp cut, PT.boolty),
              ("strength", constIntExp strength, PT.intty),
              (
                "direction",
                translateAssocDirection direction, PT.assocDirectionty
              )
            ]
            Loc.noloc

    val priorityRecTy = (U.listToRecordTy [("priority", PT.priorityty)])
    val priorityRecOptTy =
        TY.CONty{tyCon = PT.optionTyCon, args = [priorityRecTy]}
    fun translatePriority (FE.Preferred n) =
        constructExp PT.PreferredCon [] (SOME(constIntExp n)) Loc.noloc
      | translatePriority (FE.Deferred) =
        constructExp PT.DeferredCon [] NONE Loc.noloc
    fun translatePriorityRec {priority} =
        U.listToRecordExp
            [("priority", translatePriority priority, PT.priorityty)]
            Loc.noloc
  in

  fun translateFormatExpression (FE.Term(n, string)) =
      constructExp
          PT.TermCon
          []
          (SOME
               (U.listToTupleExp
                    [
                      (constIntExp n, PT.intty),
                      (constStringExp string, PT.stringty)
                    ]
                    Loc.noloc))
          Loc.noloc
    | translateFormatExpression (FE.Guard (assocOpt, expList)) =
      let
        val assocOptExp =
            optionExp (Option.map translateAssoc assocOpt) assocTy Loc.noloc
        val expListExp =
            expsToListExp
                formatExpressionTy (translateFormatExpressions expList)
      in
        constructExp
            PT.GuardCon
            []
            (SOME
                 (U.listToTupleExp
                      [(assocOptExp, assocOptTy), (expListExp, expListTy)]
                      Loc.noloc))
            Loc.noloc
      end
    | translateFormatExpression (FE.Indicator {space, newline}) =
      constructExp
          PT.IndicatorCon
          []
          (SOME
               (U.listToRecordExp
                    [
                      ("space", constBoolExp space, PT.boolty),
                      (
                        "newline",
                        optionExp
                            (Option.map translatePriorityRec newline)
                            priorityRecTy Loc.noloc,
                        priorityRecOptTy
                      )
                    ]
                    Loc.noloc))
          Loc.noloc
    | translateFormatExpression (FE.StartOfIndent n) =
      constructExp PT.StartOfIndentCon [] (SOME(constIntExp n)) Loc.noloc
    | translateFormatExpression (FE.EndOfIndent) =
      constructExp PT.EndOfIndentCon [] NONE Loc.noloc

  and translateFormatExpressions (expressions as expression :: _) =
      map translateFormatExpression expressions

  fun makeConstantTerm string =
      translateFormatExpression (FE.Term(size string, string))

  fun makeGuard (assocOpt, TPExpressions) =
      let
        val assocOptExp =
            optionExp (Option.map translateAssoc assocOpt) assocTy Loc.noloc
        val expLisExp = 
            expsToListExp formatExpressionTy TPExpressions
      in
        constructExp
            PT.GuardCon
            []
            (SOME
                 (U.listToTupleExp
                      [(assocOptExp, assocOptTy), (expLisExp, expListTy)]
                      Loc.noloc))
            Loc.noloc
      end

  (**
   * convert a sequence of expressions of which types are EXP
   * to an expression of which type is EXP.
   *)
  fun concatFormatExpressions TPExpressions =
      makeGuard (NONE, TPExpressions)

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

  (***************************************************************************)

end
