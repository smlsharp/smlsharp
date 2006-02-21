(**
 * Copyright (c) 2006, Tohoku University.
 *
 * This module collects system dependent entities.
 *
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
