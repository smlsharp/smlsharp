(**
 * utilities for OS_FileSys structure.
 * @author AT&T Bell Laboratories.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OS_FileSys.sml,v 1.7 2007/07/06 14:39:04 kiyoshiy Exp $
 *)
_interface "SMLSharpOSFileSys.smi"

structure SMLSharpOSFileSys :> sig

  type file_desc = int
  datatype iodesc = IODesc of file_desc

  type dirstream
  val opendir : string -> dirstream
  val readdir : dirstream -> string option
  val rewinddir : dirstream -> unit
  val closedir : dirstream -> unit
  val chdir : string -> unit
  val getcwd : unit -> string
  val mkdir : string * int -> unit
  val rmdir : string -> unit
  val readlink : string -> string

  type stat
  val stat : string -> stat
  val lstat : string -> stat
  val fstat : file_desc -> stat
  structure ST : sig
    val isDir : stat -> bool
    val isLink : stat -> bool
    val isReg : stat -> bool
    val isChr : stat -> bool
    val isBlk : stat -> bool
    val isFIFO : stat -> bool
    val isSock : stat -> bool
    val size : stat -> Position.int
    val mtime : stat -> Time.time
    val ino : stat -> word
    val dev : stat -> word
  end
  val utime : string * {actime: Time.time, modtime: Time.time} option -> unit
  val unlink : string -> unit
  val rename : {old: string, new: string} -> unit

  datatype access_mode = A_READ | A_WRITE | A_EXEC
  val access : string * access_mode list -> bool
  val tmpName : unit -> string

  val stdin : file_desc
  val stdout : file_desc
  val stderr : file_desc
  type whence
  val SEEK_SET : whence
  val SEEK_CUR : whence

  val close : file_desc -> unit
  val openf : string * string -> file_desc
  val lseek : file_desc * Position.int * whence -> Position.int
  val readVec : file_desc * int -> Word8Vector.vector
  val readArr : file_desc * Word8ArraySlice.slice -> int
  val writeVec : file_desc * Word8VectorSlice.slice -> int
  val writeArr : file_desc * Word8ArraySlice.slice -> int

end =
struct

  infixr 5 ::
  infix 4 < =
  infix 3 :=
  val op < = SMLSharp.Int.lt

  val prim_opendir =
      _import "prim_GenericOS_opendir"
      : __attribute__((no_callback)) string -> unit ptr
  val prim_readdir =
      _import "prim_GenericOS_readdir"
      : __attribute__((no_callback,alloc)) unit ptr -> char ptr
  val prim_rewinddir =
      _import "prim_GenericOS_rewinddir"
      : __attribute__((no_callback)) unit ptr -> unit
  val prim_closedir =
      _import "prim_GenericOS_closedir"
      : __attribute__((no_callback)) unit ptr -> int
                                                 
  type file_desc = int
  datatype iodesc = IODesc of file_desc

  type dirstream = {dirHandle : unit ptr, isOpen : bool ref}

  fun opendir dirname =
      let val dirHandle = prim_opendir dirname
      in if dirHandle = _NULL then raise SMLSharpRuntime.OS_SysErr ()
         else {dirHandle = dirHandle, isOpen = ref true}
      end
  fun readdir {dirHandle, isOpen = ref true} =
      SMLSharpRuntime.str_new_option (prim_readdir dirHandle)
    | readdir _ =
      raise SMLSharpRuntime.SysErr ("readdir on closed dirstream", NONE)
  fun rewinddir {dirHandle, isOpen = ref true} =
      prim_rewinddir dirHandle
    | rewinddir _ =
      raise SMLSharpRuntime.SysErr ("rewinddir on closed dirstream", NONE)
  fun closedir {dirHandle, isOpen as ref true} =
      (prim_closedir dirHandle; isOpen := false)
    | closedir _ = ()
                   
  val prim_chdir =
      _import "prim_GenericOS_chdir"
      : __attribute__((no_callback)) string -> int
  val prim_getcwd =
      _import "prim_GenericOS_getcwd"
      : __attribute__((no_callback,alloc)) () -> char ptr
  val prim_mkdir =
      _import "prim_GenericOS_mkdir"
      : __attribute__((no_callback)) (string, int) -> int
  val prim_rmdir =
      _import "rmdir"
      : __attribute__((no_callback)) string -> int
                                               
  fun chdir dirname =
      if prim_chdir dirname < 0
      then raise SMLSharpRuntime.OS_SysErr () else ()
  fun getcwd () =
      let
        val ret = prim_getcwd ()
      in
        case SMLSharpRuntime.str_new_option ret of
          NONE => (SMLSharpRuntime.free ret;
                   raise SMLSharpRuntime.OS_SysErr ())
        | SOME s => (SMLSharpRuntime.free (SMLSharp.Pointer.toUnitPtr ret); s)
      end
  fun mkdir (dirname, mode) =
      if prim_mkdir (dirname, mode) < 0
      then raise SMLSharpRuntime.OS_SysErr () else ()
  fun rmdir dirname =
      if prim_rmdir dirname < 0
      then raise SMLSharpRuntime.OS_SysErr () else ()
                                                   
  val prim_stat =
      _import "prim_GenericOS_stat"
      : __attribute__((no_callback))
        (string, word array) -> int
  val ya_GenericOS_fstat =
      _import "prim_GenericOS_fstat"
      : __attribute__((no_callback))
        (int, word array) -> int
                             
  val S_IFMT   = 0wxf000 : word
  val S_IFIFO  = 0wx1000 : word
  val S_IFCHR  = 0wx2000 : word
  val S_IFDIR  = 0wx4000 : word
  val S_IFBLK  = 0wx6000 : word
  val S_IFREG  = 0wx8000 : word
  val S_IFLNK  = 0wxa000 : word
  val S_IFSOCK = 0wxc000 : word
  val S_ISUID  = 0wx0800 : word
  val S_ISGID  = 0wx0400 : word
  val S_ISVTX  = 0wx0200 : word
  val S_IRUSR  = 0wx0100 : word
  val S_IWUSR  = 0wx0080 : word
  val S_IXUSR  = 0wx0040 : word

  type stat =
      {dev: word, ino: word, mode: word, atime: word, mtime: word, size: word}

  fun toStat ary =
      {dev = SMLSharp.PrimArray.sub (ary, 0),
       ino = SMLSharp.PrimArray.sub (ary, 1),
       mode = SMLSharp.PrimArray.sub (ary, 2),
       atime = SMLSharp.PrimArray.sub (ary, 3),
       mtime = SMLSharp.PrimArray.sub (ary, 4),
       size = SMLSharp.PrimArray.sub (ary, 5)} : stat

  fun stat filename =
      let
        val ary = SMLSharp.PrimArray.allocArray 6
        val err = prim_stat (filename, ary)
      in
        if err < 0 then raise SMLSharpRuntime.OS_SysErr () else ();
        toStat ary
      end

  fun fstat fd =
      let
        val ary = SMLSharp.PrimArray.allocArray 6
        val err = ya_GenericOS_fstat (fd, ary)
      in
        if err < 0 then raise SMLSharpRuntime.OS_SysErr () else ();
        toStat ary
      end

  (* FIXME *)
  val lstat = stat

  structure ST =
  struct
    fun isDir ({mode,...}:stat) =
        SMLSharp.Word.andb (mode, S_IFMT) = S_IFDIR
    fun isLink ({mode,...}:stat) =
        SMLSharp.Word.andb (mode, S_IFMT) = S_IFLNK
    fun isReg ({mode,...}:stat) =
        SMLSharp.Word.andb (mode, S_IFMT) = S_IFREG
    fun isChr ({mode,...}:stat) =
        SMLSharp.Word.andb (mode, S_IFMT) = S_IFCHR
    fun isBlk ({mode,...}:stat) =
        SMLSharp.Word.andb (mode, S_IFMT) = S_IFBLK
    fun isFIFO ({mode,...}:stat) =
        SMLSharp.Word.andb (mode, S_IFMT) = S_IFIFO
    fun isSock ({mode,...}:stat) =
        SMLSharp.Word.andb (mode, S_IFMT) = S_IFSOCK
    fun size ({size,...}:stat) =
        Position.fromInt (SMLSharp.Word.toIntX size)
    fun mtime ({mtime,...}:stat) =
        Time.fromSeconds (LargeInt.fromInt (SMLSharp.Word.toIntX mtime))
    fun dev ({dev,...}:stat) = dev
    fun ino ({ino,...}:stat) = ino
  end

  fun statWithTest filename =
      SOME (stat filename)
      handle e as SMLSharpRuntime.SysErr (_, err) =>
             case err of
               NONE => raise e
             | SOME _ =>
               if err = SMLSharpRuntime.syserror "noent" then NONE
               else if err = SMLSharpRuntime.syserror "perm" then NONE
               else raise e

  datatype access_mode = A_READ | A_WRITE | A_EXEC

  fun access (filename, modes : access_mode list) =
      case statWithTest filename of
        NONE => false
      | SOME {mode,...} =>
        let
          fun loop (nil, z) = z
            | loop (h::t, z) =
              let
                val h = case h of A_READ => S_IRUSR
                                | A_WRITE => S_IWUSR
                                | A_EXEC => S_IXUSR
              in
                loop (t, SMLSharp.Word.orb (h, z))
              end
          val mask = loop (modes, 0w0)
        in
          SMLSharp.Word.andb (mode, mask) = mask
        end

  val prim_utime =
      _import "prim_GenericOS_utime"
      : __attribute__((no_callback)) (string, word, word) -> int
                                                             
  fun utime (filename, timeOpt) =
      let
        val (atime, mtime) =
            case timeOpt of
              SOME {actime, modtime} => (actime, modtime)
            | NONE => let val now = Time.now () in (now, now) end
        fun timeToWord t =
            SMLSharp.Word.fromInt (LargeInt.toInt (Time.toSeconds t))
        val err = prim_utime (filename, timeToWord atime, timeToWord mtime)
      in
        if err < 0 then raise SMLSharpRuntime.OS_SysErr () else ()
      end
        
  val prim_readlink =
      _import "prim_GenericOS_readlink"
      : __attribute__((no_callback,alloc)) string -> string
                                                     
  fun readlink filename =
      let
        val ret = prim_readlink filename
      in
        if SMLSharp.identityEqual (SMLSharp.PrimString.toBoxed ret, _NULL)
        then raise SMLSharpRuntime.OS_SysErr () else ret
      end
        
  val prim_remove =
      _import "remove"
      : __attribute__((no_callback)) string -> int
  val prim_rename =
      _import "rename"
      : __attribute__((no_callback)) (string, string) -> int
                                                         
  fun unlink filename =
      if prim_remove filename < 0
      then raise SMLSharpRuntime.OS_SysErr () else ()
  fun rename {old, new} =
      if prim_rename (old, new) < 0
      then raise SMLSharpRuntime.OS_SysErr () else ()

  val prim_tmpName =
      _import "prim_tmpName"
      : __attribute__((no_callback,alloc)) () -> string

  fun tmpName () =
      case prim_tmpName () of
        "" => raise SMLSharpRuntime.OS_SysErr ()
      | x => x

  val stdin = 0 : file_desc
  val stdout = 1 : file_desc
  val stderr = 2 : file_desc
  type whence = int
  val SEEK_SET = SMLSharpRuntime.cconstInt "SEEK_SET" : whence
  val SEEK_CUR = SMLSharpRuntime.cconstInt "SEEK_CUR" : whence

  val prim_close =
      _import "close"
      : __attribute__((no_callback)) int -> int
  val prim_fopen =
      _import "prim_GenericOS_open"
      : __attribute__((no_callback)) (string, string) -> int
  val prim_lseek =
      _import "prim_GenericOS_lseek"
      : __attribute__((no_callback)) (int, int, int) -> int

  fun close fd =
      if prim_close fd < 0 then raise SMLSharpRuntime.OS_SysErr () else ()

  fun openf (filename, mode) =
      let
        val fd = prim_fopen (filename, mode)
      in
        if fd < 0 then raise SMLSharpRuntime.OS_SysErr () else fd
      end

  fun lseek (fd, pos, whence) =
      let
        val ret = prim_lseek (fd, Position.toInt pos, whence)
      in
        if ret < 0 then raise SMLSharpRuntime.OS_SysErr ()
        else Position.fromInt ret
      end

  val prim_readVec =
      _import "prim_GenericOS_read"
      : __attribute__((no_callback))
        (int, string, word, word) -> int
  val prim_readAry =
      _import "prim_GenericOS_read"
      : __attribute__((no_callback))
        (int, Word8Array.array, word, word) -> int
  val prim_writeVec =
      _import "prim_GenericOS_write"
      : __attribute__((no_callback))
        (int, Word8Vector.vector, word, word) -> int
  val prim_writeAry =
      _import "prim_GenericOS_write"
      : __attribute__((no_callback))
        (int, Word8Array.array, word, word) -> int

  fun readVec (fd, len) =
      if len < 0 then raise Size else
      let
        val buf = SMLSharp.PrimString.allocArray len
        val n = prim_readVec (fd, buf, 0w0, Word.fromInt len)
      in
        if n < 0 then raise SMLSharpRuntime.OS_SysErr () else
        let
          val ret = SMLSharp.PrimString.allocVector n
        in
          SMLSharp.PrimString.copy_unsafe (buf, 0, ret, 0, n);
          Byte.stringToBytes ret
        end
      end

  fun readArr (fd, slice) =
      let
        val (buf, beg, len) = Word8ArraySlice.base slice
        val n = prim_readAry (fd, buf, Word.fromInt beg, Word.fromInt len)
      in
        if n < 0 then raise SMLSharpRuntime.OS_SysErr () else n
      end

  fun writeVec (fd, slice) =
      let
        val (buf, beg, len) = Word8VectorSlice.base slice
        val n = prim_writeVec (fd, buf,
                               SMLSharp.Word.fromInt beg,
                               SMLSharp.Word.fromInt len)
      in
        if n < 0 then raise SMLSharpRuntime.OS_SysErr () else n
      end

  fun writeArr (fd, slice) =
      let
        val (buf, beg, len) = Word8ArraySlice.base slice
        val n = prim_writeAry (fd, buf,
                               SMLSharp.Word.fromInt beg,
                               SMLSharp.Word.fromInt len)
      in
        if n < 0 then raise SMLSharpRuntime.OS_SysErr () else n
      end

end
