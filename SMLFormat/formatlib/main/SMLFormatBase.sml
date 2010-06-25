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

  structure Truncator = Truncator(FE)
  structure AssocResolver = AssocResolver(FE)
  structure PreProcessor = PreProcessor(FE)

  end

  (***************************************************************************)

  datatype parameter = datatype PrinterParameter.parameter

  (***************************************************************************)

  exception Fail of string

  (***************************************************************************)

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

  fun prettyPrint parameters expressions =
      let
        val parameter = PrinterParameter.convert parameters
      in
        (trace "pretty-print" (PrettyPrinter.format parameter)
         o trace "preprocess" (PreProcessor.preProcess parameter)
         o trace "assocResolve" (AssocResolver.resolve parameter)
         o trace "truncate" (Truncator.truncate parameter))
            (FormatExpression.Guard(NONE, expressions))
      end
        handle PreProcessor.Fail message =>
               raise Fail ("in preprocess:" ^ message)
             | PreProcessor.UnMatchEndOfIndent message =>
               raise Fail message
             | PrettyPrinter.UnMatchEndOfIndent =>
               raise Fail "unmatched EndOfIndent"
             | PrettyPrinter.IndentUnderFlow indent =>
               raise Fail ("indent underflow(" ^ Int.toString indent ^ ")")

  (***************************************************************************)

end;
