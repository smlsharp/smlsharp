(**
 *  The top level module of the SMLDoc.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: SMLDOC.sig,v 1.2 2004/10/20 03:18:40 kiyoshiy Exp $
 *)
signature SMLDOC =
sig

  (***************************************************************************)

  (**
   *  makes documents describing the ML program.
   * @params parameter fileNames
   * @param parameter the global parameter
   * @param fileNames the names of files containing ML program.
   * @return unit
   *
   * @author YAMATODANI Kiyoshi
   * @version 1.0
   *)
  val makeDocument :
      DocumentGenerationParameter.parameter -> string list -> unit

  (***************************************************************************)

end