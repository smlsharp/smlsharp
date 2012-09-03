(**
 * parameter for pretty-printer.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PrinterParameter.sml,v 1.4 2007/06/18 13:30:43 kiyoshiy Exp $
 *)
structure PrinterParameter : PRINTER_PARAMETER =
struct

  (***************************************************************************)

  val defaultNewline = "\n"
  val defaultSpace = " "
  val defaultColumns = 80
  val defaultGuardLeft = "("
  val defaultGuardRight = ")"
  val defaultMaxDepthOfGuards = NONE
  val defaultMaxWidthOfGuards = NONE
  val defaultCutOverTail = false

  datatype parameter =
           Newline of string
         | Space of string
         | Columns of int
         | GuardLeft of string
         | GuardRight of string
         | MaxDepthOfGuards of int option
         | MaxWidthOfGuards of int option
         | CutOverTail of bool

  (***************************************************************************)

end