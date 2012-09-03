(* implementations of current primitives by new primitives *)

local
  (* FIXME: use NULL, but current NULL is an integer, not pointer. *)
  val isNull : unit ptr -> bool = ya_isNull

  fun ! (ref x) = x

  fun raiseSysErr () =
      let
        val errno = StandardC_errno ()
      in
        raise SysErr (ya_StandardC_strerror errno, SOME errno)
      end

  fun checkError (err:int) =
      if err < 0 then raiseSysErr () else ()

  fun checkErrorIfNull (ptr:unit ptr) =
      if isNull ptr then raiseSysErr () else ()
in

fun String_concat2 (x:string, y:string) : string =
    let
      val n1 = String_size x
      val n2 = String_size y
      val newstr = ya_String_allocateImmutableNoInit (Word_fromInt (n1 + n2))
    in
      String_copy (x, 0, newstr, 0, n1);
      String_copy (y, 0, newstr, n1, n2);
      newstr
    end

fun Real_split (x:real) : real * real =
    let
      val intg = ref 0.0
      val frac = ya_Real_modf (x, intg)
    in
      (frac, !intg)
    end

fun Real_toManExp (x:real) : real * int =
    let
      val exp = ref 0
      val man = ya_Real_frexp (x, exp)
    in
      (man, !exp)
    end

fun Time_gettimeofday (x:int) : int * int =
    let
      val ret = Array_mutableArray (2, 0)
      val err = ya_Time_gettimeofday ret
    in
      checkError err;
      (Array_sub (ret, 0), Array_sub (ret, 1))
    end
    handle SysErr (s,n) => raise SysErr (String_concat2("gettimeofday:",s),n)

fun CommandLine_arguments (x:int) : string array =
    let
      val argc = ya_CommandLine_argc ()
      val argv = Array_mutableArray (argc, "")
      fun f i =
          if i < argc
          then (Array_update (argv, i, ya_CommandLine_argv i);
                f (i+1))
          else ()
    in
      f 0; argv
    end
    handle SysErr (s,n) => raise SysErr (String_concat2("arguments:",s),n)

fun DynamicLink_dlopen (filename:string) : unit ptr =
    let
      val libhandle = ya_DynamicLink_dlopen filename
    in
      if isNull libhandle
      then raise SysErr (ya_DynamicLink_dlerror (), NONE)
      else libhandle
    end

fun DynamicLink_dlclose (libhandle:unit ptr) : unit =
    if ya_DynamicLink_dlclose libhandle < 0
    then raise SysErr (ya_DynamicLink_dlerror (), NONE)
    else ()

fun DynamicLink_dlsym (libhandle:unit ptr, symname:string) : unit ptr =
    let
      val ptr = ya_DynamicLink_dlsym (libhandle, symname)
    in
      if isNull libhandle
      then raise SysErr (ya_DynamicLink_dlerror (), NONE)
      else ptr
    end

fun GenericOS_syserror (errname:string) : int option =
    let
      val errno = ya_GenericOS_syserror errname
    in
      if errno < 0 then NONE else SOME errno
    end

val GenericOS_errorMsg : int -> string = ya_StandardC_strerror

fun GenericOS_getSTDIN (_:int) : word = 0w0
fun GenericOS_getSTDOUT (_:int) : word = 0w1
fun GenericOS_getSTDERR (_:int) : word = 0w2

fun GenericOS_fileOpen (filename:string, mode:string) : word =
    let
      val fd = ya_GenericOS_open (filename, mode)
    in
      checkError fd;
      Word_fromInt fd
    end

fun GenericOS_fileClose (fd:word) : unit =
    checkError (ya_GenericOS_close (Word_toIntX fd))

fun GenericOS_fileReadBuf (fd:word, buf, offset:int, len:int) : int =
    if offset < 0 orelse len < 0
    then raise SysErr ("invalid argument", NONE)
    else
      let
        val n = ya_GenericOS_read (Word_toIntX fd, buf, 0w0, Word_fromInt len)
      in
        checkError n;
        n
      end

fun GenericOS_fileRead (fd:word, len:int) : byteArray =
    if len < 0
    then raise SysErr ("invalid argument", NONE)
    else
      let
        val buf = ya_String_allocateMutableNoInit (Word_fromInt len)
        val n = GenericOS_fileReadBuf (fd, _cast(buf) : byteArray, 0, len)
      in
        if n = len
        then _cast(buf) : byteArray
        else
          let
            val dst = ya_String_allocateMutableNoInit (Word_fromInt n)
          in
            String_copy (buf, 0, dst, 0, n);
            _cast(dst) : byteArray
          end
      end

fun GenericOS_fileWrite (fd:word, buf:byteArray, offset:int, len:int) : int =
    if offset < 0 orelse len < 0
    then raise SysErr ("invalid argument", NONE)
    else
      let
        val n = ya_GenericOS_write (Word_toIntX fd, buf,
                                    Word_fromInt offset, Word_fromInt len)
      in
        checkError n;
        n
      end

fun GenericOS_fileSetPosition (fd:word, pos:int) : int =
    let
      val newpos = ya_GenericOS_lseekSet (Word_toIntX fd, pos)
    in
      checkError newpos;
      newpos
    end

fun GenericOS_fileGetPosition (fd:word) : int =
    let
      val pos = ya_GenericOS_lseekSet (Word_toIntX fd, 0)
    in
      checkError pos;
      pos
    end

fun GenericOS_fileNo (fd:word) : int = Word_toIntX fd

local
  val S_IFIFO  = 0wx1000
  val S_IFCHR  = 0wx2000
  val S_IFDIR  = 0wx4000
  val S_IFBLK  = 0wx6000
  val S_IFREG  = 0wx8000
  val S_IFLNK  = 0wxa000
  val S_IFSOCK = 0wxc000
  val S_ISUID  = 0wx0800
  val S_ISGID  = 0wx0400
  val S_ISVTX  = 0wx0200
  val S_IRUSR  = 0wx0100
  val S_IWUSR  = 0wx0080
  val S_IXUSR  = 0wx0040

  fun get_stat (ary:word array) =
      {dev = Array_sub (ary, 0),
       ino = Array_sub (ary, 1),
       mode = Array_sub (ary, 2),
       atime = Array_sub (ary, 3),
       mtime = Array_sub (ary, 4),
       size = Word_toIntX (Array_sub (ary, 5))}

  fun stat filename =
      let
        val st = Array_mutableArray (6, 0w0)
        val err = ya_GenericOS_stat (filename, st)
      in
        checkError err;
        get_stat st
      end

  fun fstat fd =
      let
        val st = Array_mutableArray (6, 0w0)
        val err = ya_GenericOS_fstat (Word_toIntX fd, st)
      in
        checkError err;
        get_stat st
      end

  fun test stat (fd, mask) =
      if Word_andb (#mode (stat fd), mask) = 0w0 then false else true
in

fun GenericOS_fileSize (fd:word) : int =
    #size (fstat fd)

fun GenericOS_isRegFD  (fd:word) : bool = test fstat (fd, S_IFREG)
fun GenericOS_isLinkFD (fd:word) : bool = test fstat (fd, S_IFLNK)
fun GenericOS_isDirFD  (fd:word) : bool = test fstat (fd, S_IFDIR)
fun GenericOS_isChrFD  (fd:word) : bool = test fstat (fd, S_IFCHR)
fun GenericOS_isBlkFD  (fd:word) : bool = test fstat (fd, S_IFBLK)
fun GenericOS_isFIFOFD (fd:word) : bool = test fstat (fd, S_IFIFO)
fun GenericOS_isSockFD (fd:word) : bool = test fstat (fd, S_IFSOCK)

fun GenericOS_isFileExists (filename:string) : bool =
    (* assume that fileStat raises an error if the file does not exist. *)
    (stat filename; true)

fun GenericOS_getFileModTime (filename:string) : int =
    Word_toIntX (#mtime (stat filename))

fun GenericOS_getFileSize (filename:string) : int =
    #size (stat filename)

fun GenericOS_isFileReadable (filename:string) : bool =
    test stat (filename, S_IRUSR)

fun GenericOS_isFileWritable (filename:string) : bool =
    test stat (filename, S_IWUSR)

fun GenericOS_isFileExecutable (filename:string) : bool =
    test stat (filename, S_IXUSR)

fun GenericOS_isLink (filename:string) : bool =
    test stat (filename, S_IFLNK)

fun GenericOS_isDir (filename:string) : bool =
    test stat (filename, S_IFDIR)

fun GenericOS_getFileID (filename:string) : word =
    (* this is temporary solution.
     * It can be possible that the same id is generated for multiple files. *)
    let
      val {ino, dev, ...} = stat filename
    in
      Word_orb (ino, Word_leftShift (dev, 0w24))
    end

fun GenericOS_setFileTime (filename:string, mtime:int) : unit =
    let
      val {atime, ...} = stat filename
      val err = ya_GenericOS_utime (filename, atime, Word_fromInt mtime)
    in
      checkError err
    end

end

fun GenericOS_remove (filename:string) : unit =
    checkError (ya_GenericOS_remove filename)

fun GenericOS_rename (filename:string, newfilename:string) : unit =
    checkError (ya_GenericOS_rename (filename, newfilename))

fun GenericOS_readLink (filename:string) : string =
    let
      val ret = ya_GenericOS_readlink filename
    in
      checkErrorIfNull (_cast(ret) : unit ptr);
      ret
    end

fun GenericOS_tempFileName () : string =
    let
      val ret = ya_GenericOS_tmpnam ()
    in
      checkErrorIfNull (_cast(ret) : unit ptr);
      ret
    end

fun GenericOS_chDir (dirname:string) : unit =
    checkError (ya_GenericOS_chdir (dirname))

fun GenericOS_mkDir (dirname:string) : unit =
    checkError (ya_GenericOS_mkdir (dirname))

fun GenericOS_rmDir (dirname:string) : unit =
    checkError (ya_GenericOS_rmdir (dirname))

fun GenericOS_getDir (_:int) : string =
    let
      val ret = ya_GenericOS_getcwd ()
    in
      checkErrorIfNull (_cast(ret):unit ptr);
      ret
    end

fun GenericOS_openDir (dirname:string) : word =
    let
      val dirhandle = ya_GenericOS_opendir dirname
    in
      if isNull dirhandle
      then raiseSysErr ()
      else _cast(dirhandle) : word
    end

fun GenericOS_readDir (dirhandle:word) : string option =
    let
      val dirhandle = _cast(dirhandle) : unit ptr
      val ret = ya_GenericOS_readdir dirhandle
    in
      if isNull (_cast(ret):unit ptr) then NONE else SOME ret
    end

fun GenericOS_rewindDir (dirhandle:word) : unit =
    ya_GenericOS_rewinddir (_cast(dirhandle) : unit ptr)

fun GenericOS_closeDir (dirhandle:word) : unit =
    checkError (ya_GenericOS_closedir (_cast(dirhandle) : unit ptr))

fun GenericOS_system (command:string) : int =
    let
      val status = ya_GenericOS_system command
    in
      checkError status;
      status
    end

fun GenericOS_getEnv (varname:string) : string option =
    let
      val ret = ya_GenericOS_getenv varname
    in
      if isNull (_cast(ret):unit ptr) then NONE else SOME ret
    end

local
  val POLLIN = 0w0
  val POLLOUT = 0w1
  val POLLPRI = 0w2

  fun fold (f, z, fds) =
      let
        fun fold' (i : int, f : 'a * int -> int, z : int, l : 'a array) =
            if i >= Array_length fds then z
            else fold' (i+1, f, f (Array_sub (l, i), z), l)
      in
        fold' (0, f, z, fds)
      end

  fun toFDSet (fds : (int * word) array, event : word) =
      let
        val len = fold (fn ((fd, ev), n) => if ev = event then n + 1 else n,
                        0, fds)
        val fdset = Array_mutableArray (len, 0)
      in
        fold (fn ((fd, ev), i) => (Array_update (fdset, i, fd); 0), 0, fds);
        fdset
      end

  fun fromFDSet (infds : int array, outfds : int array, prifds : int array) =
      let
        fun count fdset =
            fold (fn (fd, n) => if fd >= 0 then n + 1 else n, 0, fdset)

        fun set (dst, i, ev, fdset) =
            fold (fn (fd, n) =>
                     if fd >= 0
                     then (Array_update (dst, i, (fd, ev)); i + 1) else n,
                  i, fdset)

        val numIn = count infds
        val numOut = count outfds
        val numPri = count prifds
        val fds = Array_mutableArray (numIn + numOut + numPri, (0, 0w0))
        val i = 0
        val i = set (fds, i, POLLIN, infds)
        val i = set (fds, i, POLLOUT, outfds)
        val i = set (fds, i, POLLPRI, prifds)
      in
        fds
      end
in

fun GenericOS_getPOLLINFlag  (_:int) : word = POLLIN
fun GenericOS_getPOLLOUTFlag (_:int) : word = POLLOUT
fun GenericOS_getPOLLPRIFlag (_:int) : word = POLLPRI

fun GenericOS_poll
        (fds : (int * word) array, timeout : (int * int) option)
        : (int * word) array =
    let
      val (timeoutSec, timeoutMicro) =
          case timeout of
            SOME (sec, micro) => (sec, micro)
          | NONE => (~1, ~1)

      val infds  = toFDSet (fds, POLLIN)
      val outfds = toFDSet (fds, POLLOUT)
      val prifds = toFDSet (fds, POLLPRI)

      val err = ya_GenericOS_select (infds, outfds, prifds,
                                     timeoutSec, timeoutMicro)
      val _ = checkError err
    in
      if err = 0 then Array_mutableArray (0, (0,0w0))  (* timeout *)
      else fromFDSet (infds, outfds, prifds)
    end

end

fun Timer_getTime (x:int) : int * int * int * int * int * int =
    let
      val ret = Array_mutableArray (6, 0)
      val err = ya_Timer_getTimes ret
    in
      checkError err;
      (Array_sub (ret, 0),
       Array_sub (ret, 1),
       Array_sub (ret, 2),
       Array_sub (ret, 3),
       Array_sub (ret, 4),
       Array_sub (ret, 5))
    end
    handle SysErr (s,n) => raise SysErr (String_concat2("times:",s),n)

fun GC_addFinalizable (x:'a ref) : int =
    raise SysErr ("GC_adFinalizeable is not implemented", NONE)
fun GC_fixedCopy (x:'a ref) : 'a =
    raise SysErr ("GC_fixedCopy is not implemented", NONE)
fun GC_releaseFLOB (x:'a ref) : unit =
    raise SysErr ("GC_releaseFLOB is not implemented", NONE)
fun GC_addressOfFLOB (x:'a ref) : unit ptr =
    raise SysErr ("GC_addressOfFLOB is not implemented", NONE)
fun GC_copyBlock (x:'a ref) : 'a =
    raise SysErr ("GC_copyBlock is not implemented", NONE)

end
