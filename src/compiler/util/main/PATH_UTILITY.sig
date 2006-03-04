(**
 * Utility functions for path manipulation.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PATH_UTILITY.sig,v 1.8 2006/03/01 08:55:47 kiyoshiy Exp $
 *)
signature PATH_UTILITY =
sig

  (***************************************************************************)

  val isAbsolute : string -> bool

  (**
   * convert a path to its absolute form.
   * Example. 
   * <pre>
   * makeAbsolute "/foo/bar" "boo.sml" ==> "/foo/bar/boo.sml"
   * makeAbsolute "/foo/bar" "/boo.sml" ==> "/boo.sml"
   * </pre>
   * @params directory path
   * @param directory the directory used as base if path is relative.
   * @param path the path to be converted into absolute.
   * @return SOME absolute path equivalent to the path parameter.
   *         NONE if the file does not exist.
   *)
  val makeAbsolute : string -> string -> string option

  val collectFilesInDir : (string -> bool) -> string -> string list

  val joinBaseExt : {base:string, ext:string option} -> string

  val joinDirFile : {dir:string, file:string} -> string

  val splitBaseExt : string -> {base:string, ext:string option}

  val splitDirFile : string -> {dir:string, file:string}

  (***************************************************************************)

end
