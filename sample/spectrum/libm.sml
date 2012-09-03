(**
 * libm.sml
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: libm.sml,v 1.2 2007/03/29 17:00:08 katsu Exp $
 *)

structure Libm =
struct

  (* ANSI *)
  val sin = _import "sin" : (real) -> real
  val log10 = _import "log10" : (real) -> real

end
