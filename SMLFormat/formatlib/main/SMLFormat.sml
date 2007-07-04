(**
 * Pretty-printer library for Standard ML.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SMLFormat.sml,v 1.3 2007/05/30 14:18:31 kiyoshiy Exp $
 *)
structure SMLFormat :> SMLFORMAT =
struct

  (***************************************************************************)

  structure FormatExpression = FormatExpression

  structure PrinterParameter = PrinterParameter

  structure BasicFormatters = BasicFormatters

  (***************************************************************************)

  datatype parameter = datatype PrinterParameter.parameter

  (***************************************************************************)

  exception Fail of string

  (***************************************************************************)

  fun prettyPrint parameter expressions =
      (PrettyPrinter.format
       parameter
       (PreProcessor.preProcess
        parameter (FormatExpression.Guard(NONE, expressions))))
      handle PreProcessor.Fail message =>
             raise Fail ("in preoprocess:" ^ message)
           | PreProcessor.UnMatchEndOfIndent message =>
             raise Fail message
           | PrettyPrinter.UnMatchEndOfIndent =>
             raise Fail "unmatched EndOfIndent"
           | PrettyPrinter.IndentUnderFlow indent =>
             raise Fail ("indent underflow(" ^ Int.toString indent ^ ")")

  (***************************************************************************)

end