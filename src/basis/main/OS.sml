(**
 * OS
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

structure OS =
struct
  structure FileSys = SMLSharp_OSFileSys
  structure IO = SMLSharp_OSIO
  structure Path = SMLSharp_SMLNJ_OS_Path
  structure Process = SMLSharp_OSProcess
  open SMLSharp_Runtime
end
