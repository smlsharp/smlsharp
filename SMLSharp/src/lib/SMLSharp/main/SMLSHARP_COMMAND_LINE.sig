(**
 * functions to access command line arguments.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSHARP_COMMAND_LINE.sig,v 1.1 2007/04/13 13:27:35 kiyoshiy Exp $
 *)
signature SMLSHARP_COMMAND_LINE =
sig

  (**
   * name of the executable image with which the smlsharp is invoked.
   * @return SOME(name) if smlsharp is invoked with an executable image which
   *         is specified with name. <br>
   *         NONE if smlsharp is invoked without any specific executable image
   *         (for example, running in the interactive mode).
   *)
  val executableImageName : unit -> string option

end
