(**
 * parameter for pretty-printer.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PRINTER_PARAMETER.sig,v 1.2 2007/01/30 13:27:05 kiyoshiy Exp $
 *)
signature PRINTER_PARAMETER =
sig

  (***************************************************************************)

  (** Its value is "\n". *)
  val defaultNewline : string
  (** Its value is " ". *)
  val defaultSpace : string
  (** Its value is 80. *)
  val defaultColumns : int
  (** Its value is "(". *)
  val defaultGuardLeft : string
  (** Its value is ")". *)
  val defaultGuardRight : string

  datatype parameter =
           (** a string used to begin a new line. 
            * For example, "\n" or "&lt;br&gt;".
            *)
           Newline of string
         | (** a string used to insert a space.
            * For example, " " or "&amp;nbsp;".
            * The specified string is considered to occupy 1 column in the
            * formatted output.
            *)
           Space of string
         | (** the desired number of columns in which the output is formatted.
            *)
           Columns of int
         | (** a string to be used to enclose at the left side of Guard.
            * For example, "(" or "[".
            * The specified string is considered to occupy 1 column in the
            * formatted output. *)
           GuardLeft of string
         | (** a string to be used to enclose at the right side of Guard.
            * For example, ")" or "]".
            * The specified string is considered to occupy 1 column in the
            * formatted output. *)
           GuardRight of string

  (***************************************************************************)

end