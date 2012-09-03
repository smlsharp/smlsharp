(**
 * This module provides access to the name and arguments used to invoke the
 * currently running program.
 * @author YAMATODANI Kiyoshi
 * @version $Id: CommandLine.sml,v 1.1 2005/08/25 01:42:42 kiyoshiy Exp $
 *)
structure CommandLine : COMMAND_LINE =
struct

  (***************************************************************************)

  fun name () = CommandLine_name 0
  fun arguments () = CommandLine_arguments 0

  (***************************************************************************)

end;