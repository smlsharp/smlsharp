(**
 * Copyright (c) 2006, Tohoku University.
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

end;
