(* posix.sig
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * Signature for POSIX 1003.1 binding
 *
 *)

signature POSIX =
  sig

    structure Error   : POSIX_ERROR
    structure Signal  : POSIX_SIGNAL
    structure Process : POSIX_PROCESS
    structure ProcEnv : POSIX_PROC_ENV
    structure FileSys : POSIX_FILE_SYS
    structure IO      : POSIX_IO
    structure SysDB   : POSIX_SYS_DB
    structure TTY     : POSIX_TTY

    sharing type Process.pid = ProcEnv.pid = TTY.pid
        and type Process.signal = Signal.signal
        and type ProcEnv.file_desc = FileSys.file_desc = TTY.file_desc
        and type FileSys.open_mode = IO.open_mode
        and type ProcEnv.uid = FileSys.uid = SysDB.uid
        and type ProcEnv.gid = FileSys.gid = SysDB.gid

  end (* signature POSIX *)

