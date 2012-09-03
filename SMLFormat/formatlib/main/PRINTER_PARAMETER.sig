(**
 * parameter for pretty-printer.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: PRINTER_PARAMETER.sig,v 1.4 2007/06/18 13:30:43 kiyoshiy Exp $
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
  (** Its value is NONE. *)
  val defaultMaxDepthOfGuards : int option
  (** Its value is NONE. *)
  val defaultMaxWidthOfGuards : int option
  (** Its value is false. *)
  val defaultCutOverTail : bool

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
         | (** specifies the maximum depth of nests of Guards to be formatted.
            * Guards nested at deeper than specified are discarded.
            * If NONE, Guards at every depth are formatted.
            *)
           MaxDepthOfGuards of int option
         | (** specifies the maximum elements of Guards to be formatted.
            * Only first elements of specified number are formatted.
            * If NONE, all of elements of Guards are formatted.
            *)
           MaxWidthOfGuards of int option
         | (** specifies whether to truncate tail-characters of each line
            * if they over the specified number of columns.
            *)
           CutOverTail of bool

  (***************************************************************************)

end