(**
 * Math structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Math.sml,v 1.3 2005/09/10 06:45:34 kiyoshiy Exp $
 *)
structure Math =
struct

  (***************************************************************************)

  type real = real

  (***************************************************************************)

  val pi = 3.14159265359

  val e = 2.71828182846

  val sqrt = Math_sqrt

  val sin = Math_sin
  val cos = Math_cos
  val tan = Math_tan

  val asin = Math_asin
  val acos = Math_acos

  val atan = Math_atan

  val atan2 = Math_atan2

  val exp = Math_exp

  val pow = Math_pow

  val ln = Math_ln
  val log10 = Math_log10

  val sinh = Math_sinh
  val cosh = Math_cosh
  val tanh = Math_tanh

  (***************************************************************************)

end
