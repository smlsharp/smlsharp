(**
 * Utility functions for file path manipulation.
 * <p>
 * NOTE: This structure has nothing to do with the module path.
 * It is the Path structure in "path" module that defines functions for that
 * purpose.
 * </p>
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PathUtility.sml,v 1.3 2007/09/19 05:28:55 matsu Exp $
 *)
structure PathUtility : PATH_UTILITY =
struct

  (***************************************************************************)

  fun trPath path =
      String.translate
          (fn #"\\" => "/" | ch => String.str ch)
          path

  fun isAbsolute path =
      if OS.Path.isAbsolute path
      then
        (* Unix absolute path on Unix, or Windows absolute path on cygwin *)
        true
      else
        if #"/" = String.sub(path, 0)
        then true (* Unix style absolute path on cygwin(ex "/home/yamato") *)
        else
          if "" <> OS.Path.getVolume path
          then true (* Windows style absolute path, but separated by "/" *)
          else false

  (**
   * convert path string to absolute path.
   * <p>
   *  When operating on cygwin environment, it is convenient to specify
   * paths of source files in Unix style such as "/home/yamato/".
   *  If the argument path is in Unix style, this function converts it to
   * Windows style path.
   *  But on Windows, OS.FileSys.fullPath can recognizes absolute path strings
   * in Unix style, but OS.Path.isAbsolute/isRelative does not consider
   * those paths as absolute path.
   * </p>
   * <p>
   *  This function considers paths beginning with the "/" as absolute paths.
   * </p>
   *)
  fun makeAbsolute {dir, path} =
      (OS.Path.mkCanonical
           (OS.FileSys.fullPath
                (trPath
                     (if isAbsolute path
                      then path
                      else OS.Path.concat(dir, path)))))
      handle OS.SysErr _ =>
             raise Fail (path ^ " does not exist.")

  fun collectFilesInDir filter directoryPath =
      let
        val dirStream = OS.FileSys.openDir directoryPath
        fun collect sourceNames =
            case OS.FileSys.readDir dirStream of
              (* For Basis Library of New Version
              NONE => sourceFiles
            | SOME entryName =>
               *)
              NONE (*""*) => List.rev sourceNames
            | SOME entryName =>
              if filter entryName
              then collect (entryName :: sourceNames)
              else collect sourceNames
      in
        collect []
      end

  (**
   * similar with OS.Path.splitDirFile.
   * But this version recognizes both "/" and "\\" as separator.
   * <pre>
   *   "D:/foo/bar/hoge.txt"  ==> {dir = "D:/foo/bar", file = "hoge.txt"}
   *   "D:/foo/bar\hoge.txt"  ==> {dir = "D:/foo/bar/hoge", file = "hoge.txt"}
   * </pre>
   *)
  fun splitDirFile path =
      let
        val pathSize = size path
        fun findSep ~1 = NONE
          | findSep n =
            case String.sub(path, n) of
              #"/" => SOME n
            | #"\\" => SOME n
            | _ => findSep (n - 1)
      in
        case findSep (pathSize - 1) of
          NONE => {dir = "", file = path}
        | SOME 0 => {dir = "/", file = path}
        | SOME pos =>
          {
            dir = String.extract(path, 0, SOME pos),
            file = String.extract(path, pos + 1, NONE)
          }
      end

(*
  (* NOTE : this function use always "/". *)
  fun joinDirFile {dir, file} =
      if String.sub(dir, size dir - 1) = #"/"
      then dir ^ file
      else dir ^ "/" ^ file
*)
  fun joinDirFile arg = trPath (OS.Path.joinDirFile arg)

  val splitBaseExt = OS.Path.splitBaseExt

  val joinBaseExt = OS.Path.joinBaseExt

  (***************************************************************************)

end
