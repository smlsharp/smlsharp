(**
 * libm.sml
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: libm.sml,v 1.2 2007/03/29 17:00:08 katsu Exp $
 *)

structure Libm =
struct

  local
    open CConfig
    open DynamicLink

    val libmName =
        valOf (findLibrary ("m","sin",["math.h"]))
(*
    (* Mac OS X *)
    val libmName = "/usr/lib/libSystem.B.dylib"
*)
(*
    (* MinGW *)
    val libmName = "msvcrt.dll"
*)

    val libm = dlopen libmName
  in

  (* ANSI *)
  val sin = dlsym (libm, "sin") : _import (real) -> real
  val log10 = dlsym (libm, "log10") : _import (real) -> real

  end

end
