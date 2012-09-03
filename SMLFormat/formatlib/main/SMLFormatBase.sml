(**
 * Pretty-printer library for Standard ML.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SMLFormatBase.sml,v 1.2 2008/03/01 00:51:27 kiyoshiy Exp $
 *)
functor SMLFormatBase(FT : FORMAT_EXPRESSION_TYPES)
        :> SMLFORMAT
               where type FormatExpression.expression = FT.expression
               where type FormatExpression.assocDirection = FT.assocDirection
               where type FormatExpression.priority = FT.priority =
struct

  (***************************************************************************)

  structure FormatExpression = FormatExpression(FT)

  structure PrinterParameter = PrinterParameter

  local
  structure FE = FormatExpression
  in

  structure BasicFormatters = BasicFormatters(FE)

  structure PrettyPrinter = PrettyPrinter(FE)

  structure PreProcessor =
            PreProcessor
                (struct structure FE = FE structure PP = PrettyPrinter end)

  end

  (***************************************************************************)

  datatype parameter = datatype PrinterParameter.parameter

  (***************************************************************************)

  exception Fail of string

  (***************************************************************************)

  (* another module so that other modules PrettyPrinter, PreProcessor *)
  val traceLevel = ref 0
  fun trace phase f arg =
      if !traceLevel = 0
      then f arg
      else
        (
          print ("[SMLFormat] begin " ^ phase ^ "\n");
          f arg
          before print ("[SMLFormat] end " ^ phase ^ "\n")
        )

  fun prettyPrint parameter expressions =
      (trace
           "pretty-print"
           (PrettyPrinter.format parameter)
           (trace
                "preprocess"
                (PreProcessor.preProcess parameter)
                (FormatExpression.Guard(NONE, expressions))))
      handle PreProcessor.Fail message =>
             raise Fail ("in preoprocess:" ^ message)
           | PreProcessor.UnMatchEndOfIndent message =>
             raise Fail message
           | PrettyPrinter.UnMatchEndOfIndent =>
             raise Fail "unmatched EndOfIndent"
           | PrettyPrinter.IndentUnderFlow indent =>
             raise Fail ("indent underflow(" ^ Int.toString indent ^ ")")

  (***************************************************************************)

end;
