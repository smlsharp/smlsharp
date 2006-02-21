(**
 * parameter for pretty-printer.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PrinterParameter.sml,v 1.1 2006/02/07 12:51:53 kiyoshiy Exp $
 *)
structure PrinterParameter : PRINTER_PARAMETER =
struct

  (***************************************************************************)

  type printerParameter =
       {
         newlineString : string,
         spaceString : string,
         columns : int
       }

  (***************************************************************************)

end