(**
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: OS.sml,v 1.1 2006/10/27 14:06:25 kiyoshiy Exp $
 *)
structure OS =
struct
  open OS
  structure FileSys =
  struct
    open FileSys
    val readDir = fn arg => case readDir arg of "" => NONE | s => SOME s
  end
  structure Process =
  struct
    open Process
    fun sleep _ = (raise Fail "sorry, unimplemented") : unit
  end
end;
