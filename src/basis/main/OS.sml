(**
 * OS structure.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "OS.smi"

structure OS :> OS
  where type syserror = SMLSharpRuntime.syserror
  where type IO.iodesc = SMLSharpSMLNJ_OS_IO.iodesc
=
struct

  structure FileSys = SMLSharpSMLNJ_OS_FileSys
  structure IO = SMLSharpSMLNJ_OS_IO
  structure Path = SMLSharpSMLNJ_OS_Path
  structure Process = SMLSharpOSProcess

  open SMLSharpRuntime

end
