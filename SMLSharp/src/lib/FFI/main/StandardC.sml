(**
 * This module provides common functions for using Standard C library.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: StandardC.sml,v 1.1 2006/11/04 13:16:37 kiyoshiy Exp $
 *)
structure StandardC : STANDARD_C =
struct

  fun errno () = SMLSharp.Runtime.StandardC_errno ()

end
