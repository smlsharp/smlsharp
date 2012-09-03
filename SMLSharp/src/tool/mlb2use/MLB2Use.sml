(**
 * MLB2Use generates a list of "use" directives from MLton mlb files.
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MLB2Use.sml,v 1.5 2007/08/10 15:15:18 kiyoshiy Exp $
 *)
structure MLB2Use
  : sig
      val convert
          : {
              baseDirOpt : string option,
              excludeAbsPath : bool ,
              pathMapFileOpt : string option ,
              rootMLBFile : string,
              verbose : bool
            }
            -> string list
    end =
struct

  val isTrace = ref true
  fun trace msg =
      if !isTrace
      then TextIO.output(TextIO.stdErr, msg ^ "\n")
      else ()

  datatype fileType = MLB | CM | OTHER
  fun fileType path =
      case OS.Path.ext path of
        SOME "mlb" => MLB
      | SOME "cm" => CM
      | _ => OTHER

  fun trPath path =
      (* OS.Path of SML# accepts both '/' and '\\'. *)
      path
(* OS.Path of SML/NJ does not accept '/' as dir separator on Windows.
      String.translate (fn #"/" => "\\" | ch => String.str ch) path
*)

  fun convert
          {baseDirOpt, excludeAbsPath, pathMapFileOpt, rootMLBFile, verbose} =
      let
        val _ = isTrace := verbose
        val pathMap =
            case pathMapFileOpt
             of SOME pathMapFile => PathMap.new pathMapFile
              | NONE => PathMap.empty

        fun regularize {fileOrig, cwd} =
            let
              val fileOrig = trPath fileOrig
              val fileExp = PathMap.expand pathMap fileOrig
            in
              if String.isPrefix "${" fileExp
              then fileExp
              else
                let
                  val fileAbs =
                      OS.Path.mkAbsolute {path = fileExp, relativeTo = cwd}
                  val fileAbs = OS.Path.mkCanonical fileAbs
                in
                  fileAbs
                end
            end

        val rootMLB =
            regularize
                {fileOrig = rootMLBFile, cwd = trPath (OS.FileSys.getDir ())}
        val {dir = rootMLBdir, ...} = OS.Path.splitDirFile rootMLB
        val cwd =
            case baseDirOpt 
             of SOME baseDir => 
                regularize
                    {fileOrig = baseDir, cwd = trPath (OS.FileSys.getDir ())}
              | NONE => rootMLBdir

        fun mkRelative absPath =
            if String.isPrefix "${" absPath
            then absPath
            else
              let
                val relPath = 
                    OS.Path.mkRelative {path = absPath, relativeTo = cwd}
                    handle OS.Path.Path => absPath
              in
                if
                  OS.Path.isRelative relPath
                  andalso not (String.isPrefix "." relPath)
                then OS.Path.concat (".", relPath)
                else relPath
              end

        fun trans [] seenMLBs seenSMLs = List.rev seenSMLs
          | trans ((cwd, path) :: paths) seenMLBs seenSMLs =
            let
              val path = regularize {fileOrig = path, cwd = cwd}
            in
              if List.exists (fn x => x = path) seenMLBs
              then
                (
                  trace ("skip visited file: " ^ path);
                  trans paths seenMLBs seenSMLs
                )
              else 
                case fileType path
                 of OTHER => trans paths seenMLBs (path :: seenSMLs)
                  | ftype =>
                  let
                    val {dir = cwd, ...} = OS.Path.splitDirFile path
                    val files =
                        (case ftype 
                          of MLB => MLBParser.parseFile path
                           | CM => CMFileParser.readCMFile path
                           | _ => raise Fail "Bug:ftype")
                        handle e => (trace (exnMessage e); [])
                    val files = 
                        if excludeAbsPath
                        then List.filter (not o OS.Path.isAbsolute) files
                        else files
                    val files =
                        map
                            (fn file =>
                                regularize {cwd = cwd, fileOrig = file})
                            files
                    val newPaths = map (fn file => (cwd, file)) files
                  in
                    trans (newPaths @ paths) (path :: seenMLBs) seenSMLs
                  end
            end
        val absPaths = trans [(cwd, rootMLB)] [] []
        val relativePaths = map mkRelative absPaths
      in
        relativePaths
      end

end;
