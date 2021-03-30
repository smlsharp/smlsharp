(**
 * OS
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)

structure OS =
struct
  structure FileSys = SMLSharp_OSFileSys
  structure IO = SMLSharp_OSIO
  structure Path = SMLSharp_SMLNJ_OS_Path
  structure Process = SMLSharp_OSProcess
  open SMLSharp_Runtime
end
