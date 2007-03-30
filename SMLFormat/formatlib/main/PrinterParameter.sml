(**
 * parameter for pretty-printer.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PrinterParameter.sml,v 1.2 2007/01/30 13:27:05 kiyoshiy Exp $
 *)
structure PrinterParameter : PRINTER_PARAMETER =
struct

  (***************************************************************************)

  val defaultNewline = "\n"
  val defaultSpace = " "
  val defaultColumns = 80
  val defaultGuardLeft = "("
  val defaultGuardRight = ")"

  datatype parameter =
           Newline of string
         | Space of string
         | Columns of int
         | GuardLeft of string
         | GuardRight of string

  (***************************************************************************)

end