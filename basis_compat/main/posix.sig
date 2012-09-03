signature POSIX =
  sig
    structure Error : POSIX_ERROR
    structure Signal : POSIX_SIGNAL
    structure Process : POSIX_PROCESS
    structure ProcEnv : POSIX_PROC_ENV
    structure FileSys : POSIX_FILE_SYS
    structure IO : POSIX_IO
    structure SysDB : POSIX_SYS_DB
    structure TTY : POSIX_TTY
    sharing type SysDB.gid = FileSys.gid = ProcEnv.gid
    sharing type SysDB.uid = FileSys.uid = ProcEnv.uid
    sharing type IO.open_mode = FileSys.open_mode
    sharing type TTY.file_desc = FileSys.file_desc = ProcEnv.file_desc
    sharing type Signal.signal = Process.signal
    sharing type TTY.pid = ProcEnv.pid = Process.pid
  end
