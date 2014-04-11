(**
 * OS.FileSys
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infix  6  + - ^
infixr 5 :: @
infix 4 = <> > >= < <=
infix 3 := o
val op - = SMLSharp_Builtin.Int.sub_unsafe
val op < = SMLSharp_Builtin.Int.lt
val op @ = List.@
structure Word = SMLSharp_Builtin.Word
structure Array = SMLSharp_Builtin.Array
structure String = SMLSharp_Builtin.String
structure Pointer = SMLSharp_Builtin.Pointer
structure Path = SMLSharp_SMLNJ_OS_Path

structure SMLSharp_OSFileSys =
struct

  val prim_opendir =
      _import "prim_GenericOS_opendir"
      : __attribute__((no_callback,suspend)) string -> unit ptr
  val prim_readdir =
      _import "prim_GenericOS_readdir"
      : __attribute__((no_callback,alloc,suspend)) unit ptr -> char ptr
  val prim_rewinddir =
      _import "prim_GenericOS_rewinddir"
      : __attribute__((no_callback,suspend)) unit ptr -> ()
  val prim_closedir =
      _import "prim_GenericOS_closedir"
      : __attribute__((no_callback,suspend)) unit ptr -> int

  type dirstream = {dirHandle : unit ptr, isOpen : bool ref}

  fun openDir dirname =
      let val dirHandle = prim_opendir dirname
      in if dirHandle = _NULL then raise SMLSharp_Runtime.OS_SysErr ()
         else {dirHandle = dirHandle, isOpen = ref true}
      end

  fun readDir {dirHandle, isOpen} =
      if !isOpen
      then SMLSharp_Runtime.str_new_option (prim_readdir dirHandle)
      else raise SMLSharp_Runtime.SysErr ("readdir on closed dirstream", NONE)

  fun rewindDir {dirHandle, isOpen} =
      if !isOpen
      then prim_rewinddir dirHandle
      else raise SMLSharp_Runtime.SysErr ("rewinddir on closed dirstream", NONE)

  fun closeDir {dirHandle, isOpen} =
      if !isOpen
      then (prim_closedir dirHandle; isOpen := false)
      else ()

  val prim_chdir =
      _import "prim_GenericOS_chdir"
      : __attribute__((no_callback,suspend)) string -> int
  val prim_getcwd =
      _import "prim_GenericOS_getcwd"
      : __attribute__((no_callback,alloc)) () -> char ptr
  val prim_mkdir =
      _import "prim_GenericOS_mkdir"
      : __attribute__((no_callback,suspend)) (string, int) -> int
  val prim_rmdir =
      _import "rmdir"
      : __attribute__((no_callback,suspend)) string -> int

  fun chDir dirname =
      if prim_chdir dirname < 0
      then raise SMLSharp_Runtime.OS_SysErr () else ()

  fun getDir () =
      let
        val ret = prim_getcwd ()
      in
        case SMLSharp_Runtime.str_new_option ret of
          NONE => raise SMLSharp_Runtime.OS_SysErr ()
        | SOME s => (SMLSharp_Runtime.free ret; s)
      end

  fun mkDir dirname =
      if prim_mkdir (dirname, 511 (*0777*)) < 0
      then raise SMLSharp_Runtime.OS_SysErr () else ()

  fun rmDir dirname =
      if prim_rmdir dirname < 0
      then raise SMLSharp_Runtime.OS_SysErr () else ()

  fun statWithTest filename =
      SOME (SMLSharp_OSIO.stat filename)
      handle e as SMLSharp_Runtime.SysErr (_, err) =>
             case err of
               NONE => raise e
             | SOME _ =>
               if err = SMLSharp_Runtime.syserror "noent" then NONE
               else if err = SMLSharp_Runtime.syserror "perm" then NONE
               else raise e

  fun isDir filename =
      Word.andb (#mode (SMLSharp_OSIO.stat filename), SMLSharp_OSIO.S_IFMT)
      = SMLSharp_OSIO.S_IFDIR

  fun isLink filename =
      Word.andb (#mode (SMLSharp_OSIO.lstat filename), SMLSharp_OSIO.S_IFMT)
      = SMLSharp_OSIO.S_IFLNK

  val prim_readlink =
      _import "prim_GenericOS_readlink"
      : __attribute__((no_callback,alloc,suspend)) string -> string

  fun readLink filename =
      let
        val ret = prim_readlink filename
      in
        if Pointer.identityEqual (String.castToBoxed ret, _NULL)
        then raise SMLSharp_Runtime.OS_SysErr () else ret
      end

  fun fullPath path =
      let
        val cwd = getDir ()
        fun makePath (revArcs, vol) =
            Path.toString {isAbs = true, arcs = List.rev revArcs, vol = vol}
        fun walk (0, _, _, _) =
            raise SMLSharp_Runtime.SysErr ("too many links", NONE)
          | walk (n, path, vol, nil) = makePath (path, vol)
          | walk (n, path, vol, ""::t) = walk (n, path, vol, t)
          | walk (n, path, vol, "."::t) = walk (n, path, vol, t)
          | walk (n, nil, vol, ".."::t) = walk (n, nil, vol, t)
          | walk (n, _::r, vol, ".."::t) = walk (n, r, vol, t)
          | walk (n, path, vol1, h::t) =
            let
              val filename = makePath (h::path, vol1)
            in
              if isLink filename then
                let
                  val {isAbs, arcs, vol} = Path.fromString (readLink filename)
                  val rest = arcs @ t
                  val (path, vol) = if isAbs then (arcs, vol) else (path, vol1)
                in
                  walk (n - 1, path, vol, rest)
                end
              else walk (n, h::path, vol1, t)
            end
        val maxLinks = 64
      in
        case Path.fromString path of
          {isAbs=true, arcs, vol} => walk (maxLinks, [], vol, arcs)
        | {isAbs=false, arcs=arcs2, ...} =>
          let
            val {arcs=arcs1, vol, ...} = Path.fromString (getDir ())
          in
            walk (maxLinks, [], vol, arcs1 @ arcs2)
          end
      end

  fun realPath path =
      if Path.isAbsolute path
      then fullPath path
      else Path.mkRelative {path = fullPath path,
                            relativeTo = fullPath (getDir ())}

  fun modTime filename =
      Time.fromSeconds
        (LargeInt.fromInt (Word.toIntX (#mtime (SMLSharp_OSIO.stat filename))))

  fun fileSize filename =
      Word.toIntX (#size (SMLSharp_OSIO.stat filename))

  val prim_utime =
      _import "prim_GenericOS_utime"
      : __attribute__((no_callback,suspend)) (string, word, word) -> int

  fun setTime (filename, timeOpt) =
      let
        val time =
            case timeOpt of
              SOME time => time
            | NONE => Time.now ()
        val t = Word.fromInt (LargeInt.toInt (Time.toSeconds time))
        val err = prim_utime (filename, t, t)
      in
        if err < 0 then raise SMLSharp_Runtime.OS_SysErr () else ()
      end

  val unlink =
      _import "unlink"
      : __attribute__((no_callback,suspend)) string -> int

  fun remove filename =
      if unlink filename < 0
      then raise SMLSharp_Runtime.OS_SysErr () else ()

  val prim_rename =
      _import "rename"
      : __attribute__((no_callback,suspend)) (string, string) -> int

  fun rename {old, new} =
      if prim_rename (old, new) < 0
      then raise SMLSharp_Runtime.OS_SysErr () else ()

  datatype access_mode = A_READ | A_WRITE | A_EXEC

  fun access (filename, modes) =
      case statWithTest filename of
        NONE => false
      | SOME {mode,...} =>
        let
          fun loop (nil, z) = z
            | loop (h::t, z) =
              Word.orb (z, case h of A_READ => SMLSharp_OSIO.S_IRUSR
                                   | A_WRITE => SMLSharp_OSIO.S_IWUSR
                                   | A_EXEC => SMLSharp_OSIO.S_IXUSR)
          val mask = loop (modes, 0w0)
        in
          Word.andb (mode, mask) = mask
        end

  val prim_tmpName =
      _import "prim_tmpName"
      : __attribute__((no_callback,alloc,suspend)) () -> string

  fun tmpName () =
      case prim_tmpName () of
        "" => raise SMLSharp_Runtime.OS_SysErr ()
      | x => x

  type file_id = SMLSharp_OSIO.stat

  val fileId = SMLSharp_OSIO.stat

  fun hash ({dev, ino, ...}:file_id) =
      Word.add (Word.lshift (dev, 0w16), ino)

  val op < = Word.lt
  val op > = Word.gt

  fun compare ({dev=dev1, ino=ino1, ...}:file_id,
               {dev=dev2, ino=ino2, ...}:file_id) =
      if dev1 < dev2 then General.LESS
      else if dev1 > dev2 then General.GREATER
      else if ino1 < ino2 then General.LESS
      else if ino1 > ino2 then General.GREATER
      else General.EQUAL

end
