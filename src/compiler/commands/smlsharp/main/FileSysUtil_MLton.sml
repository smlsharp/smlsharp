(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: FileSysUtil_MLton.sml,v 1.4 2007/02/23 12:39:17 kiyoshiy Exp $
 *)
structure FileSysUtil =
struct

  structure MPO = MLton.Platform.OS
  structure PF = Posix.FileSys

  fun setFileModeExecutable fileName =
      case MPO.host of
        MPO.Cygwin => ()
      | MPO.MinGW => ()
      | _ =>        
        let
          val stat = PF.stat fileName
          val mode = PF.ST.mode stat
        in
          PF.chmod (fileName, PF.S.flags [mode, PF.S.ixusr])
        end
  val PathSeparator = 
      case MPO.host of
        MPO.Cygwin => #";"
      | MPO.MinGW => #";"
      | _ => #":"

end;
