(**
 * OS_FileSys structure.
 * @author AT&T Bell Laboratories.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OS_FileSys.sml,v 1.6 2005/08/27 10:03:39 kiyoshiy Exp $
 *)
(* os-filesys.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * The Posix implementation of the generic file system interface.
 *
 *)
structure OS_FileSys : OS_FILE_SYS =
struct

  (***************************************************************************)

  val sysWordToWord = Word.fromLargeWord o SysWord.toLargeWord

  (********************)

  type dirstream = {dirHandle : word, isOpen : bool ref}

  fun openDir path = 
      let val dirHandle = GenericOS_openDir path
      in {dirHandle = dirHandle, isOpen = ref true}
      end
  fun readDir {dirHandle, isOpen = ref true} = 
      GenericOS_readDir dirHandle
    | readDir {isOpen = ref false, ...} = 
      raise SysErr ("readDir on closed dirstream", NONE)
  fun rewindDir {dirHandle, isOpen = ref true} = 
      GenericOS_rewindDir dirHandle
    | rewindDir {isOpen = ref false, ...} = 
      raise SysErr ("rewindDir on closed dirstream", NONE)
  fun closeDir {dirHandle, isOpen} = 
      case isOpen of
        ref true => (GenericOS_closeDir dirHandle; isOpen := false)
      | ref false => ()

  (********************)

  val chDir = GenericOS_chDir : string -> unit
  val getDir = fn () => (GenericOS_getDir : int -> string) 0
  val mkDir = GenericOS_mkDir : string -> unit

  val rmDir = GenericOS_rmDir : string -> unit
  val isDir = GenericOS_isDir : string -> bool

  (********************)

  val isLink = GenericOS_isLink : string -> bool
  val readLink = GenericOS_readLink : string -> string

  val fileSize = GenericOS_getFileSize : string -> int
  fun modTime path =
      let val seconds = GenericOS_getFileModTime path
      in Time.fromSeconds seconds
      end
  fun setTime (path, timeOpt) =
      let
        val time = case timeOpt of NONE => Time.now () | SOME t => t
        val seconds = Time.toSeconds time
      in
        GenericOS_setFileTime(path, Time.toSeconds time)
      end
  val remove = GenericOS_remove : string -> unit
  fun rename {old, new} = GenericOS_rename (old, new)

  datatype access_mode = A_READ | A_WRITE | A_EXEC

  fun access (path, accesses) =
      case accesses of
        [] => GenericOS_isFileExists path
      | _ :: _ =>
        let
          fun checkPermission A_READ = GenericOS_isFileReadable path
            | checkPermission A_WRITE = GenericOS_isFileWritable path
            | checkPermission A_EXEC = GenericOS_isFileExecutable path
        in
          List.all (fn access => checkPermission access) accesses
        end

  (********************)

  structure P = OS_Path

  (* the maximum number of links allowed *)
  val maxLinks = 64

  (* A UNIX specific implementation of fullPath *)
  fun fullPath p =
      let
        val oldCWD = getDir()
        fun mkPath pathFromRoot =
            P.toString{isAbs = true, vol = "", arcs = List.rev pathFromRoot}
        fun walkPath (0, _, _) = raise SysErr("too many links", NONE)
          | walkPath (n, pathFromRoot, []) = mkPath pathFromRoot
          | walkPath (n, pathFromRoot, "" :: al) =
            walkPath (n, pathFromRoot, al)
          | walkPath (n, pathFromRoot, "." :: al) =
            walkPath (n, pathFromRoot, al)
          | walkPath (n, [], ".." :: al) = walkPath (n, [], al)
          | walkPath (n, _ :: r, ".." :: al) =
            (chDir ".."; walkPath (n, r, al))
          | walkPath (n, pathFromRoot, [arc]) =
            if (isLink arc)
            then expandLink (n, pathFromRoot, arc, [])
            else mkPath (arc :: pathFromRoot)
          | walkPath (n, pathFromRoot, arc::al) =
            if (isLink arc)
            then expandLink (n, pathFromRoot, arc, al)
            else (chDir arc; walkPath (n, arc::pathFromRoot, al))
        and expandLink (n, pathFromRoot, link, rest) = 
            case (P.fromString(readLink link))
             of {isAbs = false, arcs, ...} =>
                walkPath (n-1, pathFromRoot, List.@(arcs, rest))
              | {isAbs = true, arcs, ...} =>
                gotoRoot (n-1, List.@(arcs, rest))
        and gotoRoot (n, arcs) = (chDir "/"; walkPath (n, [], arcs))
        fun computeFullPath arcs =
            (gotoRoot(maxLinks, arcs) before chDir oldCWD)
            handle ex => (chDir oldCWD; raise ex)
      in
        case (P.fromString p)
         of {isAbs = false, arcs, ...} =>
            let val {arcs = arcs', ...} = P.fromString(oldCWD)
            in computeFullPath (List.@(arcs', arcs))
            end
          | {isAbs = true, arcs, ...} => computeFullPath arcs
      end

  fun realPath p =
      if (P.isAbsolute p)
      then fullPath p
      else P.mkRelative {path = fullPath p, relativeTo = fullPath(getDir())}

  val tmpName = GenericOS_tempFileName : unit -> string

  type file_id = Word.word

  fun fileId fname = GenericOS_getFileID fname

  fun hash fileID = fileID

  fun compare (fileID1 : file_id, fileID2) =
      if (Word.<(fileID1, fileID2))
      then General.LESS
      else
        if (Word.>(fileID1, fileID2))
        then General.GREATER
        else General.EQUAL

  (***************************************************************************)

end


