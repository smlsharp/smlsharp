(**
 * a simple interpreter of file path string.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PathResolver.sml,v 1.7 2006/02/28 16:11:06 kiyoshiy Exp $
 *)
structure PathResolver : PATH_RESOLVER =
struct

  (***************************************************************************)

  structure PC = ParserComb
  structure PU = PathUtility
  structure TE = TopLevelError

  (***************************************************************************)

  fun isRBRACE #"}" = true
    | isRBRACE _ = false

  fun isDollar #"$" = true
    | isDollar _ = false

  fun isPSChar #"/" = true
    | isPSChar #"\\" = true
    | isPSChar _ = false

  fun scanPath reader stream =
      PC.wrap
          (PC.oneOrMore(PC.eatChar (not o isDollar)), implode)
          reader stream
  fun scanVariable getVariable reader stream =
      PC.wrap
          (
            PC.seqWith
                #2
                (
                  PC.string "${",
                  PC.seqWith
                      #1
                      (PC.oneOrMore(PC.eatChar (not o isRBRACE)), PC.char #"}")
                ),
            getVariable o implode
          )
          reader stream
  fun scan getVariable reader stream =
      PC.wrap
          (
            PC.oneOrMore(PC.or' [scanVariable getVariable, scanPath]),
            String.concat
          )
          reader stream

  local
    fun isRelativePath path =
        (String.isPrefix ".." path) orelse (String.isPrefix "." path)
    fun isFileExists path =
        (OS.FileSys.access (path, [OS.FileSys.A_READ]))
        handle OS.SysErr (message, err) => false
    fun findFileInPathList baseDir path [] = NONE
      | findFileInPathList baseDir path (loadPath :: loadPaths) =
        case 
          PU.makeAbsolute
              baseDir (PU.joinDirFile {dir = loadPath, file = path})
         of
          SOME absPath => SOME absPath
        | NONE => findFileInPathList baseDir path loadPaths
  in
  (**
   * resolves a path to an existing file.
   * <p>
   *  The path resolution takes two parameters: base directory and a load path
   * list.
   * In the following, assume that base directory is <code>/doo/bee</code>
   * and a load path list is <code>{/bro/sis, /mom/pap, .}</code> .
   * </p>
   * <p>
   * Paths are classified into the three types.
   * <dl>
   *   <dt>1, Absolute</dt>
   *   <dd>A full path from a root directory.
   *     <ul>
   *       <li>/foo/bar</li>
   *       <li>D:/foo/bar</li>
   *     </ul>
   *     </dd>
   *   <dt>2, Relative to the base directory</dt>
   *   <dd>A path beginning with "." or "..".
   *      It is interpreted as a path relative to the base directory.
   *     <ul>
   *       <li>./foo/bar</li>
   *       <li>../foo/bar</li>
   *     </ul>
   *      These are resolved to /doo/bee/foo/bar and /doo/foo/bar,
   *     respectively.
   *     </dd>
   *   <dt>3, Other</dt>
   *   <dd>A path in other form.
   *      It is searched for in each directory in the load path list.
   *     <ul>
   *       <li>foo/bar</li>
   *       <li>bar</li>
   *     </ul>
   *      Assumed that /mom/pap/foo/bar and /doo/bee/bar exist and that there
   *     are no other file, these are resolved to /mom/pap/foo/bar and
   *     /doo/bee/bar, respectively.
   *     </dd>
   * </dl>
   * </p>
   * @params getVariable loadPathList baseDir path
   * @param getVariable a function which gives a value of variable.
   * @param loadPathList a list of load paths, which are used to resolve the
   *                    third form path.
   * @param baseDir a base directory, which is used to resolve the second
   *               form path.
   * @param path a path
   * @return an absolute path to an existing file.
   * @exception TopLevelError.InvalidPath if no existing file is found.
   *)
  fun resolve getVariable loadPathList =
      let
        val getVariable' =
            fn name =>
               case getVariable name of
                 SOME value => value
               | NONE => raise TE.InvalidPath ("undefined variable: " ^ name)
      in
        fn baseDir =>
           fn path =>
              case StringCvt.scanString (scan getVariable') path of
                 NONE => raise TE.InvalidPath "invalid path format"
               | SOME parsedPath =>
                 (if PU.isAbsolute parsedPath
                  then (* 1st form *)
                    if isFileExists parsedPath
                    then parsedPath
                    else
                      raise
                        TE.InvalidPath
                            ("absolute path not found: " ^ parsedPath)
                  else
                    if isRelativePath parsedPath
                    then (* 2nd form *)
                      case PU.makeAbsolute baseDir parsedPath of
                        SOME absPath => absPath
                      | NONE =>
                        raise
                          TE.InvalidPath
                              ("file not found:" ^ parsedPath
                               ^ " in " ^ baseDir)
                    else
                      (* 3rd form *)
                      case 
                        findFileInPathList baseDir parsedPath loadPathList
                       of
                        SOME absPath => absPath
                      | NONE =>
                        raise
                          TE.InvalidPath
                              ("file not found in path list: " ^ path))
                 handle OS.SysErr (message, err) =>
                        raise TE.InvalidPath ("file not found: " ^ parsedPath)
      end
  end

  fun resolve' variables =
      let
        val variableMap =
            List.foldr
                (fn ((name, value), map) => SEnv.insert (map, name, value))
                SEnv.empty
                variables
        fun getVariable name = SEnv.find (variableMap, name)
      in resolve getVariable
      end

  (***************************************************************************)

end;
