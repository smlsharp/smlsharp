(**
 * Pretty-printer library for Standard ML.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: SMLFORMAT.sig,v 1.3 2008/03/01 00:51:27 kiyoshiy Exp $
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
   * verbosity of trace message.
   * No trace is output if 0.
   *)
  val traceLevel : int ref

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