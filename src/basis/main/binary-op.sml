(**
 * binary operators.
 * @author UENO Katsuhiro
 * @copyright 2011, Tohoku University.
 *)
_interface "binary-op.smi"

infix 4 = <> > >= < <=

fun op <> (x, y) = if x = y then false else true
