(**
 * libc.sml
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: libc.sml,v 1.2 2007/03/29 17:00:08 katsu Exp $
 *)

structure Libc =
struct

  local
    open CConfig
    open DynamicLink

    val libcName =
        valOf (findLibrary ("c","fopen",["stdio.h"]))
(*
    (* Mac OS X *)
    val libcName = "/usr/lib/libSystem.B.dylib"
*)
(*
    (* MinGW *)
    val libcName = "msvcrt.dll"
*)

    val libc = dlopen libcName
  in

  type c_file = unit ptr

  (* ANSI *)
  val fopen   = dlsym (libc, "fopen") : _import (string, string) -> c_file
  val fclose  = dlsym (libc, "fclose") : _import (c_file) -> unit
  val c_fread = dlsym (libc, "fread")
  fun fread (a,len,c_file) =
      _ffiapply c_fread (a:'a array, _sizeof('a), len:int, c_file:c_file) : int

  val c_memcpy = dlsym (libc, "memcpy")
  fun memcpy (dst,src,len) =
      _ffiapply c_memcpy (dst:UnmanagedMemory.address,
                          src:'a array, _sizeof('a) * len) : unit

  (* POSIX.1 *)
  val fdopen  = dlsym (libc, "fdopen") : _import (int, string) -> c_file

  (* BSD *)
  val usleep  = dlsym (libc, "usleep") : _import (int) -> int

  (*
   * Note for Windows users:
   * - msvcrt.dll has "_fdopen" but it is broken. Please use fopen instead of fdopen.
   * - Windows does not have usleep.
   *)

  end

end
