(* posix-filesys.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * Structure for POSIX 1003.1 file system operations
 *
 *)

local
    structure SysWord = SysWordImp
    structure Word32 = Word32Imp
    structure Time = TimeImp
in
structure POSIX_FileSys =
  struct
    val ++ = SysWord.orb
    val & = SysWord.andb
    infix ++ &

    type word = SysWord.word
    type s_int = SysInt.int

    fun cfun x = CInterface.c_function "POSIX-FileSys" x
    val osval : string -> s_int = cfun "osval"
    val w_osval = SysWord.fromInt o osval

    datatype uid = UID of word
    datatype gid = GID of word

    datatype file_desc = FD of {fd : s_int}
    fun intOf (FD{fd,...}) = fd
    fun fd fd = FD{fd=fd}
    fun fdToWord (FD{fd,...}) = SysWord.fromInt fd
    fun wordToFD fd = FD{fd = SysWord.toInt fd}

  (* conversions between OS.IO.iodesc values and Posix file descriptors. *)
    fun fdToIOD (FD{fd,...}) = OS.IO.IODesc fd
    fun iodToFD (OS.IO.IODesc fd) = SOME(FD{fd = fd})

    val o_rdonly = w_osval "O_RDONLY"
    val o_wronly = w_osval "O_WRONLY"
    val o_rdwr = w_osval "O_RDWR"

    datatype open_mode = O_RDONLY | O_WRONLY | O_RDWR
    fun omodeFromWord omode =
          if omode = o_rdonly then O_RDONLY
          else if omode = o_wronly then O_WRONLY
          else if omode = o_rdwr then O_RDWR
          else raise Fail ("POSIX_FileSys.omodeFromWord: unknown mode "^
                                  (Word32.toString omode))

    fun omodeToWord O_RDONLY = o_rdonly
      | omodeToWord O_WRONLY = o_wronly
      | omodeToWord O_RDWR = o_rdwr

    fun uidToWord (UID i) = i
    fun wordToUid i = UID i
    fun gidToWord (GID i) = i
    fun wordToGid i = GID i

    type c_dirstream = Assembly.object  (* the underlying C DIRSTREAM *)

    datatype dirstream = DS of {
	dirStrm : c_dirstream,
	isOpen : bool ref
      }

    val opendir' : string -> c_dirstream  = cfun "opendir"
    val readdir' : c_dirstream -> string  = cfun "readdir"
    val rewinddir' : c_dirstream -> unit  = cfun "rewinddir"
    val closedir' : c_dirstream -> unit	  = cfun "closedir"
    fun opendir path = DS{
	    dirStrm = opendir' path,
	    isOpen = ref true
	  }
    fun readdir (DS{dirStrm, isOpen = ref false}) =
	  raise Assembly.SysErr("readdir on closed directory stream", NONE)
      | readdir (DS{dirStrm, ...}) =
	  case readdir' dirStrm of
	      "" => NONE
	    | name => SOME name
    fun rewinddir (DS{dirStrm, isOpen = ref false}) =
	  raise Assembly.SysErr("rewinddir on closed directory stream", NONE)
      | rewinddir (DS{dirStrm, ...}) = rewinddir' dirStrm
    fun closedir (DS{dirStrm, isOpen = ref false}) = ()
      | closedir (DS{dirStrm, isOpen}) = (
	  isOpen := false;
	  closedir' dirStrm)

    val chdir : string -> unit = cfun "chdir"
    val getcwd : unit -> string = cfun "getcwd"

    val stdin  = fd 0
    val stdout = fd 1
    val stderr = fd 2

    structure S =
      struct
        datatype flags = MODE of word
        type mode = flags

        fun fromWord w = MODE w
        fun toWord (MODE w) = w

        fun flags ms = MODE(List.foldl (fn (MODE m,acc) => m ++ acc) 0w0 ms)
        fun anySet (MODE m, MODE m') = (m & m') <> 0w0
        fun allSet (MODE m, MODE m') = (m & m') = m
 
        val irwxu = MODE(w_osval "irwxu")
        val irusr = MODE(w_osval "irusr")
        val iwusr = MODE(w_osval "iwusr")
        val ixusr = MODE(w_osval "ixusr")
        val irwxg = MODE(w_osval "irwxg")
        val irgrp = MODE(w_osval "irgrp")
        val iwgrp = MODE(w_osval "iwgrp")
        val ixgrp = MODE(w_osval "ixgrp")
        val irwxo = MODE(w_osval "irwxo")
        val iroth = MODE(w_osval "iroth")
        val iwoth = MODE(w_osval "iwoth")
        val ixoth = MODE(w_osval "ixoth")
        val isuid = MODE(w_osval "isuid")
        val isgid = MODE(w_osval "isgid")

      end

    structure O =
      struct
        datatype flags = OFL of word

        fun fromWord w = OFL w
        fun toWord (OFL w) = w

        fun flags ms = OFL(List.foldl (fn (OFL m,acc) => m ++ acc) 0w0 ms)
        fun anySet (OFL m, OFL m') = (m & m') <> 0w0
        fun allSet (OFL m, OFL m') = (m & m') = m

        val append   = OFL(w_osval "O_APPEND")
        val dsync    = OFL(w_osval "O_DSYNC")
        val excl     = OFL(w_osval "O_EXCL")
        val noctty   = OFL(w_osval "O_NOCTTY")
        val nonblock = OFL(w_osval "O_NONBLOCK")
        val rsync    = OFL(w_osval "O_RSYNC")
        val sync     = OFL(w_osval "O_SYNC")
        val o_trunc  = w_osval "O_TRUNC"
        val trunc    = OFL o_trunc
        val o_creat  = w_osval "O_CREAT"
        val crflags  = o_wronly ++ o_creat ++ o_trunc

      end

    val openf' : string * word * word -> s_int = cfun "openf"
    fun openf (fname, omode, O.OFL flags) =
          fd(openf'(fname, flags ++ (omodeToWord omode), 0w0))
    fun createf (fname, omode, O.OFL oflags, S.MODE mode) = let
          val flags = O.o_creat ++ oflags ++ (omodeToWord omode)
          in
            fd(openf'(fname, flags, mode))
          end
    fun creat (fname, S.MODE mode) =
          fd(openf'(fname, O.crflags, mode))

    val umask' : word -> word = cfun "umask"
    fun umask (S.MODE mode) = S.MODE(umask' mode)

    val link' : string * string -> unit = cfun "link"
    fun link {old, new} = link'(old,new)
    val rename' : string * string -> unit = cfun "rename"
    fun rename {old, new} = rename'(old,new)
    val symlink' : string * string -> unit = cfun "symlink"
    fun symlink {old, new} = symlink'(old,new)

    val mkdir' : string * word -> unit = cfun "mkdir"
    fun mkdir (dirname, S.MODE mode) = mkdir'(dirname,mode)

    val mkfifo' : string * word -> unit = cfun "mkfifo"
    fun mkfifo (name, S.MODE mode) = mkfifo'(name,mode)

    val unlink : string -> unit = cfun "unlink"
    val rmdir : string -> unit = cfun "rmdir"
    val readlink : string -> string = cfun "readlink"

    val ftruncate' : s_int * Position.int -> unit = cfun "ftruncate"
    fun ftruncate (FD{fd,...}, len) = ftruncate' (fd, len);

    datatype dev = DEV of word
    fun devToWord (DEV i) = i
    fun wordToDev i = DEV i

    datatype ino = INO of word
    fun inoToWord (INO i) = i
    fun wordToIno i = INO i

    structure ST =
      struct
        datatype stat = ST of {
                 ftype : s_int,
                 mode  : S.mode,
                 ino   : ino,
                 dev   : dev,
                 nlink : int,
                 uid   : uid,
                 gid   : gid,
                 size  : Position.int,
                 atime : Time.time,
                 mtime : Time.time,
                 ctime : Time.time
               }
      (* The following assumes the C stat functions pull the
       * file type from the mode field and return the
       * integer below corresponding to the file type.
       *) 
	fun isDir  (ST{ftype, ...}) = (ftype = 0x4000)
	fun isChr  (ST{ftype, ...}) = (ftype = 0x2000)
	fun isBlk  (ST{ftype, ...}) = (ftype = 0x6000)
	fun isReg  (ST{ftype, ...}) = (ftype = 0x8000)
	fun isFIFO (ST{ftype, ...}) = (ftype = 0x1000)
	fun isLink (ST{ftype, ...}) = (ftype = 0xA000)
	fun isSock (ST{ftype, ...}) = (ftype = 0xC000)

        fun mode (ST{mode,...}) = mode
        fun ino (ST{ino,...}) = ino
        fun dev (ST{dev,...}) = dev
        fun nlink (ST{nlink,...}) = nlink
        fun uid (ST{uid,...}) = uid
        fun gid (ST{gid,...}) = gid
        fun size (ST{size,...}) = size
        fun atime (ST{atime,...}) = atime
        fun mtime (ST{mtime,...}) = mtime
        fun ctime (ST{ctime,...}) = ctime
      end (* structure ST *) 

  (* this layout needs to track c-libs/posix-filesys/stat.c *)
    type statrep =
      ( s_int			(* file type *)
      * word			(* mode *)
      * word			(* ino *)
      * word			(* devno *)
      * word			(* nlink *)
      * word			(* uid *)
      * word			(* gid *)
      * Position.int		(* size *)
      * Int32.int		(* atime *)
      * Int32.int		(* mtime *)
      * Int32.int		(* ctime *)
      )
    fun mkStat (sr : statrep) = ST.ST{
	    ftype = #1 sr,
            mode = S.MODE (#2 sr),
            ino = INO (#3 sr),
            dev = DEV (#4 sr),
            nlink = SysWord.toInt(#5 sr),	(* probably should be an int in
						 * the run-time too.
						 *)
            uid = UID(#6 sr),
            gid = GID(#7 sr),
            size = #8 sr,
            atime = Time.fromSeconds (Int32Imp.toLarge (#9 sr)),
            mtime = Time.fromSeconds (Int32Imp.toLarge (#10 sr)),
            ctime = Time.fromSeconds (Int32Imp.toLarge (#11 sr))
          }

    val stat' : string -> statrep = cfun "stat"
    val lstat' : string -> statrep = cfun "lstat"
    val fstat' : s_int -> statrep = cfun "fstat"
    fun stat fname = mkStat (stat' fname)
    fun lstat fname = mkStat (lstat' fname) (* POSIX 1003.1a *)
    fun fstat (FD{fd}) = mkStat (fstat' fd)

    datatype access_mode = A_READ | A_WRITE | A_EXEC
    val a_read = w_osval "A_READ"	(* R_OK *)
    val a_write = w_osval "A_WRITE"	(* W_OK *)
    val a_exec = w_osval "A_EXEC"	(* X_OK *)
    val a_file = w_osval "A_FILE"	(* F_OK *)
    fun amodeToWord [] = a_file
      | amodeToWord l = let
          fun amtoi (A_READ,v) = a_read ++ v
            | amtoi (A_WRITE,v) = a_write ++ v
            | amtoi (A_EXEC,v) = a_exec ++ v
          in
            List.foldl amtoi a_file l
          end
    val access' : string * word -> bool = cfun "access"
    fun access (fname, aml) = access'(fname, amodeToWord aml)

    val chmod' : string * word -> unit = cfun "chmod"
    fun chmod (fname, S.MODE m) = chmod'(fname, m)

    val fchmod' : s_int * word -> unit = cfun "fchmod"
    fun fchmod (FD{fd}, S.MODE m) = fchmod'(fd, m)

    val chown' : string * word * word -> unit = cfun "chown"
    fun chown (fname, UID uid, GID gid) = chown'(fname, uid, gid)

    val fchown' : s_int * word * word -> unit = cfun "fchown"
    fun fchown (fd, UID uid, GID gid) = fchown'(intOf fd, uid, gid)

    val utime' : string * Int32.int * Int32.int -> unit = cfun "utime"
    fun utime (file, NONE) = utime' (file, ~1, 0)
      | utime (file, SOME{actime, modtime}) = let
          val atime = Int32Imp.fromLarge (Time.toSeconds actime)
          val mtime = Int32Imp.fromLarge (Time.toSeconds modtime)
          in
            utime'(file,atime,mtime)
          end
    
    val pathconf  : (string * string) -> word option = cfun "pathconf"
    val fpathconf'  : (s_int * string) -> word option = cfun "fpathconf"
    fun fpathconf (FD{fd}, s) = fpathconf'(fd, s)

  end (* structure POSIX_FileSys *)
end

