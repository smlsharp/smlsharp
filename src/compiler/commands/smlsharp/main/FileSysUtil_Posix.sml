(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: FileSysUtil_Posix.sml,v 1.4 2007/02/23 12:32:37 kiyoshiy Exp $
 *)
structure FileSysUtil =
struct

  structure PF = Posix.FileSys

  fun setFileModeExecutable fileName =
      let
        val stat = PF.stat fileName
        val mode = PF.ST.mode stat
      in
       PF.chmod (fileName, PF.S.flags [mode, PF.S.ixusr])
      end
  val PathSeparator = #":"

end;
