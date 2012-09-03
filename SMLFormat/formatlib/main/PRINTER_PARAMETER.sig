(**
 * parameter for pretty-printer.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PRINTER_PARAMETER.sig,v 1.1 2006/02/07 12:51:52 kiyoshiy Exp $
 *)
signature PRINTER_PARAMETER =
sig

  (***************************************************************************)

  type printerParameter =
       {
         (** string used as newline. *)
         newlineString : string,
         (** string used as space. *)
         spaceString : string,
         (** the number of columns. *)
         columns : int
       }

  (***************************************************************************)

end