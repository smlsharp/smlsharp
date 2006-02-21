(**
 * Copyright (c) 2006, Tohoku University.
 *
 * a simple interpreter of file path string.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PATH_RESOLVER.sig,v 1.4 2006/02/18 04:59:29 ohori Exp $
 *)
signature PATH_RESOLVER =
sig

  (***************************************************************************)

  (**
   * 
   * <ol>
   *   <li>replaces variable names with their values obtained by the
   *     getVariable function.</li>
   *   <li>If the path obtained by (1) is absolute path, and it points to an
   *     existing file, returns it. If not found, raise a
   *     TopLevelError.InvalidPath.
   *   <li>If the path is relative, concats a path in the search path list
   *     and the path obtained by (1).
   *     If the path points to an existing file, returns it.
   *     Otherwise, it tries next path in the search path list.</li>
   * </ol>
   * @params getVariable pathlist basedir path
   * @param getVariable a function which returns a string value of a variable.
   * @param pathlist a list of search path.
   * @param basedir filepath
   * @return resolved file path
   * @exception TopLevelError.InvalidPath raised if resolution is impossible.
   *)
  val resolve :
      (** getVariable *) (string -> string option)
      -> (** search path list *) string list
      -> (** base directory *) string
      -> (** file path *) string
      -> string

  (***************************************************************************)

end
