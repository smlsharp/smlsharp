(**
 * a simple interpreter of file path string.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PATH_RESOLVER.sig,v 1.6 2007/04/19 13:50:43 kiyoshiy Exp $
 *)
signature PATH_RESOLVER =
sig

  (***************************************************************************)

  (**
   * resolve path to an an absolute path.
   * <ol>
   *   <li>replaces variable names with their values obtained by the
   *     getVariable function.</li>
   *   <li>If the path obtained by (1) is absolute path, and it points to an
   *     existing file, returns it. If not found, raise a
   *     TopLevelError.InvalidPath.
   *   <li>If the path obtained by (1) is relative path which begins with
   *     '.' or '..', interprets the path relative to basedir.
   *     If it points to an existing file, returns it. Raises
   *     a TopLevelError.InvalidPath, otherwise. </li>
   *   <li>Otherwise, concats a path at the top of the search path list
   *     and the path obtained by (1).
   *     If the path points to an existing file, returns it.
   *     Otherwise, it tries next path in the search path list.</li>
   * </ol>
   * Following literals have special meaning in pathlist and path parameter.
   * <dl>
   *   <dt>${PWD}</dt>
   *   <dd>${PWD} is replaced with the current working directory of the
   *     compiler.</dd>
   *   <dt>.</dt>
   *   <dd>'.' which appears at the beginning of paths in pathlist and path
   *     is replaced with basedir. </dd>
   *   <dt>..</dt>
   *   <dd>'..' which appears at the beginning of paths in pathlist and path
   *     is replaced with the parent directory of basedir. </dd>
   * </dl>
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
