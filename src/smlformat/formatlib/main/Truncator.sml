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
        fun takeHead _ accum [] = List.rev accum
          | takeHead 0 accum symbols =
            (List.rev accum) @ elision :: (List.filter keepSymbol symbols)
          | takeHead w accum ((symbol as FE.Term _) :: symbols) =
            takeHead (w - 1) (symbol :: accum) symbols
          | takeHead w accum ((symbol as FE.Guard _) :: symbols) =
            takeHead (w - 1) (symbol :: accum) symbols
          | takeHead w accum (symbol :: symbols) =
            takeHead w (symbol :: accum) symbols
        fun visit depth (FE.Guard (enclosedAssocOpt, symbols)) =
            if isCutOffDepth depth
            then elision
            else
              let
                val symbols' = 
                    map
                        (visit (depth + 1)) 
                        (case #maxWidthOfGuards parameter of
                           NONE => symbols
                         | SOME width => takeHead width [] symbols)
              in
                FE.Guard (enclosedAssocOpt, symbols')
              end
          | visit depth symbol = symbol
      in
        visit 0 symbol
      end
  end

  (***************************************************************************)

end;