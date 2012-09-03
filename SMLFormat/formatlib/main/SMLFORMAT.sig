(**
 * Pretty-printer library for Standard ML.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SMLFORMAT.sig,v 1.2 2007/01/30 13:27:05 kiyoshiy Exp $
 *)
signature SMLFORMAT =
sig

  (***************************************************************************)

  structure FormatExpression : FORMAT_EXPRESSION

  structure PrinterParameter : PRINTER_PARAMETER

  structure BasicFormatters : BASIC_FORMATTERS

  sharing type FormatExpression.expression = BasicFormatters.expression

  (***************************************************************************)

  datatype parameter = datatype PrinterParameter.parameter

  (***************************************************************************)

  (**
   * raised when any error occurs.
   * @params message
   * @param message the error message
   *)
  exception Fail of string

  (***************************************************************************)

  (**
   *  translates the format expressions into a text representation which
   * fits within the specified column width.
   * <p>
   *  This function tries to insert newline characters so that the text can
   * fit within the specified column width, but it may exceed the specified
   * column width if the column width is too small.
   * </p>
   * @params parameter expressions
   * @param parameter parameters which control the printer
   * @param expressions a list of format expressions.
   * @return the text representation of the expressions
   *)
  val prettyPrint :
      parameter list -> FormatExpression.expression list -> string

  (***************************************************************************)

end