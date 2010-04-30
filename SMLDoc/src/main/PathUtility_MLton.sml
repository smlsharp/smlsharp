(**
 * Utility functions for file path manipulation.
 * <p>
 * NOTE: This structure has nothing to do with the module path.
 * It is the Path structure in "path" module that defines functions for that
 * purpose.
 * </p>
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PathUtility_MLton.sml,v 1.3 2007/09/19 05:28:55 matsu Exp $
 *)
structure PathUtility : PATH_UTILITY =
struct

  (***************************************************************************)

  structure OP = OS.Path

  fun trPath path =
      String.translate
          (fn #"\\" => "/" | ch => String.str ch)
          path

  fun isAbsolute path = OP.isAbsolute path

  fun makeAbsolute {dir, path} =
      let
        val absPath = 
            if isAbsolute path
            then path
            else
              let
		val mkAbs = fn (path, dir) => OP.mkAbsolute {path = path, relativeTo = dir} 
                val absDir =
                    if isAbsolute dir
                    then dir
                    else mkAbs (dir, OS.FileSys.getDir ())
              in mkAbs (path, absDir) end
      in
        (* OS.SysErr is raised if not exist *)
        OS.FileSys.isDir absPath;
        absPath
      end
        handle OS.SysErr (message, err) => raise Fail (message ^ ":" ^ path)
             | OP.Path => raise Fail (path ^ " does not exist.")

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
  fun joinDirFile {dir, file} = trPath (OP.concat (dir, file))

  val splitBaseExt = OP.splitBaseExt

  val joinBaseExt = OP.joinBaseExt

  (***************************************************************************)

end
