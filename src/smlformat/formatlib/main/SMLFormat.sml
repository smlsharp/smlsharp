(**
 * Pretty-printer library for Standard ML.
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 * @version $Id: SMLFormat.sml,v 1.4 2008/02/28 13:08:30 kiyoshiy Exp $
 *)
(*
  2012-11-5 ohori
  deleted signature constraint.
  With the constraint, one cannot specify structure replication in
  the interface file, since signature constraint in general generate
  code and therefore cannot be identical to the original.
  Also, for the top-level file with smi specificatinon, signature 
  constraint is not important.
*)
structure SMLFormat (* : SMLFORMAT *) = 
struct

  (***************************************************************************)

  structure FormatExpression = FormatExpression

  structure PrinterParameter = PrinterParameter

  structure BasicFormatters = BasicFormatters

  (***************************************************************************)

  datatype parameter = datatype PrinterParameter.parameter

  type format = FormatExpression.expression list

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

  fun prettyPrint1 parameter expressions =
      (trace "pretty-print" (PrettyPrinter.format parameter)
       o trace "preprocess" (PreProcessor.preProcess parameter)
       o trace "assocResolve" (AssocResolver.resolve parameter)
       o trace "truncate" (Truncator.truncate parameter))
        (FormatExpression.Guard(NONE, expressions))
      handle PreProcessor.Fail message =>
             raise Fail ("in preprocess:" ^ message)
           | PreProcessor.UnMatchEndOfIndent message =>
             raise Fail message
           | PrettyPrinter.UnMatchEndOfIndent =>
             raise Fail "unmatched EndOfIndent"
           | PrettyPrinter.IndentUnderFlow indent =>
             raise Fail ("indent underflow(" ^ Int.toString indent ^ ")")

  fun prettyPrint parameters expressions =
      case PrinterParameter.convert parameters of
        {newlineString = "\n", spaceString = " ", columns,
         guardLeft = "(", guardRight = ")",
         maxDepthOfGuards = NONE, maxWidthOfGuards = NONE,
         cutOverTail = false, outputFunction} =>
        PrettyPrinter2.format
          {outputFn = outputFunction, width = columns}
          expressions
      | parameters =>
        prettyPrint1 parameters expressions

  (***************************************************************************)
  

end
