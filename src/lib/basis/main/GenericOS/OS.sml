(**
 * OS structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OS.sml,v 1.2 2005/08/23 05:04:10 kiyoshiy Exp $
 *)
structure OS : OS =
struct

  (***************************************************************************)

  type syserror = int
  fun errorName syserror = GenericOS_errorName syserror
  fun syserror name = GenericOS_syserror name
  fun errorMsg syserror = GenericOS_errorMsg syserror
(*
  exception SysErr of string * syserror option
*)
  exception SysErr = SysErr

  structure FileSys = OS_FileSys
  structure Path = OS_Path
  structure Process = OS_Process
  structure IO = OS_IO

  (***************************************************************************)

end;