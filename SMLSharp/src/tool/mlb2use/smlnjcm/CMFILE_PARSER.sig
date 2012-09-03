(**
 * parser of SML/NJ CM description file.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: CMFILE_PARSER.sig,v 1.2 2004/10/20 03:26:07 kiyoshiy Exp $
 *)
signature CMFILE_PARSER =
sig

  (***************************************************************************)

  val isCMFileName : string -> bool

  val readCMFile : string -> string list

  (***************************************************************************)

end