(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: FileSysUtil_SMLSharp.sml,v 1.1 2007/08/11 11:32:59 kiyoshiy Exp $
 *)
structure FileSysUtil =
struct

  structure MPO = SMLSharp.Platform.OS

  fun setFileModeExecutable fileName =
      case MPO.host of
        MPO.Cygwin => ()
      | MPO.MinGW => ()
      | _ =>
        (* ToDo : call chmod to set exec-bit of the file. *)
        (
          print
              ("sorry, you have to set execution bit of "
               ^ fileName ^ " by yourself.\n");
          ()
        )

  val PathSeparator = 
      case MPO.host of
        MPO.Cygwin => #";"
      | MPO.MinGW => #";"
      | _ => #":"

end;
