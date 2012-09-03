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

  val sqrt = SMLSharp.Runtime.Math_sqrt

  val sin = SMLSharp.Runtime.Math_sin
  val cos = SMLSharp.Runtime.Math_cos
  val tan = SMLSharp.Runtime.Math_tan

  val asin = SMLSharp.Runtime.Math_asin
  val acos = SMLSharp.Runtime.Math_acos

  val atan = SMLSharp.Runtime.Math_atan

  val atan2 = SMLSharp.Runtime.Math_atan2

  val exp = SMLSharp.Runtime.Math_exp

  val pow = SMLSharp.Runtime.Math_pow

  val ln = SMLSharp.Runtime.Math_ln
  val log10 = SMLSharp.Runtime.Math_log10

  val sinh = SMLSharp.Runtime.Math_sinh
  val cosh = SMLSharp.Runtime.Math_cosh
  val tanh = SMLSharp.Runtime.Math_tanh

  (***************************************************************************)

end
