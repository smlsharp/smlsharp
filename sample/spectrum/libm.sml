(**
 * libm.sml
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: libm.sml,v 1.1.2.1 2007/03/26 06:26:50 katsu Exp $
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
    val libcName = "/usr/lib/libSystem.B.dylib"
*)
    val libm = dlopen libmName
  in

  (* ANSI *)
  val sin = dlsym (libm, "sin") : _import (real) -> real
  val log10 = dlsym (libm, "log10") : _import (real) -> real

  end

end
