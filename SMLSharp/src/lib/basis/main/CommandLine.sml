(**
 * This module provides access to the name and arguments used to invoke the
 * currently running program.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: CommandLine.sml,v 1.2 2008/01/12 09:27:58 kiyoshiy Exp $
 *)
structure CommandLine : COMMAND_LINE =
struct

  (***************************************************************************)

  fun name () = SMLSharp.Runtime.CommandLine_name 0
  fun arguments () =
      let
        val array = SMLSharp.Runtime.CommandLine_arguments 0
        val list = Array.foldr (op ::) [] array
      in
        list
      end

  (***************************************************************************)

end