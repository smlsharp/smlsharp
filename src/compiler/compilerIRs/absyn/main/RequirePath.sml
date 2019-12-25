(*
 * interpret file paths that are used in _require and _use
 * @copyright (c) 2019, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure RequirePath =
struct

  (*
   * While the notation of file paths depends on the kind of operating systems
   * (for example, path separator character is different between Unix and
   * Windows), the file paths used in _require and _use are system-independent
   * notation so that SML# source files are portable among operating systems.
   *
   * A _require file path sequence of "components" (in terms of URL), each of
   * which is separated by a sequence of one or more slash (/) characters.
   * Each component must not be empty.  Neithter empty path (there is no
   * component), absolute paths (a path whose first compoent is empty), nor
   * directory paths (a path whose last component is empty) is allowed.
   * "." and ".." are special components: "." indicates current directory and
   * ".." means parent direcotory.  Since directory paths are not allowed,
   * paths ended with neither "." nor ".." is allowed.
   *
   * A _require file path is parsed, normalized, and then converted to
   * the file path of the current operating system.  The normalization
   * is performed as follows:
   * (1) Obtain component list by splitting the given path by a slash.
   * (2) If the first or last component is empty, report an error.
   * (3) Remove all empty components.
   * (4) If there is a "." in the component list, remove the ".".
   * (5) Goto (3) until no "." is found in the component list.
   * (6) If the last component is "..", report an error.
   *
   * Note that ".." in the middle of path is not deleted; "a/c" and "a/b/../c"
   * have different meaning under the existence of symbolic links.
   *)

  type path = string list

  fun fromString string = String.fields (fn c => c = #"/") string

  fun toString path = String.concatWith "/" path

  fun format_path path =
      SMLFormat.BasicFormatters.format_list
        (SMLFormat.BasicFormatters.format_string,
         SMLFormat.BasicFormatters.format_string "/")
        path

  fun beginsWithDot ("." :: _) = true
    | beginsWithDot (".." :: _) = true
    | beginsWithDot _ = false

  fun prependDot nil = nil
    | prependDot (l as ("" :: _)) = l
    | prependDot (l as ("." :: _)) = l
    | prependDot (l as (".." :: _)) = l
    | prependDot path = "." :: path

  datatype reason =
      EmptyPath
    | AbsolutePath
    | DirectoryPath

  exception Path of reason

  fun normalize path =
      case path of
        nil => raise Path DirectoryPath
      | "" :: t => normalize t
      | "." :: t => normalize t
      | ".." :: t => Filename.dotdot :: normalize t
(*
      | x :: ".." :: t => normalize t
*)
      | x :: nil => Filename.fromString x :: nil
      | x :: t => Filename.fromString x :: normalize t

  fun toFilename path =
      case path of
        nil => raise Path EmptyPath
      | "" :: nil => raise Path EmptyPath
      | "" :: _ :: _ => raise Path AbsolutePath
      | components =>
        case normalize components of
          nil => raise Path EmptyPath
        | h :: t => foldl (fn (x, z) => Filename.concatPath (z, x)) h t

end
