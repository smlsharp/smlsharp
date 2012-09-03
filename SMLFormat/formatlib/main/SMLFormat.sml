(**
 * Pretty-printer library for Standard ML.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SMLFormat.sml,v 1.1 2006/02/07 12:51:53 kiyoshiy Exp $
 *)
structure SMLFormat :> SMLFORMAT =
struct

  (***************************************************************************)

  structure FormatExpression = FormatExpression

  structure PrinterParameter = PrinterParameter

  structure BasicFormatters = BasicFormatters

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
           | PrettyPrinter.Fail message =>
             raise Fail ("in print:" ^ message)

  (***************************************************************************)

end