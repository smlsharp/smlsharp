(**
 * Utility functions for path manipulation.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PATH_UTILITY.sig,v 1.3 2007/01/01 05:03:59 kiyoshiy Exp $
 *)
signature PATH_UTILITY =
sig

  (***************************************************************************)

  (**
   * substitute '\' in the path to '/'.
   *)
  val trPath : string -> string

  val isAbsolute : string -> bool

  (**
   * convert a path to its absolute form.
   * Example. 
   * <pre>
   * makeAbsolute {dir = "/foo/bar", path = "boo.sml"} ==> "/foo/bar/boo.sml"
   * makeAbsolute {dir = "/foo/bar", path = "/boo.sml"} ==> "/boo.sml"
   * </pre>
   * @params {dir, path}
   * @param dir the directory used as base if path is relative.
   * @param path the path to be converted into absolute.
   * @return absolute path equivalent to the path parameter.
   * @throws SysErr if the file does not exist.
   *)
  val makeAbsolute : {dir : string, path : string} -> string

  val collectFilesInDir : (string -> bool) -> string -> string list

  val joinBaseExt : {base:string, ext:string option} -> string

  val joinDirFile : {dir:string, file:string} -> string

  val splitBaseExt : string -> {base:string, ext:string option}

  val splitDirFile : string -> {dir:string, file:string}

  (***************************************************************************)

end
