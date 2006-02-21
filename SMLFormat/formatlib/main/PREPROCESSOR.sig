(**
 *  This module translates FormatExpression.expression into
 * PrettyPrinter.symbol.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PREPROCESSOR.sig,v 1.1 2006/02/07 12:51:52 kiyoshiy Exp $
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

  (***************************************************************************)

  (**
   *  translates a FormatExpression.expression into a PrettyPrinter.symbol.
   * @params parameter symbol
   * @param parameter parameters which control the printer
   * @param symbol a format expression
   * @return a PrettyPrinter.symbol translated from the symbol.
   *)
  val preProcess :
      PrinterParameter.printerParameter ->
      FormatExpression.expression ->
      PrettyPrinter.symbol

  (***************************************************************************)

end
