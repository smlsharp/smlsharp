(**
 *  This module translates FormatExpression.expression into
 * PrettyPrinter.symbol.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PREPROCESSOR.sig,v 1.3 2007/05/30 14:18:31 kiyoshiy Exp $
 *)
signature PREPROCESSOR =
sig

  (***************************************************************************)

  (**
   * raised when any error occurs.
   * @params message
   * @param message the error message
   *)
  exception Fail of string

  (** the exception raised when the EndOfIndent with no matched
   * FormatIndicator is found.
   * @params message
   * @param message the error message
   *)
  exception UnMatchEndOfIndent of string

  (***************************************************************************)

  (**
   *  translates a FormatExpression.expression into a PrettyPrinter.symbol.
   * @params parameter symbol
   * @param parameter parameters which control the printer
   * @param symbol a format expression
   * @return a PrettyPrinter.symbol translated from the symbol.
   *)
  val preProcess :
      PrinterParameter.parameter list ->
      FormatExpression.expression ->
      PrettyPrinter.symbol

  (***************************************************************************)

end
