(**
 * This module truncates symbols beyond the depth and width of Guards
 * specified by user parameter.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: PreProcessor.sml,v 1.7 2010/02/09 07:53:18 katsu Exp $
 *)
structure Truncator =
struct

  (***************************************************************************)

  structure FE = FormatExpression

  (***************************************************************************)

  local
    val elision =
(*
        FE.Term (3, "...")
*)
        FE.Guard
            (
              NONE,
              [
                FE.Indicator
                    {space = true, newline = SOME{priority = FE.Deferred}},
                FE.Term (3, "...")
              ]
            )

    fun snoc nil x = [x]
      | snoc l x = [FE.Sequence l, x]

    fun filterFE f nil nil r = r
      | filterFE f nil (h :: t) r =
        filterFE f h t r
      | filterFE f (FE.Sequence x :: t) k r =
        filterFE f x (t :: k) r
      | filterFE f (h :: t) k r =
        filterFE f t k (if f h then snoc r h else r)
    val filterFE = fn f => fn l => fn k => filterFE f l k nil

  in
  (**
   * truncates symbols beyond the depth and width of Guards specified by
   * maxDepthOfGuards and maxWidthOfGuards parameters.
   *)
  fun truncate {maxDepthOfGuards = NONE, maxWidthOfGuards = NONE, ...} symbol =
      symbol
    | truncate (parameter : PrinterParameter.parameterRecord) symbol =
      let
        val isCutOffDepth =
            case #maxDepthOfGuards parameter of
              NONE => (fn _ => false)
            | SOME depth => (fn d => depth <= d)
        fun keepSymbol (FE.StartOfIndent _) = true
          | keepSymbol FE.EndOfIndent = true
          | keepSymbol _ = false
        fun takeHead d _ accum nil nil = accum
          | takeHead d 0 accum symbols k =
            FE.Sequence accum
            :: elision
            :: filterFE keepSymbol symbols k
          | takeHead d w accum nil (h :: t) =
            takeHead d w accum h t
          | takeHead d w accum (FE.Sequence x :: t) k =
            takeHead d w accum x (t :: k)
          | takeHead d w accum ((symbol as FE.Term _) :: symbols) k =
            takeHead d (w - 1) (visit (d + 1) symbol :: accum) symbols k
          | takeHead d w accum ((symbol as FE.Guard _) :: symbols) k =
            takeHead d (w - 1) (visit (d + 1) symbol :: accum) symbols k
          | takeHead d w accum (symbol :: symbols) k =
            takeHead d w (visit (d + 1) symbol :: accum) symbols k
        and visit depth (FE.Guard (enclosedAssocOpt, symbols)) =
            if isCutOffDepth depth
            then elision
            else FE.Guard
                   (enclosedAssocOpt,
                    case #maxWidthOfGuards parameter of
                      NONE => symbols
                    | SOME width => takeHead depth width nil symbols nil)
          | visit depth symbol = symbol
      in
        visit 0 symbol
      end
  end

  (***************************************************************************)

end;
