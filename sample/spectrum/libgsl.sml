(**
 * libgsl.sml
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @version $Id: libgsl.sml,v 1.4 2007/06/18 08:42:07 katsu Exp $
 *)

structure GSL =
struct

  val fft_real_radix2_transform =
      _import "gsl_fft_real_radix2_transform"
      : (real array, int, int) -> int

end
