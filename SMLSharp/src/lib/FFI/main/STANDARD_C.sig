(**
 * This module provides common functions for using Standard C library.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: STANDARD_C.sig,v 1.1 2006/11/04 13:16:37 kiyoshiy Exp $
 *)
signature STANDARD_C =
sig

  (**
   * obtains the current value of the global variable 'errno' declared in
   * errno.h .
   *)
  val errno : unit -> int

end;