(**
 * This module collects system dependent entities.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 *)
signature SYSTEMDEF =
sig

  (***************************************************************************)

  (**
   * native byte order of the platform.
   *)
  val NativeByteOrder : SystemDefTypes.byteOrder

  (***************************************************************************)

end
