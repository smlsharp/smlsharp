(**
 * libc.sml
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: libc.sml,v 1.2 2007/03/29 17:00:08 katsu Exp $
 *)


structure Libc =
struct

  type c_file = unit ptr

  (* ANSI *)
  val fopen   = _import "fopen" : (string, string) -> c_file
  val fclose  = _import "fclose" : (c_file) -> ()
  fun fread (a,len,c_file) =
      _ffiapply _import "fread"
        (a:'a array, _sizeof('a), len:int, c_file:c_file) : int

  fun memcpy (dst,src,len) =
      _ffiapply _import "memcpy"
        (dst:unit ptr, src:'a array, _sizeof('a) * len) : ()

  (* POSIX.1 *)
  val fdopen  = _import "fdopen" : (int, string) -> c_file

  (* BSD *)
  val usleep  = _import "usleep" : (int) -> int

  (*
   * Note for Windows users:
   * - msvcrt.dll has "_fdopen" but it is broken. Please use fopen instead of fdopen.
   * - Windows does not have usleep.
   *)

end
