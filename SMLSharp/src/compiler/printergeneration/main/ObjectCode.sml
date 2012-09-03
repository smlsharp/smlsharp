(**
 *  This structure defines constants and operators on terms in the language
 * which is the target of compilation.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ObjectCode.sml,v 1.34 2008/05/31 12:18:22 ohori Exp $
 *)
structure ObjectCode =
struct
local

  structure CT = ConstantTerm
  structure FE = SMLFormat.FormatExpression
  structure IT = InitialTypeContext
  structure NM = NameMap
  structure P = Path
  structure PP = SMLFormat
  structure PT = PredefinedTypes
  structure TP = TypedCalc
  structure TPU = TypedCalcUtils
  structure TU = TypesUtils
  structure TY = Types
  structure U = Utility

in

  fun failException (message, loc) =
      TP.TPEXNCONSTRUCT
          {
            exn = PT.FormatterExnPathInfo,
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
      TP.TPDATACONSTRUCT
          {
            con = con,
            instTyList = instTyList,
            argExpOpt = argExpOpt,
            loc = loc
          }
  fun constBoolExp bool =
      constructExp (if bool then PT.trueConPathInfo else PT.falseConPathInfo) [] NONE Loc.noloc
  fun optionExp NONE ty loc = constructExp PT.noneConPathInfo [ty] NONE loc
    | optionExp (SOME arg) ty loc = constructExp PT.someConPathInfo [ty] (SOME arg) loc
  (**
   * convert a sequence of expressions of which types are "elementTy"
   * to an expression of which type is "elementTy list".
   *)
  fun expsToListExp elementTy TPExpressions =
      case TPExpressions of
        nil => constructExp PT.nilConPathInfo [elementTy] NONE Loc.noloc
      | h::t =>
        TP.TPLIST
          {expList = TPExpressions,
           listTy = TY.RAWty {tyCon = PT.listTyCon, args = [elementTy]},
           loc = TPU.getLocOfExp h}

  val formatExpressionTy = PT.expressionTy
  val formatterResultTy = formatExpressionTy

  val nameOfFormatExnRef = "_format_exnRef"

  fun applyTy (TY.FUNMty(_, resultTy), argTy) = resultTy
    | applyTy (ty, _) =
      raise
        Control.Bug ("expected FUNMty, but " ^ TypeFormatter.tyToString ty)

  fun tyOfFormatterOfTy ty = TY.FUNMty([ty], formatterResultTy)

  fun makeTyVarList number =
      List.tabulate
          (
            number,
            fn _ =>
               TY.newty TY.univKind
          )

  (**
   * Get the type of formatter of a type constructor.
   * The type this function returns is mono type.
   * It should be polytyped by using TU.generalizer if needed.
   *)
  fun tyOfFormatterOfDefinedTyCon (tyCon as {name, tyvars, ...} : TY.tyCon) =
      let
          (* type ('a1,...'an) name *)
          (* ['X1,...,'Xn.('X1->r)->...->('Xn->r)->('X1,...,'Xn) name->r] *)
          (* for each argument tyvar, generate ID *)
          val tyVars = makeTyVarList (List.length tyvars)
          (* ('X1,...,'Xn) name *)
          val formatTargetTy =
              TY.RAWty {tyCon = tyCon, args = tyVars}
          (* ('X1,...,'Xn) name -> r *)
          val actualFormatterTy = tyOfFormatterOfTy formatTargetTy
          (* ('X1->r) -> ... ('Xn->r) -> ('X1,...,'Xn) name -> r *)
          val formatterMonoTy =
              foldr
                  (fn (tyVar, resultTy) =>
                      let
                          val formatterTy = tyOfFormatterOfTy tyVar
                          val newResultTy = TY.FUNMty([formatterTy], resultTy)
                      in newResultTy end)
                  actualFormatterTy
                  tyVars
      in
          formatterMonoTy
      end



  fun tyOfFormatterOfTySpec (tyCon as {name, tyvars, ...} : TY.tyCon) =
      let
        (* type ('a1,...'an) name *)
        (* ['X1,...,'Xn.('X1->r)->...->('Xn->r)->('X1,...,'Xn) name->r] *)
        (* for each argument tyvar, generate ID *)
        val tyVars = makeTyVarList (List.length tyvars)
        (* ('X1,...,'Xn) name *)
        val formatTargetTy = TY.SPECty {tyCon = tyCon, args = tyVars}
        (* ('X1,...,'Xn) name -> r *)
        val actualFormatterTy = tyOfFormatterOfTy formatTargetTy
        (* ('X1->r) -> ... ('Xn->r) -> ('X1,...,'Xn) name -> r *)
        val formatterMonoTy =
            foldr
                (fn (tyVar, resultTy) =>
                    let
                      val formatterTy = tyOfFormatterOfTy tyVar
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
  fun tyOfFormatterOfTyFun (tyFun as {name, ...} : TY.tyFun) =
      let
        val (bodyTy, argTys) =
            U.instantiateTy
                (TY.POLYty
                     {
                       body = TU.derefTy (#body tyFun),
                       boundtvars = #tyargs tyFun
                     })
      in
        case BoundTypeVarID.Map.numItems argTys of
          0 => TY.FUNMty([bodyTy], formatExpressionTy)
        | arity =>
          let
            (* type ('a1,...'an) name *)
            (*['X1,...,'Xn.('X1->r)->...->('Xn->r)->('X1,...,'Xn) name->r] *)
            val tyVars = BoundTypeVarID.Map.listItems argTys
            (* ('X1,...,'Xn) name -> r *)
            val actualFormatterTy = tyOfFormatterOfTy bodyTy
            (* ('X1->r) -> ... ('Xn->r) -> ('X1,...,'Xn) name -> r *)
            val formatterMonoTy =
                foldr
                    (fn (tyVar, resultTy) =>
                        let
                          val formatterTy = tyOfFormatterOfTy tyVar
                          val newResultTy = TY.FUNMty([formatterTy], resultTy)
                        in newResultTy end)
                    actualFormatterTy
                    tyVars
          in
            formatterMonoTy
          end
      end

(*
  fun tyOfFormatterOfTySpec (tySpec : TY.tySpec) =
      tyOfFormatterOfTyName (U.tySpecToTyName tySpec)
*)
      
  fun FEToString formatExpressions = Control.prettyPrint formatExpressions

(*
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
*)

  val SMLSharpStructurePath = Path.appendUsrPath (Path.externPath, "SMLSharp")

  local
    val printFormatName = "printFormat"
    val printFormatTy = TY.FUNMty([formatExpressionTy], PT.unitty)
    val printFormatVarPathInfo =
        {namePath = (printFormatName, SMLSharpStructurePath), ty = printFormatTy}
    val printFormatExp = TP.TPVAR(printFormatVarPathInfo, Loc.noloc)
  in
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
  end

  local
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
          namePath = (printFormatOfValBindingName, SMLSharpStructurePath),
          (* strpath = P.topStrPath,*)
          ty = printFormatOfValBindingTy
        }
    val printFormatOfValBindingExp =
        TP.TPVAR(printFormatOfValBindingVarPathInfo, Loc.noloc)
  in
  fun printFormatOfValBinding (namePath, valueExp, typeExp, loc) =
      let
        val name = NM.namePathToString namePath
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
  end

(*
  fun printFormatStatic expressions =
      printString (constStringExp (FEToString expressions))
*)

  local
    val expListTy =
        TY.RAWty {tyCon = PT.listTyCon, args = [formatExpressionTy]}

    val assocTy =
        U.listToRecordTy
            [
              ("cut", PT.boolty),
              ("strength", PT.intty),
              ("direction", PT.assocDirectionTy)
            ]
    val assocOptTy = TY.RAWty {tyCon = PT.optionTyCon, args = [assocTy]}
    fun translateAssocDirection direction =
        case direction
         of FE.Left => constructExp PT.leftConPathInfo [] NONE Loc.noloc
          | FE.Right => constructExp PT.rightConPathInfo [] NONE Loc.noloc
          | FE.Neutral => constructExp PT.neutralConPathInfo [] NONE Loc.noloc
    fun translateAssoc {cut, strength, direction} =
        U.listToRecordExp
            [
              ("cut", constBoolExp cut, PT.boolty),
              ("strength", constIntExp strength, PT.intty),
              (
                "direction",
                translateAssocDirection direction, PT.assocDirectionTy
              )
            ]
            Loc.noloc

    val priorityRecTy = (U.listToRecordTy [("priority", PT.priorityTy)])
    val priorityRecOptTy = TY.RAWty {tyCon = PT.optionTyCon, args = [priorityRecTy]}
    fun translatePriority (FE.Preferred n) =
        constructExp PT.preferredConPathInfo [] (SOME(constIntExp n)) Loc.noloc
      | translatePriority (FE.Deferred) =
        constructExp PT.deferredConPathInfo [] NONE Loc.noloc
    fun translatePriorityRec {priority} =
        U.listToRecordExp
            [("priority", translatePriority priority, PT.priorityTy)]
            Loc.noloc
  in

  fun translateFormatExpression loc (FE.Term(n, string)) =
      constructExp
          PT.termConPathInfo
          []
          (SOME
               (U.listToTupleExp
                    [
                      (constIntExp n, PT.intty),
                      (constStringExp string, PT.stringty)
                    ]
                    loc))
          loc
    | translateFormatExpression loc (FE.Guard (assocOpt, expList)) =
      let
        val assocOptExp =
            optionExp (Option.map translateAssoc assocOpt) assocTy loc
        val expListExp =
            expsToListExp
                formatExpressionTy (translateFormatExpressions loc expList)
      in
        constructExp
            PT.guardConPathInfo
            []
            (SOME
                 (U.listToTupleExp
                      [(assocOptExp, assocOptTy), (expListExp, expListTy)]
                      loc))
            loc
      end
    | translateFormatExpression loc (FE.Indicator {space, newline}) =
      constructExp
          PT.indicatorConPathInfo
          []
          (SOME
               (U.listToRecordExp
                    [
                      ("space", constBoolExp space, PT.boolty),
                      (
                        "newline",
                        optionExp
                            (Option.map translatePriorityRec newline)
                            priorityRecTy loc,
                        priorityRecOptTy
                      )
                    ]
                    loc))
          loc
    | translateFormatExpression loc FE.Newline =
      constructExp PT.newlineConPathInfo [] NONE loc
    | translateFormatExpression loc (FE.StartOfIndent n) =
      constructExp PT.startOfIndentConPathInfo [] (SOME(constIntExp n)) loc
    | translateFormatExpression loc (FE.EndOfIndent) =
      constructExp PT.endOfIndentConPathInfo [] NONE loc

  and translateFormatExpressions loc (expressions as expression :: _) =
      map (translateFormatExpression loc) expressions
    | translateFormatExpressions loc nil =
      raise
        Control.Bug
            "nil expression to translateFormatExpressions \
            \(printergeneration/main/ObjectCode.sml)"

  fun makeConstantTerm string =
      translateFormatExpression Loc.noloc (FE.Term(size string, string))

  fun makeGuard (assocOpt, TPExpressions) =
      let
        val assocOptExp =
            optionExp (Option.map translateAssoc assocOpt) assocTy Loc.noloc
        val expLisExp = 
            expsToListExp formatExpressionTy TPExpressions
      in
        constructExp
            PT.guardConPathInfo
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


  fun printString (string, loc) =
      printFormat (translateFormatExpression loc (FE.Term(size string, string)))

  fun printFormatStatic expressions =
      printString (FEToString expressions, Loc.noloc)

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

  fun preformat formatExpressions =
      let
        (* 7 = size "val : " + 1 *)
        val width = if !Control.printWidth > 7
                    then !Control.printWidth - 7
                    else !Control.printWidth
        val params = [SMLFormat.Columns width]
        val str = SMLFormat.prettyPrint params formatExpressions
        val lines = String.fields (fn c => c = #"\n") str
        val newline = FE.Indicator {space = false,
                                    newline = SOME {priority = FE.Preferred 1}}
        fun toFE nil = nil
          | toFE [x] = [FE.Term (size x, x)]
          | toFE (h::t) = FE.Term (width, h) :: newline :: toFE t
        val format = FE.Guard (NONE, toFE lines)
      in
        translateFormatExpression Loc.noloc format
      end

end
end
